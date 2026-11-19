<?php
/**
 * POST /api/vendor/forgot-password/reset
 * Resets vendor password after OTP verification.
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/validation.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST')    { sendError('Method not allowed. Use POST.', 405); }

$rawBody = file_get_contents('php://input');
$body = json_decode($rawBody, true) ?? [];

$email       = strtolower(trim($body['email'] ?? ''));
$otp         = trim((string)($body['otp'] ?? ''));
$newPassword = $body['new_password'] ?? '';

if (empty($email) || empty($otp) || empty($newPassword)) {
    sendError('Email, OTP, and new password are required.', 422);
}

if (strlen($newPassword) < 6) {
    sendError('Password must be at least 6 characters long.', 422);
}

try {
    $pdo = getDBConnection();

    // Verify OTP record
    $stmt = $pdo->prepare("
        SELECT id FROM password_resets 
        WHERE LOWER(email) = LOWER(:email) 
          AND TRIM(otp) = TRIM(:otp) 
        ORDER BY id DESC
        LIMIT 1
    ");
    $stmt->execute([':email' => $email, ':otp' => $otp]);
    $reset = $stmt->fetch();

    if (!$reset) {
        sendError('Invalid or incorrect OTP code.', 400);
    }

    // Hash new password and update vendor account
    $hashedPassword = password_hash($newPassword, PASSWORD_BCRYPT);
    $upStmt = $pdo->prepare("
        UPDATE vendors 
        SET password = :pass, updated_at = NOW() 
        WHERE LOWER(email) = LOWER(:email)
    ");
    $upStmt->execute([
        ':pass'  => $hashedPassword,
        ':email' => $email,
    ]);

    // Delete password reset record
    $delStmt = $pdo->prepare("DELETE FROM password_resets WHERE LOWER(email) = LOWER(:email)");
    $delStmt->execute([':email' => $email]);

    sendSuccess('Password reset successfully. You can now log in.', ['reset' => true]);

} catch (Exception $e) {
    sendError('Server error: ' . $e->getMessage(), 500);
}
