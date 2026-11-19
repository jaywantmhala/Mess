<?php
/**
 * GET /api/admin/service-locations
 *
 * List all service_locations with their plans.
 * Requires: Authorization: Bearer <JWT> (admin)
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

$search = isset($_GET['search']) ? trim($_GET['search']) : '';
$status = isset($_GET['status']) ? trim($_GET['status']) : 'all';

$pdo = getDBConnection();

try {
    // Build WHERE clause
    $where  = [];
    $params = [];

    if ($status === 'active')   { $where[] = "sl.status = 'active'"; }
    if ($status === 'inactive') { $where[] = "sl.status = 'inactive'"; }
    if ($search !== '') {
        $searchPattern = '%' . $search . '%';
        $where[] = "(sl.location_name LIKE :sl_s1 OR sl.address LIKE :sl_s2)";
        $params[':sl_s1'] = $searchPattern;
        $params[':sl_s2'] = $searchPattern;
    }
    $whereSQL = count($where) > 0 ? 'WHERE ' . implode(' AND ', $where) : '';

    // Fetch service locations
    $stmt = $pdo->prepare("
        SELECT sl.id, sl.location_name, sl.address, sl.latitude, sl.longitude,
               sl.radius_km, sl.tiffin_charge, sl.original_tiffin_charge, sl.country, sl.region, sl.status,
               sl.created_at, sl.updated_at
        FROM service_locations sl
        $whereSQL
        ORDER BY sl.location_name ASC
    ");
    $stmt->execute($params);
    $locations = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Fetch all plans for returned location IDs
    $locationIds = array_column($locations, 'id');
    $plansByLocation = [];
    if (!empty($locationIds)) {
        $inClause = implode(',', array_map('intval', $locationIds));
        $planRows = $pdo->query("
            SELECT id, service_location_id, plan_name, description, price, duration,
                   total_deliveries, meals_per_day, meal_type, delivery_time_slot,
                   discount, delivery_charge, tiffin_charge, status, legacy_plan_id
            FROM plans
            WHERE service_location_id IN ($inClause)
            ORDER BY price ASC
        ")->fetchAll(PDO::FETCH_ASSOC);

        foreach ($planRows as &$p) {
            $p['id']                  = (int)$p['id'];
            $p['service_location_id'] = (int)$p['service_location_id'];
            $p['price']               = number_format((float)$p['price'], 2, '.', '');
            $p['duration']            = (int)$p['duration'];
            $p['total_deliveries']    = (int)$p['total_deliveries'];
            $p['meals_per_day']       = (int)$p['meals_per_day'];
            $p['discount']            = number_format((float)$p['discount'], 2, '.', '');
            $p['delivery_charge']     = number_format((float)$p['delivery_charge'], 2, '.', '');
            $p['tiffin_charge']       = number_format((float)($p['tiffin_charge'] ?? 50.0), 2, '.', '');
            $p['legacy_plan_id']      = $p['legacy_plan_id'] ? (int)$p['legacy_plan_id'] : null;
            $plansByLocation[$p['service_location_id']][] = $p;
        }
        unset($p);
    }

    // Attach plans to each location
    foreach ($locations as &$loc) {
        $loc['id']                     = (int)$loc['id'];
        $loc['latitude']               = (float)$loc['latitude'];
        $loc['longitude']              = (float)$loc['longitude'];
        $loc['radius_km']              = (float)$loc['radius_km'];
        $curr                          = (float)($loc['tiffin_charge'] ?? 50.0);
        $orig                          = (float)($loc['original_tiffin_charge'] ?? 0.0);
        $loc['tiffin_charge']          = number_format($curr, 2, '.', '');
        $loc['original_tiffin_charge'] = number_format($orig, 2, '.', '');
        $loc['discount_percentage']    = ($orig > $curr && $orig > 0)
            ? round((($orig - $curr) / $orig) * 100, 1)
            : 0;
        $loc['plans']                  = $plansByLocation[$loc['id']] ?? [];
    }
    unset($loc);

    sendSuccess('Service locations retrieved successfully.', [
        'list'  => $locations,
        'total' => count($locations),
    ]);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
