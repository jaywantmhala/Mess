<?php
/**
 * POST /api/vendor/menu/delete
 *
 * Deletes an existing daily food menu item.
 * Body: { id }
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
    'id'
]);

$menuId = (int)$body['id'];

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

// Time cutoff validation: lock removal according to meal timing
date_default_timezone_set('Asia/Kolkata');
$todayStr = date('Y-m-d');
$currentHour = (int)date('H');
$itemDate = $existingItem['menu_date'];
$itemMealType = !empty($existingItem['meal_type']) ? $existingItem['meal_type'] : 'Lunch';

if ($itemDate < $todayStr) {
    sendError('This menu item cannot be removed because its date has passed.', 403);
}
if ($itemDate === $todayStr && strcasecmp($itemMealType, 'Lunch') === 0 && $currentHour >= 16) {
    sendError('Lunch menu cannot be removed once lunch time has passed.', 403);
}

// Delete menu item
$stmt = $pdo->prepare("DELETE FROM menus WHERE id = :id");
$stmt->execute([':id' => $menuId]);

// Invalidate Redis menu cache for this hotel
if (!empty($existingItem['hotel_id'])) {
    RedisHelper::invalidateHotelMenu((int)$existingItem['hotel_id'], $existingItem['menu_date'] ?? null);
}

sendSuccess('Food item removed from menu successfully.');
