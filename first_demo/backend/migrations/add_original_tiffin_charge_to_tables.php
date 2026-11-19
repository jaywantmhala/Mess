<?php
require_once __DIR__ . '/../config/database.php';

$pdo = getDBConnection();

echo "Running migration: add_original_tiffin_charge_to_tables.php\n";

$tables = [
    'service_locations'  => '0.00',
    'plans'              => '0.00',
    'subscription_plans' => '0.00',
    'orders'             => '0.00',
];

foreach ($tables as $table => $default) {
    try {
        $cols = $pdo->query("SHOW COLUMNS FROM `$table`")->fetchAll(PDO::FETCH_COLUMN);
        if (!in_array('original_tiffin_charge', $cols)) {
            $pdo->exec("ALTER TABLE `$table` ADD COLUMN `original_tiffin_charge` DECIMAL(10,2) NOT NULL DEFAULT $default");
            echo "[OK] Added original_tiffin_charge to $table\n";
        } else {
            echo "[SKIP] original_tiffin_charge already exists in $table\n";
        }
    } catch (Exception $e) {
        echo "[ERROR] $table: " . $e->getMessage() . "\n";
    }
}

echo "Migration finished.\n";
