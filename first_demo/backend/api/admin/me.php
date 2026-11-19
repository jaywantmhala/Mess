<?php
/**
 * GET /api/admin/me
 *
 * Get the profile of the currently logged in admin.
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

if (!$payload || !isset($payload['sub']) || ($payload['role'] ?? '') !== 'admin') {
    sendError('Unauthorized. Admin access required.', 401);
}

$pdo = getDBConnection();

$stmt = $pdo->prepare("
    SELECT id, full_name, email, is_active, created_at, updated_at
    FROM admins WHERE id = :id AND is_active = 1 LIMIT 1
");
$stmt->execute([':id' => (int) $payload['sub']]);
$admin = $stmt->fetch();

if (!$admin) {
    sendError('Admin profile not found or deactivated.', 404);
}

sendSuccess('Admin profile fetched successfully.', [
    'admin' => $admin
]);
