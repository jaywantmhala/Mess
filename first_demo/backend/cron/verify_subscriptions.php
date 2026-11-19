<?php
/**
 * Cron Job — Daily Subscription Verifier
 *
 * Verifies all active subscriptions:
 * 1. Expires overdue subscriptions (end_date < today)
 * 2. Completes subscriptions with 0 remaining deliveries
 * 3. Sends FCM expiration warnings (7 days, 3 days, 1 day, on expiry)
 *
 * Can be run via CLI: php verify_subscriptions.php
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers/fcm.php';

// Verify running from CLI or allow safe manual runs
if (php_sapi_name() !== 'cli') {
    header('Content-Type: application/json; charset=utf-8');
}

try {
    $pdo = getDBConnection();
    
    $today = new DateTime();
    $todayStr = $today->format('Y-m-d');
    
    echo "=== Running Daily Subscription Verification [ " . date('Y-m-d H:i:s') . " ] ===\n";

    // ── 1. Expire subscriptions that have passed their end date ─────────────────
    $overdueStmt = $pdo->prepare("
        SELECT id, customer_id, end_date 
        FROM customer_subscriptions 
        WHERE status = 'ACTIVE' AND end_date <= ?
    ");
    $overdueStmt->execute([$todayStr]);
    $overdueSubs = $overdueStmt->fetchAll(PDO::FETCH_ASSOC);

    echo "Found " . count($overdueSubs) . " overdue subscriptions.\n";
    foreach ($overdueSubs as $sub) {
        $subId = (int)$sub['id'];
        $customerId = (int)$sub['customer_id'];
        
        $pdo->beginTransaction();
        try {
            // Update status to EXPIRED
            $upd = $pdo->prepare("UPDATE customer_subscriptions SET status = 'EXPIRED', expiration_timestamp = NOW(), updated_at = NOW() WHERE id = ?");
            $upd->execute([$subId]);
            
            // Cancel all pending deliveries
            $cancelDel = $pdo->prepare("UPDATE subscription_deliveries SET status = 'CANCELLED' WHERE subscription_id = ? AND status = 'PENDING'");
            $cancelDel->execute([$subId]);
            
            // ── Reset plan credit balance from wallet ──
            try {
                $walletStmt = $pdo->prepare("SELECT wallet_id, balance, plan_credit_balance FROM wallets WHERE customer_id = ? FOR UPDATE");
                $walletStmt->execute([$customerId]);
                $wallet = $walletStmt->fetch(PDO::FETCH_ASSOC);
                
                if ($wallet) {
                    $prevBalance = (float)$wallet['balance'];
                    $resetAmount = $prevBalance;
                    $newBalance = 0.00;
                    
                    if ($prevBalance > 0) {
                        // Update wallet: reset balance and plan_credit_balance to 0.00
                        $updW = $pdo->prepare("UPDATE wallets SET balance = 0.00, plan_credit_balance = 0.00 WHERE wallet_id = ?");
                        $updW->execute([(int)$wallet['wallet_id']]);
                        
                        // Audit log in wallet_resets
                        $auditStmt = $pdo->prepare("
                            INSERT INTO wallet_resets (customer_id, subscription_id, previous_balance, reset_amount, balance_after, reason)
                            VALUES (?, ?, ?, ?, 0.00, 'PLAN_EXPIRED')
                        ");
                        $auditStmt->execute([$customerId, $subId, $prevBalance, $resetAmount]);
                        
                        // Debit transaction record
                        $txnStmt = $pdo->prepare("
                            INSERT INTO wallet_transactions (wallet_id, type, amount, description, balance_after)
                            VALUES (?, 'DEBIT', ?, ?, 0.00)
                        ");
                        $txnStmt->execute([(int)$wallet['wallet_id'], $resetAmount, 'Plan Expired - Wallet Reset to 0']);
                        
                        echo "   -> Wallet reset to 0 for customer #$customerId (Previous balance ₹$prevBalance wiped)\n";
                    } else {
                        // Balance already 0, clear plan credit tracker
                        $updW = $pdo->prepare("UPDATE wallets SET balance = 0.00, plan_credit_balance = 0.00 WHERE wallet_id = ?");
                        $updW->execute([(int)$wallet['wallet_id']]);
                        echo "   -> Wallet balance already 0 for customer #$customerId.\n";
                    }
                }
            } catch (Exception $walletEx) {
                echo "   -> Warning: Could not reset wallet for customer #$customerId: " . $walletEx->getMessage() . "\n";
            }

            $pdo->commit();
            echo "-> Subscription #$subId has EXPIRED. Cancelled pending deliveries.\n";

            // Send FCM push alert
            FcmHelper::sendToCustomer($customerId, "⚠️ Subscription Expired", "Your meal subscription has expired and unused plan credits have been removed from your wallet. Please renew to continue receiving meals.");
        } catch (Exception $ex) {
            $pdo->rollBack();
            echo "-> Error expiring subscription #$subId: " . $ex->getMessage() . "\n";
        }
    }

    // ── 1b. Sweep pass: Reset wallet to 0.00 for any customer with NO active unexpired subscription ──
    $sweepStmt = $pdo->query("
        SELECT w.wallet_id, w.customer_id, w.balance 
        FROM wallets w
        WHERE w.balance > 0 
          AND NOT EXISTS (
              SELECT 1 FROM customer_subscriptions cs 
              WHERE cs.customer_id = w.customer_id 
                AND cs.status = 'ACTIVE' 
                AND cs.end_date > CURDATE() 
                AND cs.remaining_deliveries > 0
          )
    ");
    $unsubscribedWallets = $sweepStmt->fetchAll(PDO::FETCH_ASSOC);
    echo "Found " . count($unsubscribedWallets) . " wallets with positive balance but no active subscription.\n";

    foreach ($unsubscribedWallets as $w) {
        $cId = (int)$w['customer_id'];
        $wId = (int)$w['wallet_id'];
        $prevBal = (float)$w['balance'];

        $pdo->beginTransaction();
        try {
            $updW = $pdo->prepare("UPDATE wallets SET balance = 0.00, plan_credit_balance = 0.00 WHERE wallet_id = ?");
            $updW->execute([$wId]);

            $auditStmt = $pdo->prepare("
                INSERT INTO wallet_resets (customer_id, subscription_id, previous_balance, reset_amount, balance_after, reason)
                VALUES (?, NULL, ?, ?, 0.00, 'NO_ACTIVE_PLAN_EXPIRED')
            ");
            $auditStmt->execute([$cId, $prevBal, $prevBal]);

            $txnStmt = $pdo->prepare("
                INSERT INTO wallet_transactions (wallet_id, type, amount, description, balance_after)
                VALUES (?, 'DEBIT', ?, 'Plan Expired - Wallet Reset to 0', 0.00)
            ");
            $txnStmt->execute([$wId, $prevBal]);

            $pdo->commit();
            echo "-> Swept wallet #$wId for customer #$cId: balance reset from ₹$prevBal to 0.00\n";
        } catch (Exception $ex) {
            $pdo->rollBack();
        }
    }

    // ── 2. Complete subscriptions that have 0 remaining deliveries ──────────────
    $completedStmt = $pdo->query("
        SELECT id, customer_id 
        FROM customer_subscriptions 
        WHERE status = 'ACTIVE' AND remaining_deliveries = 0
    ");
    $completedSubs = $completedStmt->fetchAll(PDO::FETCH_ASSOC);

    echo "Found " . count($completedSubs) . " completed subscriptions (0 deliveries remaining).\n";
    foreach ($completedSubs as $sub) {
        $subId = (int)$sub['id'];
        $customerId = (int)$sub['customer_id'];
        
        $pdo->beginTransaction();
        try {
            // Update status to COMPLETED
            $upd = $pdo->prepare("UPDATE customer_subscriptions SET status = 'COMPLETED', expiration_timestamp = NOW(), updated_at = NOW() WHERE id = ?");
            $upd->execute([$subId]);
            
            // Cancel all pending deliveries
            $cancelDel = $pdo->prepare("UPDATE subscription_deliveries SET status = 'CANCELLED' WHERE subscription_id = ? AND status = 'PENDING'");
            $cancelDel->execute([$subId]);
            
            $pdo->commit();
            echo "-> Subscription #$subId is COMPLETED. Cancelled pending deliveries.\n";

            // Send FCM push alert
            FcmHelper::sendToCustomer($customerId, "🍽️ Subscription Completed", "You have received all meals in your subscription. Renew now to get more meals!");
        } catch (Exception $ex) {
            $pdo->rollBack();
            echo "-> Error completing subscription #$subId: " . $ex->getMessage() . "\n";
        }
    }

    // ── 3. Send warnings for active plans expiring soon (7 days, 3 days, 1 day, today)
    $activeStmt = $pdo->query("
        SELECT cs.id, cs.customer_id, cs.end_date, sp.plan_name 
        FROM customer_subscriptions cs
        JOIN subscription_plans sp ON cs.plan_id = sp.id
        WHERE cs.status = 'ACTIVE'
    ");
    $activeSubs = $activeStmt->fetchAll(PDO::FETCH_ASSOC);

    echo "Scanning " . count($activeSubs) . " active subscriptions for upcoming expiration.\n";
    foreach ($activeSubs as $sub) {
        $subId = (int)$sub['id'];
        $customerId = (int)$sub['customer_id'];
        $endDate = new DateTime($sub['end_date']);
        $planName = $sub['plan_name'];
        
        // Calculate difference in days
        $diff = $today->diff($endDate);
        $daysLeft = (int)$diff->format('%r%a'); // format signed difference

        if ($daysLeft === 7) {
            FcmHelper::sendToCustomer($customerId, "📅 Subscription Expiring Soon", "Your subscription to $planName expires in 7 days. Renew now to avoid interruption.");
            echo "-> Sent 7-day expiration warning to customer #$customerId for sub #$subId.\n";
        } else if ($daysLeft === 3) {
            FcmHelper::sendToCustomer($customerId, "📅 Subscription Expiring Soon", "Your subscription to $planName expires in 3 days. Renew now to avoid interruption.");
            echo "-> Sent 3-day expiration warning to customer #$customerId for sub #$subId.\n";
        } else if ($daysLeft === 1) {
            FcmHelper::sendToCustomer($customerId, "⏰ Subscription Expires Tomorrow", "Your subscription to $planName expires tomorrow! Renew now to avoid interruption.");
            echo "-> Sent 1-day expiration warning to customer #$customerId for sub #$subId.\n";
        } else if ($daysLeft === 0) {
            FcmHelper::sendToCustomer($customerId, "⏰ Subscription Expires Today", "Your subscription to $planName expires today! Renew now to continue receiving meals.");
            echo "-> Sent today-expiry warning to customer #$customerId for sub #$subId.\n";
        }
    }

    echo "=== Daily Subscription Verification completed successfully ===\n";
    if (php_sapi_name() !== 'cli') {
        echo json_encode(['success' => true, 'message' => 'Daily subscriptions verification completed successfully.']);
    }

} catch (Exception $e) {
    echo "Fatal Error: " . $e->getMessage() . "\n";
    if (php_sapi_name() !== 'cli') {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Daily verification failed: ' . $e->getMessage()]);
    }
}
