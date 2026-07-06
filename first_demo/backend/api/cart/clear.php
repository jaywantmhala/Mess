<?php
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST') { sendError('Method not allowed.', 405); }

$token = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;
if (!$payload || !isset($payload['sub'])) { sendError('Unauthorized.', 401); }
$customerId = (int) $payload['sub'];

try {
    $pdo  = getDBConnection();
    $stmt = $pdo->prepare("DELETE FROM cart_items WHERE customer_id = ?");
    $stmt->execute([$customerId]);

    sendSuccess('Cart cleared successfully.', []);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
