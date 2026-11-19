<?php
/**
 * POST /api/admin/locations/save
 *
 * Add or modify a location component (city, pincode, area, sub_area, plan).
 * Requires: Authorization: Bearer <JWT>
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

$body = requireJsonBody(['type']);
$type = trim($body['type']);
$id   = isset($body['id']) ? (int)$body['id'] : null;

$pdo = getDBConnection();

try {
    if ($type === 'city') {
        $cityName = isset($body['city_name']) ? trim(sanitize($body['city_name'])) : '';
        $isActive = isset($body['is_active']) ? (int)(bool)$body['is_active'] : 1;

        if (empty($cityName)) { sendError('City name is required.', 422); }

        // Check duplicate
        if ($id) {
            $stmt = $pdo->prepare("SELECT id FROM cities WHERE city_name = :name AND id != :id LIMIT 1");
            $stmt->execute([':name' => $cityName, ':id' => $id]);
        } else {
            $stmt = $pdo->prepare("SELECT id FROM cities WHERE city_name = :name LIMIT 1");
            $stmt->execute([':name' => $cityName]);
        }
        if ($stmt->fetch()) { sendError("A city named '{$cityName}' already exists.", 400); }

        if ($id) {
            $stmt = $pdo->prepare("UPDATE cities SET city_name = :name, is_active = :active, updated_at = NOW() WHERE id = :id");
            $stmt->execute([':name' => $cityName, ':active' => $isActive, ':id' => $id]);
            sendSuccess('City updated successfully.', ['id' => $id]);
        } else {
            $stmt = $pdo->prepare("INSERT INTO cities (city_name, is_active, created_at, updated_at) VALUES (:name, :active, NOW(), NOW())");
            $stmt->execute([':name' => $cityName, ':active' => $isActive]);
            sendSuccess('City created successfully.', ['id' => (int)$pdo->lastInsertId()]);
        }

    } elseif ($type === 'pincode') {
        $pincode = isset($body['pincode']) ? trim(sanitize($body['pincode'])) : '';
        $cityId  = isset($body['city_id']) ? (int)$body['city_id'] : 0;
        $isActive = isset($body['is_active']) ? (int)(bool)$body['is_active'] : 1;

        if (empty($pincode)) { sendError('Pin code is required.', 422); }
        if ($cityId <= 0)    { sendError('Valid parent city is required.', 422); }

        // Verify city exists
        $stmt = $pdo->prepare("SELECT id FROM cities WHERE id = ? LIMIT 1");
        $stmt->execute([$cityId]);
        if (!$stmt->fetch()) { sendError("Selected city does not exist.", 400); }

        // Check duplicate
        if ($id) {
            $stmt = $pdo->prepare("SELECT id FROM pincodes WHERE pincode = :pin AND city_id = :city_id AND id != :id LIMIT 1");
            $stmt->execute([':pin' => $pincode, ':city_id' => $cityId, ':id' => $id]);
        } else {
            $stmt = $pdo->prepare("SELECT id FROM pincodes WHERE pincode = :pin AND city_id = :city_id LIMIT 1");
            $stmt->execute([':pin' => $pincode, ':city_id' => $cityId]);
        }
        if ($stmt->fetch()) { sendError("Pin code '{$pincode}' already exists in this city.", 400); }

        if ($id) {
            $stmt = $pdo->prepare("UPDATE pincodes SET pincode = :pin, city_id = :city_id, is_active = :active, updated_at = NOW() WHERE id = :id");
            $stmt->execute([':pin' => $pincode, ':city_id' => $cityId, ':active' => $isActive, ':id' => $id]);
            sendSuccess('Pin code updated successfully.', ['id' => $id]);
        } else {
            $stmt = $pdo->prepare("INSERT INTO pincodes (pincode, city_id, is_active, created_at, updated_at) VALUES (:pin, :city_id, :active, NOW(), NOW())");
            $stmt->execute([':pin' => $pincode, ':city_id' => $cityId, ':active' => $isActive]);
            sendSuccess('Pin code created successfully.', ['id' => (int)$pdo->lastInsertId()]);
        }

    } elseif ($type === 'area') {
        $areaName  = isset($body['area_name'])  ? trim(sanitize($body['area_name']))  : '';
        $pincodeId = isset($body['pincode_id']) ? (int)$body['pincode_id'] : 0;
        $isActive  = isset($body['is_active'])  ? (int)(bool)$body['is_active']      : 1;

        if (empty($areaName)) { sendError('Area name is required.', 422); }
        if ($pincodeId <= 0)  { sendError('Valid parent Pin code is required.', 422); }

        // Verify pincode exists
        $stmt = $pdo->prepare("SELECT id FROM pincodes WHERE id = ? LIMIT 1");
        $stmt->execute([$pincodeId]);
        if (!$stmt->fetch()) { sendError("Selected Pin code does not exist.", 400); }

        // Check duplicate
        if ($id) {
            $stmt = $pdo->prepare("SELECT id FROM areas WHERE area_name = :name AND pincode_id = :pincode_id AND id != :id LIMIT 1");
            $stmt->execute([':name' => $areaName, ':pincode_id' => $pincodeId, ':id' => $id]);
        } else {
            $stmt = $pdo->prepare("SELECT id FROM areas WHERE area_name = :name AND pincode_id = :pincode_id LIMIT 1");
            $stmt->execute([':name' => $areaName, ':pincode_id' => $pincodeId]);
        }
        if ($stmt->fetch()) { sendError("Area '{$areaName}' already exists under this Pin code.", 400); }

        if ($id) {
            $stmt = $pdo->prepare("UPDATE areas SET area_name = :name, pincode_id = :pincode_id, is_active = :active, updated_at = NOW() WHERE id = :id");
            $stmt->execute([':name' => $areaName, ':pincode_id' => $pincodeId, ':active' => $isActive, ':id' => $id]);
            sendSuccess('Area updated successfully.', ['id' => $id]);
        } else {
            $stmt = $pdo->prepare("INSERT INTO areas (area_name, pincode_id, is_active, created_at, updated_at) VALUES (:name, :pincode_id, :active, NOW(), NOW())");
            $stmt->execute([':name' => $areaName, ':pincode_id' => $pincodeId, ':active' => $isActive]);
            sendSuccess('Area created successfully.', ['id' => (int)$pdo->lastInsertId()]);
        }

    } elseif ($type === 'sub_area') {
        $subAreaName = isset($body['sub_area_name']) ? trim(sanitize($body['sub_area_name'])) : '';
        $areaId      = isset($body['area_id'])       ? (int)$body['area_id']                 : 0;
        $lat         = isset($body['latitude'])      ? (float)$body['latitude']              : 0.0;
        $lng         = isset($body['longitude'])     ? (float)$body['longitude']             : 0.0;
        $radius      = isset($body['delivery_radius']) ? (float)$body['delivery_radius']      : 5.0;
        $charge      = isset($body['delivery_charge']) ? (float)$body['delivery_charge']      : 0.0;
        $isActive    = isset($body['is_active'])     ? (int)(bool)$body['is_active']         : 1;

        if (empty($subAreaName)) { sendError('Sub Area name is required.', 422); }
        if ($areaId <= 0)        { sendError('Valid parent Area is required.', 422); }

        // Verify area exists
        $stmt = $pdo->prepare("SELECT id FROM areas WHERE id = ? LIMIT 1");
        $stmt->execute([$areaId]);
        if (!$stmt->fetch()) { sendError("Selected Area does not exist.", 400); }

        // Check duplicate
        if ($id) {
            $stmt = $pdo->prepare("SELECT id FROM sub_areas WHERE sub_area_name = :name AND area_id = :area_id AND id != :id LIMIT 1");
            $stmt->execute([':name' => $subAreaName, ':area_id' => $areaId, ':id' => $id]);
        } else {
            $stmt = $pdo->prepare("SELECT id FROM sub_areas WHERE sub_area_name = :name AND area_id = :area_id LIMIT 1");
            $stmt->execute([':name' => $subAreaName, ':area_id' => $areaId]);
        }
        if ($stmt->fetch()) { sendError("Sub Area '{$subAreaName}' already exists under this Area.", 400); }

        if ($id) {
            $stmt = $pdo->prepare("
                UPDATE sub_areas 
                SET sub_area_name = :name, area_id = :area_id, latitude = :lat, longitude = :lng, 
                    location = ST_PointFromText(CONCAT('POINT(', :lng_loc, ' ', :lat_loc, ')'), 4326),
                    delivery_radius = :radius, delivery_charge = :charge, is_active = :active, updated_at = NOW() 
                WHERE id = :id
            ");
            $stmt->execute([
                ':name'    => $subAreaName,
                ':area_id' => $areaId,
                ':lat'     => $lat,
                ':lng'     => $lng,
                ':lng_loc' => $lng,
                ':lat_loc' => $lat,
                ':radius'  => $radius,
                ':charge'  => $charge,
                ':active'  => $isActive,
                ':id'      => $id
            ]);
            
            sendSuccess('Sub Area updated successfully.', ['id' => $id]);
        } else {
            $stmt = $pdo->prepare("
                INSERT INTO sub_areas (sub_area_name, area_id, latitude, longitude, location, delivery_radius, delivery_charge, is_active, created_at, updated_at) 
                VALUES (:name, :area_id, :lat, :lng, ST_PointFromText(CONCAT('POINT(', :lng_loc, ' ', :lat_loc, ')'), 4326), :radius, :charge, :active, NOW(), NOW())
            ");
            $stmt->execute([
                ':name'    => $subAreaName,
                ':area_id' => $areaId,
                ':lat'     => $lat,
                ':lng'     => $lng,
                ':lng_loc' => $lng,
                ':lat_loc' => $lat,
                ':radius'  => $radius,
                ':charge'  => $charge,
                ':active'  => $isActive
            ]);
            $newId = (int)$pdo->lastInsertId();
            
            sendSuccess('Sub Area created successfully.', ['id' => $newId]);
        }

    } elseif ($type === 'plan') {
        $subAreaId    = isset($body['sub_area_id'])    ? (int)$body['sub_area_id']        : 0;
        $planName     = isset($body['plan_name'])     ? trim(sanitize($body['plan_name'])) : '';
        $description  = isset($body['description'])   ? trim(sanitize($body['description'])) : '';
        $price        = isset($body['price'])         ? (float)$body['price']              : 0.0;
        $duration     = isset($body['duration'])      ? (int)$body['duration']            : 0;
        $deliveries   = isset($body['total_deliveries']) ? (int)$body['total_deliveries'] : 0;
        $mealsPerDay  = isset($body['meals_per_day']) ? (int)$body['meals_per_day']       : 1;
        $mealType     = isset($body['meal_type'])     ? trim(sanitize($body['meal_type'])) : 'VEG';
        $timeSlot     = isset($body['delivery_time_slot']) ? trim(sanitize($body['delivery_time_slot'])) : '';
        $discount     = isset($body['discount'])      ? (float)$body['discount']           : 0.0;
        $charge       = isset($body['delivery_charge']) ? (float)$body['delivery_charge'] : 0.0;
        $isActive     = isset($body['is_active'])     ? (int)(bool)$body['is_active']     : 1;

        if ($subAreaId <= 0)  { sendError('Valid Sub Area location is required.', 422); }
        if (empty($planName)) { sendError('Plan Name is required.', 422); }
        if ($price < 0)       { sendError('Price cannot be negative.', 422); }
        if ($duration < 1)    { sendError('Plan duration must be at least 1 day.', 422); }
        if ($deliveries < 1)  { sendError('Total deliveries must be at least 1.', 422); }
        if (empty($timeSlot)) { sendError('Delivery time slot is required.', 422); }

        // Verify sub area exists
        $stmt = $pdo->prepare("SELECT id FROM sub_areas WHERE id = ? LIMIT 1");
        $stmt->execute([$subAreaId]);
        if (!$stmt->fetch()) { sendError("Selected Sub Area location does not exist.", 400); }

        // Check duplicate plan name per sub_area
        if ($id) {
            $stmt = $pdo->prepare("SELECT id FROM subscription_plans WHERE plan_name = :name AND sub_area_id = :sub_area_id AND id != :id LIMIT 1");
            $stmt->execute([':name' => $planName, ':sub_area_id' => $subAreaId, ':id' => $id]);
        } else {
            $stmt = $pdo->prepare("SELECT id FROM subscription_plans WHERE plan_name = :name AND sub_area_id = :sub_area_id LIMIT 1");
            $stmt->execute([':name' => $planName, ':sub_area_id' => $subAreaId]);
        }
        if ($stmt->fetch()) { sendError("Plan '{$planName}' already exists under this Sub Area.", 400); }

        if ($id) {
            $stmt = $pdo->prepare("
                UPDATE subscription_plans 
                SET sub_area_id = :sub_area_id, plan_name = :name, description = :desc, price = :price, 
                    duration = :dur, total_deliveries = :del, meals_per_day = :meals, meal_type = :type, 
                    delivery_time_slot = :slot, discount = :disc, delivery_charge = :charge, is_active = :active, updated_at = NOW() 
                WHERE id = :id
            ");
            $stmt->execute([
                ':sub_area_id' => $subAreaId,
                ':name'        => $planName,
                ':desc'        => $description,
                ':price'       => $price,
                ':dur'         => $duration,
                ':del'         => $deliveries,
                ':meals'       => $mealsPerDay,
                ':type'        => $mealType,
                ':slot'        => $timeSlot,
                ':disc'        => $discount,
                ':charge'      => $charge,
                ':active'      => $isActive,
                ':id'          => $id
            ]);
            sendSuccess('Subscription plan updated successfully.', ['id' => $id]);
        } else {
            $stmt = $pdo->prepare("
                INSERT INTO subscription_plans (sub_area_id, plan_name, description, price, duration, total_deliveries, meals_per_day, meal_type, delivery_time_slot, discount, delivery_charge, is_active, created_at, updated_at) 
                VALUES (:sub_area_id, :name, :desc, :price, :dur, :del, :meals, :type, :slot, :disc, :charge, :active, NOW(), NOW())
            ");
            $stmt->execute([
                ':sub_area_id' => $subAreaId,
                ':name'        => $planName,
                ':desc'        => $description,
                ':price'       => $price,
                ':dur'         => $duration,
                ':del'         => $deliveries,
                ':meals'       => $mealsPerDay,
                ':type'        => $mealType,
                ':slot'        => $timeSlot,
                ':disc'        => $discount,
                ':charge'      => $charge,
                ':active'      => $isActive
            ]);
            sendSuccess('Subscription plan created successfully.', ['id' => (int)$pdo->lastInsertId()]);
        }

    } elseif ($type === 'unified') {
        $pincode     = trim(sanitize($body['pincode'] ?? ''));
        $areaName    = trim(sanitize($body['area_name'] ?? ''));
        $cityName    = trim(sanitize($body['city_name'] ?? '')) ?: 'Default';
        $subAreaName = trim(sanitize($body['sub_area_name'] ?? '')) ?: ($areaName !== '' ? $areaName : $pincode);
        $country     = trim(sanitize($body['country'] ?? 'IN'));
        $region      = trim(sanitize($body['region'] ?? ''));
        $address     = trim($body['address'] ?? '');
        $lat         = (float)($body['latitude'] ?? 0.0);
        $lng         = (float)($body['longitude'] ?? 0.0);
        $radius      = (float)($body['delivery_radius'] ?? 5.0);
        $charge      = (float)($body['delivery_charge'] ?? 0.0);
        $isActive    = isset($body['is_active']) ? (int)(bool)$body['is_active'] : 1;
        $plans       = $body['plans'] ?? [];

        if (empty($pincode)) { sendError('Pin code is required.', 422); }

        $pdo->beginTransaction();

        try {
            // 1. Get or Create City
            $stmt = $pdo->prepare("SELECT id FROM cities WHERE LOWER(city_name) = LOWER(:name) LIMIT 1");
            $stmt->execute([':name' => $cityName]);
            $cityRow = $stmt->fetch();
            if ($cityRow) {
                $cityId = (int)$cityRow['id'];
            } else {
                $stmt = $pdo->prepare("INSERT INTO cities (city_name, is_active, created_at, updated_at) VALUES (:name, 1, NOW(), NOW())");
                $stmt->execute([':name' => $cityName]);
                $cityId = (int)$pdo->lastInsertId();
            }

            // 2. Get or Create Pin Code
            $stmt = $pdo->prepare("SELECT id FROM pincodes WHERE pincode = :pin AND city_id = :city_id LIMIT 1");
            $stmt->execute([':pin' => $pincode, ':city_id' => $cityId]);
            $pinRow = $stmt->fetch();
            if ($pinRow) {
                $pincodeId = (int)$pinRow['id'];
            } else {
                $stmt = $pdo->prepare("INSERT INTO pincodes (pincode, city_id, is_active, created_at, updated_at) VALUES (:pin, :city_id, 1, NOW(), NOW())");
                $stmt->execute([':pin' => $pincode, ':city_id' => $cityId]);
                $pincodeId = (int)$pdo->lastInsertId();
            }

            // 3. Get or Create Area (Case-insensitive matching for area_name)
            $stmt = $pdo->prepare("SELECT id FROM areas WHERE LOWER(area_name) = LOWER(:name) AND pincode_id = :pincode_id LIMIT 1");
            $stmt->execute([':name' => $areaName, ':pincode_id' => $pincodeId]);
            $areaRow = $stmt->fetch();
            if ($areaRow) {
                $areaId = (int)$areaRow['id'];
            } else {
                $stmt = $pdo->prepare("INSERT INTO areas (area_name, pincode_id, is_active, created_at, updated_at) VALUES (:name, :pincode_id, 1, NOW(), NOW())");
                $stmt->execute([':name' => $areaName, ':pincode_id' => $pincodeId]);
                $areaId = (int)$pdo->lastInsertId();
            }

            // 4. Get, Update or Create Sub Area
            $subAreaId = isset($body['sub_area_id']) ? (int)$body['sub_area_id'] : null;

            if (!$subAreaId) {
                $stmt = $pdo->prepare("SELECT id FROM sub_areas WHERE sub_area_name = :name AND area_id = :area_id LIMIT 1");
                $stmt->execute([':name' => $subAreaName, ':area_id' => $areaId]);
                $saRow = $stmt->fetch();
                if ($saRow) {
                    $subAreaId = (int)$saRow['id'];
                }
            }

            // 4. Check for nearby active plan duplicate within 500 meters
            $duplicateWarning = null;
            if ($lat != 0.0 && $lng != 0.0) {
                try {
                    $dupStmt = $pdo->prepare("
                        SELECT id, sub_area_name, 
                               ROUND(ST_Distance_Sphere(location, ST_PointFromText(CONCAT('POINT(', :lng, ' ', :lat, ')'), 4326)), 1) AS dist_m
                        FROM sub_areas
                        WHERE is_active = 1
                          AND id != :current_id
                          AND ST_Distance_Sphere(location, ST_PointFromText(CONCAT('POINT(', :lng_dist, ' ', :lat_dist, ')'), 4326)) <= 500
                        LIMIT 1
                    ");
                    $dupStmt->execute([
                        ':current_id' => $subAreaId ?? 0,
                        ':lat'        => $lat,
                        ':lng'        => $lng,
                        ':lat_dist'   => $lat,
                        ':lng_dist'   => $lng,
                    ]);
                    $dupRow = $dupStmt->fetch();
                    if ($dupRow) {
                        $duplicateWarning = "Notice: Active service area '{$dupRow['sub_area_name']}' already exists within {$dupRow['dist_m']} meters of this location.";
                    }
                } catch (Exception $ex) {}
            }

            if ($subAreaId) {
                $stmt = $pdo->prepare("
                    UPDATE sub_areas 
                    SET sub_area_name = :name, area_id = :area_id, latitude = :lat, longitude = :lng, 
                        location = ST_PointFromText(CONCAT('POINT(', :lng_loc, ' ', :lat_loc, ')'), 4326),
                        delivery_radius = :radius, delivery_charge = :charge, 
                        country = :country, region = :region, address = :address,
                        is_active = :active, updated_at = NOW() 
                    WHERE id = :id
                ");
                $stmt->execute([
                    ':name'    => $subAreaName,
                    ':area_id' => $areaId,
                    ':lat'     => $lat,
                    ':lng'     => $lng,
                    ':lng_loc' => $lng,
                    ':lat_loc' => $lat,
                    ':radius'  => $radius,
                    ':charge'  => $charge,
                    ':country' => $country,
                    ':region'  => $region,
                    ':address' => $address,
                    ':active'  => $isActive,
                    ':id'      => $subAreaId
                ]);
            } else {
                $stmt = $pdo->prepare("
                    INSERT INTO sub_areas (sub_area_name, area_id, latitude, longitude, location, delivery_radius, delivery_charge, country, region, address, is_active, created_at, updated_at) 
                    VALUES (:name, :area_id, :lat, :lng, ST_PointFromText(CONCAT('POINT(', :lng_loc, ' ', :lat_loc, ')'), 4326), :radius, :charge, :country, :region, :address, :active, NOW(), NOW())
                ");
                $stmt->execute([
                    ':name'    => $subAreaName,
                    ':area_id' => $areaId,
                    ':lat'     => $lat,
                    ':lng'     => $lng,
                    ':lng_loc' => $lng,
                    ':lat_loc' => $lat,
                    ':radius'  => $radius,
                    ':charge'  => $charge,
                    ':country' => $country,
                    ':region'  => $region,
                    ':address' => $address,
                    ':active'  => $isActive
                ]);
                $subAreaId = (int)$pdo->lastInsertId();
            }

            // 5. Sync Plans
            $keepPlanIds = [];
            foreach ($plans as $p) {
                $pId          = isset($p['id']) ? (int)$p['id'] : null;
                $pName        = trim(sanitize($p['plan_name'] ?? ''));
                $pDesc        = trim(sanitize($p['description'] ?? ''));
                $pPrice       = (float)($p['price'] ?? 0.0);
                $pDuration    = (int)($p['duration'] ?? 30);
                $pDeliveries  = (int)($p['total_deliveries'] ?? 30);
                $pMeals       = (int)($p['meals_per_day'] ?? 1);
                $pMealType    = trim(sanitize($p['meal_type'] ?? 'VEG'));
                $pSlot        = trim(sanitize($p['delivery_time_slot'] ?? ''));
                $pDiscount    = (float)($p['discount'] ?? 0.0);
                $pDelCharge   = (float)($p['delivery_charge'] ?? 0.0);
                $pIsActive    = isset($p['is_active']) ? (int)(bool)$p['is_active'] : 1;

                if (empty($pName)) continue;

                if ($pId) {
                    $stmt = $pdo->prepare("
                        UPDATE subscription_plans 
                        SET sub_area_id = :sub_area_id, plan_name = :name, description = :desc, price = :price, 
                            duration = :dur, total_deliveries = :del, meals_per_day = :meals, meal_type = :type, 
                            delivery_time_slot = :slot, discount = :disc, delivery_charge = :charge, is_active = :active, updated_at = NOW() 
                        WHERE id = :id
                    ");
                    $stmt->execute([
                        ':sub_area_id' => $subAreaId,
                        ':name'        => $pName,
                        ':desc'        => $pDesc,
                        ':price'       => $pPrice,
                        ':dur'         => $pDuration,
                        ':del'         => $pDeliveries,
                        ':meals'       => $pMeals,
                        ':type'        => $pMealType,
                        ':slot'        => $pSlot,
                        ':disc'        => $pDiscount,
                        ':charge'      => $pDelCharge,
                        ':active'      => $pIsActive,
                        ':id'          => $pId
                    ]);
                    $keepPlanIds[] = $pId;
                } else {
                    $stmt = $pdo->prepare("
                        INSERT INTO subscription_plans (sub_area_id, plan_name, description, price, duration, total_deliveries, meals_per_day, meal_type, delivery_time_slot, discount, delivery_charge, is_active, created_at, updated_at) 
                        VALUES (:sub_area_id, :name, :desc, :price, :dur, :del, :meals, :type, :slot, :disc, :charge, :active, NOW(), NOW())
                    ");
                    $stmt->execute([
                        ':sub_area_id' => $subAreaId,
                        ':name'        => $pName,
                        ':desc'        => $pDesc,
                        ':price'       => $pPrice,
                        ':dur'         => $pDuration,
                        ':del'         => $pDeliveries,
                        ':meals'       => $pMeals,
                        ':type'        => $pMealType,
                        ':slot'        => $pSlot,
                        ':disc'        => $pDiscount,
                        ':charge'      => $pDelCharge,
                        ':active'      => $pIsActive
                    ]);
                    $keepPlanIds[] = (int)$pdo->lastInsertId();
                }
            }

            // Sync plans deletion/deactivation
            if (!empty($keepPlanIds)) {
                $inClause = implode(',', array_map('intval', $keepPlanIds));
                try {
                    $pdo->exec("DELETE FROM subscription_plans WHERE sub_area_id = {$subAreaId} AND id NOT IN ({$inClause})");
                } catch (PDOException $ex) {
                    $pdo->exec("UPDATE subscription_plans SET is_active = 0 WHERE sub_area_id = {$subAreaId} AND id NOT IN ({$inClause})");
                }
            } else {
                try {
                    $pdo->exec("DELETE FROM subscription_plans WHERE sub_area_id = {$subAreaId}");
                } catch (PDOException $ex) {
                    $pdo->exec("UPDATE subscription_plans SET is_active = 0 WHERE sub_area_id = {$subAreaId}");
                }
            }

            $pdo->commit();
            sendSuccess($duplicateWarning ? "Saved successfully. $duplicateWarning" : 'Service Area and Subscription plans saved successfully.', [
                'id'      => $subAreaId,
                'warning' => $duplicateWarning
            ]);

        } catch (PDOException $e) {
            $pdo->rollBack();
            sendError('Transaction failed: ' . $e->getMessage(), 500);
        }

    } else {
        sendError('Invalid type. Must be city, pincode, area, sub_area, plan, or unified.', 400);
    }
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
