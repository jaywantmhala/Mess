<?php
// backend/api/vendor/orders/list.php
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

try {
    $pdo = getDBConnection();
    
    // Fetch all orders for hotels owned by this vendor
    $stmt = $pdo->prepare("
        SELECT o.order_id, o.customer_id, o.hotel_id, o.subtotal, o.delivery_fee, 
               o.tax_amount, o.grand_total, o.wallet_deducted, o.payment_method, 
               o.delivery_address, o.status, o.created_at, o.updated_at,
               c.full_name AS customer_name, c.email AS customer_email, h.hotel_name
        FROM orders o
        JOIN hotels h ON o.hotel_id = h.id
        JOIN customers c ON o.customer_id = c.id
        WHERE h.vendor_id = ?
        ORDER BY o.order_id DESC
    ");
    $stmt->execute([$vendorId]);
    $orders = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Fetch order items for each order
    $itemStmt = $pdo->prepare("
        SELECT oi.order_item_id, oi.menu_item_id, oi.quantity, oi.price, m.food_name
        FROM order_items oi
        JOIN menus m ON oi.menu_item_id = m.id
        WHERE oi.order_id = ?
    ");

    $result = [];
    foreach ($orders as $order) {
        $orderId = (int)$order['order_id'];
        $itemStmt->execute([$orderId]);
        $items = $itemStmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Map types correctly
        $order['order_id'] = $orderId;
        $order['customer_id'] = (int)$order['customer_id'];
        $order['hotel_id'] = (int)$order['hotel_id'];
        $order['subtotal'] = (float)$order['subtotal'];
        $order['delivery_fee'] = (float)$order['delivery_fee'];
        $order['tax_amount'] = (float)$order['tax_amount'];
        $order['grand_total'] = (float)$order['grand_total'];
        $order['wallet_deducted'] = (float)$order['wallet_deducted'];
        $order['items'] = array_map(function($i) {
            return [
                'order_item_id' => (int)$i['order_item_id'],
                'menu_item_id' => (int)$i['menu_item_id'],
                'quantity' => (int)$i['quantity'],
                'price' => (float)$i['price'],
                'food_name' => $i['food_name']
            ];
        }, $items);

        $result[] = $order;
    }

    sendSuccess('Orders fetched successfully.', $result);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
