<?php
/**
 * POST /api/vendor/forgot-password/send-otp
 * Generates and sends a 6-digit OTP to vendor's email for password reset.
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/validation.php';
require_once __DIR__ . '/../../helpers/mailer.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST')    { sendError('Method not allowed. Use POST.', 405); }

$rawBody = file_get_contents('php://input');
$body = json_decode($rawBody, true) ?? [];

$email = strtolower(trim(sanitize($body['email'] ?? '')));

if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    sendError('Email is not valid', 422);
}

try {
    $pdo = getDBConnection();
    
    // Check if vendor exists
    $stmt = $pdo->prepare("SELECT id FROM vendors WHERE LOWER(email) = LOWER(:email) AND is_active = 1 LIMIT 1");
    $stmt->execute([':email' => $email]);
    $user = $stmt->fetch();

    if (!$user) {
        sendError('Email is not valid', 404);
    }

    // Generate 6-digit OTP
    $otp = (string)random_int(100000, 999999);

    // Delete existing reset requests for this email
    $delStmt = $pdo->prepare("DELETE FROM password_resets WHERE LOWER(email) = LOWER(:email)");
    $delStmt->execute([':email' => $email]);

    // Insert new OTP with 10-minute expiry
    $insStmt = $pdo->prepare("
        INSERT INTO password_resets (email, otp, expires_at, created_at)
        VALUES (:email, :otp, DATE_ADD(NOW(), INTERVAL 10 MINUTE), NOW())
    ");
    $insStmt->execute([
        ':email' => $email,
        ':otp'   => $otp,
    ]);

    // Send email using Gmail SMTP
    $mailRes = sendOTPEmail($email, $otp);

    if ($mailRes['success']) {
        sendSuccess('OTP has been sent to your email address.', [
            'email' => $email,
        ]);
    } else {
        sendError('Failed to send OTP email: ' . ($mailRes['error'] ?? 'Unknown error'), 500);
    }

} catch (Exception $e) {
    sendError('Server error: ' . $e->getMessage(), 500);
}
