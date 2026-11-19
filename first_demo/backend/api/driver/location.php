<?php
// backend/api/driver/location.php

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/jwt.php';
require_once __DIR__ . '/../../helpers/ably_helper.php';
require_once __DIR__ . '/../../helpers/redis_helper.php';

function getDistanceInMeters($lat1, $lon1, $lat2, $lon2) {
    $earthRadius = 6371000;
    $latFrom = deg2rad($lat1);
    $lonFrom = deg2rad($lon1);
    $latTo = deg2rad($lat2);
    $lonTo = deg2rad($lon2);
    $latDelta = $latTo - $latFrom;
    $lonDelta = $lonTo - $lonFrom;
    $angle = 2 * asin(sqrt(pow(sin($latDelta / 2), 2) +
      cos($latFrom) * cos($latTo) * pow(sin($lonDelta / 2), 2)));
    return $angle * $earthRadius;
}

try {
    $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (!preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
        sendError('Unauthorized - No token provided', 401);
    }

    $token = $matches[1];
    $payload = JWT::verify($token);
    if (!$payload || ($payload['role'] ?? '') !== 'driver') {
        sendError('Unauthorized - Invalid driver token', 401);
    }

    $driverId = (int)$payload['sub'];
    $data = json_decode(file_get_contents('php://input'), true);

    $lat = (float)($data['latitude'] ?? 0.0);
    $lng = (float)($data['longitude'] ?? 0.0);

    if ($lat == 0.0 && $lng == 0.0) {
        sendError('Invalid coordinates', 400);
    }

    // 0. Update Redis high-speed in-memory GPS cache
    RedisHelper::updateDriverLocation($driverId, $lat, $lng);

    $pdo = getDBConnection();

    // 1. Update driver's last known location
    $stmt = $pdo->prepare("UPDATE drivers SET latitude = ?, longitude = ? WHERE id = ?");
    $stmt->execute([$lat, $lng, $driverId]);

    // 2. Fetch active orders for driver
    $stmt = $pdo->prepare("
        SELECT o.order_id, o.customer_id, ca.latitude as cust_lat, ca.longitude as cust_lng,
               d.full_name, d.phone_number, d.vehicle_number
        FROM orders o
        LEFT JOIN customer_addresses ca ON o.customer_id = ca.customer_id
        JOIN drivers d ON o.driver_id = d.id
        WHERE o.driver_id = ? AND o.status IN ('assigned', 'accepted_by_driver', 'picked_up', 'arrived_at_customer')
    ");
    $stmt->execute([$driverId]);
    $activeOrders = $stmt->fetchAll(PDO::FETCH_ASSOC);

    foreach ($activeOrders as $order) {
        $orderId = (int)$order['order_id'];
        $customerId = (int)$order['customer_id'];
        $custLat = $order['cust_lat'] ? (float)$order['cust_lat'] : 18.5204;
        $custLng = $order['cust_lng'] ? (float)$order['cust_lng'] : 73.8567;

        $distance = getDistanceInMeters($lat, $lng, $custLat, $custLng);
        $eta = max(1, (int)round($distance / 416.7)); // 25 km/h avg speed (416.7 m/min)

        $eventPayload = [
            'order_id'       => $orderId,
            'customer_id'    => $customerId,
            'driver_id'      => $driverId,
            'latitude'       => $lat,
            'longitude'      => $lng,
            'distance'       => $distance,
            'eta'            => $eta,
            'driver_name'    => $order['full_name'],
            'driver_phone'   => $order['phone_number'],
            'vehicle_number' => $order['vehicle_number']
        ];

        $orderChannel1 = AblyHelper::getOrderChannel($orderId);
        $orderChannel2 = "order_{$orderId}";
        AblyHelper::publish('DRIVER_LOCATION_UPDATED', $eventPayload, $orderChannel1);
        AblyHelper::publish('DRIVER_LOCATION_UPDATED', $eventPayload, $orderChannel2);
        AblyHelper::publish('DRIVER_LOCATION_UPDATED', $eventPayload, AblyHelper::getDefaultChannel());
    }

    sendSuccess('Location updated successfully', [
        'latitude' => $lat,
        'longitude' => $lng
    ]);

} catch (Exception $e) {
    sendError('Error updating location: ' . $e->getMessage(), 500);
}
