<?php
require_once __DIR__ . '/config/database.php';
try {
    $pdo = getDBConnection();
    $stmt = $pdo->query("SELECT id, hotel_name, latitude, longitude FROM hotels");
    $hotels = $stmt->fetchAll(PDO::FETCH_ASSOC);
    print_r($hotels);
} catch (Exception $e) {
    echo $e->getMessage();
}
