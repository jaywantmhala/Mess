<?php
/**
 * GET /api/customer/subscription/history
 *
 * Fetch the authenticated customer's subscription history.
 */

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    sendError('Method not allowed. Use GET.', 405);
}

$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || !isset($payload['sub'])) {
    sendError('Unauthorized. Please log in.', 401);
}

$customerId = (int)$payload['sub'];

try {
    $pdo = getDBConnection();

    $historySql = "
        SELECT cs.*, 
               COALESCE(p.plan_name, sp.plan_name, 'Subscription Plan') AS plan_name,
               COALESCE(p.price, sp.price, 0.00) AS price,
               COALESCE(p.duration, sp.duration, 30) AS duration,
               COALESCE(p.total_deliveries, sp.total_deliveries, 30) AS plan_total_deliveries, 
               COALESCE(p.meals_per_day, sp.meals_per_day, 1) AS meals_per_day,
               COALESCE(p.meal_type, sp.meal_type, 'VEG') AS meal_type,
               COALESCE(p.delivery_time_slot, sp.delivery_time_slot, '12:00 PM - 02:00 PM') AS delivery_time_slot,
               COALESCE(sl.location_name, sa.sub_area_name, '') AS sub_area_name,
               COALESCE(sl.region, a.area_name, '') AS area_name
        FROM customer_subscriptions cs
        LEFT JOIN plans p ON cs.plan_id = p.id
        LEFT JOIN service_locations sl ON p.service_location_id = sl.id
        LEFT JOIN subscription_plans sp ON cs.plan_id = sp.id
        LEFT JOIN sub_areas sa ON sp.sub_area_id = sa.id
        LEFT JOIN areas a ON sa.area_id = a.id
        WHERE cs.customer_id = ?
        ORDER BY cs.id DESC
    ";
    $historyStmt = $pdo->prepare($historySql);
    $historyStmt->execute([$customerId]);
    $subscriptions = $historyStmt->fetchAll(PDO::FETCH_ASSOC);

    // Format fields
    foreach ($subscriptions as &$sub) {
        $sub['id'] = (int)$sub['id'];
        $sub['customer_id'] = (int)$sub['customer_id'];
        $sub['plan_id'] = (int)$sub['plan_id'];
        $sub['remaining_deliveries'] = (int)$sub['remaining_deliveries'];
        $sub['total_deliveries'] = (int)$sub['total_deliveries'];
        $sub['completed_deliveries'] = (int)$sub['completed_deliveries'];
        $sub['auto_renew'] = (bool)$sub['auto_renew'];
        $sub['price'] = number_format((float)$sub['price'], 2, '.', '');
        $sub['pause_history'] = json_decode($sub['pause_history'] ?? '[]', true);
    }
    unset($sub);

    sendSuccess('Subscription history retrieved successfully.', [
        'subscriptions' => $subscriptions
    ]);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
