<?php
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'GET') { sendError('Method not allowed.', 405); }

$token = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;
if (!$payload || !isset($payload['sub'])) { sendError('Unauthorized.', 401); }
$customerId = (int) $payload['sub'];

try {
    $pdo = getDBConnection();

    // ── Fallback: expire overdue subscriptions & reset wallet balance to 0 ──
    try {
        $expUpd = $pdo->prepare("UPDATE customer_subscriptions SET status = 'EXPIRED', expiration_timestamp = NOW(), updated_at = NOW() WHERE customer_id = ? AND status = 'ACTIVE' AND end_date <= CURDATE()");
        $expUpd->execute([$customerId]);

        $actCheck = $pdo->prepare("SELECT COUNT(*) FROM customer_subscriptions WHERE customer_id = ? AND status = 'ACTIVE' AND end_date > CURDATE() AND remaining_deliveries > 0");
        $actCheck->execute([$customerId]);

        if ((int)$actCheck->fetchColumn() === 0) {
            $wStmt = $pdo->prepare("SELECT wallet_id, balance FROM wallets WHERE customer_id = ? FOR UPDATE");
            $wStmt->execute([$customerId]);
            $w = $wStmt->fetch(PDO::FETCH_ASSOC);
            if ($w && (float)$w['balance'] > 0) {
                $prev = (float)$w['balance'];
                $pdo->prepare("UPDATE wallets SET balance = 0.00, plan_credit_balance = 0.00 WHERE wallet_id = ?")->execute([(int)$w['wallet_id']]);
                $pdo->prepare("INSERT INTO wallet_resets (customer_id, subscription_id, previous_balance, reset_amount, balance_after, reason) VALUES (?, NULL, ?, ?, 0.00, 'NO_ACTIVE_PLAN_EXPIRED')")->execute([$customerId, $prev, $prev]);
                $pdo->prepare("INSERT INTO wallet_transactions (wallet_id, type, amount, description, balance_after) VALUES (?, 'DEBIT', ?, 'Plan Expired - Wallet Reset to 0', 0.00)")->execute([(int)$w['wallet_id'], $prev]);
            }
        }
    } catch (Exception $e) {
        // Silently fail
    }

    // Fetch wallet
    $stmt = $pdo->prepare("SELECT wallet_id, customer_id, balance, COALESCE(plan_credit_balance, 0.00) AS plan_credit_balance FROM wallets WHERE customer_id = ?");
    $stmt->execute([$customerId]);
    $wallet = $stmt->fetch(PDO::FETCH_ASSOC);

    // Auto-create wallet if it doesn't exist
    if (!$wallet) {
        $insert = $pdo->prepare("INSERT INTO wallets (customer_id, balance) VALUES (?, 0.00)");
        $insert->execute([$customerId]);
        $walletId = (int) $pdo->lastInsertId();
        $wallet = [
            'wallet_id'   => $walletId,
            'customer_id' => $customerId,
            'balance'     => '0.00',
            'plan_credit_balance' => '0.00',
        ];
    }

    sendSuccess('Wallet balance fetched successfully.', [
        'wallet_id'   => (int) $wallet['wallet_id'],
        'customer_id' => (int) $wallet['customer_id'],
        'balance'     => number_format((float) $wallet['balance'], 2, '.', ''),
        'plan_credit_balance' => number_format((float)$wallet['plan_credit_balance'], 2, '.', ''),
    ]);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
