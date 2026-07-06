<?php
/**
 * POST /api/driver/login
 * Authenticates a driver and returns a JWT token.
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
    SELECT id, full_name, email, password, vehicle_number, phone_number, is_online, created_at
    FROM drivers WHERE email = :email LIMIT 1
");
$stmt->execute([':email' => $email]);
$driver = $stmt->fetch();

if (!$driver || !password_verify($password, $driver['password'])) {
    sendError('Invalid email or password.', 401);
}

unset($driver['password']);

$token = JWT::generate([
    'sub'       => (int)$driver['id'],
    'email'     => $driver['email'],
    'full_name' => $driver['full_name'],
    'role'      => 'driver',
]);

sendSuccess('Login successful.', [
    'token'  => $token,
    'driver' => $driver,
]);
