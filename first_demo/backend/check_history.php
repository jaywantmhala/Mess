<?php
require_once 'd:/flutter/first_demo/backend/config/database.php';
$pdo = getDBConnection();
$stmt = $pdo->query("SELECT * FROM admin_whatsapp_notifications ORDER BY id DESC LIMIT 5");
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));
