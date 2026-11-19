<?php
/**
 * POST /api/admin/vendors/edit
 *
 * Edit a vendor account's full details:
 * - full_name, email, phone, password (optional)
 * - is_active (status)
 * - location: country, state, district, taluka
 * - bank details: bank_name, account_holder_name, account_number, ifsc_code
 * - hotel details: hotel_name, hotel_address, fssai_number, gst_number, pan_number
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

$rawBody = file_get_contents('php://input');
$body = json_decode($rawBody, true) ?? [];

$vendorId = (int)($body['id'] ?? 0);
$fullName = sanitize($body['full_name'] ?? '');
$email    = strtolower(trim($body['email'] ?? ''));
$phone    = sanitize($body['phone'] ?? ($body['mobile_number'] ?? ''));
$password = isset($body['password']) ? trim($body['password']) : '';

$country  = sanitize($body['country'] ?? 'India');
$state    = sanitize($body['state'] ?? '');
$district = sanitize($body['district'] ?? '');
$taluka   = sanitize($body['taluka'] ?? '');
$region   = sanitize($body['region'] ?? '');
$area     = sanitize($body['area'] ?? '');

$isActive = isset($body['is_active']) ? (int)(bool)$body['is_active'] : 1;
$status   = $isActive ? 'active' : 'inactive';

$bankName          = sanitize($body['bank_name'] ?? '');
$accountHolderName = sanitize($body['account_holder_name'] ?? '');
$accountNumber     = sanitize($body['account_number'] ?? '');
$ifscCode          = strtoupper(trim(sanitize($body['ifsc_code'] ?? '')));

$businessName      = sanitize($body['business_name'] ?? $fullName);
$ownerName         = sanitize($body['owner_name'] ?? $fullName);

if ($vendorId <= 0) { sendError('Invalid vendor ID.', 422); }
if (strlen($fullName) < 2) { sendError('Full name must be at least 2 characters long.', 422); }
if (!isValidEmail($email)) { sendError('Please enter a valid email address.', 422); }

$pdo = getDBConnection();

// Check if vendor exists
$stmt = $pdo->prepare("SELECT id FROM vendors WHERE id = :id LIMIT 1");
$stmt->execute([':id' => $vendorId]);
if (!$stmt->fetch()) { sendError('Vendor not found.', 404); }

// Check if email is already taken by another vendor
$stmt = $pdo->prepare("SELECT id FROM vendors WHERE email = :email AND id != :id LIMIT 1");
$stmt->execute([':email' => $email, ':id' => $vendorId]);
if ($stmt->fetch()) { sendError('This email is already in use by another vendor.', 409); }

try {
    $pdo->beginTransaction();

    $fields = [
        'full_name = :full_name',
        'email = :email',
        'phone = :phone',
        'mobile_number = :mobile_number',
        'country = :country',
        'state = :state',
        'district = :district',
        'taluka = :taluka',
        'region = :region',
        'area = :area',
        'is_active = :is_active',
        'status = :status',
        'bank_name = :bank_name',
        'account_holder_name = :account_holder_name',
        'account_number = :account_number',
        'ifsc_code = :ifsc_code',
        'business_name = :business_name',
        'owner_name = :owner_name',
        'updated_at = NOW()'
    ];

    $params = [
        ':full_name'           => $fullName,
        ':email'               => $email,
        ':phone'               => $phone,
        ':mobile_number'       => $phone,
        ':country'             => $country,
        ':state'               => $state,
        ':district'            => $district,
        ':taluka'              => $taluka,
        ':region'              => $region,
        ':area'                => $area,
        ':is_active'           => $isActive,
        ':status'              => $status,
        ':bank_name'           => $bankName,
        ':account_holder_name' => $accountHolderName,
        ':account_number'      => $accountNumber,
        ':ifsc_code'           => $ifscCode,
        ':business_name'       => $businessName,
        ':owner_name'          => $ownerName,
        ':id'                  => $vendorId,
    ];

    if (!empty($password)) {
        $fields[] = 'password = :password';
        $params[':password'] = password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);
    }

    $sql = "UPDATE vendors SET " . implode(', ', $fields) . " WHERE id = :id";
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);

    // Optional hotel update if hotel fields are provided
    $hotelName    = sanitize($body['hotel_name'] ?? '');
    $hotelAddress = sanitize($body['hotel_address'] ?? '');
    $fssaiNumber  = sanitize($body['fssai_number'] ?? '');
    $gstNumber    = sanitize($body['gst_number'] ?? '');
    $panNumber    = sanitize($body['pan_number'] ?? '');
    $aadharNumber = sanitize($body['aadhar_number'] ?? '');

    // Check if vendor has a hotel record
    $hotelCheckStmt = $pdo->prepare("SELECT id FROM hotels WHERE vendor_id = :vendor_id ORDER BY id ASC LIMIT 1");
    $hotelCheckStmt->execute([':vendor_id' => $vendorId]);
    $existingHotelId = $hotelCheckStmt->fetchColumn();

    if ($existingHotelId) {
        $hotelUpdates = ['updated_at = NOW()'];
        $hotelParams = [':hotel_id' => $existingHotelId];

        if (!empty($hotelName)) {
            $hotelUpdates[] = 'hotel_name = :hotel_name';
            $hotelParams[':hotel_name'] = $hotelName;
        }
        if (!empty($hotelAddress)) {
            $hotelUpdates[] = 'hotel_address = :hotel_address';
            $hotelParams[':hotel_address'] = $hotelAddress;
        }
        if (isset($body['fssai_number'])) {
            $hotelUpdates[] = 'fssai_number = :fssai_number';
            $hotelParams[':fssai_number'] = $fssaiNumber;
        }
        if (isset($body['gst_number'])) {
            $hotelUpdates[] = 'gst_number = :gst_number';
            $hotelParams[':gst_number'] = $gstNumber;
        }
        if (isset($body['pan_number'])) {
            $hotelUpdates[] = 'pan_number = :pan_number';
            $hotelParams[':pan_number'] = $panNumber;
        }
        if (isset($body['aadhar_number'])) {
            $hotelUpdates[] = 'aadhar_number = :aadhar_number';
            $hotelParams[':aadhar_number'] = $aadharNumber;
        }
        if (!empty($phone)) {
            $hotelUpdates[] = 'mobile_number = :hotel_mobile';
            $hotelParams[':hotel_mobile'] = $phone;
        }
        if (!empty($ownerName)) {
            $hotelUpdates[] = 'owner_name = :hotel_owner';
            $hotelParams[':hotel_owner'] = $ownerName;
        }
        if (isset($body['state'])) {
            $hotelUpdates[] = 'state = :hotel_state';
            $hotelParams[':hotel_state'] = $state;
        }
        if (isset($body['district'])) {
            $hotelUpdates[] = 'district = :hotel_district';
            $hotelParams[':hotel_district'] = $district;
        }
        if (isset($body['taluka'])) {
            $hotelUpdates[] = 'taluka = :hotel_taluka';
            $hotelParams[':hotel_taluka'] = $taluka;
        }
        if (isset($body['region'])) {
            $hotelUpdates[] = 'region = :hotel_region';
            $hotelParams[':hotel_region'] = $region;
        }
        if (isset($body['area'])) {
            $hotelUpdates[] = 'area = :hotel_area';
            $hotelParams[':hotel_area'] = $area;
        }

        if (count($hotelUpdates) > 1) {
            $hotelSql = "UPDATE hotels SET " . implode(', ', $hotelUpdates) . " WHERE id = :hotel_id";
            $hotelStmt = $pdo->prepare($hotelSql);
            $hotelStmt->execute($hotelParams);
        }
    }

    $pdo->commit();

    sendSuccess('Vendor details updated successfully.', [
        'vendor' => [
            'id'                  => $vendorId,
            'full_name'           => $fullName,
            'email'               => $email,
            'phone'               => $phone,
            'country'             => $country,
            'state'               => $state,
            'district'            => $district,
            'taluka'              => $taluka,
            'region'              => $region,
            'area'                => $area,
            'bank_name'           => $bankName,
            'account_holder_name' => $accountHolderName,
            'account_number'      => $accountNumber,
            'ifsc_code'           => $ifscCode,
            'is_active'           => (bool)$isActive,
            'status'              => $status,
            'hotel_name'          => $hotelName
        ]
    ]);
} catch (Exception $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    sendError('Failed to update vendor: ' . $e->getMessage(), 500);
}
