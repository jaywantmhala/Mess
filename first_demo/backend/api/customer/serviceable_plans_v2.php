<?php
/**
 * POST /api/customer/serviceable-plans-v2
 *
 * Nearest-eligible service location algorithm (§5 from spec):
 *  1. Get customer lat/lng (from body or saved address)
 *  2. Filter service_locations WHERE status='active'
 *  3. Compute distance_km to each candidate
 *  4. Keep candidates where distance_km <= radius_km + 0.2 (GPS tolerance)
 *  5. Sort ASC, pick first (nearest)
 *  6. Return only that location's active plans (never merge across locations)
 *
 * Body: { latitude?, longitude?, pincode?, customer_address? }
 * Headers: Authorization: Bearer <token>
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/validation.php';

const GPS_TOLERANCE_KM = 0.2;

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST')    { sendError('Method not allowed. Use POST.', 405); }

$rawBody = file_get_contents('php://input');
$body    = json_decode($rawBody, true) ?? [];

$lat     = isset($body['latitude'])  ? (float)$body['latitude']  : 0.0;
$lng     = isset($body['longitude']) ? (float)$body['longitude'] : 0.0;

$pdo = getDBConnection();

// ── If no coordinates in body, try saved address from JWT ─────────────────────
if ($lat === 0.0 && $lng === 0.0) {
    require_once __DIR__ . '/../../helpers/jwt.php';
    $token = JWT::getBearerToken();
    if ($token) {
        $pl = JWT::verify($token);
        if ($pl && isset($pl['sub'])) {
            $cid = (int)$pl['sub'];
            try {
                $addrStmt = $pdo->prepare(
                    "SELECT latitude, longitude FROM customer_addresses
                     WHERE customer_id = :cid AND latitude != 0 AND longitude != 0
                     ORDER BY is_default DESC, id DESC LIMIT 1"
                );
                $addrStmt->execute([':cid' => $cid]);
                $addrRow = $addrStmt->fetch(PDO::FETCH_ASSOC);
                if ($addrRow) {
                    $lat = (float)$addrRow['latitude'];
                    $lng = (float)$addrRow['longitude'];
                }
            } catch (PDOException $ex) {}
        }
    }
}

if ($lat === 0.0 && $lng === 0.0) {
    sendSuccess('No location provided.', [
        'serviceable'      => false,
        'service_location' => null,
        'plans'            => [],
    ]);
    exit;
}

try {
    // ── §5 Nearest-eligible-location algorithm ────────────────────────────────
    $stmt = $pdo->prepare("
        SELECT
            sl.id,
            sl.location_name,
            sl.address,
            sl.latitude,
            sl.longitude,
            sl.radius_km,
            sl.tiffin_charge,
            sl.original_tiffin_charge,
            sl.country,
            sl.region,
            sl.status,
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
          ) <= (sl.radius_km + :gps_tol) * 1000
        ORDER BY distance_km ASC
        LIMIT 1
    ");
    $stmt->execute([
        ':lat1'    => $lat,
        ':lng1'    => $lng,
        ':lat2'    => $lat,
        ':lng2'    => $lng,
        ':gps_tol' => GPS_TOLERANCE_KM,
    ]);
    $nearestLocation = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$nearestLocation) {
        sendSuccess('No subscription plans are available at your selected location.', [
            'serviceable'      => false,
            'service_location' => null,
            'plans'            => [],
        ]);
        exit;
    }

    // ── Fetch plans for the nearest location only ──────────────────────────────
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

    $areaTiffin = (!empty($nearestLocation['tiffin_charge']) && (float)$nearestLocation['tiffin_charge'] > 0)
        ? (float)$nearestLocation['tiffin_charge']
        : 50.0;
    $origTiffin = !empty($nearestLocation['original_tiffin_charge'])
        ? (float)$nearestLocation['original_tiffin_charge']
        : 0.0;
    $tiffinDiscount = ($origTiffin > $areaTiffin && $origTiffin > 0)
        ? round((($origTiffin - $areaTiffin) / $origTiffin) * 100, 1)
        : 0;

    // Format fields
    foreach ($plans as &$p) {
        $p['id']                  = (int)$p['id'];
        $p['service_location_id'] = (int)$p['service_location_id'];
        $p['price']               = number_format((float)$p['price'], 2, '.', '');
        $p['duration']            = (int)$p['duration'];
        $p['total_deliveries']    = (int)$p['total_deliveries'];
        $p['meals_per_day']       = (int)$p['meals_per_day'];
        $p['discount']            = number_format((float)$p['discount'], 2, '.', '');
        $p['tiffin_charge']       = number_format($areaTiffin, 2, '.', '');
        $p['original_tiffin_charge'] = number_format($origTiffin, 2, '.', '');
        $p['discount_percentage'] = $tiffinDiscount;
        $p['has_discount']        = ($origTiffin > $areaTiffin && $origTiffin > 0);
        $p['legacy_plan_id']      = $p['legacy_plan_id'] ? (int)$p['legacy_plan_id'] : null;
        // Attach radius from parent location
        $p['radius_km']           = (float)$nearestLocation['radius_km'];
        $p['distance_km']         = (float)$nearestLocation['distance_km'];
    }
    unset($p);

    $areaTiffin = (!empty($nearestLocation['tiffin_charge']) && (float)$nearestLocation['tiffin_charge'] > 0)
        ? (float)$nearestLocation['tiffin_charge']
        : 50.0;
    $origTiffin = !empty($nearestLocation['original_tiffin_charge'])
        ? (float)$nearestLocation['original_tiffin_charge']
        : 0.0;
    $tiffinDiscount = ($origTiffin > $areaTiffin && $origTiffin > 0)
        ? round((($origTiffin - $areaTiffin) / $origTiffin) * 100, 1)
        : 0;

    $serviceLocation = [
        'id'                     => (int)$nearestLocation['id'],
        'location_name'          => $nearestLocation['location_name'],
        'address'                => $nearestLocation['address'],
        'latitude'               => (float)$nearestLocation['latitude'],
        'longitude'              => (float)$nearestLocation['longitude'],
        'radius_km'              => (float)$nearestLocation['radius_km'],
        'tiffin_charge'          => $areaTiffin,
        'original_tiffin_charge' => $origTiffin,
        'discount_percentage'    => $tiffinDiscount,
        'has_discount'           => ($origTiffin > $areaTiffin && $origTiffin > 0),
        'distance_km'            => (float)$nearestLocation['distance_km'],
        'country'                => $nearestLocation['country'],
        'region'                 => $nearestLocation['region'],
    ];

    sendSuccess(
        !empty($plans)
            ? 'Serviceable plans retrieved successfully.'
            : 'Service location found but no active plans available.',
        [
            'serviceable'      => !empty($plans),
            'service_location' => $serviceLocation,
            'plans'            => $plans,
        ]
    );

} catch (PDOException $e) {
    sendError('Failed to resolve serviceable plans: ' . $e->getMessage(), 500);
}
