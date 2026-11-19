<?php
/**
 * POST /api/customer/status
 * Updates customer online status and last_seen_at heartbeat.
 * Requires: Authorization: Bearer <JWT>
 * Body: { is_online?: int|bool }
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
if (!$payload || !isset($payload['sub'])) {
    sendError('Unauthorized. Please log in again.', 401);
}

$customerId = (int)$payload['sub'];
$input = json_decode(file_get_contents('php://input'), true) ?? [];

$isOnline = isset($input['is_online']) ? (int)(bool)$input['is_online'] : 1;

try {
    $pdo = getDBConnection();
    
    $stmt = $pdo->prepare("
        UPDATE customers 
        SET is_online = :is_online, last_seen_at = NOW(), updated_at = NOW()
        WHERE id = :id
    ");
    $stmt->execute([
        ':is_online' => $isOnline,
        ':id'        => $customerId
    ]);

    sendSuccess('Customer status updated successfully.', [
        'customer_id'  => $customerId,
        'is_online'    => (bool)$isOnline,
        'last_seen_at' => date('Y-m-d H:i:s')
    ]);
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
