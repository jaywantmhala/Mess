<?php
/**
 * GET or POST /api/admin/whatsapp/targets
 *
 * Retrieves target counts (users with valid WhatsApp mobile numbers),
 * breakdown, and recipient list filtered by Target Role (all, customers, vendors, drivers),
 * State, District, and Taluka.
 */

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || !isset($payload['sub']) || ($payload['role'] ?? '') !== 'admin') {
    sendError('Unauthorized. Admin access required.', 401);
}

$inputData = $_SERVER['REQUEST_METHOD'] === 'POST' ? json_decode(file_get_contents('php://input'), true) ?? $_POST : $_GET;

$target   = strtolower(trim($inputData['target'] ?? 'all'));
$state    = trim($inputData['state'] ?? '');
$district = trim($inputData['district'] ?? '');
$taluka   = trim($inputData['taluka'] ?? '');
$userType = strtolower(trim($inputData['user_type'] ?? 'all')); // all, customers, vendors, drivers
$search   = trim($inputData['search'] ?? '');
$page     = max(1, (int)($inputData['page'] ?? 1));
$limit    = min(100, max(1, (int)($inputData['limit'] ?? 25)));
$offset   = ($page - 1) * $limit;

if ($district === 'all') $district = '';
if ($taluka === 'all')   $taluka   = '';
if ($state === 'all')    $state    = '';

$pdo = getDBConnection();

// Helper for Customers
function buildCustomerWaWhere($state, $district, $taluka, $search = '') {
    $where = ["c.phone_number IS NOT NULL AND TRIM(c.phone_number) != ''"];
    $params = [];

    if (!empty($state)) {
        $where[] = "(c.state = :c_state OR ca.state = :c_state_ca OR LOWER(ca.full_address) LIKE :c_state_like)";
        $params[':c_state'] = $state;
        $params[':c_state_ca'] = $state;
        $params[':c_state_like'] = '%' . strtolower($state) . '%';
    }
    if (!empty($district)) {
        $where[] = "(c.district = :c_dist OR ca.district = :c_dist_ca OR LOWER(ca.city) = LOWER(:c_city) OR LOWER(ca.full_address) LIKE :c_dist_like)";
        $params[':c_dist'] = $district;
        $params[':c_dist_ca'] = $district;
        $params[':c_city'] = $district;
        $params[':c_dist_like'] = '%' . strtolower($district) . '%';
    }
    if (!empty($taluka)) {
        $where[] = "(c.taluka = :c_tal OR ca.taluka = :c_tal_ca OR LOWER(ca.full_address) LIKE :c_tal_like)";
        $params[':c_tal'] = $taluka;
        $params[':c_tal_ca'] = $taluka;
        $params[':c_tal_like'] = '%' . strtolower($taluka) . '%';
    }
    if (!empty($search)) {
        $where[] = "(c.full_name LIKE :c_search OR c.email LIKE :c_search OR c.phone_number LIKE :c_search)";
        $params[':c_search'] = '%' . $search . '%';
    }

    return ['WHERE ' . implode(' AND ', $where), $params];
}

// Helper for Vendors
function buildVendorWaWhere($state, $district, $taluka, $search = '') {
    $where = ["v.phone IS NOT NULL AND TRIM(v.phone) != ''"];
    $params = [];

    if (!empty($state)) {
        $where[] = "(v.state = :v_state OR LOWER(h.hotel_address) LIKE :v_state_like)";
        $params[':v_state'] = $state;
        $params[':v_state_like'] = '%' . strtolower($state) . '%';
    }
    if (!empty($district)) {
        $where[] = "(v.district = :v_dist OR LOWER(h.city) = LOWER(:v_city) OR LOWER(h.hotel_address) LIKE :v_dist_like)";
        $params[':v_dist'] = $district;
        $params[':v_city'] = $district;
        $params[':v_dist_like'] = '%' . strtolower($district) . '%';
    }
    if (!empty($taluka)) {
        $where[] = "(v.taluka = :v_tal OR LOWER(h.hotel_address) LIKE :v_tal_like)";
        $params[':v_tal'] = $taluka;
        $params[':v_tal_like'] = '%' . strtolower($taluka) . '%';
    }
    if (!empty($search)) {
        $where[] = "(v.full_name LIKE :v_search OR v.email LIKE :v_search OR v.phone LIKE :v_search)";
        $params[':v_search'] = '%' . $search . '%';
    }

    return ['WHERE ' . implode(' AND ', $where), $params];
}

