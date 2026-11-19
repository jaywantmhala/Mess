<?php
/**
 * GET /api/admin/dashboard/summary
 *
 * Fetch system-wide summary metrics for the dashboard including revenue by location.
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

try {
    // 1. Total Vendors
    $totalVendors = (int) $pdo->query("SELECT COUNT(*) FROM vendors")->fetchColumn();

    // 2. Total Users/Customers
    $totalUsers = (int) $pdo->query("SELECT COUNT(*) FROM customers")->fetchColumn();

    // 3. Total Drivers
    $totalDrivers = (int) $pdo->query("SELECT COUNT(*) FROM drivers")->fetchColumn();

    // 4. Total Orders
    $totalOrders = (int) $pdo->query("SELECT COUNT(*) FROM orders")->fetchColumn();

    // 5. Total Revenue (sum of grand_total of non-cancelled orders)
    $totalRevenue = (float) $pdo->query("
        SELECT COALESCE(SUM(grand_total), 0.00) 
        FROM orders 
        WHERE status != 'cancelled'
    ")->fetchColumn();

    // 6. Revenue by Location / City (Pune, Ahmednagar, Pimpri-Chinchwad, etc.)
    $locationStmt = $pdo->query("
        SELECT 
            CASE 
                WHEN LOWER(COALESCE(h.city, '')) LIKE '%pune%' OR LOWER(COALESCE(h.hotel_address, '')) LIKE '%pune%' THEN 'Pune'
                WHEN LOWER(COALESCE(h.city, '')) LIKE '%ahmednagar%' OR LOWER(COALESCE(h.hotel_address, '')) LIKE '%ahmednagar%' OR LOWER(COALESCE(h.city, '')) LIKE '%nagar%' THEN 'Ahmednagar'
                WHEN LOWER(COALESCE(h.city, '')) LIKE '%pimpri%' OR LOWER(COALESCE(h.city, '')) LIKE '%chinchwad%' THEN 'Pimpri-Chinchwad'
                WHEN NULLIF(TRIM(h.city), '') IS NOT NULL THEN TRIM(h.city)
                ELSE 'Pune'
            END AS location_name,
            COUNT(o.order_id) AS total_orders,
            COALESCE(SUM(o.grand_total), 0.00) AS total_revenue
        FROM orders o
        JOIN hotels h ON o.hotel_id = h.id
        WHERE o.status != 'cancelled'
        GROUP BY location_name
        ORDER BY total_revenue DESC
    ");
    $locationResults = $locationStmt->fetchAll(PDO::FETCH_ASSOC);

    // Map into array ensuring primary cities like Pune & Ahmednagar are always present
    $locationMap = [
        'Pune' => ['location_name' => 'Pune', 'total_orders' => 0, 'total_revenue' => '0.00'],
        'Ahmednagar' => ['location_name' => 'Ahmednagar', 'total_orders' => 0, 'total_revenue' => '0.00'],
    ];

    foreach ($locationResults as $row) {
        $locName = $row['location_name'];
        $locationMap[$locName] = [
            'location_name' => $locName,
            'total_orders'  => (int)$row['total_orders'],
            'total_revenue' => number_format((float)$row['total_revenue'], 2, '.', '')
        ];
    }

    $locationRevenue = array_values($locationMap);

    sendSuccess('Dashboard summary metrics fetched successfully.', [
        'summary' => [
            'total_vendors'     => $totalVendors,
            'total_users'       => $totalUsers,
            'total_drivers'     => $totalDrivers,
            'total_orders'      => $totalOrders,
            'total_revenue'     => number_format($totalRevenue, 2, '.', ''),
            'location_revenue'  => $locationRevenue,
        ]
    ]);
} catch (PDOException $e) {
    sendError('Failed to fetch dashboard summary: ' . $e->getMessage(), 500);
}
