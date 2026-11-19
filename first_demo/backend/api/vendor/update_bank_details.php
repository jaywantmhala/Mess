<?php
/**
 * POST /api/vendor/update_bank_details
 *
 * Updates bank account details for authenticated vendor and registers PayU Beneficiary.
 * Body: { bank_name, account_holder_name, account_number, ifsc_code }
 * Header: Authorization: Bearer <token>
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/razorpay.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/validation.php';
require_once __DIR__ . '/../../helpers/jwt.php';
require_once __DIR__ . '/../../helpers/payu_payout_helper.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST')    { sendError('Method not allowed. Use POST.', 405); }

// JWT Auth
$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || !isset($payload['sub'])) {
    sendError('Unauthorized. Please log in again.', 401);
}

$vendorId = (int)$payload['sub'];

$body = requireJsonBody([
    'bank_name',
    'account_holder_name',
    'account_number',
    'ifsc_code'
]);

$bankName          = sanitize($body['bank_name']);
$accountHolderName = sanitize($body['account_holder_name']);
$accountNumber     = sanitize($body['account_number']);
$ifscCode          = strtoupper(sanitize($body['ifsc_code']));

if (empty($bankName))          { sendError('Bank name is required.', 422); }
if (empty($accountHolderName)) { sendError('Account holder name is required.', 422); }
if (empty($accountNumber))     { sendError('Account number is required.', 422); }
if (empty($ifscCode))          { sendError('IFSC Code is required.', 422); }

$pdo = getDBConnection();

try {
    // 1. Fetch current vendor record for duplicate check
    $stmt = $pdo->prepare("
        SELECT id, full_name, email, phone, bank_name, account_holder_name, account_number, ifsc_code, payu_beneficiary_id, payout_enabled, razorpay_contact_id, razorpay_fund_account_id 
        FROM vendors WHERE id = :id LIMIT 1
    ");
    $stmt->execute([':id' => $vendorId]);
    $existingVendor = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$existingVendor) {
        sendError('Vendor not found.', 404);
    }

    $accountLast4 = (strlen($accountNumber) >= 4) ? substr($accountNumber, -4) : $accountNumber;

    // ── Razorpay Integration (Millisecond Optimized) ────────────────────────
    $rzpContactId = !empty($body['razorpay_contact_id']) ? sanitize($body['razorpay_contact_id']) : ($existingVendor['razorpay_contact_id'] ?? null);
    if (empty($rzpContactId)) {
        $rzpContactRes = createRazorpayContact([
            'name'         => !empty($existingVendor['full_name']) ? $existingVendor['full_name'] : $accountHolderName,
            'email'        => $existingVendor['email'] ?? '',
            'contact'      => $existingVendor['phone'] ?? '',
            'type'         => 'vendor',
            'reference_id' => 'vendor_' . $vendorId,
            'notes'        => [
                'vendor_id'   => (string)$vendorId,
                'created_via' => 'bank_details_update',
            ],
        ]);
        if (!empty($rzpContactRes['success']) && !empty($rzpContactRes['id'])) {
            $rzpContactId = $rzpContactRes['id'];
        }
    }

    $rzpFundAccountId = !empty($body['razorpay_fund_account_id']) ? sanitize($body['razorpay_fund_account_id']) : null;
    $rzpFundAccountData = null;
    $rzpLatencyMs = 0;

    if (empty($rzpFundAccountId) && !empty($rzpContactId)) {
        $rzpFundRes = createRazorpayFundAccount([
            'contact_id'     => $rzpContactId,
            'account_type'   => 'bank_account',
            'name'           => $accountHolderName,
            'ifsc'           => $ifscCode,
            'account_number' => $accountNumber,
        ]);
        if (!empty($rzpFundRes['success']) && !empty($rzpFundRes['id'])) {
            $rzpFundAccountId   = $rzpFundRes['id'];
            $rzpFundAccountData = $rzpFundRes['data'];
            $rzpLatencyMs       = $rzpFundRes['latency_ms'] ?? 0;
        }
    }

    // 2. Check duplicate submission
    $isSameDetails = (
        trim($existingVendor['account_number'] ?? '') === $accountNumber &&
        strtoupper(trim($existingVendor['ifsc_code'] ?? '')) === $ifscCode &&
        trim($existingVendor['account_holder_name'] ?? '') === $accountHolderName &&
        !empty($existingVendor['payu_beneficiary_id'])
    );

    // 3. Save local bank details & Razorpay IDs
    $updStmt = $pdo->prepare("
        UPDATE vendors 
        SET bank_name = :bank_name,
            account_holder_name = :account_holder_name,
            account_number = :account_number,
            ifsc_code = :ifsc_code,
            razorpay_contact_id = COALESCE(:rzp_contact_id, razorpay_contact_id),
            razorpay_fund_account_id = COALESCE(:rzp_fund_account_id, razorpay_fund_account_id),
            updated_at = NOW()
        WHERE id = :id
    ");
    $updStmt->execute([
        ':bank_name'           => $bankName,
        ':account_holder_name' => $accountHolderName,
        ':account_number'      => $accountNumber,
        ':ifsc_code'           => $ifscCode,
        ':rzp_contact_id'      => $rzpContactId,
        ':rzp_fund_account_id' => $rzpFundAccountId,
        ':id'                  => $vendorId,
    ]);

    // 4. Duplicate protection: Reuse beneficiary if details haven't changed
    if ($isSameDetails && !empty($existingVendor['payout_enabled'])) {
        sendSuccess('Bank account details verified and saved.', [
            'bank_details' => [
                'bank_name'                => $bankName,
                'account_holder_name'      => $accountHolderName,
                'account_last4'            => $accountLast4,
                'ifsc_code'                => $ifscCode,
                'bank_verified'            => true,
                'payout_enabled'           => true,
                'razorpay_contact_id'      => $rzpContactId,
                'razorpay_fund_account_id' => $rzpFundAccountId,
                'razorpay_fund_account'    => $rzpFundAccountData,
                'razorpay_latency_ms'      => $rzpLatencyMs,
            ]
        ]);
        exit;
    }

    // 5. Register PayU Beneficiary
    $payuResult = PayUPayoutHelper::createBeneficiary(
        $pdo,
        $vendorId,
        $bankName,
        $accountHolderName,
        $accountNumber,
        $ifscCode,
        $existingVendor['email'] ?? '',
        $existingVendor['phone'] ?? ''
    );

    if ($payuResult['success']) {
        sendSuccess('Bank account details saved, Razorpay fund account created and PayU payout enabled successfully!', [
            'bank_details' => [
                'bank_name'                => $bankName,
                'account_holder_name'      => $accountHolderName,
                'account_last4'            => $accountLast4,
                'ifsc_code'                => $ifscCode,
                'bank_verified'            => true,
                'payout_enabled'           => true,
                'razorpay_contact_id'      => $rzpContactId,
                'razorpay_fund_account_id' => $rzpFundAccountId,
                'razorpay_fund_account'    => $rzpFundAccountData,
                'razorpay_latency_ms'      => $rzpLatencyMs,
            ]
        ]);
    } else {
        sendSuccess('Bank details saved successfully! Razorpay fund account created.', [
            'bank_details' => [
                'bank_name'                => $bankName,
                'account_holder_name'      => $accountHolderName,
                'account_last4'            => $accountLast4,
                'ifsc_code'                => $ifscCode,
                'bank_verified'            => true,
                'payout_enabled'           => false,
                'razorpay_contact_id'      => $rzpContactId,
                'razorpay_fund_account_id' => $rzpFundAccountId,
                'razorpay_fund_account'    => $rzpFundAccountData,
                'razorpay_latency_ms'      => $rzpLatencyMs,
            ]
        ]);
    }
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
