<?php
/**
 * GET /api/admin/locations
 *
 * Retrieve lists of manual locations (cities, pincodes, areas, sub-areas, plans) or dropdown lists.
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

$type   = isset($_GET['type'])   ? trim($_GET['type'])   : 'all'; // city, pincode, area, sub_area, plan, dropdowns, all
$search = isset($_GET['search']) ? trim($_GET['search']) : '';
$status = isset($_GET['status']) ? trim($_GET['status']) : 'all'; // all, active, inactive

$pdo = getDBConnection();

try {
    if ($type === 'dropdowns') {
        // Fetch all active elements for dropdown select inputs
        $cities = $pdo->query("SELECT id, city_name FROM cities WHERE is_active = 1 ORDER BY city_name ASC")->fetchAll(PDO::FETCH_ASSOC);
        
        $pincodes = $pdo->query("
            SELECT p.id, p.pincode, c.city_name 
            FROM pincodes p
            JOIN cities c ON p.city_id = c.id
            WHERE p.is_active = 1 AND c.is_active = 1
            ORDER BY p.pincode ASC
        ")->fetchAll(PDO::FETCH_ASSOC);

        $areas = $pdo->query("
            SELECT a.id, a.area_name, p.pincode, c.city_name
            FROM areas a
            JOIN pincodes p ON a.pincode_id = p.id
            JOIN cities c ON p.city_id = c.id
            WHERE a.is_active = 1 AND p.is_active = 1 AND c.is_active = 1
            ORDER BY a.area_name ASC
        ")->fetchAll(PDO::FETCH_ASSOC);

        $subAreas = $pdo->query("
            SELECT s.id, s.sub_area_name, a.area_name, p.pincode, c.city_name
            FROM sub_areas s
            JOIN areas a ON s.area_id = a.id
            JOIN pincodes p ON a.pincode_id = p.id
            JOIN cities c ON p.city_id = c.id
            WHERE s.is_active = 1 AND a.is_active = 1 AND p.is_active = 1 AND c.is_active = 1
            ORDER BY s.sub_area_name ASC
        ")->fetchAll(PDO::FETCH_ASSOC);

        sendSuccess('Dropdown lists retrieved successfully.', [
            'cities'    => $cities,
            'pincodes'  => $pincodes,
            'areas'     => $areas,
            'sub_areas' => $subAreas
        ]);
        exit;
    }

    $whereClauses = [];
    $params = [];

    if ($status === 'active') {
        $whereClauses[] = "x.is_active = 1";
    } elseif ($status === 'inactive') {
        $whereClauses[] = "x.is_active = 0";
    }

    // Branch based on list type
    if ($type === 'city') {
        if ($search !== '') {
            $whereClauses[] = "x.city_name LIKE :search";
            $params[':search'] = '%' . $search . '%';
        }
        $where = count($whereClauses) > 0 ? 'WHERE ' . implode(' AND ', $whereClauses) : '';
        
        $sql = "SELECT x.* FROM cities x $where ORDER BY x.city_name ASC";
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $result = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Format
        foreach ($result as &$row) {
            $row['id'] = (int)$row['id'];
            $row['is_active'] = (bool)$row['is_active'];
        }
        sendSuccess('Cities retrieved successfully.', ['list' => $result]);
        
    } elseif ($type === 'pincode') {
        if ($search !== '') {
            $searchPattern = '%' . $search . '%';
            $whereClauses[] = "(x.pincode LIKE :loc_p1 OR c.city_name LIKE :loc_p2)";
            $params[':loc_p1'] = $searchPattern;
            $params[':loc_p2'] = $searchPattern;
        }
        $where = count($whereClauses) > 0 ? 'WHERE ' . implode(' AND ', $whereClauses) : '';
        
        $sql = "
            SELECT x.*, c.city_name 
            FROM pincodes x
            JOIN cities c ON x.city_id = c.id
            $where 
            ORDER BY x.pincode ASC
        ";
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $result = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        foreach ($result as &$row) {
            $row['id'] = (int)$row['id'];
            $row['city_id'] = (int)$row['city_id'];
            $row['is_active'] = (bool)$row['is_active'];
        }
        sendSuccess('Pincodes retrieved successfully.', ['list' => $result]);
        
    } elseif ($type === 'area') {
        if ($search !== '') {
            $searchPattern = '%' . $search . '%';
            $whereClauses[] = "(x.area_name LIKE :loc_a1 OR p.pincode LIKE :loc_a2 OR c.city_name LIKE :loc_a3)";
            $params[':loc_a1'] = $searchPattern;
            $params[':loc_a2'] = $searchPattern;
            $params[':loc_a3'] = $searchPattern;
        }
        $where = count($whereClauses) > 0 ? 'WHERE ' . implode(' AND ', $whereClauses) : '';
        
        $sql = "
            SELECT x.*, p.pincode, c.city_name, c.id AS city_id
            FROM areas x
            JOIN pincodes p ON x.pincode_id = p.id
            JOIN cities c ON p.city_id = c.id
            $where 
            ORDER BY x.area_name ASC
        ";
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $result = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        foreach ($result as &$row) {
            $row['id'] = (int)$row['id'];
            $row['pincode_id'] = (int)$row['pincode_id'];
            $row['city_id'] = (int)$row['city_id'];
            $row['is_active'] = (bool)$row['is_active'];
        }
        sendSuccess('Areas retrieved successfully.', ['list' => $result]);
        
    } elseif ($type === 'sub_area') {
        if ($search !== '') {
            $searchPattern = '%' . $search . '%';
            $whereClauses[] = "(x.sub_area_name LIKE :loc_sa1 OR a.area_name LIKE :loc_sa2 OR p.pincode LIKE :loc_sa3 OR c.city_name LIKE :loc_sa4)";
            $params[':loc_sa1'] = $searchPattern;
            $params[':loc_sa2'] = $searchPattern;
            $params[':loc_sa3'] = $searchPattern;
            $params[':loc_sa4'] = $searchPattern;
        }
        $where = count($whereClauses) > 0 ? 'WHERE ' . implode(' AND ', $whereClauses) : '';
        
        $sql = "
            SELECT x.*, a.area_name, p.pincode, c.city_name, c.id AS city_id, p.id AS pincode_id
            FROM sub_areas x
            JOIN areas a ON x.area_id = a.id
            JOIN pincodes p ON a.pincode_id = p.id
            JOIN cities c ON p.city_id = c.id
            $where 
            ORDER BY x.sub_area_name ASC
        ";
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $result = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        foreach ($result as &$row) {
            $row['id'] = (int)$row['id'];
            $row['area_id'] = (int)$row['area_id'];
            $row['pincode_id'] = (int)$row['pincode_id'];
            $row['city_id'] = (int)$row['city_id'];
            $row['latitude'] = (float)$row['latitude'];
            $row['longitude'] = (float)$row['longitude'];
            $row['delivery_radius'] = (float)$row['delivery_radius'];
            $row['delivery_charge'] = number_format((float)$row['delivery_charge'], 2, '.', '');
            $row['is_active'] = (bool)$row['is_active'];
            unset($row['location']);
        }
        sendSuccess('Sub Areas retrieved successfully.', ['list' => $result]);
        
    } elseif ($type === 'plan') {
        if ($search !== '') {
            $searchPattern = '%' . $search . '%';
            $whereClauses[] = "(x.plan_name LIKE :loc_pl1 OR sa.sub_area_name LIKE :loc_pl2 OR a.area_name LIKE :loc_pl3 OR p.pincode LIKE :loc_pl4 OR c.city_name LIKE :loc_pl5)";
            $params[':loc_pl1'] = $searchPattern;
            $params[':loc_pl2'] = $searchPattern;
            $params[':loc_pl3'] = $searchPattern;
            $params[':loc_pl4'] = $searchPattern;
            $params[':loc_pl5'] = $searchPattern;
        }
        $where = count($whereClauses) > 0 ? 'WHERE ' . implode(' AND ', $whereClauses) : '';
        
        $sql = "
            SELECT x.*, sa.sub_area_name, a.area_name, p.pincode, c.city_name, c.id AS city_id, p.id AS pincode_id, a.id AS area_id
            FROM subscription_plans x
            JOIN sub_areas sa ON x.sub_area_id = sa.id
            JOIN areas a ON sa.area_id = a.id
            JOIN pincodes p ON a.pincode_id = p.id
            JOIN cities c ON p.city_id = c.id
            $where 
            ORDER BY x.plan_name ASC
        ";
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $result = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        foreach ($result as &$row) {
            $row['id'] = (int)$row['id'];
            $row['sub_area_id'] = (int)$row['sub_area_id'];
            $row['area_id'] = (int)$row['area_id'];
            $row['pincode_id'] = (int)$row['pincode_id'];
            $row['city_id'] = (int)$row['city_id'];
            $row['price'] = number_format((float)$row['price'], 2, '.', '');
            $row['duration'] = (int)$row['duration'];
            $row['total_deliveries'] = (int)$row['total_deliveries'];
            $row['meals_per_day'] = (int)$row['meals_per_day'];
            $row['discount'] = number_format((float)$row['discount'], 2, '.', '');
            $row['delivery_charge'] = number_format((float)$row['delivery_charge'], 2, '.', '');
            $row['is_active'] = (bool)$row['is_active'];
        }
        sendSuccess('Subscription Plans retrieved successfully.', ['list' => $result]);
        
    } else {
        sendError('Invalid type. Specify city, pincode, area, sub_area, plan, or dropdowns.', 400);
    }
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
