<?php
/**
 * POST /api/admin/payouts/sync-vendors
 *
 * Automatically applies Razorpay Contacts and Fund Accounts
 * for all existing vendors in the database.
 */

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../config/razorpay.php';
require_once __DIR__ . '/../../../helpers/cors.php';
require_once __DIR__ . '/../../../helpers/jwt.php';
require_once __DIR__ . '/../../../helpers/response.php';

header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

try {
    $token = JWT::getBearerToken();
    $payload = $token ? JWT::verify($token) : null;

    if (!$payload || !isset($payload['sub']) || ($payload['role'] ?? '') !== 'admin') {
        sendError('Unauthorized. Admin access required.', 401);
    }

    @set_time_limit(300);
    $pdo = getDBConnection();
    $result = syncAllExistingVendorsRazorpay($pdo);

    echo json_encode([
        'success'       => true,
        'message'       => "Successfully synchronized {$result['synced_count']} existing vendor(s) with Razorpay Contacts and Fund Accounts.",
        'total_vendors' => $result['total_vendors'],
        'synced_count'  => $result['synced_count'],
        'details'       => $result['details'],
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Sync failed: ' . $e->getMessage()
    ]);
}
