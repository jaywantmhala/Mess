<?php
/**
 * GET /api/vendor/hotels
 *
 * Retrieves all hotels owned by the authenticated vendor.
 * Header: Authorization: Bearer <token>
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

// ── JWT Authentication ────────────────────────────────────────────────────────
$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || !isset($payload['sub'])) {
    sendError('Unauthorized. Please log in again.', 401);
}

$vendorId = (int)$payload['sub'];

// ── Fetch Hotels ──────────────────────────────────────────────────────────────
$pdo  = getDBConnection();
$stmt = $pdo->prepare("SELECT * FROM hotels WHERE vendor_id = :vendor_id ORDER BY id DESC");
$stmt->execute([':vendor_id' => $vendorId]);
$hotels = $stmt->fetchAll();

sendSuccess('Hotels retrieved.', [
    'hotels' => $hotels,
]);
