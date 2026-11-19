<?php
/**
 * Admin API: Vendor Payout Schedule Settings
 * GET /api/admin/payouts/settings
 * POST /api/admin/payouts/settings
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

    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        $settings = RazorpayXPayoutService::getSettings($pdo);
        echo json_encode([
            'success'  => true,
            'settings' => $settings
        ]);
        exit;
    }

    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $raw = file_get_contents('php://input');
        $body = json_decode($raw, true) ?: $_POST;

        $updated = RazorpayXPayoutService::saveSettings($pdo, $body);
        echo json_encode([
            'success'  => true,
            'message'  => 'Payout schedule settings saved successfully.',
            'settings' => $updated
        ]);
        exit;
    }

    sendError('Method not allowed.', 405);

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
