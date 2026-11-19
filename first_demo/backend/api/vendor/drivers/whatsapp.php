<?php
/**
 * POST /api/vendor/drivers/whatsapp
 *
 * Sends a dynamic WhatsApp message to a vendor's driver using the Meta / Click2Api WhatsApp API
 * (the same WhatsApp API used in Admin Panel Broadcasts).
 * Requires: Authorization: Bearer <JWT> (Vendor role required)
 * Body: { driver_id?, phone?, message }
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST') { sendError('Method not allowed.', 405); }

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/jwt.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/click2api_helper.php';

$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || ($payload['role'] ?? '') !== 'vendor') {
    sendError('Unauthorized access. Vendor token required.', 401);
}

$vendorId = (int)$payload['sub'];

$body = json_decode(file_get_contents('php://input'), true);
if (!is_array($body)) {
    sendError('Invalid JSON payload.', 400);
}

$driverId = isset($body['driver_id']) ? (int)$body['driver_id'] : 0;
$phone    = trim($body['phone'] ?? ($body['phone_number'] ?? ''));
$message  = trim($body['message'] ?? '');
$driverName = trim($body['driver_name'] ?? '');

$pdo = getDBConnection();

// If driver_id provided, verify ownership and get details
if ($driverId > 0) {
    $stmt = $pdo->prepare("SELECT id, full_name, phone_number, vehicle_number FROM drivers WHERE id = ? AND vendor_id = ? LIMIT 1");
    $stmt->execute([$driverId, $vendorId]);
    $driver = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$driver) {
        sendError('Driver not found or does not belong to your account.', 404);
    }
    if (empty($phone)) {
        $phone = $driver['phone_number'];
    }
    if (empty($driverName)) {
        $driverName = $driver['full_name'];
    }
}

if (empty($phone)) {
    sendError('Driver phone number is required.', 422);
}
if (empty($message)) {
    sendError('Message content is required.', 422);
}

$cleanPhone = preg_replace('/[^0-9]/', '', $phone);
$last10 = substr($cleanPhone, -10);

if (strlen($last10) < 10) {
    sendError('Invalid 10-digit mobile number.', 422);
}

// Dispatch WhatsApp message via Meta Approved Template (hungrily_broadcast)
$waSuccess = false;
$waMessage = '';

try {
    $res = sendDriverCredentialsWhatsApp($last10, $driverName, $message);
    if (!empty($res['success'])) {
        $waSuccess = true;
        $waMessage = 'WhatsApp message dispatched successfully via Meta WhatsApp API.';
    } else {
        $waMessage = $res['message'] ?? 'Failed to deliver WhatsApp message via server API.';
    }
} catch (Throwable $e) {
    $waMessage = $e->getMessage();
    error_log("[Vendor Driver WhatsApp Send Error] " . $e->getMessage());
}

if ($waSuccess) {
    sendSuccess('WhatsApp message sent successfully via WhatsApp API.', [
        'phone'            => $last10,
        'driver_name'      => $driverName,
        'whatsapp_sent'    => true,
        'whatsapp_message' => $waMessage,
    ]);
} else {
    sendError('WhatsApp delivery error: ' . $waMessage, 502);
}
