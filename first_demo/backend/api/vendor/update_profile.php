<?php
/**
 * POST /api/vendor/update_profile
 *
 * Update vendor profile information (full_name, email, phone, country, state, district, taluka).
 * Requires: Authorization: Bearer <JWT>
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

$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || !isset($payload['sub'])) {
    sendError('Unauthorized. Vendor access required.', 401);
}

$vendorId = (int) $payload['sub'];

$body = json_decode(file_get_contents('php://input'), true) ?? [];

$pdo = getDBConnection();

// Check if vendor exists
$stmt = $pdo->prepare("SELECT id, full_name, email, phone, country, state, district, taluka FROM vendors WHERE id = :id LIMIT 1");
$stmt->execute([':id' => $vendorId]);
$existingVendor = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$existingVendor) {
    sendError('Vendor profile not found.', 404);
}

$fullName = sanitize($body['full_name'] ?? $body['fullName'] ?? '');
$email    = strtolower(trim($body['email'] ?? ''));
$phone    = sanitize($body['phone_number'] ?? $body['phoneNumber'] ?? $body['phone'] ?? '');
$country  = sanitize($body['country'] ?? '');
$state    = sanitize($body['state'] ?? '');
$district = sanitize($body['district'] ?? '');
$taluka   = sanitize($body['taluka'] ?? '');

$fullName = !empty($fullName) ? $fullName : $existingVendor['full_name'];
$email    = !empty($email) ? $email : $existingVendor['email'];
$phone    = !empty($phone) ? $phone : ($existingVendor['phone'] ?? '');
$country  = !empty($country) ? $country : ($existingVendor['country'] ?? 'India');
$state    = !empty($state) ? $state : ($existingVendor['state'] ?? '');
$district = !empty($district) ? $district : ($existingVendor['district'] ?? '');
$taluka   = !empty($taluka) ? $taluka : ($existingVendor['taluka'] ?? '');

if (!empty($email) && !isValidEmail($email)) {
    sendError('Please enter a valid email address.', 422);
}

// Update profile
$stmt = $pdo->prepare("
    UPDATE vendors SET
        full_name  = :full_name,
        email      = :email,
        phone      = :phone,
        country    = :country,
        state      = :state,
        district   = :district,
        taluka     = :taluka,
        updated_at = NOW()
    WHERE id = :id
");
$stmt->execute([
    ':full_name' => $fullName,
    ':email'     => $email,
    ':phone'     => $phone,
    ':country'   => $country,
    ':state'     => $state,
    ':district'  => $district,
    ':taluka'    => $taluka,
    ':id'        => $vendorId,
]);

// Fetch updated row
$stmt = $pdo->prepare("
    SELECT id, full_name, email, phone, country, state, district, taluka, is_active, created_at, updated_at
    FROM vendors WHERE id = :id LIMIT 1
");
$stmt->execute([':id' => $vendorId]);
$updatedVendor = $stmt->fetch(PDO::FETCH_ASSOC);

sendSuccess('Profile updated successfully!', [
    'vendor' => $updatedVendor,
]);
