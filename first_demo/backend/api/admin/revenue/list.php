<?php
/**
 * GET /api/admin/revenue/list
 *
 * Retrieves revenue metrics and orders filtered by customer location.
 * Uses: orders -> customer_id -> customer_addresses (and customer profile location fallback).
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

if (!$payload || !isset($payload['sub']) || ($payload['role'] ?? '') !== 'admin') {
    sendError('Unauthorized. Admin access required.', 401);
}

$pdo = getDBConnection();
ensureCustomerLocationColumns($pdo);
ensureCustomerAddressLocationColumns($pdo);

$country  = isset($_GET['country'])  ? trim($_GET['country'])  : '';
$state    = isset($_GET['state'])    ? trim($_GET['state'])    : '';
$district = isset($_GET['district']) ? trim($_GET['district']) : '';
$taluka   = isset($_GET['taluka'])   ? trim($_GET['taluka'])   : '';
$status   = isset($_GET['status'])   ? trim($_GET['status'])   : '';
$search   = isset($_GET['search'])   ? trim($_GET['search'])   : '';
$page     = max(1, (int)($_GET['page'] ?? 1));
$limit    = max(1, min(100, (int)($_GET['limit'] ?? 15)));
$offset   = ($page - 1) * $limit;

try {
    $where = [];
    $params = [];

    // Filter by Country on customer_addresses
    if (!empty($country) && strtolower($country) !== 'all') {
        if (in_array(strtolower($country), ['india', 'in'])) {
            $where[] = "(ca.country IN ('India', 'IN') OR c.country IN ('India', 'IN') OR ca.country IS NULL OR ca.country = '')";
        } else {
            $where[] = "(ca.country = :country1 OR c.country = :country2)";
            $params[':country1'] = $country;
            $params[':country2'] = $country;
        }
    }

    // Filter by State on customer_addresses
    if (!empty($state) && strtolower($state) !== 'all') {
        $where[] = "(ca.state = :state1 OR c.state = :state2 OR LOWER(ca.full_address) LIKE :state3)";
        $sPattern = '%' . strtolower($state) . '%';
        $params[':state1'] = $state;
        $params[':state2'] = $state;
        $params[':state3'] = $sPattern;
    }

    // Filter by District on customer_addresses (district & city)
    if (!empty($district) && strtolower($district) !== 'all') {
        $where[] = "(ca.district = :district1 OR ca.city = :district2 OR c.district = :district3 OR LOWER(ca.full_address) LIKE :district4)";
        $dPattern = '%' . strtolower($district) . '%';
        $params[':district1'] = $district;
        $params[':district2'] = $district;
        $params[':district3'] = $district;
        $params[':district4'] = $dPattern;
    }

    // Filter by Taluka on customer_addresses
    if (!empty($taluka) && strtolower($taluka) !== 'all') {
        $where[] = "(ca.taluka = :taluka1 OR c.taluka = :taluka2 OR LOWER(ca.full_address) LIKE :taluka3)";
        $tPattern = '%' . strtolower($taluka) . '%';
        $params[':taluka1'] = $taluka;
        $params[':taluka2'] = $taluka;
        $params[':taluka3'] = $tPattern;
    }

    // Filter by Order Status
    if (!empty($status) && strtolower($status) !== 'all') {
        $where[] = "o.status = :status";
        $params[':status'] = $status;
    }

    // Search filter
    if (!empty($search)) {
        $where[] = "(c.full_name LIKE :search1 OR c.email LIKE :search2 OR c.phone_number LIKE :search3 OR h.hotel_name LIKE :search4 OR CAST(o.order_id AS CHAR) LIKE :search5)";
        $searchPattern = '%' . $search . '%';
        $params[':search1'] = $searchPattern;
        $params[':search2'] = $searchPattern;
        $params[':search3'] = $searchPattern;
        $params[':search4'] = $searchPattern;
        $params[':search5'] = $searchPattern;
    }

    $whereClause = !empty($where) ? 'WHERE ' . implode(' AND ', $where) : '';

    // 1. Get Location Metrics Summary
    $summarySql = "
        SELECT 
            COALESCE(SUM(CASE WHEN o.status != 'cancelled' THEN o.grand_total ELSE 0 END), 0.00) AS total_revenue,
            COUNT(CASE WHEN o.status != 'cancelled' THEN 1 END) AS total_orders,
            COUNT(DISTINCT o.order_id) AS all_orders_count,
            COALESCE(AVG(CASE WHEN o.status != 'cancelled' THEN o.grand_total END), 0.00) AS avg_order_value,
            COUNT(DISTINCT o.customer_id) AS unique_customers
        FROM orders o
        JOIN customers c ON c.id = o.customer_id
        LEFT JOIN customer_addresses ca ON ca.customer_id = c.id
        LEFT JOIN hotels h ON h.id = o.hotel_id
        $whereClause
    ";
    $summaryStmt = $pdo->prepare($summarySql);
    $summaryStmt->execute($params);
    $metrics = $summaryStmt->fetch(PDO::FETCH_ASSOC);

    $totalRevenue     = (float)($metrics['total_revenue'] ?? 0);
    $totalOrders      = (int)($metrics['total_orders'] ?? 0);
    $allOrdersCount   = (int)($metrics['all_orders_count'] ?? 0);
    $avgOrderValue    = (float)($metrics['avg_order_value'] ?? 0);
    $uniqueCustomers  = (int)($metrics['unique_customers'] ?? 0);

    // 2. Count total paginated records
    $totalRecords = $allOrdersCount;
    $totalPages   = $totalRecords > 0 ? (int)ceil($totalRecords / $limit) : 1;

    // 3. Fetch detailed orders list with customer address location
    $listSql = "
        SELECT 
            o.order_id,
            o.customer_id,
            o.hotel_id,
            o.grand_total,
            o.subtotal,
            o.delivery_fee,
            o.tax_amount,
            o.status,
            o.payment_method,
            o.created_at,
            c.full_name AS customer_name,
            c.phone_number AS customer_phone,
            c.email AS customer_email,
            h.hotel_name,
            MAX(COALESCE(NULLIF(TRIM(ca.taluka), ''), NULLIF(TRIM(c.taluka), ''))) AS taluka,
            MAX(COALESCE(NULLIF(TRIM(ca.district), ''), NULLIF(TRIM(ca.city), ''), NULLIF(TRIM(c.district), ''))) AS district,
            MAX(COALESCE(NULLIF(TRIM(ca.state), ''), NULLIF(TRIM(c.state), ''))) AS state,
            MAX(COALESCE(NULLIF(TRIM(ca.country), ''), NULLIF(TRIM(c.country), ''), 'India')) AS country
        FROM orders o
        JOIN customers c ON c.id = o.customer_id
        LEFT JOIN customer_addresses ca ON ca.customer_id = c.id
        LEFT JOIN hotels h ON h.id = o.hotel_id
        $whereClause
        GROUP BY o.order_id
        ORDER BY o.created_at DESC
        LIMIT :limit OFFSET :offset
    ";

    $listStmt = $pdo->prepare($listSql);
    foreach ($params as $k => $v) {
        $listStmt->bindValue($k, $v);
    }
    $listStmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $listStmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $listStmt->execute();

    $orders = $listStmt->fetchAll(PDO::FETCH_ASSOC);

    $formattedOrders = array_map(function($ord) {
        return [
            'order_id'       => (int)$ord['order_id'],
            'customer_id'    => (int)$ord['customer_id'],
            'customer_name'  => $ord['customer_name'] ?? 'Guest Customer',
            'customer_phone' => $ord['customer_phone'] ?? '',
            'customer_email' => $ord['customer_email'] ?? '',
            'hotel_id'       => (int)$ord['hotel_id'],
            'hotel_name'     => $ord['hotel_name'] ?? 'N/A',
            'grand_total'    => number_format((float)$ord['grand_total'], 2, '.', ''),
            'subtotal'       => number_format((float)$ord['subtotal'], 2, '.', ''),
            'delivery_fee'   => number_format((float)$ord['delivery_fee'], 2, '.', ''),
            'tax_amount'     => number_format((float)$ord['tax_amount'], 2, '.', ''),
            'status'         => strtolower($ord['status'] ?? 'pending'),
            'payment_method' => $ord['payment_method'] ?? 'COD',
            'country'        => !empty($ord['country']) ? $ord['country'] : 'India',
            'state'          => $ord['state'] ?? '',
            'district'       => $ord['district'] ?? '',
            'taluka'         => $ord['taluka'] ?? '',
            'created_at'     => $ord['created_at'],
        ];
    }, $orders);

    sendSuccess('Revenue and order metrics retrieved successfully.', [
        'metrics' => [
            'total_revenue'    => number_format($totalRevenue, 2, '.', ''),
            'total_orders'     => $totalOrders,
            'avg_order_value'  => number_format($avgOrderValue, 2, '.', ''),
            'unique_customers' => $uniqueCustomers,
        ],
        'orders' => $formattedOrders,
        'pagination' => [
            'total_records' => $totalRecords,
            'total_pages'   => $totalPages,
            'current_page'  => $page,
            'per_page'      => $limit
        ]
    ]);

} catch (PDOException $e) {
    sendError('Database error fetching revenue metrics: ' . $e->getMessage(), 500);
}
