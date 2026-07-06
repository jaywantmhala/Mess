<?php
/**
 * POST /api/driver/signup
 * Registers a new driver.
 * Body: { full_name, email, password, confirm_password, vehicle_number, phone_number }
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

$body = requireJsonBody(['full_name', 'email', 'password', 'confirm_password', 'vehicle_number', 'phone_number']);
$fullName = sanitize($body['full_name']);
$email = strtolower(trim($body['email']));
$password = $body['password'];
$confirmPassword = $body['confirm_password'];
$vehicleNumber = sanitize($body['vehicle_number']);
$phoneNumber = sanitize($body['phone_number']);

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
if (empty($vehicleNumber)) {
    sendError('Vehicle number is required.', 422);
}
if (empty($phoneNumber)) {
    sendError('Phone number is required.', 422);
}

$pdo = getDBConnection();

// Check duplicate email
$stmt = $pdo->prepare("SELECT id FROM drivers WHERE email = :email LIMIT 1");
$stmt->execute([':email' => $email]);
if ($stmt->fetch()) {
    sendError('A driver account with this email already exists.', 409);
}

$hashedPassword = password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);

$stmt = $pdo->prepare("
    INSERT INTO drivers (full_name, email, password, vehicle_number, phone_number, is_online, created_at, updated_at)
    VALUES (:full_name, :email, :password, :vehicle_number, :phone_number, 0, NOW(), NOW())
");
$stmt->execute([
    ':full_name' => $fullName,
    ':email'     => $email,
    ':password'  => $hashedPassword,
    ':vehicle_number' => $vehicleNumber,
    ':phone_number' => $phoneNumber
]);
$driverId = (int)$pdo->lastInsertId();

$stmt = $pdo->prepare("SELECT id, full_name, email, vehicle_number, phone_number, is_online, created_at FROM drivers WHERE id = :id");
$stmt->execute([':id' => $driverId]);
$driver = $stmt->fetch();

$token = JWT::generate([
    'sub'       => $driverId,
    'email'     => $email,
    'full_name' => $fullName,
    'role'      => 'driver',
]);

sendSuccess('Driver account created successfully.', [
    'token'  => $token,
    'driver' => $driver,
], 201);
