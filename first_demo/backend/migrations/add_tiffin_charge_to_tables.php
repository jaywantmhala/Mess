<?php
require_once __DIR__ . '/../config/database.php';

$pdo = getDBConnection();

echo "Running migration: add_tiffin_charge_to_tables.php\n";

$tables = [
    'service_locations'  => '50.00',
    'plans'              => '50.00',
    'sub_areas'          => '50.00',
    'subscription_plans' => '50.00',
    'orders'             => '50.00',
];

foreach ($tables as $table => $default) {
    try {
        $cols = $pdo->query("SHOW COLUMNS FROM `$table`")->fetchAll(PDO::FETCH_COLUMN);
        if (!in_array('tiffin_charge', $cols)) {
            $pdo->exec("ALTER TABLE `$table` ADD COLUMN `tiffin_charge` DECIMAL(10,2) NOT NULL DEFAULT $default");
            echo "[OK] Added tiffin_charge to $table\n";
        } else {
            echo "[SKIP] tiffin_charge already exists in $table\n";
        }
    } catch (Exception $e) {
        echo "[ERROR] $table: " . $e->getMessage() . "\n";
    }
}

echo "Migration finished.\n";
