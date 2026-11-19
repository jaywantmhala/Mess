<?php
/**
 * POST /api/auth/refresh
 *
 * Exchanging a valid Refresh Token for a new Access Token & rotated Refresh Token.
 * Body: { "refresh_token": "..." }
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendError('Method not allowed. Use POST.', 405);
}

$body = json_decode(file_get_contents('php://input'), true) ?? [];
$refreshToken = trim($body['refresh_token'] ?? '');

if (empty($refreshToken)) {
    sendError('Refresh token is required.', 401);
}

$pdo = getDBConnection();

$session = JWT::verifyRefreshToken($refreshToken, $pdo);
if (!$session) {
    sendError('Invalid or expired refresh token.', 401);
}

$userId = $session['user_id'];
$role   = $session['role'];

// Fetch user data based on role
$userData = null;
if ($role === 'vendor') {
    $stmt = $pdo->prepare("SELECT id, full_name, email, is_active FROM vendors WHERE id = :id LIMIT 1");
    $stmt->execute([':id' => $userId]);
    $userData = $stmt->fetch();
} else if ($role === 'driver') {
    $stmt = $pdo->prepare("SELECT id, full_name, email, is_active FROM drivers WHERE id = :id LIMIT 1");
    $stmt->execute([':id' => $userId]);
    $userData = $stmt->fetch();
} else { // customer
    $stmt = $pdo->prepare("SELECT id, full_name, email, is_active FROM customers WHERE id = :id LIMIT 1");
    $stmt->execute([':id' => $userId]);
    $userData = $stmt->fetch();
}

if (!$userData || (isset($userData['is_active']) && (int)$userData['is_active'] === 0)) {
    JWT::revokeRefreshToken($refreshToken, $pdo);
    sendError('User account is inactive or disabled.', 401);
}

// Generate new access token (1 hour)
$newAccessToken = JWT::generate([
    'sub'       => $userId,
    'role'      => $role,
    'email'     => $userData['email'],
    'full_name' => $userData['full_name'] ?? '',
]);

// Rotate refresh token (30 days)
$newRefreshToken = JWT::generateRefreshToken($userId, $role, $pdo);

sendSuccess('Token refreshed successfully.', [
    'token'         => $newAccessToken,
    'refresh_token' => $newRefreshToken,
    'role'          => $role,
]);
