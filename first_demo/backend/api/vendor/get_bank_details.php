<?php
/**
 * GET /api/vendor/get_bank_details
 *
 * Fetches saved bank account details for authenticated vendor.
 * Header: Authorization: Bearer <token>
 * Returns last 4 digits only for security.
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/razorpay.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/jwt.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'GET')     { sendError('Method not allowed. Use GET.', 405); }

// JWT Auth
$token   = JWT::getBearerToken();
$payload = $token ? JWT::verify($token) : null;

if (!$payload || !isset($payload['sub'])) {
    sendError('Unauthorized. Please log in again.', 401);
}

$vendorId = (int)$payload['sub'];
$pdo = getDBConnection();

try {
    $stmt = $pdo->prepare("
        SELECT bank_name, account_holder_name, account_number, ifsc_code, bank_verified, payout_enabled, payu_beneficiary_id, razorpay_contact_id, razorpay_fund_account_id 
        FROM vendors 
        WHERE id = :id 
        LIMIT 1
    ");
    $stmt->execute([':id' => $vendorId]);
    $vendor = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$vendor) {
        sendError('Vendor not found.', 404);
    }

    // Automatically apply Razorpay Contact & Fund Account for existing vendors if not yet synced
    if (empty($vendor['razorpay_contact_id']) || (empty($vendor['razorpay_fund_account_id']) && !empty($vendor['account_number']) && !empty($vendor['ifsc_code']))) {
        $fullStmt = $pdo->prepare("SELECT id, full_name, email, phone, bank_name, account_holder_name, account_number, ifsc_code, razorpay_contact_id, razorpay_fund_account_id FROM vendors WHERE id = :id LIMIT 1");
        $fullStmt->execute([':id' => $vendorId]);
        $fullVendor = $fullStmt->fetch(PDO::FETCH_ASSOC);

        if ($fullVendor) {
            $syncRes = syncVendorRazorpayAccount($pdo, $fullVendor);
            if (!empty($syncRes['contact_id'])) {
                $vendor['razorpay_contact_id'] = $syncRes['contact_id'];
            }
            if (!empty($syncRes['fund_account_id'])) {
                $vendor['razorpay_fund_account_id'] = $syncRes['fund_account_id'];
            }
        }
    }

    $rawAccount = $vendor['account_number'] ?? '';
    $accountLast4 = (strlen($rawAccount) >= 4) ? substr($rawAccount, -4) : $rawAccount;

    sendSuccess('Bank details retrieved successfully.', [
        'bank_details' => [
            'bank_name'                => $vendor['bank_name'] ?? '',
            'account_holder_name'      => $vendor['account_holder_name'] ?? '',
            'account_last4'            => $accountLast4,
            'ifsc_code'                => $vendor['ifsc_code'] ?? '',
            'bank_verified'            => (bool)($vendor['bank_verified'] ?? false),
            'payout_enabled'           => (bool)($vendor['payout_enabled'] ?? false),
            'razorpay_contact_id'      => $vendor['razorpay_contact_id'] ?? '',
            'razorpay_fund_account_id' => $vendor['razorpay_fund_account_id'] ?? '',
        ]
    ]);
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
