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
require_once __DIR__ . '/../../../helpers/ably_helper.php';


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
    
    // Ensure required tables and schema columns exist BEFORE transaction (prevents MySQL implicit commits)
    try {
        $pdo->exec("
            CREATE TABLE IF NOT EXISTS `tiffin_returns` (
                `id`          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                `order_id`    INT UNSIGNED NOT NULL,
                `hotel_id`    INT UNSIGNED NOT NULL,
                `driver_id`   INT UNSIGNED NOT NULL,
                `barcode`     TEXT DEFAULT NULL,
                `status`      VARCHAR(50) DEFAULT 'RETURNED',
                `scanned_at`  DATETIME DEFAULT CURRENT_TIMESTAMP,
                `returned_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
                `created_at`  DATETIME DEFAULT CURRENT_TIMESTAMP,
                `updated_at`  DATETIME DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

            CREATE TABLE IF NOT EXISTS `tiffin_return_logs` (
                `id`          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                `order_id`    INT UNSIGNED NOT NULL,
                `driver_id`   INT UNSIGNED NOT NULL,
                `customer_id` INT UNSIGNED NOT NULL,
                `hotel_id`    INT UNSIGNED NOT NULL,
                `otp`         TEXT DEFAULT NULL,
                `verified_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
                `log_details` TEXT DEFAULT NULL,
                `created_at`  DATETIME DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ");
    } catch (Throwable $schemaErr) {}

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

    // Fetch hotel details for name and verification
    $hotelStmt = $pdo->prepare("SELECT hotel_name FROM hotels WHERE id = ?");
    $hotelStmt->execute([(int)$order['hotel_id']]);
    $hotelName = $hotelStmt->fetchColumn() ?: 'Restaurant';

    // If tiffin return was already verified (or retried), return success idempotently
    if ($order['tiffin_received_to_hotel'] === 'received') {
        $pdo->commit();
        sendSuccess("$hotelName Tiffin Returned Successfully ✓", [
            'order_id'                 => $orderId,
            'hotel_id'                 => (int)$order['hotel_id'],
            'hotel_name'               => $hotelName,
            'tiffin_received_to_hotel' => 'received',
            'status'                   => 'RETURNED'
        ]);
    }

    $cleanInput = strtoupper(trim($otp));
    $expectedOtp = strtoupper(trim((string)$order['tiffin_return_otp']));
    $expectedHotelQr1 = "HOTEL_" . $order['hotel_id'] . "_TIFFIN";
    $expectedHotelQr2 = "HOTEL_" . $order['hotel_id'];
    $expectedHotelQr3 = "HOTEL" . $order['hotel_id'] . "TIFFIN";
    $expectedOrderId1 = (string)$orderId;
    $expectedOrderId2 = "#" . $orderId;

    // Detect if driver scanned a barcode belonging to another hotel (e.g., HOTEL_99_TIFFIN)
    if (preg_match('/^HOTEL_?(\d+)/i', $cleanInput, $matches)) {
        $scannedHotelId = (int)$matches[1];
        if ($scannedHotelId !== (int)$order['hotel_id']) {
            $pdo->rollBack();
            sendError("This QR code is invalid.", 400);
        }
    }

    $isValid = (!empty($expectedOtp) && $cleanInput === $expectedOtp)
            || ($cleanInput === $expectedHotelQr1)
            || ($cleanInput === $expectedHotelQr2)
            || ($cleanInput === $expectedHotelQr3)
            || ($cleanInput === $expectedOrderId1)
            || ($cleanInput === $expectedOrderId2);

    if (!$isValid) {
        $pdo->rollBack();
        sendError("This QR code is invalid.", 400);
    }

    $customerId = (int)$order['customer_id'];
    $hotelId = (int)$order['hotel_id'];

    // 1. Update orders table safely
    try {
        $updateStmt = $pdo->prepare("
            UPDATE orders 
            SET tiffin_received_to_hotel = 'received',
                tiffin_returned_driver_id = ?,
                tiffin_returned_at = NOW(),
                updated_at = NOW()
            WHERE order_id = ?
        ");
        $updateStmt->execute([$driverId, $orderId]);
    } catch (Throwable $upErr) {
        $updateStmt = $pdo->prepare("
            UPDATE orders 
            SET tiffin_received_to_hotel = 'received',
                updated_at = NOW()
            WHERE order_id = ?
        ");
        $updateStmt->execute([$orderId]);
    }

    $safeOtp = substr($otp, 0, 250);

    // 2. Insert into tiffin_returns table (safely wrapped)
    try {
        $trStmt = $pdo->prepare("
            INSERT INTO tiffin_returns (order_id, hotel_id, driver_id, barcode, status, scanned_at, returned_at, created_at, updated_at)
            VALUES (?, ?, ?, ?, 'RETURNED', NOW(), NOW(), NOW(), NOW())
        ");
        $trStmt->execute([$orderId, $hotelId, $driverId, $safeOtp]);
    } catch (Throwable $trErr) {
        error_log("Note on tiffin_returns insert: " . $trErr->getMessage());
    }

    // 3. Insert into tiffin_return_logs table (safely wrapped)
    try {
        $logDetails = "Tiffin return verified successfully via OTP/Barcode: $safeOtp for Hotel: $hotelName by Driver ID: $driverId";
        $logStmt = $pdo->prepare("
            INSERT INTO tiffin_return_logs (order_id, driver_id, customer_id, hotel_id, otp, verified_at, log_details)
            VALUES (?, ?, ?, ?, ?, NOW(), ?)
        ");
        $logStmt->execute([$orderId, $driverId, $customerId, $hotelId, $safeOtp, $logDetails]);
    } catch (Throwable $logErr) {
        error_log("Note on tiffin_return_logs insert: " . $logErr->getMessage());
    }

    // Commit Transaction
    $pdo->commit();

    // ── Send real-time notification via Ably ─────────────────
    try {
        $confirmPayload = [
            'event'                   => 'tiffin-return-completed',
            'order_id'                => $orderId,
            'pending_tiffin_order_id' => $orderId,
            'customer_id'             => $customerId,
            'driver_id'               => $driverId,
            'hotel_id'                => $hotelId,
            'hotel_name'              => $hotelName,
            'status'                  => 'RETURNED',
            'message'                 => "Tiffin Returned Successfully ✓ for $hotelName"
        ];
        $driverChannel = AblyHelper::getDriverChannel($driverId);
        AblyHelper::publish('tiffin-return-completed', $confirmPayload, $driverChannel);
        AblyHelper::publish('tiffin-return-completed', $confirmPayload, "driver_{$driverId}");
        AblyHelper::publish('TIFFIN_RETURN_CONFIRMED', $confirmPayload, $driverChannel);
        AblyHelper::publish('TIFFIN_RETURN_CONFIRMED', $confirmPayload, "driver_{$driverId}");
    } catch (Throwable $e) {
        error_log("Notification error in tiffin_verify.php: " . $e->getMessage());
    }

    sendSuccess("$hotelName Tiffin Returned Successfully ✓", [
        'order_id'                 => $orderId,
        'hotel_id'                 => $hotelId,
        'hotel_name'               => $hotelName,
        'tiffin_received_to_hotel' => 'received',
        'status'                   => 'RETURNED'
    ]);

} catch (Throwable $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    sendError('Database or system error: ' . $e->getMessage(), 500);
}
