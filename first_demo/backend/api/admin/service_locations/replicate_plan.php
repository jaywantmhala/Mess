<?php
/**
 * POST /api/admin/service-locations/replicate-plan
 *
 * Replicate one or multiple subscription plans across selected service locations.
 * Requires: Authorization: Bearer <JWT> (admin)
 *
 * Body: {
 *   plans: [{
 *     plan_name,
 *     description?,
 *     price,
 *     duration,
 *     total_deliveries,
 *     meals_per_day,
 *     meal_type,
 *     delivery_time_slot,
 *     discount?,
 *     delivery_charge?,
 *     status
 *   }],
 *   target_location_ids: [int]
 * }
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

$rawPlans = [];
if (isset($body['plans']) && is_array($body['plans'])) {
    $rawPlans = $body['plans'];
} elseif (isset($body['plan']) && is_array($body['plan'])) {
    $rawPlans = [$body['plan']];
}

$targetLocationIds = is_array($body['target_location_ids'] ?? null) ? array_map('intval', $body['target_location_ids']) : [];

if (empty($rawPlans)) { sendError('At least one plan must be provided to copy.', 422); }
if (empty($targetLocationIds)) { sendError('At least one target service location must be selected.', 422); }

$pdo = getDBConnection();

try {
    $pdo->beginTransaction();

    $insP = $pdo->prepare("
        INSERT INTO plans
            (service_location_id, plan_name, description, price, duration,
             total_deliveries, meals_per_day, meal_type, delivery_time_slot,
             discount, delivery_charge, tiffin_charge, status)
        VALUES
            (:sl_id, :name, :desc, :price, :dur, :del, :meals, :type,
             :slot, :disc, :charge, :tiffin_charge, :status)
    ");

    $replicatedLocCount = 0;
    $totalPlansCopied = 0;

    foreach ($targetLocationIds as $locId) {
        if ($locId <= 0) continue;

        // Check if location exists
        $chk = $pdo->prepare("SELECT id FROM service_locations WHERE id = ? LIMIT 1");
        $chk->execute([$locId]);
        if (!$chk->fetch()) continue;

        $plansCopiedForThisLoc = 0;

        foreach ($rawPlans as $plan) {
            $pName    = trim(sanitize($plan['plan_name'] ?? ''));
            $pDesc    = trim(sanitize($plan['description'] ?? ''));
            $pPrice   = max(0, (float)($plan['price'] ?? 0));
            $pDur     = max(1, (int)($plan['duration'] ?? 30));
            $pDel     = max(1, (int)($plan['total_deliveries'] ?? 30));
            $pMeals   = max(1, (int)($plan['meals_per_day'] ?? 1));
            $pType    = in_array($plan['meal_type'] ?? '', ['VEG','NON-VEG','BOTH']) ? $plan['meal_type'] : 'VEG';
            $pSlot    = trim(sanitize($plan['delivery_time_slot'] ?? ''));
            $pDisc    = max(0, (float)($plan['discount'] ?? 0));
            $pCharge  = max(0, (float)($plan['delivery_charge'] ?? 0));
            $pTiffin  = max(0, (float)($plan['tiffin_charge'] ?? 50.00));
            $pStatus  = in_array($plan['status'] ?? '', ['active','inactive']) ? $plan['status'] : 'active';

            if (empty($pName)) continue;

            $insP->execute([
                ':sl_id'         => $locId,
                ':name'          => $pName,
                ':desc'          => $pDesc,
                ':price'         => $pPrice,
                ':dur'           => $pDur,
                ':del'           => $pDel,
                ':meals'         => $pMeals,
                ':type'          => $pType,
                ':slot'          => $pSlot,
                ':disc'          => $pDisc,
                ':charge'        => $pCharge,
                ':tiffin_charge' => $pTiffin,
                ':status'        => $pStatus,
            ]);

            $plansCopiedForThisLoc++;
            $totalPlansCopied++;
        }

        if ($plansCopiedForThisLoc > 0) {
            $replicatedLocCount++;
        }
    }

    $pdo->commit();

    sendSuccess([
        'replicated_location_count' => $replicatedLocCount,
        'total_plans_copied' => $totalPlansCopied,
        'message' => "Successfully copied {$totalPlansCopied} plan(s) to {$replicatedLocCount} service location(s)."
    ]);
} catch (Exception $e) {
    if ($pdo->inTransaction()) { $pdo->rollBack(); }
    sendError('Database error replicating plans: ' . $e->getMessage(), 500);
}
