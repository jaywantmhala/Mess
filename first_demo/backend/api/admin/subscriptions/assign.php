<?php
/**
 * POST /api/admin/subscriptions/assign
 *
 * Manually assign a subscription plan to a customer from the Admin panel.
 * Deducts/credits wallet as appropriate (credits plan price to customer wallet, 
 * registers active subscription, and creates wallet transaction record).
 *
 * Request Body: { customer_id, plan_id, notes? }
 * Headers: Authorization: Bearer <JWT> (Admin)
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

// ── JWT Admin Authentication ──────────────────────────────────────────────────
$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || !isset($payload['sub']) || ($payload['role'] ?? '') !== 'admin') {
    sendError('Unauthorized. Admin access required.', 401);
}

$rawInput = file_get_contents('php://input');
$body     = json_decode($rawInput, true) ?? [];

$customerId = isset($body['customer_id']) ? (int)$body['customer_id'] : 0;
$planId     = isset($body['plan_id']) ? (int)$body['plan_id'] : 0;
$notes      = isset($body['notes']) ? trim($body['notes']) : '';

if ($customerId <= 0 || $planId <= 0) {
    sendError('Both customer_id and plan_id are required.', 422);
}

try {
    $pdo = getDBConnection();

    // Remove foreign key constraint on customer_subscriptions if legacy issue exists
    try {
        $pdo->exec("ALTER TABLE `customer_subscriptions` DROP FOREIGN KEY `fk_cust_sub_plan` drop foreign key `fk_cust_sub_plan`");
    } catch (PDOException $ex) {}

    $pdo->beginTransaction();

    // 1. Verify customer exists
    $custStmt = $pdo->prepare("SELECT id, full_name, email FROM customers WHERE id = ? FOR UPDATE");
    $custStmt->execute([$customerId]);
    $customer = $custStmt->fetch(PDO::FETCH_ASSOC);

    if (!$customer) {
        throw new Exception("Customer profile not found.", 404);
    }

    // 2. Fetch the plan details — check new `plans` table first, fallback to `subscription_plans`
    $plan = null;
    $newPlanStmt = $pdo->prepare("
        SELECT p.id, p.plan_name, p.price, p.duration, p.total_deliveries, p.status, sl.location_name
        FROM plans p
        LEFT JOIN service_locations sl ON p.service_location_id = sl.id
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
            'price'            => (float)$newPlan['price'],
            'duration'         => (int)$newPlan['duration'],
            'total_deliveries' => (int)$newPlan['total_deliveries'],
            'location'         => $newPlan['location_name'] ?? ''
        ];
    } else {
        // Fallback: legacy subscription_plans table
        $legStmt = $pdo->prepare("
            SELECT sp.id, sp.plan_name, sp.price, sp.duration, sp.total_deliveries, sp.is_active, sa.sub_area_name
            FROM subscription_plans sp
            LEFT JOIN sub_areas sa ON sp.sub_area_id = sa.id
            WHERE sp.id = ? FOR UPDATE
        ");
        $legStmt->execute([$planId]);
        $legPlan = $legStmt->fetch(PDO::FETCH_ASSOC);

        if (!$legPlan) {
            throw new Exception("Subscription plan not found.", 404);
        }
        if (!$legPlan['is_active']) {
            throw new Exception("Selected subscription plan is deactivated.", 422);
        }
        $plan = [
            'plan_name'        => $legPlan['plan_name'],
            'price'            => (float)$legPlan['price'],
            'duration'         => (int)$legPlan['duration'],
            'total_deliveries' => (int)$legPlan['total_deliveries'],
            'location'         => $legPlan['sub_area_name'] ?? ''
        ];
    }

    $planName        = $plan['plan_name'];
    $planPrice       = $plan['price'];
    $planDuration    = $plan['duration'];
    $totalDeliveries = $plan['total_deliveries'];

    // 3. Close/Supercede any existing active subscription for this customer
    $updOldSub = $pdo->prepare("
        UPDATE customer_subscriptions 
        SET status = 'EXPIRED', updated_at = NOW() 
        WHERE customer_id = ? AND status = 'ACTIVE'
    ");
    $updOldSub->execute([$customerId]);

    // 4. Credit plan price to customer's wallet (mirroring app buy flow)
    $wStmt = $pdo->prepare("SELECT wallet_id, balance FROM wallets WHERE customer_id = ? FOR UPDATE");
    $wStmt->execute([$customerId]);
    $wallet = $wStmt->fetch(PDO::FETCH_ASSOC);

    if (!$wallet) {
        $insWallet = $pdo->prepare("INSERT INTO wallets (customer_id, balance, plan_credit_balance) VALUES (?, 0.00, 0.00)");
        $insWallet->execute([$customerId]);
        $walletId = (int)$pdo->lastInsertId();
        $balance  = 0.00;
    } else {
        $walletId = (int)$wallet['wallet_id'];
        $balance  = (float)$wallet['balance'];
    }

    $newBalance = round($balance + $planPrice, 2);

    $updWallet = $pdo->prepare("UPDATE wallets SET balance = ?, plan_credit_balance = plan_credit_balance + ? WHERE wallet_id = ?");
    $updWallet->execute([$newBalance, $planPrice, $walletId]);

    // 5. Create wallet transaction record
    $txnStmt = $pdo->prepare("
        INSERT INTO wallet_transactions (wallet_id, type, amount, description, balance_after)
        VALUES (?, 'CREDIT', ?, ?, ?)
    ");
    $txnDescription = "Subscription Plan Assigned by Admin: " . $planName;
    if ($notes !== '') {
        $txnDescription .= " (" . $notes . ")";
    }
    $txnStmt->execute([$walletId, $planPrice, $txnDescription, $newBalance]);
    $transactionId = (int)$pdo->lastInsertId();

    // 6. Insert new active subscription record
    $insSub = $pdo->prepare("
        INSERT INTO customer_subscriptions (customer_id, plan_id, status, remaining_deliveries, total_deliveries, completed_deliveries, start_date, end_date)
        VALUES (?, ?, 'ACTIVE', ?, ?, 0, CURDATE(), DATE_ADD(CURDATE(), INTERVAL ? DAY))
    ");
    $insSub->execute([$customerId, $planId, $totalDeliveries, $totalDeliveries, $planDuration]);
    $subscriptionId = (int)$pdo->lastInsertId();

    // 7. Generate subscription delivery dates schedule if subscription_deliveries table exists
    try {
        $startDate = new DateTime();
        $insDel = $pdo->prepare("INSERT INTO subscription_deliveries (subscription_id, customer_id, delivery_date, status) VALUES (?, ?, ?, 'PENDING')");
        for ($i = 0; $i < $totalDeliveries; $i++) {
            $deliveryDateStr = $startDate->format('Y-m-d');
            $insDel->execute([$subscriptionId, $customerId, $deliveryDateStr]);
            $startDate->modify('+1 day');
        }
    } catch (Exception $ex) {
        // Table may not exist or schedule generation non-critical
    }

    $pdo->commit();

    // Send push notification to customer
    try {
        FcmHelper::sendToCustomer(
            $customerId,
            "Subscription Plan Assigned!",
            "Admin assigned you the subscription plan '" . $planName . "'. ₹" . number_format($planPrice, 2, '.', '') . " has been added to your wallet!"
        );
    } catch (Exception $ex) {}

    sendSuccess("Subscription plan successfully assigned to customer and wallet credited.", [
        'subscription_id'    => $subscriptionId,
        'customer_id'        => $customerId,
        'customer_name'      => $customer['full_name'],
        'plan_id'            => $planId,
        'plan_name'          => $planName,
        'price_credited'     => number_format($planPrice, 2, '.', ''),
        'wallet_new_balance' => number_format($newBalance, 2, '.', ''),
        'total_deliveries'   => $totalDeliveries,
        'transaction_id'     => $transactionId
    ]);

} catch (Exception $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    $code = $e->getCode();
    $status = ($code >= 400 && $code <= 500) ? $code : 500;
    sendError($e->getMessage(), $status);
}
