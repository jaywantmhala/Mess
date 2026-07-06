<?php
/**
 * POST /api/driver/orders/status
 * Updates the status of an assigned order.
 * Requires: Authorization: Bearer <JWT>
 * Body: { order_id, status }
 */

header('Content-Type: application/json; charset=utf-8');

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/jwt.php';
require_once __DIR__ . '/../../../helpers/response.php';

// ── JWT Authentication ────────────────────────────────────────────────────────
$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || ($payload['role'] ?? '') !== 'driver') {
    sendError('Unauthorized access. Driver token required.', 401);
}

$driverId = (int)$payload['sub'];

// Read JSON input
$input = json_decode(file_get_contents('php://input'), true);
$orderId = isset($input['order_id']) ? (int)$input['order_id'] : 0;
$status = isset($input['status']) ? trim($input['status']) : '';

if ($orderId <= 0 || empty($status)) {
    sendError('Required fields: order_id and status.', 400);
}

// Validate status enum
$validStatuses = ['accepted_by_driver', 'picked_up', 'completed'];
if (!in_array($status, $validStatuses)) {
    sendError('Invalid order status. Allowed: ' . implode(', ', $validStatuses), 400);
}

try {
    $pdo = getDBConnection();
    
    // Check if order exists and belongs to this driver
    $checkStmt = $pdo->prepare("
        SELECT driver_id, customer_id, hotel_id 
        FROM orders 
        WHERE order_id = ?
    ");
    $checkStmt->execute([$orderId]);
    $order = $checkStmt->fetch(PDO::FETCH_ASSOC);

    if (!$order) {
        sendError('Order not found.', 404);
    }

    if ((int)$order['driver_id'] !== $driverId) {
        sendError('Forbidden. This order is not assigned to you.', 403);
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
