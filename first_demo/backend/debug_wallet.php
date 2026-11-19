<?php
require_once __DIR__ . '/config/database.php';

$pdo = getDBConnection();

// ─── 1. Show all customers ─────────────────────────────────────────────────
echo "=== CUSTOMERS ===\n";
$rows = $pdo->query("SELECT id, full_name, email FROM customers")->fetchAll();
foreach ($rows as $r) {
    echo "  id={$r['id']} name={$r['full_name']} email={$r['email']}\n";
}

// ─── 2. Show all wallets ───────────────────────────────────────────────────
echo "\n=== WALLETS ===\n";
$rows = $pdo->query("SELECT w.wallet_id, w.customer_id, w.balance, c.full_name FROM wallets w JOIN customers c ON w.customer_id=c.id")->fetchAll();
foreach ($rows as $r) {
    echo "  wallet_id={$r['wallet_id']} customer={$r['full_name']} balance={$r['balance']}\n";
}

// ─── 3. Show last 10 wallet transactions ──────────────────────────────────
echo "\n=== LAST 10 WALLET TRANSACTIONS ===\n";
$rows = $pdo->query("SELECT wt.id, wt.wallet_id, wt.type, wt.amount, wt.description, wt.balance_after, wt.created_at FROM wallet_transactions wt ORDER BY wt.id DESC LIMIT 10")->fetchAll();
if (empty($rows)) {
    echo "  (no transactions found)\n";
}
foreach ($rows as $r) {
    echo "  id={$r['id']} type={$r['type']} amount={$r['amount']} desc=\"{$r['description']}\" balance_after={$r['balance_after']} at={$r['created_at']}\n";
}

// ─── 4. Show last 5 orders ────────────────────────────────────────────────
echo "\n=== LAST 5 ORDERS ===\n";
$rows = $pdo->query("SELECT o.order_id, o.customer_id, o.grand_total, o.wallet_deducted, o.payment_method, o.status, o.is_subscription_order, o.created_at FROM orders o ORDER BY o.order_id DESC LIMIT 5")->fetchAll();
if (empty($rows)) {
    echo "  (no orders found)\n";
}
foreach ($rows as $r) {
    $sub = $r['is_subscription_order'] ? ' [SUBSCRIPTION - wallet NOT deducted]' : '';
    echo "  order_id={$r['order_id']} customer={$r['customer_id']} total={$r['grand_total']} wallet_deducted={$r['wallet_deducted']} method={$r['payment_method']} status={$r['status']}{$sub}\n";
}

// ─── 5. Show active subscriptions ────────────────────────────────────────
echo "\n=== ACTIVE SUBSCRIPTIONS ===\n";
$rows = $pdo->query("SELECT cs.id, cs.customer_id, cs.status, cs.remaining_deliveries, cs.end_date, c.full_name FROM customer_subscriptions cs JOIN customers c ON cs.customer_id=c.id WHERE cs.status='ACTIVE' AND cs.end_date >= CURDATE() AND cs.remaining_deliveries > 0")->fetchAll();
if (empty($rows)) {
    echo "  (no active subscriptions - wallet deduction should work normally)\n";
} else {
    echo "  *** FOUND ACTIVE SUBSCRIPTIONS - wallet deduction is SKIPPED for these customers! ***\n";
    foreach ($rows as $r) {
        echo "  sub_id={$r['id']} customer={$r['full_name']} remaining={$r['remaining_deliveries']} end={$r['end_date']}\n";
    }
}

echo "\nDone.\n";
