<?php
/**
 * GET /api/vendor/payouts
 *
 * Returns payout settlement history for the authenticated vendor.
 * Header: Authorization: Bearer <token>
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'GET')     { sendError('Method not allowed. Use GET.', 405); }

// JWT Auth
$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || !isset($payload['sub']) || ($payload['role'] ?? '') !== 'vendor') {
    sendError('Unauthorized. Vendor token required.', 401);
}

$vendorId = (int)$payload['sub'];
$pdo = getDBConnection();

require_once __DIR__ . '/../../helpers/payu_payout_helper.php';

try {
    // Check any pending/processing payouts for this vendor and refresh status live from PayU (PayU payouts only)
    $pendingStmt = $pdo->prepare("SELECT id FROM vendor_payouts WHERE vendor_id = :id AND status IN ('PROCESSING', 'PENDING') AND (payment_method IS NULL OR payment_method = 'payu')");
    $pendingStmt->execute([':id' => $vendorId]);
    $pendingRows = $pendingStmt->fetchAll(PDO::FETCH_ASSOC);

    foreach ($pendingRows as $pr) {
        PayUPayoutHelper::checkAndUpdatePayoutStatus($pdo, (int)$pr['id']);
    }

    // Get vendor's last 4 digits
    $vStmt = $pdo->prepare("SELECT account_number FROM vendors WHERE id = :id LIMIT 1");
    $vStmt->execute([':id' => $vendorId]);
    $rawAccount = $vStmt->fetchColumn() ?: '';
    $accountLast4 = (strlen($rawAccount) >= 4) ? substr($rawAccount, -4) : $rawAccount;

    $stmt = $pdo->prepare("
        SELECT id, amount, merchant_ref_id, payu_txn_id, payment_type, status, failure_reason, initiated_at, completed_at, created_at
        FROM vendor_payouts
        WHERE vendor_id = :vendor_id
        ORDER BY id DESC
        LIMIT 50
    ");
    $stmt->execute([':vendor_id' => $vendorId]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $payouts = array_map(function($r) use ($accountLast4) {
        return [
            'payout_id'          => (int)$r['id'],
            'amount'             => (float)$r['amount'],
            'status'             => $r['status'],
            'payment_type'       => $r['payment_type'],
            'initiated_at'       => $r['initiated_at'] ?: $r['created_at'],
            'completed_at'       => $r['completed_at'],
            'bank_account_last4' => $accountLast4,
            'payu_reference'     => $r['merchant_ref_id'],
            'failure_reason'     => $r['failure_reason'],
        ];
    }, $rows);

    sendSuccess('Vendor payouts fetched successfully.', $payouts);
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
