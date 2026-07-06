<?php
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST') { sendError('Method not allowed.', 405); }

$token = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;
if (!$payload || !isset($payload['sub'])) { sendError('Unauthorized.', 401); }
$customerId = (int) $payload['sub'];

$body = json_decode(file_get_contents('php://input'), true);
if (!isset($body['menu_item_id'], $body['hotel_id'], $body['quantity'])) {
    sendError('menu_item_id, hotel_id, and quantity are required.', 422);
}

$menuItemId = (int) $body['menu_item_id'];
$hotelId    = (int) $body['hotel_id'];
$quantity   = (int) $body['quantity'];

if ($menuItemId <= 0) { sendError('Invalid menu_item_id.', 422); }
if ($hotelId    <= 0) { sendError('Invalid hotel_id.', 422); }
if ($quantity   <= 0) { sendError('Quantity must be at least 1.', 422); }

try {
    $pdo = getDBConnection();

    // Check if the menu item exists and belongs to the given hotel
    $menuStmt = $pdo->prepare(
        "SELECT id FROM menus WHERE id = ? AND hotel_id = ? AND is_available = 1"
    );
    $menuStmt->execute([$menuItemId, $hotelId]);
    if (!$menuStmt->fetch()) {
        sendError('Menu item not found or unavailable.', 404);
    }

    // Check for hotel conflict in existing cart
    $conflictStmt = $pdo->prepare(
        "SELECT ci.hotel_id, h.hotel_name AS hotel_name
         FROM cart_items ci
         JOIN hotels h ON h.id = ci.hotel_id
         WHERE ci.customer_id = ?
         LIMIT 1"
    );
    $conflictStmt->execute([$customerId]);
    $existingCart = $conflictStmt->fetch(PDO::FETCH_ASSOC);

    if ($existingCart && (int) $existingCart['hotel_id'] !== $hotelId) {
        // Cart has items from a different hotel
        http_response_code(409);
        echo json_encode([
            'success'            => false,
            'message'            => 'Your cart has items from another restaurant. Please clear your cart before adding items from a different restaurant.',
            'hotel_conflict'     => true,
            'existing_hotel_name'=> $existingCart['hotel_name'],
        ]);
        exit;
    }

    // Upsert: if the cart_item already exists, add quantity; otherwise insert
    $upsertStmt = $pdo->prepare(
        "INSERT INTO cart_items (customer_id, hotel_id, menu_item_id, quantity)
         VALUES (?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE quantity = quantity + VALUES(quantity)"
    );
    $upsertStmt->execute([$customerId, $hotelId, $menuItemId, $quantity]);

    // Return full cart summary
    require_once __DIR__ . '/cart_summary.php';
    $summary = getCartSummary($pdo, $customerId);
    sendSuccess('Item added to cart.', $summary);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
