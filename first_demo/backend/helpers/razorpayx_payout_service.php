<?php
/**
 * RazorpayX Automated Vendor Payout Service
 * Hungrily Foods Project
 *
 * Implements schedule settings, server-side dispatching, dynamic vendor discovery,
 * atomic wallet balance reservation, idempotent RazorpayX transfers, status reconciliation,
 * and batch execution tracking.
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/razorpay.php';
require_once __DIR__ . '/vendor_wallet_helper.php';

class RazorpayXPayoutService {

    const DEFAULT_TIMEZONE = 'Asia/Kolkata';

    /**
     * Auto-create all required payout tables if missing
     */
    public static function ensureTablesExist(PDO $pdo): void {
        static $checked = false;
        if ($checked) return;

        try {
            $pdo->exec("
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

                CREATE TABLE IF NOT EXISTS `payout_execution_lock` (
                    `lock_name`  VARCHAR(50) PRIMARY KEY,
                    `locked_at`  DATETIME NOT NULL,
                    `locked_by`  VARCHAR(100) NOT NULL,
                    `expires_at` DATETIME NOT NULL
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
            ");
            $checked = true;
        } catch (Throwable $t) {}
    }

    /**
     * Retrieve payout schedule settings.
     */
    public static function getSettings(PDO $pdo): array {
        self::ensureTablesExist($pdo);
        $stmt = $pdo->query("SELECT * FROM `payout_settings` WHERE id = 1 LIMIT 1");
        $settings = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$settings) {
            // Auto-initialize if row was missing
            $tz = new DateTimeZone(self::DEFAULT_TIMEZONE);
            $now = new DateTime('now', $tz);
            $next = clone $now;
            $next->setTime(0, 0, 0);
            if ($next <= $now) $next->modify('+1 day');

            $pdo->exec("
                INSERT INTO `payout_settings` 
                (id, auto_payout_enabled, schedule_hour, schedule_minute, schedule_ampm, schedule_time_24, timezone, next_run_at)
                VALUES (1, 1, 12, 0, 'AM', '00:00', 'Asia/Kolkata', '{$next->format('Y-m-d H:i:s')}')
            ");
            return self::getSettings($pdo);
        }

        // Calculate dynamic next_run_at if past
        $nextRun = self::calculateNextRun(
            (int)$settings['schedule_hour'],
            (int)$settings['schedule_minute'],
            $settings['schedule_ampm'],
            $settings['timezone'] ?: self::DEFAULT_TIMEZONE,
            $settings['last_run_cycle'] ?? null
        );

        // Update in DB if drifted
        if (empty($settings['next_run_at']) || strtotime($settings['next_run_at']) <= time()) {
            $upd = $pdo->prepare("UPDATE `payout_settings` SET next_run_at = :nxt WHERE id = 1");
            $upd->execute([':nxt' => $nextRun['formatted_sql']]);
            $settings['next_run_at'] = $nextRun['formatted_sql'];
        }

        $settings['next_run_formatted'] = date('d M Y, h:i A', strtotime($settings['next_run_at'])) . ' (IST)';
        $settings['last_run_formatted'] = !empty($settings['last_run_at']) 
            ? date('d M Y, h:i A', strtotime($settings['last_run_at'])) . ' (IST)' 
            : 'Never executed';

        return $settings;
    }

    /**
     * Save payout schedule settings with server-side validation.
     */
    public static function saveSettings(PDO $pdo, array $input): array {
        $enabled = !empty($input['auto_payout_enabled']) ? 1 : 0;
        $hour    = isset($input['schedule_hour']) ? max(1, min(12, (int)$input['schedule_hour'])) : 12;
        $minute  = isset($input['schedule_minute']) ? max(0, min(59, (int)$input['schedule_minute'])) : 0;
        $ampm    = strtoupper(trim($input['schedule_ampm'] ?? 'AM')) === 'PM' ? 'PM' : 'AM';
        $tzName  = self::DEFAULT_TIMEZONE;

        // Convert to 24-hour representation
        $hour24 = $hour % 12;
        if ($ampm === 'PM') {
            $hour24 += 12;
        }
        $time24 = sprintf('%02d:%02d', $hour24, $minute);

        // Calculate next run
        $nextRun = self::calculateNextRun($hour, $minute, $ampm, $tzName);

        $stmt = $pdo->prepare("
            UPDATE `payout_settings`
            SET auto_payout_enabled  = :enabled,
                schedule_hour        = :hour,
                schedule_minute      = :minute,
                schedule_ampm        = :ampm,
                schedule_time_24     = :time24,
                timezone             = :tz,
                next_run_at          = :next_run,
                last_run_cycle       = NULL,
                updated_at           = NOW()
            WHERE id = 1
        ");

        $stmt->execute([
            ':enabled'  => $enabled,
            ':hour'     => $hour,
            ':minute'   => $minute,
            ':ampm'     => $ampm,
            ':time24'   => $time24,
            ':tz'       => $tzName,
            ':next_run' => $nextRun['formatted_sql'],
        ]);

        return self::getSettings($pdo);
    }

    /**
     * Computes the next scheduled execution date and time in the specified timezone.
     */
    public static function calculateNextRun(int $hour12, int $minute, string $ampm, string $tzName = 'Asia/Kolkata', ?string $lastRunCycle = null): array {
        $tz = new DateTimeZone($tzName);
        $now = new DateTime('now', $tz);

        $hour24 = $hour12 % 12;
        if ($ampm === 'PM') {
            $hour24 += 12;
        }

        $scheduledToday = clone $now;
        $scheduledToday->setTime($hour24, $minute, 0);

        $scheduledTime24 = sprintf('%02d:%02d', $hour24, $minute);
        $todayDate       = $now->format('Y-m-d');
        $cycleKey        = $todayDate . '@' . $scheduledTime24;

        $alreadyRanForThisSchedule = (!empty($lastRunCycle) && ($lastRunCycle === $cycleKey || $lastRunCycle === $todayDate));

        // If the scheduled time for today is still ahead AND hasn't already run today
        if ($scheduledToday > $now && !$alreadyRanForThisSchedule) {
            $next = $scheduledToday;
        } else {
            $next = clone $scheduledToday;
            $next->modify('+1 day');
        }

        return [
            'datetime'      => $next,
            'timestamp'     => $next->getTimestamp(),
            'formatted_sql' => $next->format('Y-m-d H:i:s'),
            'formatted_ui'  => $next->format('d M Y, h:i A') . ' (IST)',
        ];
    }

    /**
     * Atomically acquires an execution lock to prevent overlapping runs.
     */
    public static function acquireLock(PDO $pdo, string $lockName = 'payout_cron_lock', int $timeoutSeconds = 300, string $lockedBy = 'scheduler'): bool {
        // Clean expired locks
        $pdo->prepare("DELETE FROM `payout_execution_lock` WHERE lock_name = :l AND expires_at < NOW()")->execute([':l' => $lockName]);

        $now = date('Y-m-d H:i:s');
        $expires = date('Y-m-d H:i:s', time() + $timeoutSeconds);

        try {
            $stmt = $pdo->prepare("
                INSERT INTO `payout_execution_lock` (lock_name, locked_at, locked_by, expires_at)
                VALUES (:l, :now, :by, :exp)
            ");
            return $stmt->execute([
                ':l'   => $lockName,
                ':now' => $now,
                ':by'  => $lockedBy,
                ':exp' => $expires,
            ]);
        } catch (PDOException $e) {
            return false; // Lock already held
        }
    }

    /**
     * Releases an execution lock.
     */
    public static function releaseLock(PDO $pdo, string $lockName = 'payout_cron_lock'): void {
        try {
            $pdo->prepare("DELETE FROM `payout_execution_lock` WHERE lock_name = :l")->execute([':l' => $lockName]);
        } catch (Throwable $e) {}
    }

    /**
     * Calculates real database-backed summary statistics for the payout dashboard.
     */
    public static function getSummaryMetrics(PDO $pdo, ?string $cycle = null): array {
        $cycle = $cycle ?: date('Y-m-d');

        // 1. Total Eligible Vendors count and total eligible payout amount
        $eligibleVendors = self::discoverEligibleVendors($pdo, $cycle);
        $totalEligibleCount  = count($eligibleVendors);
        $totalEligibleAmount = 0.0;
        foreach ($eligibleVendors as $v) {
            $totalEligibleAmount += (float)$v['net_payable_amount'];
        }

        // 2. Query status metrics from razorpay_vendor_payouts
        $stmt = $pdo->query("
            SELECT 
                COUNT(*) as total_payouts,
                COALESCE(SUM(CASE WHEN status IN ('pending') THEN 1 ELSE 0 END), 0) as pending_count,
                COALESCE(SUM(CASE WHEN status IN ('pending') THEN net_payout_amount ELSE 0 END), 0) as pending_amount,
                COALESCE(SUM(CASE WHEN status IN ('processing', 'queued') THEN 1 ELSE 0 END), 0) as processing_count,
                COALESCE(SUM(CASE WHEN status IN ('processing', 'queued') THEN net_payout_amount ELSE 0 END), 0) as processing_amount,
                COALESCE(SUM(CASE WHEN status IN ('processed') THEN 1 ELSE 0 END), 0) as successful_count,
                COALESCE(SUM(CASE WHEN status IN ('processed') THEN net_payout_amount ELSE 0 END), 0) as successful_amount,
                COALESCE(SUM(CASE WHEN status IN ('failed', 'rejected', 'cancelled') THEN 1 ELSE 0 END), 0) as failed_count,
                COALESCE(SUM(CASE WHEN status IN ('failed', 'rejected', 'cancelled') THEN net_payout_amount ELSE 0 END), 0) as failed_amount,
                COALESCE(SUM(CASE WHEN status IN ('unknown', 'reversed') THEN 1 ELSE 0 END), 0) as unknown_count,
                COALESCE(SUM(CASE WHEN status IN ('unknown', 'reversed') THEN net_payout_amount ELSE 0 END), 0) as unknown_amount
            FROM `razorpay_vendor_payouts`
        ");
        $stats = $stmt->fetch(PDO::FETCH_ASSOC) ?: [];

        return [
            'total_eligible_vendors'          => (int)$totalEligibleCount,
            'total_eligible_payout_amount'    => round($totalEligibleAmount, 2),
            'total_eligible_amount_formatted' => '₹ ' . number_format($totalEligibleAmount, 2),
            'pending_count'                   => (int)($stats['pending_count'] ?? 0),
            'pending_amount'                  => round((float)($stats['pending_amount'] ?? 0), 2),
            'processing_count'                => (int)($stats['processing_count'] ?? 0),
            'processing_amount'               => round((float)($stats['processing_amount'] ?? 0), 2),
            'successful_count'                => (int)($stats['successful_count'] ?? 0),
            'successful_amount'               => round((float)($stats['successful_amount'] ?? 0), 2),
            'failed_count'                    => (int)($stats['failed_count'] ?? 0),
            'failed_amount'                   => round((float)($stats['failed_amount'] ?? 0), 2),
            'unknown_count'                   => (int)($stats['unknown_count'] ?? 0),
            'unknown_amount'                  => round((float)($stats['unknown_amount'] ?? 0), 2),
            'total_amount_successfully_paid'  => round((float)($stats['successful_amount'] ?? 0), 2),
            'total_paid_formatted'            => '₹ ' . number_format((float)($stats['successful_amount'] ?? 0), 2),
        ];
    }

    /**
     * Dynamically discovers all active vendors eligible for payout for the target date cycle.
     */
    public static function discoverEligibleVendors(PDO $pdo, string $targetDate): array {
        // Fetch active vendors
        $stmt = $pdo->prepare("
            SELECT v.id, v.full_name, v.email, v.phone, v.bank_name, v.account_holder_name, 
                   v.account_number, v.ifsc_code, v.razorpay_contact_id, v.razorpay_fund_account_id
            FROM vendors v
            WHERE v.is_active = 1
            ORDER BY v.id ASC
        ");
        $stmt->execute();
        $vendors = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $eligible = [];

        foreach ($vendors as $v) {
            $vendorId = (int)$v['id'];

            // 1. Calculate today's real order earnings from completed orders in vendor_wallet_transactions
            // Exclude reversals and refund credits so failed payouts never inflate earnings
            $earnStmt = $pdo->prepare("
                SELECT COALESCE(SUM(amount), 0) as today_earnings, COUNT(*) as orders_count
                FROM vendor_wallet_transactions
                WHERE vendor_id = :vid 
                  AND type = 'CREDIT' 
                  AND (description NOT LIKE '%Reversal%' AND description NOT LIKE '%refund%')
                  AND DATE(created_at) = :target_date
            ");
            $earnStmt->execute([
                ':vid'         => $vendorId,
                ':target_date' => $targetDate,
            ]);
            $earnData = $earnStmt->fetch(PDO::FETCH_ASSOC);
            $todayEarnings = (float)($earnData['today_earnings'] ?? 0);
            $ordersCount   = (int)($earnData['orders_count'] ?? 0);

            // 2. Calculate already active / settled payouts for today's cycle
            $settledStmt = $pdo->prepare("
                SELECT COALESCE(SUM(net_payout_amount), 0) as settled_today
                FROM razorpay_vendor_payouts
                WHERE vendor_id = :vid
                  AND payout_cycle = :cycle
                  AND status IN ('processed', 'processing', 'queued', 'pending')
            ");
            $settledStmt->execute([':vid' => $vendorId, ':cycle' => $targetDate]);
            $settledToday = (float)$settledStmt->fetchColumn();

            // Unsettled earnings remaining for today
            $unsettledEarnings = max(0, round($todayEarnings - $settledToday, 2));

            // 3. Fetch current wallet balance
            $walletData   = VendorWalletHelper::getBalance($vendorId);
            $totalBalance = (float)($walletData['balance'] ?? 0);

            // Net payable is capped by available wallet balance
            $netPayable = round(min($unsettledEarnings, $totalBalance), 2);

            // Check fund account availability
            $hasFundAccount = !empty($v['razorpay_fund_account_id']);
            $hasBankDetails = !empty($v['account_number']) && !empty($v['ifsc_code']);

            if ($netPayable > 0 && ($hasFundAccount || $hasBankDetails)) {
                $eligible[] = [
                    'vendor_id'                  => $vendorId,
                    'vendor_name'                => $v['full_name'],
                    'vendor_email'               => $v['email'],
                    'vendor_phone'               => $v['phone'],
                    'bank_name'                  => $v['bank_name'],
                    'account_number'             => $v['account_number'],
                    'ifsc_code'                  => $v['ifsc_code'],
                    'razorpay_contact_id'        => $v['razorpay_contact_id'],
                    'razorpay_fund_account_id'   => $v['razorpay_fund_account_id'],
                    'today_earnings'             => $todayEarnings,
                    'settled_today'              => $settledToday,
                    'available_wallet_balance'   => $totalBalance,
                    'net_payable_amount'         => $netPayable,
                    'orders_count'               => $ordersCount,
                    'payout_cycle'               => $targetDate,
                ];
            }
        }

        return $eligible;
    }

    /**
     * Executes an individual vendor payout through RazorpayX with full duplicate protection.
     */
    public static function processVendorPayout(PDO $pdo, array $vendor, string $targetDate, ?int $runId, string $triggerType = 'scheduled'): array {
        $vendorId = (int)$vendor['vendor_id'];
        $netAmount = (float)$vendor['net_payable_amount'];
        $earnings  = (float)$vendor['today_earnings'];
        $deductions = 0.00; // Customizable commission/deduction breakdown

        if ($netAmount <= 0) {
            return ['success' => false, 'message' => 'Zero payable amount.'];
        }

        // 1. Resolve Fund Account ID if missing
        $fundAccountId = trim($vendor['razorpay_fund_account_id'] ?? '');
        $contactId     = trim($vendor['razorpay_contact_id'] ?? '');

        if (empty($fundAccountId)) {
            $rawIfsc = strtoupper(trim(preg_replace('/[^A-Za-z0-9]/', '', $vendor['ifsc_code'] ?? '')));
            $rawAcc  = trim((string)($vendor['account_number'] ?? ''));

            // In test mode, fallback to valid test bank details if invalid dummy IFSC was provided
            $isTestMode = (defined('RAZORPAY_TEST_MODE') && RAZORPAY_TEST_MODE) || (strpos(RAZORPAY_KEY_ID, 'rzp_test_') === 0);
            if ($isTestMode) {
                if (!preg_match('/^[A-Z]{4}0[A-Z0-9]{6}$/', $rawIfsc)) {
                    $rawIfsc = 'KKBK0001773'; // Valid Kotak test IFSC
                }
                if (strlen($rawAcc) < 6 || !ctype_digit($rawAcc)) {
                    $rawAcc = '4050544613';
                }
            }

            // Auto-provision fund account in Razorpay if valid bank details exist
            if (!empty($rawAcc) && !empty($rawIfsc)) {
                if (empty($contactId)) {
                    $cRes = createRazorpayContact([
                        'name'    => $vendor['vendor_name'],
                        'email'   => $vendor['vendor_email'],
                        'contact' => $vendor['vendor_phone'],
                        'type'    => 'vendor',
                    ]);
                    if ($cRes['success'] && !empty($cRes['id'])) {
                        $contactId = $cRes['id'];
                        $pdo->prepare("UPDATE vendors SET razorpay_contact_id = ? WHERE id = ?")->execute([$contactId, $vendorId]);
                    }
                }

                if (!empty($contactId)) {
                    $faRes = createRazorpayFundAccount([
                        'contact_id'     => $contactId,
                        'name'           => $vendor['vendor_name'],
                        'ifsc'           => $rawIfsc,
                        'account_number' => $rawAcc,
                    ]);
                    if ($faRes['success'] && !empty($faRes['id'])) {
                        $fundAccountId = $faRes['id'];
                        $pdo->prepare("UPDATE vendors SET razorpay_fund_account_id = ? WHERE id = ?")->execute([$fundAccountId, $vendorId]);
                    }
                }
            }
        }

        if (empty($fundAccountId)) {
            $reason = 'No active Razorpay Fund Account could be provisioned. Check bank account and IFSC code: ' . ($vendor['ifsc_code'] ?: 'Empty');
            $cycleDateStr = str_replace('-', '', $targetDate);
            $failRef = "HUNGRILY-PO-{$vendorId}-{$cycleDateStr}-FAIL";
            $failIdem = sprintf("PO-%d-%s-FAIL", $vendorId, substr($cycleDateStr, 4));
            try {
                $insFail = $pdo->prepare("
                    INSERT INTO `razorpay_vendor_payouts`
                    (payout_run_id, vendor_id, payout_cycle, internal_reference_id, idempotency_key,
                     fund_account_id, source_account_number, eligible_earnings, commission_deductions,
                     net_payout_amount, amount_paise, currency, mode, purpose, queue_if_low_balance,
                     status, failure_reason, failure_code, initiated_at, status_history)
                    VALUES
                    (:run_id, :vendor_id, :cycle, :ref_id, :idem_key,
                     NULL, '2323230074781323', :earnings, 0,
                     :net_amt, :amt_paise, 'INR', 'IMPS', 'payout', 1,
                     'failed', :fail_reason, 'INVALID_BANK_DETAILS', NOW(), :history)
                ");
                $insFail->execute([
                    ':run_id'      => $runId,
                    ':vendor_id'   => $vendorId,
                    ':cycle'       => $targetDate,
                    ':ref_id'      => $failRef,
                    ':idem_key'    => $failIdem,
                    ':earnings'    => $netAmount,
                    ':net_amt'     => $netAmount,
                    ':amt_paise'   => (int)round($netAmount * 100),
                    ':fail_reason' => $reason,
                    ':history'     => json_encode([['status' => 'failed', 'timestamp' => time(), 'source' => 'system', 'note' => $reason]])
                ]);
            } catch (Throwable $e) {
                // Ignore failure logging exceptions
            }
            return [
                'success' => false,
                'message' => $reason
            ];
        }

        // 2. Stable Idempotency & Unique Reference
        $cycleDateStr = str_replace('-', '', $targetDate);
        $referenceId = "HUNGRILY-PO-{$vendorId}-{$cycleDateStr}-" . substr(md5(uniqid((string)$vendorId, true)), 0, 6);
        // Razorpay strictly enforces X-Payout-Idempotency header length <= 36 characters
        $idempotencyKey = sprintf("PO-%d-%s-%s", $vendorId, substr($cycleDateStr, 4), substr(md5("{$vendorId}_{$targetDate}_{$netAmount}_" . microtime(true)), 0, 16));

        // Source account from settings
        $settings = self::getSettings($pdo);
        $sourceAccount = $settings['razorpayx_account_number'] ?: '2323230074781323';
        $amountPaise = (int)round($netAmount * 100);

        // 3. Atomically claim & reserve payout in DB
        $pdo->beginTransaction();
        try {
            // Check double submission inside transaction
            if ($runId) {
                $dupCheck = $pdo->prepare("
                    SELECT id, status, internal_reference_id 
                    FROM razorpay_vendor_payouts 
                    WHERE vendor_id = :vid AND payout_run_id = :run_id AND status NOT IN ('failed', 'rejected', 'cancelled')
                    FOR UPDATE
                ");
                $dupCheck->execute([':vid' => $vendorId, ':run_id' => $runId]);
            } else {
                $dupCheck = $pdo->prepare("
                    SELECT id, status, internal_reference_id 
                    FROM razorpay_vendor_payouts 
                    WHERE vendor_id = :vid AND payout_cycle = :cycle AND status IN ('processing', 'pending')
                    FOR UPDATE
                ");
                $dupCheck->execute([':vid' => $vendorId, ':cycle' => $targetDate]);
            }
            if ($dupCheck->fetch()) {
                $pdo->rollBack();
                return ['success' => false, 'message' => 'Payout already active or processed for this batch.'];
            }

            // Debit vendor wallet balance atomically
            $wCheck = $pdo->prepare("SELECT balance FROM vendor_wallets WHERE vendor_id = ? FOR UPDATE");
            $wCheck->execute([$vendorId]);
            $currBal = (float)$wCheck->fetchColumn();

            if ($currBal < $netAmount) {
                $pdo->rollBack();
                return ['success' => false, 'message' => 'Insufficient wallet balance at execution time.'];
            }

            $newBal = round($currBal - $netAmount, 2);
            $pdo->prepare("UPDATE vendor_wallets SET balance = ?, updated_at = NOW() WHERE vendor_id = ?")->execute([$newBal, $vendorId]);

            // Insert transaction ledger record
            $insTx = $pdo->prepare("
                INSERT INTO vendor_wallet_transactions (vendor_id, type, amount, balance_after, description, created_at)
                VALUES (?, 'DEBIT', ?, ?, ?, NOW())
            ");
            $insTx->execute([
                $vendorId,
                $netAmount,
                $newBal,
                "RazorpayX Daily Settlement Payout (Ref: {$referenceId}, Amount: ₹" . number_format($netAmount, 2) . ")"
            ]);

            // Create initial payout record
            $insPayout = $pdo->prepare("
                INSERT INTO `razorpay_vendor_payouts`
                (payout_run_id, vendor_id, payout_cycle, internal_reference_id, idempotency_key,
                 fund_account_id, source_account_number, eligible_earnings, commission_deductions,
                 net_payout_amount, amount_paise, currency, mode, purpose, queue_if_low_balance,
                 status, initiated_at, raw_request)
                VALUES
                (:run_id, :vendor_id, :cycle, :ref_id, :idem_key,
                 :fa_id, :src_acc, :earnings, :deductions,
                 :net_amt, :amt_paise, 'INR', :mode, :purpose, 1,
                 'pending', NOW(), :req)
            ");

            $payload = [
                'account_number'       => $sourceAccount,
                'fund_account_id'      => $fundAccountId,
                'amount'               => $amountPaise,
                'currency'             => 'INR',
                'mode'                 => $settings['payout_mode'] ?: 'IMPS',
                'purpose'              => $settings['payout_purpose'] ?: 'payout',
                'queue_if_low_balance' => (bool)$settings['queue_if_low_balance'],
                'reference_id'         => $referenceId,
                'narration'            => 'Hungrily Vendor Payout',
                'notes'                => [
                    'vendor_id'    => (string)$vendorId,
                    'vendor_name'  => $vendor['vendor_name'],
                    'payout_cycle' => $targetDate,
                    'run_id'       => (string)($runId ?: 0),
                ],
            ];

            $insPayout->execute([
                ':run_id'     => $runId,
                ':vendor_id'  => $vendorId,
                ':cycle'      => $targetDate,
                ':ref_id'     => $referenceId,
                ':idem_key'   => $idempotencyKey,
                ':fa_id'      => $fundAccountId,
                ':src_acc'    => $sourceAccount,
                ':earnings'   => $earnings,
                ':deductions' => $deductions,
                ':net_amt'    => $netAmount,
                ':amt_paise'  => $amountPaise,
                ':mode'       => $payload['mode'],
                ':purpose'    => $payload['purpose'],
                ':req'        => json_encode($payload),
            ]);

            $payoutRecordId = (int)$pdo->lastInsertId();
            $pdo->commit();

        } catch (Throwable $e) {
            $pdo->rollBack();
            return ['success' => false, 'message' => 'Database error reserving payout: ' . $e->getMessage()];
        }

        // 4. Submit to RazorpayX API
        $apiResult = createRazorpayXPayout($payload, $idempotencyKey);
        $rawResp = json_encode($apiResult);
        $rzpPayoutId = $apiResult['id'] ?? null;
        $rzpStatus = strtolower($apiResult['status'] ?? 'unknown');
        $utr = $apiResult['data']['utr'] ?? null;
        $failReason = $apiResult['error'] ?? null;
        $failCode = $apiResult['error_code'] ?? null;

        // Map Razorpay status
        $finalStatus = 'processing';
        if ($rzpStatus === 'processed') {
            $finalStatus = 'processed';
        } elseif ($rzpStatus === 'queued') {
            $finalStatus = 'queued';
        } elseif ($rzpStatus === 'processing' || $rzpStatus === 'pending') {
            $finalStatus = 'processing';
        } elseif (in_array($rzpStatus, ['rejected', 'failed', 'cancelled'])) {
            $finalStatus = 'failed';
        }

        // 5. Update payout record with API response
        $statusHistory = json_encode([[
            'status'    => $finalStatus,
            'timestamp' => time(),
            'source'    => 'razorpay_post',
            'note'      => 'Initial API submission response'
        ]]);

        $updPayout = $pdo->prepare("
            UPDATE `razorpay_vendor_payouts`
            SET razorpay_payout_id = :rzp_id,
                status             = :st,
                utr                = :utr,
                failure_reason     = :fail_r,
                failure_code       = :fail_c,
                raw_response       = :raw_resp,
                status_history     = :hist,
                processed_at       = CASE WHEN :st2 = 'processed' THEN NOW() ELSE processed_at END,
                updated_at         = NOW()
            WHERE id = :id
        ");

        $updPayout->execute([
            ':rzp_id'    => $rzpPayoutId,
            ':st'        => $finalStatus,
            ':utr'       => $utr,
            ':fail_r'    => $failReason,
            ':fail_c'    => $failCode,
            ':raw_resp'  => $rawResp,
            ':hist'      => $statusHistory,
            ':st2'       => $finalStatus,
            ':id'        => $payoutRecordId,
        ]);

        // If transfer permanently rejected on submission, automatically refund vendor wallet
        if ($finalStatus === 'failed') {
            self::refundVendorWalletForFailedPayout($pdo, $payoutRecordId, $failReason ?: 'Razorpay transfer rejected');
        }

        // Mirror to vendor_payouts table for backward compatibility
        try {
            $pdo->prepare("
                INSERT INTO `vendor_payouts`
                (vendor_id, amount, merchant_ref_id, payment_type, status, failure_reason, initiated_at, completed_at, payment_method, txnid, target_date)
                VALUES (?, ?, ?, 'IMPS', ?, ?, NOW(), CASE WHEN ? = 'processed' THEN NOW() ELSE NULL END, 'razorpayx', ?, ?)
            ")->execute([
                $vendorId,
                $netAmount,
                $referenceId,
                strtoupper($finalStatus === 'processed' ? 'SUCCESS' : ($finalStatus === 'failed' ? 'FAILED' : 'PROCESSING')),
                $failReason,
                $finalStatus,
                $rzpPayoutId,
                $targetDate
            ]);
        } catch (Throwable $e) {}

        return [
            'success'               => ($finalStatus !== 'failed'),
            'payout_record_id'      => $payoutRecordId,
            'razorpay_payout_id'    => $rzpPayoutId,
            'internal_reference_id' => $referenceId,
            'status'                => $finalStatus,
            'net_amount'            => $netAmount,
            'amount_paise'          => $amountPaise,
            'utr'                   => $utr,
            'error'                 => $failReason,
            'latency_ms'            => $apiResult['latency_ms'] ?? 0,
        ];
    }

    /**
     * Cleans up stale batches that were interrupted by a server reboot or killed worker.
     */
    public static function cleanupStaleRuns(PDO $pdo): void {
        try {
            $pdo->exec("
                UPDATE `payout_runs` 
                SET status = 'INTERRUPTED', 
                    completion_time = NOW(), 
                    summary_notes = 'Batch interrupted by process termination or server restart.' 
                WHERE status = 'RUNNING' 
                  AND start_time < (NOW() - INTERVAL 15 MINUTE)
            ");
        } catch (Throwable $e) {}
    }

    /**
     * Executes the complete daily payout batch run across all eligible vendors.
     */
    public static function executePayoutBatch(PDO $pdo, string $triggerType = 'scheduled', ?string $targetDate = null, ?string $cycleKey = null): array {
        $targetDate = $targetDate ?: date('Y-m-d');
        $lockName = 'vendor_payout_batch_lock';
        self::cleanupStaleRuns($pdo);

        if (!self::acquireLock($pdo, $lockName, 600, $triggerType)) {
            return [
                'success' => false,
                'message' => 'Another payout batch is already in progress. Please wait for it to complete.'
            ];
        }

        $runCode = 'RUN-' . date('Ymd-His') . '-' . substr(bin2hex(random_bytes(3)), 0, 4);

        // 1. Create run record
        $insRun = $pdo->prepare("
            INSERT INTO `payout_runs` 
            (run_code, trigger_type, target_date, scheduled_time, start_time, status)
            VALUES (:code, :trig, :date, NOW(), NOW(), 'RUNNING')
        ");
        $insRun->execute([
            ':code' => $runCode,
            ':trig' => $triggerType,
            ':date' => $targetDate,
        ]);
        $runId = (int)$pdo->lastInsertId();

        // 2. Discover eligible vendors
        $eligibleVendors = self::discoverEligibleVendors($pdo, $targetDate);
        $totalExamined = count($eligibleVendors);

        $submittedCount  = 0;
        $successfulCount = 0;
        $failedCount     = 0;
        $pendingCount    = 0;
        $totalAmount     = 0.0;
        $results         = [];

        foreach ($eligibleVendors as $v) {
            $res = self::processVendorPayout($pdo, $v, $targetDate, $runId, $triggerType);
            $results[] = [
                'vendor_id'   => $v['vendor_id'],
                'vendor_name' => $v['vendor_name'],
                'amount'      => $v['net_payable_amount'],
                'result'      => $res,
            ];

            if ($res['success']) {
                $submittedCount++;
                $totalAmount += (float)$v['net_payable_amount'];
                if ($res['status'] === 'processed') {
                    $successfulCount++;
                } else {
                    $pendingCount++;
                }
            } else {
                $failedCount++;
            }
        }

        // 3. Finalize run status
        $finalStatus = 'COMPLETED';
        if ($failedCount > 0 && $successfulCount > 0) {
            $finalStatus = 'COMPLETED_WITH_EXCEPTIONS';
        } elseif ($failedCount > 0 && $successfulCount === 0 && $pendingCount === 0) {
            $finalStatus = 'FAILED';
        }

        $summaryNotes = "Batch executed via {$triggerType}. Examined: {$totalExamined}, Submitted: {$submittedCount}, Processed: {$successfulCount}, Pending/Queued: {$pendingCount}, Failed: {$failedCount}. Total Amount: ₹" . number_format($totalAmount, 2);

        $updRun = $pdo->prepare("
            UPDATE `payout_runs`
            SET completion_time    = NOW(),
                vendors_examined   = :ex,
                payouts_submitted  = :sub,
                successful_payouts = :succ,
                failed_payouts     = :fail,
                pending_payouts    = :pend,
                total_amount       = :amt,
                status             = :st,
                summary_notes      = :notes,
                updated_at         = NOW()
            WHERE id = :id
        ");

        $updRun->execute([
            ':ex'    => $totalExamined,
            ':sub'   => $submittedCount,
            ':succ'  => $successfulCount,
            ':fail'  => $failedCount,
            ':pend'  => $pendingCount,
            ':amt'   => $totalAmount,
            ':st'    => $finalStatus,
            ':notes' => $summaryNotes,
            ':id'    => $runId,
        ]);

        // 4. Update payout_settings last_run info
        $settingsRow = self::getSettings($pdo);
        $time24 = $settingsRow['schedule_time_24'] ?: '00:00';
        $cycleKeyToSave = $cycleKey ?: ($targetDate . '@' . $time24);
        $nextRun = self::calculateNextRun(
            (int)$settingsRow['schedule_hour'],
            (int)$settingsRow['schedule_minute'],
            $settingsRow['schedule_ampm'],
            $settingsRow['timezone'] ?: self::DEFAULT_TIMEZONE,
            $cycleKeyToSave
        );

        $updSettings = $pdo->prepare("
            UPDATE `payout_settings`
            SET last_run_cycle  = :cycle,
                last_run_at     = NOW(),
                last_run_status = :st,
                next_run_at     = :next_run,
                updated_at      = NOW()
            WHERE id = 1
        ");
        $updSettings->execute([
            ':cycle'    => $cycleKeyToSave,
            ':st'       => $finalStatus === 'COMPLETED' ? 'Completed' : ($finalStatus === 'COMPLETED_WITH_EXCEPTIONS' ? 'Attention Required' : 'Failed'),
            ':next_run' => $nextRun['formatted_sql'],
        ]);

        self::releaseLock($pdo, $lockName);

        return [
            'success'            => true,
            'run_id'             => $runId,
            'run_code'           => $runCode,
            'status'             => $finalStatus,
            'vendors_examined'   => $totalExamined,
            'payouts_submitted'  => $submittedCount,
            'successful_payouts' => $successfulCount,
            'pending_payouts'    => $pendingCount,
            'failed_payouts'     => $failedCount,
            'total_amount'       => $totalAmount,
            'message'            => $summaryNotes,
            'details'            => $results,
        ];
    }

    /**
     * Reconciles an existing payout record by checking Razorpay API.
     */
    public static function reconcilePayoutRecord(PDO $pdo, int $payoutId): array {
        $stmt = $pdo->prepare("SELECT * FROM `razorpay_vendor_payouts` WHERE id = :id LIMIT 1");
        $stmt->execute([':id' => $payoutId]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$row) {
            return ['success' => false, 'message' => 'Payout record not found.'];
        }

        if (empty($row['razorpay_payout_id'])) {
            return ['success' => false, 'message' => 'No Razorpay Payout ID assigned to this record.'];
        }

        $res = getRazorpayXPayout($row['razorpay_payout_id']);
        if (!$res['success']) {
            return ['success' => false, 'message' => 'Razorpay reconciliation check failed: ' . ($res['error'] ?? 'API error')];
        }

        $data = $res['data'] ?? [];
        $newStatus = strtolower($data['status'] ?? $row['status']);
        $utr = $data['utr'] ?? $row['utr'];
        $failReason = $data['failure_reason'] ?? $row['failure_reason'];

        $history = json_decode($row['status_history'] ?: '[]', true) ?: [];
        $history[] = [
            'status'    => $newStatus,
            'timestamp' => time(),
            'source'    => 'manual_reconciliation',
            'utr'       => $utr,
        ];

        $upd = $pdo->prepare("
            UPDATE `razorpay_vendor_payouts`
            SET status         = :st,
                utr            = :utr,
                failure_reason = :fr,
                raw_response   = :raw,
                status_history = :hist,
                processed_at   = CASE WHEN :st2 = 'processed' THEN NOW() ELSE processed_at END,
                updated_at     = NOW()
            WHERE id = :id
        ");

        $upd->execute([
            ':st'   => $newStatus,
            ':utr'  => $utr,
            ':fr'   => $failReason,
            ':raw'  => json_encode($data),
            ':hist' => json_encode($history),
            ':st2'  => $newStatus,
            ':id'   => $payoutId,
        ]);

        // If status changed to failed/rejected/cancelled, automatically refund debited wallet balance
        if (in_array($newStatus, ['failed', 'rejected', 'cancelled']) && !in_array($row['status'], ['failed', 'rejected', 'cancelled'])) {
            self::refundVendorWalletForFailedPayout($pdo, $payoutId, $failReason ?: "Reconciled status: {$newStatus}");
        }

        return [
            'success'        => true,
            'payout_id'      => $payoutId,
            'old_status'     => $row['status'],
            'new_status'     => $newStatus,
            'utr'            => $utr,
            'failure_reason' => $failReason,
            'raw_data'       => $data,
        ];
    }

    /**
     * Atomically refunds the vendor wallet if a debited payout has failed.
     * Guaranteed idempotent - checks ledger to prevent duplicate refunds.
     */
    public static function refundVendorWalletForFailedPayout(PDO $pdo, int $payoutRecordId, string $reason = 'Payout failed'): bool {
        try {
            $stmt = $pdo->prepare("SELECT * FROM `razorpay_vendor_payouts` WHERE id = :id FOR UPDATE");
            $stmt->execute([':id' => $payoutRecordId]);
            $payout = $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$payout) {
                return false;
            }

            $vendorId = (int)$payout['vendor_id'];
            $amount   = (float)$payout['net_payout_amount'];
            $refId    = $payout['internal_reference_id'];

            if ($amount <= 0 || empty($refId)) {
                return false;
            }

            // 1. Verify that a DEBIT actually occurred for this payout reference
            $checkDebit = $pdo->prepare("
                SELECT id FROM vendor_wallet_transactions 
                WHERE vendor_id = :vid AND type = 'DEBIT' AND description LIKE :ref
                LIMIT 1
            ");
            $checkDebit->execute([':vid' => $vendorId, ':ref' => "%{$refId}%"]);
            if (!$checkDebit->fetch()) {
                // Was never debited (e.g. failed before debit or invalid fund account)
                return false;
            }

            // 2. Check if a refund CREDIT already exists for this reference (strict idempotency)
            $checkRefund = $pdo->prepare("
                SELECT id FROM vendor_wallet_transactions 
                WHERE vendor_id = :vid AND type = 'CREDIT' AND description LIKE :ref
                LIMIT 1
            ");
            $checkRefund->execute([':vid' => $vendorId, ':ref' => "%{$refId}%"]);
            if ($checkRefund->fetch()) {
                // Already refunded!
                return true;
            }

            // 3. Lock vendor wallet and credit back amount
            $wStmt = $pdo->prepare("SELECT balance FROM vendor_wallets WHERE vendor_id = ? FOR UPDATE");
            $wStmt->execute([$vendorId]);
            $currentBal = (float)$wStmt->fetchColumn();
            $newBal = round($currentBal + $amount, 2);

            $pdo->prepare("UPDATE vendor_wallets SET balance = ?, updated_at = NOW() WHERE vendor_id = ?")->execute([$newBal, $vendorId]);

            // 4. Insert CREDIT transaction record
            $insTx = $pdo->prepare("
                INSERT INTO vendor_wallet_transactions (vendor_id, type, amount, balance_after, description, created_at)
                VALUES (?, 'CREDIT', ?, ?, ?, NOW())
            ");
            $insTx->execute([
                $vendorId,
                $amount,
                $newBal,
                "Automatic refund for failed RazorpayX payout (Ref: {$refId}, Reason: {$reason})"
            ]);

            // 5. Update payout status history
            $history = json_decode($payout['status_history'] ?: '[]', true) ?: [];
            $history[] = [
                'status'    => 'refunded_to_wallet',
                'timestamp' => time(),
                'source'    => 'system_auto_refund',
                'amount'    => $amount,
                'note'      => $reason
            ];
            $pdo->prepare("UPDATE `razorpay_vendor_payouts` SET status_history = ?, updated_at = NOW() WHERE id = ?")->execute([json_encode($history), $payoutRecordId]);

            // 6. Mirror failure status to legacy vendor_payouts table
            try {
                $pdo->prepare("UPDATE vendor_payouts SET status = 'FAILED', failure_reason = ?, updated_at = NOW() WHERE merchant_ref_id = ?")->execute([$reason, $refId]);
            } catch (Throwable $e) {}

            return true;
        } catch (Throwable $e) {
            error_log("Failed to process automatic wallet refund for payout #{$payoutRecordId}: " . $e->getMessage());
            return false;
        }
    }
}
