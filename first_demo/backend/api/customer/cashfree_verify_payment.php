<?php
/**
 * POST /api/customer/cashfree/verify_payment
 *
 * Verifies payment with Cashfree API and activates customer subscription.
 *
 * Request Body: { order_id: string, plan_id: int }
 * Headers: Authorization: Bearer <token>
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/cashfree.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendError('Method not allowed. Use POST.', 405);
}

// ── JWT Authentication ────────────────────────────────────────────────────────
$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || !isset($payload['sub'])) {
    sendError('Unauthorized. Please log in.', 401);
}

$customerId = (int)$payload['sub'];

// ── Parse request body ────────────────────────────────────────────────────────
$body = json_decode(file_get_contents('php://input'), true);
if (empty($body['order_id'])) {
    sendError('Order ID is required.', 422);
}

$orderId = trim($body['order_id']);
$planId  = isset($body['plan_id']) ? (int)$body['plan_id'] : 0;

try {
    $pdo = getDBConnection();

    // 1. Fetch cashfree payment record
    $stmt = $pdo->prepare("SELECT * FROM cashfree_payments WHERE order_id = ? AND customer_id = ?");
    $stmt->execute([$orderId, $customerId]);
    $cfPayment = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$cfPayment) {
        throw new Exception("Payment record not found.", 404);
    }

    if ($planId <= 0) {
        $planId = (int)$cfPayment['plan_id'];
    }

    // If already verified PAID, return success
    if ($cfPayment['order_status'] === 'PAID') {
        sendSuccess('Payment already verified and active.', [
            'order_id'     => $orderId,
            'order_status' => 'PAID',
        ]);
    }

    // 2. Query Cashfree API for Order Status
    $cfResp = callCashfreeAPI("/orders/{$orderId}", 'GET');

    if ($cfResp['status_code'] !== 200) {
        $msg = $cfResp['body']['message'] ?? 'Failed to query Cashfree order status.';
        throw new Exception("Cashfree Error ($cfResp[status_code]): $msg", 400);
    }

    $cfBody      = $cfResp['body'];
    $orderStatus = strtoupper($cfBody['order_status'] ?? '');

    // In Cashfree, status 'PAID' or 'COMPLETED' indicates successful payment
    $isPaid = ($orderStatus === 'PAID' || $orderStatus === 'COMPLETED');

    if (!$isPaid) {
        // Update local status
        $upd = $pdo->prepare("UPDATE cashfree_payments SET order_status = ? WHERE order_id = ?");
        $upd->execute([$orderStatus, $orderId]);

        throw new Exception("Payment is not completed. Cashfree status: " . ($orderStatus ?: 'PENDING'), 400);
    }

    // Ensure legacy FK constraint is removed outside transaction
    try {
        $pdo->exec("ALTER TABLE `customer_subscriptions` DROP FOREIGN KEY `fk_cust_sub_plan`");
    } catch (PDOException $ex) {}

    // 3. Begin atomic subscription activation
    $pdo->beginTransaction();

    // Fetch subscription plan details (check plans table first)
    $pStmt = $pdo->prepare("SELECT id, plan_name, price, duration, total_deliveries FROM plans WHERE id = ?");
    $pStmt->execute([$planId]);
    $plan = $pStmt->fetch(PDO::FETCH_ASSOC);

    if (!$plan) {
        $pStmt = $pdo->prepare("SELECT id, plan_name, price, duration, total_deliveries FROM subscription_plans WHERE id = ?");
        $pStmt->execute([$planId]);
        $plan = $pStmt->fetch(PDO::FETCH_ASSOC);
    }

    $duration        = 30;
    $totalDeliveries = 30;
    $planName        = 'Subscription Plan';
    $planPrice       = (float)$cfPayment['amount'];

    if ($plan) {
        $duration        = (int)$plan['duration'];
        $totalDeliveries = (int)$plan['total_deliveries'];
        $planName        = $plan['plan_name'];
        $planPrice       = (float)$plan['price'];
    } else {
        if ($planId === 2) { $duration = 90; $totalDeliveries = 90; $planName = 'Quarterly Plan'; }
        elseif ($planId === 3) { $duration = 365; $totalDeliveries = 365; $planName = 'Yearly Plan'; }
    }

    // Mark existing active subscriptions as EXPIRED / CANCELLED if any
    $cancelOld = $pdo->prepare("UPDATE customer_subscriptions SET status = 'EXPIRED' WHERE customer_id = ? AND status = 'ACTIVE'");
    $cancelOld->execute([$customerId]);

    // Insert new customer subscription
    $insSub = $pdo->prepare("
        INSERT INTO customer_subscriptions (customer_id, plan_id, status, remaining_deliveries, start_date, end_date)
        VALUES (?, ?, 'ACTIVE', ?, CURDATE(), DATE_ADD(CURDATE(), INTERVAL ? DAY))
    ");
    $insSub->execute([$customerId, $planId, $totalDeliveries, $duration]);
    $subscriptionId = (int)$pdo->lastInsertId();

    // Get wallet_id for transaction logging & balance update
    $wStmt = $pdo->prepare("SELECT wallet_id, balance FROM wallets WHERE customer_id = ? FOR UPDATE");
    $wStmt->execute([$customerId]);
    $wallet = $wStmt->fetch(PDO::FETCH_ASSOC);

    if (!$wallet) {
        $insW = $pdo->prepare("INSERT INTO wallets (customer_id, balance) VALUES (?, 0.00)");
        $insW->execute([$customerId]);
        $walletId = (int)$pdo->lastInsertId();
        $balance = 0.00;
    } else {
        $walletId = (int)$wallet['wallet_id'];
        $balance = (float)$wallet['balance'];
    }

    // Credit plan amount to customer's wallet balance
    $newBalance = round($balance + $planPrice, 2);

    // Update wallet balance in database
    $updW = $pdo->prepare("UPDATE wallets SET balance = ? WHERE wallet_id = ?");
    $updW->execute([$newBalance, $walletId]);

    // Record wallet transaction for Cashfree payment audit
    $txnStmt = $pdo->prepare("
        INSERT INTO wallet_transactions (wallet_id, type, amount, description, balance_after)
        VALUES (?, 'CREDIT', ?, ?, ?)
    ");
    $txnDesc = "Cashfree Subscription Payment: " . $planName . " (Order: " . $orderId . ")";
    $txnStmt->execute([$walletId, $planPrice, $txnDesc, $newBalance]);

    // Update cashfree_payments table
    $cfPaymentId = $cfBody['cf_order_id'] ?? ($cfBody['payments'][0]['cf_payment_id'] ?? null);
    $updCf = $pdo->prepare("UPDATE cashfree_payments SET order_status = 'PAID', cf_payment_id = ? WHERE order_id = ?");
    $updCf->execute([$cfPaymentId, $orderId]);

    $pdo->commit();

    sendSuccess('Subscription payment verified and plan activated successfully!', [
        'subscription_id' => $subscriptionId,
        'order_id'        => $orderId,
        'plan_name'       => $planName,
        'amount_paid'     => $planPrice,
        'status'          => 'ACTIVE',
        'end_date'        => date('Y-m-d', strtotime("+$duration days")),
    ]);

} catch (Exception $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    $code = $e->getCode();
    $status = ($code >= 400 && $code <= 500) ? $code : 500;
    sendError($e->getMessage(), $status);
}
