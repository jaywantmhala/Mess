<?php
/**
 * GET /api/vendor/wallet/balance
 * Returns current vendor wallet balance.
 * Requires: Authorization: Bearer <JWT> (Vendor role required)
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'GET') { sendError('Method not allowed.', 405); }

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/jwt.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/vendor_wallet_helper.php';

$token = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || ($payload['role'] ?? '') !== 'vendor') {
    sendError('Unauthorized. Vendor token required.', 401);
}

$vendorId = (int)$payload['sub'];

try {
    $data = VendorWalletHelper::getBalance($vendorId);
    sendSuccess('Vendor wallet balance fetched successfully.', $data);
} catch (Throwable $e) {
    sendError('Database or system error: ' . $e->getMessage(), 500);
}
