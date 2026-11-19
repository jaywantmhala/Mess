<?php
/**
 * POST /api/auth/delete_account
 *
 * Permanently deletes the customer account and all associated customer data
 * from the MySQL database.
 *
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

$pdo = getDBConnection();

try {
    // 1. Verify customer exists
    $stmt = $pdo->prepare("SELECT id, email FROM customers WHERE id = ? LIMIT 1");
    $stmt->execute([$customerId]);
    $customer = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$customer) {
        sendError('Customer account not found in database.', 404);
    }

    $customerEmail = $customer['email'];

    $pdo->beginTransaction();

    // 2. Delete related records across child tables safely
    $pdo->prepare("DELETE FROM customer_subscriptions WHERE customer_id = ?")->execute([$customerId]);
    $pdo->prepare("DELETE FROM razorpay_payments WHERE customer_id = ?")->execute([$customerId]);
    $pdo->prepare("DELETE FROM cashfree_payments WHERE customer_id = ?")->execute([$customerId]);
    $pdo->prepare("DELETE FROM upi_payments WHERE customer_id = ?")->execute([$customerId]);
    $pdo->prepare("DELETE FROM customer_addresses WHERE customer_id = ?")->execute([$customerId]);
    $pdo->prepare("DELETE FROM cart_items WHERE customer_id = ?")->execute([$customerId]);
    if (!empty($customerEmail)) {
        $pdo->prepare("DELETE FROM password_resets WHERE email = ?")->execute([$customerEmail]);
    }

    // Delete wallet transactions & wallet
    $wStmt = $pdo->prepare("SELECT wallet_id FROM wallets WHERE customer_id = ?");
    $wStmt->execute([$customerId]);
    $wallet = $wStmt->fetch(PDO::FETCH_ASSOC);
    if ($wallet) {
        $pdo->prepare("DELETE FROM wallet_transactions WHERE wallet_id = ?")->execute([$wallet['wallet_id']]);
        $pdo->prepare("DELETE FROM wallets WHERE wallet_id = ?")->execute([$wallet['wallet_id']]);
    }

    // Delete order items and orders
    $pdo->prepare("DELETE FROM order_items WHERE order_id IN (SELECT order_id FROM orders WHERE customer_id = ?)")->execute([$customerId]);
    $pdo->prepare("DELETE FROM orders WHERE customer_id = ?")->execute([$customerId]);

    // 3. Physically delete customer row from `customers` table
    $delCustomer = $pdo->prepare("DELETE FROM customers WHERE id = ?");
    $delCustomer->execute([$customerId]);

    $pdo->commit();

    sendSuccess('Account and all associated data permanently deleted from database.', [
        'customer_id' => $customerId,
        'deleted'     => true,
    ]);

} catch (Exception $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    sendError('Failed to delete account from database: ' . $e->getMessage(), 500);
}
