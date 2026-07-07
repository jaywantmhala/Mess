<?php
/**
 * POST /api/driver/orders/tiffin_verify
 * Verifies the 4-digit OTP for tiffin return.
 * Requires: Authorization: Bearer <JWT>
 * Body: { order_id, otp }
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
$otp = isset($input['otp']) ? trim($input['otp']) : '';

if ($orderId <= 0 || empty($otp)) {
    sendError('Required fields: order_id and otp.', 400);
}

try {
    $pdo = getDBConnection();
    
    // Start Transaction for Race-Condition Protection
    $pdo->beginTransaction();

    // Lock the row for update
    $checkStmt = $pdo->prepare("
        SELECT order_id, customer_id, hotel_id, status, tiffin_received_to_hotel, tiffin_return_otp 
        FROM orders 
        WHERE order_id = ?
        FOR UPDATE
    ");
    $checkStmt->execute([$orderId]);
    $order = $checkStmt->fetch(PDO::FETCH_ASSOC);

    if (!$order) {
        $pdo->rollBack();
        sendError('Order not found.', 404);
    }

    if ($order['status'] !== 'completed') {
        $pdo->rollBack();
        sendError('Tiffin return can only be verified for completed (delivered) orders.', 400);
    }

    if ($order['tiffin_received_to_hotel'] === 'received') {
        $pdo->rollBack();
        sendError('Tiffin return has already been verified for this order.', 400);
    }

    if ($order['tiffin_return_otp'] !== $otp) {
        $pdo->rollBack();
        sendError('Invalid OTP. Please try again.', 400);
    }

    $customerId = (int)$order['customer_id'];
    $hotelId = (int)$order['hotel_id'];

    // Update orders table
    $updateStmt = $pdo->prepare("
        UPDATE orders 
        SET tiffin_received_to_hotel = 'received',
            tiffin_returned_driver_id = ?,
            tiffin_returned_at = NOW(),
            updated_at = NOW()
        WHERE order_id = ?
    ");
    $updateStmt->execute([$driverId, $orderId]);

    // Insert log details
    $logDetails = "Tiffin return verified successfully via OTP: $otp by Driver ID: $driverId";
    $logStmt = $pdo->prepare("
        INSERT INTO tiffin_return_logs (order_id, driver_id, customer_id, hotel_id, otp, verified_at, log_details)
        VALUES (?, ?, ?, ?, ?, NOW(), ?)
    ");
    $logStmt->execute([$orderId, $driverId, $customerId, $hotelId, $otp, $logDetails]);

    // Commit Transaction
    $pdo->commit();

    // ── Send real-time notification to WebSocket server ─────────────────
    try {
        $fp = @fsockopen("127.0.0.1", 8081, $errno, $errstr, 1);
        if ($fp) {
            $notification = [
                'system_event' => true,
                'secret' => 'first_demo_system_websocket_secret_key_2026',
                'event' => 'TIFFIN_RETURN_CONFIRMED',
                'data' => [
                    'order_id' => $orderId,
                    'customer_id' => $customerId,
                    'driver_id' => $driverId,
                    'hotel_id' => $hotelId
                ]
            ];
            @fwrite($fp, json_encode($notification));
            @fclose($fp);
        }
    } catch (Exception $e) {
        // Suppress WebSocket notification error to avoid blocking the REST response
    }

    sendSuccess('Tiffin return verified and completed successfully.', [
        'order_id' => $orderId,
        'tiffin_received_to_hotel' => 'received'
    ]);

} catch (PDOException $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    sendError('Database error: ' . $e->getMessage(), 500);
}
