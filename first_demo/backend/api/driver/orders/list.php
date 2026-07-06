<?php
/**
 * GET /api/driver/orders
 * Returns list of orders assigned to the authenticated driver.
 * Requires: Authorization: Bearer <JWT>
 */

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'GET')     { sendError('Method not allowed. Use GET.', 405); }

$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;
if (!$payload || !isset($payload['sub']) || ($payload['role'] ?? '') !== 'driver') {
    sendError('Unauthorized. Please log in again.', 401);
}

$driverId = (int)$payload['sub'];

$pdo = getDBConnection();
$stmt = $pdo->prepare("
    SELECT 
        o.order_id, 
        o.status, 
        o.grand_total, 
        o.payment_method, 
        o.delivery_address, 
        o.created_at,
        h.hotel_name, 
        h.hotel_address, 
        h.latitude as hotel_lat, 
        h.longitude as hotel_lng,
        c.latitude as customer_lat, 
        c.longitude as customer_lng, 
        cust.full_name as customer_name
    FROM orders o
    JOIN hotels h ON o.hotel_id = h.id
    JOIN customers cust ON o.customer_id = cust.id
    LEFT JOIN customer_addresses c ON o.customer_id = c.customer_id
    WHERE o.driver_id = :driver_id
    ORDER BY o.order_id DESC
");
$stmt->execute([':driver_id' => $driverId]);
$orders = $stmt->fetchAll(PDO::FETCH_ASSOC);

// Map output types
foreach ($orders as &$order) {
    $order['order_id'] = (int)$order['order_id'];
    $order['grand_total'] = (float)$order['grand_total'];
    $order['hotel_lat'] = (float)$order['hotel_lat'];
    $order['hotel_lng'] = (float)$order['hotel_lng'];
    $order['customer_lat'] = $order['customer_lat'] ? (float)$order['customer_lat'] : 18.5204;
    $order['customer_lng'] = $order['customer_lng'] ? (float)$order['customer_lng'] : 73.8567;
}

sendSuccess('Assigned orders retrieved.', ['orders' => $orders]);
