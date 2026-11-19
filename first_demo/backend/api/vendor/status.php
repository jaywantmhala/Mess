<?php
/**
 * POST /api/vendor/status
 * Updates vendor online status.
 * Requires: Authorization: Bearer <JWT>
 * Body: { is_online }
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/jwt.php';
require_once __DIR__ . '/../../helpers/ably_helper.php';


header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST')    { sendError('Method not allowed. Use POST.', 405); }

$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;
if (!$payload || !isset($payload['sub']) || ($payload['role'] ?? '') !== 'vendor') {
    sendError('Unauthorized. Please log in again.', 401);
}

$vendorId = (int)$payload['sub'];
$input = json_decode(file_get_contents('php://input'), true);

$isOnline = isset($input['is_online']) ? (int)$input['is_online'] : 1;

try {
    $pdo = getDBConnection();
    
    $stmt = $pdo->prepare("
        UPDATE vendors 
        SET is_online = :is_online, updated_at = NOW()
        WHERE id = :id
    ");
    $stmt->execute([
        ':is_online' => $isOnline,
        ':id'        => $vendorId
    ]);

    // Send notifications via Ably to broadcast to all customer screens
    try {
        AblyHelper::publish('VENDOR_STATUS_UPDATED', [
            'vendor_id' => $vendorId,
            'is_online' => (bool)$isOnline
        ]);

    } catch (Exception $e) {
        // Suppress websocket notification error to avoid blocking the REST response
    }

    sendSuccess('Status updated successfully.', [
        'is_online' => (bool)$isOnline
    ]);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
