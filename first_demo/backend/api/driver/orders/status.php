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

    // If order is completed, check for previous pending tiffin returns from the same hotel
    $hasPendingTiffin = false;
    $pendingTiffinOrder = null;
    if ($status === 'completed') {
        $pendingStmt = $pdo->prepare("
            SELECT order_id, hotel_id 
            FROM orders 
            WHERE customer_id = ? 
              AND hotel_id = ? 
              AND tiffin_received_to_hotel = 'pending' 
              AND order_id < ? 
              AND status = 'completed'
            ORDER BY order_id ASC 
            LIMIT 1
        ");
        $pendingStmt->execute([$customerId, $hotelId, $orderId]);
        $pendingTiffinOrder = $pendingStmt->fetch(PDO::FETCH_ASSOC);
        
        if ($pendingTiffinOrder) {
            $hasPendingTiffin = true;
            // Generate 4-digit OTP
            $otp = strval(rand(1000, 9999));
            // Store OTP in database
            $otpStmt = $pdo->prepare("UPDATE orders SET tiffin_return_otp = ? WHERE order_id = ?");
            $otpStmt->execute([$otp, $pendingTiffinOrder['order_id']]);
            $pendingTiffinOrder['otp'] = $otp;
        }
    }

    // ── Send real-time notification to WebSocket server ─────────────────
    try {
        // Send ORDER_STATUS_UPDATED event
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

        // If there's a pending tiffin, send the PENDING_TIFFIN_RETURN event in a new connection
        if ($hasPendingTiffin && $pendingTiffinOrder) {
            // Fetch hotel name
            $hotelStmt = $pdo->prepare("SELECT hotel_name FROM hotels WHERE id = ?");
            $hotelStmt->execute([$hotelId]);
            $hotelName = $hotelStmt->fetchColumn() ?: 'Restaurant';

            $fpTiffin = @fsockopen("127.0.0.1", 8081, $errno, $errstr, 1);
            if ($fpTiffin) {
                $tiffinNotification = [
                    'system_event' => true,
                    'secret' => 'first_demo_system_websocket_secret_key_2026',
                    'event' => 'PENDING_TIFFIN_RETURN',
                    'data' => [
                        'previous_order_id' => (int)$pendingTiffinOrder['order_id'],
                        'current_order_id' => $orderId,
                        'customer_id' => $customerId,
                        'driver_id' => $driverId,
                        'hotel_id' => $hotelId,
                        'hotel_name' => $hotelName,
                        'otp' => $pendingTiffinOrder['otp']
                    ]
                ];
                @fwrite($fpTiffin, json_encode($tiffinNotification));
                @fclose($fpTiffin);
            }
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
