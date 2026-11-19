<?php
/**
 * POST /api/admin/locations/geocode
 *
 * Geocode an address to coordinates. Admin-only endpoint.
 * Request Body: { "address": "123 Main St, Pune, Maharashtra" }
 * 
 * Also supports reverse geocoding:
 * Request Body: { "latitude": 18.5204, "longitude": 73.8567 }
 */

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/jwt.php';
require_once __DIR__ . '/../../../helpers/validation.php';
require_once __DIR__ . '/../../../helpers/geocoding.php';

// Allow CORS
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendError('Method Not Allowed', 405);
}

// Verify Admin Auth
$headers = getallheaders();
$authHeader = isset($headers['Authorization']) ? $headers['Authorization'] : (isset($headers['authorization']) ? $headers['authorization'] : '');

if (empty($authHeader) || !preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
    sendError('Unauthorized: Missing or invalid token', 401);
}

$token = $matches[1];
$userData = validateJWT($token);

if (!$userData || !isset($userData['role']) || $userData['role'] !== 'admin') {
    sendError('Forbidden: Admin access required', 403);
}

$data = json_decode(file_get_contents("php://input"), true);

if (isset($data['address'])) {
    $address = sanitizeInput($data['address']);
    if (empty($address)) {
        sendError('Address is required', 400);
    }
    
    $result = GeocodingHelper::geocodeAddress($address);
    if ($result['success']) {
        sendSuccess('Address geocoded successfully', $result);
    } else {
        sendError('Failed to geocode address: ' . $result['error'], 400);
    }
} elseif (isset($data['latitude']) && isset($data['longitude'])) {
    $lat = (float) $data['latitude'];
    $lng = (float) $data['longitude'];
    
    $result = GeocodingHelper::reverseGeocode($lat, $lng);
    if ($result['success']) {
        sendSuccess('Coordinates reverse-geocoded successfully', $result);
    } else {
        sendError('Failed to reverse-geocode coordinates: ' . $result['error'], 400);
    }
} else {
    sendError('Either address or both latitude and longitude are required', 400);
}
