<?php
/**
 * POST /api/admin/vendors/add
 *
 * Add a new vendor account.
 * Body: { full_name, email, password, confirm_password }
 * Requires: Authorization: Bearer <JWT>
 */

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../config/razorpay.php';
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

$body = requireJsonBody(['full_name', 'email', 'password', 'confirm_password']);

$fullName        = sanitize($body['full_name']);
$email           = strtolower(trim($body['email']));
$password        = $body['password'];
$confirmPassword = $body['confirm_password'];

if (strlen($fullName) < 2) { sendError('Full name must be at least 2 characters long.', 422); }
if (!isValidEmail($email)) { sendError('Please enter a valid email address.', 422); }
if (!isValidPassword($password)) {
    sendError('Password must be at least 8 characters long and contain both letters and numbers.', 422);
}
if ($password !== $confirmPassword) { sendError('Passwords do not match.', 422); }

$pdo = getDBConnection();

// Check if vendor already exists
$stmt = $pdo->prepare("SELECT id FROM vendors WHERE email = :email LIMIT 1");
$stmt->execute([':email' => $email]);
if ($stmt->fetch()) { sendError('A vendor account with this email already exists.', 409); }

$hashedPassword = password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);

$stmt = $pdo->prepare("
    INSERT INTO vendors (full_name, email, password, is_active, created_at, updated_at)
    VALUES (:full_name, :email, :password, 1, NOW(), NOW())
");

try {
    $stmt->execute([
        ':full_name' => $fullName,
        ':email'     => $email,
        ':password'  => $hashedPassword,
    ]);
    $vendorId = $pdo->lastInsertId();

    $phone = sanitize($body['phone'] ?? $body['phone_number'] ?? '');
    $rzpContactId = null;
    $rzpRes = createRazorpayContact([
        'name'         => $fullName,
        'email'        => $email,
        'contact'      => $phone,
        'type'         => 'vendor',
        'reference_id' => 'vendor_' . $vendorId,
        'notes'        => [
            'vendor_id'   => (string)$vendorId,
            'created_via' => 'admin_panel',
        ],
    ]);
    if (!empty($rzpRes['success']) && !empty($rzpRes['id'])) {
        $rzpContactId = $rzpRes['id'];
        $pdo->prepare("UPDATE vendors SET razorpay_contact_id = :cid, updated_at = NOW() WHERE id = :id")
            ->execute([':cid' => $rzpContactId, ':id' => $vendorId]);
    }
    
    sendSuccess('Vendor account created successfully.', [
        'vendor' => [
            'id'                  => (int) $vendorId,
            'full_name'           => $fullName,
            'email'               => $email,
            'is_active'           => true,
            'razorpay_contact_id' => $rzpContactId,
        ]
    ], 201);
} catch (PDOException $e) {
    sendError('Failed to create vendor: ' . $e->getMessage(), 500);
}
