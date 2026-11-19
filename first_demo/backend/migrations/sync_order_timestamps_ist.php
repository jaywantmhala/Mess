<?php
/**
 * Migration: sync_order_timestamps_ist.php
 *
 * Ensures:
 * 1. MySQL session and PHP default timezone are set to Asia/Kolkata (IST, +05:30).
 * 2. orders table has created_at with DATETIME DEFAULT CURRENT_TIMESTAMP.
 * 3. idx_orders_created_at index exists on orders(created_at) for optimized date filtering.
 * 4. Displays existing order timestamps and allows optional one-time adjustment for past UTC orders.
 *
 * Usage:
 *   CLI:  php migrations/sync_order_timestamps_ist.php [--convert-past-utc]
 *   HTTP: https://hungrilyfoods.com/migrations/sync_order_timestamps_ist.php[?convert_past_utc=1]
 */

require_once __DIR__ . '/../config/database.php';

if (php_sapi_name() !== 'cli') {
    header('Content-Type: text/plain; charset=utf-8');
}

echo "========================================================\n";
echo " Migration: Sync Orders Timezone & Created At (IST +05:30)\n";
echo "========================================================\n\n";

try {
    $pdo = getDBConnection();

    // ── 1. Check Timezones ──────────────────────────────────────────────────
    $tzRow = $pdo->query("SELECT @@session.time_zone AS session_tz, @@global.time_zone AS global_tz, NOW() AS mysql_now")->fetch(PDO::FETCH_ASSOC);
    $phpTz = date_default_timezone_get();
    $phpNow = date('Y-m-d H:i:s');

    echo "[1] TIMEZONE VERIFICATION:\n";
    echo "    PHP default timezone:     $phpTz\n";
    echo "    PHP current time (IST):   $phpNow\n";
    echo "    MySQL session time_zone:  {$tzRow['session_tz']}\n";
    echo "    MySQL global time_zone:   {$tzRow['global_tz']}\n";
    echo "    MySQL current time (NOW): {$tzRow['mysql_now']}\n";

    if ($tzRow['session_tz'] === '+05:30' && $phpTz === 'Asia/Kolkata') {
        echo "    [OK] Timezones are synchronized to Indian Standard Time (IST).\n\n";
    } else {
        echo "    [WARNING] Timezone mismatch detected. Re-applying SET time_zone = '+05:30'...\n";
        $pdo->exec("SET time_zone = '+05:30'");
        date_default_timezone_set('Asia/Kolkata');
        echo "    [OK] Timezone re-applied.\n\n";
    }

    // ── 2. Check and Optimize orders table columns & indexes ────────────────
    echo "[2] SCHEMA VERIFICATION:\n";
    $cols = $pdo->query("DESCRIBE orders")->fetchAll(PDO::FETCH_ASSOC);
    $colNames = array_column($cols, 'Field');

    if (!in_array('created_at', $colNames)) {
        $pdo->exec("ALTER TABLE `orders` ADD COLUMN `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP AFTER `status`");
        echo "    [OK] Added missing created_at column to orders table.\n";
    } else {
        echo "    [OK] created_at column exists in orders table.\n";
    }

    if (!in_array('updated_at', $colNames)) {
        $pdo->exec("ALTER TABLE `orders` ADD COLUMN `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER `created_at`");
        echo "    [OK] Added missing updated_at column to orders table.\n";
    } else {
        echo "    [OK] updated_at column exists in orders table.\n";
    }

    // Ensure index on created_at exists for fast date-based queries
    $indexes = $pdo->query("SHOW INDEX FROM `orders` WHERE Key_name = 'idx_orders_created_at'")->fetchAll(PDO::FETCH_ASSOC);
    if (empty($indexes)) {
        try {
            $pdo->exec("ALTER TABLE `orders` ADD INDEX `idx_orders_created_at` (`created_at`)");
            echo "    [OK] Added index idx_orders_created_at on orders(created_at).\n";
        } catch (Exception $e) {
            echo "    [SKIP] Could not add index: " . $e->getMessage() . "\n";
        }
    } else {
        echo "    [OK] Index idx_orders_created_at already exists.\n";
    }

    echo "\n";

    // ── 3. Inspect recent order timestamps ──────────────────────────────────
    echo "[3] RECENT ORDERS (LATEST 10):\n";
    $stmt = $pdo->query("
        SELECT o.order_id, o.customer_id, o.hotel_id, o.meal_type, o.created_at, o.status,
               COALESCE(h.hotel_name, 'N/A') AS hotel_name
        FROM orders o
        LEFT JOIN hotels h ON o.hotel_id = h.id
        ORDER BY o.order_id DESC
        LIMIT 10
    ");
    $recent = $stmt->fetchAll(PDO::FETCH_ASSOC);

    if (empty($recent)) {
        echo "    No orders found in database.\n";
    } else {
        foreach ($recent as $ord) {
            $raw = $ord['created_at'];
            $dt = new DateTime($raw);
            $formatted = $dt->format('d/m/Y, h:i A');
            echo "    Order #{$ord['order_id']} | Hotel: {$ord['hotel_name']} | Meal: {$ord['meal_type']} | Status: {$ord['status']} | DB: $raw | Display: $formatted\n";
        }
    }
    echo "\n";

    // ── 4. Optional: Adjust past UTC orders if requested ────────────────────
    $isConvertRequested = false;
    if (php_sapi_name() === 'cli') {
        global $argv;
        $isConvertRequested = isset($argv) && in_array('--convert-past-utc', $argv);
    } else {
        $isConvertRequested = !empty($_GET['convert_past_utc']) && $_GET['convert_past_utc'] === '1';
    }

    if ($isConvertRequested) {
        echo "[4] PAST UTC TIMESTAMP ADJUSTMENT:\n";
        echo "    Converting older orders created before IST enforcement (+5:30)...\n";
        // Only adjust orders where created_at is earlier than today's fix date
        $cutoffDate = date('Y-m-d H:i:s');
        $updStmt = $pdo->prepare("
            UPDATE orders 
            SET created_at = DATE_ADD(created_at, INTERVAL '5:30' HOUR_MINUTE)
            WHERE created_at < ?
        ");
        $updStmt->execute([$cutoffDate]);
        $affected = $updStmt->rowCount();
        echo "    [OK] Adjusted $affected past orders by +5 hours 30 minutes to match IST.\n\n";
    } else {
        echo "[4] PAST UTC TIMESTAMP ADJUSTMENT (INFO):\n";
        echo "    Past orders created before this fix remain as recorded in DB.\n";
        echo "    To convert older UTC order timestamps by +5:30 to IST, run with:\n";
        echo "      CLI:  php migrations/sync_order_timestamps_ist.php --convert-past-utc\n";
        echo "      HTTP: ?convert_past_utc=1\n\n";
    }

    echo "========================================================\n";
    echo " Migration completed successfully!\n";
    echo "========================================================\n";

} catch (Exception $e) {
    echo "\n[ERROR] Migration failed: " . $e->getMessage() . "\n";
    exit(1);
}
