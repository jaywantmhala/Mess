<?php
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST') { sendError('Method not allowed.', 405); }

$token = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;
if (!$payload || !isset($payload['sub'])) { sendError('Unauthorized.', 401); }
$customerId = (int) $payload['sub'];

$body = json_decode(file_get_contents('php://input'), true);
if (!isset($body['amount'])) { sendError('Amount is required.', 422); }

$amount = (float) $body['amount'];
if ($amount <= 0)     { sendError('Amount must be greater than 0.', 422); }
if ($amount > 50000)  { sendError('Amount cannot exceed 50,000.', 422); }

try {
    $pdo = getDBConnection();
    $pdo->beginTransaction();

    // Get or create wallet (with row lock for update)
    $stmt = $pdo->prepare("SELECT wallet_id, balance FROM wallets WHERE customer_id = ? FOR UPDATE");
    $stmt->execute([$customerId]);
    $wallet = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$wallet) {
        $ins = $pdo->prepare("INSERT INTO wallets (customer_id, balance) VALUES (?, 0.00)");
        $ins->execute([$customerId]);
        $walletId      = (int) $pdo->lastInsertId();
        $currentBalance = 0.00;
    } else {
        $walletId      = (int) $wallet['wallet_id'];
        $currentBalance = (float) $wallet['balance'];
    }

    $newBalance = $currentBalance + $amount;

    // Update wallet balance
    $upd = $pdo->prepare("UPDATE wallets SET balance = ? WHERE wallet_id = ?");
    $upd->execute([$newBalance, $walletId]);

    // Insert transaction record
    $txn = $pdo->prepare(
        "INSERT INTO wallet_transactions (wallet_id, type, amount, description, balance_after)
         VALUES (?, 'CREDIT', ?, 'Wallet Recharge', ?)"
    );
    $txn->execute([$walletId, $amount, $newBalance]);
    $transactionId = (int) $pdo->lastInsertId();

    $pdo->commit();

    sendSuccess('Wallet recharged successfully.', [
        'new_balance'    => number_format($newBalance, 2, '.', ''),
        'transaction_id' => $transactionId,
    ]);

} catch (PDOException $e) {
    if (isset($pdo) && $pdo->inTransaction()) { $pdo->rollBack(); }
    sendError('Database error: ' . $e->getMessage(), 500);
}
