<?php
/**
 * GET /api/admin/vendors
 *
 * Retrieves paginated list of vendors for admin panel with optional location filters.
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
$page     = isset($_GET['page']) ? (int)$_GET['page'] : 1;
$limit    = isset($_GET['limit']) ? (int)$_GET['limit'] : 10;

if ($page < 1) $page = 1;
if ($limit < 1 || $limit > 100) $limit = 10;
$offset = ($page - 1) * $limit;

$pdo = getDBConnection();
ensureVendorLocationColumns($pdo);

// Build WHERE clauses
$where = [];
$params = [];

// Location Params
$country  = isset($_GET['country'])  ? trim($_GET['country'])  : '';
$state    = isset($_GET['state'])    ? trim($_GET['state'])    : '';
$district = isset($_GET['district']) ? trim($_GET['district']) : '';
$taluka   = isset($_GET['taluka'])   ? trim($_GET['taluka'])   : '';
$region   = isset($_GET['region'])   ? trim($_GET['region'])   : '';
$area     = isset($_GET['area'])     ? trim($_GET['area'])     : '';

if ($search !== '') {
    $searchId = preg_replace('/[^0-9]/', '', $search);
    $searchPattern = '%' . $search . '%';
    $searchFields = [
        'v.full_name', 'v.email', 'v.phone', 'v.mobile_number',
        'v.owner_name', 'v.business_name', 'h.hotel_name', 'h.city', 'h.hotel_address'
    ];
    $searchParts = [];
    if ($searchId !== '' && (strpos($search, '#') === 0 || is_numeric($search))) {
        $searchParts[] = "v.id = :search_id";
        $params[':search_id'] = (int)$searchId;
    }
    foreach ($searchFields as $idx => $f) {
        $key = ':s_' . $idx;
        $searchParts[] = "$f LIKE $key";
        $params[$key] = $searchPattern;
    }
    $where[] = '(' . implode(' OR ', $searchParts) . ')';
}

if ($status === 'active') {
    $where[] = "v.is_active = 1";
} elseif ($status === 'inactive') {
    $where[] = "v.is_active = 0";
} elseif ($status === 'online') {
    $where[] = "v.is_online = 1";
} elseif ($status === 'offline') {
    $where[] = "(v.is_online = 0 OR v.is_online IS NULL)";
}

if ($date !== '' && strtolower($date) !== 'all') {
    $where[] = "DATE(v.created_at) = :filter_date";
    $params[':filter_date'] = $date;
}

if ($country !== '' && strtolower($country) !== 'all') {
    if (in_array(strtolower($country), ['india', 'in'])) {
        $where[] = "(v.country IN ('India', 'IN') OR v.country IS NULL OR v.country = '')";
    } else {
        $where[] = "(v.country = :country1 OR LOWER(h.hotel_address) LIKE :country2)";
        $cPattern = '%' . strtolower($country) . '%';
        $params[':country1'] = $country;
        $params[':country2'] = $cPattern;
    }
}

if ($state !== '' && strtolower($state) !== 'all') {
    $where[] = "(v.state = :state OR (COALESCE(v.state, '') = '' AND h.state = :state))";
    $params[':state'] = $state;
}

if ($district !== '' && strtolower($district) !== 'all') {
    $where[] = "(v.district = :district OR (COALESCE(v.district, '') = '' AND (h.district = :district OR h.city = :district)))";
    $params[':district'] = $district;
}

if ($taluka !== '' && strtolower($taluka) !== 'all') {
    $where[] = "(v.taluka = :taluka OR (COALESCE(v.taluka, '') = '' AND h.taluka = :taluka))";
    $params[':taluka'] = $taluka;
}

if ($region !== '' && strtolower($region) !== 'all') {
    $where[] = "(v.region = :region OR (COALESCE(v.region, '') = '' AND h.region = :region))";
    $params[':region'] = $region;
}

if ($area !== '' && strtolower($area) !== 'all') {
    $where[] = "(v.area = :area OR (COALESCE(v.area, '') = '' AND h.area = :area))";
    $params[':area'] = $area;
}

$whereClause = count($where) > 0 ? 'WHERE ' . implode(' AND ', $where) : '';

try {
    // Get total count
    $countSql = "SELECT COUNT(DISTINCT v.id) FROM vendors v LEFT JOIN hotels h ON h.vendor_id = v.id $whereClause";
    $countStmt = $pdo->prepare($countSql);
    $countStmt->execute($params);
    $totalRecords = (int) $countStmt->fetchColumn();
    $totalPages   = $totalRecords > 0 ? ceil($totalRecords / $limit) : 1;

    // Get paginated results with hotel count and associated driver count, showing online vendors first
    $sql = "
        SELECT v.id, v.full_name, v.email, COALESCE(v.phone, '') AS phone, v.is_active,
               COALESCE(v.is_online, 0) AS is_online,
               MAX(COALESCE(NULLIF(TRIM(v.country), ''), 'India')) AS country,
               MAX(COALESCE(NULLIF(TRIM(v.state), ''), '')) AS state,
               MAX(COALESCE(NULLIF(TRIM(v.district), ''), NULLIF(TRIM(h.city), ''), '')) AS district,
               MAX(COALESCE(NULLIF(TRIM(v.taluka), ''), NULLIF(TRIM(h.taluka), ''), '')) AS taluka,
               MAX(COALESCE(NULLIF(TRIM(v.region), ''), NULLIF(TRIM(h.region), ''), '')) AS region,
               MAX(COALESCE(NULLIF(TRIM(v.area), ''), NULLIF(TRIM(h.area), ''), '')) AS area,
               v.bank_name, v.account_holder_name, v.account_number, v.ifsc_code, v.created_at, v.updated_at,
               COUNT(DISTINCT h.id) AS hotel_count,
               COUNT(DISTINCT d.id) AS driver_count
        FROM vendors v
        LEFT JOIN hotels h ON h.vendor_id = v.id
        LEFT JOIN drivers d ON d.vendor_id = v.id
        $whereClause
        GROUP BY v.id
        ORDER BY " . ($sort === 'oldest' ? 'v.created_at ASC, v.id ASC' : ($sort === 'online' ? 'COALESCE(v.is_online, 0) DESC, v.created_at DESC, v.id DESC' : 'v.created_at DESC, v.id DESC')) . "
        LIMIT :limit OFFSET :offset
    ";
    
    $stmt = $pdo->prepare($sql);
    
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    foreach ($params as $key => $val) {
        $stmt->bindValue($key, $val);
    }
    
    $stmt->execute();
    $vendors = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Format fields & fetch hotels/revenue per vendor
    foreach ($vendors as &$vendor) {
        $vendor['id'] = (int) $vendor['id'];
        $vendor['is_active'] = (bool) $vendor['is_active'];
        $vendor['is_online'] = (bool) $vendor['is_online'];
        $vendor['hotel_count'] = (int) $vendor['hotel_count'];
        $vendor['driver_count'] = (int) $vendor['driver_count'];

        // Bank details sub-object
        $vendor['bank_details'] = [
            'bank_name' => $vendor['bank_name'] ?? '',
            'account_holder_name' => $vendor['account_holder_name'] ?? '',
            'account_number' => $vendor['account_number'] ?? '',
            'ifsc_code' => $vendor['ifsc_code'] ?? '',
        ];

        // Fetch registered hotels for this vendor
        $hotelStmt = $pdo->prepare("SELECT id, hotel_name, hotel_address, owner_name, mobile_number, email, pan_number, pan_photo_url, aadhar_number, aadhar_photo_url, fssai_number, fssai_photo_url, shop_act_number, shop_act_photo_url, udyam_aadhar_number, udyam_aadhar_photo_url, photo_url FROM hotels WHERE vendor_id = :vendor_id");
        $hotelStmt->execute([':vendor_id' => $vendor['id']]);
        $vendor['hotels'] = $hotelStmt->fetchAll(PDO::FETCH_ASSOC);

        // Calculate Daily and Weekly Revenue for this vendor
        $todayStr = date('Y-m-d');
        $weekAgoStr = date('Y-m-d', strtotime('-7 days'));

        $revStmt = $pdo->prepare("
            SELECT 
                COALESCE(SUM(CASE WHEN DATE(o.created_at) = :today THEN o.grand_total ELSE 0 END), 0.00) AS daily_revenue,
                COALESCE(SUM(CASE WHEN DATE(o.created_at) >= :week_ago THEN o.grand_total ELSE 0 END), 0.00) AS weekly_revenue
            FROM orders o
            JOIN hotels h ON h.id = o.hotel_id
            WHERE h.vendor_id = :vendor_id AND o.status != 'cancelled'
        ");
        $revStmt->execute([
            ':today' => $todayStr,
            ':week_ago' => $weekAgoStr,
            ':vendor_id' => $vendor['id']
        ]);
        $rev = $revStmt->fetch(PDO::FETCH_ASSOC);

        $vendor['daily_revenue'] = number_format((float)($rev['daily_revenue'] ?? 0), 2, '.', '');
        $vendor['weekly_revenue'] = number_format((float)($rev['weekly_revenue'] ?? 0), 2, '.', '');
    }

    sendSuccess('Vendors fetched successfully.', [
        'vendors' => $vendors,
        'pagination' => [
            'total_records' => $totalRecords,
            'total_pages'   => $totalPages,
            'current_page'  => $page,
            'per_page'      => $limit
        ]
    ]);

} catch (PDOException $e) {
    sendError('Database error fetching vendors: ' . $e->getMessage(), 500);
}
