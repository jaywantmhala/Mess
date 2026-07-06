<?php
require_once __DIR__ . '/config/database.php';
try {
    $pdo = getDBConnection();
    $stmt = $pdo->query("SELECT * FROM customers");
    $customers = $stmt->fetchAll(PDO::FETCH_ASSOC);
    print_r($customers);
} catch (Exception $e) {
    echo $e->getMessage();
}
