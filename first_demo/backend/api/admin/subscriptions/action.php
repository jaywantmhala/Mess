<?php
/**
 * POST /api/admin/subscriptions/action
 *
 * Perform administrative actions on customer subscriptions.
 * Request Body: { subscription_id, action, days (for extend), new_plan_id (for change_plan) }
 */

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/jwt.php';
require_once __DIR__ . '/../../../helpers/fcm.php';

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

// Validate Admin authorization
if (!$payload || !isset($payload['sub'])) {
    sendError('Unauthorized. Please log in.', 401);
}

$body           = json_decode(file_get_contents('php://input'), true);
$subscriptionId = isset($body['subscription_id']) ? (int)$body['subscription_id'] : 0;
$action         = isset($body['action']) ? trim($body['action']) : '';

if ($subscriptionId <= 0 || empty($action)) {
    sendError('subscription_id and action are required.', 422);
}

try {
    $pdo = getDBConnection();
    $pdo->beginTransaction();

    // Fetch subscription details
    $stmt = $pdo->prepare("
        SELECT * 
        FROM customer_subscriptions 
        WHERE id = ? 
        FOR UPDATE
    ");
    $stmt->execute([$subscriptionId]);
    $subscription = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$subscription) {
        throw new Exception("Subscription not found.", 404);
    }

    $customerId = (int)$subscription['customer_id'];
    $oldStatus  = $subscription['status'];

    switch (strtolower($action)) {
        case 'pause':
            if ($oldStatus !== 'ACTIVE') {
                throw new Exception("Only ACTIVE subscriptions can be paused. Current status: $oldStatus", 400);
            }
            $history = json_decode($subscription['pause_history'] ?? '[]', true);
            $history[] = [
                'paused_at'   => date('Y-m-d H:i:s'),
                'resumed_at'  => null,
                'paused_days' => 0
            ];
            $upd = $pdo->prepare("UPDATE customer_subscriptions SET status = 'PAUSED', pause_history = ?, updated_at = NOW() WHERE id = ?");
            $upd->execute([json_encode($history), $subscriptionId]);
            
            FcmHelper::sendToCustomer($customerId, "Subscription Paused", "An administrator has paused your subscription.");
            break;

        case 'resume':
            if ($oldStatus !== 'PAUSED') {
                throw new Exception("Only PAUSED subscriptions can be resumed. Current status: $oldStatus", 400);
            }
            $history = json_decode($subscription['pause_history'] ?? '[]', true);
            if (empty($history)) {
                throw new Exception("Pause history empty or corrupt.", 400);
            }
            $lastIdx = count($history) - 1;
            $history[$lastIdx]['resumed_at'] = date('Y-m-d H:i:s');

            $pausedAt = new DateTime($history[$lastIdx]['paused_at']);
            $resumedAt = new DateTime($history[$lastIdx]['resumed_at']);
            $diff = $pausedAt->diff($resumedAt);
            $days = (int)$diff->format('%a');
            if ($days < 1) {
                $days = 1;
            }
            $history[$lastIdx]['paused_days'] = $days;

            $endDate = new DateTime($subscription['end_date']);
            $endDate->modify("+$days days");
            $newEndDateStr = $endDate->format('Y-m-d');

            $upd = $pdo->prepare("UPDATE customer_subscriptions SET status = 'ACTIVE', end_date = ?, pause_history = ?, updated_at = NOW() WHERE id = ?");
            $upd->execute([$newEndDateStr, json_encode($history), $subscriptionId]);

            // Shift pending deliveries
            $shift = $pdo->prepare("UPDATE subscription_deliveries SET delivery_date = DATE_ADD(delivery_date, INTERVAL ? DAY) WHERE subscription_id = ? AND status = 'PENDING'");
            $shift->execute([$days, $subscriptionId]);

            FcmHelper::sendToCustomer($customerId, "Subscription Resumed", "Your subscription is now ACTIVE. End date extended by $days days.");
            break;

        case 'extend':
            $extendDays = isset($body['days']) ? (int)$body['days'] : 0;
            if ($extendDays <= 0) {
                throw new Exception("Number of extension days must be greater than 0.", 422);
            }

            $endDate = new DateTime($subscription['end_date']);
            $endDate->modify("+$extendDays days");
            $newEndDateStr = $endDate->format('Y-m-d');

            $upd = $pdo->prepare("UPDATE customer_subscriptions SET end_date = ?, updated_at = NOW() WHERE id = ?");
            $upd->execute([$newEndDateStr, $subscriptionId]);

            // Shift pending deliveries
            $shift = $pdo->prepare("UPDATE subscription_deliveries SET delivery_date = DATE_ADD(delivery_date, INTERVAL ? DAY) WHERE subscription_id = ? AND status = 'PENDING'");
            $shift->execute([$extendDays, $subscriptionId]);

            FcmHelper::sendToCustomer($customerId, "Subscription Extended", "Your subscription end date has been extended by $extendDays days to $newEndDateStr.");
            break;

        case 'cancel':
            $upd = $pdo->prepare("UPDATE customer_subscriptions SET status = 'CANCELLED', expiration_timestamp = NOW(), updated_at = NOW() WHERE id = ?");
            $upd->execute([$subscriptionId]);

            // Cancel all pending deliveries
            $cancelDel = $pdo->prepare("UPDATE subscription_deliveries SET status = 'CANCELLED' WHERE subscription_id = ? AND status = 'PENDING'");
            $cancelDel->execute([$subscriptionId]);

            FcmHelper::sendToCustomer($customerId, "Subscription Cancelled", "Your subscription has been cancelled by an administrator.");
            break;

        case 'change_plan':
            $newPlanId = isset($body['new_plan_id']) ? (int)$body['new_plan_id'] : 0;
            if ($newPlanId <= 0) {
                throw new Exception("new_plan_id is required to change plan.", 422);
            }

            // Fetch new plan details
            $pStmt = $pdo->prepare("SELECT plan_name, duration, total_deliveries FROM subscription_plans WHERE id = ?");
            $pStmt->execute([$newPlanId]);
            $newPlan = $pStmt->fetch(PDO::FETCH_ASSOC);
            if (!$newPlan) {
                throw new Exception("New plan not found.", 404);
            }

            // Fetch old plan details
            $oldPStmt = $pdo->prepare("SELECT total_deliveries FROM subscription_plans WHERE id = ?");
            $oldPStmt->execute([$subscription['plan_id']]);
            $oldPlanTotal = (int)$oldPStmt->fetchColumn();

            $diff = (int)$newPlan['total_deliveries'] - $oldPlanTotal;
            $newRemaining = max(0, (int)$subscription['remaining_deliveries'] + $diff);
            $newTotal = max(0, (int)$subscription['total_deliveries'] + $diff);

            // Extend end date by duration difference if needed
            $upd = $pdo->prepare("
                UPDATE customer_subscriptions 
                SET plan_id = ?, 
                    remaining_deliveries = ?, 
                    total_deliveries = ?, 
                    updated_at = NOW() 
                WHERE id = ?
            ");
            $upd->execute([$newPlanId, $newRemaining, $newTotal, $subscriptionId]);

            // If new plan has more deliveries, append them to schedule
            if ($diff > 0) {
                $lastDelDateStr = $pdo->query("SELECT MAX(delivery_date) FROM subscription_deliveries WHERE subscription_id = $subscriptionId")->fetchColumn() ?: date('Y-m-d');
                $lastDelDate = new DateTime($lastDelDateStr);
                $lastDelDate->modify('+1 day');

                $insStmt = $pdo->prepare("INSERT INTO subscription_deliveries (subscription_id, customer_id, delivery_date, status) VALUES (?, ?, ?, 'PENDING')");
                for ($i = 0; $i < $diff; $i++) {
                    $insStmt->execute([$subscriptionId, $customerId, $lastDelDate->format('Y-m-d')]);
                    $lastDelDate->modify('+1 day');
                }
            } else if ($diff < 0) {
                // Delete excess pending deliveries
                $excess = abs($diff);
                $pdo->exec("
                    DELETE FROM subscription_deliveries 
                    WHERE subscription_id = $subscriptionId AND status = 'PENDING' 
                    LIMIT $excess
                ");
            }

            FcmHelper::sendToCustomer($customerId, "Subscription Plan Changed", "Your subscription plan has been changed to " . $newPlan['plan_name'] . ".");
            break;

        default:
            throw new Exception("Unknown action: $action", 400);
    }

    $pdo->commit();

    sendSuccess("Action '$action' processed successfully.", [
        'subscription_id' => $subscriptionId,
        'action' => $action
    ]);

} catch (Exception $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    $code = $e->getCode();
    $status = ($code >= 400 && $code <= 500) ? $code : 500;
    sendError($e->getMessage(), $status);
}
