<?php
/**
 * POST /api/vendor/delete_hotel
 *
 * Deletes an existing hotel.
 * Body: { id }
 * Header: Authorization: Bearer <token>
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/validation.php';
require_once __DIR__ . '/../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST')    { sendError('Method not allowed. Use POST.', 405); }

// ── JWT Authentication ────────────────────────────────────────────────────────
$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || !isset($payload['sub'])) {
    sendError('Unauthorized. Please log in again.', 401);
}

$vendorId = (int)$payload['sub'];

// ── Validate Input ────────────────────────────────────────────────────────────
$body = requireJsonBody([
    'id'
]);

$hotelId = (int)$body['id'];

// ── Database ──────────────────────────────────────────────────────────────────
$pdo = getDBConnection();

// Verify hotel exists and belongs to this vendor
$stmt = $pdo->prepare("SELECT id FROM hotels WHERE id = :id AND vendor_id = :vendor_id LIMIT 1");
$stmt->execute([
    ':id'        => $hotelId,
    ':vendor_id' => $vendorId,
]);
if (!$stmt->fetch()) {
    sendError('Hotel listing not found or permission denied.', 404);
}

// Delete hotel
$stmt = $pdo->prepare("DELETE FROM hotels WHERE id = :id AND vendor_id = :vendor_id");
$stmt->execute([
    ':id'        => $hotelId,
    ':vendor_id' => $vendorId,
]);

sendSuccess('Hotel deleted successfully.');
