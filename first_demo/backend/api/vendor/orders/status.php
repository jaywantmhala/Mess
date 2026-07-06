<?php
// backend/api/vendor/orders/status.php
header('Content-Type: application/json; charset=utf-8');

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/jwt.php';
require_once __DIR__ . '/../../../helpers/response.php';

// ── JWT Authentication ────────────────────────────────────────────────────────
$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || ($payload['role'] ?? '') !== 'vendor') {
    sendError('Unauthorized access. Vendor token required.', 401);
}

$vendorId = (int)$payload['sub'];

// Read JSON input
$input = json_decode(file_get_contents('php://input'), true);
$orderId = isset($input['order_id']) ? (int)$input['order_id'] : 0;
$status = isset($input['status']) ? trim($input['status']) : '';

if ($orderId <= 0 || empty($status)) {
    sendError('Required fields: order_id and status.', 400);
}

// Validate status enum
$validStatuses = ['created_order', 'accepted', 'rejected', 'preparing', 'ready', 'completed', 'cancelled'];
if (!in_array($status, $validStatuses)) {
    sendError('Invalid order status. Allowed: ' . implode(', ', $validStatuses), 400);
}

try {
    $pdo = getDBConnection();
    
    // Check if order exists and belongs to this vendor
    $checkStmt = $pdo->prepare("
        SELECT o.status, o.customer_id, o.hotel_id, h.vendor_id
        FROM orders o
        JOIN hotels h ON o.hotel_id = h.id
        WHERE o.order_id = ?
    ");
    $checkStmt->execute([$orderId]);
    $order = $checkStmt->fetch(PDO::FETCH_ASSOC);

    if (!$order) {
        sendError('Order not found.', 44);
    }

    if ((int)$order['vendor_id'] !== $vendorId) {
        sendError('Forbidden. You do not manage this hotel\'s orders.', 403);
    }

    // Update the status in DB
    $updateStmt = $pdo->prepare("UPDATE orders SET status = ?, updated_at = NOW() WHERE order_id = ?");
    $updateStmt->execute([$status, $orderId]);

    $customerId = (int)$order['customer_id'];
    $hotelId = (int)$order['hotel_id'];

    // ── Send real-time notification to WebSocket server ─────────────────
    try {
        $fp = @fsockopen("127.0.0.1", 8081, $errno, $errstr, 1);
        if ($fp) {
            $notification = [
                'system_event' => true,
                'secret' => 'first_demo_system_websocket_secret_key_2026',
                'event' => 'ORDER_STATUS_UPDATED',
                'data' => [
                    'order_id' => $orderId,
                    'customer_id' => $customerId,
                    'hotel_id' => $hotelId,
                    'status' => $status
                ]
            ];
            @fwrite($fp, json_encode($notification));
            @fclose($fp);
        }
    } catch (Exception $e) {
        // Suppress WebSocket notification error to avoid blocking the REST response
    }

    sendSuccess('Order status updated successfully.', [
        'order_id' => $orderId,
        'status' => $status
    ]);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
