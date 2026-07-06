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

    // Fetch wallet
    $stmt = $pdo->prepare("SELECT wallet_id, customer_id, balance FROM wallets WHERE customer_id = ?");
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
        ];
    }

    sendSuccess('Wallet balance fetched successfully.', [
        'wallet_id'   => (int) $wallet['wallet_id'],
        'customer_id' => (int) $wallet['customer_id'],
        'balance'     => number_format((float) $wallet['balance'], 2, '.', ''),
    ]);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
