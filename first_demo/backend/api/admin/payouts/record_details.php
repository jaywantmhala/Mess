<?php
/**
 * Admin API: Individual Payout Details & Earning Ledger Breakdown
 * GET /api/admin/payouts/record-details?id=...
 */

require_once __DIR__ . '/../../../config/database.php';
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

    $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
    if ($id <= 0) {
        sendError('Invalid payout record ID.', 400);
    }

    $pdo = getDBConnection();

    // 2. Fetch payout record
    $stmt = $pdo->prepare("
        SELECT 
            rp.*,
            v.full_name AS vendor_name,
            v.account_holder_name AS business_name,
            v.phone AS vendor_phone,
            v.email AS vendor_email,
            v.bank_name,
            v.account_number,
            v.ifsc_code,
            v.razorpay_contact_id,
            v.razorpay_fund_account_id AS vendor_saved_fund_account_id
        FROM `razorpay_vendor_payouts` rp
        JOIN `vendors` v ON rp.vendor_id = v.id
        WHERE rp.id = :id
        LIMIT 1
    ");
    $stmt->execute([':id' => $id]);
    $payout = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$payout) {
        sendError('Payout record not found.', 404);
    }

    // 3. Fetch related eligible orders and earning allocations for this vendor and cycle date
    $cycle = $payout['payout_cycle'];
    $vendorId = (int)$payout['vendor_id'];

    $earnStmt = $pdo->prepare("
        SELECT 
            vwt.id,
            vwt.order_id,
            vwt.type,
            vwt.amount,
            vwt.balance_after,
            vwt.description,
            vwt.created_at,
            o.subtotal,
            o.delivery_fee,
            o.tax_amount,
            o.grand_total,
            o.status AS order_status,
            o.delivered_at
        FROM `vendor_wallet_transactions` vwt
        LEFT JOIN `orders` o ON vwt.order_id = o.order_id
        WHERE vwt.vendor_id = :vid
          AND vwt.type = 'CREDIT'
          AND DATE(vwt.created_at) = :cycle
        ORDER BY vwt.id DESC
    ");
    $earnStmt->execute([':vid' => $vendorId, ':cycle' => $cycle]);
    $earnings = $earnStmt->fetchAll(PDO::FETCH_ASSOC);

    // 4. Parse JSON fields safely
    $payout['status_history_parsed'] = json_decode($payout['status_history'] ?: '[]', true) ?: [];
    $payout['raw_request_parsed']    = json_decode($payout['raw_request'] ?: '{}', true) ?: [];
    $payout['raw_response_parsed']   = json_decode($payout['raw_response'] ?: '{}', true) ?: [];

    // Mask sensitive bank account number in response
    if (!empty($payout['account_number'])) {
        $payout['account_number_masked'] = 'XXXX' . substr($payout['account_number'], -4);
    }

    echo json_encode([
        'success'             => true,
        'payout'              => $payout,
        'earning_allocations' => $earnings,
        'earnings_count'      => count($earnings),
    ]);

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
