<?php
/**
 * Admin API: Reconcile Payout with Razorpay
 * POST /api/admin/payouts/reconcile
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

    $raw = file_get_contents('php://input');
    $body = json_decode($raw, true) ?: $_POST;
    $id = isset($body['id']) ? (int)$body['id'] : 0;

    if ($id <= 0) {
        sendError('Invalid payout record ID.', 400);
    }

    $pdo = getDBConnection();
    $res = RazorpayXPayoutService::reconcilePayoutRecord($pdo, $id);

    echo json_encode($res);

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
