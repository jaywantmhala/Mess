<?php
/**
 * POST /api/customer/subscription/pause
 *
 * Pause the customer's currently active subscription.
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
        SELECT id, status, pause_history 
        FROM customer_subscriptions 
        WHERE customer_id = ? 
        ORDER BY id DESC 
        LIMIT 1 
        FOR UPDATE
    ");
    $stmt->execute([$customerId]);
    $subscription = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$subscription) {
        throw new Exception("No subscription found to pause.", 404);
    }

    if ($subscription['status'] !== 'ACTIVE') {
        throw new Exception("Only ACTIVE subscriptions can be paused. Current status: " . $subscription['status'], 400);
    }

    // 2. Parse pause history and append new pause block
    $history = json_decode($subscription['pause_history'] ?? '[]', true);
    $history[] = [
        'paused_at' => date('Y-m-d H:i:s'),
        'resumed_at' => null,
        'paused_days' => 0
    ];

    // 3. Update status and pause history
    $updateStmt = $pdo->prepare("
        UPDATE customer_subscriptions 
        SET status = 'PAUSED', pause_history = ?, updated_at = NOW() 
        WHERE id = ?
    ");
    $updateStmt->execute([json_encode($history), $subscription['id']]);

    $pdo->commit();

    sendSuccess('Subscription paused successfully.', [
        'subscription_id' => (int)$subscription['id'],
        'status' => 'PAUSED'
    ]);

} catch (Exception $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    $code = $e->getCode();
    $status = ($code >= 400 && $code <= 500) ? $code : 500;
    sendError($e->getMessage(), $status);
}
