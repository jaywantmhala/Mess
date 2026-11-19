<?php
/**
 * POST /api/customer/cashfree/create_order
 *
 * Creates a Cashfree Payment Order for buying a subscription plan.
 *
 * Request Body: { plan_id: int }
 * Headers: Authorization: Bearer <token>
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/cashfree.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/jwt.php';

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

// ── JWT Authentication ────────────────────────────────────────────────────────
$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || !isset($payload['sub'])) {
    sendError('Unauthorized. Please log in.', 401);
}

$customerId = (int)$payload['sub'];

// ── Parse request body ────────────────────────────────────────────────────────
$body = json_decode(file_get_contents('php://input'), true);
if (!isset($body['plan_id'])) {
    sendError('Plan ID is required.', 422);
}

$planId = (int)$body['plan_id'];

try {
    $pdo = getDBConnection();

    // 1. Fetch subscription plan (check new plans table first)
    $stmt = $pdo->prepare("SELECT id, plan_name, price, (status = 'active') AS is_active FROM plans WHERE id = ?");
    $stmt->execute([$planId]);
    $plan = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$plan) {
        $stmt = $pdo->prepare("SELECT id, plan_name, price, is_active FROM subscription_plans WHERE id = ?");
        $stmt->execute([$planId]);
        $plan = $stmt->fetch(PDO::FETCH_ASSOC);
    }

    if (!$plan) {
        // Fallback default plans if not in DB yet
        $defaultPlans = [
            1 => ['plan_name' => 'Monthly Plan', 'price' => 199.0],
            2 => ['plan_name' => 'Quarterly Plan', 'price' => 499.0],
            3 => ['plan_name' => 'Yearly Plan', 'price' => 1499.0],
        ];
        if (isset($defaultPlans[$planId])) {
            $plan = [
                'id'        => $planId,
                'plan_name' => $defaultPlans[$planId]['plan_name'],
                'price'     => $defaultPlans[$planId]['price'],
                'is_active' => true
            ];
        } else {
            throw new Exception("Subscription plan not found.", 404);
        }
    }

    if (!$plan['is_active']) {
        throw new Exception("Selected subscription plan is deactivated.", 422);
    }

    $planName  = $plan['plan_name'];
    $planPrice = (float)$plan['price'];

    // 2. Fetch customer info
    $cStmt = $pdo->prepare("SELECT id, full_name, email FROM customers WHERE id = ?");
    $cStmt->execute([$customerId]);
    $customer = $cStmt->fetch(PDO::FETCH_ASSOC);

    $custName  = !empty($customer['full_name']) ? $customer['full_name'] : 'Customer ' . $customerId;
    $custEmail = !empty($customer['email']) ? $customer['email'] : 'customer' . $customerId . '@example.com';
    $custPhone = '9876543210'; // Valid 10-digit phone for Cashfree requirements

    // 3. Ensure cashfree_payments table exists
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS `cashfree_payments` (
            `id`                 INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `order_id`           VARCHAR(100) NOT NULL UNIQUE,
            `customer_id`        INT UNSIGNED NOT NULL,
            `plan_id`            INT UNSIGNED NOT NULL,
            `amount`             DECIMAL(10,2) NOT NULL,
            `payment_session_id` VARCHAR(255) DEFAULT NULL,
            `order_status`       VARCHAR(50) NOT NULL DEFAULT 'CREATED',
            `cf_payment_id`      VARCHAR(100) DEFAULT NULL,
            `created_at`         DATETIME DEFAULT CURRENT_TIMESTAMP,
            `updated_at`         DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            CONSTRAINT `fk_cf_cust` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");

    // 4. Generate unique order_id
    $orderId = "SUB_" . $planId . "_" . $customerId . "_" . time() . rand(10, 99);

    // 5. Call Cashfree Orders API
    $scheme = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on') ? "https" : "http";
    $host   = $_SERVER['HTTP_HOST'] ?? 'localhost:8000';

    $cashfreeReq = [
        'order_amount'   => $planPrice,
        'order_currency' => 'INR',
        'order_id'       => $orderId,
        'customer_details' => [
            'customer_id'    => 'CUST_' . $customerId,
            'customer_name'  => $custName,
            'customer_email' => $custEmail,
            'customer_phone' => $custPhone,
        ],
        'order_meta' => [
            'return_url' => "$scheme://$host/api/customer/payu/success?order_id=$orderId",
        ],
        'order_note' => 'Subscription Purchase: ' . $planName,
    ];

    $response = callCashfreeAPI('/orders', 'POST', $cashfreeReq);

    if ($response['status_code'] !== 200 && $response['status_code'] !== 201) {
        $msg = $response['body']['message'] ?? 'Failed to create Cashfree payment session.';
        throw new Exception("Cashfree Error ($response[status_code]): $msg", 400);
    }

    $cfBody           = $response['body'];
    $paymentSessionId = $cfBody['payment_session_id'] ?? null;

    if (!$paymentSessionId) {
        throw new Exception("Payment session ID not returned by Cashfree.", 500);
    }

    // 6. Save payment session record
    $insStmt = $pdo->prepare("
        INSERT INTO cashfree_payments (order_id, customer_id, plan_id, amount, payment_session_id, order_status)
        VALUES (?, ?, ?, ?, ?, 'CREATED')
    ");
    $insStmt->execute([$orderId, $customerId, $planId, $planPrice, $paymentSessionId]);

    sendSuccess('Cashfree payment order created successfully.', [
        'order_id'           => $orderId,
        'payment_session_id' => $paymentSessionId,
        'environment'        => CASHFREE_ENV,
        'amount'             => $planPrice,
        'plan_id'            => $planId,
        'plan_name'          => $planName,
    ]);

} catch (Exception $e) {
    $code = $e->getCode();
    $status = ($code >= 400 && $code <= 500) ? $code : 500;
    sendError($e->getMessage(), $status);
}
