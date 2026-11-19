<?php
/**
 * GET /api/admin/drivers
 *
 * Retrieves a paginated list of delivery drivers with optional location filters.
 * Query Params: search, status (all, online, offline), country, state, district, taluka, page, limit
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

// Params
$search   = isset($_GET['search'])   ? trim($_GET['search'])   : '';
$status   = isset($_GET['status'])   ? trim($_GET['status'])   : 'all'; // all, online, offline, active, inactive
$sort     = isset($_GET['sort'])     ? trim($_GET['sort'])     : 'newest'; // newest (date DESC), oldest (date ASC), online
$date     = isset($_GET['date'])     ? trim($_GET['date'])     : ''; // YYYY-MM-DD
$vendorId = isset($_GET['vendor_id']) ? (int)$_GET['vendor_id'] : 0;
$country  = isset($_GET['country'])  ? trim($_GET['country'])  : '';
$state    = isset($_GET['state'])    ? trim($_GET['state'])    : '';
$district = isset($_GET['district']) ? trim($_GET['district']) : '';
$taluka   = isset($_GET['taluka'])   ? trim($_GET['taluka'])   : '';
$page     = isset($_GET['page'])     ? (int)$_GET['page']      : 1;
$limit    = isset($_GET['limit'])    ? (int)$_GET['limit']     : 10;

if ($page < 1) $page = 1;
if ($limit < 1 || $limit > 100) $limit = 10;
$offset = ($page - 1) * $limit;

$pdo = getDBConnection();

$where  = [];
$params = [];

if ($search !== '') {
    $searchId = preg_replace('/[^0-9]/', '', $search);
    $searchPattern = '%' . $search . '%';
    $searchFields = [
        'd.full_name', 'd.email', 'd.phone_number', 'd.vehicle_number',
        'v.full_name', 'v.business_name', 'd.district', 'd.taluka'
    ];
    $searchParts = [];
    if ($searchId !== '' && (strpos($search, '#') === 0 || is_numeric($search))) {
        $searchParts[] = "d.id = :search_id";
        $params[':search_id'] = (int)$searchId;
    }
    foreach ($searchFields as $idx => $f) {
        $key = ':ds_' . $idx;
        $searchParts[] = "$f LIKE $key";
        $params[$key] = $searchPattern;
    }
    $where[] = '(' . implode(' OR ', $searchParts) . ')';
}

if ($status === 'online') {
    $where[] = "d.is_online = 1";
} elseif ($status === 'offline') {
    $where[] = "(d.is_online = 0 OR d.is_online IS NULL)";
} elseif ($status === 'active') {
    $where[] = "(d.status = 'active' OR d.status IS NULL)";
} elseif ($status === 'inactive') {
    $where[] = "d.status = 'inactive'";
}

if ($date !== '' && strtolower($date) !== 'all') {
    $where[] = "DATE(d.created_at) = :filter_date";
    $params[':filter_date'] = $date;
}

if ($vendorId > 0) {
    $where[] = "d.vendor_id = :vendor_id";
    $params[':vendor_id'] = $vendorId;
}

if ($country !== '' && strtolower($country) !== 'all') {
    if (in_array(strtolower($country), ['india', 'in'])) {
        $where[] = "(d.country IN ('India', 'IN') OR d.country IS NULL OR d.country = '')";
    } else {
        $where[] = "d.country = :country";
        $params[':country'] = $country;
    }
}
if ($state !== '' && strtolower($state) !== 'all') {
    $where[] = "d.state = :state";
    $params[':state'] = $state;
}
if ($district !== '' && strtolower($district) !== 'all') {
    $where[] = "d.district = :district";
    $params[':district'] = $district;
}
if ($taluka !== '' && strtolower($taluka) !== 'all') {
    $where[] = "d.taluka = :taluka";
    $params[':taluka'] = $taluka;
}

$whereClause = count($where) > 0 ? 'WHERE ' . implode(' AND ', $where) : '';

try {
    // Total Count
    $countSql  = "SELECT COUNT(DISTINCT d.id) FROM drivers d LEFT JOIN vendors v ON v.id = d.vendor_id $whereClause";
    $countStmt = $pdo->prepare($countSql);
    $countStmt->execute($params);
    $totalRecords = (int) $countStmt->fetchColumn();
    $totalPages   = $totalRecords > 0 ? ceil($totalRecords / $limit) : 1;

    // Records with vendor info and online-first ordering
    $sql = "
        SELECT d.id, d.vendor_id, d.full_name, d.email, d.phone_number, d.vehicle_number,
               COALESCE(d.is_online, 0) AS is_online,
               COALESCE(d.status, 'active') AS status,
               d.latitude, d.longitude,
               COALESCE(d.max_capacity, 3) AS max_capacity,
               COALESCE(d.country, 'India') AS country,
               COALESCE(d.state, '') AS state,
               COALESCE(d.district, '') AS district,
               COALESCE(d.taluka, '') AS taluka,
               d.created_at, d.updated_at,
               COALESCE(v.full_name, '') AS vendor_name,
               COALESCE(v.business_name, '') AS vendor_business_name,
               COALESCE(v.phone, '') AS vendor_phone
        FROM drivers d
        LEFT JOIN vendors v ON v.id = d.vendor_id
        $whereClause
        ORDER BY " . ($sort === 'oldest' ? 'd.created_at ASC, d.id ASC' : ($sort === 'online' ? 'COALESCE(d.is_online, 0) DESC, d.created_at DESC, d.id DESC' : 'd.created_at DESC, d.id DESC')) . "
        LIMIT :limit OFFSET :offset
    ";
    $stmt = $pdo->prepare($sql);
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    foreach ($params as $key => $val) {
        $stmt->bindValue($key, $val);
    }
    $stmt->execute();
    $drivers = $stmt->fetchAll(PDO::FETCH_ASSOC);

    foreach ($drivers as &$driver) {
        $driver['id'] = (int)$driver['id'];
        $driver['is_online'] = (bool)$driver['is_online'];
        $driver['max_capacity'] = (int)$driver['max_capacity'];
    }

    sendSuccess('Delivery drivers retrieved successfully.', [
        'drivers'    => $drivers,
        'pagination' => [
            'total_records' => $totalRecords,
            'total_pages'   => $totalPages,
            'current_page'  => $page,
            'per_page'      => $limit,
        ],
    ]);
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
