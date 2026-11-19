<?php
/**
 * POST /api/customer/subscription/resume
 *
 * Resume the customer's currently paused subscription, extending dates.
 */

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendError('Method not allowed. Use POST.', 405);
}

$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || !isset($payload['sub'])) {
    sendError('Unauthorized. Please log in.', 401);
}

$customerId = (int)$payload['sub'];

try {
    $pdo = getDBConnection();
    $pdo->beginTransaction();

    // 1. Fetch latest subscription for update
    $stmt = $pdo->prepare("
        SELECT id, status, end_date, pause_history 
        FROM customer_subscriptions 
        WHERE customer_id = ? 
        ORDER BY id DESC 
        LIMIT 1 
        FOR UPDATE
    ");
    $stmt->execute([$customerId]);
    $subscription = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$subscription) {
        throw new Exception("No subscription found to resume.", 404);
    }

    if ($subscription['status'] !== 'PAUSED') {
        throw new Exception("Only PAUSED subscriptions can be resumed. Current status: " . $subscription['status'], 400);
    }

    // 2. Parse pause history and find the active pause entry
    $history = json_decode($subscription['pause_history'] ?? '[]', true);
    if (empty($history)) {
        throw new Exception("Invalid pause history state.", 400);
    }

    $lastIdx = count($history) - 1;
    $history[$lastIdx]['resumed_at'] = date('Y-m-d H:i:s');

    // Calculate days paused
    $pausedAt = new DateTime($history[$lastIdx]['paused_at']);
    $resumedAt = new DateTime($history[$lastIdx]['resumed_at']);
    $diff = $pausedAt->diff($resumedAt);
    $days = (int)$diff->format('%a');
    if ($days < 1) {
        $days = 1; // Minimum extend is 1 day
    }
    $history[$lastIdx]['paused_days'] = $days;

    // 3. Extend subscription end_date
    $endDate = new DateTime($subscription['end_date']);
    $endDate->modify("+$days days");
    $newEndDateStr = $endDate->format('Y-m-d');

    // 4. Update status, end_date, and pause history
    $updateStmt = $pdo->prepare("
        UPDATE customer_subscriptions 
        SET status = 'ACTIVE', end_date = ?, pause_history = ?, updated_at = NOW() 
        WHERE id = ?
    ");
    $updateStmt->execute([$newEndDateStr, json_encode($history), $subscription['id']]);

    // 5. Shift all PENDING deliveries forward in subscription_deliveries
    $shiftStmt = $pdo->prepare("
        UPDATE subscription_deliveries 
        SET delivery_date = DATE_ADD(delivery_date, INTERVAL ? DAY) 
        WHERE subscription_id = ? AND status = 'PENDING'
    ");
    $shiftStmt->execute([$days, $subscription['id']]);

    $pdo->commit();

    sendSuccess('Subscription resumed successfully. End date extended by ' . $days . ' days.', [
        'subscription_id' => (int)$subscription['id'],
        'status' => 'ACTIVE',
        'extended_days' => $days,
        'new_end_date' => $newEndDateStr
    ]);

} catch (Exception $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    $code = $e->getCode();
    $status = ($code >= 400 && $code <= 500) ? $code : 500;
    sendError($e->getMessage(), $status);
}
