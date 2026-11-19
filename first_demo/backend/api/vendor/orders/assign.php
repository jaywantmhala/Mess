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
require_once __DIR__ . '/../../../helpers/ably_helper.php';


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

function calcDistanceKm($lat1, $lon1, $lat2, $lon2) {
    if ($lat1 == 0 || $lon1 == 0 || $lat2 == 0 || $lon2 == 0) return 0.0;
    $earthRadius = 6371; // in km
    $dLat = deg2rad($lat2 - $lat1);
    $dLon = deg2rad($lon2 - $lon1);
    $a = sin($dLat/2) * sin($dLat/2) + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLon/2) * sin($dLon/2);
    $c = 2 * atan2(sqrt($a), sqrt(1-$a));
    return round($earthRadius * $c, 2);
}

try {
    $pdo = getDBConnection();
    
    // Check if order exists and belongs to this vendor
    $checkStmt = $pdo->prepare("
        SELECT o.status, o.customer_id, o.hotel_id, o.grand_total, o.delivery_fee, o.delivery_address, h.vendor_id, h.hotel_name, h.hotel_address, h.latitude as hotel_lat, h.longitude as hotel_lng
        FROM orders o
        JOIN hotels h ON o.hotel_id = h.id
        WHERE o.order_id = ?
    ");
    $checkStmt->execute([$orderId]);
    $order = $checkStmt->fetch(PDO::FETCH_ASSOC);

    if (!$order) {
        sendError('Order not found.', 404);
    }

    if ((int)$order['vendor_id'] !== $vendorId) {
        sendError('Forbidden. You do not manage this hotel\'s orders.', 403);
    }

    // Check if driver exists
    $driverStmt = $pdo->prepare("SELECT id, full_name, latitude, longitude FROM drivers WHERE id = ? LIMIT 1");
    $driverStmt->execute([$driverId]);
    $driver = $driverStmt->fetch(PDO::FETCH_ASSOC);

    if (!$driver) {
        sendError('Driver does not exist.', 422);
    }

    // ── Enforce Single Active Order Per Driver Constraint ──────────────────────
    $activeOrderStmt = $pdo->prepare("
        SELECT order_id 
        FROM orders 
        WHERE driver_id = ? 
          AND status IN ('assigned', 'accepted_by_driver', 'picked_up') 
        LIMIT 1
    ");
    $activeOrderStmt->execute([$driverId]);
    $activeOrder = $activeOrderStmt->fetch(PDO::FETCH_ASSOC);

    if ($activeOrder) {
        $driverName = $driver['full_name'] ?? 'Driver';
        $activeId = $activeOrder['order_id'];
        sendError("{$driverName} already has an active order (#{$activeId}). Next order can only be assigned after the current order is delivered.", 422);
    }

    // Update order status and assign driver
    $updateStmt = $pdo->prepare("
        UPDATE orders 
        SET driver_id = ?, status = 'assigned', updated_at = NOW() 
        WHERE order_id = ?
    ");
    $updateStmt->execute([$driverId, $orderId]);

    $customerId      = (int)$order['customer_id'];
    $hotelId         = (int)$order['hotel_id'];
    $hotelName       = $order['hotel_name'] ?? 'Restaurant';
    $hotelAddress    = $order['hotel_address'] ?? 'Hotel Address';
    $deliveryAddress = $order['delivery_address'] ?? 'Customer Delivery Address';
    $grandTotal      = (float)($order['grand_total'] ?? 0.0);
    $deliveryFee     = (float)($order['delivery_fee'] ?? 0.0);
    $hotelLat        = (float)($order['hotel_lat'] ?? 0.0);
    $hotelLng        = (float)($order['hotel_lng'] ?? 0.0);

    $driverLat = (float)($driver['latitude'] ?? 0.0);
    $driverLng = (float)($driver['longitude'] ?? 0.0);

    // Customer address location
    $custAddrStmt = $pdo->prepare("SELECT latitude, longitude FROM customer_addresses WHERE customer_id = ? LIMIT 1");
    $custAddrStmt->execute([$customerId]);
    $custAddr = $custAddrStmt->fetch(PDO::FETCH_ASSOC);
    $custLat = $custAddr ? (float)$custAddr['latitude'] : 0.0;
    $custLng = $custAddr ? (float)$custAddr['longitude'] : 0.0;

    $pickupDistanceKm = calcDistanceKm($driverLat, $driverLng, $hotelLat, $hotelLng);
    if ($pickupDistanceKm <= 0) $pickupDistanceKm = 1.85;

    $dropDistanceKm = calcDistanceKm($hotelLat, $hotelLng, $custLat, $custLng);
    if ($dropDistanceKm <= 0) $dropDistanceKm = 4.25;

    $driverEarning = $deliveryFee > 0 ? $deliveryFee : round(35.0 + ($dropDistanceKm * 6.0), 2);
    $incentive = round($driverEarning * 0.20, 2);

    // ── Send system notifications via Ably ─────────────────
    try {
        $assignmentPayload = [
            'order_id'        => $orderId,
            'driver_id'       => $driverId,
            'hotel_id'        => $hotelId,
            'hotel_name'      => $hotelName,
            'pickup_address'  => $hotelAddress,
            'drop_address'    => $deliveryAddress,
            'grand_total'     => $grandTotal,
            'driver_earning'  => $driverEarning,
            'incentive'       => $incentive,
            'pickup_distance' => $pickupDistanceKm,
            'drop_distance'   => $dropDistanceKm,
            'status'          => 'assigned',
        ];
        // Event 1: Notify assigned driver on driver_{driverId} channel
        AblyHelper::publishDriverAssignment($driverId, $assignmentPayload);

        // Event 2: Broadcast status change to order tracking channel order_{orderId} and vendor channel vendor_{vendorId}
        $statusData = [
            'order_id'    => $orderId,
            'customer_id' => $customerId,
            'hotel_id'    => $hotelId,
            'vendor_id'   => $vendorId,
            'driver_id'   => $driverId,
            'status'      => 'assigned'
        ];
        AblyHelper::publishOrderUpdate($orderId, $statusData);
        AblyHelper::publish('ORDER_STATUS_UPDATED', $statusData, AblyHelper::getVendorChannel($vendorId));

        // Send FCM Notifications
        require_once __DIR__ . '/../../../helpers/fcm.php';
        // Notify Driver
        FcmHelper::sendToDriver($driverId, "New Order Assigned", "Order #$orderId is assigned to you. Pick up from $hotelName.", [
            'order_id'  => (string)$orderId,
            'driver_id' => (string)$driverId,
            'event'     => 'ORDER_ASSIGNED',
            'status'    => 'assigned'
        ]);
        // Notify Customer
        $driverName = $driver['full_name'] ?? 'Driver';
        FcmHelper::sendToCustomer($customerId, "Order Assigned", "Your order #$orderId has been assigned to driver $driverName.", [
            'order_id'  => (string)$orderId,
            'event'     => 'ORDER_STATUS_UPDATED',
            'status'    => 'assigned'
        ]);
    } catch (Throwable $e) {
        error_log("Notification error in assign.php: " . $e->getMessage());
    }

    sendSuccess('Order assigned to driver successfully.', [
        'order_id' => $orderId,
        'driver_id' => $driverId,
        'status' => 'assigned'
    ]);

} catch (Throwable $e) {
    sendError('Database or system error: ' . $e->getMessage(), 500);
}
