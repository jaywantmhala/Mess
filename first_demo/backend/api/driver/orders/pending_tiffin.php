<?php
/**
 * GET /api/driver/orders/pending_tiffin
 * Checks if there is any pending tiffin return request for the authenticated driver.
 * Requires: Authorization: Bearer <JWT>
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'GET')     { sendError('Method not allowed. Use GET.', 405); }

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/jwt.php';

$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;
if (!$payload || !isset($payload['sub']) || ($payload['role'] ?? '') !== 'driver') {
    sendError('Unauthorized. Driver token required.', 401);
}

$driverId = (int)$payload['sub'];

try {
    $pdo = getDBConnection();

    $requestedCustomerId = isset($_GET['customer_id']) ? (int)$_GET['customer_id'] : 0;
    $requestedHotelId    = isset($_GET['hotel_id']) ? (int)$_GET['hotel_id'] : 0;

    if ($requestedCustomerId <= 0) {
        sendSuccess('No pending tiffin check without customer_id.', [
            'has_pending' => false
        ]);
        exit;
    }

    // Query for any completed order with pending tiffin return assigned to driver for the specified customer & hotel
    $sql = "
        SELECT 
            o.order_id AS previous_order_id,
            o.customer_id,
            o.hotel_id,
            o.tiffin_return_otp AS otp,
            h.hotel_name
        FROM orders o
        JOIN hotels h ON o.hotel_id = h.id
        WHERE o.tiffin_received_to_hotel = 'pending'
          AND o.status = 'completed'
          AND o.driver_id = :driver_id
          AND o.customer_id = :customer_id
    ";

    $params = [
        ':driver_id'   => $driverId,
        ':customer_id' => $requestedCustomerId,
    ];

    if ($requestedHotelId > 0) {
        $sql .= " AND o.hotel_id = :hotel_id ";
        $params[':hotel_id'] = $requestedHotelId;
    }

    $sql .= " ORDER BY o.order_id DESC LIMIT 1";

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $pending = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($pending) {
        // If OTP is null, generate one
        if (empty($pending['otp'])) {
            $otp = strval(rand(1000, 9999));
            $otpStmt = $pdo->prepare("UPDATE orders SET tiffin_return_otp = ? WHERE order_id = ?");
            $otpStmt->execute([$otp, $pending['previous_order_id']]);
            $pending['otp'] = $otp;
        }

        sendSuccess('Pending tiffin return found.', [
            'has_pending'       => true,
            'event'             => 'tiffin-return-required',
            'order_id'          => (int)$pending['previous_order_id'],
            'previous_order_id' => (int)$pending['previous_order_id'],
            'customer_id'       => (int)$pending['customer_id'],
            'driver_id'         => $driverId,
            'hotel_id'          => (int)$pending['hotel_id'],
            'hotel_name'        => $pending['hotel_name'],
            'message'           => "Previous Tiffin Return Required. Please return the previous tiffin from {$pending['hotel_name']}.",
            'action'            => 'SCAN_BARCODE',
            'otp'               => $pending['otp']
        ]);
    } else {
        sendSuccess('No pending tiffin return.', [
            'has_pending' => false
        ]);
    }

} catch (Throwable $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
