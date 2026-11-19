<?php
/**
 * Admin API: Vendor Payout Dashboard Overview
 * GET /api/admin/payouts/dashboard
 */

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../config/razorpay.php';
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

    // 2. Schedule settings
    $settings = RazorpayXPayoutService::getSettings($pdo);

    // 3. Summary statistics from real DB records
    $cycle = $_GET['cycle'] ?? date('Y-m-d');
    $summary = RazorpayXPayoutService::getSummaryMetrics($pdo, $cycle);

    // 4. Live Razorpay Banking Balance
    $balanceRes = getRazorpayBankingBalances();
    $bankingBalance = null;
    if ($balanceRes['success'] && !empty($balanceRes['primary_balance'])) {
        $primary = $balanceRes['primary_balance'];
        $availPaise = (int)($primary['available_amount'] ?? $primary['amount'] ?? 0);
        $availRupees = $availPaise / 100;
        $refreshedAt = (int)($primary['refreshed_at'] ?? time());

        $bankingBalance = [
            'account_number'             => $primary['account_number'] ?? 'N/A',
            'account_type'               => $primary['account_type'] ?? 'razorpayx_lite',
            'currency'                   => $primary['currency'] ?? 'INR',
            'available_amount_paise'     => $availPaise,
            'available_amount_rupees'    => $availRupees,
            'available_amount_formatted' => '₹ ' . number_format($availRupees, 2),
            'refreshed_at'               => $refreshedAt,
            'refreshed_at_formatted'     => date('d M Y, h:i A', $refreshedAt),
            'latency_ms'                 => $balanceRes['latency_ms'] ?? 0,
        ];
    }

    echo json_encode([
        'success'         => true,
        'settings'        => $settings,
        'summary'         => $summary,
        'banking_balance' => $bankingBalance,
    ]);

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
