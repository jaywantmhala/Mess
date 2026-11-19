<?php
/**
 * POST /api/customer/serviceable-plans
 *
 * Resolves serviceable subscription plans using strict spatial radius matching 
 * on service_locations & plans tables, with Google Maps Geocoding fallback,
 * and text-matching fallback for address/pincode.
 *
 * Body: { latitude?, longitude?, pincode?, customer_address? }
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/validation.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST')    { sendError('Method not allowed. Use POST.', 405); }

$rawBody = file_get_contents('php://input');
$body = json_decode($rawBody, true) ?? [];

$lat          = isset($body['latitude']) ? (float)$body['latitude'] : 0.0;
$lng          = isset($body['longitude']) ? (float)$body['longitude'] : 0.0;
$pincode      = isset($body['pincode']) ? trim(sanitize($body['pincode'])) : '';

$customerAddr = '';
if (isset($body['customer_address']) && trim($body['customer_address']) !== '') {
    $customerAddr = trim($body['customer_address']);
} elseif (isset($body['address']) && trim($body['address']) !== '') {
    $customerAddr = trim($body['address']);
}

$pdo = getDBConnection();

// Load saved address from token if request address is empty
if ($customerAddr === '' && $lat === 0.0 && $lng === 0.0) {
    require_once __DIR__ . '/../../helpers/jwt.php';
    $token = JWT::getBearerToken();
    if ($token) {
        $payload = JWT::verify($token);
        if ($payload && isset($payload['sub'])) {
            $customerId = (int)$payload['sub'];
            try {
                $addrStmt = $pdo->prepare("SELECT full_address, latitude, longitude, pincode FROM customer_addresses WHERE customer_id = :cid ORDER BY is_default DESC, id DESC LIMIT 1");
                $addrStmt->execute([':cid' => $customerId]);
                $addrRow = $addrStmt->fetch(PDO::FETCH_ASSOC);
                if ($addrRow) {
                    if (!empty($addrRow['full_address'])) $customerAddr = $addrRow['full_address'];
                    if (!empty($addrRow['latitude'])) $lat = (float)$addrRow['latitude'];
                    if (!empty($addrRow['longitude'])) $lng = (float)$addrRow['longitude'];
                    if (!empty($addrRow['pincode']) && $pincode === '') $pincode = $addrRow['pincode'];
                }
            } catch (Exception $e) {}
        }
    }
}

// ── Google Maps Geocoding Fallback if lat/lng are 0 ─────────────────────────────
if (($lat === 0.0 || $lng === 0.0) && $customerAddr !== '') {
    $apiKey = defined('GOOGLE_MAPS_API_KEY') ? GOOGLE_MAPS_API_KEY : '';
    if (!empty($apiKey)) {
        $geoUrl = 'https://maps.googleapis.com/maps/api/geocode/json?address=' . urlencode($customerAddr) . '&key=' . $apiKey;
        $geoResp = @file_get_contents($geoUrl);
        if ($geoResp) {
            $geoJson = json_decode($geoResp, true);
            if (($geoJson['status'] ?? '') === 'OK' && !empty($geoJson['results'])) {
                $loc = $geoJson['results'][0]['geometry']['location'] ?? null;
                if ($loc && isset($loc['lat'], $loc['lng'])) {
                    $lat = (float)$loc['lat'];
                    $lng = (float)$loc['lng'];
                }
            }
        }
    }
}

try {
    $plans = [];
    $resolvedLocation = null;
    $hasCoordinates = ($lat != 0.0 && $lng != 0.0);

    // ── STAGE 1: Spatial Radius Matching against `service_locations` & `plans` ──
    if ($hasCoordinates) {
        $stmt = $pdo->prepare("
            SELECT sl.id, sl.location_name, sl.address, sl.latitude, sl.longitude, sl.radius_km, sl.tiffin_charge, sl.original_tiffin_charge, sl.country, sl.region,
                   ROUND(
                       ST_Distance_Sphere(
                           sl.location,
                           ST_PointFromText(CONCAT('POINT(', :lng1, ' ', :lat1, ')'), 4326)
                       ) / 1000, 3
                   ) AS distance_km
            FROM service_locations sl
            WHERE sl.status = 'active'
              AND sl.latitude != 0
              AND sl.longitude != 0
              AND ST_Distance_Sphere(
                  sl.location,
                  ST_PointFromText(CONCAT('POINT(', :lng2, ' ', :lat2, ')'), 4326)
              ) <= (sl.radius_km + 0.2) * 1000
            ORDER BY distance_km ASC
            LIMIT 1
        ");
        $stmt->execute([
            ':lat1' => $lat,
            ':lng1' => $lng,
            ':lat2' => $lat,
            ':lng2' => $lng,
        ]);
        $nearestLocation = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($nearestLocation) {
            $resolvedLocation = [
                'id'            => (int)$nearestLocation['id'],
                'location_name' => $nearestLocation['location_name'],
                'address'       => $nearestLocation['address'],
                'latitude'      => (float)$nearestLocation['latitude'],
                'longitude'     => (float)$nearestLocation['longitude'],
                'radius_km'     => (float)$nearestLocation['radius_km'],
                'tiffin_charge'          => (float)($nearestLocation['tiffin_charge'] ?? 50.0),
                'original_tiffin_charge' => (float)($nearestLocation['original_tiffin_charge'] ?? 0.0),
                'discount_percentage'    => (((float)($nearestLocation['original_tiffin_charge'] ?? 0.0) > (float)($nearestLocation['tiffin_charge'] ?? 50.0)) && (float)($nearestLocation['original_tiffin_charge'] ?? 0.0) > 0)
                    ? round((((float)$nearestLocation['original_tiffin_charge'] - (float)$nearestLocation['tiffin_charge']) / (float)$nearestLocation['original_tiffin_charge']) * 100, 1)
                    : 0,
                'distance_km'            => (float)$nearestLocation['distance_km'],
                'sub_area_name'          => $nearestLocation['location_name'],
            ];

            $planStmt = $pdo->prepare("
                SELECT id, service_location_id, plan_name, description, price, duration,
                       total_deliveries, meals_per_day, meal_type, delivery_time_slot,
                       discount, delivery_charge, tiffin_charge, status, legacy_plan_id
                FROM plans
                WHERE service_location_id = :sl_id
                  AND status = 'active'
                ORDER BY price ASC
            ");
            $planStmt->execute([':sl_id' => (int)$nearestLocation['id']]);
            $plans = $planStmt->fetchAll(PDO::FETCH_ASSOC);
        }
    }

    // ── STAGE 2: Text Matching Fallback on `service_locations` ─────────────────────
    if (empty($plans) && !$hasCoordinates && ($customerAddr !== '' || $pincode !== '')) {
        $stmt = $pdo->prepare("
            SELECT id, location_name, address, latitude, longitude, radius_km, tiffin_charge
            FROM service_locations
            WHERE status = 'active'
        ");
        $stmt->execute();
        $candidates = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $customerAddrLower = strtolower($customerAddr);
        $inputPincodeLower = strtolower($pincode);
        $matchedCandidates = [];

        foreach ($candidates as $cand) {
            $addrStr = strtolower(trim($cand['address'] ?? ''));
            $nameStr = strtolower(trim($cand['location_name'] ?? ''));

            $nameMatched = ($nameStr !== '' && $customerAddrLower !== '' && stripos($customerAddrLower, $nameStr) !== false);
            $addrMatched = ($addrStr !== '' && $customerAddrLower !== '' && stripos($customerAddrLower, $addrStr) !== false);
            $pincodeMatched = ($inputPincodeLower !== '' && stripos($addrStr, $inputPincodeLower) !== false);

            if ($nameMatched || $addrMatched || $pincodeMatched) {
                $score = 0;
                if ($nameMatched) $score += 100;
                if ($addrMatched) $score += 50;
                if ($pincodeMatched) $score += 25;
                $cand['match_score'] = $score;
                $matchedCandidates[] = $cand;
            }
        }

        if (!empty($matchedCandidates)) {
            usort($matchedCandidates, function($a, $b) { return $b['match_score'] - $a['match_score']; });
            $bestMatch = $matchedCandidates[0];

            $resolvedLocation = [
                'id'            => (int)$bestMatch['id'],
                'location_name' => $bestMatch['location_name'],
                'address'       => $bestMatch['address'],
                'latitude'      => (float)$bestMatch['latitude'],
                'longitude'     => (float)$bestMatch['longitude'],
                'radius_km'     => (float)$bestMatch['radius_km'],
                'tiffin_charge' => (float)($bestMatch['tiffin_charge'] ?? 50.0),
                'distance_km'   => 0.0,
                'sub_area_name' => $bestMatch['location_name'],
            ];

            $planStmt = $pdo->prepare("
                SELECT id, service_location_id, plan_name, description, price, duration,
                       total_deliveries, meals_per_day, meal_type, delivery_time_slot,
                       discount, delivery_charge, tiffin_charge, status, legacy_plan_id
                FROM plans
                WHERE service_location_id = :sl_id
                  AND status = 'active'
                ORDER BY price ASC
            ");
            $planStmt->execute([':sl_id' => (int)$bestMatch['id']]);
            $plans = $planStmt->fetchAll(PDO::FETCH_ASSOC);
        }
    }

    // ── STAGE 3: Legacy Fallback (`subscription_plans` & `sub_areas` tables) ───────
    if (empty($plans)) {
        if ($hasCoordinates) {
            $stmt = $pdo->prepare("
                SELECT sp.*, sa.sub_area_name, sa.latitude AS sa_lat, sa.longitude AS sa_lng, sa.delivery_charge AS sub_area_charge, sa.delivery_radius, sa.tiffin_charge AS sub_area_tiffin
                FROM subscription_plans sp
                JOIN sub_areas sa ON sp.sub_area_id = sa.id
                WHERE sp.is_active = 1 AND sa.is_active = 1
            ");
            $stmt->execute();
            $plans = $stmt->fetchAll(PDO::FETCH_ASSOC);
        }
    }

    // Format output fields
    foreach ($plans as &$p) {
        $p['id']               = (int)$p['id'];
        $p['sub_area_id']      = (int)($p['service_location_id'] ?? $p['sub_area_id'] ?? 1);
        $p['price']            = number_format((float)$p['price'], 2, '.', '');
        $p['duration']         = (int)$p['duration'];
        $p['total_deliveries'] = (int)$p['total_deliveries'];
        $p['meals_per_day']    = (int)($p['meals_per_day'] ?? 1);
        $p['discount']         = number_format((float)($p['discount'] ?? 0), 2, '.', '');
        $p['delivery_charge']  = number_format((float)($p['delivery_charge'] ?? 0), 2, '.', '');
        $p['tiffin_charge']    = number_format((float)($p['tiffin_charge'] ?? $p['sub_area_tiffin'] ?? $resolvedLocation['tiffin_charge'] ?? 50.0), 2, '.', '');
        $p['is_active']        = true;
        $p['sub_area_name']    = $resolvedLocation['location_name'] ?? 'Service Area';
    }
    unset($p);

    $isServiceable = !empty($plans);

    sendSuccess(
        $isServiceable ? 'Serviceable plans retrieved successfully.' : 'No subscription plans are available in your location radius.',
        [
            'serviceable'      => $isServiceable,
            'sub_area'         => $resolvedLocation,
            'service_location' => $resolvedLocation,
            'plans'            => $plans
        ]
    );

} catch (PDOException $e) {
    sendError('Failed to resolve serviceable plans: ' . $e->getMessage(), 500);
}
