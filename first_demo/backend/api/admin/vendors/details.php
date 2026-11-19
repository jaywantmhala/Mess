<?php
/**
 * GET /api/admin/vendors/details?id=X&date=YYYY-MM-DD
 *
 * Retrieve detailed vendor information:
 * - Profile details & bank account info
 * - List of all hotels/mess managed by vendor with full details & document verifications
 * - Daily, weekly, and total revenue
 * - Today's orders & date-filtered orders list (paginated) with order items
 * - Today's menu catalog (all food items offered across vendor hotels)
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

$id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
if ($id <= 0) {
    sendError('Invalid vendor ID.', 400);
}

$dateParam = isset($_GET['date']) ? trim($_GET['date']) : '';

$pdo = getDBConnection();

try {
    // 1. Fetch vendor profile
    $stmt = $pdo->prepare("
        SELECT v.id, v.full_name, v.email, COALESCE(v.phone, '') AS phone, v.is_active, 
               COALESCE(v.country, 'India') AS country, COALESCE(v.state, '') AS state,
               COALESCE(v.district, '') AS district, COALESCE(v.taluka, '') AS taluka,
               COALESCE(v.region, '') AS region, COALESCE(v.area, '') AS area,
               v.bank_name, v.account_holder_name, v.account_number, v.ifsc_code,
               v.created_at, v.updated_at
        FROM vendors v
        WHERE v.id = :id
        LIMIT 1
    ");
    $stmt->execute([':id' => $id]);
    $vendor = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$vendor) {
        sendError('Vendor profile not found.', 404);
    }

    $vendor['id'] = (int)$vendor['id'];
    $vendor['is_active'] = (bool)$vendor['is_active'];

    // 2. Fetch all hotels / mess associated with this vendor
    $hotelStmt = $pdo->prepare("
        SELECT id, hotel_name, hotel_address, city, district, taluka, region, area, owner_name, mobile_number, email,
               pan_number, pan_photo_url, aadhar_number, aadhar_photo_url,
               fssai_number, fssai_photo_url, shop_act_number, shop_act_photo_url,
               udyam_aadhar_number, udyam_aadhar_photo_url, photo_url, 1 AS is_active
        FROM hotels
        WHERE vendor_id = :vendor_id
        ORDER BY id DESC
    ");
    $hotelStmt->execute([':vendor_id' => $id]);
    $hotels = $hotelStmt->fetchAll(PDO::FETCH_ASSOC);
    $hotelIds = array_map(function($h) { return (int)$h['id']; }, $hotels);

    // 3. Fetch Revenue (Daily, Weekly, Lifetime)
    $dailyRev = 0.00;
    $weeklyRev = 0.00;
    $totalRev = 0.00;

    try {
        $dailyStmt = $pdo->prepare("
            SELECT COALESCE(SUM(amount), 0.00) 
            FROM vendor_wallet_transactions 
            WHERE vendor_id = :id AND type = 'CREDIT' AND DATE(created_at) = CURDATE()
        ");
        $dailyStmt->execute([':id' => $id]);
        $dailyRev = (float)$dailyStmt->fetchColumn();

        $weeklyStmt = $pdo->prepare("
            SELECT COALESCE(SUM(amount), 0.00) 
            FROM vendor_wallet_transactions 
            WHERE vendor_id = :id AND type = 'CREDIT' AND DATE(created_at) >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
        ");
        $weeklyStmt->execute([':id' => $id]);
        $weeklyRev = (float)$weeklyStmt->fetchColumn();

        $totalStmt = $pdo->prepare("
            SELECT COALESCE(SUM(amount), 0.00) 
            FROM vendor_wallet_transactions 
            WHERE vendor_id = :id AND type = 'CREDIT'
        ");
        $totalStmt->execute([':id' => $id]);
        $totalRev = (float)$totalStmt->fetchColumn();
    } catch (PDOException $e) {
        // Fallback calculation from completed orders if transactions table empty
        if (!empty($hotelIds)) {
            $inClause = implode(',', $hotelIds);
            $totalStmt = $pdo->query("SELECT COALESCE(SUM(grand_total), 0.00) FROM orders WHERE hotel_id IN ($inClause) AND status = 'delivered'");
            $totalRev = (float)$totalStmt->fetchColumn();

            $dailyStmt = $pdo->query("SELECT COALESCE(SUM(grand_total), 0.00) FROM orders WHERE hotel_id IN ($inClause) AND status = 'delivered' AND DATE(created_at) = CURDATE()");
            $dailyRev = (float)$dailyStmt->fetchColumn();

            $weeklyStmt = $pdo->query("SELECT COALESCE(SUM(grand_total), 0.00) FROM orders WHERE hotel_id IN ($inClause) AND status = 'delivered' AND DATE(created_at) >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)");
            $weeklyRev = (float)$weeklyStmt->fetchColumn();
        }
    }

    // 4. Fetch Vendor Orders (Date Filterable & Paginated)
    $orderPage = isset($_GET['order_page']) ? (int)$_GET['order_page'] : 1;
    $orderLimit = isset($_GET['order_limit']) ? (int)$_GET['order_limit'] : 10;
    if ($orderPage < 1) $orderPage = 1;
    if ($orderLimit < 1 || $orderLimit > 50) $orderLimit = 10;
    $orderOffset = ($orderPage - 1) * $orderLimit;

    $whereOrders = ["(h.vendor_id = :vid1 OR o.hotel_id IN (SELECT id FROM hotels WHERE vendor_id = :vid2))"];
    $orderParams = [':vid1' => $id, ':vid2' => $id];

    if ($dateParam !== '') {
        $whereOrders[] = "DATE(o.created_at) = :order_date";
        $orderParams[':order_date'] = $dateParam;
    }

    $whereOrdersClause = "WHERE " . implode(' AND ', $whereOrders);

    $countSql = "SELECT COUNT(*) FROM orders o LEFT JOIN hotels h ON o.hotel_id = h.id $whereOrdersClause";
    $countStmt = $pdo->prepare($countSql);
    $countStmt->execute($orderParams);
    $totalOrders = (int)$countStmt->fetchColumn();
    $totalOrderPages = ceil($totalOrders / $orderLimit);

    $ordersSql = "
        SELECT o.order_id, o.customer_id, o.hotel_id, o.subtotal, o.delivery_fee, 
               o.tax_amount, o.grand_total, o.wallet_deducted, o.payment_method, 
               o.delivery_address, o.status, o.created_at,
               COALESCE(c.full_name, 'Customer') AS customer_name, 
               COALESCE(c.phone_number, c.phone, '') AS customer_phone,
               COALESCE(h.hotel_name, 'Hotel') AS hotel_name
        FROM orders o
        LEFT JOIN hotels h ON o.hotel_id = h.id
        LEFT JOIN customers c ON o.customer_id = c.id
        $whereOrdersClause
        ORDER BY o.order_id DESC
        LIMIT :limit OFFSET :offset
    ";

    $ordersStmt = $pdo->prepare($ordersSql);
    $ordersStmt->bindValue(':limit', $orderLimit, PDO::PARAM_INT);
    $ordersStmt->bindValue(':offset', $orderOffset, PDO::PARAM_INT);
    foreach ($orderParams as $k => $v) {
        $ordersStmt->bindValue($k, $v);
    }
    $ordersStmt->execute();
    $orders = $ordersStmt->fetchAll(PDO::FETCH_ASSOC);

    // Fetch items for each order
    $itemStmt = $pdo->prepare("
        SELECT oi.order_item_id, oi.menu_item_id, oi.quantity, oi.price, 
               COALESCE(m.food_name, 'Food Item') AS food_name
        FROM order_items oi
        LEFT JOIN menus m ON oi.menu_item_id = m.id
        WHERE oi.order_id = ?
    ");

    foreach ($orders as &$order) {
        $orderId = (int)$order['order_id'];
        $itemStmt->execute([$orderId]);
        $order['items'] = $itemStmt->fetchAll(PDO::FETCH_ASSOC);
        $order['grand_total'] = number_format((float)$order['grand_total'], 2, '.', '');
    }

    // 5. Fetch Today's Menu Catalog across all vendor hotels
    $menuPage = isset($_GET['menu_page']) ? (int)$_GET['menu_page'] : 1;
    $menuLimit = isset($_GET['menu_limit']) ? (int)$_GET['menu_limit'] : 10;
    if ($menuPage < 1) $menuPage = 1;
    if ($menuLimit < 1 || $menuLimit > 50) $menuLimit = 10;
    $menuOffset = ($menuPage - 1) * $menuLimit;

    $menuItems = [];
    $totalMenuItems = 0;
    $totalMenuPages = 0;

    if (!empty($hotelIds)) {
        $inClause = implode(',', $hotelIds);
        
        $countMenuStmt = $pdo->query("SELECT COUNT(*) FROM menus WHERE hotel_id IN ($inClause) AND menu_date = CURDATE()");
        $totalMenuItems = (int)$countMenuStmt->fetchColumn();
        $totalMenuPages = ceil($totalMenuItems / $menuLimit);

        $menuSql = "
            SELECT m.id, m.hotel_id, m.food_name, m.price, m.description, 
                   COALESCE(m.is_available, 1) AS is_available, COALESCE(m.food_type, 'VEG') AS meal_type,
                   COALESCE(m.food_type, 'VEG') AS food_type,
                   m.menu_date, h.hotel_name
            FROM menus m
            JOIN hotels h ON m.hotel_id = h.id
            WHERE m.hotel_id IN ($inClause) AND m.menu_date = CURDATE()
            ORDER BY m.id DESC
            LIMIT :limit OFFSET :offset
        ";
        $menuStmt = $pdo->prepare($menuSql);
        $menuStmt->bindValue(':limit', $menuLimit, PDO::PARAM_INT);
        $menuStmt->bindValue(':offset', $menuOffset, PDO::PARAM_INT);
        $menuStmt->execute();
        $menuItems = $menuStmt->fetchAll(PDO::FETCH_ASSOC);
    }

    // 6. Fetch all delivery drivers associated with this vendor
    $driverStmt = $pdo->prepare("
        SELECT d.id, d.vendor_id, d.full_name, d.email, d.phone_number, d.vehicle_number,
               COALESCE(d.is_online, 0) AS is_online,
               COALESCE(d.status, 'active') AS status,
               COALESCE(d.max_capacity, 3) AS max_capacity,
               COALESCE(d.country, 'India') AS country,
               COALESCE(d.state, '') AS state,
               COALESCE(d.district, '') AS district,
               COALESCE(d.taluka, '') AS taluka,
               d.latitude, d.longitude,
               d.created_at,
               COUNT(o.order_id) AS active_order_count
        FROM drivers d
        LEFT JOIN orders o ON o.driver_id = d.id AND o.status IN ('assigned', 'accepted_by_driver', 'picked_up')
        WHERE d.vendor_id = :vendor_id
        GROUP BY d.id
        ORDER BY COALESCE(d.is_online, 0) DESC, d.id DESC
    ");
    $driverStmt->execute([':vendor_id' => $id]);
    $drivers = $driverStmt->fetchAll(PDO::FETCH_ASSOC);

    foreach ($drivers as &$dr) {
        $dr['id'] = (int)$dr['id'];
        $dr['is_online'] = (bool)$dr['is_online'];
        $dr['max_capacity'] = (int)$dr['max_capacity'];
        $dr['active_order_count'] = (int)$dr['active_order_count'];
    }

    sendSuccess('Vendor details retrieved successfully.', [
        'vendor' => $vendor,
        'hotels' => $hotels,
        'drivers' => $drivers,
        'revenue' => [
            'daily'    => number_format($dailyRev, 2, '.', ''),
            'weekly'   => number_format($weeklyRev, 2, '.', ''),
            'lifetime' => number_format($totalRev, 2, '.', ''),
        ],
        'orders' => [
            'data' => $orders,
            'selected_date' => $dateParam !== '' ? $dateParam : 'All Dates',
            'pagination' => [
                'total_records' => $totalOrders,
                'total_pages'   => $totalOrderPages,
                'current_page'  => $orderPage,
                'per_page'      => $orderLimit
            ]
        ],
        'menu' => [
            'data' => $menuItems,
            'pagination' => [
                'total_records' => $totalMenuItems,
                'total_pages'   => $totalMenuPages,
                'current_page'  => $menuPage,
                'per_page'      => $menuLimit
            ]
        ]
    ]);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
