<?php
/**
 * POST /api/vendor/login
 *
 * Authenticate a vendor and return a JWT token.
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
    SELECT id, full_name, email, password, is_active, created_at
    FROM vendors WHERE email = :email LIMIT 1
");
$stmt->execute([':email' => $email]);
$vendor = $stmt->fetch();

if (!$vendor || !password_verify($password, $vendor['password'])) {
    sendError('Invalid email or password.', 401);
}

if (!(bool)$vendor['is_active']) {
    sendError('Your account has been deactivated. Please contact support.', 403);
}

// Strip password
unset($vendor['password']);

// JWT
$token = JWT::generate([
    'sub'       => (int) $vendor['id'],
    'email'     => $vendor['email'],
    'full_name' => $vendor['full_name'],
    'role'      => 'vendor',
]);

sendSuccess('Login successful.', [
    'token'  => $token,
    'vendor' => $vendor,
]);
