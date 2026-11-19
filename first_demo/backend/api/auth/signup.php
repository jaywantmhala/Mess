<?php
/**
 * POST /api/auth/signup
 *
 * Registers a new customer.
 * Body: { full_name, email, password, confirm_password }
 */

require_once __DIR__ . '/../../helpers/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/validation.php';
require_once __DIR__ . '/../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] !== 'POST')    { sendError('Method not allowed. Use POST.', 405); }

// ── Validate Input ────────────────────────────────────────────────────────────
$body            = requireJsonBody(['full_name', 'email', 'password', 'confirm_password', 'phone_number']);
$fullName        = sanitize($body['full_name']);
$email           = strtolower(trim($body['email']));
$password        = $body['password'];
$confirmPassword = $body['confirm_password'];
$phoneNumber     = sanitize($body['phone_number']);

if (strlen($fullName) < 2 || strlen($fullName) > 150) {
    sendError('Full name must be between 2 and 150 characters.', 422);
}
if (!isValidEmail($email)) {
    sendError('Please enter a valid email address.', 422);
}
if (empty($phoneNumber) || strlen($phoneNumber) < 7 || strlen($phoneNumber) > 20) {
    sendError('Please enter a valid phone number.', 422);
}
if (!isValidPassword($password)) {
    sendError('Password must be at least 8 characters with at least one letter and one number.', 422);
}
if ($password !== $confirmPassword) {
    sendError('Passwords do not match.', 422);
}

// ── Database ──────────────────────────────────────────────────────────────────
$pdo = getDBConnection();

// Check for duplicate email
$stmt = $pdo->prepare("SELECT id FROM customers WHERE email = :email LIMIT 1");
$stmt->execute([':email' => $email]);
if ($stmt->fetch()) {
    sendError('An account with this email already exists. Please sign in.', 409);
}

// Bcrypt hash password (cost 12)
$hashedPassword = password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);

$stmt = $pdo->prepare("
    INSERT INTO customers (full_name, email, password, phone_number, created_at, updated_at)
    VALUES (:full_name, :email, :password, :phone_number, NOW(), NOW())
");
$stmt->execute([
    ':full_name'    => $fullName,
    ':email'        => $email,
    ':password'     => $hashedPassword,
    ':phone_number' => $phoneNumber,
]);
$customerId = (int) $pdo->lastInsertId();

// Fetch inserted row (no password)
$stmt = $pdo->prepare("
    SELECT id, full_name, email, phone_number, is_active, email_verified, created_at
    FROM customers WHERE id = :id
");
$stmt->execute([':id' => $customerId]);
$customer = $stmt->fetch();

// JWT
$token = JWT::generate([
    'sub'       => $customerId,
    'role'      => 'customer',
    'email'     => $email,
    'full_name' => $fullName,
]);

$refreshToken = JWT::generateRefreshToken($customerId, 'customer', $pdo);

sendSuccess('Account created successfully.', [
    'token'         => $token,
    'refresh_token' => $refreshToken,
    'customer'      => $customer,
], 201);
