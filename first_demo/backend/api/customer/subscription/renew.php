<?php
/**
 * POST /api/customer/subscription/renew
 *
 * Renew subscription, either extending current or creating a new record.
 * Body: { plan_id } (optional, defaults to current plan)
 */

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/jwt.php';
require_once __DIR__ . '/../../../helpers/fcm.php';

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

$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || !isset($payload['sub'])) {
    sendError('Unauthorized. Please log in.', 401);
}

$customerId = (int)$payload['sub'];

// Parse request body
$body = json_decode(file_get_contents('php://input'), true);
$reqPlanId = isset($body['plan_id']) ? (int)$body['plan_id'] : null;

try {
    $pdo = getDBConnection();
    $pdo->beginTransaction();

    // 1. Fetch current subscription
    $stmt = $pdo->prepare("
        SELECT id, plan_id, status, end_date, remaining_deliveries, total_deliveries, completed_deliveries
        FROM customer_subscriptions 
        WHERE customer_id = ? 
        ORDER BY id DESC 
        LIMIT 1 
        FOR UPDATE
    ");
    $stmt->execute([$customerId]);
    $currentSub = $stmt->fetch(PDO::FETCH_ASSOC);

    // Resolve plan to subscribe/renew
    $targetPlanId = $reqPlanId ?: ($currentSub ? (int)$currentSub['plan_id'] : null);
    if (!$targetPlanId) {
        throw new Exception("Plan ID is required for subscription.", 422);
    }

    // 2. Fetch the plan details
    $planStmt = $pdo->prepare("SELECT plan_name, price, duration, total_deliveries, is_active FROM subscription_plans WHERE id = ? FOR UPDATE");
    $planStmt->execute([$targetPlanId]);
    $plan = $planStmt->fetch(PDO::FETCH_ASSOC);

    if (!$plan) {
        throw new Exception("Plan not found.", 404);
    }
    if (!$plan['is_active']) {
        throw new Exception("Plan is deactivated.", 422);
    }

    $planPrice = (float)$plan['price'];
    $duration = (int)$plan['duration'];
    $planTotalDeliveries = (int)$plan['total_deliveries'];

    // 3. Recharge wallet first (Plan amount is stored in user's wallet)
    $wStmt = $pdo->prepare("SELECT wallet_id, balance FROM wallets WHERE customer_id = ? FOR UPDATE");
    $wStmt->execute([$customerId]);
    $wallet = $wStmt->fetch(PDO::FETCH_ASSOC);

    if (!$wallet) {
        $insWallet = $pdo->prepare("INSERT INTO wallets (customer_id, balance) VALUES (?, 0.00)");
        $insWallet->execute([$customerId]);
        $walletId = (int)$pdo->lastInsertId();
        $balance = 0.00;
    } else {
        $walletId = (int)$wallet['wallet_id'];
        $balance = (float)$wallet['balance'];
    }

    // Keep the balance stored (no deduction)
    $newBalance = round($balance + $planPrice, 2);
    $updWallet = $pdo->prepare("UPDATE wallets SET balance = ?, plan_credit_balance = plan_credit_balance + ? WHERE wallet_id = ?");
    $updWallet->execute([$newBalance, $planPrice, $walletId]);

    // Insert CREDIT transaction record
    $txnStmt = $pdo->prepare("
        INSERT INTO wallet_transactions (wallet_id, type, amount, description, balance_after)
        VALUES (?, 'CREDIT', ?, ?, ?)
    ");
    $txnDescription = "Subscription Renewed (Amount Stored): " . $plan['plan_name'];
    $txnStmt->execute([$walletId, $planPrice, $txnDescription, $newBalance]);
    $transactionId = (int)$pdo->lastInsertId();

    $subscriptionId = 0;
    $isExtension = false;
    $newEndDateStr = '';

    // 4. Expiry/Renewal business rules:
    // If the customer has a current subscription that is ACTIVE or PAUSED:
    if ($currentSub && in_array($currentSub['status'], ['ACTIVE', 'PAUSED'])) {
        $isExtension = true;
        $subscriptionId = (int)$currentSub['id'];

        // Extend the end_date by duration days
        $endDate = new DateTime($currentSub['end_date']);
        $endDate->modify("+$duration days");
        $newEndDateStr = $endDate->format('Y-m-d');

        // Update active subscription details
        $updSub = $pdo->prepare("
            UPDATE customer_subscriptions 
            SET status = 'ACTIVE', 
                remaining_deliveries = remaining_deliveries + ?, 
                total_deliveries = total_deliveries + ?, 
                end_date = ?, 
                renewal_status = 'RENEWED',
                updated_at = NOW() 
            WHERE id = ?
        ");
        $updSub->execute([$planTotalDeliveries, $planTotalDeliveries, $newEndDateStr, $subscriptionId]);

        // Calculate start date for new calendar (the day after old end date)
        $oldEndDate = new DateTime($currentSub['end_date']);
        $oldEndDate->modify('+1 day');
        $calendarStartDate = $oldEndDate->format('Y-m-d');

        // Generate and append new scheduled deliveries
        generateDeliveries($pdo, $subscriptionId, $customerId, $calendarStartDate, $planTotalDeliveries);

    } else {
        // Create a NEW subscription record
        $startDateStr = date('Y-m-d');
        $endDate = new DateTime($startDateStr);
        $endDate->modify("+$duration days");
        $newEndDateStr = $endDate->format('Y-m-d');

        $insSub = $pdo->prepare("
            INSERT INTO customer_subscriptions (customer_id, plan_id, status, remaining_deliveries, total_deliveries, completed_deliveries, start_date, end_date, renewal_status)
            VALUES (?, ?, 'ACTIVE', ?, ?, 0, ?, ?, 'NONE')
        ");
        $insSub->execute([$customerId, $targetPlanId, $planTotalDeliveries, $planTotalDeliveries, $startDateStr, $newEndDateStr]);
        $subscriptionId = (int)$pdo->lastInsertId();

        // Generate scheduled deliveries calendar
        generateDeliveries($pdo, $subscriptionId, $customerId, $startDateStr, $planTotalDeliveries);
    }

    $pdo->commit();

    // Send FCM notification
    FcmHelper::sendToCustomer($customerId, "🎉 Subscription Renewed!", "Your subscription to " . $plan['plan_name'] . " is now active until $newEndDateStr.");

    sendSuccess('Subscription renewed successfully.', [
        'subscription_id' => $subscriptionId,
        'is_extension' => $isExtension,
        'new_end_date' => $newEndDateStr,
        'wallet_balance' => number_format($newBalance, 2, '.', ''),
        'transaction_id' => $transactionId
    ]);

} catch (Exception $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    $code = $e->getCode();
    $status = ($code >= 400 && $code <= 500) ? $code : 500;
    sendError($e->getMessage(), $status);
}

/**
 * Generate PENDING deliveries for the given subscription calendar period.
 */
function generateDeliveries($pdo, $subscriptionId, $customerId, $startDateStr, $totalDeliveries) {
    $startDate = new DateTime($startDateStr);
    $insStmt = $pdo->prepare("
        INSERT INTO subscription_deliveries (subscription_id, customer_id, delivery_date, status)
        VALUES (?, ?, ?, 'PENDING')
    ");
    for ($i = 0; $i < $totalDeliveries; $i++) {
        $dateStr = $startDate->format('Y-m-d');
        $insStmt->execute([$subscriptionId, $customerId, $dateStr]);
        $startDate->modify('+1 day');
    }
}
