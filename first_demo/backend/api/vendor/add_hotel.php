<?php
/**
 * POST /api/vendor/add_hotel
 *
 * Adds a new hotel under the authenticated vendor.
 * Body: { owner_name, contact_no, hotel_name, address, latitude, longitude, photo_url }
 * Header: Authorization: Bearer <token>
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/validation.php';
require_once __DIR__ . '/../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST')    { sendError('Method not allowed. Use POST.', 405); }

// ── JWT Authentication ────────────────────────────────────────────────────────
$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || !isset($payload['sub'])) {
    sendError('Unauthorized. Please log in again.', 401);
}

$vendorId = (int)$payload['sub'];

// ── Validate Input ────────────────────────────────────────────────────────────
$body = requireJsonBody([
    'owner_name',
    'mobile_number',
    'email',
    'hotel_name',
    'hotel_address',
    'latitude',
    'longitude'
]);

$ownerName    = sanitize($body['owner_name']);
$mobileNumber = sanitize($body['mobile_number']);
$email        = sanitize($body['email']);
$hotelName    = sanitize($body['hotel_name']);
$hotelAddress = sanitize($body['hotel_address']);
$latitude     = filter_var($body['latitude'], FILTER_VALIDATE_FLOAT);
$longitude    = filter_var($body['longitude'], FILTER_VALIDATE_FLOAT);

$placeId  = isset($body['place_id'])  ? sanitize($body['place_id'])  : null;
$city     = isset($body['city'])      ? sanitize($body['city'])      : null;
$area     = isset($body['area'])      ? sanitize($body['area'])      : null;
$state    = isset($body['state'])     ? sanitize($body['state'])     : null;
$country  = isset($body['country'])   ? sanitize($body['country'])   : null;
$pincode  = isset($body['pincode'])   ? sanitize($body['pincode'])   : null;
$landmark = isset($body['landmark'])  ? sanitize($body['landmark'])  : null;
$photoUrl = isset($body['photo_url'])  ? sanitize($body['photo_url'])  : null;

if (empty($ownerName))     { sendError('Owner name is required.', 422); }
if (empty($mobileNumber))  { sendError('Mobile number is required.', 422); }
if (empty($email))         { sendError('Email is required.', 422); }
if (!isValidEmail($email)) { sendError('Valid email is required.', 422); }
if (empty($hotelName))     { sendError('Hotel name is required.', 422); }
if (empty($hotelAddress))  { sendError('Hotel address is required.', 422); }

// Validate coordinate boundaries
if ($latitude === false || $latitude < -90.0 || $latitude > 90.0) {
    sendError('Valid latitude between -90 and 90 is required.', 422);
}
if ($longitude === false || $longitude < -180.0 || $longitude > 180.0) {
    sendError('Valid longitude between -180 and 180 is required.', 422);
}

// ── Database ──────────────────────────────────────────────────────────────────
$pdo = getDBConnection();

// Verify vendor exists and is active
$stmt = $pdo->prepare("SELECT id FROM vendors WHERE id = :id AND is_active = 1 LIMIT 1");
$stmt->execute([':id' => $vendorId]);
if (!$stmt->fetch()) {
    sendError('Vendor account not found or deactivated.', 404);
}

// Insert hotel
$stmt = $pdo->prepare("
    INSERT INTO hotels (
        vendor_id, hotel_name, owner_name, mobile_number, email, hotel_address, 
        latitude, longitude, place_id, city, area, state, country, pincode, landmark, photo_url, created_at, updated_at
    )
    VALUES (
        :vendor_id, :hotel_name, :owner_name, :mobile_number, :email, :hotel_address, 
        :latitude, :longitude, :place_id, :city, :area, :state, :country, :pincode, :landmark, :photo_url, NOW(), NOW()
    )
");
$stmt->execute([
    ':vendor_id'     => $vendorId,
    ':hotel_name'    => $hotelName,
    ':owner_name'    => $ownerName,
    ':mobile_number' => $mobileNumber,
    ':email'         => $email,
    ':hotel_address' => $hotelAddress,
    ':latitude'      => $latitude,
    ':longitude'     => $longitude,
    ':place_id'      => $placeId,
    ':city'          => $city,
    ':area'          => $area,
    ':state'         => $state,
    ':country'       => $country,
    ':pincode'       => $pincode,
    ':landmark'      => $landmark,
    ':photo_url'     => $photoUrl,
]);

$hotelId = (int)$pdo->lastInsertId();

// Fetch the added hotel
$stmt = $pdo->prepare("SELECT * FROM hotels WHERE id = :id");
$stmt->execute([':id' => $hotelId]);
$hotel = $stmt->fetch();

sendSuccess('Hotel added successfully.', [
    'hotel' => $hotel,
], 201);
