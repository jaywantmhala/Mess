<?php
/**
 * POST /api/orders/chat/send
 * Sends a chat message for an active order before driver assignment.
 * Body: { order_id, message }
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
require_once __DIR__ . '/../../../helpers/fcm.php';

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
$message = trim($body['message'] ?? '');

if ($orderId <= 0) {
    sendError('Valid order_id is required.', 422);
}
if (empty($message)) {
    sendError('Message content cannot be empty.', 422);
}

try {
    $pdo = getDBConnection();

    // Verify order exists and validate ownership/permission
    $orderStmt = $pdo->prepare("
        SELECT o.order_id, o.customer_id, o.driver_id, o.status, h.vendor_id, h.hotel_name
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

    // ── Strict Constraint: Chat is disabled once driver is assigned ─────────
    if ($order['driver_id'] !== null && (int)$order['driver_id'] > 0) {
        sendError('Chat is closed for this order because a driver has already been assigned.', 400);
    }

    // Insert chat message
    $insStmt = $pdo->prepare("
        INSERT INTO order_chats (order_id, sender_type, sender_id, message, is_read, created_at)
        VALUES (:order_id, :sender_type, :sender_id, :message, 0, NOW())
    ");
    $insStmt->execute([
        ':order_id'    => $orderId,
        ':sender_type' => $userRole,
        ':sender_id'   => $userId,
        ':message'     => $message,
    ]);

    $chatId = (int)$pdo->lastInsertId();

    $msgData = [
        'id'          => $chatId,
        'order_id'    => $orderId,
        'sender_type' => $userRole,
        'sender_id'   => $userId,
        'message'     => $message,
        'is_read'     => false,
        'created_at'  => date('Y-m-d H:i:s'),
    ];

    // Publish to Ably order chat channel, hotel channel, and global channel so both Customer & Vendor receive real-time updates
    $chatChannel   = AblyHelper::getOrderChatChannel($orderId);
    $hotelChannel  = AblyHelper::getHotelOrdersChannel((int)$order['hotel_id']);
    $globalChannel = AblyHelper::getDefaultChannel();

    AblyHelper::publish('CHAT_MESSAGE', $msgData, $chatChannel);
    AblyHelper::publish('CHAT_MESSAGE', $msgData, $hotelChannel);
    AblyHelper::publish('CHAT_MESSAGE', $msgData, $globalChannel);

    // Send FCM notification to recipient
    if ($userRole === 'customer') {
        // Send to vendor
        $vendorId = (int)$order['vendor_id'];
        FcmHelper::sendToVendor($vendorId, "New message on Order #{$orderId}", $message, [
            'event'    => 'CHAT_MESSAGE',
            'order_id' => (string)$orderId,
        ]);
    } else {
        // Send to customer
        $customerId = (int)$order['customer_id'];
        FcmHelper::sendToCustomer($customerId, "New message from {$order['hotel_name']}", $message, [
            'event'    => 'CHAT_MESSAGE',
            'order_id' => (string)$orderId,
        ]);
    }

    sendSuccess('Message sent successfully.', [
        'message' => $msgData
    ]);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