// Helper for Drivers
function buildDriverWaWhere($state, $district, $taluka, $search = '') {
    $where = ["d.phone_number IS NOT NULL AND TRIM(d.phone_number) != ''"];
    $params = [];

    if (!empty($state)) {
        $where[] = "d.state = :d_state";
        $params[':d_state'] = $state;
    }
    if (!empty($district)) {
        $where[] = "d.district = :d_dist";
        $params[':d_dist'] = $district;
    }
    if (!empty($taluka)) {
        $where[] = "d.taluka = :d_tal";
        $params[':d_tal'] = $taluka;
    }
    if (!empty($search)) {
        $where[] = "(d.full_name LIKE :d_search OR d.email LIKE :d_search OR d.phone_number LIKE :d_search)";
        $params[':d_search'] = '%' . $search . '%';
    }

    return ['WHERE ' . implode(' AND ', $where), $params];
}

try {
    // 1. Calculate counts for Customers
    [$custClause, $custParams] = buildCustomerWaWhere($state, $district, $taluka);
    $custSql = "
        SELECT COUNT(DISTINCT c.id) AS total
        FROM customers c
        LEFT JOIN customer_addresses ca ON ca.customer_id = c.id
        $custClause
    ";
    $stmtCust = $pdo->prepare($custSql);
    $stmtCust->execute($custParams);
    $custCount = (int)$stmtCust->fetchColumn();

    // 2. Calculate counts for Vendors
    [$vendClause, $vendParams] = buildVendorWaWhere($state, $district, $taluka);
    $vendSql = "
        SELECT COUNT(DISTINCT v.id) AS total
        FROM vendors v
        LEFT JOIN hotels h ON h.vendor_id = v.id
        $vendClause
    ";
    $stmtVend = $pdo->prepare($vendSql);
    $stmtVend->execute($vendParams);
    $vendCount = (int)$stmtVend->fetchColumn();

    // 3. Calculate counts for Drivers
    [$drivClause, $drivParams] = buildDriverWaWhere($state, $district, $taluka);
    $drivSql = "
        SELECT COUNT(DISTINCT d.id) AS total
        FROM drivers d
        $drivClause
    ";
    $stmtDriv = $pdo->prepare($drivSql);
    $stmtDriv->execute($drivParams);
    $drivCount = (int)$stmtDriv->fetchColumn();

    if ($target === 'customers') {
        $totalTargetPhoneUsers = $custCount;
    } elseif ($target === 'vendors') {
        $totalTargetPhoneUsers = $vendCount;
    } elseif ($target === 'drivers') {
        $totalTargetPhoneUsers = $drivCount;
    } else {
        $totalTargetPhoneUsers = $custCount + $vendCount + $drivCount;
    }

    // 4. Retrieve List of Recipients with Phone Numbers
    $recipients = [];
    $totalListCount = 0;

    $activeUserType = ($userType !== 'all') ? $userType : (($target !== 'all') ? $target : 'all');

    $fetchCustomers = ($activeUserType === 'all' || $activeUserType === 'customers');
    $fetchVendors   = ($activeUserType === 'all' || $activeUserType === 'vendors');
    $fetchDrivers   = ($activeUserType === 'all' || $activeUserType === 'drivers');

    $unionQueries = [];
    $unionParams  = [];

    if ($fetchCustomers) {
        [$cW, $cP] = buildCustomerWaWhere($state, $district, $taluka, $search);
        $unionQueries[] = "
            SELECT c.id, 'Customer' AS role_type, c.full_name AS name,
                   c.email, c.phone_number AS phone,
                   COALESCE(NULLIF(TRIM(c.district), ''), MAX(ca.district), '') AS district,
                   COALESCE(NULLIF(TRIM(c.taluka), ''), MAX(ca.taluka), '') AS taluka,
                   1 AS has_phone, c.created_at
            FROM customers c
            LEFT JOIN customer_addresses ca ON ca.customer_id = c.id
            $cW
            GROUP BY c.id, c.full_name, c.email, c.phone_number, c.district, c.taluka, c.created_at
        ";
        $unionParams = array_merge($unionParams, $cP);
    }

    if ($fetchVendors) {
        [$vW, $vP] = buildVendorWaWhere($state, $district, $taluka, $search);
        $unionQueries[] = "
            SELECT v.id, 'Vendor' AS role_type, v.full_name AS name,
                   v.email, v.phone AS phone,
                   COALESCE(NULLIF(TRIM(v.district), ''), MAX(h.city), '') AS district,
                   COALESCE(NULLIF(TRIM(v.taluka), ''), '') AS taluka,
                   1 AS has_phone, v.created_at
            FROM vendors v
            LEFT JOIN hotels h ON h.vendor_id = v.id
            $vW
            GROUP BY v.id, v.full_name, v.email, v.phone, v.district, v.taluka, v.created_at
        ";
        $unionParams = array_merge($unionParams, $vP);
    }

    if ($fetchDrivers) {
        [$dW, $dP] = buildDriverWaWhere($state, $district, $taluka, $search);
        $unionQueries[] = "
            SELECT d.id, 'Driver' AS role_type, d.full_name AS name,
                   d.email, d.phone_number AS phone,
                   COALESCE(NULLIF(TRIM(d.district), ''), '') AS district,
                   COALESCE(NULLIF(TRIM(d.taluka), ''), '') AS taluka,
                   1 AS has_phone, d.created_at
            FROM drivers d
            $dW
            GROUP BY d.id, d.full_name, d.email, d.phone_number, d.district, d.taluka, d.created_at
        ";
        $unionParams = array_merge($unionParams, $dP);
    }

    if (!empty($unionQueries)) {
        $fullUnionSql = implode(" UNION ALL ", $unionQueries);
        
        $countUnionSql = "SELECT COUNT(*) FROM ($fullUnionSql) AS combined_list";
        $stmtCount = $pdo->prepare($countUnionSql);
        $stmtCount->execute($unionParams);
        $totalListCount = (int)$stmtCount->fetchColumn();

        $paginatedUnionSql = "$fullUnionSql ORDER BY created_at DESC LIMIT $limit OFFSET $offset";
        $stmtList = $pdo->prepare($paginatedUnionSql);
        $stmtList->execute($unionParams);
        $recipients = $stmtList->fetchAll(PDO::FETCH_ASSOC);
    }

    sendSuccess('WhatsApp target metrics and preview fetched successfully.', [
        'filters' => [
            'target'   => $target,
            'state'    => $state,
            'district' => $district,
            'taluka'   => $taluka,
        ],
        'counts' => [
            'total_users'     => $totalTargetPhoneUsers,
            'total_phones'    => $totalTargetPhoneUsers,
            'customers_total' => $custCount,
            'vendors_total'   => $vendCount,
            'drivers_total'   => $drivCount,
        ],
        'recipients' => [
            'active_tab'   => $activeUserType,
            'total_count'  => $totalListCount,
            'page'         => $page,
            'limit'        => $limit,
            'total_pages'  => $totalListCount > 0 ? ceil($totalListCount / $limit) : 1,
            'list'         => $recipients,
        ]
    ]);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
