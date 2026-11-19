<?php
/**
 * Migration: Add gst_number and gst_photo_url to hotels table if not present.
 */

require_once __DIR__ . '/../config/database.php';

header('Content-Type: text/plain; charset=utf-8');

try {
    $pdo = getDBConnection();
    
    // Check if columns exist
    $colsStmt = $pdo->query("DESCRIBE hotels");
    $columns = $colsStmt->fetchAll(PDO::FETCH_COLUMN);

    if (!in_array('gst_number', $columns)) {
        $pdo->exec("ALTER TABLE hotels ADD COLUMN gst_number VARCHAR(50) NULL AFTER udyam_aadhar_photo_url");
        echo "Column 'gst_number' added successfully.\n";
    } else {
        echo "Column 'gst_number' already exists.\n";
    }

    if (!in_array('gst_photo_url', $columns)) {
        $pdo->exec("ALTER TABLE hotels ADD COLUMN gst_photo_url VARCHAR(255) NULL AFTER gst_number");
        echo "Column 'gst_photo_url' added successfully.\n";
    } else {
        echo "Column 'gst_photo_url' already exists.\n";
    }

    echo "Migration completed successfully!\n";
} catch (Exception $e) {
    echo "Migration error: " . $e->getMessage() . "\n";
}
