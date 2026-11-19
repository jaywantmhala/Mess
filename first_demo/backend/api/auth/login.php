<?php
/**
 * POST /api/auth/login
 *
 * Authenticate a customer and return a JWT token.
 * Body: { email, password }
 */

require_once __DIR__ . '/../../helpers/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/validation.php';
require_once __DIR__ . '/../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');

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

// Timing-safe bcrypt password verification
if (!$customer || !password_verify($password, $customer['password'])) {
    sendError('Invalid email or password.', 401);
}

if (!(bool)$customer['is_active']) {
    sendError('Your account has been deactivated. Please contact support.', 403);
}

// Update last_login_at and set online
$fcmToken = trim($body['fcm_token'] ?? '');
if (!empty($fcmToken)) {
    $pdo->prepare("UPDATE customers SET last_login_at = NOW(), last_seen_at = NOW(), is_online = 1, fcm_token = :fcm, updated_at = NOW() WHERE id = :id")
        ->execute([':id' => $customer['id'], ':fcm' => $fcmToken]);
} else {
    $pdo->prepare("UPDATE customers SET last_login_at = NOW(), last_seen_at = NOW(), is_online = 1, updated_at = NOW() WHERE id = :id")
        ->execute([':id' => $customer['id']]);
}

// Strip password from response
unset($customer['password']);
$customer['last_login_at'] = date('Y-m-d H:i:s');

// JWT
$token = JWT::generate([
    'sub'       => (int) $customer['id'],
    'role'      => 'customer',
    'email'     => $customer['email'],
    'full_name' => $customer['full_name'],
]);

$refreshToken = JWT::generateRefreshToken((int) $customer['id'], 'customer', $pdo);

sendSuccess('Login successful.', [
    'token'         => $token,
    'refresh_token' => $refreshToken,
    'customer'      => $customer,
]);
