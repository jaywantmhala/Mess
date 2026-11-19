<?php
/**
 * GET /api/admin/drivers/details?id=X
 *
 * Retrieve full delivery driver profile details for admin panel.
 * Requires: Authorization: Bearer <JWT>
 */

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'GET')     { sendError('Method not allowed. Use GET.', 405); }

$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || !isset($payload['sub']) || ($payload['role'] ?? '') !== 'admin') {
    sendError('Unauthorized. Admin access required.', 401);
}

$id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
if ($id <= 0) {
    sendError('Invalid driver ID.', 400);
}

$pdo = getDBConnection();

try {
    $stmt = $pdo->prepare("
        SELECT d.id, d.vendor_id, d.full_name, d.email, d.password,
               COALESCE(d.phone_number, '') AS phone_number,
               COALESCE(d.vehicle_number, '') AS vehicle_number,
               COALESCE(d.is_online, 0) AS is_online,
               COALESCE(d.status, 'active') AS status,
               d.max_capacity,
               COALESCE(d.country, 'India') AS country,
               COALESCE(d.state, '') AS state,
               COALESCE(d.district, '') AS district,
               COALESCE(d.taluka, '') AS taluka,
               d.latitude, d.longitude,
               d.created_at, d.updated_at,
               COALESCE(v.full_name, '') AS vendor_name,
               COALESCE(v.business_name, '') AS vendor_business_name,
               COALESCE(v.phone, '') AS vendor_phone,
               COALESCE(v.email, '') AS vendor_email
        FROM drivers d
        LEFT JOIN vendors v ON v.id = d.vendor_id
        WHERE d.id = :id
        LIMIT 1
    ");
    $stmt->execute([':id' => $id]);
    $driver = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$driver) {
        sendError('Driver profile not found.', 404);
    }

    $driver['id'] = (int)$driver['id'];
    $driver['is_online'] = (bool)$driver['is_online'];
    $driver['max_capacity'] = (int)($driver['max_capacity'] ?? 3);

    sendSuccess('Driver profile retrieved successfully.', [
        'driver' => $driver
    ]);
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
