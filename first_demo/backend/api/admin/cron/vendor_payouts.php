<?php
/**
 * POST /api/admin/cron/vendor-payouts
 *
 * Daily Cron Endpoint to process vendor payouts every night at 12 o'clock.
 * Transfers ONLY TODAY'S EARNINGS (not overall accumulated balance) for each eligible vendor.
 */

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/vendor_wallet_helper.php';
require_once __DIR__ . '/../../../helpers/payu_payout_helper.php';

header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

$pdo = getDBConnection();

try {
    // Target date for today's earnings (defaults to current date YYYY-MM-DD or custom parameter)
    $targetDate = $_GET['date'] ?? $_POST['date'] ?? date('Y-m-d');

    // Fetch all vendors with payout_enabled = 1 and valid PayU beneficiary ID
    $stmt = $pdo->prepare("
        SELECT id, full_name, email, phone, bank_name, account_holder_name, account_number, ifsc_code, payu_beneficiary_id 
        FROM vendors 
        WHERE payout_enabled = 1 AND payu_beneficiary_id IS NOT NULL AND payu_beneficiary_id != ''
    ");
    $stmt->execute();
    $vendors = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $processed = [];
    $skipped   = [];

    foreach ($vendors as $vendor) {
        $vendorId = (int)$vendor['id'];

        // 1. Calculate ONLY TODAY'S EARNINGS for this vendor
        $earnStmt = $pdo->prepare("
            SELECT COALESCE(SUM(amount), 0) as today_earnings 
            FROM vendor_wallet_transactions 
            WHERE vendor_id = :vendor_id 
              AND type = 'CREDIT' 
              AND DATE(created_at) = :target_date
        ");
        $earnStmt->execute([
            ':vendor_id'   => $vendorId,
            ':target_date' => $targetDate,
        ]);
        $todayEarnings = (float)$earnStmt->fetchColumn();

        // 2. Fetch available wallet balance
        $walletData   = VendorWalletHelper::getBalance($vendorId);
        $totalBalance = (float)($walletData['balance'] ?? 0);

        // Payout amount is strictly TODAY'S EARNINGS (capped at current available balance)
        $payoutAmount = round(min($todayEarnings, $totalBalance), 2);

        if ($payoutAmount <= 0) {
            $skipped[] = [
                'vendor_id'      => $vendorId,
                'today_earnings' => $todayEarnings,
                'total_balance'  => $totalBalance,
                'reason'         => 'No earnings recorded for today or zero available balance.'
            ];
            continue;
        }

        // 3. Initiate payout for TODAY'S EARNINGS ONLY
        $res = PayUPayoutHelper::initiatePayout($pdo, $vendorId, $payoutAmount);
        $processed[] = [
            'vendor_id'       => $vendorId,
            'today_earnings'  => $todayEarnings,
            'payout_amount'   => $payoutAmount,
            'success'         => $res['success'],
            'merchant_ref_id' => $res['merchant_ref_id'] ?? null,
            'message'         => $res['message'] ?? '',
        ];
    }

    sendSuccess("Daily vendor payouts processed for date: {$targetDate} (Today's Earnings Only).", [
        'target_date'            => $targetDate,
        'total_eligible_vendors' => count($vendors),
        'processed_payouts'      => $processed,
        'skipped_vendors'        => $skipped,
    ]);
} catch (Throwable $e) {
    sendError('Cron execution failed: ' . $e->getMessage(), 500);
}
