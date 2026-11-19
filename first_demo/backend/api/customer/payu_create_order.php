<?php
/**
 * POST /api/customer/payu/create_order
 *
 * Creates a PayU Order for buying or renewing a subscription plan.
 * Validates plan price server-side (never trusting client amount) and generates PayU hash.
 *
 * Request Body: { plan_id: int }
 * Headers: Authorization: Bearer <token>
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/payu.php';
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

    // 1. Fetch subscription plan & validate price on backend
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
            'is_active' => true
        ];
    }

    if (!$plan['is_active']) {
        throw new Exception("Selected subscription plan is deactivated.", 422);
    }

    $planName  = $plan['plan_name'];
    $planPrice = (float)$plan['price'];
    $amountFormatted = number_format($planPrice, 2, '.', '');
    $amountInPaise   = (int)round($planPrice * 100);

    // 2. Fetch customer info
    $cStmt = $pdo->prepare("SELECT id, full_name, email FROM customers WHERE id = ?");
    $cStmt->execute([$customerId]);
    $customer = $cStmt->fetch(PDO::FETCH_ASSOC);

    $custName  = !empty($customer['full_name']) ? $customer['full_name'] : 'Customer ' . $customerId;
    $firstName = explode(' ', trim($custName))[0];
    if (empty($firstName)) $firstName = 'Customer';
    $custEmail = !empty($customer['email']) ? $customer['email'] : 'customer' . $customerId . '@hungrilyfoods.com';
    $custPhone = '9876543210';

    // 3. Generate unique transaction ID & receipt
    $txnid     = "TXN_" . $customerId . "_" . time() . "_" . mt_rand(1000, 9999);
    $productInfo = $planName;

    // 4. Calculate PayU Hash
    $hashParams = [
        'txnid'       => $txnid,
        'amount'      => $amountFormatted,
        'productinfo' => $productInfo,
        'firstname'   => $firstName,
        'email'       => $custEmail,
        'udf1'        => (string)$customerId,
        'udf2'        => (string)$planId,
        'udf3'        => '',
        'udf4'        => '',
        'udf5'        => '',
    ];
    $hash = generatePayUHash($hashParams);

    // 5. Ensure payu_payments table exists and save payment attempt record
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS `payu_payments` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `customer_id` INT NOT NULL,
            `internal_transaction_id` VARCHAR(100) NOT NULL,
            `plan_id` INT DEFAULT NULL,
            `txnid` VARCHAR(100) NOT NULL,
            `mihpayid` VARCHAR(100) DEFAULT NULL,
            `amount` DECIMAL(10,2) NOT NULL,
            `currency` VARCHAR(10) DEFAULT 'INR',
            `status` VARCHAR(50) NOT NULL DEFAULT 'created',
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            KEY `idx_payu_txnid` (`txnid`),
            KEY `idx_payu_mihpayid` (`mihpayid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");

    $insStmt = $pdo->prepare("
        INSERT INTO payu_payments 
            (customer_id, internal_transaction_id, plan_id, txnid, amount, currency, status, created_at, updated_at)
        VALUES 
            (?, ?, ?, ?, ?, 'INR', 'created', NOW(), NOW())
    ");
    $insStmt->execute([
        $customerId,
        $txnid,
        $planId,
        $txnid,
        $planPrice
    ]);

    // Also populate razorpay_payments if it exists for backwards-compatibility checks
    try {
        $insLegacy = $pdo->prepare("
            INSERT INTO razorpay_payments 
                (customer_id, internal_transaction_id, plan_id, order_id, razorpay_order_id, amount, currency, status, created_at, updated_at)
            VALUES 
                (?, ?, ?, ?, ?, ?, 'INR', 'created', NOW(), NOW())
        ");
        $insLegacy->execute([$customerId, $txnid, $planId, $txnid, $txnid, $planPrice]);
    } catch (Exception $ex) {}

    $scheme = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on') ? "https" : "http";
    $host = $_SERVER['HTTP_HOST'] ?? 'localhost:8000';
    $surl = "$scheme://$host/api/customer/payu/success";
    $furl = "$scheme://$host/api/customer/payu/failure";

    sendSuccess('PayU payment order created successfully.', [
        'order_id'                => $txnid,
        'txnid'                   => $txnid,
        'internal_transaction_id' => $txnid,
        'key'                     => PAYU_MERCHANT_KEY,
        'key_id'                  => PAYU_MERCHANT_KEY,
        'amount'                  => $planPrice,
        'amount_formatted'        => $amountFormatted,
        'amount_paise'            => $amountInPaise,
        'currency'                => 'INR',
        'productinfo'             => $productInfo,
        'firstname'               => $firstName,
        'customer_name'           => $custName,
        'customer_email'          => $custEmail,
        'customer_phone'          => $custPhone,
        'hash'                    => $hash,
        'action'                  => PAYU_BASE_URL,
        'surl'                    => $surl,
        'furl'                    => $furl,
        'udf1'                    => (string)$customerId,
        'udf2'                    => (string)$planId,
        'status'                  => 'created',
        'plan_id'                 => $planId,
        'plan_name'               => $planName,
    ]);

} catch (Exception $e) {
    $rawCode = $e->getCode();
    $code    = is_numeric($rawCode) ? (int)$rawCode : 500;
    $status  = ($code >= 400 && $code <= 599) ? $code : 500;
    sendError($e->getMessage(), $status);
}
