<?php
/**
 * POST /api/vendor/update_fcm_token
 * Updates/registers FCM token for the authenticated vendor.
 * Body: { fcm_token }
 * Header: Authorization: Bearer <token>
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST') { sendError('Method not allowed. Use POST.', 405); }

$token = JWT::getBearerToken();
if (!$token) {
    sendError('Authorization token is required.', 401);
}
$payload = JWT::verify($token);
if (!$payload || !isset($payload['sub']) || ($payload['role'] ?? '') !== 'vendor') {
    sendError('Invalid or expired vendor token.', 401);
}
$vendorId = (int) $payload['sub'];

$body = json_decode(file_get_contents('php://input'), true);
$fcmToken = isset($body['fcm_token']) ? trim($body['fcm_token']) : '';

if (empty($fcmToken)) {
    sendError('fcm_token is required.', 422);
}

try {
    $pdo = getDBConnection();
    $stmt = $pdo->prepare("UPDATE vendors SET fcm_token = ?, updated_at = NOW() WHERE id = ?");
    $stmt->execute([$fcmToken, $vendorId]);
    sendSuccess('Vendor FCM token updated successfully.');
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
