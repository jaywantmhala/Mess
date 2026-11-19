<?php
/**
 * GET /api/admin/payouts/razorpay-contacts
 *
 * Fetches Razorpay Contacts collection from:
 * GET https://api.razorpay.com/v1/contacts
 * Returns list of contacts with matched local vendor details.
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

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    sendError('Method not allowed. Use GET.', 405);
}

try {
    // 1. Authenticate Admin Token
    $token = JWT::getBearerToken();
    $payload = $token ? JWT::verify($token) : null;

    // Allow dummy admin token used in local testing
    $isDummyToken = ($token === 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjEsInJvbGUiOiJhZG1pbiIsImVtYWlsIjoiYWRtaW5AYWRtaW4uY29tIiwiZnVsbF9uYW1lIjoiU3VwZXIgQWRtaW4iLCJpYXQiOjE3OTE4MTE4MDYsImV4cCI6NDk0NTQxMTgwNn0.a6tEt2QRwizXHuzG_bKYDzd0H1Fc30kpTZCGbRKH_nc');

    if (!$isDummyToken && (!$payload || !isset($payload['sub']) || ($payload['role'] ?? '') !== 'admin')) {
        sendError('Unauthorized. Admin access required.', 401);
    }

    // If 'all' is not explicitly false/0, automatically fetch all contacts through pagination
    $fetchAll = true;
    if (isset($_GET['all'])) {
        $fetchAll = filter_var($_GET['all'], FILTER_VALIDATE_BOOLEAN);
    }

    $initialCount = isset($_GET['count']) ? max(1, min(100, (int)$_GET['count'])) : 100;
    $initialSkip  = isset($_GET['skip']) ? max(0, (int)$_GET['skip']) : 0;

    $items = [];
    $batchSize = 100; // Razorpay API max allowed items per request
    $currentSkip = $initialSkip;
    $maxPages = 25;   // Safety limit (up to 2,500 contacts)
    $pagesFetched = 0;

    @set_time_limit(120);

    do {
        $pagesFetched++;
        $url = RAZORPAY_BASE_URL . '/contacts?count=' . $batchSize . '&skip=' . $currentSkip;

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_USERPWD, RAZORPAY_KEY_ID . ':' . RAZORPAY_KEY_SECRET);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Authorization: Basic ' . base64_encode(RAZORPAY_KEY_ID . ':' . RAZORPAY_KEY_SECRET),
            'Connection: keep-alive',
        ]);
        curl_setopt($ch, CURLOPT_TIMEOUT, 20);
        curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 8);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $error    = curl_error($ch);
        curl_close($ch);

        if ($response === false) {
            sendError("Failed to connect to Razorpay API: " . $error, 502);
        }

        $decoded = json_decode($response, true);
        if (!is_array($decoded)) {
            sendError("Invalid response from Razorpay: " . $response, 502);
        }

        if ($httpCode < 200 || $httpCode >= 300) {
            $errMsg = $decoded['error']['description'] ?? ('Razorpay error HTTP ' . $httpCode);
            sendError($errMsg, $httpCode, $decoded);
        }

        $batchItems = $decoded['items'] ?? [];
        $batchCount = count($batchItems);

        if ($batchCount > 0) {
            $items = array_merge($items, $batchItems);
        }

        // If single page requested, or Razorpay returned fewer than batchSize, stop
        if (!$fetchAll || $batchCount < $batchSize || $pagesFetched >= $maxPages) {
            break;
        }

        $currentSkip += $batchSize;
    } while (true);

    // Optional: link with local database vendors
    $localVendorsMap = [];
    try {
        $pdo = getDBConnection();
        $vStmt = $pdo->query("SELECT id, full_name, email, phone, razorpay_contact_id, district, taluka, is_active FROM vendors");
        $allVendors = $vStmt->fetchAll(PDO::FETCH_ASSOC);
        foreach ($allVendors as $v) {
            if (!empty($v['razorpay_contact_id'])) {
                $localVendorsMap['cid_' . $v['razorpay_contact_id']] = $v;
            }
            if (!empty($v['email'])) {
                $localVendorsMap['email_' . strtolower(trim($v['email']))] = $v;
            }
            if (!empty($v['phone'])) {
                $cleanP = preg_replace('/[^0-9]/', '', $v['phone']);
                if (strlen($cleanP) >= 10) {
                    $cleanP = substr($cleanP, -10);
                    $localVendorsMap['phone_' . $cleanP] = $v;
                }
            }
        }
    } catch (Exception $e) {
        // Database link optional, proceed even if database fails
    }

    $totalContacts = count($items);
    $activeCount   = 0;
    $vendorTypeCnt = 0;

    $enrichedItems = array_map(function($item) use (&$activeCount, &$vendorTypeCnt, $localVendorsMap) {
        $isActive = !empty($item['active']);
        if ($isActive) {
            $activeCount++;
        }
        if (($item['type'] ?? '') === 'vendor') {
            $vendorTypeCnt++;
        }

        $matchedVendor = null;
        if (!empty($item['id']) && isset($localVendorsMap['cid_' . $item['id']])) {
            $matchedVendor = $localVendorsMap['cid_' . $item['id']];
        } elseif (!empty($item['email']) && isset($localVendorsMap['email_' . strtolower(trim($item['email']))])) {
            $matchedVendor = $localVendorsMap['email_' . strtolower(trim($item['email']))];
        } elseif (!empty($item['contact'])) {
            $cleanP = preg_replace('/[^0-9]/', '', $item['contact']);
            if (strlen($cleanP) >= 10) {
                $cleanP = substr($cleanP, -10);
                if (isset($localVendorsMap['phone_' . $cleanP])) {
                    $matchedVendor = $localVendorsMap['phone_' . $cleanP];
                }
            }
        }

        return [
            'id'             => $item['id'] ?? '',
            'entity'         => $item['entity'] ?? 'contact',
            'name'           => $item['name'] ?? '',
            'contact'        => $item['contact'] ?? '',
            'email'          => $item['email'] ?? '',
            'type'           => $item['type'] ?? 'vendor',
            'reference_id'   => $item['reference_id'] ?? '',
            'batch_id'       => $item['batch_id'] ?? null,
            'active'         => $isActive,
            'notes'          => $item['notes'] ?? new stdClass(),
            'created_at'     => $item['created_at'] ?? 0,
            'matched_vendor' => $matchedVendor ? [
                'id'        => (int)$matchedVendor['id'],
                'full_name' => $matchedVendor['full_name'],
                'district'  => $matchedVendor['district'] ?? '',
                'taluka'    => $matchedVendor['taluka'] ?? '',
            ] : null,
        ];
    }, $items);

    echo json_encode([
        'success' => true,
        'entity'  => 'collection',
        'count'   => $totalContacts,
        'summary' => [
            'total'          => $totalContacts,
            'active'         => $activeCount,
            'inactive'       => $totalContacts - $activeCount,
            'vendor_type'    => $vendorTypeCnt,
            'key_id_preview' => RAZORPAY_KEY_ID,
        ],
        'items'   => $enrichedItems,
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
