<?php
/**
 * Razorpay Banking Balances API for Admin Panel
 * Endpoint: GET /api/admin/payouts/banking-balances
 *
 * Hits Razorpay API: GET https://api.razorpay.com/v1/banking_balances
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
    // 1. Authenticate Admin Token
    $token = JWT::getBearerToken();
    $payload = $token ? JWT::verify($token) : null;

    if (!$payload || !isset($payload['sub']) || ($payload['role'] ?? '') !== 'admin') {
        sendError('Unauthorized. Admin access required.', 401);
    }

    // 2. Query Parameters
    $accountNumber = isset($_GET['account_number']) ? trim($_GET['account_number']) : null;
    $forceRefresh = !empty($_GET['refresh']) && ($_GET['refresh'] === '1' || $_GET['refresh'] === 'true');

    // 3. Hit Razorpay API: GET /v1/banking_balances
    $res = getRazorpayBankingBalances($accountNumber, $forceRefresh);

    if (!$res['success']) {
        echo json_encode([
            'success'         => false,
            'message'         => $res['error'] ?? 'Failed to fetch Razorpay banking balances.',
            'items'           => [],
            'count'           => 0,
            'primary_balance' => null,
            'latency_ms'      => $res['latency_ms'] ?? 0,
        ]);
        exit;
    }

    $items = $res['items'];
    $formattedItems = [];

    foreach ($items as $item) {
        $availPaise = isset($item['available_amount']) ? (int)$item['available_amount'] : (int)($item['amount'] ?? 0);
        $availRupees = $availPaise / 100;
        $refreshedAt = isset($item['refreshed_at']) ? (int)$item['refreshed_at'] : null;

        $formattedItems[] = array_merge($item, [
            'available_amount_rupees'    => $availRupees,
            'available_amount_formatted' => '₹ ' . number_format($availRupees, 2),
            'refreshed_at_formatted'     => $refreshedAt ? date('d M Y, h:i A', $refreshedAt) : 'N/A',
        ]);
    }

    $primary = !empty($formattedItems) ? $formattedItems[0] : null;

    echo json_encode([
        'success'         => true,
        'count'           => count($formattedItems),
        'items'           => $formattedItems,
        'primary_balance' => $primary,
        'raw_payload'     => $res['data'] ?? null,
        'latency_ms'      => $res['latency_ms'] ?? 0,
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
