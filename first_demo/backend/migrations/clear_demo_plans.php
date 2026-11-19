<?php
/**
 * Migration: Check and delete demo plans from `plans` and `subscription_plans` tables.
 */

require_once __DIR__ . '/../config/database.php';

header('Content-Type: text/plain; charset=utf-8');

try {
    $pdo = getDBConnection();

    // Check `plans` table
    $stmt = $pdo->query("SELECT id, plan_name, price FROM plans");
    $plans = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo "--- Current Plans in 'plans' table ---\n";
    print_r($plans);

    // Delete all rows in plans and subscription_plans
    $count1 = $pdo->exec("DELETE FROM plans");
    echo "Deleted $count1 demo plans from 'plans' table.\n";

    try {
        $count2 = $pdo->exec("DELETE FROM subscription_plans");
        echo "Deleted $count2 demo plans from 'subscription_plans' table.\n";
    } catch (Exception $e) {
        echo "subscription_plans table notice: " . $e->getMessage() . "\n";
    }

    echo "All demo plans removed successfully!\n";
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
