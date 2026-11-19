<?php
/**
 * POST /api/admin/users/delete
 *
 * Delete a customer account and all associated wallets, orders, cart items (cascades).
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
$userId = (int)$body['id'];

if ($userId <= 0) { sendError('Invalid user ID.', 422); }

$pdo = getDBConnection();

// Check if customer exists
$stmt = $pdo->prepare("SELECT id FROM customers WHERE id = :id LIMIT 1");
$stmt->execute([':id' => $userId]);
if (!$stmt->fetch()) { sendError('Customer not found.', 404); }

// Delete customer
$stmt = $pdo->prepare("DELETE FROM customers WHERE id = :id");

try {
    $stmt->execute([':id' => $userId]);
    sendSuccess('Customer and all associated records deleted successfully.', ['id' => $userId]);
} catch (PDOException $e) {
    sendError('Failed to delete customer: ' . $e->getMessage(), 500);
}
