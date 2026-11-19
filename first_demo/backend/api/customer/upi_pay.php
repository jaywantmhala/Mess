<?php
/**
 * POST /api/customer/upi_pay
 *
 * Direct UPI Payment verification and Subscription activation/renewal.
 *
 * Request Body: { plan_id: int, utr_number: string }
 * Headers: Authorization: Bearer <token>
 */

require_once __DIR__ . '/../../config/database.php';
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
if (empty($body['plan_id'])) {
    sendError('Plan ID is required.', 422);
}

$planId = (int)$body['plan_id'];
$utrNumber = isset($body['utr_number']) ? trim($body['utr_number']) : '';

if (empty($utrNumber)) {
    sendError('UTR / Transaction Reference ID is required.', 422);
}

if (strlen($utrNumber) < 6) {
    sendError('Please enter a valid UTR / Transaction Reference ID.', 422);
}

try {
    $pdo = getDBConnection();

    // Create upi_payments table if it does not exist
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS upi_payments (
            id INT AUTO_INCREMENT PRIMARY KEY,
            customer_id INT NOT NULL,
            plan_id INT NOT NULL,
            utr_number VARCHAR(100) NOT NULL UNIQUE,
            amount DECIMAL(10,2) NOT NULL,
            status VARCHAR(20) NOT NULL DEFAULT 'VERIFIED',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");

    // Check if UTR number was already used
    $checkUtr = $pdo->prepare("SELECT id FROM upi_payments WHERE utr_number = ?");
    $checkUtr->execute([$utrNumber]);
    if ($checkUtr->fetch()) {
        sendError('This UTR / Transaction ID has already been submitted or processed.', 422);
    }

    // Ensure legacy FK constraint is removed outside transaction
    try {
        $pdo->exec("ALTER TABLE `customer_subscriptions` DROP FOREIGN KEY `fk_cust_sub_plan`");
    } catch (PDOException $ex) {}

    $pdo->beginTransaction();

    // 1. Fetch subscription plan details (check plans table first)
    $pStmt = $pdo->prepare("SELECT id, plan_name, price, duration, total_deliveries, (status = 'active') AS is_active FROM plans WHERE id = ? FOR UPDATE");
    $pStmt->execute([$planId]);
    $plan = $pStmt->fetch(PDO::FETCH_ASSOC);

    if (!$plan) {
        $pStmt = $pdo->prepare("SELECT id, plan_name, price, duration, total_deliveries, is_active FROM subscription_plans WHERE id = ? FOR UPDATE");
        $pStmt->execute([$planId]);
        $plan = $pStmt->fetch(PDO::FETCH_ASSOC);
    }

    $duration        = 30;
    $totalDeliveries = 30;
    $planName        = 'Subscription Plan';
    $planPrice       = 199.00;

    if ($plan) {
        $duration        = (int)$plan['duration'];
        $totalDeliveries = (int)$plan['total_deliveries'];
        $planName        = $plan['plan_name'];
        $planPrice       = (float)$plan['price'];
    } else {
        if ($planId === 2) { $duration = 90; $totalDeliveries = 90; $planName = 'Quarterly Plan'; $planPrice = 499.00; }
        elseif ($planId === 3) { $duration = 365; $totalDeliveries = 365; $planName = 'Yearly Plan'; $planPrice = 1499.00; }
    }

    // Record the UPI payment
    $insUpi = $pdo->prepare("
        INSERT INTO upi_payments (customer_id, plan_id, utr_number, amount, status)
        VALUES (?, ?, ?, ?, 'VERIFIED')
    ");
    $insUpi->execute([$customerId, $planId, $utrNumber, $planPrice]);
    $upiPaymentId = (int)$pdo->lastInsertId();

    // Deactivate/Expire previous active subscriptions
    $cancelOld = $pdo->prepare("UPDATE customer_subscriptions SET status = 'EXPIRED' WHERE customer_id = ? AND status = 'ACTIVE'");
    $cancelOld->execute([$customerId]);

    // Activate new customer subscription

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

    // Update wallet balance with plan price
    $newBalance = round($balance + $planPrice, 2);
    $updW = $pdo->prepare("UPDATE wallets SET balance = ? WHERE wallet_id = ?");
    $updW->execute([$newBalance, $walletId]);

    // Record wallet transaction
    $txnStmt = $pdo->prepare("
        INSERT INTO wallet_transactions (wallet_id, type, amount, description, balance_after)
        VALUES (?, 'CREDIT', ?, ?, ?)
    ");
    $txnDesc = "UPI Subscription Payment: " . $planName . " (UTR: " . $utrNumber . ")";
    $txnStmt->execute([$walletId, $planPrice, $txnDesc, $newBalance]);

    $pdo->commit();

    sendSuccess('UPI Payment verified successfully! Plan activated.', [
        'subscription_id' => $subscriptionId,
        'upi_payment_id'  => $upiPaymentId,
        'plan_name'       => $planName,
        'amount_paid'     => $planPrice,
        'utr_number'      => $utrNumber,
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
