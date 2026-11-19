<?php
/**
 * POST /api/admin/signup
 *
 * Register a new admin account.
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

// Check if email already exists
$stmt = $pdo->prepare("SELECT id FROM admins WHERE email = :email LIMIT 1");
$stmt->execute([':email' => $email]);
if ($stmt->fetch()) { sendError('An account with this email already exists.', 409); }

$hashedPassword = password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);

$stmt = $pdo->prepare("
    INSERT INTO admins (full_name, email, password, is_active, created_at, updated_at)
    VALUES (:full_name, :email, :password, 1, NOW(), NOW())
");

try {
    $stmt->execute([
        ':full_name' => $fullName,
        ':email'     => $email,
        ':password'  => $hashedPassword,
    ]);
    $adminId = $pdo->lastInsertId();
} catch (PDOException $e) {
    sendError('Failed to register admin. ' . $e->getMessage(), 500);
}

// Generate token
$token = JWT::generate([
    'sub'       => (int) $adminId,
    'email'     => $email,
    'full_name' => $fullName,
    'role'      => 'admin',
]);

sendSuccess('Admin registered successfully.', [
    'token' => $token,
    'admin' => [
        'id'        => (int) $adminId,
        'full_name' => $fullName,
        'email'     => $email,
    ]
], 201);
