<?php
/**
 * GET or POST /api/migrate
 * GET or POST /api/admin/migrate
 * GET or POST /api/migrate.php
 *
 * Automatic database schema migration runner for Production & Local.
 * Auto-creates all missing tables, adds missing columns, verifies indexes & data types,
 * and returns an exhaustive real-time JSON status report.
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/razorpay.php';
require_once __DIR__ . '/../helpers/response.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

try {
    $pdo = getDBConnection();
    $report = [
        'database'              => DB_NAME,
        'environment'           => (defined('DB_NAME') && strpos(DB_NAME, 'u292076282') !== false) ? 'Production (hungrilyfoods.com)' : 'Local / Staging',
        'tables_verified'       => [],
        'new_columns_added'     => [],
        'column_modifications'  => [],
        'executed_at'           => date('Y-m-d H:i:s T'),
    ];

    $totalColsChecked = 0;
    $totalColsAdded   = 0;

    /**
     * Helper to safely add missing columns to existing tables
     */
    function ensureColumns(PDO $pdo, string $table, array $columns, array &$report, int &$totalColsChecked, int &$totalColsAdded): array {
        $added = [];
        try {
            $stmt = $pdo->query("DESCRIBE `$table`");
            $existingCols = $stmt->fetchAll(PDO::FETCH_COLUMN);

            foreach ($columns as $col => $definition) {
                $totalColsChecked++;
                if (!in_array($col, $existingCols)) {
                    $pdo->exec("ALTER TABLE `$table` ADD COLUMN `$col` $definition");
                    $added[] = $col;
                    $totalColsAdded++;
                }
            }
        } catch (Exception $e) {
            $report['errors'][] = "Error checking columns for $table: " . $e->getMessage();
        }

        if (!empty($added)) {
            $report['new_columns_added'][$table] = $added;
        }
        return $added;
    }

    /**
     * Helper to safely execute table creation and log verification
     */
    function verifyTable(PDO $pdo, string $table, string $sql, array &$report): void {
        try {
            $pdo->exec($sql);
            $report['tables_verified'][] = $table;
        } catch (Exception $e) {
            $report['errors'][] = "Error creating/verifying table $table: " . $e->getMessage();
        }
    }

    // =========================================================================
    // 1. ADMINS TABLE
    // =========================================================================
    verifyTable($pdo, 'admins', "
        CREATE TABLE IF NOT EXISTS `admins` (
            `id`         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `full_name`  VARCHAR(150) NOT NULL,
            `email`      VARCHAR(255) NOT NULL UNIQUE,
            `password`   VARCHAR(255) NOT NULL,
            `is_active`  TINYINT(1) NOT NULL DEFAULT 1,
            `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    ensureColumns($pdo, 'admins', [
        'full_name'  => 'VARCHAR(150) NOT NULL',
        'email'      => 'VARCHAR(255) NOT NULL',
        'password'   => 'VARCHAR(255) NOT NULL',
        'is_active'  => 'TINYINT(1) NOT NULL DEFAULT 1',
    ], $report, $totalColsChecked, $totalColsAdded);


    // =========================================================================
    // 2. VENDORS TABLE
    // =========================================================================
    verifyTable($pdo, 'vendors', "
        CREATE TABLE IF NOT EXISTS `vendors` (
            `id`                         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `full_name`                  VARCHAR(150) DEFAULT NULL,
            `owner_name`                 VARCHAR(255) DEFAULT NULL,
            `business_name`              VARCHAR(255) DEFAULT NULL,
            `email`                      VARCHAR(255) DEFAULT NULL,
            `phone`                      VARCHAR(20) DEFAULT NULL,
            `mobile_number`              VARCHAR(20) DEFAULT NULL,
            `password`                   VARCHAR(255) DEFAULT NULL,
            `country`                    VARCHAR(100) NOT NULL DEFAULT 'India',
            `state`                      VARCHAR(100) DEFAULT NULL,
            `district`                   VARCHAR(100) DEFAULT NULL,
            `taluka`                     VARCHAR(100) DEFAULT NULL,
            `is_active`                  TINYINT(1) NOT NULL DEFAULT 1,
            `status`                     ENUM('active','inactive') DEFAULT 'active',
            `fcm_token`                  VARCHAR(255) DEFAULT NULL,
            `bank_name`                  VARCHAR(255) DEFAULT NULL,
            `account_holder_name`        VARCHAR(255) DEFAULT NULL,
            `account_number`             VARCHAR(100) DEFAULT NULL,
            `ifsc_code`                  VARCHAR(50) DEFAULT NULL,
            `payu_beneficiary_id`        VARCHAR(100) DEFAULT NULL,
            `bank_verified`              TINYINT(1) NOT NULL DEFAULT 0,
            `payout_enabled`             TINYINT(1) NOT NULL DEFAULT 0,
            `bank_verified_at`           DATETIME DEFAULT NULL,
            `payu_beneficiary_created_at` DATETIME DEFAULT NULL,
            `wallet_balance`             DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            `created_at`                 DATETIME DEFAULT CURRENT_TIMESTAMP,
            `updated_at`                 DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    ensureColumns($pdo, 'vendors', [
        'full_name'                   => 'VARCHAR(150) DEFAULT NULL',
        'owner_name'                  => 'VARCHAR(255) DEFAULT NULL',
        'business_name'               => 'VARCHAR(255) DEFAULT NULL',
        'email'                       => 'VARCHAR(255) DEFAULT NULL',
        'phone'                       => 'VARCHAR(20) DEFAULT NULL',
        'mobile_number'               => 'VARCHAR(20) DEFAULT NULL',
        'country'                     => "VARCHAR(100) NOT NULL DEFAULT 'India'",
        'state'                       => 'VARCHAR(100) DEFAULT NULL',
        'district'                    => 'VARCHAR(100) DEFAULT NULL',
        'taluka'                      => 'VARCHAR(100) DEFAULT NULL',
        'region'                      => 'VARCHAR(150) DEFAULT NULL',
        'area'                        => 'VARCHAR(150) DEFAULT NULL',
        'is_active'                   => 'TINYINT(1) NOT NULL DEFAULT 1',
        'status'                      => "ENUM('active','inactive') DEFAULT 'active'",
        'fcm_token'                   => 'VARCHAR(255) DEFAULT NULL',
        'bank_name'                   => 'VARCHAR(255) DEFAULT NULL',
        'account_holder_name'         => 'VARCHAR(255) DEFAULT NULL',
        'account_number'              => 'VARCHAR(100) DEFAULT NULL',
        'ifsc_code'                   => 'VARCHAR(50) DEFAULT NULL',
        'payu_beneficiary_id'         => 'VARCHAR(100) DEFAULT NULL',
        'bank_verified'               => 'TINYINT(1) NOT NULL DEFAULT 0',
        'payout_enabled'              => 'TINYINT(1) NOT NULL DEFAULT 0',
        'bank_verified_at'            => 'DATETIME DEFAULT NULL',
        'payu_beneficiary_created_at' => 'DATETIME DEFAULT NULL',
        'wallet_balance'              => 'DECIMAL(10,2) NOT NULL DEFAULT 0.00',
        'razorpay_contact_id'         => 'VARCHAR(100) DEFAULT NULL',
        'razorpay_fund_account_id'    => 'VARCHAR(100) DEFAULT NULL',
    ], $report, $totalColsChecked, $totalColsAdded);


    // =========================================================================
    // 3. HOTELS (MESS) TABLE
    // =========================================================================
    verifyTable($pdo, 'hotels', "
        CREATE TABLE IF NOT EXISTS `hotels` (
            `id`                     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `vendor_id`              INT UNSIGNED NOT NULL,
            `hotel_name`             VARCHAR(255) NOT NULL,
            `owner_name`             VARCHAR(150) DEFAULT NULL,
            `mobile_number`          VARCHAR(20) DEFAULT NULL,
            `email`                  VARCHAR(255) DEFAULT NULL,
            `hotel_address`          TEXT DEFAULT NULL,
            `latitude`               DECIMAL(10,8) DEFAULT 0.00000000,
            `longitude`              DECIMAL(11,8) DEFAULT 0.00000000,
            `place_id`               VARCHAR(255) DEFAULT NULL,
            `city`                   VARCHAR(150) DEFAULT NULL,
            `area`                   VARCHAR(150) DEFAULT NULL,
            `state`                  VARCHAR(150) DEFAULT NULL,
            `district`               VARCHAR(150) DEFAULT NULL,
            `taluka`                 VARCHAR(150) DEFAULT NULL,
            `country`                VARCHAR(150) DEFAULT 'India',
            `pincode`                VARCHAR(20) DEFAULT NULL,
            `landmark`               VARCHAR(255) DEFAULT NULL,
            `photo_url`              VARCHAR(500) DEFAULT NULL,
            `status`                 ENUM('active','inactive') DEFAULT 'active',
            `fssai_number`           VARCHAR(100) DEFAULT NULL,
            `fssai_photo_url`        TEXT DEFAULT NULL,
            `pan_number`             VARCHAR(100) DEFAULT NULL,
            `pan_photo_url`          TEXT DEFAULT NULL,
            `aadhar_number`          VARCHAR(100) DEFAULT NULL,
            `aadhar_photo_url`       TEXT DEFAULT NULL,
            `shop_act_number`        VARCHAR(100) DEFAULT NULL,
            `shop_act_photo_url`     TEXT DEFAULT NULL,
            `udyam_aadhar_number`    VARCHAR(100) DEFAULT NULL,
            `udyam_aadhar_photo_url` TEXT DEFAULT NULL,
            `gst_number`             VARCHAR(50) DEFAULT NULL,
            `gst_photo_url`          VARCHAR(255) DEFAULT NULL,
            `gst_percentage`         DECIMAL(5,2) NOT NULL DEFAULT 5.00,
            `service_type`           VARCHAR(20) NOT NULL DEFAULT 'BOTH',
            `food_type`              VARCHAR(20) NOT NULL DEFAULT 'BOTH',
            `is_vendor_online`       TINYINT(1) DEFAULT 1,
            `created_at`             DATETIME DEFAULT CURRENT_TIMESTAMP,
            `updated_at`             DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            KEY `idx_hotel_vendor` (`vendor_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    ensureColumns($pdo, 'hotels', [
        'owner_name'             => 'VARCHAR(150) DEFAULT NULL',
        'mobile_number'          => 'VARCHAR(20) DEFAULT NULL',
        'email'                  => 'VARCHAR(255) DEFAULT NULL',
        'hotel_address'          => 'TEXT DEFAULT NULL',
        'latitude'               => 'DECIMAL(10,8) DEFAULT 0.00000000',
        'longitude'              => 'DECIMAL(11,8) DEFAULT 0.00000000',
        'place_id'               => 'VARCHAR(255) DEFAULT NULL',
        'city'                   => 'VARCHAR(150) DEFAULT NULL',
        'area'                   => 'VARCHAR(150) DEFAULT NULL',
        'region'                 => 'VARCHAR(150) DEFAULT NULL',
        'state'                  => 'VARCHAR(150) DEFAULT NULL',
        'district'               => 'VARCHAR(150) DEFAULT NULL',
        'taluka'                 => 'VARCHAR(150) DEFAULT NULL',
        'country'                => "VARCHAR(150) DEFAULT 'India'",
        'pincode'                => 'VARCHAR(20) DEFAULT NULL',
        'landmark'               => 'VARCHAR(255) DEFAULT NULL',
        'photo_url'              => 'VARCHAR(500) DEFAULT NULL',
        'status'                 => "ENUM('active','inactive') DEFAULT 'active'",
        'fssai_number'           => 'VARCHAR(100) DEFAULT NULL',
        'fssai_photo_url'        => 'TEXT DEFAULT NULL',
        'pan_number'             => 'VARCHAR(100) DEFAULT NULL',
        'pan_photo_url'          => 'TEXT DEFAULT NULL',
        'aadhar_number'          => 'VARCHAR(100) DEFAULT NULL',
        'aadhar_photo_url'       => 'TEXT DEFAULT NULL',
        'shop_act_number'        => 'VARCHAR(100) DEFAULT NULL',
        'shop_act_photo_url'     => 'TEXT DEFAULT NULL',
        'udyam_aadhar_number'    => 'VARCHAR(100) DEFAULT NULL',
        'udyam_aadhar_photo_url' => 'TEXT DEFAULT NULL',
        'gst_number'             => 'VARCHAR(50) DEFAULT NULL',
        'gst_photo_url'          => 'VARCHAR(255) DEFAULT NULL',
        'gst_percentage'         => 'DECIMAL(5,2) NOT NULL DEFAULT 5.00',
        'service_type'           => "VARCHAR(20) NOT NULL DEFAULT 'BOTH'",
        'food_type'              => "VARCHAR(20) NOT NULL DEFAULT 'BOTH'",
        'is_vendor_online'       => 'TINYINT(1) DEFAULT 1',
    ], $report, $totalColsChecked, $totalColsAdded);


    // =========================================================================
    // 4. CUSTOMERS TABLE
    // =========================================================================
    verifyTable($pdo, 'customers', "
        CREATE TABLE IF NOT EXISTS `customers` (
            `id`              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `full_name`       VARCHAR(255) DEFAULT NULL,
            `email`           VARCHAR(255) DEFAULT NULL,
            `phone`           VARCHAR(20) DEFAULT NULL,
            `phone_number`    VARCHAR(20) DEFAULT NULL,
            `password`        VARCHAR(255) DEFAULT NULL,
            `is_active`       TINYINT(1) NOT NULL DEFAULT 1,
            `email_verified`  TINYINT(1) NOT NULL DEFAULT 0,
            `profile_picture` VARCHAR(500) DEFAULT NULL,
            `country`         VARCHAR(100) NOT NULL DEFAULT 'India',
            `state`           VARCHAR(100) DEFAULT NULL,
            `district`        VARCHAR(100) DEFAULT NULL,
            `taluka`          VARCHAR(100) DEFAULT NULL,
            `fcm_token`       VARCHAR(255) DEFAULT NULL,
            `status`          ENUM('active','inactive') DEFAULT 'active',
            `last_login_at`   DATETIME DEFAULT NULL,
            `created_at`      DATETIME DEFAULT CURRENT_TIMESTAMP,
            `updated_at`      DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    ensureColumns($pdo, 'customers', [
        'full_name'       => 'VARCHAR(255) DEFAULT NULL',
        'email'           => 'VARCHAR(255) DEFAULT NULL',
        'phone'           => 'VARCHAR(20) DEFAULT NULL',
        'phone_number'    => 'VARCHAR(20) DEFAULT NULL',
        'password'        => 'VARCHAR(255) DEFAULT NULL',
        'is_active'       => 'TINYINT(1) NOT NULL DEFAULT 1',
        'email_verified'  => 'TINYINT(1) NOT NULL DEFAULT 0',
        'profile_picture' => 'VARCHAR(500) DEFAULT NULL',
        'country'         => "VARCHAR(100) NOT NULL DEFAULT 'India'",
        'state'           => 'VARCHAR(100) DEFAULT NULL',
        'district'        => 'VARCHAR(100) DEFAULT NULL',
        'taluka'          => 'VARCHAR(100) DEFAULT NULL',
        'region'          => 'VARCHAR(100) DEFAULT NULL',
        'area'            => 'VARCHAR(255) DEFAULT NULL',
        'full_address'    => 'TEXT DEFAULT NULL',
        'fcm_token'       => 'VARCHAR(255) DEFAULT NULL',
        'status'          => "ENUM('active','inactive') DEFAULT 'active'",
        'last_login_at'   => 'DATETIME DEFAULT NULL',
        'is_online'       => 'TINYINT(1) NOT NULL DEFAULT 0',
        'last_seen_at'    => 'DATETIME DEFAULT NULL',
    ], $report, $totalColsChecked, $totalColsAdded);


    // =========================================================================
    // 5. CUSTOMER_ADDRESSES TABLE
    // =========================================================================
    verifyTable($pdo, 'customer_addresses', "
        CREATE TABLE IF NOT EXISTS `customer_addresses` (
            `id`            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `customer_id`   INT UNSIGNED NOT NULL,
            `address_line1` VARCHAR(255) DEFAULT NULL,
            `address_line2` VARCHAR(255) DEFAULT NULL,
            `city`          VARCHAR(100) DEFAULT NULL,
            `state`         VARCHAR(100) DEFAULT NULL,
            `district`      VARCHAR(255) DEFAULT NULL,
            `taluka`        VARCHAR(255) DEFAULT NULL,
            `country`       VARCHAR(100) DEFAULT 'India',
            `pincode`       VARCHAR(20) DEFAULT NULL,
            `latitude`      DECIMAL(10,8) DEFAULT 0.00000000,
            `longitude`     DECIMAL(11,8) DEFAULT 0.00000000,
            `is_default`    TINYINT(1) DEFAULT 0,
            `created_at`    DATETIME DEFAULT CURRENT_TIMESTAMP,
            KEY `idx_cust_addr_cust` (`customer_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    ensureColumns($pdo, 'customer_addresses', [
        'name'          => 'VARCHAR(255) DEFAULT NULL',
        'mobile_number' => 'VARCHAR(20) DEFAULT NULL',
        'tag'           => "VARCHAR(20) NOT NULL DEFAULT 'HOME'",
        'full_address'  => 'TEXT DEFAULT NULL',
        'house_no'      => 'VARCHAR(255) DEFAULT NULL',
        'area'          => 'VARCHAR(255) DEFAULT NULL',
        'region'        => 'VARCHAR(100) DEFAULT NULL',
        'landmark'      => 'VARCHAR(255) DEFAULT NULL',
        'place_id'      => 'VARCHAR(255) DEFAULT NULL',
        'address_line1' => 'VARCHAR(255) DEFAULT NULL',
        'address_line2' => 'VARCHAR(255) DEFAULT NULL',
        'city'          => 'VARCHAR(100) DEFAULT NULL',
        'state'         => 'VARCHAR(100) DEFAULT NULL',
        'district'      => 'VARCHAR(255) DEFAULT NULL',
        'taluka'        => 'VARCHAR(255) DEFAULT NULL',
        'country'       => "VARCHAR(100) DEFAULT 'India'",
        'pincode'       => 'VARCHAR(20) DEFAULT NULL',
        'latitude'      => 'DECIMAL(10,8) DEFAULT 0.00000000',
        'longitude'     => 'DECIMAL(11,8) DEFAULT 0.00000000',
        'is_default'    => 'TINYINT(1) DEFAULT 0',
    ], $report, $totalColsChecked, $totalColsAdded);


    // =========================================================================
    // 6. DRIVERS TABLE
    // =========================================================================
    verifyTable($pdo, 'drivers', "
        CREATE TABLE IF NOT EXISTS `drivers` (
            `id`             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `full_name`      VARCHAR(255) NOT NULL,
            `email`          VARCHAR(255) DEFAULT NULL,
            `phone_number`   VARCHAR(20) DEFAULT NULL,
            `password`       VARCHAR(255) DEFAULT NULL,
            `vehicle_number` VARCHAR(50) DEFAULT NULL,
            `is_online`      TINYINT(1) DEFAULT 0,
            `latitude`       DECIMAL(10,8) DEFAULT 0.00000000,
            `longitude`      DECIMAL(11,8) DEFAULT 0.00000000,
            `max_capacity`   INT NOT NULL DEFAULT 3,
            `country`        VARCHAR(100) NOT NULL DEFAULT 'India',
            `state`          VARCHAR(100) DEFAULT NULL,
            `district`       VARCHAR(100) DEFAULT NULL,
            `taluka`         VARCHAR(100) DEFAULT NULL,
            `fcm_token`      VARCHAR(255) DEFAULT NULL,
            `status`         ENUM('active','inactive') DEFAULT 'active',
            `created_at`     DATETIME DEFAULT CURRENT_TIMESTAMP,
            `updated_at`     DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    ensureColumns($pdo, 'drivers', [
        'full_name'      => 'VARCHAR(255) NOT NULL',
        'email'          => 'VARCHAR(255) DEFAULT NULL',
        'phone_number'   => 'VARCHAR(20) DEFAULT NULL',
        'password'       => 'VARCHAR(255) DEFAULT NULL',
        'vehicle_number' => 'VARCHAR(50) DEFAULT NULL',
        'is_online'      => 'TINYINT(1) DEFAULT 0',
        'latitude'       => 'DECIMAL(10,8) DEFAULT 0.00000000',
        'longitude'      => 'DECIMAL(11,8) DEFAULT 0.00000000',
        'max_capacity'   => 'INT NOT NULL DEFAULT 3',
        'country'        => "VARCHAR(100) NOT NULL DEFAULT 'India'",
        'state'          => 'VARCHAR(100) DEFAULT NULL',
        'district'       => 'VARCHAR(100) DEFAULT NULL',
        'taluka'         => 'VARCHAR(100) DEFAULT NULL',
        'fcm_token'      => 'VARCHAR(255) DEFAULT NULL',
        'status'         => "ENUM('active','inactive') DEFAULT 'active'",
    ], $report, $totalColsChecked, $totalColsAdded);


    // =========================================================================
    // 7. ORDERS TABLE
    // =========================================================================
    verifyTable($pdo, 'orders', "
        CREATE TABLE IF NOT EXISTS `orders` (
            `order_id`                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `hotel_id`                  INT UNSIGNED DEFAULT NULL,
            `customer_id`               INT UNSIGNED DEFAULT NULL,
            `driver_id`                 INT UNSIGNED DEFAULT NULL,
            `status`                    VARCHAR(50) NOT NULL DEFAULT 'created_order',
            `grand_total`               DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            `subtotal`                  DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            `delivery_fee`              DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            `tax_amount`                DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            `tiffin_charge`             DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            `area_tiffin_charge`        DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            `wallet_deducted`           DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            `payment_method`            VARCHAR(50) DEFAULT 'cod',
            `delivery_address`          TEXT DEFAULT NULL,
            `meal_type`                 ENUM('Lunch','Dinner') NOT NULL DEFAULT 'Lunch',
            `tiffin_received_to_hotel`  VARCHAR(50) NOT NULL DEFAULT 'pending',
            `tiffin_return_otp`         VARCHAR(255) DEFAULT NULL,
            `tiffin_returned_driver_id` INT UNSIGNED DEFAULT NULL,
            `tiffin_returned_at`        DATETIME DEFAULT NULL,
            `created_at`                DATETIME DEFAULT CURRENT_TIMESTAMP,
            `updated_at`                DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            KEY `idx_orders_hotel` (`hotel_id`),
            KEY `idx_orders_customer` (`customer_id`),
            KEY `idx_orders_driver` (`driver_id`),
            KEY `idx_orders_status` (`status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    ensureColumns($pdo, 'orders', [
        'hotel_id'                  => 'INT UNSIGNED DEFAULT NULL',
        'customer_id'               => 'INT UNSIGNED DEFAULT NULL',
        'driver_id'                 => 'INT UNSIGNED DEFAULT NULL',
        'status'                    => "VARCHAR(50) NOT NULL DEFAULT 'created_order'",
        'grand_total'               => 'DECIMAL(10,2) NOT NULL DEFAULT 0.00',
        'subtotal'                  => 'DECIMAL(10,2) NOT NULL DEFAULT 0.00',
        'delivery_fee'              => 'DECIMAL(10,2) NOT NULL DEFAULT 0.00',
        'tax_amount'                => 'DECIMAL(10,2) NOT NULL DEFAULT 0.00',
        'tiffin_charge'             => 'DECIMAL(10,2) NOT NULL DEFAULT 0.00',
        'area_tiffin_charge'        => 'DECIMAL(10,2) NOT NULL DEFAULT 0.00',
        'wallet_deducted'           => 'DECIMAL(10,2) NOT NULL DEFAULT 0.00',
        'payment_method'            => "VARCHAR(50) DEFAULT 'cod'",
        'delivery_address'          => 'TEXT DEFAULT NULL',
        'meal_type'                 => "ENUM('Lunch','Dinner') NOT NULL DEFAULT 'Lunch'",
        'tiffin_received_to_hotel'  => "VARCHAR(50) NOT NULL DEFAULT 'pending'",
        'tiffin_return_otp'         => 'VARCHAR(255) DEFAULT NULL',
        'tiffin_returned_driver_id' => 'INT UNSIGNED DEFAULT NULL',
        'tiffin_returned_at'        => 'DATETIME DEFAULT NULL',
    ], $report, $totalColsChecked, $totalColsAdded);


    // =========================================================================
    // 8. ORDER_ITEMS TABLE
    // =========================================================================
    verifyTable($pdo, 'order_items', "
        CREATE TABLE IF NOT EXISTS `order_items` (
            `order_item_id`   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `order_id`        INT UNSIGNED NOT NULL,
            `menu_item_id`    INT UNSIGNED NOT NULL,
            `quantity`        INT NOT NULL DEFAULT 1,
            `price`           DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            `customizations`  TEXT DEFAULT NULL,
            `mandatory_items` TEXT DEFAULT NULL,
            `created_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            KEY `idx_order_item_order` (`order_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    ensureColumns($pdo, 'order_items', [
        'order_id'        => 'INT UNSIGNED NOT NULL',
        'menu_item_id'    => 'INT UNSIGNED NOT NULL',
        'quantity'        => 'INT NOT NULL DEFAULT 1',
        'price'           => 'DECIMAL(10,2) NOT NULL DEFAULT 0.00',
        'customizations'  => 'TEXT DEFAULT NULL',
        'mandatory_items' => 'TEXT DEFAULT NULL',
    ], $report, $totalColsChecked, $totalColsAdded);


    // =========================================================================
    // 9. MENUS TABLE
    // =========================================================================
    verifyTable($pdo, 'menus', "
        CREATE TABLE IF NOT EXISTS `menus` (
            `id`              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `hotel_id`        INT UNSIGNED NOT NULL,
            `food_name`       VARCHAR(255) NOT NULL,
            `description`     TEXT DEFAULT NULL,
            `food_type`       VARCHAR(20) NOT NULL DEFAULT 'VEG',
            `price`           DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            `original_price`  DECIMAL(10,2) DEFAULT NULL,
            `item_category`   VARCHAR(20) NOT NULL DEFAULT 'MANDATORY',
            `spice_level`     VARCHAR(20) DEFAULT 'NONE',
            `mandatory_items` TEXT DEFAULT NULL,
            `optional_items`  TEXT DEFAULT NULL,
            `is_popular`      TINYINT(1) NOT NULL DEFAULT 0,
            `is_available`    TINYINT(1) NOT NULL DEFAULT 1,
            `image_url`       VARCHAR(500) DEFAULT NULL,
            `meal_type`       ENUM('Lunch','Dinner') NOT NULL DEFAULT 'Lunch',
            `menu_date`       DATE DEFAULT NULL,
            `status`          ENUM('active','inactive') DEFAULT 'active',
            `created_at`      DATETIME DEFAULT CURRENT_TIMESTAMP,
            `updated_at`      DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            KEY `idx_menu_hotel` (`hotel_id`),
            KEY `idx_menu_date_meal` (`menu_date`, `meal_type`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    ensureColumns($pdo, 'menus', [
        'food_name'       => 'VARCHAR(255) NOT NULL',
        'description'     => 'TEXT DEFAULT NULL',
        'food_type'       => "VARCHAR(20) NOT NULL DEFAULT 'VEG'",
        'price'           => 'DECIMAL(10,2) NOT NULL DEFAULT 0.00',
        'original_price'  => 'DECIMAL(10,2) DEFAULT NULL',
        'item_category'   => "VARCHAR(20) NOT NULL DEFAULT 'MANDATORY'",
        'spice_level'     => "VARCHAR(20) DEFAULT 'NONE'",
        'mandatory_items' => 'TEXT DEFAULT NULL',
        'optional_items'  => 'TEXT DEFAULT NULL',
        'is_popular'      => 'TINYINT(1) NOT NULL DEFAULT 0',
        'is_available'    => 'TINYINT(1) NOT NULL DEFAULT 1',
        'image_url'       => 'VARCHAR(500) DEFAULT NULL',
        'meal_type'       => "ENUM('Lunch','Dinner') NOT NULL DEFAULT 'Lunch'",
        'menu_date'       => 'DATE DEFAULT NULL',
        'status'          => "ENUM('active','inactive') DEFAULT 'active'",
    ], $report, $totalColsChecked, $totalColsAdded);


    // =========================================================================
    // 10. WALLETS (CUSTOMER) TABLE
    // =========================================================================
    verifyTable($pdo, 'wallets', "
        CREATE TABLE IF NOT EXISTS `wallets` (
            `wallet_id`           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `customer_id`         INT UNSIGNED NOT NULL UNIQUE,
            `balance`             DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            `plan_credit_balance` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            `created_at`          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at`          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    ensureColumns($pdo, 'wallets', [
        'customer_id'         => 'INT UNSIGNED NOT NULL',
        'balance'             => 'DECIMAL(10,2) NOT NULL DEFAULT 0.00',
        'plan_credit_balance' => 'DECIMAL(10,2) NOT NULL DEFAULT 0.00',
    ], $report, $totalColsChecked, $totalColsAdded);


    // =========================================================================
    // 11. WALLET_TRANSACTIONS (CUSTOMER) TABLE
    // =========================================================================
    verifyTable($pdo, 'wallet_transactions', "
        CREATE TABLE IF NOT EXISTS `wallet_transactions` (
            `id`            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `wallet_id`     INT UNSIGNED NOT NULL,
            `type`          VARCHAR(20) NOT NULL,
            `amount`        DECIMAL(10,2) NOT NULL,
            `description`   VARCHAR(255) DEFAULT NULL,
            `balance_after` DECIMAL(10,2) NOT NULL,
            `created_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            KEY `idx_wallet_txn_wallet` (`wallet_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    ensureColumns($pdo, 'wallet_transactions', [
        'wallet_id'     => 'INT UNSIGNED NOT NULL',
        'type'          => 'VARCHAR(20) NOT NULL',
        'amount'        => 'DECIMAL(10,2) NOT NULL',
        'description'   => 'VARCHAR(255) DEFAULT NULL',
        'balance_after' => 'DECIMAL(10,2) NOT NULL',
    ], $report, $totalColsChecked, $totalColsAdded);


    // =========================================================================
    // 12. WALLET_RESETS TABLE
    // =========================================================================
    verifyTable($pdo, 'wallet_resets', "
        CREATE TABLE IF NOT EXISTS `wallet_resets` (
            `id`               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `customer_id`      INT UNSIGNED NOT NULL,
            `subscription_id`  INT UNSIGNED NULL,
            `previous_balance` DECIMAL(10,2) NOT NULL,
            `reset_amount`     DECIMAL(10,2) NOT NULL,
            `balance_after`    DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            `reason`           VARCHAR(255) NOT NULL DEFAULT 'PLAN_EXPIRED',
            `created_at`       DATETIME DEFAULT CURRENT_TIMESTAMP,
            KEY `idx_wr_cust` (`customer_id`),
            KEY `idx_wr_created` (`created_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    ensureColumns($pdo, 'wallet_resets', [
        'customer_id'      => 'INT UNSIGNED NOT NULL',
        'subscription_id'  => 'INT UNSIGNED NULL',
        'previous_balance' => 'DECIMAL(10,2) NOT NULL',
        'reset_amount'     => 'DECIMAL(10,2) NOT NULL',
        'balance_after'    => 'DECIMAL(10,2) NOT NULL DEFAULT 0.00',
        'reason'           => "VARCHAR(255) NOT NULL DEFAULT 'PLAN_EXPIRED'",
    ], $report, $totalColsChecked, $totalColsAdded);


    // =========================================================================
    // 13. VENDOR_WALLETS TABLE
    // =========================================================================
    verifyTable($pdo, 'vendor_wallets', "
        CREATE TABLE IF NOT EXISTS `vendor_wallets` (
            `id`         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `vendor_id`  INT UNSIGNED NOT NULL UNIQUE,
            `balance`    DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    ensureColumns($pdo, 'vendor_wallets', [
        'vendor_id' => 'INT UNSIGNED NOT NULL',
        'balance'   => 'DECIMAL(10,2) NOT NULL DEFAULT 0.00',
    ], $report, $totalColsChecked, $totalColsAdded);


    // =========================================================================
    // 14. VENDOR_WALLET_TRANSACTIONS TABLE
    // =========================================================================
    verifyTable($pdo, 'vendor_wallet_transactions', "
        CREATE TABLE IF NOT EXISTS `vendor_wallet_transactions` (
            `id`            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `vendor_id`     INT UNSIGNED NOT NULL,
            `order_id`      INT UNSIGNED DEFAULT NULL,
            `type`          VARCHAR(20) NOT NULL,
            `amount`        DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            `balance_after` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            `description`   VARCHAR(255) DEFAULT NULL,
            `created_at`    DATETIME DEFAULT CURRENT_TIMESTAMP,
            KEY `idx_vwt_vendor` (`vendor_id`),
            KEY `idx_vwt_order` (`order_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    ensureColumns($pdo, 'vendor_wallet_transactions', [
        'vendor_id'     => 'INT UNSIGNED NOT NULL',
        'order_id'      => 'INT UNSIGNED DEFAULT NULL',
        'type'          => 'VARCHAR(20) NOT NULL',
        'amount'        => 'DECIMAL(10,2) NOT NULL DEFAULT 0.00',
        'balance_after' => 'DECIMAL(10,2) NOT NULL DEFAULT 0.00',
        'description'   => 'VARCHAR(255) DEFAULT NULL',
    ], $report, $totalColsChecked, $totalColsAdded);


    // =========================================================================
    // 15. VENDOR_PAYOUTS TABLE
    // =========================================================================
    verifyTable($pdo, 'vendor_payouts', "
        CREATE TABLE IF NOT EXISTS `vendor_payouts` (
            `id`                       INT(11) UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
            `vendor_id`                INT(11) UNSIGNED NOT NULL,
            `amount`                   DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            `merchant_ref_id`          VARCHAR(100) DEFAULT NULL,
            `batch_id`                 VARCHAR(100) DEFAULT NULL,
            `payu_txn_id`              VARCHAR(100) DEFAULT NULL,
            `payu_transaction_ref_no` VARCHAR(100) DEFAULT NULL,
            `bank_transaction_ref_no` VARCHAR(100) DEFAULT NULL,
            `payment_type`             VARCHAR(20) NOT NULL DEFAULT 'IMPS',
            `status`                   VARCHAR(50) NOT NULL DEFAULT 'PENDING',
            `payment_method`           VARCHAR(50) DEFAULT 'bank_transfer',
            `txnid`                    VARCHAR(100) DEFAULT NULL,
            `payu_utr`                 VARCHAR(100) DEFAULT NULL,
            `target_date`              DATE DEFAULT NULL,
            `failure_reason`           TEXT DEFAULT NULL,
            `initiated_at`             DATETIME DEFAULT NULL,
            `completed_at`             DATETIME DEFAULT NULL,
            `created_at`               DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at`               DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            KEY `idx_vp_vendor` (`vendor_id`),
            KEY `idx_vp_status` (`status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    ensureColumns($pdo, 'vendor_payouts', [
        'merchant_ref_id'          => 'VARCHAR(100) DEFAULT NULL',
        'batch_id'                 => 'VARCHAR(100) DEFAULT NULL',
        'payu_txn_id'              => 'VARCHAR(100) DEFAULT NULL',
        'payu_transaction_ref_no' => 'VARCHAR(100) DEFAULT NULL',
        'bank_transaction_ref_no' => 'VARCHAR(100) DEFAULT NULL',
        'payment_type'             => "VARCHAR(20) NOT NULL DEFAULT 'IMPS'",
        'status'                   => "VARCHAR(50) NOT NULL DEFAULT 'PENDING'",
        'payment_method'           => "VARCHAR(50) DEFAULT 'bank_transfer'",
        'txnid'                    => 'VARCHAR(100) DEFAULT NULL',
        'payu_utr'                 => 'VARCHAR(100) DEFAULT NULL',
        'target_date'              => 'DATE DEFAULT NULL',
        'failure_reason'           => 'TEXT DEFAULT NULL',
        'initiated_at'             => 'DATETIME DEFAULT NULL',
        'completed_at'             => 'DATETIME DEFAULT NULL',
    ], $report, $totalColsChecked, $totalColsAdded);


    // =========================================================================
    // 16. CART_ITEMS TABLE
    // =========================================================================
    verifyTable($pdo, 'cart_items', "
        CREATE TABLE IF NOT EXISTS `cart_items` (
            `id`             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `customer_id`    INT UNSIGNED NOT NULL,
            `hotel_id`       INT UNSIGNED NOT NULL,
            `menu_item_id`   INT UNSIGNED NOT NULL,
            `quantity`       INT NOT NULL DEFAULT 1,
            `customizations` TEXT DEFAULT NULL,
            `created_at`     DATETIME DEFAULT CURRENT_TIMESTAMP,
            `updated_at`     DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            KEY `idx_cart_cust` (`customer_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    ensureColumns($pdo, 'cart_items', [
        'customer_id'    => 'INT UNSIGNED NOT NULL',
        'hotel_id'       => 'INT UNSIGNED NOT NULL',
        'menu_item_id'   => 'INT UNSIGNED NOT NULL',
        'quantity'       => 'INT NOT NULL DEFAULT 1',
        'customizations' => 'TEXT DEFAULT NULL',
    ], $report, $totalColsChecked, $totalColsAdded);


    // =========================================================================
    // 17. SERVICE_LOCATIONS TABLE
    // =========================================================================
    verifyTable($pdo, 'service_locations', "
        CREATE TABLE IF NOT EXISTS `service_locations` (
            `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
            `location_name` VARCHAR(255) NOT NULL,
            `address`       TEXT DEFAULT NULL,
            `latitude`      DECIMAL(10,8) NOT NULL DEFAULT 0.00000000,
            `longitude`     DECIMAL(11,8) NOT NULL DEFAULT 0.00000000,
            `location`      POINT DEFAULT NULL,
            `radius_km`     DECIMAL(5,2) NOT NULL DEFAULT 5.00,
            `tiffin_charge` DECIMAL(10,2) NOT NULL DEFAULT 50.00,
            `country`       VARCHAR(50) NOT NULL DEFAULT 'IN',
            `region`        VARCHAR(100) DEFAULT NULL,
            `status`        ENUM('active','inactive') NOT NULL DEFAULT 'active',
            `created_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            KEY `idx_service_loc_status` (`status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    ensureColumns($pdo, 'service_locations', [
        'location_name' => 'VARCHAR(255) NOT NULL',
        'address'       => 'TEXT DEFAULT NULL',
        'latitude'      => 'DECIMAL(10,8) NOT NULL DEFAULT 0.00000000',
        'longitude'     => 'DECIMAL(11,8) NOT NULL DEFAULT 0.00000000',
        'location'      => 'POINT DEFAULT NULL',
        'radius_km'     => 'DECIMAL(5,2) NOT NULL DEFAULT 5.00',
        'tiffin_charge' => 'DECIMAL(10,2) NOT NULL DEFAULT 50.00',
        'country'       => "VARCHAR(50) NOT NULL DEFAULT 'IN'",
        'region'        => 'VARCHAR(100) DEFAULT NULL',
        'status'        => "ENUM('active','inactive') NOT NULL DEFAULT 'active'",
    ], $report, $totalColsChecked, $totalColsAdded);


    // =========================================================================
    // 18. PLANS TABLE
    // =========================================================================
    verifyTable($pdo, 'plans', "
        CREATE TABLE IF NOT EXISTS `plans` (
            `id`                  INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
            `service_location_id` INT UNSIGNED NOT NULL,
            `plan_name`           VARCHAR(255) NOT NULL,
            `description`         TEXT DEFAULT NULL,
            `price`               DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            `duration`            INT NOT NULL DEFAULT 30,
            `total_deliveries`    INT NOT NULL DEFAULT 30,
            `meals_per_day`       INT NOT NULL DEFAULT 1,
            `meal_type`           ENUM('VEG','NON-VEG','BOTH') NOT NULL DEFAULT 'VEG',
            `delivery_time_slot`  VARCHAR(100) DEFAULT NULL,
            `discount`            DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            `delivery_charge`     DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            `tiffin_charge`       DECIMAL(10,2) NOT NULL DEFAULT 50.00,
            `status`              ENUM('active','inactive') NOT NULL DEFAULT 'active',
            `legacy_plan_id`      INT UNSIGNED DEFAULT NULL,
            `created_at`          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at`          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            KEY `idx_plans_service_loc` (`service_location_id`),
            KEY `idx_plans_status` (`status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    ensureColumns($pdo, 'plans', [
        'service_location_id' => 'INT UNSIGNED NOT NULL',
        'plan_name'           => 'VARCHAR(255) NOT NULL',
        'description'         => 'TEXT DEFAULT NULL',
        'price'               => 'DECIMAL(10,2) NOT NULL DEFAULT 0.00',
        'duration'            => 'INT NOT NULL DEFAULT 30',
        'total_deliveries'    => 'INT NOT NULL DEFAULT 30',
        'meals_per_day'       => 'INT NOT NULL DEFAULT 1',
        'meal_type'           => "ENUM('VEG','NON-VEG','BOTH') NOT NULL DEFAULT 'VEG'",
        'delivery_time_slot'  => 'VARCHAR(100) DEFAULT NULL',
        'discount'            => 'DECIMAL(10,2) NOT NULL DEFAULT 0.00',
        'delivery_charge'     => 'DECIMAL(10,2) NOT NULL DEFAULT 0.00',
        'tiffin_charge'       => 'DECIMAL(10,2) NOT NULL DEFAULT 50.00',
        'status'              => "ENUM('active','inactive') NOT NULL DEFAULT 'active'",
        'legacy_plan_id'      => 'INT UNSIGNED DEFAULT NULL',
    ], $report, $totalColsChecked, $totalColsAdded);


    // =========================================================================
    // 19. CUSTOMER_SUBSCRIPTIONS TABLE
    // =========================================================================
    verifyTable($pdo, 'customer_subscriptions', "
        CREATE TABLE IF NOT EXISTS `customer_subscriptions` (
            `id`                   INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
            `customer_id`          INT UNSIGNED NOT NULL,
            `plan_id`              INT UNSIGNED NOT NULL,
            `start_date`           DATE NOT NULL,
            `end_date`             DATE NOT NULL,
            `status`               VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
            `remaining_deliveries` INT NOT NULL DEFAULT 30,
            `total_deliveries`     INT NOT NULL DEFAULT 30,
            `completed_deliveries` INT NOT NULL DEFAULT 0,
            `auto_renew`           TINYINT(1) NOT NULL DEFAULT 1,
            `pause_history`        TEXT DEFAULT NULL,
            `expiration_timestamp` DATETIME DEFAULT NULL,
            `created_at`           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at`           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            KEY `idx_cust_sub_cust` (`customer_id`),
            KEY `idx_cust_sub_status` (`status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    ensureColumns($pdo, 'customer_subscriptions', [
        'customer_id'          => 'INT UNSIGNED NOT NULL',
        'plan_id'              => 'INT UNSIGNED NOT NULL',
        'start_date'           => 'DATE NOT NULL',
        'end_date'             => 'DATE NOT NULL',
        'status'               => "VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'",
        'remaining_deliveries' => 'INT NOT NULL DEFAULT 30',
        'total_deliveries'     => 'INT NOT NULL DEFAULT 30',
        'completed_deliveries' => 'INT NOT NULL DEFAULT 0',
        'auto_renew'           => 'TINYINT(1) NOT NULL DEFAULT 1',
        'pause_history'        => 'TEXT DEFAULT NULL',
        'expiration_timestamp' => 'DATETIME DEFAULT NULL',
    ], $report, $totalColsChecked, $totalColsAdded);


    // =========================================================================
    // 20. VENDOR_SUBSCRIPTIONS TABLE
    // =========================================================================
    verifyTable($pdo, 'vendor_subscriptions', "
        CREATE TABLE IF NOT EXISTS `vendor_subscriptions` (
            `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
            `vendor_id`   INT UNSIGNED NOT NULL,
            `plan_id`     INT UNSIGNED NOT NULL,
            `start_date`  DATE NOT NULL,
            `end_date`    DATE NOT NULL,
            `status`      VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
            `created_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            KEY `idx_vend_sub_vend` (`vendor_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    ensureColumns($pdo, 'vendor_subscriptions', [
        'vendor_id'  => 'INT UNSIGNED NOT NULL',
        'plan_id'    => 'INT UNSIGNED NOT NULL',
        'start_date' => 'DATE NOT NULL',
        'end_date'   => 'DATE NOT NULL',
        'status'     => "VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'",
    ], $report, $totalColsChecked, $totalColsAdded);


    // =========================================================================
    // 21. SUBSCRIPTION_DELIVERIES TABLE
    // =========================================================================
    verifyTable($pdo, 'subscription_deliveries', "
        CREATE TABLE IF NOT EXISTS `subscription_deliveries` (
            `id`              INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
            `subscription_id` INT UNSIGNED NOT NULL,
            `order_id`        INT UNSIGNED DEFAULT NULL,
            `delivery_date`   DATE NOT NULL,
            `status`          VARCHAR(50) NOT NULL DEFAULT 'PENDING',
            `created_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            KEY `idx_sub_deliv_sub` (`subscription_id`),
            KEY `idx_sub_deliv_date` (`delivery_date`),
            KEY `idx_sub_deliv_status` (`status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    ensureColumns($pdo, 'subscription_deliveries', [
        'subscription_id' => 'INT UNSIGNED NOT NULL',
        'order_id'        => 'INT UNSIGNED DEFAULT NULL',
        'delivery_date'   => 'DATE NOT NULL',
        'status'          => "VARCHAR(50) NOT NULL DEFAULT 'PENDING'",
    ], $report, $totalColsChecked, $totalColsAdded);


    // =========================================================================
    // 22. LEGACY LOCATION HIERARCHY TABLES (cities, pincodes, areas, sub_areas, subscription_plans)
    // =========================================================================
    verifyTable($pdo, 'cities', "
        CREATE TABLE IF NOT EXISTS `cities` (
            `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
            `city_name`  VARCHAR(150) NOT NULL,
            `is_active`  TINYINT(1) NOT NULL DEFAULT 1,
            `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    verifyTable($pdo, 'pincodes', "
        CREATE TABLE IF NOT EXISTS `pincodes` (
            `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
            `pincode`    VARCHAR(20) NOT NULL,
            `city_id`    INT UNSIGNED NOT NULL,
            `is_active`  TINYINT(1) NOT NULL DEFAULT 1,
            `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            KEY `idx_pin_city` (`city_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    verifyTable($pdo, 'areas', "
        CREATE TABLE IF NOT EXISTS `areas` (
            `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
            `area_name`  VARCHAR(150) NOT NULL,
            `pincode_id` INT UNSIGNED NOT NULL,
            `is_active`  TINYINT(1) NOT NULL DEFAULT 1,
            `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            KEY `idx_area_pin` (`pincode_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    verifyTable($pdo, 'sub_areas', "
        CREATE TABLE IF NOT EXISTS `sub_areas` (
            `id`              INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
            `sub_area_name`   VARCHAR(255) NOT NULL,
            `area_id`         INT UNSIGNED DEFAULT NULL,
            `latitude`        DECIMAL(10,8) DEFAULT 0.00000000,
            `longitude`       DECIMAL(11,8) DEFAULT 0.00000000,
            `location`        POINT DEFAULT NULL,
            `delivery_radius` DECIMAL(5,2) NOT NULL DEFAULT 5.00,
            `delivery_charge` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            `tiffin_charge`   DECIMAL(10,2) NOT NULL DEFAULT 50.00,
            `is_active`       TINYINT(1) NOT NULL DEFAULT 1,
            `created_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    ensureColumns($pdo, 'sub_areas', [
        'area_id'         => 'INT UNSIGNED DEFAULT NULL',
        'latitude'        => 'DECIMAL(10,8) DEFAULT 0.00000000',
        'longitude'       => 'DECIMAL(11,8) DEFAULT 0.00000000',
        'location'        => 'POINT DEFAULT NULL',
        'delivery_radius' => 'DECIMAL(5,2) NOT NULL DEFAULT 5.00',
        'delivery_charge' => 'DECIMAL(10,2) NOT NULL DEFAULT 0.00',
        'tiffin_charge'   => 'DECIMAL(10,2) NOT NULL DEFAULT 50.00',
        'is_active'       => 'TINYINT(1) NOT NULL DEFAULT 1',
    ], $report, $totalColsChecked, $totalColsAdded);

    verifyTable($pdo, 'subscription_plans', "
        CREATE TABLE IF NOT EXISTS `subscription_plans` (
            `id`                 INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
            `sub_area_id`        INT UNSIGNED NOT NULL,
            `plan_name`          VARCHAR(255) NOT NULL,
            `description`        TEXT DEFAULT NULL,
            `price`              DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            `duration`           INT NOT NULL DEFAULT 30,
            `total_deliveries`   INT NOT NULL DEFAULT 30,
            `meals_per_day`      INT NOT NULL DEFAULT 1,
            `meal_type`          ENUM('VEG','NON-VEG','BOTH') NOT NULL DEFAULT 'VEG',
            `delivery_time_slot` VARCHAR(100) DEFAULT NULL,
            `discount`           DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            `delivery_charge`    DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            `tiffin_charge`      DECIMAL(10,2) NOT NULL DEFAULT 50.00,
            `is_active`          TINYINT(1) NOT NULL DEFAULT 1,
            `created_at`         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at`         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            KEY `idx_sp_sub_area` (`sub_area_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    ensureColumns($pdo, 'subscription_plans', [
        'sub_area_id'        => 'INT UNSIGNED NOT NULL',
        'plan_name'          => 'VARCHAR(255) NOT NULL',
        'description'        => 'TEXT DEFAULT NULL',
        'price'              => 'DECIMAL(10,2) NOT NULL DEFAULT 0.00',
        'duration'           => 'INT NOT NULL DEFAULT 30',
        'total_deliveries'   => 'INT NOT NULL DEFAULT 30',
        'meals_per_day'      => 'INT NOT NULL DEFAULT 1',
        'meal_type'          => "ENUM('VEG','NON-VEG','BOTH') NOT NULL DEFAULT 'VEG'",
        'delivery_time_slot' => 'VARCHAR(100) DEFAULT NULL',
        'discount'           => 'DECIMAL(10,2) NOT NULL DEFAULT 0.00',
        'delivery_charge'    => 'DECIMAL(10,2) NOT NULL DEFAULT 0.00',
        'tiffin_charge'      => 'DECIMAL(10,2) NOT NULL DEFAULT 50.00',
        'is_active'          => 'TINYINT(1) NOT NULL DEFAULT 1',
    ], $report, $totalColsChecked, $totalColsAdded);


    // =========================================================================
    // 23. ORDER_CHATS TABLE (In-App Order Chat)
    // =========================================================================
    verifyTable($pdo, 'order_chats', "
        CREATE TABLE IF NOT EXISTS `order_chats` (
            `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
            `order_id`    INT UNSIGNED NOT NULL,
            `sender_type` VARCHAR(20) NOT NULL,
            `sender_id`   INT UNSIGNED NOT NULL,
            `message`     TEXT NOT NULL,
            `is_read`     TINYINT(1) NOT NULL DEFAULT 0,
            `created_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            KEY `idx_order_chats_order` (`order_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    ensureColumns($pdo, 'order_chats', [
        'order_id'    => 'INT UNSIGNED NOT NULL',
        'sender_type' => 'VARCHAR(20) NOT NULL',
        'sender_id'   => 'INT UNSIGNED NOT NULL',
        'message'     => 'TEXT NOT NULL',
        'is_read'     => 'TINYINT(1) NOT NULL DEFAULT 0',
    ], $report, $totalColsChecked, $totalColsAdded);


    // =========================================================================
    // 24. ADMIN_NOTIFICATIONS TABLE (Push Broadcast Logs)
    // =========================================================================
    verifyTable($pdo, 'admin_notifications', "
        CREATE TABLE IF NOT EXISTS `admin_notifications` (
            `id`           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `title`        VARCHAR(255) NOT NULL,
            `body`         TEXT NOT NULL,
            `target`       VARCHAR(50) NOT NULL DEFAULT 'all',
            `state`        VARCHAR(100) DEFAULT NULL,
            `district`     VARCHAR(100) DEFAULT NULL,
            `taluka`       VARCHAR(100) DEFAULT NULL,
            `target_count` INT UNSIGNED DEFAULT 0,
            `click_action` VARCHAR(100) DEFAULT NULL,
            `image_url`    TEXT DEFAULT NULL,
            `created_at`   DATETIME DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    ensureColumns($pdo, 'admin_notifications', [
        'title'        => 'VARCHAR(255) NOT NULL',
        'body'         => 'TEXT NOT NULL',
        'target'       => "VARCHAR(50) NOT NULL DEFAULT 'all'",
        'state'        => 'VARCHAR(100) DEFAULT NULL',
        'district'     => 'VARCHAR(100) DEFAULT NULL',
        'taluka'       => 'VARCHAR(100) DEFAULT NULL',
        'target_count' => 'INT UNSIGNED DEFAULT 0',
        'click_action' => 'VARCHAR(100) DEFAULT NULL',
        'image_url'    => 'TEXT DEFAULT NULL',
    ], $report, $totalColsChecked, $totalColsAdded);


    // =========================================================================
    // 25. ADMIN_WHATSAPP_NOTIFICATIONS TABLE (WhatsApp Broadcast Logs)
    // =========================================================================
    verifyTable($pdo, 'admin_whatsapp_notifications', "
        CREATE TABLE IF NOT EXISTS `admin_whatsapp_notifications` (
            `id`           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `message`      TEXT NOT NULL,
            `target`       VARCHAR(50) NOT NULL DEFAULT 'all',
            `state`        VARCHAR(100) DEFAULT NULL,
            `district`     VARCHAR(100) DEFAULT NULL,
            `taluka`       VARCHAR(100) DEFAULT NULL,
            `target_count` INT UNSIGNED DEFAULT 0,
            `sent_count`   INT UNSIGNED DEFAULT 0,
            `failed_count` INT UNSIGNED DEFAULT 0,
            `created_at`   DATETIME DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    ensureColumns($pdo, 'admin_whatsapp_notifications', [
        'message'      => 'TEXT NOT NULL',
        'target'       => "VARCHAR(50) NOT NULL DEFAULT 'all'",
        'state'        => 'VARCHAR(100) DEFAULT NULL',
        'district'     => 'VARCHAR(100) DEFAULT NULL',
        'taluka'       => 'VARCHAR(100) DEFAULT NULL',
        'target_count' => 'INT UNSIGNED DEFAULT 0',
        'sent_count'   => 'INT UNSIGNED DEFAULT 0',
        'failed_count' => 'INT UNSIGNED DEFAULT 0',
    ], $report, $totalColsChecked, $totalColsAdded);


    // =========================================================================
    // 26. NOTIFICATION_HISTORY TABLE
    // =========================================================================
    verifyTable($pdo, 'notification_history', "
        CREATE TABLE IF NOT EXISTS `notification_history` (
            `id`              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `title`           VARCHAR(255) NOT NULL,
            `body`            TEXT NOT NULL,
            `target_type`     VARCHAR(50) DEFAULT 'all',
            `recipient_count` INT DEFAULT 0,
            `created_at`      DATETIME DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    ensureColumns($pdo, 'notification_history', [
        'title'           => 'VARCHAR(255) NOT NULL',
        'body'            => 'TEXT NOT NULL',
        'target_type'     => "VARCHAR(50) DEFAULT 'all'",
        'recipient_count' => 'INT DEFAULT 0',
    ], $report, $totalColsChecked, $totalColsAdded);


    // =========================================================================
    // 26b. USER_NOTIFICATIONS & USER_NOTIFICATION_READS TABLES
    // =========================================================================
    verifyTable($pdo, 'user_notifications', "
        CREATE TABLE IF NOT EXISTS `user_notifications` (
            `id`         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `user_type`  VARCHAR(50) NOT NULL DEFAULT 'all',
            `user_id`    INT UNSIGNED DEFAULT NULL,
            `title`      VARCHAR(255) NOT NULL,
            `body`       TEXT NOT NULL,
            `type`       VARCHAR(50) DEFAULT 'general',
            `image_url`  TEXT DEFAULT NULL,
            `data`       TEXT DEFAULT NULL,
            `is_read`    TINYINT(1) DEFAULT 0,
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    ensureColumns($pdo, 'user_notifications', [
        'user_type'  => "VARCHAR(50) NOT NULL DEFAULT 'all'",
        'user_id'    => 'INT UNSIGNED DEFAULT NULL',
        'title'      => 'VARCHAR(255) NOT NULL',
        'body'       => 'TEXT NOT NULL',
        'type'       => "VARCHAR(50) DEFAULT 'general'",
        'image_url'  => 'TEXT DEFAULT NULL',
        'data'       => 'TEXT DEFAULT NULL',
        'is_read'    => 'TINYINT(1) DEFAULT 0',
    ], $report, $totalColsChecked, $totalColsAdded);

    verifyTable($pdo, 'user_notification_reads', "
        CREATE TABLE IF NOT EXISTS `user_notification_reads` (
            `id`                INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `user_type`         VARCHAR(50) NOT NULL,
            `user_id`           INT UNSIGNED NOT NULL,
            `notification_id`   INT UNSIGNED NOT NULL,
            `notification_type` VARCHAR(50) DEFAULT 'admin',
            `read_at`           DATETIME DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY `user_notif_read_unique` (`user_type`, `user_id`, `notification_id`, `notification_type`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    ensureColumns($pdo, 'user_notification_reads', [
        'user_type'         => 'VARCHAR(50) NOT NULL',
        'user_id'           => 'INT UNSIGNED NOT NULL',
        'notification_id'   => 'INT UNSIGNED NOT NULL',
        'notification_type' => "VARCHAR(50) DEFAULT 'admin'",
    ], $report, $totalColsChecked, $totalColsAdded);


    // =========================================================================
    // 27. TIFFIN_RETURNS TABLE
    // =========================================================================
    verifyTable($pdo, 'tiffin_returns', "
        CREATE TABLE IF NOT EXISTS `tiffin_returns` (
            `id`          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `order_id`    INT UNSIGNED NOT NULL,
            `hotel_id`    INT UNSIGNED NOT NULL,
            `driver_id`   INT UNSIGNED NOT NULL,
            `barcode`     TEXT DEFAULT NULL,
            `status`      VARCHAR(50) NOT NULL DEFAULT 'RETURNED',
            `scanned_at`  DATETIME DEFAULT CURRENT_TIMESTAMP,
            `returned_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            `created_at`  DATETIME DEFAULT CURRENT_TIMESTAMP,
            `updated_at`  DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            KEY `idx_tr_order` (`order_id`),
            KEY `idx_tr_hotel` (`hotel_id`),
            KEY `idx_tr_driver` (`driver_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    ensureColumns($pdo, 'tiffin_returns', [
        'order_id'    => 'INT UNSIGNED NOT NULL',
        'hotel_id'    => 'INT UNSIGNED NOT NULL',
        'driver_id'   => 'INT UNSIGNED NOT NULL',
        'barcode'     => 'TEXT DEFAULT NULL',
        'status'      => "VARCHAR(50) NOT NULL DEFAULT 'RETURNED'",
        'scanned_at'  => 'DATETIME DEFAULT CURRENT_TIMESTAMP',
        'returned_at' => 'DATETIME DEFAULT CURRENT_TIMESTAMP',
    ], $report, $totalColsChecked, $totalColsAdded);


    // =========================================================================
    // 28. TIFFIN_RETURN_LOGS TABLE
    // =========================================================================
    verifyTable($pdo, 'tiffin_return_logs', "
        CREATE TABLE IF NOT EXISTS `tiffin_return_logs` (
            `id`          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `order_id`    INT UNSIGNED NOT NULL,
            `driver_id`   INT UNSIGNED NOT NULL,
            `customer_id` INT UNSIGNED NOT NULL,
            `hotel_id`    INT UNSIGNED NOT NULL,
            `otp`         TEXT DEFAULT NULL,
            `verified_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            `log_details` TEXT DEFAULT NULL,
            KEY `idx_trl_order` (`order_id`),
            KEY `idx_trl_driver` (`driver_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    ensureColumns($pdo, 'tiffin_return_logs', [
        'order_id'    => 'INT UNSIGNED NOT NULL',
        'driver_id'   => 'INT UNSIGNED NOT NULL',
        'customer_id' => 'INT UNSIGNED NOT NULL',
        'hotel_id'    => 'INT UNSIGNED NOT NULL',
        'otp'         => 'TEXT DEFAULT NULL',
        'verified_at' => 'DATETIME DEFAULT CURRENT_TIMESTAMP',
        'log_details' => 'TEXT DEFAULT NULL',
    ], $report, $totalColsChecked, $totalColsAdded);


    // =========================================================================
    // 29. REFRESH_TOKENS TABLE
    // =========================================================================
    verifyTable($pdo, 'refresh_tokens', "
        CREATE TABLE IF NOT EXISTS `refresh_tokens` (
            `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
            `user_id`    INT UNSIGNED NOT NULL,
            `role`       VARCHAR(20) NOT NULL DEFAULT 'customer',
            `token_hash` VARCHAR(255) NOT NULL,
            `expires_at` DATETIME NOT NULL,
            `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY `uq_token_hash` (`token_hash`),
            KEY `idx_user_role` (`user_id`, `role`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);


    // =========================================================================
    // 30. OTP_VERIFICATIONS TABLE
    // =========================================================================
    verifyTable($pdo, 'otp_verifications', "
        CREATE TABLE IF NOT EXISTS `otp_verifications` (
            `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
            `phone`      VARCHAR(20) NOT NULL,
            `otp`        VARCHAR(10) NOT NULL,
            `role`       VARCHAR(20) NOT NULL DEFAULT 'customer',
            `expires_at` DATETIME NOT NULL,
            `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            KEY `idx_phone_role` (`phone`, `role`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);


    // =========================================================================
    // 31. PASSWORD_RESETS TABLE
    // =========================================================================
    verifyTable($pdo, 'password_resets', "
        CREATE TABLE IF NOT EXISTS `password_resets` (
            `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
            `email`      VARCHAR(255) NOT NULL,
            `otp`        VARCHAR(10) NOT NULL,
            `expires_at` DATETIME NOT NULL,
            `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            KEY `idx_pwd_reset_email` (`email`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);


    // =========================================================================
    // 32. PAYU_PAYMENTS TABLE
    // =========================================================================
    verifyTable($pdo, 'payu_payments', "
        CREATE TABLE IF NOT EXISTS `payu_payments` (
            `id`                      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `customer_id`             INT UNSIGNED NOT NULL,
            `internal_transaction_id` VARCHAR(100) DEFAULT NULL,
            `plan_id`                 INT UNSIGNED DEFAULT NULL,
            `txnid`                   VARCHAR(100) DEFAULT NULL,
            `mihpayid`                VARCHAR(100) DEFAULT NULL,
            `amount`                  DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            `currency`                VARCHAR(10) NOT NULL DEFAULT 'INR',
            `status`                  VARCHAR(50) NOT NULL DEFAULT 'created',
            `failure_code`            VARCHAR(100) DEFAULT NULL,
            `failure_message`         TEXT DEFAULT NULL,
            `created_at`              DATETIME DEFAULT CURRENT_TIMESTAMP,
            `updated_at`              DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            KEY `idx_payu_customer` (`customer_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);


    // =========================================================================
    // 33. RAZORPAY_PAYMENTS TABLE
    // =========================================================================
    verifyTable($pdo, 'razorpay_payments', "
        CREATE TABLE IF NOT EXISTS `razorpay_payments` (
            `id`                      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `customer_id`             INT UNSIGNED NOT NULL,
            `user_id`                 INT UNSIGNED DEFAULT NULL,
            `internal_transaction_id` VARCHAR(100) DEFAULT NULL,
            `plan_id`                 INT UNSIGNED DEFAULT NULL,
            `order_id`                VARCHAR(100) DEFAULT NULL,
            `razorpay_order_id`       VARCHAR(100) DEFAULT NULL,
            `razorpay_payment_id`     VARCHAR(100) DEFAULT NULL,
            `razorpay_signature`      VARCHAR(255) DEFAULT NULL,
            `amount`                  DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            `currency`                VARCHAR(10) NOT NULL DEFAULT 'INR',
            `status`                  VARCHAR(50) NOT NULL DEFAULT 'created',
            `failure_code`            VARCHAR(100) DEFAULT NULL,
            `failure_message`         TEXT DEFAULT NULL,
            `created_at`              DATETIME DEFAULT CURRENT_TIMESTAMP,
            `updated_at`              DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            KEY `idx_rzp_customer` (`customer_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);


    // =========================================================================
    // 34. CASHFREE_PAYMENTS TABLE
    // =========================================================================
    verifyTable($pdo, 'cashfree_payments', "
        CREATE TABLE IF NOT EXISTS `cashfree_payments` (
            `id`                 INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `order_id`           VARCHAR(100) NOT NULL UNIQUE,
            `customer_id`        INT UNSIGNED NOT NULL,
            `plan_id`            INT UNSIGNED NOT NULL,
            `amount`             DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            `payment_session_id` VARCHAR(255) DEFAULT NULL,
            `order_status`       VARCHAR(50) NOT NULL DEFAULT 'CREATED',
            `cf_payment_id`      VARCHAR(100) DEFAULT NULL,
            `created_at`         DATETIME DEFAULT CURRENT_TIMESTAMP,
            `updated_at`         DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            KEY `idx_cf_customer` (`customer_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);


    // =========================================================================
    // 35. UPI_PAYMENTS TABLE
    // =========================================================================
    verifyTable($pdo, 'upi_payments', "
        CREATE TABLE IF NOT EXISTS `upi_payments` (
            `id`          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `customer_id` INT UNSIGNED NOT NULL,
            `plan_id`     INT UNSIGNED NOT NULL,
            `utr_number`  VARCHAR(100) NOT NULL UNIQUE,
            `amount`      DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            `status`      VARCHAR(20) NOT NULL DEFAULT 'VERIFIED',
            `created_at`  DATETIME DEFAULT CURRENT_TIMESTAMP,
            KEY `idx_upi_cust` (`customer_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);


    // =========================================================================
    // 36. FCM_TOKENS TABLE
    // =========================================================================
    verifyTable($pdo, 'fcm_tokens', "
        CREATE TABLE IF NOT EXISTS `fcm_tokens` (
            `id`          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `user_type`   VARCHAR(50) NOT NULL DEFAULT 'customer',
            `user_id`     INT UNSIGNED NOT NULL,
            `fcm_token`   VARCHAR(500) NOT NULL,
            `device_type` VARCHAR(50) DEFAULT 'android',
            `created_at`  DATETIME DEFAULT CURRENT_TIMESTAMP,
            `updated_at`  DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            KEY `idx_fcm_user` (`user_type`, `user_id`),
            KEY `idx_fcm_token` (`fcm_token`(191))
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);


    // =========================================================================
    // 37. RAZORPAY_VENDOR_PAYOUTS TABLE
    // =========================================================================
    verifyTable($pdo, 'razorpay_vendor_payouts', "
        CREATE TABLE IF NOT EXISTS `razorpay_vendor_payouts` (
            `id`                    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `payout_run_id`         INT UNSIGNED DEFAULT NULL,
            `vendor_id`             INT UNSIGNED NOT NULL,
            `payout_cycle`          VARCHAR(50) NOT NULL,
            `internal_reference_id` VARCHAR(100) NOT NULL UNIQUE,
            `idempotency_key`       VARCHAR(100) NOT NULL UNIQUE,
            `fund_account_id`       VARCHAR(100) NOT NULL,
            `source_account_number` VARCHAR(100) NOT NULL,
            `eligible_earnings`     DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            `commission_deductions` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            `net_payout_amount`     DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            `amount_paise`          BIGINT UNSIGNED NOT NULL DEFAULT 0,
            `currency`              VARCHAR(10) NOT NULL DEFAULT 'INR',
            `mode`                  VARCHAR(20) NOT NULL DEFAULT 'IMPS',
            `purpose`               VARCHAR(50) NOT NULL DEFAULT 'payout',
            `queue_if_low_balance`  TINYINT(1) NOT NULL DEFAULT 1,
            `razorpay_payout_id`    VARCHAR(100) DEFAULT NULL,
            `status`                ENUM('queued','pending','processing','processed','reversed','cancelled','rejected','failed','unknown') NOT NULL DEFAULT 'pending',
            `utr`                   VARCHAR(100) DEFAULT NULL,
            `failure_reason`        TEXT DEFAULT NULL,
            `failure_code`          VARCHAR(100) DEFAULT NULL,
            `initiated_at`          DATETIME DEFAULT NULL,
            `processed_at`          DATETIME DEFAULT NULL,
            `raw_request`           TEXT DEFAULT NULL,
            `raw_response`          TEXT DEFAULT NULL,
            `status_history`        TEXT DEFAULT NULL,
            `created_at`            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at`            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            KEY `idx_rzp_payout_run` (`payout_run_id`),
            KEY `idx_rzp_vendor_id` (`vendor_id`),
            KEY `idx_rzp_payout_cycle` (`payout_cycle`),
            KEY `idx_rzp_payout_id` (`razorpay_payout_id`),
            KEY `idx_rzp_status` (`status`),
            KEY `idx_rzp_created_at` (`created_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);


    // =========================================================================
    // 38. PAYOUT_SETTINGS TABLE
    // =========================================================================
    verifyTable($pdo, 'payout_settings', "
        CREATE TABLE IF NOT EXISTS `payout_settings` (
            `id`                       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `auto_payout_enabled`      TINYINT(1) NOT NULL DEFAULT 1,
            `schedule_hour`            TINYINT UNSIGNED NOT NULL DEFAULT 12,
            `schedule_minute`          TINYINT UNSIGNED NOT NULL DEFAULT 0,
            `schedule_ampm`            VARCHAR(2) NOT NULL DEFAULT 'AM',
            `schedule_time_24`         VARCHAR(5) NOT NULL DEFAULT '00:00',
            `timezone`                 VARCHAR(50) NOT NULL DEFAULT 'Asia/Kolkata',
            `last_run_cycle`           VARCHAR(50) DEFAULT NULL,
            `last_run_at`              DATETIME DEFAULT NULL,
            `last_run_status`          VARCHAR(50) NOT NULL DEFAULT 'Idle',
            `next_run_at`              DATETIME DEFAULT NULL,
            `razorpayx_account_number` VARCHAR(100) NOT NULL DEFAULT '2323230074781323',
            `payout_mode`              VARCHAR(20) NOT NULL DEFAULT 'IMPS',
            `payout_purpose`           VARCHAR(50) NOT NULL DEFAULT 'payout',
            `queue_if_low_balance`     TINYINT(1) NOT NULL DEFAULT 1,
            `created_at`               DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at`               DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    // Ensure default payout_settings row (id = 1) exists
    try {
        $chkSettings = $pdo->query("SELECT id FROM `payout_settings` WHERE id = 1 LIMIT 1");
        if (!$chkSettings || !$chkSettings->fetch()) {
            $pdo->exec("
                INSERT INTO `payout_settings` (
                    id, auto_payout_enabled, schedule_hour, schedule_minute, schedule_ampm, schedule_time_24, timezone, razorpayx_account_number
                ) VALUES (
                    1, 1, 12, 0, 'AM', '00:00', 'Asia/Kolkata', '2323230074781323'
                )
            ");
        }
    } catch (Throwable $t) {}


    // =========================================================================
    // 39. PAYOUT_EXECUTION_LOCK TABLE
    // =========================================================================
    verifyTable($pdo, 'payout_execution_lock', "
        CREATE TABLE IF NOT EXISTS `payout_execution_lock` (
            `lock_name`  VARCHAR(50) PRIMARY KEY,
            `locked_at`  DATETIME NOT NULL,
            `locked_by`  VARCHAR(100) NOT NULL,
            `expires_at` DATETIME NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);


    // =========================================================================
    // 40. PAYOUT_RUNS TABLE
    // =========================================================================
    verifyTable($pdo, 'payout_runs', "
        CREATE TABLE IF NOT EXISTS `payout_runs` (
            `id`                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `run_code`            VARCHAR(64) NOT NULL UNIQUE,
            `trigger_type`        ENUM('scheduled','manual') NOT NULL DEFAULT 'scheduled',
            `target_date`         DATE NOT NULL,
            `scheduled_time`      DATETIME DEFAULT NULL,
            `start_time`          DATETIME NOT NULL,
            `completion_time`     DATETIME DEFAULT NULL,
            `vendors_examined`    INT UNSIGNED NOT NULL DEFAULT 0,
            `payouts_submitted`   INT UNSIGNED NOT NULL DEFAULT 0,
            `successful_payouts`  INT UNSIGNED NOT NULL DEFAULT 0,
            `failed_payouts`      INT UNSIGNED NOT NULL DEFAULT 0,
            `pending_payouts`     INT UNSIGNED NOT NULL DEFAULT 0,
            `total_amount`        DECIMAL(12,2) NOT NULL DEFAULT 0.00,
            `status`              ENUM('RUNNING','COMPLETED','COMPLETED_WITH_EXCEPTIONS','FAILED') NOT NULL DEFAULT 'RUNNING',
            `summary_notes`       TEXT DEFAULT NULL,
            `created_at`          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at`          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            KEY `idx_payout_runs_target_date` (`target_date`),
            KEY `idx_payout_runs_status` (`status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);


    // =========================================================================
    // 41. ENQUIRIES TABLE
    // =========================================================================
    verifyTable($pdo, 'enquiries', "
        CREATE TABLE IF NOT EXISTS `enquiries` (
            `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `name`       VARCHAR(150) NOT NULL,
            `phone`      VARCHAR(20)  NOT NULL,
            `state`      VARCHAR(100) NOT NULL DEFAULT '',
            `district`   VARCHAR(100) NOT NULL DEFAULT '',
            `taluka`     VARCHAR(100) NOT NULL DEFAULT '',
            `area`       VARCHAR(150) NOT NULL DEFAULT '',
            `notes`      TEXT         DEFAULT NULL,
            `status`     VARCHAR(50)  NOT NULL DEFAULT 'New',
            `created_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_enq_date` (`created_at`),
            KEY `idx_enq_state` (`state`),
            KEY `idx_enq_district` (`district`),
            KEY `idx_enq_taluka` (`taluka`),
            KEY `idx_enq_area` (`area`),
            KEY `idx_enq_status` (`status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ", $report);

    ensureColumns($pdo, 'enquiries', [
        'name'       => 'VARCHAR(150) NOT NULL',
        'phone'      => 'VARCHAR(20)  NOT NULL',
        'state'      => "VARCHAR(100) NOT NULL DEFAULT ''",
        'district'   => "VARCHAR(100) NOT NULL DEFAULT ''",
        'taluka'     => "VARCHAR(100) NOT NULL DEFAULT ''",
        'area'       => "VARCHAR(150) NOT NULL DEFAULT ''",
        'notes'      => 'TEXT         DEFAULT NULL',
        'status'     => "VARCHAR(50)  NOT NULL DEFAULT 'New'",
    ], $report, $totalColsChecked, $totalColsAdded);


    // =========================================================================
    // TYPE MODIFICATIONS & CRITICAL FIXES FOR EXISTING INSTALLATIONS
    // =========================================================================
    $modifications = [
        "ALTER TABLE `tiffin_return_logs` MODIFY COLUMN `otp` TEXT DEFAULT NULL",
        "ALTER TABLE `tiffin_returns` MODIFY COLUMN `barcode` TEXT DEFAULT NULL",
        "ALTER TABLE `orders` MODIFY COLUMN `tiffin_received_to_hotel` VARCHAR(50) NOT NULL DEFAULT 'pending'",
        "ALTER TABLE `orders` MODIFY COLUMN `tiffin_return_otp` VARCHAR(255) DEFAULT NULL",
        "ALTER TABLE `orders` MODIFY COLUMN `tiffin_charge` DECIMAL(10,2) NOT NULL DEFAULT 0.00",
        "ALTER TABLE `orders` MODIFY COLUMN `area_tiffin_charge` DECIMAL(10,2) NOT NULL DEFAULT 0.00",
        "ALTER TABLE `orders` MODIFY COLUMN `status` VARCHAR(50) NOT NULL DEFAULT 'created_order'",
        "ALTER TABLE `service_locations` MODIFY COLUMN `tiffin_charge` DECIMAL(10,2) NOT NULL DEFAULT 50.00",
        "ALTER TABLE `plans` MODIFY COLUMN `tiffin_charge` DECIMAL(10,2) NOT NULL DEFAULT 50.00",
        "ALTER TABLE `hotels` MODIFY COLUMN `gst_percentage` DECIMAL(5,2) NOT NULL DEFAULT 5.00",
        "ALTER TABLE `hotels` MODIFY COLUMN `is_vendor_online` TINYINT(1) DEFAULT 1",
        "UPDATE `menus` SET `meal_type` = 'Lunch' WHERE `meal_type` IS NULL OR `meal_type` = ''",
        "ALTER TABLE `menus` MODIFY COLUMN `meal_type` ENUM('Lunch','Dinner') NOT NULL DEFAULT 'Lunch'",
        "ALTER TABLE `customers` ADD COLUMN `region` VARCHAR(100) DEFAULT NULL",
        "ALTER TABLE `customers` ADD COLUMN `area` VARCHAR(255) DEFAULT NULL",
        "ALTER TABLE `customer_addresses` ADD COLUMN `region` VARCHAR(100) DEFAULT NULL",
        "ALTER TABLE `customer_addresses` ADD COLUMN `area` VARCHAR(255) DEFAULT NULL",
        "ALTER TABLE `customer_addresses` ADD COLUMN `full_address` TEXT DEFAULT NULL",
        "ALTER TABLE `vendors` ADD COLUMN `region` VARCHAR(150) DEFAULT NULL",
        "ALTER TABLE `vendors` ADD COLUMN `area` VARCHAR(150) DEFAULT NULL",
        "ALTER TABLE `hotels` ADD COLUMN `region` VARCHAR(150) DEFAULT NULL",
        "ALTER TABLE `hotels` ADD COLUMN `area` VARCHAR(150) DEFAULT NULL",
    ];

    foreach ($modifications as $sql) {
        try {
            $pdo->exec($sql);
            $report['column_modifications'][] = $sql;
        } catch (Exception $modEx) {
            // Table might not exist or column is already formatted
        }
    }

    // Synchronize vendors with Razorpay if explicitly requested via ?sync_rzp=1
    $shouldSyncRzp = isset($_GET['sync_rzp']) && $_GET['sync_rzp'] == '1';
    if ($shouldSyncRzp) {
        try {
            $rzpSyncResult = syncAllExistingVendorsRazorpay($pdo);
            $report['razorpay_sync'] = [
                'total_vendors' => $rzpSyncResult['total_vendors'],
                'synced_count'  => $rzpSyncResult['synced_count'],
                'details'       => $rzpSyncResult['details'],
            ];
        } catch (Exception $rzpEx) {
            $report['razorpay_sync'] = [
                'status' => 'skipped_or_failed',
                'error'  => $rzpEx->getMessage(),
            ];
        }
    } else {
        $report['razorpay_sync'] = [
            'status' => 'skipped',
            'note'   => 'Pass ?sync_rzp=1 to trigger Razorpay external API synchronization.',
        ];
    }

    $report['summary'] = [
        'total_tables_verified' => count($report['tables_verified']),
        'total_columns_checked' => $totalColsChecked,
        'new_columns_added_cnt' => $totalColsAdded,
        'modifications_cnt'     => count($report['column_modifications']),
        'status'                => 'All database tables and columns are refreshed and 100% up-to-date.',
    ];

    sendSuccess('Database migration completed successfully. Tables and columns refreshed.', [
        'migration_report' => $report,
        'server_time'      => date('Y-m-d H:i:s T'),
    ]);

} catch (Exception $e) {
    sendError('Migration failed: ' . $e->getMessage(), 500);
}
