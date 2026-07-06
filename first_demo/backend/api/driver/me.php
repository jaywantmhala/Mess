<?php
/**
 * GET /api/driver/me
 * Returns authenticated driver profile.
 * Requires: Authorization: Bearer <JWT>
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'GET')     { sendError('Method not allowed. Use GET.', 405); }

$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;
if (!$payload || !isset($payload['sub']) || ($payload['role'] ?? '') !== 'driver') {
    sendError('Unauthorized. Please log in again.', 401);
}

$pdo  = getDBConnection();
$stmt = $pdo->prepare("
    SELECT id, full_name, email, vehicle_number, phone_number, is_online, latitude, longitude, created_at, updated_at
    FROM drivers WHERE id = :id LIMIT 1
");
$stmt->execute([':id' => (int) $payload['sub']]);
$driver = $stmt->fetch();

if (!$driver) { sendError('Driver profile not found.', 404); }

sendSuccess('Profile fetched.', ['driver' => $driver]);
