<?php
/**
 * POST /api/vendor/menu/edit
 *
 * Edits an existing daily food menu item details.
 * Body: { id, food_name, description, food_type, menu_date, image_url }
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
    'id',
    'food_name',
    'food_type',
    'menu_date'
]);

$menuId      = (int)$body['id'];
$foodName    = sanitize($body['food_name']);
$foodType    = strtoupper(sanitize($body['food_type']));
$menuDate    = sanitize($body['menu_date']);
$description = isset($body['description']) ? sanitize($body['description']) : '';
$imageUrl    = isset($body['image_url']) ? sanitize($body['image_url']) : null;
$price       = isset($body['price']) ? (double)$body['price'] : 0.0;
$spiceLevel  = isset($body['spice_level']) ? sanitize($body['spice_level']) : 'NONE';
$isPopular   = isset($body['is_popular']) ? (int)$body['is_popular'] : 0;
$isAvailable = isset($body['is_available']) ? (int)$body['is_available'] : 1;

if (empty($foodName)) { sendError('Food name is required.', 422); }
if ($foodType !== 'VEG' && $foodType !== 'NON-VEG') {
    sendError('Food type must be either VEG or NON-VEG.', 422);
}
if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $menuDate)) {
    sendError('Invalid menu date format. Use YYYY-MM-DD.', 422);
}

// ── Database ──────────────────────────────────────────────────────────────────
$pdo = getDBConnection();

// Verify menu item belongs to a hotel owned by this vendor
$stmt = $pdo->prepare("
    SELECT m.id FROM menus m
    JOIN hotels h ON m.hotel_id = h.id
    WHERE m.id = :menu_id AND h.vendor_id = :vendor_id
    LIMIT 1
");
$stmt->execute([
    ':menu_id'   => $menuId,
    ':vendor_id' => $vendorId,
]);
if (!$stmt->fetch()) {
    sendError('Menu item not found or permission denied.', 404);
}

// Update daily menu item
$stmt = $pdo->prepare("
    UPDATE menus 
    SET 
        food_name = :food_name, 
        description = :description, 
        food_type = :food_type, 
        price = :price,
        spice_level = :spice_level,
        is_popular = :is_popular,
        is_available = :is_available,
        image_url = COALESCE(:image_url, image_url), 
        menu_date = :menu_date,
        updated_at = NOW()
    WHERE id = :id
");
$stmt->execute([
    ':id'          => $menuId,
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

// Fetch updated menu item
$stmt = $pdo->prepare("SELECT * FROM menus WHERE id = :id");
$stmt->execute([':id' => $menuId]);
$menuItem = $stmt->fetch();

sendSuccess('Food item updated successfully.', [
    'menu_item' => $menuItem,
]);
