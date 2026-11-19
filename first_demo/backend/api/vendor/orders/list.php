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
    
    $dateParam     = isset($_GET['date']) ? trim($_GET['date']) : '';
    $mealTypeParam = isset($_GET['meal_type']) ? trim($_GET['meal_type']) : '';

    // Fetch orders for hotels owned by this vendor (optionally filtered by date & meal_type)
    $sql = "
        SELECT o.order_id, o.customer_id, o.hotel_id, o.driver_id, o.subtotal, o.delivery_fee, 
               o.tax_amount, o.grand_total, o.wallet_deducted, o.payment_method, 
               o.delivery_address, o.status, o.created_at, o.updated_at,
               COALESCE(o.meal_type, 'Lunch') AS meal_type,
               COALESCE(c.full_name, 'Customer') AS customer_name, 
               COALESCE(c.email, '') AS customer_email, 
               COALESCE(c.phone_number, c.phone, '') AS customer_phone,
               COALESCE(h.hotel_name, 'Hotel') AS hotel_name,
               COALESCE(h.hotel_address, '') AS hotel_address,
               COALESCE(h.latitude, 0.0) AS hotel_latitude,
               COALESCE(h.longitude, 0.0) AS hotel_longitude,
               COALESCE(d.full_name, '') AS driver_name,
               COALESCE(d.phone_number, '') AS driver_phone,
               COALESCE(d.vehicle_number, '') AS vehicle_number,
               COALESCE(d.latitude, 0.0) AS driver_latitude,
               COALESCE(d.longitude, 0.0) AS driver_longitude,
               COALESCE(d.is_online, 0) AS driver_is_online,
               COALESCE(
                   (SELECT ca.latitude FROM customer_addresses ca WHERE ca.customer_id = o.customer_id AND (TRIM(ca.full_address) = TRIM(o.delivery_address) OR o.delivery_address LIKE CONCAT('%', ca.full_address, '%') OR ca.full_address LIKE CONCAT('%', o.delivery_address, '%')) ORDER BY (TRIM(ca.full_address) = TRIM(o.delivery_address)) DESC, ca.id DESC LIMIT 1),
                   (SELECT ca.latitude FROM customer_addresses ca WHERE (TRIM(ca.full_address) = TRIM(o.delivery_address) OR o.delivery_address LIKE CONCAT('%', ca.full_address, '%') OR ca.full_address LIKE CONCAT('%', o.delivery_address, '%')) ORDER BY (TRIM(ca.full_address) = TRIM(o.delivery_address)) DESC, ca.id DESC LIMIT 1),
                   (SELECT ca.latitude FROM customer_addresses ca WHERE ca.customer_id = o.customer_id AND ca.latitude != 0.0 ORDER BY ca.is_default DESC, ca.id DESC LIMIT 1),
                   c.latitude,
                   0.0
               ) AS customer_latitude,
               COALESCE(
                   (SELECT ca.longitude FROM customer_addresses ca WHERE ca.customer_id = o.customer_id AND (TRIM(ca.full_address) = TRIM(o.delivery_address) OR o.delivery_address LIKE CONCAT('%', ca.full_address, '%') OR ca.full_address LIKE CONCAT('%', o.delivery_address, '%')) ORDER BY (TRIM(ca.full_address) = TRIM(o.delivery_address)) DESC, ca.id DESC LIMIT 1),
                   (SELECT ca.longitude FROM customer_addresses ca WHERE (TRIM(ca.full_address) = TRIM(o.delivery_address) OR o.delivery_address LIKE CONCAT('%', ca.full_address, '%') OR ca.full_address LIKE CONCAT('%', o.delivery_address, '%')) ORDER BY (TRIM(ca.full_address) = TRIM(o.delivery_address)) DESC, ca.id DESC LIMIT 1),
                   (SELECT ca.longitude FROM customer_addresses ca WHERE ca.customer_id = o.customer_id AND ca.longitude != 0.0 ORDER BY ca.is_default DESC, ca.id DESC LIMIT 1),
                   c.longitude,
                   0.0
               ) AS customer_longitude
        FROM orders o
        LEFT JOIN hotels h ON o.hotel_id = h.id
        LEFT JOIN customers c ON o.customer_id = c.id
        LEFT JOIN drivers d ON o.driver_id = d.id
        WHERE (h.vendor_id = ? OR o.hotel_id IN (SELECT id FROM hotels WHERE vendor_id = ?))
    ";
    
    $params = [$vendorId, $vendorId];
    if ($dateParam !== '') {
        $sql .= " AND (DATE(o.created_at) = ? OR DATE(o.created_at) = CURDATE() OR o.status NOT IN ('delivered', 'cancelled')) ";
        $params[] = $dateParam;
    }

    if (!empty($mealTypeParam) && in_array(strtoupper($mealTypeParam), ['LUNCH', 'DINNER'])) {
        $sql .= " AND (o.meal_type = ? OR UPPER(o.meal_type) = ?) ";
        $params[] = ucfirst(strtolower($mealTypeParam));
        $params[] = strtoupper($mealTypeParam);
    }
    
    $sql .= " ORDER BY o.order_id DESC ";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $orders = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Fetch order items for each order
    $itemStmt = $pdo->prepare("
        SELECT oi.order_item_id, oi.menu_item_id, oi.quantity, oi.price, oi.customizations,
               COALESCE(oi.mandatory_items, m.mandatory_items) AS mandatory_items,
               COALESCE(m.food_name, 'Food Item') AS food_name
        FROM order_items oi
        LEFT JOIN menus m ON oi.menu_item_id = m.id
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
        $order['driver_id'] = $order['driver_id'] !== null ? (int)$order['driver_id'] : null;
        $order['driver_latitude'] = (float)$order['driver_latitude'];
        $order['driver_longitude'] = (float)$order['driver_longitude'];
        $order['hotel_latitude'] = (float)$order['hotel_latitude'];
        $order['hotel_longitude'] = (float)$order['hotel_longitude'];
        $order['customer_latitude'] = (float)$order['customer_latitude'];
        $order['customer_longitude'] = (float)$order['customer_longitude'];

        // Calculate actual customer distance from hotel (drop distance in km)
        $dropDistanceKm = 0.0;
        if (!empty($order['hotel_latitude']) && !empty($order['hotel_longitude']) && !empty($order['customer_latitude']) && !empty($order['customer_longitude'])) {
            $earthRadius = 6371; // km
            $dLat = deg2rad($order['customer_latitude'] - $order['hotel_latitude']);
            $dLon = deg2rad($order['customer_longitude'] - $order['hotel_longitude']);
            $a = sin($dLat / 2) * sin($dLat / 2) +
                 cos(deg2rad($order['hotel_latitude'])) * cos(deg2rad($order['customer_latitude'])) *
                 sin($dLon / 2) * sin($dLon / 2);
            $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
            $dropDistanceKm = round($earthRadius * $c, 2);
        }
        $order['distance_km'] = $dropDistanceKm;
        $order['drop_distance_km'] = $dropDistanceKm;

        $order['driver_is_online'] = (bool)$order['driver_is_online'];
        $order['subtotal'] = (float)$order['subtotal'];
        $order['delivery_fee'] = (float)$order['delivery_fee'];
        $order['tax_amount'] = (float)$order['tax_amount'];
        $order['grand_total'] = (float)$order['grand_total'];
        $order['wallet_deducted'] = (float)$order['wallet_deducted'];
        $order['items'] = array_map(function($i) {
            $mList = [];
            if (!empty($i['mandatory_items'])) {
                $mDecoded = json_decode($i['mandatory_items'], true);
                if (is_array($mDecoded)) $mList = $mDecoded;
            }
            $optList = [];
            if (!empty($i['customizations'])) {
                $optDecoded = json_decode($i['customizations'], true);
                if (is_array($optDecoded)) {
                    $isAssoc = (array_keys($optDecoded) !== range(0, count($optDecoded) - 1));
                    if ($isAssoc) {
                        foreach ($optDecoded as $k => $v) {
                            if (is_array($v)) $v = implode(', ', $v);
                            $optList[] = is_numeric($k) ? (string)$v : "$k: $v";
                        }
                    } else {
                        foreach ($optDecoded as $val) {
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
                'order_item_id' => (int)$i['order_item_id'],
                'menu_item_id'  => (int)$i['menu_item_id'],
                'quantity'      => (int)$i['quantity'],
                'price'         => (float)$i['price'],
                'food_name'     => $i['food_name'],
                'mandatory_items' => $mList,
                'selected_optional_items' => $optList,
            ];
        }, $items);

        $result[] = $order;
    }

    $statusStmt = $pdo->prepare("SELECT is_online FROM vendors WHERE id = ?");
    $statusStmt->execute([$vendorId]);
    $isOnline = (bool)$statusStmt->fetchColumn();

    sendSuccess('Orders fetched successfully.', [
        'is_online' => $isOnline,
        'orders' => $result
    ]);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
