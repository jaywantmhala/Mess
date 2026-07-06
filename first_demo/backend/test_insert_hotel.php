<?php
require_once __DIR__ . '/config/database.php';
try {
    $pdo = getDBConnection();
    $stmt = $pdo->prepare("INSERT INTO hotels (vendor_id, hotel_name, owner_name, mobile_number, email, hotel_address, latitude, longitude, created_at) VALUES (1, 'Far Away Grand Hotel', 'John Doe', '9876543210', 'faraway@example.com', 'Pune Railway Station, Pune', 18.5284, 73.8739, NOW())");
    $stmt->execute();
    echo "Inserted dummy hotel successfully!";
} catch (Exception $e) {
    echo $e->getMessage();
}
