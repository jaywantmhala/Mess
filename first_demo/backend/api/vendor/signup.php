<?php
/**
 * POST /api/vendor/signup
 *
 * Registers a new vendor.
 * Body: { full_name, email, password, confirm_password }
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/razorpay.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/validation.php';
require_once __DIR__ . '/../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST')    { sendError('Method not allowed. Use POST.', 405); }

// ── Validate Input ────────────────────────────────────────────────────────────
$body            = requireJsonBody(['full_name', 'email', 'password', 'confirm_password']);
$fullName        = sanitize($body['full_name']);
$email           = strtolower(trim($body['email']));
$password        = $body['password'];
$confirmPassword = $body['confirm_password'];

if (strlen($fullName) < 2 || strlen($fullName) > 150) {
    sendError('Full name must be between 2 and 150 characters.', 422);
}
if (!isValidEmail($email)) {
    sendError('Please enter a valid email address.', 422);
}
if (!isValidPassword($password)) {
    sendError('Password must be at least 8 characters with at least one letter and one number.', 422);
}
if ($password !== $confirmPassword) {
    sendError('Passwords do not match.', 422);
}

// ── Validate Mandatory Phone Number ─────────────────────────────────────────
$rawPhone = trim($body['phone_number'] ?? $body['phone'] ?? '');
$phone    = preg_replace('/[^0-9]/', '', $rawPhone);
if (strlen($phone) > 10) {
    $phone = substr($phone, -10);
}
if (strlen($phone) < 10) {
    sendError('Please enter a valid 10-digit mobile number.', 422);
}

// ── Database ──────────────────────────────────────────────────────────────────
$pdo = getDBConnection();

// Check for duplicate email
$stmt = $pdo->prepare("SELECT id FROM vendors WHERE email = :email LIMIT 1");
$stmt->execute([':email' => $email]);
if ($stmt->fetch()) {
    sendError('A vendor account with this email already exists. Please sign in.', 409);
}

// Check for duplicate phone
$stmt = $pdo->prepare("SELECT id FROM vendors WHERE phone = :phone OR phone LIKE :phone_like LIMIT 1");
$stmt->execute([':phone' => $phone, ':phone_like' => '%' . $phone]);
if ($stmt->fetch()) {
    sendError('A vendor account with this mobile number already exists. Please sign in.', 409);
}

$country  = sanitize($body['country'] ?? 'India');
$state    = sanitize($body['state'] ?? '');
$district = sanitize($body['district'] ?? '');
$taluka   = sanitize($body['taluka'] ?? '');

// Bcrypt hash (cost 12)
$hashedPassword = password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);

// Insert
$stmt = $pdo->prepare("
    INSERT INTO vendors (full_name, email, password, phone, country, state, district, taluka, created_at, updated_at)
    VALUES (:full_name, :email, :password, :phone, :country, :state, :district, :taluka, NOW(), NOW())
");
$stmt->execute([
    ':full_name' => $fullName,
    ':email'     => $email,
    ':password'  => $hashedPassword,
    ':phone'     => $phone,
    ':country'   => $country,
    ':state'     => $state,
    ':district'  => $district,
    ':taluka'    => $taluka,
]);
$vendorId = (int) $pdo->lastInsertId();

// ── Razorpay Contact Creation ─────────────────────────────────────────
$razorpayContactId = !empty($body['razorpay_contact_id']) ? sanitize($body['razorpay_contact_id']) : null;
$razorpayContactData = null;

if (empty($razorpayContactId)) {
    $rzpRes = createRazorpayContact([
        'name'         => $fullName,
        'email'        => $email,
        'contact'      => $phone,
        'type'         => 'vendor',
        'reference_id' => 'vendor_' . $vendorId,
        'notes'        => [
            'vendor_id'      => (string)$vendorId,
            'district'       => $district,
            'taluka'         => $taluka,
            'state'          => $state,
            'registered_via' => 'vendor_app_signup',
        ],
    ]);
    if (!empty($rzpRes['success']) && !empty($rzpRes['id'])) {
        $razorpayContactId   = $rzpRes['id'];
        $razorpayContactData = $rzpRes['data'];
    }
}

if (!empty($razorpayContactId)) {
    try {
        $pdo->prepare("UPDATE vendors SET razorpay_contact_id = :cid, updated_at = NOW() WHERE id = :id")
            ->execute([':cid' => $razorpayContactId, ':id' => $vendorId]);
    } catch (Exception $e) {
        error_log("[Signup] Failed to update razorpay_contact_id: " . $e->getMessage());
    }
}

// Fetch inserted row (no password)
$stmt = $pdo->prepare("
    SELECT id, full_name, email, phone, country, state, district, taluka, is_active, razorpay_contact_id, created_at
    FROM vendors WHERE id = :id
");
$stmt->execute([':id' => $vendorId]);
$vendor = $stmt->fetch();

// JWT
$token = JWT::generate([
    'sub'       => $vendorId,
    'email'     => $email,
    'full_name' => $fullName,
    'role'      => 'vendor',
]);

$refreshToken = JWT::generateRefreshToken($vendorId, 'vendor', $pdo);

sendSuccess('Vendor account created successfully.', [
    'token'               => $token,
    'refresh_token'       => $refreshToken,
    'vendor'              => $vendor,
    'razorpay_contact_id' => $razorpayContactId,
    'razorpay_contact'    => $razorpayContactData,
], 201);
