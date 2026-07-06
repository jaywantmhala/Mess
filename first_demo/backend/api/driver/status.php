<?php
/**
 * POST /api/driver/status
 * Updates driver online status and optional location.
 * Requires: Authorization: Bearer <JWT>
 * Body: { is_online, latitude, longitude }
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST')    { sendError('Method not allowed. Use POST.', 405); }

$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;
if (!$payload || !isset($payload['sub']) || ($payload['role'] ?? '') !== 'driver') {
    sendError('Unauthorized. Please log in again.', 401);
}

$driverId = (int)$payload['sub'];
$input = json_decode(file_get_contents('php://input'), true);

$isOnline = isset($input['is_online']) ? (int)$input['is_online'] : 0;
$latitude = isset($input['latitude']) ? (float)$input['latitude'] : null;
$longitude = isset($input['longitude']) ? (float)$input['longitude'] : null;

$pdo = getDBConnection();

if ($latitude !== null && $longitude !== null) {
    $stmt = $pdo->prepare("
        UPDATE drivers 
        SET is_online = :is_online, latitude = :latitude, longitude = :longitude, updated_at = NOW()
        WHERE id = :id
    ");
    $stmt->execute([
        ':is_online' => $isOnline,
        ':latitude'  => $latitude,
        ':longitude' => $longitude,
        ':id'        => $driverId
    ]);
} else {
    $stmt = $pdo->prepare("
        UPDATE drivers 
        SET is_online = :is_online, updated_at = NOW()
        WHERE id = :id
    ");
    $stmt->execute([
        ':is_online' => $isOnline,
        ':id'        => $driverId
    ]);
}

sendSuccess('Status updated successfully.', [
    'is_online' => (bool)$isOnline,
    'latitude' => $latitude,
    'longitude' => $longitude
]);
