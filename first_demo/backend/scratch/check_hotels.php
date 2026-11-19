<?php
require_once 'd:/flutter/first_demo/backend/config/database.php';
$pdo = getDbConnection();

echo "--- HOTELS COLUMNS ---\n";
$stmt = $pdo->query("SHOW COLUMNS FROM hotels");
foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $c) {
    echo $c['Field'] . " (" . $c['Type'] . ")\n";
}
