<?php
/**
 * POST /api/auth/send-otp
 *
 * Generate & send 6-digit WhatsApp OTP for customer or vendor login/signup.
 * Body: { phone: "9876543210", role: "customer" } (role defaults to "customer")
 */

require_once __DIR__ . '/../../helpers/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/validation.php';
require_once __DIR__ . '/../../helpers/click2api_helper.php';

header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendError('Method not allowed. Use POST.', 405);
}

$rawBody = file_get_contents('php://input');
$body = json_decode($rawBody, true) ?? [];

$phone = preg_replace('/[^0-9]/', '', trim($body['phone'] ?? ''));
$role  = strtolower(trim($body['role'] ?? 'customer'));

if (!in_array($role, ['customer', 'vendor'])) {
    $role = 'customer';
}

if (strlen($phone) < 10) {
    sendError('Please enter a valid 10-digit mobile number.', 422);
}

// Take last 10 digits
if (strlen($phone) > 10) {
    $phone = substr($phone, -10);
}

try {
    $pdo = getDBConnection();

    // Generate 6-digit OTP
    $otp = sprintf("%06d", random_int(100000, 999999));

    // Clear old OTPs for this phone + role
    $del = $pdo->prepare("DELETE FROM otp_verifications WHERE phone = :phone AND role = :role");
    $del->execute([':phone' => $phone, ':role' => $role]);

    // Insert new OTP with 10-minute validity
    $ins = $pdo->prepare("
        INSERT INTO otp_verifications (phone, otp, role, expires_at, created_at)
        VALUES (:phone, :otp, :role, DATE_ADD(NOW(), INTERVAL 10 MINUTE), NOW())
    ");
    $ins->execute([
        ':phone' => $phone,
        ':otp'   => $otp,
        ':role'  => $role
    ]);

    // Dispatch WhatsApp Message via Click2Api
    $sendRes = sendWhatsAppOTP($phone, $otp, 'hungrily_otp');

    if ($sendRes['success']) {
        sendSuccess('OTP has been sent to your WhatsApp number.', [
            'phone'       => $phone,
            'role'        => $role,
            'expires_in'  => 600 // 10 minutes in seconds
        ]);
    } else {
        // Fallback: If gateway fails, return error with context
        sendError('Failed to send OTP via WhatsApp: ' . $sendRes['message'], 500);
    }
} catch (Exception $e) {
    sendError('Server error: ' . $e->getMessage(), 500);
}
