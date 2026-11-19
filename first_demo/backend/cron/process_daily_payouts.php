<?php
/**
 * Cron script: process_daily_payouts.php
 * Automated Daily Payout Job
 * Triggered daily (e.g. via cron or GET /api/cron/process_daily_payouts)
 * Settles TODAY'S EARNINGS for each vendor via PayU Payout API.
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers/response.php';
require_once __DIR__ . '/../helpers/payu_payout_helper.php';

header('Content-Type: application/json; charset=utf-8');

try {
    $pdo = getDBConnection();
    $result = PayUPayoutHelper::processDailyVendorPayouts($pdo);
    sendSuccess('Daily vendor payout processing completed successfully.', $result);
} catch (Throwable $e) {
    sendError('Error executing daily vendor payouts: ' . $e->getMessage(), 500);
}
