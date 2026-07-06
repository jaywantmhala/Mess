<?php
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/jwt.php';
require_once __DIR__ . '/cart_summary.php';

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
if (!isset($body['cart_item_id'], $body['quantity'])) {
    sendError('cart_item_id and quantity are required.', 422);
}

$cartItemId = (int) $body['cart_item_id'];
$quantity   = (int) $body['quantity'];

if ($cartItemId <= 0) { sendError('Invalid cart_item_id.', 422); }

try {
    $pdo = getDBConnection();

    // Verify the cart item belongs to this customer
    $ownerStmt = $pdo->prepare(
        "SELECT cart_item_id FROM cart_items WHERE cart_item_id = ? AND customer_id = ?"
    );
    $ownerStmt->execute([$cartItemId, $customerId]);
    if (!$ownerStmt->fetch()) {
        sendError('Cart item not found.', 404);
    }

    if ($quantity <= 0) {
        // Remove the item from cart
        $del = $pdo->prepare("DELETE FROM cart_items WHERE cart_item_id = ? AND customer_id = ?");
        $del->execute([$cartItemId, $customerId]);
    } else {
        // Update quantity
        $upd = $pdo->prepare(
            "UPDATE cart_items SET quantity = ? WHERE cart_item_id = ? AND customer_id = ?"
        );
        $upd->execute([$quantity, $cartItemId, $customerId]);
    }

    $summary = getCartSummary($pdo, $customerId);
    sendSuccess('Cart updated successfully.', $summary);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
