<?php
/**
 * Razorpay Fund Account Fetch API for Admin Panel
 * Endpoint: GET /api/admin/payouts/razorpay-fund-account
 *
 * Hits Razorpay API: GET https://api.razorpay.com/v1/fund_accounts/{id}
 */

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../config/razorpay.php';
require_once __DIR__ . '/../../../helpers/cors.php';
require_once __DIR__ . '/../../../helpers/jwt.php';
require_once __DIR__ . '/../../../helpers/response.php';

header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

try {
    // 1. Authenticate Admin Token
    $token = JWT::getBearerToken();
    $payload = $token ? JWT::verify($token) : null;

    if (!$payload || !isset($payload['sub']) || ($payload['role'] ?? '') !== 'admin') {
        sendError('Unauthorized. Admin access required.', 401);
    }

    $pdo = getDBConnection();

    // 2. Extract Query Parameters
    $fundAccountId = trim($_GET['fund_account_id'] ?? $_GET['id'] ?? '');
    $contactId     = trim($_GET['contact_id'] ?? '');
    $vendorId      = !empty($_GET['vendor_id']) ? (int)$_GET['vendor_id'] : null;
    $vendor        = null;

    // 3. Resolve Vendor Profile from vendor_id or contact_id
    if ($vendorId !== null && $vendorId > 0) {
        $vStmt = $pdo->prepare("SELECT id, full_name, email, phone, razorpay_contact_id, razorpay_fund_account_id, bank_name, account_holder_name, account_number, ifsc_code FROM vendors WHERE id = :vid LIMIT 1");
        $vStmt->execute([':vid' => $vendorId]);
        $vendor = $vStmt->fetch(PDO::FETCH_ASSOC);
    } elseif (!empty($contactId)) {
        $vStmt = $pdo->prepare("SELECT id, full_name, email, phone, razorpay_contact_id, razorpay_fund_account_id, bank_name, account_holder_name, account_number, ifsc_code FROM vendors WHERE razorpay_contact_id = :cid LIMIT 1");
        $vStmt->execute([':cid' => $contactId]);
        $vendor = $vStmt->fetch(PDO::FETCH_ASSOC);
        if ($vendor) {
            $vendorId = (int)$vendor['id'];
        }
    }

    if ($vendor) {
        if (empty($fundAccountId) && !empty($vendor['razorpay_fund_account_id'])) {
            $fundAccountId = trim($vendor['razorpay_fund_account_id']);
        }
        if (empty($contactId) && !empty($vendor['razorpay_contact_id'])) {
            $contactId = trim($vendor['razorpay_contact_id']);
        }
    }

    // 4. Hit Razorpay API: GET /v1/fund_accounts/{id} directly
    if (!empty($fundAccountId)) {
        $result = getRazorpayFundAccount($fundAccountId);

        if ($result['success'] && !empty($result['data']['id'])) {
            echo json_encode([
                'success'      => true,
                'fund_account' => $result['data'],
                'latency_ms'   => $result['latency_ms'] ?? 0,
                'source'       => 'fund_account_id',
            ]);
            exit;
        }

        // If direct fetch by fund_account_id failed, fallback to contact_id
        if (empty($contactId) && !empty($result['data']['contact_id'])) {
            $contactId = $result['data']['contact_id'];
        }
    }

    // 5. Fallback: Search / List by Contact ID
    if (!empty($contactId)) {
        $contactRes = getRazorpayFundAccountsByContact($contactId);

        if ($contactRes['success'] && !empty($contactRes['items'])) {
            $items = $contactRes['items'];
            $selectedItem = $items[0];
            foreach ($items as $item) {
                if (!empty($item['active'])) {
                    $selectedItem = $item;
                    break;
                }
            }

            // Sync database if vendor was resolved
            if ($vendorId !== null && !empty($selectedItem['id'])) {
                $upStmt = $pdo->prepare("UPDATE vendors SET razorpay_fund_account_id = :fa_id WHERE id = :vid AND (razorpay_fund_account_id IS NULL OR razorpay_fund_account_id = '')");
                $upStmt->execute([':fa_id' => $selectedItem['id'], ':vid' => $vendorId]);
            }

            echo json_encode([
                'success'      => true,
                'fund_account' => $selectedItem,
                'all_accounts' => $items,
                'count'        => count($items),
                'latency_ms'   => $contactRes['latency_ms'] ?? 0,
                'source'       => 'contact_lookup',
            ]);
            exit;
        }

        // 6. If no fund account in Razorpay but vendor has bank details, attempt auto-creation
        if ($vendor && !empty($vendor['account_number']) && !empty($vendor['ifsc_code'])) {
            $cleanIfsc = strtoupper(trim($vendor['ifsc_code']));
            $accountNum = trim((string)$vendor['account_number']);
            $holderName = trim($vendor['account_holder_name'] ?? $vendor['full_name'] ?? 'Vendor Account');

            $createRes = createRazorpayFundAccount([
                'contact_id'     => $contactId,
                'name'           => $holderName,
                'ifsc'           => $cleanIfsc,
                'account_number' => $accountNum,
            ]);

            if ($createRes['success'] && !empty($createRes['id'])) {
                if ($vendorId !== null) {
                    $upStmt = $pdo->prepare("UPDATE vendors SET razorpay_fund_account_id = :fa_id WHERE id = :vid");
                    $upStmt->execute([':fa_id' => $createRes['id'], ':vid' => $vendorId]);
                }

                echo json_encode([
                    'success'      => true,
                    'fund_account' => $createRes['data'],
                    'latency_ms'   => $createRes['latency_ms'] ?? 0,
                    'source'       => 'auto_created_on_demand',
                ]);
                exit;
            }
        }
    }

    // 7. Graceful Response if vendor has no active fund account yet
    echo json_encode([
        'success'         => false,
        'fund_account'    => null,
        'message'         => 'No Razorpay fund account found for this vendor. Please ensure bank details are added in the vendor app.',
        'fund_account_id' => $fundAccountId,
        'contact_id'      => $contactId,
        'vendor_id'       => $vendorId,
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
