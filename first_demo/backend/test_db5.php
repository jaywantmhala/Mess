<?php
require_once __DIR__ . '/config/database.php';
try {
    $pdo = getDBConnection();
    $stmt = $pdo->query("SELECT * FROM customer_addresses");
    print_r($stmt->fetchAll(PDO::FETCH_ASSOC));
} catch (Exception $e) {
    echo $e->getMessage();
}
