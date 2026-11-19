<?php
/**
 * GET /api/orders/chat/messages?order_id=123
 * Retrieves all chat messages for a specific order and returns chat state.
 * Requires: Authorization: Bearer <JWT> (Customer or Vendor role)
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'GET')    { sendError('Method not allowed. Use GET.', 405); }

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/jwt.php';
require_once __DIR__ . '/../../../helpers/response.php';

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

$orderId = isset($_GET['order_id']) ? (int)$_GET['order_id'] : 0;
if ($orderId <= 0) {
    sendError('Valid order_id parameter is required.', 422);
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

    // Chat is enabled ONLY while driver is NOT assigned
    $isChatEnabled = ($order['driver_id'] === null || (int)$order['driver_id'] === 0);

    // Fetch message history
    $msgStmt = $pdo->prepare("
        SELECT id, order_id, sender_type, sender_id, message, is_read, created_at
        FROM order_chats
        WHERE order_id = ?
        ORDER BY id ASC
    ");
    $msgStmt->execute([$orderId]);
    $messages = $msgStmt->fetchAll(PDO::FETCH_ASSOC);

    $unreadCount = 0;
    foreach ($messages as &$m) {
        $m['id']          = (int)$m['id'];
        $m['order_id']    = (int)$m['order_id'];
        $m['sender_id']   = (int)$m['sender_id'];
        $m['is_read']     = (bool)$m['is_read'];
        if ($m['sender_type'] !== $userRole && !$m['is_read']) {
            $unreadCount++;
        }
    }
    unset($m);

    sendSuccess('Order chat messages retrieved.', [
        'order_id'        => $orderId,
        'is_chat_enabled' => $isChatEnabled,
        'hotel_name'      => $order['hotel_name'] ?? 'Restaurant',
        'unread_count'    => $unreadCount,
        'messages'        => $messages
    ]);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
