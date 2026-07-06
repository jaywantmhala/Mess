<?php
/**
 * POST /api/auth/login
 *
 * Authenticate a customer and return a JWT token.
 * Body: { email, password }
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
$body     = requireJsonBody(['email', 'password']);
$email    = strtolower(trim($body['email']));
$password = $body['password'];

if (!isValidEmail($email)) { sendError('Please enter a valid email address.', 422); }
if (empty($password))      { sendError('Password is required.', 422); }

// ── Database ──────────────────────────────────────────────────────────────────
$pdo = getDBConnection();

$stmt = $pdo->prepare("
    SELECT id, full_name, email, password, is_active, email_verified, last_login_at, created_at
    FROM customers WHERE email = :email LIMIT 1
");
$stmt->execute([':email' => $email]);
$customer = $stmt->fetch();

// Timing-safe check — prevents user enumeration
if (!$customer || !password_verify($password, $customer['password'])) {
    sendError('Invalid email or password.', 401);
}

if (!(bool)$customer['is_active']) {
    sendError('Your account has been deactivated. Please contact support.', 403);
}

// Update last_login_at
$pdo->prepare("UPDATE customers SET last_login_at = NOW(), updated_at = NOW() WHERE id = :id")
    ->execute([':id' => $customer['id']]);

// Strip password from response
unset($customer['password']);
$customer['last_login_at'] = date('Y-m-d H:i:s');

// JWT
$token = JWT::generate([
    'sub'       => (int) $customer['id'],
    'email'     => $customer['email'],
    'full_name' => $customer['full_name'],
]);

sendSuccess('Login successful.', [
    'token'    => $token,
    'customer' => $customer,
]);
