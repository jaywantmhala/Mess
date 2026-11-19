<?php
/**
 * Database migration for PayU Payouts integration
 * Adds payu_beneficiary fields to vendors table and creates vendor_payouts table.
 */

require_once __DIR__ . '/../config/database.php';

function runPayUPayoutMigration() {
    $pdo = getDBConnection();

    try {
        // 1. Add columns to vendors table if missing
        $existingCols = [];
        $stmt = $pdo->query("DESCRIBE vendors");
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $existingCols[] = strtolower($row['Field']);
        }

        $alterQueries = [];

        if (!in_array('payu_beneficiary_id', $existingCols)) {
            $alterQueries[] = "ADD COLUMN `payu_beneficiary_id` VARCHAR(100) NULL DEFAULT NULL AFTER `ifsc_code`";
        }
        if (!in_array('bank_verified', $existingCols)) {
            $alterQueries[] = "ADD COLUMN `bank_verified` TINYINT(1) NOT NULL DEFAULT 0 AFTER `payu_beneficiary_id`";
        }
        if (!in_array('payout_enabled', $existingCols)) {
            $alterQueries[] = "ADD COLUMN `payout_enabled` TINYINT(1) NOT NULL DEFAULT 0 AFTER `bank_verified`";
        }
        if (!in_array('bank_verified_at', $existingCols)) {
            $alterQueries[] = "ADD COLUMN `bank_verified_at` DATETIME NULL DEFAULT NULL AFTER `payout_enabled`";
        }
        if (!in_array('payu_beneficiary_created_at', $existingCols)) {
            $alterQueries[] = "ADD COLUMN `payu_beneficiary_created_at` DATETIME NULL DEFAULT NULL AFTER `bank_verified_at`";
        }

        if (!empty($alterQueries)) {
            $sql = "ALTER TABLE `vendors` " . implode(", ", $alterQueries);
            $pdo->exec($sql);
            echo "[Migration] Updated vendors table with PayU Payout columns.\n";
        } else {
            echo "[Migration] Vendors table already contains PayU Payout columns.\n";
        }

        // 2. Create vendor_payouts table if missing
        $createPayoutsTable = "
            CREATE TABLE IF NOT EXISTS `vendor_payouts` (
                `id`                       INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
                `vendor_id`                INT(11) UNSIGNED NOT NULL,
                `amount`                   DECIMAL(10,2)    NOT NULL DEFAULT 0.00,
                `merchant_ref_id`          VARCHAR(100)     NOT NULL,
                `batch_id`                 VARCHAR(100)     NULL DEFAULT NULL,
                `payu_txn_id`              VARCHAR(100)     NULL DEFAULT NULL,
                `payu_transaction_ref_no` VARCHAR(100)     NULL DEFAULT NULL,
                `bank_transaction_ref_no` VARCHAR(100)     NULL DEFAULT NULL,
                `payment_type`             VARCHAR(20)      NOT NULL DEFAULT 'IMPS',
                `status`                   ENUM('PENDING','PROCESSING','QUEUED','SUCCESS','FAILED','REVERSED') NOT NULL DEFAULT 'PENDING',
                `failure_reason`           TEXT             NULL DEFAULT NULL,
                `initiated_at`             DATETIME         NULL DEFAULT NULL,
                `completed_at`             DATETIME         NULL DEFAULT NULL,
                `created_at`               DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
                `updated_at`               DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`),
                UNIQUE KEY `uq_vendor_payouts_ref` (`merchant_ref_id`),
                KEY `idx_vendor_payouts_vendor_status` (`vendor_id`, `status`),
                KEY `idx_vendor_payouts_created` (`created_at`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
              COMMENT='Vendor payouts settlements tracking via PayU'
        ";
        $pdo->exec($createPayoutsTable);
        echo "[Migration] Created or verified vendor_payouts table.\n";

        return true;
    } catch (PDOException $e) {
        echo "[Migration Error] " . $e->getMessage() . "\n";
        return false;
    }
}

if (basename(__FILE__) === basename($_SERVER['SCRIPT_FILENAME'] ?? '')) {
    runPayUPayoutMigration();
}
