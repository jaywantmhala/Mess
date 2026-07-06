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

$page  = max(1, (int) ($_GET['page']  ?? 1));
$limit = max(1, min(100, (int) ($_GET['limit'] ?? 20)));
$offset = ($page - 1) * $limit;

try {
    $pdo = getDBConnection();

    // Ensure wallet exists
    $wStmt = $pdo->prepare("SELECT wallet_id FROM wallets WHERE customer_id = ?");
    $wStmt->execute([$customerId]);
    $wallet = $wStmt->fetch(PDO::FETCH_ASSOC);

    if (!$wallet) {
        // Auto-create wallet and return empty list
        $ins = $pdo->prepare("INSERT INTO wallets (customer_id, balance) VALUES (?, 0.00)");
        $ins->execute([$customerId]);
        sendSuccess('Transactions fetched successfully.', [
            'transactions' => [],
            'page'         => $page,
            'limit'        => $limit,
            'total'        => 0,
        ]);
    }

    $walletId = (int) $wallet['wallet_id'];

    // Count total transactions
    $countStmt = $pdo->prepare("SELECT COUNT(*) FROM wallet_transactions WHERE wallet_id = ?");
    $countStmt->execute([$walletId]);
    $total = (int) $countStmt->fetchColumn();

    // Fetch paginated transactions
    $stmt = $pdo->prepare(
        "SELECT id, type, amount, description, balance_after, created_at
         FROM wallet_transactions
         WHERE wallet_id = ?
         ORDER BY created_at DESC
         LIMIT ? OFFSET ?"
    );
    $stmt->execute([$walletId, $limit, $offset]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $transactions = array_map(function ($row) {
        return [
            'id'            => (int)    $row['id'],
            'type'          =>          $row['type'],
            'amount'        => number_format((float) $row['amount'],        2, '.', ''),
            'description'   =>          $row['description'],
            'balance_after' => number_format((float) $row['balance_after'], 2, '.', ''),
            'created_at'    =>          $row['created_at'],
        ];
    }, $rows);

    sendSuccess('Transactions fetched successfully.', [
        'transactions' => $transactions,
        'page'         => $page,
        'limit'        => $limit,
        'total'        => $total,
    ]);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
