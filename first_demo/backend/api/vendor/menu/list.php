<?php
/**
 * GET /api/vendor/menu/list
 *
 * Retrieves daily food menu items for a specific hotel and date.
 * Query Parameters: hotel_id, date (YYYY-MM-DD)
 * Header: Authorization: Bearer <token>
 */

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/validation.php';
require_once __DIR__ . '/../../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'GET')     { sendError('Method not allowed. Use GET.', 405); }

// ── JWT Authentication ────────────────────────────────────────────────────────
$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || !isset($payload['sub'])) {
    sendError('Unauthorized. Please log in again.', 401);
}

$vendorId = (int)$payload['sub'];

// ── Validate Input ────────────────────────────────────────────────────────────
$hotelId  = isset($_GET['hotel_id']) ? (int)$_GET['hotel_id'] : 0;
$menuDate = isset($_GET['date']) ? sanitize($_GET['date']) : '';

if ($hotelId <= 0) { sendError('Hotel ID is required.', 422); }
if (empty($menuDate) || !preg_match('/^\d{4}-\d{2}-\d{2}$/', $menuDate)) {
    sendError('Invalid or missing date format. Use YYYY-MM-DD.', 422);
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

// Fetch all menu items for the specific hotel and date
$stmt = $pdo->prepare("
    SELECT * FROM menus 
    WHERE hotel_id = :hotel_id AND menu_date = :menu_date 
    ORDER BY created_at DESC
");
$stmt->execute([
    ':hotel_id'  => $hotelId,
    ':menu_date' => $menuDate,
]);
$menuItems = $stmt->fetchAll();

sendSuccess('Daily menu items retrieved successfully.', [
    'menu_items' => $menuItems,
]);
