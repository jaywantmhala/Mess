<?php
require_once __DIR__ . '/../config/database.php';
$pdo = getDBConnection();
$upd = $pdo->prepare("UPDATE vendor_payouts SET bank_transaction_ref_no = 'UTR2026091598721345' WHERE id = 1 AND bank_transaction_ref_no IS NULL");
$upd->execute();
echo "Updated UTR for Payout #1: " . $upd->rowCount() . " row(s).\n";
