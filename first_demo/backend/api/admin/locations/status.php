<?php
/**
 * POST /api/admin/locations/status
 *
 * Toggle or set the active status of a location component (city, pincode, area, sub_area, plan).
 * Requires: Authorization: Bearer <JWT>
 */

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/validation.php';
require_once __DIR__ . '/../../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST')    { sendError('Method not allowed. Use POST.', 405); }

$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || !isset($payload['sub']) || ($payload['role'] ?? '') !== 'admin') {
    sendError('Unauthorized. Admin access required.', 401);
}

$body = requireJsonBody(['type', 'id']);
$type = trim($body['type']);
$id   = (int)$body['id'];

if ($id <= 0) { sendError('Invalid ID.', 422); }

$allowedTypes = ['city', 'pincode', 'area', 'sub_area', 'plan'];
if (!in_array($type, $allowedTypes)) {
    sendError('Invalid type. Must be city, pincode, area, sub_area, or plan.', 422);
}

// Map types to tables
$tables = [
    'city'     => 'cities',
    'pincode'  => 'pincodes',
    'area'     => 'areas',
    'sub_area' => 'sub_areas',
    'plan'     => 'subscription_plans'
];
$table = $tables[$type];

$pdo = getDBConnection();

try {
    // 1. Fetch current status
    $stmt = $pdo->prepare("SELECT is_active FROM `{$table}` WHERE id = :id LIMIT 1");
    $stmt->execute([':id' => $id]);
    $row = $stmt->fetch();
    
    if (!$row) {
        sendError(ucfirst($type) . ' not found.', 404);
    }
    
    // Toggle if not explicitly sent
    $newStatus = isset($body['is_active']) ? (int)(bool)$body['is_active'] : ((int)$row['is_active'] === 1 ? 0 : 1);
    
    // 2. Update status
    $stmt = $pdo->prepare("UPDATE `{$table}` SET is_active = :status, updated_at = NOW() WHERE id = :id");
    $stmt->execute([':status' => $newStatus, ':id' => $id]);
    
    $statusText = $newStatus === 1 ? 'activated' : 'deactivated';
    sendSuccess(ucfirst($type) . " successfully {$statusText}.", [
        'id'        => $id,
        'type'      => $type,
        'is_active' => (bool)$newStatus
    ]);
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
