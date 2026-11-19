<?php
/**
 * POST /api/admin/vendors/status
 *
 * Toggle or set vendor active/deactivated status.
 * Body: { id, is_active }
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

$body = requireJsonBody(['id']);
$vendorId = (int)$body['id'];

if ($vendorId <= 0) { sendError('Invalid vendor ID.', 422); }

$pdo = getDBConnection();

// Fetch vendor current status
$stmt = $pdo->prepare("SELECT is_active FROM vendors WHERE id = :id LIMIT 1");
$stmt->execute([':id' => $vendorId]);
$vendor = $stmt->fetch();

if (!$vendor) { sendError('Vendor not found.', 404); }

// If is_active is supplied in request body, use it; otherwise toggle it.
$newStatus = isset($body['is_active']) ? (int)(bool)$body['is_active'] : ((int)$vendor['is_active'] === 1 ? 0 : 1);

$stmt = $pdo->prepare("UPDATE vendors SET is_active = :is_active, updated_at = NOW() WHERE id = :id");

try {
    $stmt->execute([
        ':is_active' => $newStatus,
        ':id'        => $vendorId,
    ]);
    
    $statusText = $newStatus === 1 ? 'activated' : 'deactivated';
    sendSuccess("Vendor account successfully {$statusText}.", [
        'vendor' => [
            'id'        => $vendorId,
            'is_active' => (bool)$newStatus,
        ]
    ]);
} catch (PDOException $e) {
    sendError('Failed to change vendor status: ' . $e->getMessage(), 500);
}
