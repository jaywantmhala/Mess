<?php
/**
 * POST /api/admin/vendors/delete
 *
 * Delete a vendor account and all associated hotels, menus, and cart items (cascades).
 * Body: { id }
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

// Check if vendor exists
$stmt = $pdo->prepare("SELECT id FROM vendors WHERE id = :id LIMIT 1");
$stmt->execute([':id' => $vendorId]);
if (!$stmt->fetch()) { sendError('Vendor not found.', 404); }

// Delete vendor
$stmt = $pdo->prepare("DELETE FROM vendors WHERE id = :id");

try {
    $stmt->execute([':id' => $vendorId]);
    sendSuccess('Vendor and all associated records deleted successfully.', ['id' => $vendorId]);
} catch (PDOException $e) {
    sendError('Failed to delete vendor: ' . $e->getMessage(), 500);
}
