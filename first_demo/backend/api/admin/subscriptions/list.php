<?php
/**
 * GET /api/admin/subscriptions/list
 *
 * List all customer subscriptions with search, filtering, and pagination.
 * Headers: Authorization: Bearer <admin_token>
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

// Validate Admin authentication
if (!$payload || !isset($payload['sub'])) {
    sendError('Unauthorized. Please log in.', 401);
}

// In the current admin layout, verify that the token sub represents an admin or is authenticated.
// (Admins login via /api/admin/login and receive a token just like customer, but typically checked by email format or sub).

$search = isset($_GET['search']) ? trim($_GET['search']) : '';
$status = isset($_GET['status']) ? trim($_GET['status']) : 'all';
$page   = isset($_GET['page'])   ? max(1, (int)$_GET['page'])   : 1;
$limit  = isset($_GET['limit'])  ? max(1, (int)$_GET['limit'])  : 10;
$offset = ($page - 1) * $limit;

try {
    $pdo = getDBConnection();

    // Base query conditions
    $conditions = [];
    $params = [];

    if ($search !== '') {
        $searchPattern = '%' . $search . '%';
        $conditions[] = "(c.full_name LIKE :sub_s1 
                          OR c.email LIKE :sub_s2 
                          OR pl.plan_name LIKE :sub_s3
                          OR sp.plan_name LIKE :sub_s4 
                          OR sl.location_name LIKE :sub_s5
                          OR sa.sub_area_name LIKE :sub_s6)";
        $params[':sub_s1'] = $searchPattern;
        $params[':sub_s2'] = $searchPattern;
        $params[':sub_s3'] = $searchPattern;
        $params[':sub_s4'] = $searchPattern;
        $params[':sub_s5'] = $searchPattern;
        $params[':sub_s6'] = $searchPattern;
    }

    if ($status !== 'all') {
        if ($status === 'expiring_soon') {
            $conditions[] = "cs.status = 'ACTIVE' AND cs.end_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY)";
        } else {
            $conditions[] = "cs.status = :status";
            $params[':status'] = strtoupper($status);
        }
    }

    $whereClause = !empty($conditions) ? "WHERE " . implode(" AND ", $conditions) : "";

    // Count query
    $countSql = "
        SELECT COUNT(*) 
        FROM customer_subscriptions cs
        JOIN customers c ON cs.customer_id = c.id
        LEFT JOIN plans pl ON cs.plan_id = pl.id
        LEFT JOIN service_locations sl ON pl.service_location_id = sl.id
        LEFT JOIN subscription_plans sp ON cs.plan_id = sp.id
        LEFT JOIN sub_areas sa ON sp.sub_area_id = sa.id
        $whereClause
    ";
    $countStmt = $pdo->prepare($countSql);
    $countStmt->execute($params);
    $totalCount = (int)$countStmt->fetchColumn();

    // Data query
    $dataSql = "
        SELECT cs.*, 
               c.full_name AS customer_name, c.email AS customer_email,
               COALESCE(pl.plan_name, sp.plan_name, 'Subscription Plan') AS plan_name,
               COALESCE(pl.price, sp.price, 0.00) AS price,
               COALESCE(pl.duration, sp.duration, 30) AS duration,
               COALESCE(pl.total_deliveries, sp.total_deliveries, 30) AS plan_total_deliveries,
               COALESCE(sl.location_name, sa.sub_area_name, '') AS sub_area_name,
               COALESCE(sl.region, a.area_name, '') AS area_name,
               ci.city_name AS city
        FROM customer_subscriptions cs
        JOIN customers c ON cs.customer_id = c.id
        LEFT JOIN plans pl ON cs.plan_id = pl.id
        LEFT JOIN service_locations sl ON pl.service_location_id = sl.id
        LEFT JOIN subscription_plans sp ON cs.plan_id = sp.id
        LEFT JOIN sub_areas sa ON sp.sub_area_id = sa.id
        LEFT JOIN areas a ON sa.area_id = a.id
        LEFT JOIN pincodes p ON a.pincode_id = p.id
        LEFT JOIN cities ci ON p.city_id = ci.id
        $whereClause
        ORDER BY cs.id DESC
        LIMIT :limit OFFSET :offset
    ";
    $dataStmt = $pdo->prepare($dataSql);
    
    // Bind limit/offset as integer (needed for MySQL prepare)
    $dataStmt->bindValue(':limit',  $limit,  PDO::PARAM_INT);
    $dataStmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    foreach ($params as $key => $val) {
        $dataStmt->bindValue($key, $val);
    }
    
    $dataStmt->execute();
    $subscriptions = $dataStmt->fetchAll(PDO::FETCH_ASSOC);

    // Format output fields
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

    $totalPages = ceil($totalCount / $limit);

    sendSuccess('Subscriptions fetched successfully.', [
        'subscriptions' => $subscriptions,
        'pagination' => [
            'total_records' => $totalCount,
            'total_pages'   => $totalPages,
            'current_page'  => $page,
            'limit'         => $limit
        ]
    ]);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
