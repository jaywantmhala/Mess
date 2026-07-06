<?php
/**
 * POST /api/vendor/menu/add
 *
 * Adds a new daily food menu item under a vendor's hotel.
 * Body: { hotel_id, food_name, description, food_type, menu_date, image_url }
 * Header: Authorization: Bearer <token>
 */

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/validation.php';
require_once __DIR__ . '/../../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST')    { sendError('Method not allowed. Use POST.', 405); }

// ── JWT Authentication ────────────────────────────────────────────────────────
$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || !isset($payload['sub'])) {
    sendError('Unauthorized. Please log in again.', 401);
}

$vendorId = (int)$payload['sub'];

// ── Validate Input ────────────────────────────────────────────────────────────
$body = requireJsonBody([
    'hotel_id',
    'food_name',
    'food_type',
    'menu_date'
]);

$hotelId     = (int)$body['hotel_id'];
$foodName    = sanitize($body['food_name']);
$foodType    = strtoupper(sanitize($body['food_type']));
$menuDate    = sanitize($body['menu_date']);
$description = isset($body['description']) ? sanitize($body['description']) : '';
$imageUrl    = isset($body['image_url']) ? sanitize($body['image_url']) : null;
$price       = isset($body['price']) ? (float)$body['price'] : 0.0;
$spiceLevel  = isset($body['spice_level']) ? sanitize($body['spice_level']) : 'NONE';
$isPopular   = isset($body['is_popular']) ? (int)$body['is_popular'] : 0;
$isAvailable = isset($body['is_available']) ? (int)$body['is_available'] : 1;

if (empty($foodName)) { sendError('Food name is required.', 422); }
if ($foodType !== 'VEG' && $foodType !== 'NON-VEG') {
    sendError('Food type must be either VEG or NON-VEG.', 422);
}
// Validate date format YYYY-MM-DD
if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $menuDate)) {
    sendError('Invalid menu date format. Use YYYY-MM-DD.', 422);
}

// ── Database ──────────────────────────────────────────────────────────────────
$pdo = getDBConnection();

// Verify hotel exists and belongs to this vendor
$stmt = $pdo->prepare("SELECT id FROM hotels WHERE id = :id AND vendor_id = :vendor_id LIMIT 1");
$stmt->execute([
    ':id'        => $hotelId,
    ':vendor_id' => $vendorId,
]);
if (!$stmt->fetch()) {
    sendError('Hotel listing not found or permission denied.', 404);
}

// Insert daily menu item
$stmt = $pdo->prepare("
    INSERT INTO menus (hotel_id, food_name, description, food_type, price, spice_level, is_popular, is_available, image_url, menu_date, created_at, updated_at)
    VALUES (:hotel_id, :food_name, :description, :food_type, :price, :spice_level, :is_popular, :is_available, :image_url, :menu_date, NOW(), NOW())
");
$stmt->execute([
    ':hotel_id'    => $hotelId,
    ':food_name'   => $foodName,
    ':description' => $description,
    ':food_type'   => $foodType,
    ':price'       => $price,
    ':spice_level' => $spiceLevel,
    ':is_popular'  => $isPopular,
    ':is_available' => $isAvailable,
    ':image_url'   => $imageUrl,
    ':menu_date'   => $menuDate,
]);

$menuId = (int)$pdo->lastInsertId();

// Fetch the added menu item
$stmt = $pdo->prepare("SELECT * FROM menus WHERE id = :id");
$stmt->execute([':id' => $menuId]);
$menuItem = $stmt->fetch();

sendSuccess('Food item added to menu successfully.', [
    'menu_item' => $menuItem,
], 201);
