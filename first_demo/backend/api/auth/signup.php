<?php
/**
 * POST /api/auth/signup
 *
 * Registers a new customer.
 * Body: { full_name, email, password, confirm_password }
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

// ── Database ──────────────────────────────────────────────────────────────────
$pdo = getDBConnection();

// Check for duplicate email
$stmt = $pdo->prepare("SELECT id FROM customers WHERE email = :email LIMIT 1");
$stmt->execute([':email' => $email]);
if ($stmt->fetch()) {
    sendError('An account with this email already exists. Please sign in.', 409);
}

// Bcrypt hash (cost 12)
$hashedPassword = password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);

// Insert
$stmt = $pdo->prepare("
    INSERT INTO customers (full_name, email, password, created_at, updated_at)
    VALUES (:full_name, :email, :password, NOW(), NOW())
");
$stmt->execute([
    ':full_name' => $fullName,
    ':email'     => $email,
    ':password'  => $hashedPassword,
]);
$customerId = (int) $pdo->lastInsertId();

// Fetch inserted row (no password)
$stmt = $pdo->prepare("
    SELECT id, full_name, email, is_active, email_verified, created_at
    FROM customers WHERE id = :id
");
$stmt->execute([':id' => $customerId]);
$customer = $stmt->fetch();

// JWT
$token = JWT::generate([
    'sub'       => $customerId,
    'email'     => $email,
    'full_name' => $fullName,
]);

sendSuccess('Account created successfully.', [
    'token'    => $token,
    'customer' => $customer,
], 201);
