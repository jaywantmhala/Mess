<?php
/**
 * POST /api/admin/users/add
 *
 * Add a new customer account and create their wallet.
 * Body: { full_name, email, password, confirm_password }
 * Requires: Authorization: Bearer <JWT>
 */

require_once __DIR__ . '/../../../config/database.php';
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

// Check if email exists
$stmt = $pdo->prepare("SELECT id FROM customers WHERE email = :email LIMIT 1");
$stmt->execute([':email' => $email]);
if ($stmt->fetch()) { sendError('A customer account with this email already exists.', 409); }

    $hashedPassword = password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);

    // Insert customer with bcrypt hashed password
    $stmt = $pdo->prepare("
        INSERT INTO customers (full_name, email, password, is_active, email_verified, created_at, updated_at)
        VALUES (:full_name, :email, :password, 1, 1, NOW(), NOW())
    ");
    $stmt->execute([
        ':full_name' => $fullName,
        ':email'     => $email,
        ':password'  => $hashedPassword,
    ]);
    $customerId = $pdo->lastInsertId();
    
    // Create customer's wallet
    $stmt = $pdo->prepare("
        INSERT INTO wallets (customer_id, balance, created_at, updated_at)
        VALUES (:customer_id, 0.00, NOW(), NOW())
    ");
    $stmt->execute([':customer_id' => $customerId]);
    
    $pdo->commit();
    
    sendSuccess('Customer account created successfully with empty wallet.', [
        'user' => [
            'id'             => (int) $customerId,
            'full_name'      => $fullName,
            'email'          => $email,
            'is_active'      => true,
            'wallet_balance' => '0.00',
        ]
    ], 201);
} catch (Exception $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    sendError('Failed to create customer account: ' . $e->getMessage(), 500);
}
