<?php
/**
 * GET /api/admin/enquiries/list
 *
 * Retrieves website customer inquiries with filtering by:
 * - State, District, Taluka, Area
 * - Date-wise (today, yesterday, this_week, this_month, custom start/end date or specific date)
 * - Status & Search
 *
 * Headers: Authorization: Bearer <admin_token>
 */

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, Accept, Origin');

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
    sendError('Unauthorized. Please log in with admin account.', 401);
}

try {
    $pdo = getDBConnection();
    ensureEnquiriesTable($pdo);

    // Filters
    $state       = isset($_GET['state'])       ? trim($_GET['state'])       : '';
    $district    = isset($_GET['district'])    ? trim($_GET['district'])    : '';
    $taluka      = isset($_GET['taluka'])      ? trim($_GET['taluka'])      : '';
    $area        = isset($_GET['area'])        ? trim($_GET['area'])        : '';
    $status      = isset($_GET['status'])      ? trim($_GET['status'])      : 'all';
    $search      = isset($_GET['search'])      ? trim($_GET['search'])      : '';
    $dateFilter  = isset($_GET['date_filter']) ? trim($_GET['date_filter']) : 'all';
    $date        = isset($_GET['date'])        ? trim($_GET['date'])        : '';
    $startDate   = isset($_GET['start_date'])  ? trim($_GET['start_date'])  : (isset($_GET['date_from']) ? trim($_GET['date_from']) : '');
    $endDate     = isset($_GET['end_date'])    ? trim($_GET['end_date'])    : (isset($_GET['date_to']) ? trim($_GET['date_to']) : '');

    $page        = max(1, (int)($_GET['page'] ?? 1));
    $limit       = max(1, min(100, (int)($_GET['limit'] ?? 20)));
    $offset      = ($page - 1) * $limit;

    $where = [];
    $params = [];

    // Location Filters
    if ($state !== '' && strtolower($state) !== 'all') {
        $where[] = "state = :state";
        $params[':state'] = $state;
    }

    if ($district !== '' && strtolower($district) !== 'all') {
        $where[] = "district = :district";
        $params[':district'] = $district;
    }

    if ($taluka !== '' && strtolower($taluka) !== 'all') {
        $where[] = "taluka = :taluka";
        $params[':taluka'] = $taluka;
    }

    if ($area !== '' && strtolower($area) !== 'all') {
        $where[] = "(area = :area_exact OR area LIKE :area_like)";
        $params[':area_exact'] = $area;
        $params[':area_like'] = '%' . $area . '%';
    }

    // Status Filter
    if ($status !== '' && strtolower($status) !== 'all') {
        $where[] = "status = :status";
        $params[':status'] = $status;
    }

    // Search Filter
    if ($search !== '') {
        $where[] = "(name LIKE :s1 OR phone LIKE :s2 OR area LIKE :s3 OR taluka LIKE :s4 OR district LIKE :s5 OR notes LIKE :s6)";
        $searchPattern = '%' . $search . '%';
        $params[':s1'] = $searchPattern;
        $params[':s2'] = $searchPattern;
        $params[':s3'] = $searchPattern;
        $params[':s4'] = $searchPattern;
        $params[':s5'] = $searchPattern;
        $params[':s6'] = $searchPattern;
    }

    // Date-wise Filters
    if ($date !== '') {
        $where[] = "DATE(created_at) = :exact_date";
        $params[':exact_date'] = $date;
    } elseif ($startDate !== '' && $endDate !== '') {
        $where[] = "DATE(created_at) BETWEEN :start_date AND :end_date";
        $params[':start_date'] = $startDate;
        $params[':end_date']   = $endDate;
    } elseif ($startDate !== '') {
        $where[] = "DATE(created_at) >= :start_date_only";
        $params[':start_date_only'] = $startDate;
    } elseif ($endDate !== '') {
        $where[] = "DATE(created_at) <= :end_date_only";
        $params[':end_date_only'] = $endDate;
    } else {
        // Preset date filters
        switch ($dateFilter) {
            case 'today':
                $where[] = "DATE(created_at) = CURDATE()";
                break;
            case 'yesterday':
                $where[] = "DATE(created_at) = DATE_SUB(CURDATE(), INTERVAL 1 DAY)";
                break;
            case 'this_week':
                $where[] = "created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)";
                break;
            case 'this_month':
                $where[] = "YEAR(created_at) = YEAR(CURDATE()) AND MONTH(created_at) = MONTH(CURDATE())";
                break;
        }
    }

    $whereSql = !empty($where) ? 'WHERE ' . implode(' AND ', $where) : '';

    // Total Count with applied filters
    $countStmt = $pdo->prepare("SELECT COUNT(*) FROM `enquiries` $whereSql");
    $countStmt->execute($params);
    $totalCount = (int)$countStmt->fetchColumn();

    // Query records with pagination
    $query = "SELECT * FROM `enquiries` $whereSql ORDER BY `created_at` DESC, `id` DESC LIMIT :limit OFFSET :offset";
    $stmt = $pdo->prepare($query);

    foreach ($params as $k => $v) {
        $stmt->bindValue($k, $v);
    }
    $stmt->bindValue(':limit',  $limit,  PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();
    $enquiries = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Summary Statistics (overall counts)
    $statsStmt = $pdo->query("
        SELECT
            COUNT(*) AS total_all,
            SUM(CASE WHEN `status` = 'New' THEN 1 ELSE 0 END) AS total_new,
            SUM(CASE WHEN `status` = 'Contacted' THEN 1 ELSE 0 END) AS total_contacted,
            SUM(CASE WHEN `status` = 'In Progress' THEN 1 ELSE 0 END) AS total_in_progress,
            SUM(CASE WHEN `status` = 'Closed' THEN 1 ELSE 0 END) AS total_closed,
            SUM(CASE WHEN DATE(`created_at`) = CURDATE() THEN 1 ELSE 0 END) AS today_count
        FROM `enquiries`
    ");
    $summary = $statsStmt->fetch(PDO::FETCH_ASSOC) ?: [
        'total_all'         => 0,
        'total_new'         => 0,
        'total_contacted'   => 0,
        'total_in_progress' => 0,
        'total_closed'      => 0,
        'today_count'       => 0,
    ];

    // Distinct values in DB for active filter options
    $statesList = $pdo->query("SELECT DISTINCT `state` FROM `enquiries` WHERE `state` != '' ORDER BY `state` ASC")->fetchAll(PDO::FETCH_COLUMN);
    $districtsList = $pdo->query("SELECT DISTINCT `district` FROM `enquiries` WHERE `district` != '' ORDER BY `district` ASC")->fetchAll(PDO::FETCH_COLUMN);
    $talukasList = $pdo->query("SELECT DISTINCT `taluka` FROM `enquiries` WHERE `taluka` != '' ORDER BY `taluka` ASC")->fetchAll(PDO::FETCH_COLUMN);
    $areasList = $pdo->query("SELECT DISTINCT `area` FROM `enquiries` WHERE `area` != '' ORDER BY `area` ASC")->fetchAll(PDO::FETCH_COLUMN);

    sendSuccess('Enquiries retrieved successfully.', [
        'enquiries' => $enquiries,
        'pagination' => [
            'page'          => $page,
            'limit'         => $limit,
            'total_records' => $totalCount,
            'total_pages'   => (int)ceil($totalCount / $limit),
        ],
        'summary' => [
            'total_all'         => (int)($summary['total_all'] ?? 0),
            'total_new'         => (int)($summary['total_new'] ?? 0),
            'total_contacted'   => (int)($summary['total_contacted'] ?? 0),
            'total_in_progress' => (int)($summary['total_in_progress'] ?? 0),
            'total_closed'      => (int)($summary['total_closed'] ?? 0),
            'today_count'       => (int)($summary['today_count'] ?? 0),
        ],
        'available_filters' => [
            'states'    => $statesList,
            'districts' => $districtsList,
            'talukas'   => $talukasList,
            'areas'     => $areasList,
        ],
    ]);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
} catch (Exception $e) {
    sendError('Server error: ' . $e->getMessage(), 500);
}
