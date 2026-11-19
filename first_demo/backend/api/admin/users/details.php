<?php
/**
 * GET /api/admin/users/details?id=X
 *
 * Retrieve full customer profile details including phone number, wallet balance,
 * order history (paginated), and subscriptions.
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
    sendError('Invalid customer ID.', 400);
}

$pdo = getDBConnection();

try {
    // 1. Fetch customer details
    $stmt = $pdo->prepare("
        SELECT c.id, c.full_name, c.email, c.password, 
               COALESCE(NULLIF(c.phone_number, ''), NULLIF(c.phone, ''), '') AS phone_number, 
               COALESCE(NULLIF(c.phone_number, ''), NULLIF(c.phone, ''), '') AS phone, 
               c.is_active, 
               COALESCE(c.country, 'India') AS country,
               COALESCE(c.state, '') AS state,
               COALESCE(c.district, '') AS district,
               COALESCE(c.taluka, '') AS taluka,
               COALESCE(c.status, 'active') AS status,
               c.email_verified, c.profile_picture, c.last_login_at, c.created_at, c.updated_at,
               COALESCE(w.balance, 0.00) AS wallet_balance
        FROM customers c
        LEFT JOIN wallets w ON w.customer_id = c.id
        WHERE c.id = :id
        LIMIT 1
    ");
    $stmt->execute([':id' => $id]);
    $customer = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$customer) {
        sendError('Customer profile not found.', 404);
    }

    $customer['id'] = (int)$customer['id'];
    $customer['is_active'] = (bool)$customer['is_active'];
    $customer['email_verified'] = (bool)$customer['email_verified'];
    $customer['wallet_balance'] = number_format((float)$customer['wallet_balance'], 2, '.', '');

    // 2. Fetch customer order history
    $orderPage = isset($_GET['order_page']) ? (int)$_GET['order_page'] : 1;
    $orderLimit = isset($_GET['order_limit']) ? (int)$_GET['order_limit'] : 10;
    if ($orderPage < 1) $orderPage = 1;
    if ($orderLimit < 1 || $orderLimit > 50) $orderLimit = 10;
    $orderOffset = ($orderPage - 1) * $orderLimit;

    $countOrdersStmt = $pdo->prepare("SELECT COUNT(*) FROM orders WHERE customer_id = :id");
    $countOrdersStmt->execute([':id' => $id]);
    $totalOrders = (int)$countOrdersStmt->fetchColumn();
    $totalOrderPages = ceil($totalOrders / $orderLimit);

    $sumOrdersStmt = $pdo->prepare("SELECT COALESCE(SUM(grand_total), 0.00) FROM orders WHERE customer_id = :id AND status != 'cancelled'");
    $sumOrdersStmt->execute([':id' => $id]);
    $totalSpent = number_format((float)$sumOrdersStmt->fetchColumn(), 2, '.', '');

    $ordersStmt = $pdo->prepare("
        SELECT o.order_id, o.hotel_id, o.subtotal, o.delivery_fee, o.tax_amount, o.grand_total, 
               o.wallet_deducted, o.payment_method, o.delivery_address, o.status, o.created_at,
               COALESCE(h.hotel_name, 'Hotel') AS hotel_name
        FROM orders o
        LEFT JOIN hotels h ON o.hotel_id = h.id
        WHERE o.customer_id = :id
        ORDER BY o.order_id DESC
        LIMIT :limit OFFSET :offset
    ");
    $ordersStmt->bindValue(':id', $id, PDO::PARAM_INT);
    $ordersStmt->bindValue(':limit', $orderLimit, PDO::PARAM_INT);
    $ordersStmt->bindValue(':offset', $orderOffset, PDO::PARAM_INT);
    $ordersStmt->execute();
    $orders = $ordersStmt->fetchAll(PDO::FETCH_ASSOC);

    // Fetch order items for each order
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
        $order['wallet_deducted'] = number_format((float)$order['wallet_deducted'], 2, '.', '');
    }

    // 3. Fetch customer active/past subscriptions
    $subStmt = $pdo->prepare("
        SELECT cs.id, cs.status, cs.start_date, cs.end_date, cs.completed_deliveries, cs.total_deliveries,
               sp.plan_name, sp.meal_type, sa.sub_area_name
        FROM customer_subscriptions cs
        LEFT JOIN subscription_plans sp ON cs.plan_id = sp.id
        LEFT JOIN sub_areas sa ON sp.sub_area_id = sa.id
        WHERE cs.customer_id = :id
        ORDER BY cs.id DESC
    ");
    $subStmt->execute([':id' => $id]);
    $subscriptions = $subStmt->fetchAll(PDO::FETCH_ASSOC);

    sendSuccess('Customer profile details retrieved.', [
        'customer' => $customer,
        'summary' => [
            'total_orders' => $totalOrders,
            'total_spent'  => $totalSpent
        ],
        'orders' => [
            'data' => $orders,
            'pagination' => [
                'total_records' => $totalOrders,
                'total_pages'   => $totalOrderPages,
                'current_page'  => $orderPage,
                'per_page'      => $orderLimit
            ]
        ],
        'subscriptions' => $subscriptions
    ]);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
