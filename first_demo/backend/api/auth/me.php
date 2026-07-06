<?php
/**
 * GET /api/auth/me
 * Returns authenticated customer profile.
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

// ── JWT Auth ──────────────────────────────────────────────────────────────────
$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;
if (!$payload || !isset($payload['sub'])) {
    sendError('Unauthorized. Please log in again.', 401);
}

// ── Fetch Profile ─────────────────────────────────────────────────────────────
$pdo  = getDBConnection();
$stmt = $pdo->prepare("
    SELECT id, full_name, email, is_active, email_verified, last_login_at, created_at, updated_at
    FROM customers WHERE id = :id AND is_active = 1 LIMIT 1
");
$stmt->execute([':id' => (int) $payload['sub']]);
$customer = $stmt->fetch();

if (!$customer) { sendError('Customer not found or account deactivated.', 404); }

sendSuccess('Profile fetched.', ['customer' => $customer]);
