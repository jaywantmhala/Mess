<?php
/**
 * POST /api/payu/payout/webhook
 *
 * Webhook endpoint for receiving PayU Payout status notifications.
 * Processes SUCCESS and FAILED status updates idempotently.
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/payu_payout_helper.php';

header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

$rawInput = file_get_contents('php://input');
$data     = json_decode($rawInput, true);

if (!$data) {
    $data = $_POST;
}

if (empty($data)) {
    sendError('Empty webhook payload received.', 400);
}

$merchantRefId = $data['merchantRefId'] ?? $data['merchant_ref_id'] ?? null;
$status        = strtoupper($data['status'] ?? $data['txnStatus'] ?? '');
$payuTxnId     = $data['payuTxnId'] ?? $data['transactionId'] ?? null;
$failureReason = $data['failureReason'] ?? $data['msg'] ?? 'PayU transfer failed';

if (!$merchantRefId) {
    sendError('Missing merchantRefId in payload.', 422);
}

$pdo = getDBConnection();

try {
    $stmt = $pdo->prepare("SELECT id, vendor_id, amount, status FROM vendor_payouts WHERE merchant_ref_id = :ref LIMIT 1");
    $stmt->execute([':ref' => $merchantRefId]);
    $payout = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$payout) {
        sendError('Payout reference not found.', 404);
    }

    $payoutId = (int)$payout['id'];

    if ($status === 'SUCCESS') {
        PayUPayoutHelper::markPayoutSuccess($pdo, $payoutId, $merchantRefId, $payuTxnId, (float)$payout['amount']);
        sendSuccess('Webhook processed: Payout marked SUCCESS.');
    } else if ($status === 'FAILED' || $status === 'REVERSED') {
        if ($payout['status'] !== 'SUCCESS') {
            $upd = $pdo->prepare("UPDATE vendor_payouts SET status = 'FAILED', failure_reason = ?, updated_at = NOW() WHERE id = ?");
            $upd->execute([$failureReason, $payoutId]);
        }
        sendSuccess('Webhook processed: Payout marked FAILED.');
    } else {
        sendSuccess('Webhook received: Payout status unchanged (' . $status . ').');
    }
} catch (Throwable $e) {
    sendError('Webhook processing error: ' . $e->getMessage(), 500);
}
