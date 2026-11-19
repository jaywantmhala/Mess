<?php
/**
 * POST /api/customer/subscribe
 *
 * Purchase a subscription plan. Deducts the plan price from the customer's wallet balance,
 * creates a transaction record, and registers the subscription active state.
 *
 * Request Body: { plan_id }
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
if (!isset($body['plan_id'])) {
    sendError('Plan ID is required.', 422);
}

$planId = (int)$body['plan_id'];

try {
    $pdo = getDBConnection();
    try {
        $pdo->exec("ALTER TABLE `customer_subscriptions` DROP FOREIGN KEY `fk_cust_sub_plan`");
    } catch (PDOException $ex) {}
    $pdo->beginTransaction();

    // 1. Fetch the subscription plan — try new plans table first, fallback to subscription_plans
    $plan        = null;
    $usingNewPlan = false;

    // Try new plans table
    $newPlanStmt = $pdo->prepare("
        SELECT p.id, p.plan_name, p.price, p.duration, p.total_deliveries, p.status,
               sl.radius_km
        FROM plans p
        JOIN service_locations sl ON p.service_location_id = sl.id
        WHERE p.id = ? FOR UPDATE
    ");
    $newPlanStmt->execute([$planId]);
    $newPlan = $newPlanStmt->fetch(PDO::FETCH_ASSOC);

    if ($newPlan) {
        if ($newPlan['status'] !== 'active') {
            throw new Exception("Selected subscription plan is deactivated.", 422);
        }
        $plan = [
            'plan_name'        => $newPlan['plan_name'],
            'price'            => $newPlan['price'],
            'duration'         => $newPlan['duration'],
            'total_deliveries' => $newPlan['total_deliveries'],
        ];
        $usingNewPlan = true;
    } else {
        // Fallback: legacy subscription_plans table
        $stmt = $pdo->prepare("SELECT id, plan_name, price, duration, total_deliveries, is_active FROM subscription_plans WHERE id = ? FOR UPDATE");
        $stmt->execute([$planId]);
        $legacyPlan = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$legacyPlan) {
            throw new Exception("Subscription plan not found.", 404);
        }
        if (!$legacyPlan['is_active']) {
            throw new Exception("Selected subscription plan is deactivated.", 422);
        }
        $plan = [
            'plan_name'        => $legacyPlan['plan_name'],
            'price'            => $legacyPlan['price'],
            'duration'         => $legacyPlan['duration'],
            'total_deliveries' => $legacyPlan['total_deliveries'],
        ];
    }

    $planName        = $plan['plan_name'];
    $planPrice       = (float)$plan['price'];
    $planDuration    = (int)$plan['duration'];
    $totalDeliveries = (int)$plan['total_deliveries'];

    // 2. Check if customer already has an active subscription
    $subQuery = $pdo->prepare("
        SELECT id FROM customer_subscriptions 
        WHERE customer_id = ? AND status = 'ACTIVE' AND end_date >= CURDATE() AND remaining_deliveries > 0 
        LIMIT 1
    ");
    $subQuery->execute([$customerId]);
    if ($subQuery->fetch()) {
        throw new Exception("You already have an active subscription plan.", 422);
    }

    // 3. Get customer's wallet balance (row lock for safe concurrency)
    $wStmt = $pdo->prepare("SELECT wallet_id, balance FROM wallets WHERE customer_id = ? FOR UPDATE");
    $wStmt->execute([$customerId]);
    $wallet = $wStmt->fetch(PDO::FETCH_ASSOC);

    if (!$wallet) {
        // Create wallet if it doesn't exist
        $insWallet = $pdo->prepare("INSERT INTO wallets (customer_id, balance) VALUES (?, 0.00)");
        $insWallet->execute([$customerId]);
        $walletId = (int)$pdo->lastInsertId();
        $balance = 0.00;
    } else {
        $walletId = (int)$wallet['wallet_id'];
        $balance = (float)$wallet['balance'];
    }

    // Credit subscription plan price to customer's wallet balance
    $newBalance = round($balance + $planPrice, 2);

    // Update wallet balance in database
    $updWallet = $pdo->prepare("UPDATE wallets SET balance = ?, plan_credit_balance = plan_credit_balance + ? WHERE wallet_id = ?");
    $updWallet->execute([$newBalance, $planPrice, $walletId]);

    // Insert transaction record showing amount credited to wallet
    $txnStmt = $pdo->prepare("
        INSERT INTO wallet_transactions (wallet_id, type, amount, description, balance_after)
        VALUES (?, 'CREDIT', ?, ?, ?)
    ");
    $txnDescription = "Subscription Plan Purchase: " . $planName;
    $txnStmt->execute([$walletId, $planPrice, $txnDescription, $newBalance]);
    $transactionId = (int)$pdo->lastInsertId();

    // 7. Insert customer subscription record
    $insSub = $pdo->prepare("
        INSERT INTO customer_subscriptions (customer_id, plan_id, status, remaining_deliveries, start_date, end_date)
        VALUES (?, ?, 'ACTIVE', ?, CURDATE(), DATE_ADD(CURDATE(), INTERVAL ? DAY))
    ");
    $insSub->execute([$customerId, $planId, $totalDeliveries, $planDuration]);
    $subscriptionId = (int)$pdo->lastInsertId();

    $pdo->commit();

    sendSuccess('Subscription plan purchased successfully.', [
        'subscription_id'      => $subscriptionId,
        'plan_name'            => $planName,
        'remaining_deliveries' => $totalDeliveries,
        'price_paid'           => number_format($planPrice, 2, '.', ''),
        'wallet_new_balance'   => number_format($newBalance, 2, '.', ''),
        'transaction_id'       => $transactionId
    ]);

} catch (Exception $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    
    $code = $e->getCode();
    $status = ($code >= 400 && $code <= 500) ? $code : 500;
    sendError($e->getMessage(), $status);
}
