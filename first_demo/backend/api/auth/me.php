<?php
/**
 * GET /api/auth/me
 * Returns authenticated customer profile.
 * Requires: Authorization: Bearer <JWT>
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'GET')     { sendError('Method not allowed. Use GET.', 405); }

// ── JWT Auth ──────────────────────────────────────────────────────────────────
$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;
if (!$payload || !isset($payload['sub'])) {
    sendError('Unauthorized. Please log in again.', 401);
}

// ── Fetch Profile ─────────────────────────────────────────────────────────────
$pdo  = getDBConnection();
$stmt = $pdo->prepare("
    SELECT id, full_name, email, is_active, email_verified, last_login_at, created_at, updated_at
    FROM customers WHERE id = :id AND is_active = 1 LIMIT 1
");
$stmt->execute([':id' => (int) $payload['sub']]);
$customer = $stmt->fetch();

// ── Fallback: check & expire overdue subscriptions + reset wallet if no active plan ─────
try {
    $cId = (int)$payload['sub'];
    // 1. Expire any overdue subscriptions
    $expUpd = $pdo->prepare("UPDATE customer_subscriptions SET status = 'EXPIRED', expiration_timestamp = NOW(), updated_at = NOW() WHERE customer_id = ? AND status = 'ACTIVE' AND end_date <= CURDATE()");
    $expUpd->execute([$cId]);
    
    // 2. Check if customer has any active plan remaining
    $actCheck = $pdo->prepare("SELECT COUNT(*) FROM customer_subscriptions WHERE customer_id = ? AND status = 'ACTIVE' AND end_date > CURDATE() AND remaining_deliveries > 0");
    $actCheck->execute([$cId]);
    
    if ((int)$actCheck->fetchColumn() === 0) {
        $wStmt = $pdo->prepare("SELECT wallet_id, balance FROM wallets WHERE customer_id = ? FOR UPDATE");
        $wStmt->execute([$cId]);
        $w = $wStmt->fetch(PDO::FETCH_ASSOC);
        if ($w && (float)$w['balance'] > 0) {
            $prev = (float)$w['balance'];
            $pdo->prepare("UPDATE wallets SET balance = 0.00, plan_credit_balance = 0.00 WHERE wallet_id = ?")->execute([(int)$w['wallet_id']]);
            $pdo->prepare("INSERT INTO wallet_resets (customer_id, subscription_id, previous_balance, reset_amount, balance_after, reason) VALUES (?, NULL, ?, ?, 0.00, 'NO_ACTIVE_PLAN_EXPIRED')")->execute([$cId, $prev, $prev]);
            $pdo->prepare("INSERT INTO wallet_transactions (wallet_id, type, amount, description, balance_after) VALUES (?, 'DEBIT', ?, 'Plan Expired - Wallet Reset to 0', 0.00)")->execute([(int)$w['wallet_id'], $prev]);
        }
    }
} catch (Exception $e) {
    // Silently fail
}

if (!$customer) { sendError('Customer not found or account deactivated.', 404); }

sendSuccess('Profile fetched.', ['customer' => $customer]);
