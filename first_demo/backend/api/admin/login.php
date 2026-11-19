<?php
/**
 * POST /api/admin/login
 *
 * Authenticate an admin and return a JWT token.
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

$body     = requireJsonBody(['email', 'password']);
$email    = strtolower(trim($body['email']));
$password = $body['password'];

if (!isValidEmail($email)) { sendError('Please enter a valid email address.', 422); }
if (empty($password))      { sendError('Password is required.', 422); }

$pdo = getDBConnection();

$stmt = $pdo->prepare("
    SELECT id, full_name, email, password, is_active, created_at
    FROM admins WHERE email = :email LIMIT 1
");
$stmt->execute([':email' => $email]);
$admin = $stmt->fetch();

if (!$admin || !password_verify($password, $admin['password'])) {
    sendError('Invalid email or password.', 401);
}

if (!(bool)$admin['is_active']) {
    sendError('Your admin account has been deactivated.', 403);
}

// Strip password from response
unset($admin['password']);

// Generate token
$token = JWT::generate([
    'sub'       => (int) $admin['id'],
    'email'     => $admin['email'],
    'full_name' => $admin['full_name'],
    'role'      => 'admin',
]);

sendSuccess('Login successful.', [
    'token' => $token,
    'admin' => $admin,
]);
