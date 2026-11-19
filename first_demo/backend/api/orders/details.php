<?php
/**
 * GET /api/orders/details
 *
 * Retrieves full details for a specific order.
 * Query Parameters: order_id
 * Header: Authorization: Bearer <token>
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'GET') { sendError('Method not allowed. Use GET.', 405); }

// JWT Auth
$token = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;
if (!$payload || !isset($payload['sub'])) { sendError('Unauthorized. Please log in again.', 401); }
$customerId = (int)$payload['sub'];

$orderId = isset($_GET['order_id']) ? (int)$_GET['order_id'] : 0;
if ($orderId <= 0) { sendError('Order ID is required.', 422); }

try {
    $pdo = getDBConnection();

    // Fetch order
    $stmt = $pdo->prepare("SELECT * FROM orders WHERE order_id = :order_id AND customer_id = :customer_id LIMIT 1");
    $stmt->execute([
        ':order_id' => $orderId,
        ':customer_id' => $customerId
    ]);
    $order = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$order) {
        sendError('Order not found.', 404);
    }

    // Fetch hotel
    $stmt = $pdo->prepare("SELECT * FROM hotels WHERE id = :hotel_id LIMIT 1");
    $stmt->execute([':hotel_id' => $order['hotel_id']]);
    $hotel = $stmt->fetch(PDO::FETCH_ASSOC);

    // Fetch customer address coordinates
    $stmt = $pdo->prepare("SELECT latitude, longitude FROM customer_addresses WHERE customer_id = :customer_id ORDER BY is_default DESC, id DESC LIMIT 1");
    $stmt->execute([':customer_id' => $customerId]);
    $custAddr = $stmt->fetch(PDO::FETCH_ASSOC);

    // Fetch driver details if assigned
    $driver = null;
    if ($order['driver_id']) {
        $stmt = $pdo->prepare("SELECT id, full_name, phone_number, vehicle_number, latitude, longitude FROM drivers WHERE id = ? LIMIT 1");
        $stmt->execute([$order['driver_id']]);
        $driver = $stmt->fetch(PDO::FETCH_ASSOC);
    }

    // Fetch order items with food names and mandatory/optional customizations
    $stmt = $pdo->prepare("
        SELECT oi.price, oi.quantity, oi.customizations,
               COALESCE(oi.mandatory_items, m.mandatory_items) AS mandatory_items,
               COALESCE(m.food_name, 'Food Item') AS food_name
        FROM order_items oi
        LEFT JOIN menus m ON m.id = oi.menu_item_id
        WHERE oi.order_id = :order_id
    ");
    $stmt->execute([':order_id' => $orderId]);
    $items = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Calculate subtotal from items
    $subtotal = 0;
    foreach ($items as $item) {
        $subtotal += $item['price'] * $item['quantity'];
    }

    // Prepare response
    $data = [
        'order_id' => (int)$order['order_id'],
        'status' => $order['status'],
        'meal_type' => $order['meal_type'] ?? 'Lunch',
        'subtotal' => (float)$subtotal,
        'delivery_fee' => (float)$order['delivery_fee'],
        'tax_amount' => (float)$order['tax_amount'],
        'grand_total' => (float)$order['grand_total'],
        'wallet_deducted' => (float)$order['wallet_deducted'],
        'tiffin_charge' => (float)($order['tiffin_charge'] ?? 50.00),
        'payment_method' => $order['payment_method'],
        'delivery_address' => $order['delivery_address'],
        'created_at' => $order['created_at'],
        'delivery_otp' => $order['delivery_otp'],
        'delivered_at' => $order['delivered_at'],
        'hotel' => [
            'id' => (int)$hotel['id'],
            'hotel_name' => $hotel['hotel_name'],
            'hotel_address' => $hotel['hotel_address'],
            'phone_number' => $hotel['mobile_number'] ?? '',
            'rating' => '4.0', // Default rating representation
            'photo_url' => $hotel['photo_url'] ? $hotel['photo_url'] : '',
            'latitude' => (float)$hotel['latitude'],
            'longitude' => (float)$hotel['longitude']
        ],
        'customer' => [
            'latitude' => $custAddr ? (float)$custAddr['latitude'] : 18.5204,
            'longitude' => $custAddr ? (float)$custAddr['longitude'] : 73.8567
        ],
        'items' => array_map(function($i) {
            $mList = [];
            if (!empty($i['mandatory_items'])) {
                $mDec = json_decode($i['mandatory_items'], true);
                if (is_array($mDec)) $mList = $mDec;
            }
            $optList = [];
            if (!empty($i['customizations'])) {
                $optDec = json_decode($i['customizations'], true);
                if (is_array($optDec)) {
                    $isAssoc = (array_keys($optDec) !== range(0, count($optDec) - 1));
                    if ($isAssoc) {
                        foreach ($optDec as $k => $v) {
                            if (is_array($v)) $v = implode(', ', $v);
                            $optList[] = is_numeric($k) ? (string)$v : "$k: $v";
                        }
                    } else {
                        foreach ($optDec as $val) {
                            if (is_array($val)) {
                                foreach ($val as $k => $v) {
                                    $optList[] = is_numeric($k) ? (string)$v : "$k: $v";
                                }
                            } else {
                                $optList[] = (string)$val;
                            }
                        }
                    }
                } else if (is_string($i['customizations'])) {
                    $optList = [$i['customizations']];
                }
            }

            return [
                'food_name' => $i['food_name'],
                'quantity'  => (int)$i['quantity'],
                'price'     => (float)$i['price'],
                'mandatory_items' => $mList,
                'selected_optional_items' => $optList,
            ];
        }, $items),
        'delivery_partner' => $driver ? [
            'id' => (int)$driver['id'],
            'name' => $driver['full_name'],
            'rating' => '4.8',
            'avatar_url' => 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=200',
            'phone_number' => $driver['phone_number'],
            'vehicle_number' => $driver['vehicle_number'],
            'latitude' => (float)$driver['latitude'],
            'longitude' => (float)$driver['longitude']
        ] : null
    ];

    sendSuccess('Order details retrieved successfully.', $data);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
