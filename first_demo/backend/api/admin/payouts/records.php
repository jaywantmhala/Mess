<?php
/**
 * Admin API: Searchable & Paginated Vendor Payout Records
 * Uses RazorpayX API:
 * GET https://api.razorpay.com/v1/payouts?account_number={account_number}
 *
 * Endpoint: GET /api/admin/payouts/records
 */

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../config/razorpay.php';
require_once __DIR__ . '/../../../helpers/cors.php';
require_once __DIR__ . '/../../../helpers/jwt.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/razorpayx_payout_service.php';

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
    RazorpayXPayoutService::ensureTablesExist($pdo);

    // 2. Query Parameters
    $page          = isset($_GET['page']) ? max(1, (int)$_GET['page']) : 1;
    $limit         = isset($_GET['limit']) ? max(1, min(100, (int)$_GET['limit'])) : 15;
    $offset        = ($page - 1) * $limit;
    $search        = isset($_GET['search']) ? trim($_GET['search']) : '';
    $status        = isset($_GET['status']) ? trim($_GET['status']) : 'all';
    $vendorId      = isset($_GET['vendor_id']) && is_numeric($_GET['vendor_id']) ? (int)$_GET['vendor_id'] : null;
    $cycle         = isset($_GET['cycle']) ? trim($_GET['cycle']) : '';
    $minAmount     = isset($_GET['min_amount']) && is_numeric($_GET['min_amount']) ? (float)$_GET['min_amount'] : null;
    $maxAmount     = isset($_GET['max_amount']) && is_numeric($_GET['max_amount']) ? (float)$_GET['max_amount'] : null;
    $accountNumber = isset($_GET['account_number']) ? trim($_GET['account_number']) : '';
    $source        = isset($_GET['source']) ? trim($_GET['source']) : 'auto'; // 'auto' | 'live' | 'db'

    // Determine target RazorpayX account number
    if (empty($accountNumber)) {
        $settings = RazorpayXPayoutService::getSettings($pdo);
        $accountNumber = $settings['razorpayx_account_number'] ?: '2323230074781323';
    }

    // 3. Query Razorpay API: GET https://api.razorpay.com/v1/payouts?account_number={account_number}
    $rzpRes = getRazorpayXPayoutsList($accountNumber, 50, ($page - 1) * 50);
    $activeAcc = $rzpRes['account_number'] ?? $accountNumber;
    $liveItems = $rzpRes['items'] ?? [];

    // 4. Synchronize live Razorpay payout status into DB
    if (!empty($rzpRes['success']) && !empty($liveItems)) {
        foreach ($liveItems as $item) {
            $poutId = trim($item['id'] ?? '');
            if (empty($poutId)) continue;

            $st = strtolower($item['status'] ?? 'processing');
            $utr = $item['utr'] ?? null;
            $failReason = $item['failure_reason'] ?? null;
            $notes = $item['notes'] ?? [];
            $vendorIdNote = isset($notes['vendor_id']) ? (int)$notes['vendor_id'] : 0;
            $cycleNote = isset($notes['payout_cycle']) ? trim($notes['payout_cycle']) : date('Y-m-d', $item['created_at'] ?? time());
            $refNote = trim($item['reference_id'] ?? '');

            // Check if existing record in DB
            $chk = $pdo->prepare("SELECT id, status FROM `razorpay_vendor_payouts` WHERE razorpay_payout_id = :pid OR (internal_reference_id = :ref AND internal_reference_id != '') LIMIT 1");
            $chk->execute([':pid' => $poutId, ':ref' => $refNote]);
            $existingRow = $chk->fetch(PDO::FETCH_ASSOC);

            if ($existingRow) {
                $upd = $pdo->prepare("
                    UPDATE `razorpay_vendor_payouts`
                    SET razorpay_payout_id = :pid,
                        status             = :st,
                        utr                = COALESCE(:utr, utr),
                        failure_reason     = COALESCE(:fr, failure_reason),
                        processed_at       = CASE WHEN :st2 = 'processed' AND processed_at IS NULL THEN NOW() ELSE processed_at END,
                        updated_at         = NOW()
                    WHERE id = :id
                ");
                $upd->execute([
                    ':pid' => $poutId,
                    ':st'  => $st,
                    ':utr' => $utr,
                    ':fr'  => $failReason,
                    ':st2' => $st,
                    ':id'  => $existingRow['id'],
                ]);
            } elseif ($vendorIdNote > 0) {
                try {
                    $amtPaise = (int)($item['amount'] ?? 0);
                    $netAmt = round($amtPaise / 100, 2);
                    $ins = $pdo->prepare("
                        INSERT INTO `razorpay_vendor_payouts`
                        (vendor_id, payout_cycle, internal_reference_id, fund_account_id, source_account_number,
                         eligible_earnings, commission_deductions, net_payout_amount, amount_paise, currency,
                         mode, purpose, razorpay_payout_id, status, utr, failure_reason, initiated_at, created_at, updated_at)
                        VALUES
                        (:vid, :cycle, :ref, :fa, :src,
                         :net, 0.00, :net, :paise, 'INR',
                         :mode, :purp, :pid, :st, :utr, :fr, FROM_UNIXTIME(:c1), FROM_UNIXTIME(:c2), NOW())
                    ");
                    $ins->execute([
                        ':vid'   => $vendorIdNote,
                        ':cycle' => $cycleNote,
                        ':ref'   => $refNote ?: ("RAZORPAY-" . $poutId),
                        ':fa'    => $item['fund_account_id'] ?? null,
                        ':src'   => $activeAcc,
                        ':net'   => $netAmt,
                        ':paise' => $amtPaise,
                        ':mode'  => $item['mode'] ?? 'IMPS',
                        ':purp'  => $item['purpose'] ?? 'payout',
                        ':pid'   => $poutId,
                        ':st'    => $st,
                        ':utr'   => $utr,
                        ':fr'    => $failReason,
                        ':c1'    => $item['created_at'] ?? time(),
                        ':c2'    => $item['created_at'] ?? time(),
                    ]);
                } catch (Throwable $e) {}
            }
        }
    }

    // 5. If pure live Razorpay view requested
    if ($source === 'live') {
        $liveRecords = [];
        $liveDates = [];
        foreach ($liveItems as $idx => $it) {
            $notes = $it['notes'] ?? [];
            $vId = (int)($notes['vendor_id'] ?? 0);
            $vName = $notes['vendor_name'] ?? ('Vendor #' . $vId);
            $amtPaise = (int)($it['amount'] ?? 0);
            $netAmt = round($amtPaise / 100, 2);
            $itemCycle = $notes['payout_cycle'] ?? date('Y-m-d', $it['created_at'] ?? time());

            if (!in_array($itemCycle, $liveDates)) {
                $liveDates[] = $itemCycle;
            }

            // Fetch vendor contact info from DB if vendor_id exists
            $vPhone = '';
            $vEmail = '';
            if ($vId > 0) {
                $vStmt = $pdo->prepare("SELECT phone, email, full_name FROM vendors WHERE id = ? LIMIT 1");
                $vStmt->execute([$vId]);
                $vRow = $vStmt->fetch(PDO::FETCH_ASSOC);
                if ($vRow) {
                    $vPhone = $vRow['phone'] ?? '';
                    $vEmail = $vRow['email'] ?? '';
                    if (!empty($vRow['full_name'])) $vName = $vRow['full_name'];
                }
            }

            $liveRecords[] = [
                'id'                    => $idx + 1,
                'payout_run_id'         => $notes['run_id'] ?? null,
                'vendor_id'             => $vId,
                'vendor_name'           => $vName,
                'vendor_phone'          => $vPhone,
                'vendor_email'          => $vEmail,
                'bank_name'             => '',
                'account_number'        => '',
                'ifsc_code'             => '',
                'payout_cycle'          => $itemCycle,
                'internal_reference_id' => $it['reference_id'] ?? '',
                'idempotency_key'       => '',
                'fund_account_id'       => $it['fund_account_id'] ?? '',
                'source_account_number' => $activeAcc,
                'eligible_earnings'     => $netAmt,
                'commission_deductions' => 0,
                'net_payout_amount'     => $netAmt,
                'amount_paise'          => $amtPaise,
                'currency'              => $it['currency'] ?? 'INR',
                'mode'                  => $it['mode'] ?? 'IMPS',
                'purpose'               => $it['purpose'] ?? 'payout',
                'razorpay_payout_id'    => $it['id'] ?? '',
                'status'                => strtolower($it['status'] ?? 'unknown'),
                'utr'                   => $it['utr'] ?? '',
                'failure_reason'        => $it['failure_reason'] ?? '',
                'failure_code'          => '',
                'initiated_at'          => date('Y-m-d H:i:s', $it['created_at'] ?? time()),
                'processed_at'          => null,
                'created_at'            => date('Y-m-d H:i:s', $it['created_at'] ?? time()),
                'updated_at'            => date('Y-m-d H:i:s', $it['created_at'] ?? time()),
            ];
        }

        // Apply cycle filter to live items if specified
        if (!empty($cycle) && strtolower($cycle) !== 'all') {
            $liveRecords = array_values(array_filter($liveRecords, function($r) use ($cycle) {
                $recCycle = !empty($r['payout_cycle']) ? $r['payout_cycle'] : substr($r['created_at'], 0, 10);
                if (strlen($cycle) === 7) {
                    return strpos($recCycle, $cycle) === 0;
                }
                return $recCycle === $cycle;
            }));
        }

        echo json_encode([
            'success'                 => true,
            'source'                  => 'razorpay_live_api',
            'api_endpoint'            => "https://api.razorpay.com/v1/payouts?account_number=" . urlencode($activeAcc),
            'account_number'          => $activeAcc,
            'payout_dates'            => $liveDates,
            'records'                 => $liveRecords,
            'pagination'              => [
                'current_page' => 1,
                'limit'        => count($liveRecords),
                'total_items'  => count($liveRecords),
                'total_pages'  => 1,
            ],
            'razorpay_live_count'     => count($liveRecords),
        ]);
        exit;
    }

    // 6. Build WHERE condition for database query
    $where = ["1=1"];
    $params = [];

    if ($status !== '' && strtolower($status) !== 'all') {
        $where[] = "rp.status = :status";
        $params[':status'] = strtolower($status);
    }

    if ($vendorId !== null && $vendorId > 0) {
        $where[] = "rp.vendor_id = :vendor_id";
        $params[':vendor_id'] = $vendorId;
    }

    if (!empty($cycle) && strtolower($cycle) !== 'all') {
        if (strlen($cycle) === 7) {
            // Month format YYYY-MM
            $where[] = "(CASE WHEN rp.payout_cycle IS NOT NULL AND rp.payout_cycle != '' THEN rp.payout_cycle LIKE :cycle_m ELSE DATE_FORMAT(rp.created_at, '%Y-%m') = :cycle_m2 END)";
            $params[':cycle_m'] = $cycle . '%';
            $params[':cycle_m2'] = $cycle;
        } else {
            // Exact date format YYYY-MM-DD
            $where[] = "(CASE WHEN rp.payout_cycle IS NOT NULL AND rp.payout_cycle != '' THEN rp.payout_cycle = :cycle ELSE DATE(rp.created_at) = :cycle_date END)";
            $params[':cycle'] = $cycle;
            $params[':cycle_date'] = $cycle;
        }
    }

    if ($minAmount !== null) {
        $where[] = "rp.net_payout_amount >= :min_amt";
        $params[':min_amt'] = $minAmount;
    }

    if ($maxAmount !== null) {
        $where[] = "rp.net_payout_amount <= :max_amt";
        $params[':max_amt'] = $maxAmount;
    }

    if (!empty($search)) {
        $where[] = "(v.full_name LIKE :s1 OR v.email LIKE :s2 OR v.phone LIKE :s3 OR rp.internal_reference_id LIKE :s4 OR rp.razorpay_payout_id LIKE :s5 OR rp.utr LIKE :s6)";
        $pattern = "%{$search}%";
        $params[':s1'] = $pattern;
        $params[':s2'] = $pattern;
        $params[':s3'] = $pattern;
        $params[':s4'] = $pattern;
        $params[':s5'] = $pattern;
        $params[':s6'] = $pattern;
    }

    $whereSql = implode(' AND ', $where);

    // 7. Count query
    $countSql = "
        SELECT COUNT(*)
        FROM `razorpay_vendor_payouts` rp
        JOIN `vendors` v ON rp.vendor_id = v.id
        WHERE $whereSql
    ";
    $countStmt = $pdo->prepare($countSql);
    foreach ($params as $k => $v) {
        $countStmt->bindValue($k, $v);
    }
    $countStmt->execute();
    $totalItems = (int)$countStmt->fetchColumn();
    $totalPages = ceil($totalItems / $limit);

    // 8. Select query
    $dataSql = "
        SELECT 
            rp.id,
            rp.payout_run_id,
            rp.vendor_id,
            v.full_name AS vendor_name,
            v.account_holder_name AS business_name,
            v.phone AS vendor_phone,
            v.email AS vendor_email,
            v.bank_name,
            v.account_number,
            v.ifsc_code,
            rp.payout_cycle,
            rp.internal_reference_id,
            rp.idempotency_key,
            rp.fund_account_id,
            rp.source_account_number,
            rp.eligible_earnings,
            rp.commission_deductions,
            rp.net_payout_amount,
            rp.amount_paise,
            rp.currency,
            rp.mode,
            rp.purpose,
            rp.razorpay_payout_id,
            rp.status,
            rp.utr,
            rp.failure_reason,
            rp.failure_code,
            rp.initiated_at,
            rp.processed_at,
            rp.created_at,
            rp.updated_at
        FROM `razorpay_vendor_payouts` rp
        JOIN `vendors` v ON rp.vendor_id = v.id
        WHERE $whereSql
        ORDER BY rp.id DESC
        LIMIT :limit OFFSET :offset
    ";

    $stmt = $pdo->prepare($dataSql);
    foreach ($params as $k => $v) {
        $stmt->bindValue($k, $v);
    }
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();
    $records = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Fetch all distinct dates that have payouts to highlight in custom calendar
    $payoutDates = [];
    $payoutDateSummaries = [];
    try {
        $datesStmt = $pdo->query("
            SELECT DISTINCT payout_cycle FROM `razorpay_vendor_payouts` WHERE payout_cycle IS NOT NULL AND payout_cycle != ''
            UNION
            SELECT DISTINCT DATE_FORMAT(created_at, '%Y-%m-%d') FROM `razorpay_vendor_payouts` WHERE created_at IS NOT NULL
            ORDER BY payout_cycle DESC
            LIMIT 90
        ");
        $payoutDates = $datesStmt ? $datesStmt->fetchAll(PDO::FETCH_COLUMN) : [];

        $summaryStmt = $pdo->query("
            SELECT 
                COALESCE(NULLIF(payout_cycle, ''), DATE_FORMAT(created_at, '%Y-%m-%d')) AS p_date,
                COUNT(*) as count,
                SUM(net_payout_amount) as total_amount
            FROM `razorpay_vendor_payouts`
            GROUP BY p_date
            ORDER BY p_date DESC
            LIMIT 120
        ");
        if ($summaryStmt) {
            while ($row = $summaryStmt->fetch(PDO::FETCH_ASSOC)) {
                if (!empty($row['p_date'])) {
                    $payoutDateSummaries[$row['p_date']] = [
                        'count' => (int)$row['count'],
                        'amount' => (float)$row['total_amount']
                    ];
                }
            }
        }
    } catch (Throwable $e) {}

    echo json_encode([
        'success'                 => true,
        'source'                  => 'razorpay_synchronized',
        'api_endpoint'            => "https://api.razorpay.com/v1/payouts?account_number=" . urlencode($activeAcc),
        'account_number'          => $activeAcc,
        'payout_dates'            => array_values(array_filter($payoutDates)),
        'payout_date_summaries'   => $payoutDateSummaries,
        'razorpay_live_count'     => $rzpRes['count'] ?? count($liveItems),
        'records'                 => $records,
        'pagination'              => [
            'current_page' => $page,
            'limit'        => $limit,
            'total_items'  => $totalItems,
            'total_pages'  => $totalPages,
        ],
    ]);

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
