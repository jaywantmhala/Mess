<?php
/**
 * GET /api/vendor/orders/track?order_id=X
 *
 * Provides real-time order tracking details for vendor:
 * - Driver's live coordinates (latitude, longitude, online status, phone, vehicle)
 * - Customer's delivery coordinates & address
 * - Restaurant/Hotel coordinates & address
 * - Distance & estimated ETA
 *
 * Requires: Authorization: Bearer <vendor_token>
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'GET') { sendError('Method not allowed. Use GET.', 405); }

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/jwt.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/redis_helper.php';

$token = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || ($payload['role'] ?? '') !== 'vendor') {
    sendError('Unauthorized access. Vendor token required.', 401);
}

$vendorId = (int)$payload['sub'];
$orderId = isset($_GET['order_id']) ? (int)$_GET['order_id'] : 0;

if ($orderId <= 0) {
    sendError('Valid order_id is required.', 400);
}

function calcDistanceMeters($lat1, $lon1, $lat2, $lon2) {
    if ($lat1 == 0.0 || $lon1 == 0.0 || $lat2 == 0.0 || $lon2 == 0.0) return 0.0;
    $earthRadius = 6371000; // in meters
    $dLat = deg2rad($lat2 - $lat1);
    $dLon = deg2rad($lon2 - $lon1);
    $a = sin($dLat / 2) * sin($dLat / 2) + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLon / 2) * sin($dLon / 2);
    $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
    return $earthRadius * $c;
}

try {
    $pdo = getDBConnection();

    // Fetch order and verify vendor ownership
    $stmt = $pdo->prepare("
        SELECT o.order_id, o.customer_id, o.hotel_id, o.driver_id, o.status,
               o.delivery_address, o.meal_type, o.created_at, o.updated_at,
               h.vendor_id, h.hotel_name, h.hotel_address, h.mobile_number AS hotel_phone,
               COALESCE(h.latitude, 0.0) AS hotel_latitude,
               COALESCE(h.longitude, 0.0) AS hotel_longitude,
               c.full_name AS customer_name,
               COALESCE(c.phone_number, c.phone, '') AS customer_phone,
               c.email AS customer_email,
               COALESCE(c.latitude, 0.0) AS customer_lat_fallback,
               COALESCE(c.longitude, 0.0) AS customer_lng_fallback
        FROM orders o
        JOIN hotels h ON o.hotel_id = h.id
        LEFT JOIN customers c ON o.customer_id = c.id
        WHERE o.order_id = ?
        LIMIT 1
    ");
    $stmt->execute([$orderId]);
    $order = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$order) {
        sendError('Order not found.', 404);
    }

    if ((int)$order['vendor_id'] !== $vendorId) {
        sendError('Forbidden. You do not manage this hotel\'s orders.', 403);
    }

    // Customer delivery location: Match specifically against the delivery address of this order
    $deliveryAddress = trim($order['delivery_address'] ?? '');
    $custLat = 0.0;
    $custLng = 0.0;

    if (!empty($deliveryAddress)) {
        // Priority 1: Exact address match for this customer
        $addrStmt = $pdo->prepare("
            SELECT latitude, longitude 
            FROM customer_addresses 
            WHERE customer_id = ? 
              AND TRIM(full_address) = ?
              AND latitude != 0.0 AND longitude != 0.0
            LIMIT 1
        ");
        $addrStmt->execute([(int)$order['customer_id'], $deliveryAddress]);
        $custAddr = $addrStmt->fetch(PDO::FETCH_ASSOC);

        // Priority 2: Partial/contains address match for this customer
        if (!$custAddr) {
            $addrStmtLike = $pdo->prepare("
                SELECT latitude, longitude 
                FROM customer_addresses 
                WHERE customer_id = ? 
                  AND (? LIKE CONCAT('%', full_address, '%') OR full_address LIKE CONCAT('%', ?, '%'))
                  AND latitude != 0.0 AND longitude != 0.0
                ORDER BY (TRIM(full_address) = ?) DESC, id DESC 
                LIMIT 1
            ");
            $addrStmtLike->execute([(int)$order['customer_id'], $deliveryAddress, $deliveryAddress, $deliveryAddress]);
            $custAddr = $addrStmtLike->fetch(PDO::FETCH_ASSOC);
        }

        // Priority 3: Match address text across any saved addresses
        if (!$custAddr) {
            $addrStmtGlobal = $pdo->prepare("
                SELECT latitude, longitude 
                FROM customer_addresses 
                WHERE (TRIM(full_address) = ? OR ? LIKE CONCAT('%', full_address, '%') OR full_address LIKE CONCAT('%', ?, '%'))
                  AND latitude != 0.0 AND longitude != 0.0
                ORDER BY (TRIM(full_address) = ?) DESC, id DESC 
                LIMIT 1
            ");
            $addrStmtGlobal->execute([$deliveryAddress, $deliveryAddress, $deliveryAddress, $deliveryAddress]);
            $custAddr = $addrStmtGlobal->fetch(PDO::FETCH_ASSOC);
        }

        if ($custAddr && (float)$custAddr['latitude'] != 0.0) {
            $custLat = (float)$custAddr['latitude'];
            $custLng = (float)$custAddr['longitude'];
        }

        // Priority 4: Google Geocoding API if not found or 0.0
        if ($custLat == 0.0 || $custLng == 0.0) {
            try {
                $googleKey = 'AIzaSyDuZC6kFobB0pnp-k3VcxQIjvb0EhgfnVI';
                $geocodeUrl = 'https://maps.googleapis.com/maps/api/geocode/json?address=' . urlencode($deliveryAddress) . '&key=' . $googleKey;
                $ctx = stream_context_create(['http' => ['timeout' => 3]]);
                $geoRes = @file_get_contents($geocodeUrl, false, $ctx);
                if ($geoRes !== false) {
                    $geoData = json_decode($geoRes, true);
                    if (!empty($geoData['results'][0]['geometry']['location'])) {
                        $loc = $geoData['results'][0]['geometry']['location'];
                        $custLat = (float)$loc['lat'];
                        $custLng = (float)$loc['lng'];
                    }
                }
            } catch (Exception $ge) {
                // Ignore and fall through to default
            }
        }
    }

    // Priority 5: Fallback to customer's default address
    if ($custLat == 0.0 || $custLng == 0.0) {
        $defStmt = $pdo->prepare("
            SELECT latitude, longitude 
            FROM customer_addresses 
            WHERE customer_id = ? AND latitude != 0.0 AND longitude != 0.0
            ORDER BY is_default DESC, id DESC 
            LIMIT 1
        ");
        $defStmt->execute([(int)$order['customer_id']]);
        $defAddr = $defStmt->fetch(PDO::FETCH_ASSOC);
        if ($defAddr && (float)$defAddr['latitude'] != 0.0) {
            $custLat = (float)$defAddr['latitude'];
            $custLng = (float)$defAddr['longitude'];
        }
    }

    // Priority 6: Fallback to customer profile coordinates
    if ($custLat == 0.0 || $custLng == 0.0) {
        $custLat = (float)$order['customer_lat_fallback'];
        $custLng = (float)$order['customer_lng_fallback'];
    }

    // Driver details if assigned
    $driverData = null;
    $distanceMeters = 0.0;
    $etaMinutes = 0;

    if (!empty($order['driver_id'])) {
        $driverStmt = $pdo->prepare("
            SELECT id, full_name, phone_number, vehicle_number,
                   COALESCE(latitude, 0.0) AS latitude,
                   COALESCE(longitude, 0.0) AS longitude,
                   COALESCE(is_online, 0) AS is_online,
                   updated_at
            FROM drivers
            WHERE id = ?
            LIMIT 1
        ");
        $driverStmt->execute([(int)$order['driver_id']]);
        $driver = $driverStmt->fetch(PDO::FETCH_ASSOC);

        if ($driver) {
            $driverLat = (float)$driver['latitude'];
            $driverLng = (float)$driver['longitude'];

            // Priority: Check Redis for real-time in-memory GPS coordinates
            $redisLoc = RedisHelper::getDriverLocation((int)$driver['id']);
            if ($redisLoc && !empty($redisLoc['latitude']) && !empty($redisLoc['longitude'])) {
                $driverLat = (float)$redisLoc['latitude'];
                $driverLng = (float)$redisLoc['longitude'];
            }

            // Calculate distance between driver and customer delivery address
            if ($driverLat != 0.0 && $driverLng != 0.0 && $custLat != 0.0 && $custLng != 0.0) {
                $distanceMeters = calcDistanceMeters($driverLat, $driverLng, $custLat, $custLng);
                // Avg 25 km/h in city traffic = ~416.7 m/min
                $etaMinutes = max(1, (int)round($distanceMeters / 416.7));
            }

            $driverData = [
                'id'             => (int)$driver['id'],
                'name'           => $driver['full_name'],
                'phone'          => $driver['phone_number'],
                'vehicle_number' => $driver['vehicle_number'],
                'latitude'       => $driverLat,
                'longitude'      => $driverLng,
                'is_online'      => (bool)$driver['is_online'],
                'updated_at'     => $driver['updated_at'],
            ];
        }
    }

    // Calculate hotel to customer distance (actual drop distance in km)
    $dropDistanceKm = 0.0;
    if ((float)$order['hotel_latitude'] != 0.0 && (float)$order['hotel_longitude'] != 0.0 && $custLat != 0.0 && $custLng != 0.0) {
        $dropMeters = calcDistanceMeters((float)$order['hotel_latitude'], (float)$order['hotel_longitude'], $custLat, $custLng);
        $dropDistanceKm = round($dropMeters / 1000.0, 2);
    }

    if ($distanceMeters == 0.0 && $dropDistanceKm > 0.0) {
        $distanceMeters = $dropDistanceKm * 1000.0;
        $etaMinutes = max(1, (int)round($distanceMeters / 416.7));
    }

    $distanceKm = round($distanceMeters / 1000.0, 2);

    sendSuccess('Tracking details retrieved successfully.', [
        'order_id'           => (int)$order['order_id'],
        'status'             => $order['status'],
        'meal_type'          => $order['meal_type'] ?? 'Lunch',
        'delivery_address'   => $order['delivery_address'],
        'created_at'         => $order['created_at'],
        'updated_at'         => $order['updated_at'],
        'is_driver_assigned' => !empty($order['driver_id']),
        'customer' => [
            'id'        => (int)$order['customer_id'],
            'name'      => $order['customer_name'],
            'phone'     => $order['customer_phone'],
            'email'     => $order['customer_email'],
            'latitude'  => $custLat,
            'longitude' => $custLng,
        ],
        'hotel' => [
            'id'        => (int)$order['hotel_id'],
            'name'      => $order['hotel_name'],
            'address'   => $order['hotel_address'],
            'phone'     => $order['hotel_phone'],
            'latitude'  => (float)$order['hotel_latitude'],
            'longitude' => (float)$order['hotel_longitude'],
        ],
        'driver'             => $driverData,
        'distance_km'        => $distanceKm,
        'drop_distance_km'   => $dropDistanceKm,
        'distance_meters'    => round($distanceMeters),
        'eta_minutes'        => $etaMinutes,
    ]);

} catch (PDOException $e) {
    sendError('Database error fetching tracking data: ' . $e->getMessage(), 500);
}
