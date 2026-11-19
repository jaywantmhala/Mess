<?php
/**
 * POST /api/admin/users/status
 *
 * Toggle or set customer active/deactivated status.
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
$userId = (int)$body['id'];

if ($userId <= 0) { sendError('Invalid user ID.', 422); }

$pdo = getDBConnection();

// Fetch customer current status
$stmt = $pdo->prepare("SELECT is_active FROM customers WHERE id = :id LIMIT 1");
$stmt->execute([':id' => $userId]);
$customer = $stmt->fetch();

if (!$customer) { sendError('Customer not found.', 404); }

// Toggle if is_active is not set, otherwise set.
$newStatus = isset($body['is_active']) ? (int)(bool)$body['is_active'] : ((int)$customer['is_active'] === 1 ? 0 : 1);

$stmt = $pdo->prepare("UPDATE customers SET is_active = :is_active, updated_at = NOW() WHERE id = :id");

try {
    $stmt->execute([
        ':is_active' => $newStatus,
        ':id'        => $userId,
    ]);
    
    $statusText = $newStatus === 1 ? 'activated' : 'deactivated';
    sendSuccess("Customer account successfully {$statusText}.", [
        'user' => [
            'id'        => $userId,
            'is_active' => (bool)$newStatus,
        ]
    ]);
} catch (PDOException $e) {
    sendError('Failed to change customer status: ' . $e->getMessage(), 500);
}
