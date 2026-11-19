<?php
require_once 'd:/flutter/first_demo/backend/config/database.php';
$pdo = getDbConnection();

echo "--- MENUS COLUMNS ---\n";
$stmt = $pdo->query("SHOW COLUMNS FROM menus");
foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $c) {
    echo $c['Field'] . " (" . $c['Type'] . ") Default: " . var_export($c['Default'], true) . "\n";
}

echo "\n--- SAMPLE MENUS ---\n";
$stmt = $pdo->query("SELECT * FROM menus ORDER BY id DESC LIMIT 5");
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));
