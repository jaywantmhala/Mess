<?php
/**
 * GET /api/hotels/menu
 *
 * Retrieves available menu items for a specific hotel.
 * Query Parameters: hotel_id
 * Header: Authorization: Bearer <token>
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'GET')     { sendError('Method not allowed. Use GET.', 405); }

// ── JWT Authentication (Optional or Required depending on app rules) ────────
$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || !isset($payload['sub'])) {
    sendError('Unauthorized. Please log in again.', 401);
}

// ── Validate Input ────────────────────────────────────────────────────────────
$hotelId = isset($_GET['hotel_id']) ? (int)$_GET['hotel_id'] : 0;

if ($hotelId <= 0) { sendError('Hotel ID is required.', 422); }

// ── Database ──────────────────────────────────────────────────────────────────
$pdo = getDBConnection();

// Fetch menu items for the specific hotel for today
$stmt = $pdo->prepare("
    SELECT * FROM menus 
    WHERE hotel_id = :hotel_id AND menu_date = CURDATE()
    ORDER BY created_at DESC
");
$stmt->execute([
    ':hotel_id'  => $hotelId
]);
$menuItems = $stmt->fetchAll(PDO::FETCH_ASSOC);

// Map database fields to what Flutter app expects
$mappedItems = array_map(function($item) {
    return [
        'id' => $item['id'],
        'name' => $item['food_name'],
        'description' => $item['description'],
        'price' => (double)$item['price'],
        'originalPrice' => null, // Optional feature not in DB yet
        'isVeg' => strtoupper($item['food_type']) === 'VEG',
        'isSpicy' => strtoupper($item['spice_level']) !== 'NONE',
        'isHighlyReordered' => (bool)$item['is_popular'],
        'isAvailable' => (bool)$item['is_available'],
        'isCustomisable' => true, // Mocking customisable as true by default
        'imageUrl' => $item['image_url'] ? $item['image_url'] : 'https://images.unsplash.com/photo-1541592106381-b31e9677c0e5?q=80&w=400',
    ];
}, $menuItems);

sendSuccess('Menu items retrieved successfully.', $mappedItems);
