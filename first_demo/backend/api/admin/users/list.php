<?php
/**
 * GET /api/admin/users
 *
 * Retrieves paginated list of customers for admin panel with optional location filters.
 * Requires: Authorization: Bearer <JWT>
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

$token = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || !isset($payload['sub']) || ($payload['role'] ?? '') !== 'admin') {
    sendError('Unauthorized. Admin access required.', 401);
}

$search   = isset($_GET['search']) ? trim($_GET['search']) : '';
$status   = isset($_GET['status']) ? trim($_GET['status']) : 'all'; // all, active, inactive
$sort     = isset($_GET['sort']) ? trim($_GET['sort']) : 'newest'; // newest (date DESC), oldest (date ASC), online
$date     = isset($_GET['date']) ? trim($_GET['date']) : ''; // YYYY-MM-DD
$country  = isset($_GET['country']) ? trim($_GET['country']) : '';
$state    = isset($_GET['state']) ? trim($_GET['state']) : '';
$district = isset($_GET['district']) ? trim($_GET['district']) : '';
$taluka   = isset($_GET['taluka']) ? trim($_GET['taluka']) : '';
$region   = isset($_GET['region']) ? trim($_GET['region']) : '';
$area     = isset($_GET['area']) ? trim($_GET['area']) : '';
$page     = isset($_GET['page']) ? (int)$_GET['page'] : 1;
$limit    = isset($_GET['limit']) ? (int)$_GET['limit'] : 10;

if ($page < 1) $page = 1;
if ($limit < 1 || $limit > 100) $limit = 10;
$offset = ($page - 1) * $limit;

$pdo = getDBConnection();
ensureCustomerLocationColumns($pdo);
ensureCustomerAddressLocationColumns($pdo);
ensureCustomerSearchIndexes($pdo);

// Build WHERE clauses
$where = [];
$params = [];

if ($search !== '') {
    $searchId = preg_replace('/[^0-9]/', '', $search);
    $searchPattern = '%' . $search . '%';
    $searchParts = [];
    if ($searchId !== '' && (strpos($search, '#') === 0 || is_numeric($search))) {
        $searchParts[] = "c.id = :search_id";
        $params[':search_id'] = (int)$searchId;
    }
    $searchParts[] = "c.full_name LIKE :us_name";
    $params[':us_name'] = $searchPattern;

    $searchParts[] = "c.email LIKE :us_email";
    $params[':us_email'] = $searchPattern;

    $searchParts[] = "c.phone_number LIKE :us_phone";
    $params[':us_phone'] = $searchPattern;

    $searchParts[] = "ca.full_address LIKE :us_addr";
    $params[':us_addr'] = $searchPattern;

    $searchParts[] = "ca.city LIKE :us_city";
    $params[':us_city'] = $searchPattern;

    $searchParts[] = "ca.district LIKE :us_dist";
    $params[':us_dist'] = $searchPattern;

    $where[] = '(' . implode(' OR ', $searchParts) . ')';
}

if ($status === 'active') {
    $where[] = "c.is_active = 1";
} elseif ($status === 'inactive') {
    $where[] = "c.is_active = 0";
} elseif ($status === 'online') {
    $where[] = "(c.is_online = 1 AND c.last_seen_at IS NOT NULL AND c.last_seen_at >= (NOW() - INTERVAL 5 MINUTE))";
} elseif ($status === 'offline') {
    $where[] = "(c.is_online = 0 OR c.last_seen_at IS NULL OR c.last_seen_at < (NOW() - INTERVAL 5 MINUTE))";
}

if ($date !== '' && strtolower($date) !== 'all') {
    $where[] = "DATE(c.created_at) = :filter_date";
    $params[':filter_date'] = $date;
}

if ($country !== '' && strtolower($country) !== 'all') {
    if (in_array(strtolower($country), ['india', 'in'])) {
        $where[] = "(c.country IN ('India', 'IN') OR ca.country IN ('India', 'IN') OR c.country IS NULL OR c.country = '')";
    } else {
        $where[] = "(c.country = :country1 OR ca.country = :country2 OR LOWER(ca.full_address) LIKE :country3)";
        $cPattern = '%' . strtolower($country) . '%';
        $params[':country1'] = $country;
        $params[':country2'] = $country;
        $params[':country3'] = $cPattern;
    }
}

if ($state !== '' && strtolower($state) !== 'all') {
    $where[] = "(c.state = :state1 OR ca.state = :state2 OR LOWER(ca.full_address) LIKE :state3)";
    $sPattern = '%' . strtolower($state) . '%';
    $params[':state1'] = $state;
    $params[':state2'] = $state;
    $params[':state3'] = $sPattern;
}

if ($district !== '' && strtolower($district) !== 'all') {
    $where[] = "(c.district = :district1 OR ca.district = :district2 OR ca.city = :district3 OR LOWER(ca.full_address) LIKE :district4)";
    $dPattern = '%' . strtolower($district) . '%';
    $params[':district1'] = $district;
    $params[':district2'] = $district;
    $params[':district3'] = $district;
    $params[':district4'] = $dPattern;
}

if ($taluka !== '' && strtolower($taluka) !== 'all') {
    $where[] = "(c.taluka = :taluka1 OR ca.taluka = :taluka2 OR LOWER(ca.full_address) LIKE :taluka3)";
    $tPattern = '%' . strtolower($taluka) . '%';
    $params[':taluka1'] = $taluka;
    $params[':taluka2'] = $taluka;
    $params[':taluka3'] = $tPattern;
}

if ($region !== '' && strtolower($region) !== 'all') {
    $where[] = "(COALESCE(c.region, '') = :region1 OR LOWER(COALESCE(ca.full_address, '')) LIKE :region2 OR LOWER(COALESCE(ca.area, '')) LIKE :region3 OR LOWER(COALESCE(ca.region, '')) LIKE :region4)";
    $rPattern = '%' . strtolower($region) . '%';
    $params[':region1'] = $region;
    $params[':region2'] = $rPattern;
    $params[':region3'] = $rPattern;
    $params[':region4'] = $rPattern;
}

if ($area !== '' && strtolower($area) !== 'all') {
    $where[] = "(COALESCE(ca.area, '') = :area1 OR LOWER(COALESCE(ca.area, '')) LIKE :area2 OR LOWER(COALESCE(ca.full_address, '')) LIKE :area3 OR LOWER(COALESCE(ca.address_line1, '')) LIKE :area4 OR LOWER(COALESCE(c.area, '')) LIKE :area5)";
    $aPattern = '%' . strtolower($area) . '%';
    $params[':area1'] = $area;
    $params[':area2'] = $aPattern;
    $params[':area3'] = $aPattern;
    $params[':area4'] = $aPattern;
    $params[':area5'] = $aPattern;
}

$whereClause = count($where) > 0 ? 'WHERE ' . implode(' AND ', $where) : '';

try {
    // Get total count and online count
    $countSql = "
        SELECT COUNT(DISTINCT c.id) AS total_count,
               COUNT(DISTINCT CASE WHEN c.is_online = 1 AND c.last_seen_at IS NOT NULL AND c.last_seen_at >= (NOW() - INTERVAL 5 MINUTE) THEN c.id END) AS online_count
        FROM customers c
        LEFT JOIN customer_addresses ca ON ca.customer_id = c.id
        $whereClause
    ";
    $countStmt = $pdo->prepare($countSql);
    $countStmt->execute($params);
    $countRow = $countStmt->fetch(PDO::FETCH_ASSOC) ?: ['total_count' => 0, 'online_count' => 0];
    $totalRecords  = (int) ($countRow['total_count'] ?? 0);
    $onlineRecords = (int) ($countRow['online_count'] ?? 0);
    $totalPages    = $totalRecords > 0 ? ceil($totalRecords / $limit) : 1;

    // Get paginated results with wallet balance and order count, showing online users FIRST at the top
    $sql = "
        SELECT c.id, c.full_name, c.email, c.password, COALESCE(c.phone_number, '') AS phone_number, COALESCE(c.phone_number, '') AS phone,
               MAX(COALESCE(NULLIF(TRIM(ca.country), ''), NULLIF(TRIM(c.country), ''), 'India')) AS country,
               MAX(COALESCE(NULLIF(TRIM(ca.state), ''), NULLIF(TRIM(c.state), ''))) AS state,
               MAX(COALESCE(NULLIF(TRIM(ca.district), ''), NULLIF(TRIM(ca.city), ''), NULLIF(TRIM(c.district), ''))) AS district,
               MAX(COALESCE(NULLIF(TRIM(ca.taluka), ''), NULLIF(TRIM(c.taluka), ''))) AS taluka,
               MAX(COALESCE(NULLIF(TRIM(ca.area), ''), '')) AS area,
               MAX(COALESCE(NULLIF(TRIM(ca.full_address), ''), '')) AS full_address,
               c.is_active, c.email_verified, c.profile_picture, c.created_at, c.updated_at,
               c.last_login_at, c.last_seen_at,
               (CASE WHEN c.is_online = 1 AND c.last_seen_at IS NOT NULL AND c.last_seen_at >= (NOW() - INTERVAL 5 MINUTE) THEN 1 ELSE 0 END) AS is_online,
               COALESCE(MAX(w.balance), 0.00) AS wallet_balance,
               COUNT(DISTINCT o.order_id) AS order_count
        FROM customers c
        LEFT JOIN customer_addresses ca ON ca.customer_id = c.id
        LEFT JOIN wallets w ON w.customer_id = c.id
        LEFT JOIN orders o ON o.customer_id = c.id
        $whereClause
        GROUP BY c.id
        ORDER BY " . ($sort === 'oldest' ? 'c.created_at ASC, c.id ASC' : ($sort === 'online' ? 'is_online DESC, c.last_seen_at DESC, c.created_at DESC' : 'c.created_at DESC, c.id DESC')) . "
        LIMIT :limit OFFSET :offset
    ";
    
    $stmt = $pdo->prepare($sql);
    
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    foreach ($params as $key => $val) {
        $stmt->bindValue($key, $val);
    }
    
    $stmt->execute();
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Format fields
    foreach ($users as &$user) {
        $user['id'] = (int) $user['id'];
        $user['is_active'] = (bool) $user['is_active'];
        $user['is_online'] = (bool) $user['is_online'];
        $user['email_verified'] = (bool) $user['email_verified'];
        $user['wallet_balance'] = number_format((float)$user['wallet_balance'], 2, '.', '');
        $user['order_count'] = (int) $user['order_count'];
    }

    sendSuccess('Customers fetched successfully.', [
        'users' => $users,
        'online_count' => $onlineRecords,
        'pagination' => [
            'total_records'  => $totalRecords,
            'online_records' => $onlineRecords,
            'total_pages'    => $totalPages,
            'current_page'   => $page,
            'per_page'       => $limit
        ]
    ]);

} catch (PDOException $e) {
    sendError('Database error fetching customers: ' . $e->getMessage(), 500);
}
