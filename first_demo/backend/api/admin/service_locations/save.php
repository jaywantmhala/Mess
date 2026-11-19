<?php
/**
 * POST /api/admin/service-locations/save
 *
 * Create or update a service_location and sync its child plans.
 * Requires: Authorization: Bearer <JWT> (admin)
 *
 * Body: {
 *   id?,               // if present → update
 *   location_name,
 *   address?,
 *   latitude,
 *   longitude,
 *   radius_km,         // per-location radius — ALL plans inherit this
 *   country?,
 *   region?,
 *   status,            // 'active'|'inactive'
 *   plans: [{
 *     id?,             // if present → update existing plan
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
 *     status           // 'active'|'inactive'
 *   }]
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

$id           = isset($body['id']) ? (int)$body['id'] : null;
$locationName = trim(sanitize($body['location_name'] ?? ''));
$address      = trim($body['address'] ?? '');
$lat          = (float)($body['latitude']  ?? 0.0);
$lng          = (float)($body['longitude'] ?? 0.0);
$radiusKm     = max(0.1, (float)($body['radius_km'] ?? 5.0));
$country      = trim(sanitize($body['country'] ?? 'IN')) ?: 'IN';
$region       = trim(sanitize($body['region']  ?? ''));
$status       = in_array($body['status'] ?? '', ['active','inactive']) ? $body['status'] : 'active';
$tiffinCharge = max(0, (float)($body['tiffin_charge'] ?? 50.00));
$originalTiffinCharge = max(0, (float)($body['original_tiffin_charge'] ?? 0.00));
$plans        = is_array($body['plans'] ?? null) ? $body['plans'] : [];

if (empty($locationName)) { sendError('Location name is required.', 422); }
if ($lat === 0.0 && $lng === 0.0) { sendError('Latitude and longitude are required.', 422); }

$pdo = getDBConnection();

try {
    $pdo->beginTransaction();

    // ── Duplicate nearby location check (within 500 m for new locations) ───────
    $duplicateWarning = null;
    if (!$id && $lat !== 0.0 && $lng !== 0.0) {
        try {
            $dupStmt = $pdo->prepare("
                SELECT id, location_name,
                       ROUND(ST_Distance_Sphere(
                           location,
                           ST_PointFromText(CONCAT('POINT(', :lng, ' ', :lat, ')'), 4326)
                       ), 0) AS dist_m
                FROM service_locations
                WHERE status = 'active'
                  AND ST_Distance_Sphere(
                      location,
                      ST_PointFromText(CONCAT('POINT(', :lng2, ' ', :lat2, ')'), 4326)
                  ) <= 500
                LIMIT 1
            ");
            $dupStmt->execute([':lat' => $lat, ':lng' => $lng, ':lat2' => $lat, ':lng2' => $lng]);
            $dupRow = $dupStmt->fetch();
            if ($dupRow) {
                $duplicateWarning = "Notice: Active service location '{$dupRow['location_name']}' already exists within {$dupRow['dist_m']} meters.";
            }
        } catch (PDOException $ex) {}
    }

    // ── Batch multi-location creation check (if location_name has comma) ─────
    $rawNames = array_map('trim', explode(',', $locationName));
    $locationNames = array_values(array_filter($rawNames, function($n) { return !empty($n); }));

    if (!$id && count($locationNames) > 1) {
        $createdLocationIds = [];
        $insLoc = $pdo->prepare("
            INSERT INTO service_locations
                (location_name, address, latitude, longitude, location, radius_km, tiffin_charge, original_tiffin_charge, country, region, status)
            VALUES
                (:name, :addr, :lat, :lng,
                 ST_PointFromText(CONCAT('POINT(', :lng2, ' ', :lat2, ')'), 4326),
                 :radius, :tiffin_charge, :original_tiffin_charge, :country, :region, :status)
        ");

        $insP = $pdo->prepare("
            INSERT INTO plans
                (service_location_id, plan_name, description, price, duration,
                 total_deliveries, meals_per_day, meal_type, delivery_time_slot,
                 discount, delivery_charge, tiffin_charge, status)
            VALUES
                (:sl_id, :name, :desc, :price, :dur, :del, :meals, :type,
                 :slot, :disc, :charge, :tiffin_charge, :status)
        ");

        foreach ($locationNames as $lName) {
            $insLoc->execute([
                ':name'          => $lName,
                ':addr'          => $address,
                ':lat'           => $lat,
                ':lng'           => $lng,
                ':lng2'          => $lng,
                ':lat2'          => $lat,
                ':radius'                 => $radiusKm,
                ':tiffin_charge'          => $tiffinCharge,
                ':original_tiffin_charge' => $originalTiffinCharge,
                ':country'                => $country,
                ':region'        => $region,
                ':status'        => $status,
            ]);
            $locId = (int)$pdo->lastInsertId();
            $createdLocationIds[] = $locId;

            foreach ($plans as $p) {
                $pName    = trim(sanitize($p['plan_name'] ?? ''));
                $pDesc    = trim(sanitize($p['description'] ?? ''));
                $pPrice   = max(0, (float)($p['price'] ?? 0));
                $pDur     = max(1, (int)($p['duration'] ?? 30));
                $pDel     = max(1, (int)($p['total_deliveries'] ?? 30));
                $pMeals   = max(1, (int)($p['meals_per_day'] ?? 1));
                $pType    = in_array($p['meal_type'] ?? '', ['VEG','NON-VEG','BOTH']) ? $p['meal_type'] : 'VEG';
                $pSlot    = trim(sanitize($p['delivery_time_slot'] ?? ''));
                $pDisc    = max(0, (float)($p['discount'] ?? 0));
                $pCharge  = max(0, (float)($p['delivery_charge'] ?? 0));
                $pTiffin  = isset($p['tiffin_charge']) ? max(0, (float)$p['tiffin_charge']) : $tiffinCharge;
                $pStatus  = in_array($p['status'] ?? '', ['active','inactive']) ? $p['status'] : 'active';

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
            }
        }

        $pdo->commit();

        $count = count($createdLocationIds);
        sendSuccess("Created {$count} separate area-wise service locations successfully.", [
            'ids' => $createdLocationIds,
            'count' => $count
        ]);
        exit;
    }

    // ── Upsert service_location ────────────────────────────────────────────────
    if ($id) {
        // Verify exists
        $chk = $pdo->prepare("SELECT id FROM service_locations WHERE id = ? LIMIT 1");
        $chk->execute([$id]);
        if (!$chk->fetch()) { sendError('Service location not found.', 404); }

        $upd = $pdo->prepare("
            UPDATE service_locations SET
                location_name          = :name,
                address                = :addr,
                latitude               = :lat,
                longitude              = :lng,
                location               = ST_PointFromText(CONCAT('POINT(', :lng2, ' ', :lat2, ')'), 4326),
                radius_km              = :radius,
                tiffin_charge          = :tiffin_charge,
                original_tiffin_charge = :original_tiffin_charge,
                country                = :country,
                region                 = :region,
                status                 = :status,
                updated_at             = NOW()
            WHERE id = :id
        ");
        $upd->execute([
            ':name'                   => $locationName,
            ':addr'                   => $address,
            ':lat'                    => $lat,
            ':lng'                    => $lng,
            ':lng2'                   => $lng,
            ':lat2'                   => $lat,
            ':radius'                 => $radiusKm,
            ':tiffin_charge'          => $tiffinCharge,
            ':original_tiffin_charge' => $originalTiffinCharge,
            ':country'                => $country,
            ':region'                 => $region,
            ':status'                 => $status,
            ':id'                     => $id,
        ]);
        $serviceLocationId = $id;
    } else {
        $ins = $pdo->prepare("
            INSERT INTO service_locations
                (location_name, address, latitude, longitude, location, radius_km, tiffin_charge, original_tiffin_charge, country, region, status)
            VALUES
                (:name, :addr, :lat, :lng,
                 ST_PointFromText(CONCAT('POINT(', :lng2, ' ', :lat2, ')'), 4326),
                 :radius, :tiffin_charge, :original_tiffin_charge, :country, :region, :status)
        ");
        $ins->execute([
            ':name'                   => $locationName,
            ':addr'                   => $address,
            ':lat'                    => $lat,
            ':lng'                    => $lng,
            ':lng2'                   => $lng,
            ':lat2'                   => $lat,
            ':radius'                 => $radiusKm,
            ':tiffin_charge'          => $tiffinCharge,
            ':original_tiffin_charge' => $originalTiffinCharge,
            ':country'                => $country,
            ':region'                 => $region,
            ':status'                 => $status,
        ]);
        $serviceLocationId = (int)$pdo->lastInsertId();
    }

    // ── Sync plans ─────────────────────────────────────────────────────────────
    $keepPlanIds = [];

    foreach ($plans as $p) {
        $pId      = isset($p['id']) ? (int)$p['id'] : null;
        $pName    = trim(sanitize($p['plan_name'] ?? ''));
        $pDesc    = trim(sanitize($p['description'] ?? ''));
        $pPrice   = max(0, (float)($p['price'] ?? 0));
        $pDur     = max(1, (int)($p['duration'] ?? 30));
        $pDel     = max(1, (int)($p['total_deliveries'] ?? 30));
        $pMeals   = max(1, (int)($p['meals_per_day'] ?? 1));
        $pType    = in_array($p['meal_type'] ?? '', ['VEG','NON-VEG','BOTH']) ? $p['meal_type'] : 'VEG';
        $pSlot    = trim(sanitize($p['delivery_time_slot'] ?? ''));
        $pDisc    = max(0, (float)($p['discount'] ?? 0));
        $pCharge  = max(0, (float)($p['delivery_charge'] ?? 0));
        $pTiffin  = isset($p['tiffin_charge']) ? max(0, (float)$p['tiffin_charge']) : $tiffinCharge;
        $pStatus  = in_array($p['status'] ?? '', ['active','inactive']) ? $p['status'] : 'active';

        if (empty($pName)) continue;

        if ($pId) {
            $updP = $pdo->prepare("
                UPDATE plans SET
                    service_location_id = :sl_id,
                    plan_name           = :name,
                    description         = :desc,
                    price               = :price,
                    duration            = :dur,
                    total_deliveries    = :del,
                    meals_per_day       = :meals,
                    meal_type           = :type,
                    delivery_time_slot  = :slot,
                    discount            = :disc,
                    delivery_charge     = :charge,
                    tiffin_charge       = :tiffin_charge,
                    status              = :status,
                    updated_at          = NOW()
                WHERE id = :id AND service_location_id = :sl_id2
            ");
            $updP->execute([
                ':sl_id'         => $serviceLocationId,
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
                ':id'            => $pId,
                ':sl_id2'        => $serviceLocationId,
            ]);
            $keepPlanIds[] = $pId;
        } else {
            $insP = $pdo->prepare("
                INSERT INTO plans
                    (service_location_id, plan_name, description, price, duration,
                     total_deliveries, meals_per_day, meal_type, delivery_time_slot,
                     discount, delivery_charge, tiffin_charge, status)
                VALUES
                    (:sl_id, :name, :desc, :price, :dur, :del, :meals, :type,
                     :slot, :disc, :charge, :tiffin_charge, :status)
            ");
            $insP->execute([
                ':sl_id'         => $serviceLocationId,
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
            $keepPlanIds[] = (int)$pdo->lastInsertId();
        }
    }

    // Delete plans that were removed from the form (sync to both plans and subscription_plans)
    if (!empty($keepPlanIds)) {
        $inClause = implode(',', array_map('intval', $keepPlanIds));
        
        // Find legacy_plan_ids of the plans being kept
        $legacyKeep = $pdo->query("SELECT legacy_plan_id FROM plans WHERE id IN ($inClause) AND legacy_plan_id IS NOT NULL")->fetchAll(PDO::FETCH_COLUMN);
        
        $pdo->exec("DELETE FROM plans WHERE service_location_id = $serviceLocationId AND id NOT IN ($inClause)");

        if (!empty($legacyKeep)) {
            $legacyIn = implode(',', array_map('intval', $legacyKeep));
            $pdo->exec("DELETE FROM subscription_plans WHERE sub_area_id = $serviceLocationId AND id NOT IN ($legacyIn)");
        } else {
            $pdo->exec("DELETE FROM subscription_plans WHERE sub_area_id = $serviceLocationId");
        }
    } else {
        $pdo->exec("DELETE FROM plans WHERE service_location_id = $serviceLocationId");
        $pdo->exec("DELETE FROM subscription_plans WHERE sub_area_id = $serviceLocationId");
    }

    $pdo->commit();

    $msg = $duplicateWarning
        ? "Saved. {$duplicateWarning}"
        : ($id ? 'Service location updated successfully.' : 'Service location created successfully.');

    sendSuccess($msg, [
        'id'      => $serviceLocationId,
        'warning' => $duplicateWarning,
    ]);

} catch (PDOException $e) {
    if (isset($pdo) && $pdo->inTransaction()) $pdo->rollBack();
    sendError('Database error: ' . $e->getMessage(), 500);
}
