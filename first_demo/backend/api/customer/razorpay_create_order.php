<?php
/**
 * POST /api/customer/razorpay/create_order
 *
 * Creates a Razorpay Order for purchasing a subscription plan or paying for an order.
 *
 * Request Body: { plan_id: int, amount?: float }
 * Headers: Authorization: Bearer <token>
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/razorpay.php';
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
$planId = isset($body['plan_id']) ? (int)$body['plan_id'] : 1;
$customAmount = isset($body['amount']) ? (float)$body['amount'] : null;

try {
    $pdo = getDBConnection();

    // 1. Resolve Amount and Product Info
    $planName = 'Subscription Plan';
    $finalPrice = 199.00;

    if ($customAmount !== null && $customAmount > 0) {
        $finalPrice = round($customAmount, 2);
        $planName = 'Food Delivery Order';
    } else {
        // Fetch subscription plan
        $stmt = $pdo->prepare("SELECT id, plan_name, price, (status = 'active') AS is_active FROM plans WHERE id = ?");
        $stmt->execute([$planId]);
        $plan = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$plan) {
            $stmt = $pdo->prepare("SELECT id, plan_name, price, is_active FROM subscription_plans WHERE id = ?");
            $stmt->execute([$planId]);
            $plan = $stmt->fetch(PDO::FETCH_ASSOC);
        }

        if (!$plan) {
            $defaultPlans = [
                1 => ['plan_name' => 'Monthly Plan', 'price' => 199.0],
                2 => ['plan_name' => 'Quarterly Plan', 'price' => 499.0],
                3 => ['plan_name' => 'Yearly Plan', 'price' => 1499.0],
            ];
            $plan = [
                'id'        => $planId,
                'plan_name' => $defaultPlans[$planId]['plan_name'] ?? 'Monthly Subscription',
                'price'     => $defaultPlans[$planId]['price'] ?? 199.0,
                'is_active' => true,
            ];
        }

        if (empty($plan['is_active'])) {
            throw new Exception("Selected subscription plan is deactivated.", 422);
        }

        $planName   = $plan['plan_name'];
        $finalPrice = (float)$plan['price'];
    }

    $amountFormatted = number_format($finalPrice, 2, '.', '');
    $amountInPaise   = (int)round($finalPrice * 100);

    // 2. Fetch customer info
    $cStmt = $pdo->prepare("SELECT id, full_name, email, phone, phone_number FROM customers WHERE id = ?");
    $cStmt->execute([$customerId]);
    $customer = $cStmt->fetch(PDO::FETCH_ASSOC);

    $custName  = !empty($customer['full_name']) ? $customer['full_name'] : 'Customer ' . $customerId;
    $firstName = explode(' ', trim($custName))[0];
    if (empty($firstName)) $firstName = 'Customer';
    $custEmail = !empty($customer['email']) ? $customer['email'] : 'customer' . $customerId . '@hungrilyfoods.com';
    $custPhone = !empty($customer['phone_number']) ? $customer['phone_number'] : (!empty($customer['phone']) ? $customer['phone'] : '9876543210');

    // 3. Create Real Razorpay Order via API
    $receipt = "rcpt_" . $customerId . "_" . time();
    $rzpRes = createRazorpayOrder([
        'amount'   => $amountInPaise,
        'currency' => 'INR',
        'receipt'  => $receipt,
        'notes'    => [
            'customer_id' => (string)$customerId,
            'plan_id'     => (string)$planId,
            'plan_name'   => $planName,
        ],
    ]);

    if (!$rzpRes['success'] || empty($rzpRes['id'])) {
        $errDetail = $rzpRes['error'] ?? 'Failed to communicate with Razorpay API.';
        error_log("[Razorpay Create Order Error]: $errDetail");
        throw new Exception("Razorpay order creation failed: $errDetail", 500);
    }

    $rzpOrderId = $rzpRes['id']; // e.g. order_U2JI6TOHr4qXIp

    // 4. Save record in database
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS `razorpay_payments` (
            `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `order_id` VARCHAR(100) NOT NULL UNIQUE,
            `customer_id` INT UNSIGNED NOT NULL,
            `plan_id` INT UNSIGNED NOT NULL,
            `amount` DECIMAL(10,2) NOT NULL,
            `status` VARCHAR(50) NOT NULL DEFAULT 'CREATED',
            `razorpay_payment_id` VARCHAR(100) DEFAULT NULL,
            `razorpay_signature` VARCHAR(255) DEFAULT NULL,
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            `internal_transaction_id` VARCHAR(100) DEFAULT NULL,
            `razorpay_order_id` VARCHAR(100) DEFAULT NULL,
            `currency` VARCHAR(10) NOT NULL DEFAULT 'INR',
            `failure_code` VARCHAR(100) DEFAULT NULL,
            `failure_message` TEXT DEFAULT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");

    $insStmt = $pdo->prepare("
        INSERT INTO razorpay_payments 
            (order_id, customer_id, plan_id, amount, status, internal_transaction_id, razorpay_order_id, currency, created_at, updated_at)
        VALUES 
            (?, ?, ?, ?, 'CREATED', ?, ?, 'INR', NOW(), NOW())
        ON DUPLICATE KEY UPDATE 
            amount = VALUES(amount),
            updated_at = NOW()
    ");
    $insStmt->execute([
        $rzpOrderId,
        $customerId,
        $planId,
        $finalPrice,
        $receipt,
        $rzpOrderId,
    ]);

    // Also populate payu_payments for backward compatibility
    try {
        $insPayU = $pdo->prepare("
            INSERT INTO payu_payments 
                (customer_id, internal_transaction_id, plan_id, txnid, amount, currency, status, created_at, updated_at)
            VALUES 
                (?, ?, ?, ?, ?, 'INR', 'created', NOW(), NOW())
            ON DUPLICATE KEY UPDATE updated_at = NOW()
        ");
        $insPayU->execute([$customerId, $receipt, $planId, $rzpOrderId, $finalPrice]);
    } catch (Exception $ex) {}

    sendSuccess('Razorpay payment order created successfully.', [
        'order_id'                => $rzpOrderId,
        'txnid'                   => $rzpOrderId,
        'razorpay_order_id'       => $rzpOrderId,
        'internal_transaction_id' => $receipt,
        'key'                     => RAZORPAY_KEY_ID,
        'key_id'                  => RAZORPAY_KEY_ID,
        'amount'                  => $finalPrice,
        'amount_formatted'        => $amountFormatted,
        'amount_paise'            => $amountInPaise,
        'currency'                => 'INR',
        'productinfo'             => $planName,
        'plan_name'               => $planName,
        'firstname'               => $firstName,
        'customer_name'           => $custName,
        'customer_email'          => $custEmail,
        'customer_phone'          => $custPhone,
        'status'                  => 'created',
        'plan_id'                 => $planId,
    ]);

} catch (Exception $e) {
    $rawCode = $e->getCode();
    $code    = is_numeric($rawCode) ? (int)$rawCode : 500;
    $status  = ($code >= 400 && $code <= 599) ? $code : 500;
    sendError($e->getMessage(), $status);
}
