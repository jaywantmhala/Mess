<?php
/**
 * POST /api/vendor/orders/assign
 * Vendor assigns an order to an online driver.
 * Requires: Authorization: Bearer <JWT> (Vendor role required)
 * Body: { order_id, driver_id }
 */

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
$driverId = isset($input['driver_id']) ? (int)$input['driver_id'] : 0;

if ($orderId <= 0 || $driverId <= 0) {
    sendError('Required fields: order_id and driver_id.', 400);
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

    // Check if driver exists and is online
    $driverStmt = $pdo->prepare("SELECT id, full_name FROM drivers WHERE id = ? AND is_online = 1 LIMIT 1");
    $driverStmt->execute([$driverId]);
    $driver = $driverStmt->fetch(PDO::FETCH_ASSOC);

    if (!$driver) {
        sendError('Driver is offline or does not exist.', 422);
    }

    // Update order status and assign driver
    $updateStmt = $pdo->prepare("
        UPDATE orders 
        SET driver_id = ?, status = 'assigned', updated_at = NOW() 
        WHERE order_id = ?
    ");
    $updateStmt->execute([$driverId, $orderId]);

    $customerId = (int)$order['customer_id'];
    $hotelId = (int)$order['hotel_id'];

    // Fetch additional info for the driver's notification
    $hotelStmt = $pdo->prepare("SELECT hotel_name, grand_total FROM hotels h JOIN orders o ON o.hotel_id = h.id WHERE o.order_id = ? LIMIT 1");
    $hotelStmt->execute([$orderId]);
    $orderExtra = $hotelStmt->fetch(PDO::FETCH_ASSOC);
    $hotelName = $orderExtra['hotel_name'] ?? 'Restaurant';
    $grandTotal = (float)($orderExtra['grand_total'] ?? 0.0);

    // ── Send system notifications to WebSocket server ─────────────────
    try {
        // Event 1: Notify driver of new assignment (with full order details)
        $fp1 = @fsockopen("127.0.0.1", 8081, $errno, $errstr, 1);
        if ($fp1) {
            $notifDriver = [
                'system_event' => true,
                'secret' => 'first_demo_system_websocket_secret_key_2026',
                'event' => 'ORDER_ASSIGNED',
                'data' => [
                    'order_id'   => $orderId,
                    'driver_id'  => $driverId,
                    'hotel_id'   => $hotelId,
                    'hotel_name' => $hotelName,
                    'grand_total'=> $grandTotal,
                    'status'     => 'assigned',
                ]
            ];
            @fwrite($fp1, json_encode($notifDriver));
            @fclose($fp1);
        }

        // Event 2: Broadcast status change
        $fp2 = @fsockopen("127.0.0.1", 8081, $errno, $errstr, 1);
        if ($fp2) {
            $notifStatus = [
                'system_event' => true,
                'secret' => 'first_demo_system_websocket_secret_key_2026',
                'event' => 'ORDER_STATUS_UPDATED',
                'data' => [
                    'order_id' => $orderId,
                    'customer_id' => $customerId,
                    'hotel_id' => $hotelId,
                    'status' => 'assigned'
                ]
            ];
            @fwrite($fp2, json_encode($notifStatus));
            @fclose($fp2);
        }
    } catch (Exception $e) {
        // Suppress WebSocket notification error to avoid blocking the REST response
    }

    sendSuccess('Order assigned to driver successfully.', [
        'order_id' => $orderId,
        'driver_id' => $driverId,
        'status' => 'assigned'
    ]);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
