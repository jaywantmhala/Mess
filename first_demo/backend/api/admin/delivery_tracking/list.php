<?php
/**
 * GET /api/admin/delivery_tracking/list.php
 * Retrieves orders for live delivery tracking with Mess, Vendor, Customer, Driver, and Location details.
 * Query Params: search, status (all, active, out_for_delivery, completed, cancelled), page, limit
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

if (!$payload || !isset($payload['sub']) || ($payload['role'] ?? '') !== 'admin') {
    sendError('Unauthorized. Admin access required.', 401);
}

$search = isset($_GET['search']) ? trim($_GET['search']) : '';
$status = isset($_GET['status']) ? trim(strtolower($_GET['status'])) : 'all';
$page   = isset($_GET['page'])   ? (int)$_GET['page']  : 1;
$limit  = isset($_GET['limit'])  ? (int)$_GET['limit'] : 50;

if ($page < 1) $page = 1;
if ($limit < 1 || $limit > 100) $limit = 50;
$offset = ($page - 1) * $limit;

try {
    $pdo = getDBConnection();

    $where = [];
    $params = [];

    if ($search !== '') {
        $searchPattern = '%' . $search . '%';
        $where[] = "(CAST(o.order_id AS CHAR) LIKE :dt_s1 
                    OR h.hotel_name LIKE :dt_s2 
                    OR v.owner_name LIKE :dt_s3 
                    OR v.business_name LIKE :dt_s4 
                    OR c.full_name LIKE :dt_s5 
                    OR d.full_name LIKE :dt_s6 
                    OR o.delivery_address LIKE :dt_s7)";
        $params[':dt_s1'] = $searchPattern;
        $params[':dt_s2'] = $searchPattern;
        $params[':dt_s3'] = $searchPattern;
        $params[':dt_s4'] = $searchPattern;
        $params[':dt_s5'] = $searchPattern;
        $params[':dt_s6'] = $searchPattern;
        $params[':dt_s7'] = $searchPattern;
    }

    if ($status === 'active') {
        $where[] = "o.status IN ('created_order', 'accepted', 'preparing', 'ready', 'assigned', 'accepted_by_driver', 'picked_up', 'arrived_at_customer')";
    } elseif ($status === 'out_for_delivery') {
        $where[] = "o.status IN ('picked_up', 'arrived_at_customer')";
    } elseif ($status === 'completed') {
        $where[] = "o.status = 'completed'";
    } elseif ($status === 'cancelled') {
        $where[] = "o.status IN ('cancelled', 'rejected', 'rejected_by_driver')";
    }

    $whereClause = !empty($where) ? 'WHERE ' . implode(' AND ', $where) : '';

    // Count Total
    $countSql = "
        SELECT COUNT(*) 
        FROM orders o
        LEFT JOIN hotels h ON o.hotel_id = h.id
        LEFT JOIN vendors v ON h.vendor_id = v.id
        LEFT JOIN customers c ON o.customer_id = c.id
        LEFT JOIN drivers d ON o.driver_id = d.id
        $whereClause
    ";
    $countStmt = $pdo->prepare($countSql);
    $countStmt->execute($params);
    $totalRecords = (int)$countStmt->fetchColumn();

    // Fetch Orders
    $sql = "
        SELECT 
            o.order_id,
            o.status,
            o.grand_total,
            o.subtotal,
            o.delivery_fee,
            o.tax_amount,
            o.payment_method,
            o.delivery_address,
            COALESCE(o.meal_type, 'Lunch') AS meal_type,
            o.created_at,
            o.updated_at,
            
            -- Mess / Hotel Info
            h.id AS hotel_id,
            COALESCE(h.hotel_name, 'Mess') AS hotel_name,
            COALESCE(h.hotel_address, '') AS hotel_address,
            COALESCE(h.mobile_number, '') AS hotel_phone,
            COALESCE(h.latitude, 0.0) AS hotel_lat,
            COALESCE(h.longitude, 0.0) AS hotel_lng,
            
            -- Vendor Info
            v.id AS vendor_id,
            COALESCE(
                NULLIF(TRIM(v.owner_name), ''),
                NULLIF(TRIM(v.full_name), ''),
                NULLIF(TRIM(v.business_name), ''),
                v.email,
                'Vendor'
            ) AS vendor_name,
            COALESCE(
                NULLIF(TRIM(v.phone), ''),
                NULLIF(TRIM(v.mobile_number), ''),
                ''
            ) AS vendor_phone,
            COALESCE(v.email, '') AS vendor_email,
            
            -- Customer Info
            c.id AS customer_id,
            COALESCE(c.full_name, 'Customer') AS customer_name,
            COALESCE(c.phone_number, '') AS customer_phone,
            COALESCE(ca.latitude, 0.0) AS customer_lat,
            COALESCE(ca.longitude, 0.0) AS customer_lng,
            
            -- Driver Info
            d.id AS driver_id,
            COALESCE(d.full_name, '') AS driver_name,
            COALESCE(d.phone_number, '') AS driver_phone,
            COALESCE(d.vehicle_number, '') AS driver_vehicle_number,
            COALESCE(d.is_online, 0) AS driver_is_online,
            COALESCE(d.latitude, 0.0) AS driver_lat,
            COALESCE(d.longitude, 0.0) AS driver_lng,
            d.updated_at AS driver_last_updated
        FROM orders o
        LEFT JOIN hotels h ON o.hotel_id = h.id
        LEFT JOIN vendors v ON h.vendor_id = v.id
        LEFT JOIN customers c ON o.customer_id = c.id
        LEFT JOIN customer_addresses ca ON ca.id = (
            SELECT id FROM customer_addresses 
            WHERE customer_id = o.customer_id 
            ORDER BY is_default DESC, id DESC 
            LIMIT 1
        )
        LEFT JOIN drivers d ON o.driver_id = d.id
        $whereClause
        ORDER BY o.order_id DESC
        LIMIT :limit OFFSET :offset
    ";

    $stmt = $pdo->prepare($sql);
    foreach ($params as $key => $val) {
        $stmt->bindValue($key, $val);
    }
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();
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

    $formattedOrders = [];
    foreach ($orders as $o) {
        $orderId = (int)$o['order_id'];
        $itemStmt->execute([$orderId]);
        $items = $itemStmt->fetchAll(PDO::FETCH_ASSOC);

        $itemList = array_map(function($i) {
            $mList = [];
            if (!empty($i['mandatory_items'])) {
                $mDecoded = json_decode($i['mandatory_items'], true);
                if (is_array($mDecoded)) $mList = $mDecoded;
            }
            return [
                'order_item_id' => (int)$i['order_item_id'],
                'food_name'     => $i['food_name'],
                'quantity'      => (int)$i['quantity'],
                'price'         => (float)$i['price'],
                'mandatory_items' => $mList,
            ];
        }, $items);

        $formattedOrders[] = [
            'order_id'         => $orderId,
            'status'           => $o['status'],
            'grand_total'      => (float)$o['grand_total'],
            'subtotal'         => (float)$o['subtotal'],
            'delivery_fee'     => (float)$o['delivery_fee'],
            'tax_amount'       => (float)$o['tax_amount'],
            'payment_method'   => $o['payment_method'],
            'delivery_address' => $o['delivery_address'],
            'meal_type'        => $o['meal_type'],
            'created_at'       => $o['created_at'],
            'updated_at'       => $o['updated_at'],
            'mess' => [
                'id'      => (int)$o['hotel_id'],
                'name'    => $o['hotel_name'],
                'address' => $o['hotel_address'],
                'phone'   => $o['hotel_phone'],
                'lat'     => (float)$o['hotel_lat'],
                'lng'     => (float)$o['hotel_lng'],
            ],
            'vendor' => [
                'id'    => (int)$o['vendor_id'],
                'name'  => $o['vendor_name'],
                'phone' => $o['vendor_phone'],
                'email' => $o['vendor_email'],
            ],
            'customer' => [
                'id'      => (int)$o['customer_id'],
                'name'    => $o['customer_name'],
                'phone'   => $o['customer_phone'],
                'lat'     => (float)$o['customer_lat'],
                'lng'     => (float)$o['customer_lng'],
            ],
            'driver' => [
                'id'             => (int)$o['driver_id'],
                'name'           => $o['driver_name'],
                'phone'          => $o['driver_phone'],
                'vehicle_number' => $o['driver_vehicle_number'],
                'is_online'      => (bool)$o['driver_is_online'],
                'lat'            => (float)$o['driver_lat'],
                'lng'            => (float)$o['driver_lng'],
                'last_updated'   => $o['driver_last_updated'],
            ],
            'items' => $itemList,
        ];
    }

    sendSuccess('Live delivery tracking data retrieved.', [
        'total'  => $totalRecords,
        'page'   => $page,
        'limit'  => $limit,
        'orders' => $formattedOrders,
    ]);

} catch (Exception $e) {
    sendError('Database query error: ' . $e->getMessage(), 500);
}
