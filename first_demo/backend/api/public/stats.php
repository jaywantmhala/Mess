<?php
/**
 * GET /api/public/stats
 *
 * Public endpoint to fetch live platform statistics for the landing website.
 * Returns: { vendors_count, customers_count, hotels_count, cities: ['Pune', 'Ahilyanagar'], active_locations: 'Pune & Ahilyanagar' }
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { 
    http_response_code(204); 
    exit; 
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') { 
    sendError('Method not allowed. Use GET.', 405); 
}

try {
    $pdo = getDBConnection();

    // 1. Live count of Vendors / Hotel Partners
    $stmtVendor = $pdo->query("SELECT COUNT(*) FROM vendors");
    $vendorCount = (int)$stmtVendor->fetchColumn();

    // Also check total hotel / mess listings if higher
    $stmtHotel = $pdo->query("SELECT COUNT(*) FROM hotels");
    $hotelCount = (int)$stmtHotel->fetchColumn();

    // 2. Live count of Customers
    $stmtCustomer = $pdo->query("SELECT COUNT(*) FROM customers");
    $customerCount = (int)$stmtCustomer->fetchColumn();

    // 3. Live count of Orders / Meals Delivered
    $stmtOrders = $pdo->query("SELECT COUNT(*) FROM orders");
    $ordersCount = (int)$stmtOrders->fetchColumn();

    // 4. Live count of Delivery Drivers
    $stmtDrivers = $pdo->query("SELECT COUNT(*) FROM drivers");
    $driversCount = (int)$stmtDrivers->fetchColumn();

    sendSuccess('Live platform statistics retrieved successfully.', [
        'vendors_count'    => $vendorCount,
        'hotels_count'     => $hotelCount,
        'customers_count'  => $customerCount,
        'orders_count'     => $ordersCount,
        'drivers_count'    => $driversCount,
        'cities'           => ['Pune', 'Ahilyanagar'],
        'active_locations' => 'Pune and Ahilyanagar',
    ]);
} catch (Exception $e) {
    sendError('Failed to fetch platform statistics: ' . $e->getMessage(), 500);
}
