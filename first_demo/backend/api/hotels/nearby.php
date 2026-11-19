<?php
/**
 * GET /api/hotels/nearby
 *
 * Fetches nearby hotels within customer's radius based on GPS coordinates.
 * Query Parameters: latitude, longitude
 * Header: Authorization: Bearer <token>
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/validation.php';
require_once __DIR__ . '/../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    sendError('Method not allowed. Use GET.', 405);
}

// ── JWT Authentication (Optional for Public Website) ──────────────────────────
$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;
$customerId = ($payload && isset($payload['sub'])) ? (int)$payload['sub'] : null;
$hasSub = false;

// ── Validate Query Parameters ──────────────────────────────────────────────────
$latitude  = isset($_GET['latitude']) ? filter_var($_GET['latitude'], FILTER_VALIDATE_FLOAT) : false;
$longitude = isset($_GET['longitude']) ? filter_var($_GET['longitude'], FILTER_VALIDATE_FLOAT) : false;

// Fallback to Pune coordinates if not provided or invalid
if ($latitude === false || $latitude < -90.0 || $latitude > 90.0) {
    $latitude = 18.5204;
}
if ($longitude === false || $longitude < -180.0 || $longitude > 180.0) {
    $longitude = 73.8567;
}

// ── Fetch Hotels ──────────────────────────────────────────────────────────────
try {
    $pdo = getDBConnection();
    
    if ($customerId) {
        // Check if customer has an active subscription
        $subStmt = $pdo->prepare("
            SELECT id FROM customer_subscriptions
            WHERE customer_id = :customer_id AND status = 'ACTIVE' AND end_date >= CURDATE() AND remaining_deliveries > 0
            ORDER BY id DESC
            LIMIT 1
        ");
        $subStmt->execute([':customer_id' => $customerId]);
        $activeSub = $subStmt->fetch(PDO::FETCH_ASSOC);
        $hasSub = (bool)$activeSub;
    }

    $foodTypeParam = isset($_GET['food_type']) ? strtoupper(trim($_GET['food_type'])) : (isset($_GET['type']) ? strtoupper(trim($_GET['type'])) : '');

    $whereConds = [];
    $params = [
        ':lat1' => $latitude,
        ':lng'  => $longitude,
        ':lat2' => $latitude,
    ];

    if (!empty($foodTypeParam) && $foodTypeParam !== 'ALL') {
        if ($foodTypeParam === 'VEG') {
            $whereConds[] = "(COALESCE(h.food_type, 'BOTH') IN ('VEG', 'BOTH', ''))";
        } else if ($foodTypeParam === 'NON-VEG' || $foodTypeParam === 'NON_VEG') {
            $whereConds[] = "(COALESCE(h.food_type, 'BOTH') IN ('NON-VEG', 'NON_VEG', 'BOTH', ''))";
        }
    }

    $whereClause = !empty($whereConds) ? 'WHERE ' . implode(' AND ', $whereConds) : '';

    // Haversine formula calculation in SQL for distance calculation:
    // Calculates distance in km from customer's coordinates
    $stmt = $pdo->prepare("
        SELECT 
            h.id,
            h.vendor_id,
            h.hotel_name,
            h.owner_name,
            h.mobile_number,
            h.email,
            h.hotel_address,
            h.latitude,
            h.longitude,
            h.place_id,
            h.city,
            h.area,
            h.state,
            h.country,
            h.pincode,
            h.landmark,
            h.photo_url,
            COALESCE(h.service_type, 'BOTH') AS service_type,
            COALESCE(h.food_type, 'BOTH') AS food_type,
            h.created_at,
            v.is_online AS is_vendor_online,
            (
                6371 * acos(
                    LEAST(1.0, GREATEST(-1.0,
                        cos(radians(:lat1)) * cos(radians(h.latitude)) *
                        cos(radians(h.longitude) - radians(:lng)) +
                        sin(radians(:lat2)) * sin(radians(h.latitude))
                    ))
                )
            ) AS distance
        FROM hotels h
        LEFT JOIN vendors v ON h.vendor_id = v.id
        $whereClause
        ORDER BY distance ASC
    ");
    
    $stmt->execute($params);
    
    $hotels = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Format distance and numbers
    foreach ($hotels as &$hotel) {
        $hotel['distance'] = round((float)$hotel['distance'], 2);
        $hotel['latitude'] = (float)$hotel['latitude'];
        $hotel['longitude'] = (float)$hotel['longitude'];
        $hotel['is_vendor_online'] = (bool)$hotel['is_vendor_online'];
    }
    unset($hotel);

    sendSuccess('Nearby hotels retrieved.', [
        'has_active_subscription' => $hasSub,
        'hotels' => $hotels,
        'serviceable' => true
    ]);
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
