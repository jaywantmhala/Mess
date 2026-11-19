<?php
/**
 * RazorpayX Automated Vendor Payout Scheduler & Dispatcher
 *
 * Designed for both:
 * 1. Local Development (Windows Task Scheduler / XAMPP):
 *    Triggered every minute via Windows Task Scheduler or background runner.
 * 2. Production Deployment (Linux Crontab / Hostinger / cPanel):
 *    Triggered every minute via `* * * * * php .../payout_dispatcher.php`.
 *
 * Core Principles:
 * - Reads admin-configured schedule dynamically from MySQL.
 * - Timezone: Asia/Kolkata (IST).
 * - Atomic database locking via `payout_execution_lock` prevents overlapping executions.
 * - Daily cycle tracking via `payout_settings.last_run_cycle` guarantees exactly one daily run.
 * - Resumes gracefully after system sleep/restarts if a scheduled time was missed.
 * - Does NOT require admin panel to be open or browser to be active.
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers/razorpayx_payout_service.php';

date_default_timezone_set('Asia/Kolkata');

$isCli = (php_sapi_name() === 'cli');
$logDir = __DIR__ . '/../logs';
if (!is_dir($logDir)) {
    @mkdir($logDir, 0755, true);
}
$logFile = $logDir . '/payout_cron.log';

$log = function(string $msg) use ($isCli, $logFile) {
    $timestamp = date('Y-m-d H:i:s');
    $formatted = "[{$timestamp} IST] [Dispatcher] {$msg}\n";
    if ($isCli) {
        echo $formatted;
    }
    @file_put_contents($logFile, $formatted, FILE_APPEND);
};

if (!$isCli) {
    header('Content-Type: application/json; charset=utf-8');
}

try {
    $pdo = getDBConnection();
    $settings = RazorpayXPayoutService::getSettings($pdo);

    // 1. Check if Automatic Payouts are enabled
    if (empty($settings['auto_payout_enabled'])) {
        $msg = "Automatic vendor payouts are DISABLED in settings. Sleeping.";
        $log($msg);
        if (!$isCli) echo json_encode(['success' => true, 'executed' => false, 'message' => $msg]);
        exit(0);
    }

    $now = new DateTime('now', new DateTimeZone('Asia/Kolkata'));
    $currentTime24   = $now->format('H:i');
    $scheduledTime24 = $settings['schedule_time_24'] ?: '00:00';
    $todayDate       = $now->format('Y-m-d');
    $cycleKey        = $todayDate . '@' . $scheduledTime24;

    // 2. Check if this exact schedule cycle already executed
    if (!empty($settings['last_run_cycle']) && ($settings['last_run_cycle'] === $cycleKey || $settings['last_run_cycle'] === $todayDate)) {
        // If settings were updated AFTER last_run_at, allow the newly saved schedule to run
        $lastRunAt = !empty($settings['last_run_at']) ? strtotime($settings['last_run_at']) : 0;
        $updatedAt = !empty($settings['updated_at']) ? strtotime($settings['updated_at']) : 0;

        if ($settings['last_run_cycle'] === $cycleKey && $updatedAt <= $lastRunAt) {
            $msg = "Schedule [{$scheduledTime24} IST] for today ({$todayDate}) already completed at " . ($settings['last_run_at'] ?? 'earlier') . ". Next run: " . ($settings['next_run_at'] ?? 'tomorrow');
            $log($msg);
            if (!$isCli) echo json_encode(['success' => true, 'executed' => false, 'message' => $msg]);
            exit(0);
        }
    }

    // 3. Check if current time has reached or passed the scheduled time for today
    if ($currentTime24 < $scheduledTime24) {
        $msg = "Waiting for scheduled execution time: Current {$currentTime24} IST < Scheduled {$scheduledTime24} IST.";
        $log($msg);
        if (!$isCli) echo json_encode(['success' => true, 'executed' => false, 'message' => $msg]);
        exit(0);
    }

    // 4. Scheduled time reached! Execute Payout Batch Worker!
    $log("Scheduled time reached ({$currentTime24} >= {$scheduledTime24} IST). Initiating automated batch worker for {$todayDate} (Cycle: {$cycleKey})...");

    $result = RazorpayXPayoutService::executePayoutBatch($pdo, 'scheduled', $todayDate, $cycleKey);

    $summaryMessage = $result['message'] ?? 'Batch executed.';
    $log("Result: {$summaryMessage}");

    if (!$isCli) {
        echo json_encode([
            'success'  => $result['success'] ?? false,
            'executed' => true,
            'cycle'    => $todayCycle,
            'result'   => $result,
        ]);
    }
    exit(0);

} catch (Throwable $e) {
    $errorMsg = "FATAL ERROR: " . $e->getMessage() . " in " . $e->getFile() . ":" . $e->getLine();
    $log($errorMsg);
    error_log("[RazorpayX Payout Dispatcher] " . $errorMsg);

    if (!$isCli) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error'   => $e->getMessage()
        ]);
    }
    exit(1);
}
