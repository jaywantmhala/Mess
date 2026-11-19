<?php
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

    // 2. Query Parameters
    $page   = isset($_GET['page']) ? max(1, (int)$_GET['page']) : 1;
    $limit  = isset($_GET['limit']) ? max(1, min(100, (int)$_GET['limit'])) : 15;
    $offset = ($page - 1) * $limit;
    $search = isset($_GET['search']) ? trim($_GET['search']) : '';
    $status = isset($_GET['status']) ? trim($_GET['status']) : 'all';

    // 3. Build WHERE condition
    $whereClause = "WHERE 1=1";
    $params = [];

    if ($status !== '' && strtolower($status) !== 'all') {
        $whereClause .= " AND vp.status = :status";
        $params[':status'] = strtoupper($status);
    }

    if ($search !== '') {
        $searchPattern = '%' . $search . '%';
        $whereClause .= " AND (v.full_name LIKE :pay_s1 OR v.email LIKE :pay_s2 OR v.phone LIKE :pay_s3 OR vp.merchant_ref_id LIKE :pay_s4 OR vp.payu_txn_id LIKE :pay_s5)";
        $params[':pay_s1'] = $searchPattern;
        $params[':pay_s2'] = $searchPattern;
        $params[':pay_s3'] = $searchPattern;
        $params[':pay_s4'] = $searchPattern;
        $params[':pay_s5'] = $searchPattern;
    }

    // 4. Calculate overall summary statistics
    $summaryStmt = $pdo->query("
        SELECT 
            COALESCE(SUM(CASE WHEN status = 'SUCCESS' THEN amount ELSE 0 END), 0) AS total_settled_amount,
            COALESCE(SUM(CASE WHEN status = 'SUCCESS' AND DATE(created_at) = CURDATE() THEN amount ELSE 0 END), 0) AS today_settled_amount,
            COALESCE(SUM(CASE WHEN status IN ('PENDING', 'INITIATED', 'PROCESSING', 'QUEUED') THEN 1 ELSE 0 END), 0) AS total_pending_count,
            COALESCE(SUM(CASE WHEN status = 'FAILED' THEN 1 ELSE 0 END), 0) AS total_failed_count
        FROM vendor_payouts
    ");
    $summary = $summaryStmt->fetch(PDO::FETCH_ASSOC);

    // 5. Total count for current query
    $countSql = "
        SELECT COUNT(*) 
        FROM vendor_payouts vp
        JOIN vendors v ON vp.vendor_id = v.id
        $whereClause
    ";
    $countStmt = $pdo->prepare($countSql);
    foreach ($params as $key => $val) {
        $countStmt->bindValue($key, $val);
    }
    $countStmt->execute();
    $totalItems = (int)$countStmt->fetchColumn();
    $totalPages = ceil($totalItems / $limit);

    // 6. Fetch paginated payouts
    $sql = "
        SELECT 
            vp.id,
            vp.vendor_id,
            v.full_name AS vendor_name,
            v.account_holder_name AS vendor_business_name,
            v.phone AS vendor_phone,
            v.email AS vendor_email,
            v.bank_name,
            v.account_holder_name,
            v.account_number,
            v.ifsc_code,
            v.payu_beneficiary_id,
            v.razorpay_contact_id,
            v.razorpay_fund_account_id,
            vp.amount,
            vp.status,
            vp.merchant_ref_id AS reference_id,
            vp.payu_txn_id AS payu_payout_id,
            vp.batch_id AS payu_batch_id,
            vp.bank_transaction_ref_no AS payu_utr,
            RIGHT(v.account_number, 4) AS account_last4,
            vp.failure_reason,
            DATE(vp.created_at) AS target_date,
            vp.initiated_at AS executed_at,
            vp.completed_at,
            vp.created_at
        FROM vendor_payouts vp
        JOIN vendors v ON vp.vendor_id = v.id
        $whereClause
        ORDER BY vp.created_at DESC
        LIMIT :limit OFFSET :offset
    ";

    $stmt = $pdo->prepare($sql);
    foreach ($params as $key => $val) {
        $stmt->bindValue($key, $val);
    }
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();
    $payouts = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Format output with automatic Razorpay sync for existing vendors
    $formattedPayouts = array_map(function($item) use ($pdo) {
        if (empty($item['razorpay_contact_id']) || (empty($item['razorpay_fund_account_id']) && !empty($item['account_number']) && !empty($item['ifsc_code']))) {
            $syncRes = syncVendorRazorpayAccount($pdo, [
                'id'                  => $item['vendor_id'],
                'full_name'           => $item['vendor_name'],
                'email'               => $item['vendor_email'],
                'phone'               => $item['vendor_phone'],
                'bank_name'           => $item['bank_name'],
                'account_holder_name' => $item['account_holder_name'],
                'account_number'      => $item['account_number'],
                'ifsc_code'           => $item['ifsc_code'],
                'razorpay_contact_id' => $item['razorpay_contact_id'],
                'razorpay_fund_account_id' => $item['razorpay_fund_account_id'],
            ]);
            if (!empty($syncRes['contact_id'])) {
                $item['razorpay_contact_id'] = $syncRes['contact_id'];
            }
            if (!empty($syncRes['fund_account_id'])) {
                $item['razorpay_fund_account_id'] = $syncRes['fund_account_id'];
            }
        }

        return [
            'id'                   => (int)$item['id'],
            'vendor_id'            => (int)$item['vendor_id'],
            'vendor_name'          => $item['vendor_name'] ?? 'N/A',
            'vendor_business_name' => $item['vendor_business_name'] ?? '',
            'vendor_phone'         => $item['vendor_phone'] ?? '',
            'vendor_email'         => $item['vendor_email'] ?? '',
            'bank_name'            => $item['bank_name'] ?? '',
            'account_holder_name'  => $item['account_holder_name'] ?? '',
            'account_number'       => $item['account_number'] ?? '',
            'ifsc_code'            => $item['ifsc_code'] ?? '',
            'payu_beneficiary_id'      => $item['payu_beneficiary_id'] ?? '',
            'razorpay_contact_id'      => $item['razorpay_contact_id'] ?? '',
            'razorpay_fund_account_id' => $item['razorpay_fund_account_id'] ?? '',
            'amount'                   => (float)$item['amount'],
            'status'               => $item['status'],
            'reference_id'         => $item['reference_id'],
            'payu_payout_id'       => $item['payu_payout_id'],
            'payu_batch_id'        => $item['payu_batch_id'],
            'payu_utr'             => $item['payu_utr'],
            'account_last4'        => $item['account_last4'],
            'failure_reason'       => $item['failure_reason'],
            'target_date'          => $item['target_date'],
            'executed_at'          => $item['executed_at'],
            'completed_at'         => $item['completed_at'],
            'created_at'           => $item['created_at'],
        ];
    }, $payouts);

    require_once __DIR__ . '/../../../helpers/payu_payout_helper.php';
    $payuBalanceData = PayUPayoutHelper::getAccountBalance($pdo);

    echo json_encode([
        'success' => true,
        'summary' => [
            'total_settled_amount' => (float)$summary['total_settled_amount'],
            'today_settled_amount' => (float)$summary['today_settled_amount'],
            'total_pending_count'  => (int)$summary['total_pending_count'],
            'total_failed_count'   => (int)$summary['total_failed_count'],
            'payu_balance'         => (float)($payuBalanceData['balance'] ?? 0),
            'payu_currency'        => $payuBalanceData['currency'] ?? 'INR',
            'payu_merchant_id'     => $payuBalanceData['merchant_id'] ?? '13720818',
        ],
        'payouts' => $formattedPayouts,
        'pagination' => [
            'total_items'  => $totalItems,
            'current_page' => $page,
            'total_pages'  => $totalPages,
            'limit'        => $limit,
        ]
    ]);

} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
