<?php
/**
 * Admin API: Add Today's Earning for Vendor
 * Endpoint: POST /api/admin/payouts/add-earning
 *
 * Credits daily order earnings to a vendor's wallet and logs the transaction
 * into vendor_wallet_transactions so it immediately becomes eligible for RazorpayX Payout.
 */

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/cors.php';
require_once __DIR__ . '/../../../helpers/jwt.php';
require_once __DIR__ . '/../../../helpers/response.php';

header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendError('Method not allowed. Use POST.', 405);
}

try {
    // 1. Authenticate Admin Token
    $token = JWT::getBearerToken();
    $payload = $token ? JWT::verify($token) : null;
    if (!$payload || !isset($payload['sub']) || ($payload['role'] ?? '') !== 'admin') {
        sendError('Unauthorized. Admin access required.', 401);
    }

    $pdo = getDBConnection();

    // 2. Parse Input Data
    $raw = file_get_contents('php://input');
    $input = json_decode($raw, true) ?: $_POST;

    $vendorId = isset($input['vendor_id']) ? (int)$input['vendor_id'] : 0;
    $amount   = isset($input['amount']) ? round((float)$input['amount'], 2) : 0.00;
    $orderId  = !empty($input['order_id']) && is_numeric($input['order_id']) ? (int)$input['order_id'] : null;
    $desc     = !empty($input['description']) ? trim($input['description']) : "Daily order earning credit";

    if ($vendorId <= 0) {
        sendError('Please select a valid vendor.', 400);
    }

    if ($amount <= 0) {
        sendError('Earning amount must be greater than ₹0.00.', 400);
    }

    // 3. Verify Vendor Exists
    $vStmt = $pdo->prepare("SELECT id, full_name, email, phone, is_active FROM vendors WHERE id = :id LIMIT 1");
    $vStmt->execute([':id' => $vendorId]);
    $vendor = $vStmt->fetch(PDO::FETCH_ASSOC);

    if (!$vendor) {
        sendError('Vendor not found in database.', 404);
    }

    // 4. Atomic Transaction for Wallet Credit
    $pdo->beginTransaction();

    // Lock vendor_wallets row
    $wStmt = $pdo->prepare("SELECT id, balance FROM vendor_wallets WHERE vendor_id = :vid FOR UPDATE");
    $wStmt->execute([':vid' => $vendorId]);
    $wallet = $wStmt->fetch(PDO::FETCH_ASSOC);

    if (!$wallet) {
        $insW = $pdo->prepare("INSERT INTO vendor_wallets (vendor_id, balance, created_at, updated_at) VALUES (:vid, 0.00, NOW(), NOW())");
        $insW->execute([':vid' => $vendorId]);
        $currentBalance = 0.00;
    } else {
        $currentBalance = (float)$wallet['balance'];
    }

    $newBalance = round($currentBalance + $amount, 2);

    // Update vendor_wallets balance
    $updW = $pdo->prepare("UPDATE vendor_wallets SET balance = :bal, updated_at = NOW() WHERE vendor_id = :vid");
    $updW->execute([':bal' => $newBalance, ':vid' => $vendorId]);

    // Update vendors table wallet_balance column if exists
    try {
        $updV = $pdo->prepare("UPDATE vendors SET wallet_balance = :bal WHERE id = :vid");
        $updV->execute([':bal' => $newBalance, ':vid' => $vendorId]);
    } catch (Throwable $ignore) {}

    // Insert Credit Transaction into vendor_wallet_transactions
    $formattedAmt = number_format($amount, 2, '.', '');
    $fullDesc = $desc . ($orderId ? " (Order #$orderId)" : "") . " - ₹" . $formattedAmt;

    $insTx = $pdo->prepare("
        INSERT INTO vendor_wallet_transactions 
        (vendor_id, order_id, type, amount, balance_after, description, created_at)
        VALUES (:vid, :oid, 'CREDIT', :amt, :bal, :desc, NOW())
    ");
    $insTx->execute([
        ':vid'  => $vendorId,
        ':oid'  => $orderId,
        ':amt'  => $amount,
        ':bal'  => $newBalance,
        ':desc' => $fullDesc
    ]);
    $txId = (int)$pdo->lastInsertId();

    $pdo->commit();

    // 5. Calculate Today's Total Earnings for this Vendor
    $earnStmt = $pdo->prepare("
        SELECT COALESCE(SUM(amount), 0) as today_earnings, COUNT(*) as today_orders
        FROM vendor_wallet_transactions
        WHERE vendor_id = :vid 
          AND type = 'CREDIT' 
          AND DATE(created_at) = CURDATE()
    ");
    $earnStmt->execute([':vid' => $vendorId]);
    $earnData = $earnStmt->fetch(PDO::FETCH_ASSOC);
    $todayTotalEarnings = (float)($earnData['today_earnings'] ?? 0);
    $todayOrdersCount   = (int)($earnData['today_orders'] ?? 0);

    echo json_encode([
        'success' => true,
        'message' => "Successfully credited ₹" . number_format($amount, 2) . " to " . ($vendor['full_name'] ?: 'Vendor') . " for today's payout.",
        'data'    => [
            'transaction_id'       => $txId,
            'vendor_id'            => $vendorId,
            'vendor_name'          => $vendor['full_name'],
            'credited_amount'      => $amount,
            'wallet_balance'       => $newBalance,
            'today_total_earnings' => $todayTotalEarnings,
            'today_orders_count'   => $todayOrdersCount,
            'created_at'           => date('Y-m-d H:i:s'),
        ]
    ]);

} catch (Throwable $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Failed to add vendor earning: ' . $e->getMessage()
    ]);
}
