<?php
/**
 * POST /api/admin/service-locations/delete
 *
 * Delete a service_location or a specific plan.
 * Dual-syncs deletion to both new tables (service_locations, plans)
 * and legacy tables (sub_areas, subscription_plans) to ensure complete removal.
 *
 * Body: { id, type? }   // type = 'plan' or 'service_location' (default: 'service_location')
 */

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/validation.php';
require_once __DIR__ . '/../../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST')    { sendError('Method not allowed. Use POST.', 405); }

$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || !isset($payload['sub']) || ($payload['role'] ?? '') !== 'admin') {
    sendError('Unauthorized. Admin access required.', 401);
}

$rawBody = file_get_contents('php://input');
$body    = json_decode($rawBody, true) ?? [];

$id   = isset($body['id']) ? (int)$body['id'] : 0;
$type = trim($body['type'] ?? 'service_location');

if ($id <= 0) { sendError('Invalid ID.', 422); }

$pdo = getDBConnection();

try {
    if ($type === 'plan') {
        // Delete plan from plans table
        $legacyPlanId = null;
        $stmt = $pdo->prepare("SELECT legacy_plan_id FROM plans WHERE id = ?");
        $stmt->execute([$id]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if ($row) {
            $legacyPlanId = $row['legacy_plan_id'];
        }

        $delPlan = $pdo->prepare("DELETE FROM plans WHERE id = ?");
        $delPlan->execute([$id]);

        // Also delete from legacy subscription_plans table
        if ($legacyPlanId) {
            $delLegacy = $pdo->prepare("DELETE FROM subscription_plans WHERE id = ?");
            $delLegacy->execute([$legacyPlanId]);
        } else {
            $delLegacy = $pdo->prepare("DELETE FROM subscription_plans WHERE id = ?");
            $delLegacy->execute([$id]);
        }

        sendSuccess("Plan deleted successfully.", ['id' => $id, 'type' => 'plan']);
        exit;
    }

    // ── Delete whole Service Location ──────────────────────────────────────────
    // Fetch location details before deletion to locate matching legacy sub_area
    $stmt = $pdo->prepare("SELECT id, location_name FROM service_locations WHERE id = :id LIMIT 1");
    $stmt->execute([':id' => $id]);
    $loc = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$loc) {
        // Try fallback to sub_areas
        $stmtSa = $pdo->prepare("SELECT id, sub_area_name FROM sub_areas WHERE id = :id LIMIT 1");
        $stmtSa->execute([':id' => $id]);
        $saLoc = $stmtSa->fetch(PDO::FETCH_ASSOC);

        if (!$saLoc) {
            sendError('Service location not found.', 404);
        }
        $loc = ['id' => $saLoc['id'], 'location_name' => $saLoc['sub_area_name']];
    }

    $locId   = (int)$loc['id'];
    $locName = $loc['location_name'];

    // 1. Delete child plans
    $pdo->prepare("DELETE FROM plans WHERE service_location_id = ?")->execute([$locId]);

    // 2. Delete main service_location
    $pdo->prepare("DELETE FROM service_locations WHERE id = ?")->execute([$locId]);

    // 3. Delete matching sub_area child plans
    $pdo->prepare("DELETE FROM subscription_plans WHERE sub_area_id = ?")->execute([$locId]);

    // 4. Delete matching sub_area
    $pdo->prepare("DELETE FROM sub_areas WHERE id = ? OR sub_area_name = ?")->execute([$locId, $locName]);

    sendSuccess("Successfully deleted the service location and all associated plans.", [
        'id' => $locId
    ]);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
