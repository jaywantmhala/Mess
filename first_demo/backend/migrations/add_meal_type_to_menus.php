<?php
/**
 * Migration: Add meal_type to menus table if not present.
 * Values: 'Lunch', 'Dinner' (Default 'Lunch')
 */

require_once __DIR__ . '/../config/database.php';

header('Content-Type: text/plain; charset=utf-8');

try {
    $pdo = getDBConnection();
    
    // Check existing columns in menus table
    $colsStmt = $pdo->query("DESCRIBE menus");
    $columns = $colsStmt->fetchAll(PDO::FETCH_COLUMN);

    if (!in_array('meal_type', $columns)) {
        $pdo->exec("ALTER TABLE `menus` ADD COLUMN `meal_type` ENUM('Lunch','Dinner') NOT NULL DEFAULT 'Lunch' AFTER `image_url`");
        echo "Column 'meal_type' added successfully.\n";
    } else {
        $pdo->exec("UPDATE `menus` SET `meal_type` = 'Lunch' WHERE `meal_type` IS NULL OR `meal_type` = ''");
        $pdo->exec("ALTER TABLE `menus` MODIFY COLUMN `meal_type` ENUM('Lunch','Dinner') NOT NULL DEFAULT 'Lunch'");
        echo "Column 'meal_type' already exists and has been verified/updated.\n";
    }

    // Ensure index on menu_date and meal_type exists
    try {
        $pdo->exec("ALTER TABLE `menus` ADD INDEX `idx_menu_date_meal` (`menu_date`, `meal_type`)");
        echo "Index 'idx_menu_date_meal' added successfully.\n";
    } catch (Exception $idxEx) {
        // Index might already exist
    }

    echo "Migration completed successfully!\n";
} catch (Exception $e) {
    echo "Migration error: " . $e->getMessage() . "\n";
}
