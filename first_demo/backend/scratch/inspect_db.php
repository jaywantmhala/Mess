<?php
require_once 'd:/flutter/first_demo/backend/config/database.php';
require_once 'd:/flutter/first_demo/backend/helpers/tiffin_charge_helper.php';
$pdo = getDbConnection();

echo "--- CUSTOMER ADDRESSES COLUMNS ---\n";
$stmt = $pdo->query("SHOW COLUMNS FROM customer_addresses");
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));

echo "--- CUSTOMER ADDRESSES DATA ---\n";
$stmt = $pdo->query('SELECT * FROM customer_addresses');
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));

echo "--- CART ITEMS ---\n";
$stmt = $pdo->query('SELECT * FROM cart_items');
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));

echo "--- TEST resolveAreaTiffinCharge for customer 1 ---\n";
print_r(resolveAreaTiffinCharge($pdo, 1));

echo "--- TEST resolveAreaTiffinCharge for all customers in cart ---\n";
$customers = $pdo->query('SELECT DISTINCT customer_id FROM cart_items')->fetchAll(PDO::FETCH_COLUMN);
foreach ($customers as $cId) {
    echo "Customer $cId: \n";
    print_r(resolveAreaTiffinCharge($pdo, (int)$cId));
}
