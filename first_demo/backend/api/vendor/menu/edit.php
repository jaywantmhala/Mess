<?php
/**
 * POST /api/vendor/menu/edit
 *
 * Edits an existing daily food menu item details.
 * Body: { id, food_name, description, food_type, menu_date, image_url, mandatory_items: [], optional_items: [] }
 * Header: Authorization: Bearer <token>
 */

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/validation.php';
require_once __DIR__ . '/../../../helpers/jwt.php';
require_once __DIR__ . '/../../../helpers/redis_helper.php';

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
$price       = isset($body['price']) ? (float)$body['price'] : 0.0;
$spiceLevel  = isset($body['spice_level']) ? sanitize($body['spice_level']) : 'NONE';
$isPopular   = isset($body['is_popular']) ? (int)$body['is_popular'] : 0;
$isAvailable = isset($body['is_available']) ? (int)$body['is_available'] : 1;
$rawMealType = isset($body['meal_type']) ? trim(sanitize($body['meal_type'])) : null;
$mealType    = ($rawMealType !== null && strcasecmp($rawMealType, 'Dinner') === 0) ? 'Dinner' : (($rawMealType !== null && strcasecmp($rawMealType, 'Lunch') === 0) ? 'Lunch' : null);

$mandatoryItems = null;
if (isset($body['mandatory_items']) && is_array($body['mandatory_items'])) {
    $mandatoryItems = [];
    foreach ($body['mandatory_items'] as $item) {
        $clean = sanitize(is_array($item) ? ($item['name'] ?? '') : (string)$item);
        if (!empty($clean)) {
            $mandatoryItems[] = $clean;
        }
    }
}

$optionalItems = null;
if (isset($body['optional_items']) && is_array($body['optional_items'])) {
    $optionalItems = [];
    foreach ($body['optional_items'] as $item) {
        $clean = sanitize(is_array($item) ? ($item['name'] ?? '') : (string)$item);
        if (!empty($clean)) {
            $optionalItems[] = $clean;
        }
    }
}

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
    SELECT m.id, m.hotel_id, m.menu_date, m.meal_type FROM menus m
    JOIN hotels h ON m.hotel_id = h.id
    WHERE m.id = :menu_id AND h.vendor_id = :vendor_id
    LIMIT 1
");
$stmt->execute([
    ':menu_id'   => $menuId,
    ':vendor_id' => $vendorId,
]);
$existingItem = $stmt->fetch(PDO::FETCH_ASSOC);
if (!$existingItem) {
    sendError('Menu item not found or permission denied.', 404);
}

// Time cutoff validation: lock editing according to meal timing
date_default_timezone_set('Asia/Kolkata');
$todayStr = date('Y-m-d');
$currentHour = (int)date('H');
$itemDate = $existingItem['menu_date'];
$itemMealType = !empty($existingItem['meal_type']) ? $existingItem['meal_type'] : 'Lunch';

if ($itemDate < $todayStr) {
    sendError('This menu item cannot be edited because its date has passed.', 403);
}
if ($itemDate === $todayStr && strcasecmp($itemMealType, 'Lunch') === 0 && $currentHour >= 16) {
    sendError('Lunch menu cannot be edited once lunch time has passed.', 403);
}

$mandatoryJson = $mandatoryItems !== null ? json_encode(array_values($mandatoryItems), JSON_UNESCAPED_UNICODE) : null;
$optionalJson  = $optionalItems !== null ? json_encode(array_values($optionalItems), JSON_UNESCAPED_UNICODE) : null;

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
        meal_type = COALESCE(:meal_type, meal_type), 
        menu_date = :menu_date,
        mandatory_items = COALESCE(:mandatory_items, mandatory_items),
        optional_items = COALESCE(:optional_items, optional_items),
        updated_at = NOW()
    WHERE id = :id
");
$stmt->execute([
    ':id'              => $menuId,
    ':food_name'       => $foodName,
    ':description'     => $description,
    ':food_type'       => $foodType,
    ':price'           => $price,
    ':spice_level'     => $spiceLevel,
    ':is_popular'      => $isPopular,
    ':is_available'    => $isAvailable,
    ':image_url'       => $imageUrl,
    ':meal_type'       => $mealType,
    ':menu_date'       => $menuDate,
    ':mandatory_items' => $mandatoryJson,
    ':optional_items'  => $optionalJson,
]);

// Fetch updated menu item
$stmt = $pdo->prepare("SELECT * FROM menus WHERE id = :id");
$stmt->execute([':id' => $menuId]);
$menuItem = $stmt->fetch(PDO::FETCH_ASSOC);

if ($menuItem) {
    $menuItem['mandatory_items'] = json_decode($menuItem['mandatory_items'] ?? '[]', true) ?: [];
    $menuItem['optional_items']  = json_decode($menuItem['optional_items'] ?? '[]', true) ?: [];
}

// Invalidate Redis menu cache for this hotel
if (!empty($existingItem['hotel_id'])) {
    RedisHelper::invalidateHotelMenu((int)$existingItem['hotel_id'], $menuDate);
}

sendSuccess('Food item updated successfully.', [
    'menu_item' => $menuItem,
]);
