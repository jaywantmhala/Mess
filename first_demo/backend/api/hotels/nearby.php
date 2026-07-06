<?php
/**
 * GET /api/hotels/nearby
 *
 * Fetches hotels within a 2 km radius of the customer's coordinates.
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

// ── JWT Authentication ────────────────────────────────────────────────────────
$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || !isset($payload['sub'])) {
    sendError('Unauthorized. Please log in again.', 401);
}

// ── Validate Query Parameters ──────────────────────────────────────────────────
if (!isset($_GET['latitude']) || trim($_GET['latitude']) === '') {
    sendError("Query parameter 'latitude' is required.", 422);
}
if (!isset($_GET['longitude']) || trim($_GET['longitude']) === '') {
    sendError("Query parameter 'longitude' is required.", 422);
}

$latitude  = filter_var($_GET['latitude'], FILTER_VALIDATE_FLOAT);
$longitude = filter_var($_GET['longitude'], FILTER_VALIDATE_FLOAT);

if ($latitude === false || $latitude < -90.0 || $latitude > 90.0) {
    sendError('Valid latitude between -90 and 90 is required.', 422);
}
if ($longitude === false || $longitude < -180.0 || $longitude > 180.0) {
    sendError('Valid longitude between -180 and 180 is required.', 422);
}

// ── Fetch Hotels ──────────────────────────────────────────────────────────────
try {
    $pdo = getDBConnection();
    
    // Haversine formula calculation in SQL:
    // Earth Radius = 6371 km
    // We use LEAST & GREATEST to clamp the acos argument to [-1, 1] to prevent NaN values
    $stmt = $pdo->prepare("
        SELECT 
            id,
            hotel_name,
            owner_name,
            mobile_number,
            email,
            hotel_address,
            latitude,
            longitude,
            place_id,
            city,
            area,
            state,
            country,
            pincode,
            landmark,
            photo_url,
            created_at,
            (
                6371 * acos(
                    LEAST(1.0, GREATEST(-1.0,
                        cos(radians(:lat1)) * cos(radians(latitude)) *
                        cos(radians(longitude) - radians(:lng)) +
                        sin(radians(:lat2)) * sin(radians(latitude))
                    ))
                )
            ) AS distance
        FROM hotels
        ORDER BY distance ASC
    ");
    
    $stmt->execute([
        ':lat1' => $latitude,
        ':lng'  => $longitude,
        ':lat2' => $latitude,
    ]);
    
    $hotels = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Format distance values to floats for precision
    foreach ($hotels as &$hotel) {
        $hotel['distance'] = (double)$hotel['distance'];
        $hotel['latitude'] = (double)$hotel['latitude'];
        $hotel['longitude'] = (double)$hotel['longitude'];
    }
    unset($hotel);

    sendSuccess('Nearby hotels retrieved.', [
        'hotels' => $hotels,
    ]);
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
