<?php
require_once 'd:/flutter/first_demo/backend/config/database.php';
$pdo = getDBConnection();

echo "--- VENDORS (first 5) ---\n";
$vendors = $pdo->query("SELECT id, full_name, email, state, district, taluka, fcm_token FROM vendors LIMIT 5")->fetchAll(PDO::FETCH_ASSOC);
print_r($vendors);

echo "--- HOTELS (first 5) ---\n";
$hotels = $pdo->query("SELECT id, vendor_id, hotel_name, state, district, taluka, city, hotel_address FROM hotels LIMIT 5")->fetchAll(PDO::FETCH_ASSOC);
print_r($hotels);

echo "--- ADMIN NOTIFICATIONS (last 5) ---\n";
$notifs = $pdo->query("SELECT id, title, body, target, state, district, taluka, created_at FROM admin_notifications ORDER BY id DESC LIMIT 5")->fetchAll(PDO::FETCH_ASSOC);
print_r($notifs);
