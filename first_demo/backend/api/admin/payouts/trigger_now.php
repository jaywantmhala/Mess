<?php
/**
 * Admin API: Start Payout Now
 * POST /api/admin/payouts/trigger-now
 */

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/cors.php';
require_once __DIR__ . '/../../../helpers/jwt.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/razorpayx_payout_service.php';

header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

try {
    // 1. Authenticate Admin Token
    $token = JWT::getBearerToken();
    $payload = $token ? JWT::verify($token) : null;
    if (!$payload || !isset($payload['sub']) || ($payload['role'] ?? '') !== 'admin') {
        sendError('Unauthorized. Admin access required.', 401);
    }

    $pdo = getDBConnection();
    $targetDate = $_GET['date'] ?? $_POST['date'] ?? date('Y-m-d');

    $result = RazorpayXPayoutService::executePayoutBatch($pdo, 'manual', $targetDate);

    echo json_encode([
        'success' => $result['success'] ?? false,
        'message' => $result['message'] ?? 'Payout batch execution completed.',
        'data'    => $result,
    ]);

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error executing payout batch: ' . $e->getMessage()
    ]);
}
