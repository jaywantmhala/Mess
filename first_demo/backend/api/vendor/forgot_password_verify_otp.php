<?php
/**
 * POST /api/vendor/forgot-password/verify-otp
 * Verifies entered OTP against active reset records.
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

$email = strtolower(trim($body['email'] ?? ''));
$otp   = trim((string)($body['otp'] ?? ''));

if (empty($email) || empty($otp)) {
    sendError('Email and OTP are required.', 422);
}

try {
    $pdo = getDBConnection();
    
    $stmt = $pdo->prepare("
        SELECT id, expires_at FROM password_resets 
        WHERE LOWER(email) = LOWER(:email) 
          AND TRIM(otp) = TRIM(:otp)
        ORDER BY id DESC
        LIMIT 1
    ");
    $stmt->execute([':email' => $email, ':otp' => $otp]);
    $reset = $stmt->fetch();

    if ($reset) {
        // Check if created within last 15 minutes
        $expiresAt = strtotime($reset['expires_at']);
        if ($expiresAt && $expiresAt < (time() - 900)) {
            sendError('OTP code has expired. Please request a new code.', 400);
        }
        sendSuccess('OTP verified successfully.', ['valid' => true]);
    } else {
        sendError('Invalid or incorrect OTP code.', 400);
    }
} catch (Exception $e) {
    sendError('Server error: ' . $e->getMessage(), 500);
}
