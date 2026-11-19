<?php
/**
 * POST /api/orders/chat/mark_read
 * Marks all incoming chat messages for an order as read.
 * Body: { order_id }
 * Requires: Authorization: Bearer <JWT> (Customer or Vendor role)
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST')   { sendError('Method not allowed. Use POST.', 405); }

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/jwt.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/ably_helper.php';

$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload) {
    sendError('Unauthorized access. Token required.', 401);
}

$userRole = $payload['role'] ?? '';
$userId   = (int)($payload['sub'] ?? 0);

if (!in_array($userRole, ['customer', 'vendor'])) {
    sendError('Forbidden. Customer or Vendor token required.', 403);
}

$body    = json_decode(file_get_contents('php://input'), true) ?? [];
$orderId = (int)($body['order_id'] ?? 0);

if ($orderId <= 0) {
    sendError('Valid order_id is required.', 422);
}

try {
    $pdo = getDBConnection();

    // Verify order exists and validate ownership/permission
    $orderStmt = $pdo->prepare("
        SELECT o.order_id, o.customer_id, h.vendor_id
        FROM orders o
        JOIN hotels h ON o.hotel_id = h.id
        WHERE o.order_id = ?
    ");
    $orderStmt->execute([$orderId]);
    $order = $orderStmt->fetch(PDO::FETCH_ASSOC);

    if (!$order) {
        sendError('Order not found.', 404);
    }

    if ($userRole === 'customer' && (int)$order['customer_id'] !== $userId) {
        sendError('Forbidden. You do not own this order.', 403);
    }
    if ($userRole === 'vendor' && (int)$order['vendor_id'] !== $userId) {
        sendError('Forbidden. You do not manage this hotel\'s orders.', 403);
    }

    // Mark messages from the OTHER party as read
    $otherRole = ($userRole === 'customer') ? 'vendor' : 'customer';

    $updateStmt = $pdo->prepare("
        UPDATE order_chats
        SET is_read = 1
        WHERE order_id = ? AND sender_type = ? AND is_read = 0
    ");
    $updateStmt->execute([$orderId, $otherRole]);
    $affected = $updateStmt->rowCount();

    if ($affected > 0) {
        // Publish read receipt event to Ably channels
        $readData = [
            'order_id'       => $orderId,
            'reader_role'    => $userRole,
            'read_timestamp' => date('Y-m-d H:i:s'),
        ];
        $chatChannel   = AblyHelper::getOrderChatChannel($orderId);
        $hotelChannel  = AblyHelper::getHotelOrdersChannel((int)$order['hotel_id']);
        $globalChannel = AblyHelper::getDefaultChannel();

        AblyHelper::publish('CHAT_READ_RECEIPT', $readData, $chatChannel);
        AblyHelper::publish('CHAT_READ_RECEIPT', $readData, $hotelChannel);
        AblyHelper::publish('CHAT_READ_RECEIPT', $readData, $globalChannel);
    }

    sendSuccess('Messages marked as read.', [
        'order_id' => $orderId,
        'affected' => $affected
    ]);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
