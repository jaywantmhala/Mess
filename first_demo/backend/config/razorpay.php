<?php
/**
 * Razorpay Configuration and Contact Integration
 */

define('RAZORPAY_KEY_ID',     'rzp_test_TqYMLz1N1jVgi3');
define('RAZORPAY_KEY_SECRET', 'gM1Q6Zfu26jJkC86SWf5Wi7E');
define('RAZORPAY_BASE_URL',   'https://api.razorpay.com/v1');

/**
 * Creates a Razorpay Contact (POST /v1/contacts)
 *
 * @param array $contactData [
 *   'name'         => string,
 *   'email'        => string,
 *   'contact'      => string,
 *   'type'         => string ('vendor', 'employee', 'customer'),
 *   'reference_id' => string,
 *   'notes'        => array,
 * ]
 * @return array ['success' => bool, 'id' => string|null, 'data' => array|null, 'error' => string|null]
 */
function createRazorpayContact(array $contactData): array {
    $url = RAZORPAY_BASE_URL . '/contacts';

    $payload = [
        'name'         => trim($contactData['name'] ?? ''),
        'email'        => trim($contactData['email'] ?? ''),
        'contact'      => preg_replace('/[^0-9]/', '', (string)($contactData['contact'] ?? '')),
        'type'         => $contactData['type'] ?? 'vendor',
        'reference_id' => !empty($contactData['reference_id']) ? (string)$contactData['reference_id'] : null,
        'notes'        => !empty($contactData['notes']) && is_array($contactData['notes'])
            ? $contactData['notes']
            : [
                'role'           => 'vendor',
                'registered_via' => 'vendor_signup',
            ],
    ];

    // Ensure 10-digit mobile number for India
    if (strlen($payload['contact']) > 10) {
        $payload['contact'] = substr($payload['contact'], -10);
    }

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_USERPWD, RAZORPAY_KEY_ID . ':' . RAZORPAY_KEY_SECRET);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Authorization: Basic ' . base64_encode(RAZORPAY_KEY_ID . ':' . RAZORPAY_KEY_SECRET),
    ]);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
    curl_setopt($ch, CURLOPT_TIMEOUT, 15);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error    = curl_error($ch);

    if ($response === false) {
        error_log("[Razorpay Contacts] cURL Error: " . $error);
        return [
            'success' => false,
            'id'      => null,
            'error'   => $error,
            'data'    => null,
        ];
    }

    $decoded = json_decode($response, true);
    if (!is_array($decoded)) {
        error_log("[Razorpay Contacts] Invalid JSON response: " . $response);
        return [
            'success' => false,
            'id'      => null,
            'error'   => 'Invalid response from Razorpay: ' . $response,
            'data'    => null,
        ];
    }

    if ($httpCode >= 200 && $httpCode < 300 && !empty($decoded['id'])) {
        return [
            'success' => true,
            'id'      => $decoded['id'],
            'data'    => $decoded,
            'error'   => null,
        ];
    }

    $errMsg = $decoded['error']['description'] ?? ('Razorpay error HTTP ' . $httpCode);
    error_log("[Razorpay Contacts] API Error [HTTP $httpCode]: " . $response);

    return [
        'success'   => false,
        'id'        => null,
        'error'     => $errMsg,
        'data'      => $decoded,
        'http_code' => $httpCode,
    ];
}

/**
 * Creates a Razorpay Fund Account (POST /v1/fund_accounts)
 * Optimized for millisecond-level execution latency.
 *
 * @param array $fundData [
 *   'contact_id'     => string, // cont_xxxx
 *   'account_type'   => 'bank_account',
 *   'name'           => string, // Account Holder Name
 *   'ifsc'           => string, // IFSC code
 *   'account_number' => string, // Account number
 * ]
 * @return array ['success' => bool, 'id' => string|null, 'data' => array|null, 'latency_ms' => float, 'error' => string|null]
 */
function createRazorpayFundAccount(array $fundData): array {
    $startTime = microtime(true);
    $url = RAZORPAY_BASE_URL . '/fund_accounts';

    $payload = [
        'contact_id'   => trim($fundData['contact_id'] ?? ''),
        'account_type' => $fundData['account_type'] ?? 'bank_account',
        'bank_account' => [
            'name'           => trim($fundData['name'] ?? $fundData['account_holder_name'] ?? ''),
            'ifsc'           => strtoupper(trim($fundData['ifsc'] ?? $fundData['ifsc_code'] ?? '')),
            'account_number' => trim((string)($fundData['account_number'] ?? '')),
        ],
    ];

    if (empty($payload['contact_id'])) {
        return [
            'success'    => false,
            'id'         => null,
            'error'      => 'Missing Razorpay contact_id for fund account creation',
            'data'       => null,
            'latency_ms' => 0,
        ];
    }

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_USERPWD, RAZORPAY_KEY_ID . ':' . RAZORPAY_KEY_SECRET);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Authorization: Basic ' . base64_encode(RAZORPAY_KEY_ID . ':' . RAZORPAY_KEY_SECRET),
        'Connection: keep-alive',
    ]);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
    curl_setopt($ch, CURLOPT_TIMEOUT, 6);
    curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 3);
    curl_setopt($ch, CURLOPT_IPRESOLVE, CURL_IPRESOLVE_V4);
    curl_setopt($ch, CURLOPT_TCP_NODELAY, 1);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error    = curl_error($ch);
    $latencyMs = round((microtime(true) - $startTime) * 1000, 2);

    if ($response === false) {
        error_log("[Razorpay Fund Account] cURL Error in {$latencyMs}ms: " . $error);
        return [
            'success'    => false,
            'id'         => null,
            'error'      => $error,
            'data'       => null,
            'latency_ms' => $latencyMs,
        ];
    }

    $decoded = json_decode($response, true);
    if (!is_array($decoded)) {
        error_log("[Razorpay Fund Account] Invalid JSON in {$latencyMs}ms: " . $response);
        return [
            'success'    => false,
            'id'         => null,
            'error'      => 'Invalid response from Razorpay: ' . $response,
            'data'       => null,
            'latency_ms' => $latencyMs,
        ];
    }

    if ($httpCode >= 200 && $httpCode < 300 && !empty($decoded['id'])) {
        return [
            'success'    => true,
            'id'         => $decoded['id'],
            'data'       => $decoded,
            'error'      => null,
            'latency_ms' => $latencyMs,
        ];
    }

    $errMsg = $decoded['error']['description'] ?? ('Razorpay error HTTP ' . $httpCode);
    error_log("[Razorpay Fund Account] API Error [HTTP $httpCode] in {$latencyMs}ms: " . $response);

    return [
        'success'    => false,
        'id'         => null,
        'error'      => $errMsg,
        'data'       => $decoded,
        'http_code'  => $httpCode,
        'latency_ms' => $latencyMs,
    ];
}

/**
 * Fetches a Razorpay Fund Account (GET /v1/fund_accounts/{id})
 *
 * @param string $fundAccountId
 * @return array ['success' => bool, 'id' => string|null, 'data' => array|null, 'error' => string|null, 'latency_ms' => float]
 */
function getRazorpayFundAccount(string $fundAccountId): array {
    $startTime = microtime(true);
    $fundAccountId = trim($fundAccountId);

    if (empty($fundAccountId)) {
        return [
            'success'    => false,
            'id'         => null,
            'error'      => 'Missing fund_account_id',
            'data'       => null,
            'latency_ms' => 0,
        ];
    }

    $url = RAZORPAY_BASE_URL . '/fund_accounts/' . urlencode($fundAccountId);

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_USERPWD, RAZORPAY_KEY_ID . ':' . RAZORPAY_KEY_SECRET);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Authorization: Basic ' . base64_encode(RAZORPAY_KEY_ID . ':' . RAZORPAY_KEY_SECRET),
        'Connection: keep-alive',
    ]);
    curl_setopt($ch, CURLOPT_TIMEOUT, 15);
    curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 8);
    curl_setopt($ch, CURLOPT_IPRESOLVE, CURL_IPRESOLVE_V4);
    curl_setopt($ch, CURLOPT_TCP_NODELAY, 1);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error    = curl_error($ch);
    $latencyMs = round((microtime(true) - $startTime) * 1000, 2);

    if ($response === false) {
        error_log("[Razorpay Fund Account GET] cURL Error in {$latencyMs}ms: " . $error);
        return [
            'success'    => false,
            'id'         => null,
            'error'      => $error,
            'data'       => null,
            'latency_ms' => $latencyMs,
        ];
    }

    $decoded = json_decode($response, true);
    if (!is_array($decoded)) {
        return [
            'success'    => false,
            'id'         => null,
            'error'      => 'Invalid response from Razorpay: ' . $response,
            'data'       => null,
            'latency_ms' => $latencyMs,
        ];
    }

    if ($httpCode >= 200 && $httpCode < 300 && !empty($decoded['id'])) {
        return [
            'success'    => true,
            'id'         => $decoded['id'],
            'data'       => $decoded,
            'error'      => null,
            'latency_ms' => $latencyMs,
        ];
    }

    $errMsg = $decoded['error']['description'] ?? ('Razorpay error HTTP ' . $httpCode);
    error_log("[Razorpay Fund Account GET] API Error [HTTP $httpCode] in {$latencyMs}ms: " . $response);

    return [
        'success'    => false,
        'id'         => null,
        'error'      => $errMsg,
        'data'       => $decoded,
        'http_code'  => $httpCode,
        'latency_ms' => $latencyMs,
    ];
}

/**
 * Fetches Razorpay Fund Accounts by Contact ID (GET /v1/fund_accounts?contact_id={id})
 *
 * @param string $contactId
 * @return array ['success' => bool, 'items' => array, 'error' => string|null, 'latency_ms' => float]
 */
function getRazorpayFundAccountsByContact(string $contactId): array {
    $startTime = microtime(true);
    $contactId = trim($contactId);

    if (empty($contactId)) {
        return [
            'success'    => false,
            'items'      => [],
            'count'      => 0,
            'error'      => 'Missing contact_id',
            'latency_ms' => 0,
        ];
    }

    $url = RAZORPAY_BASE_URL . '/fund_accounts?contact_id=' . urlencode($contactId);

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_USERPWD, RAZORPAY_KEY_ID . ':' . RAZORPAY_KEY_SECRET);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Authorization: Basic ' . base64_encode(RAZORPAY_KEY_ID . ':' . RAZORPAY_KEY_SECRET),
        'Connection: keep-alive',
    ]);
    curl_setopt($ch, CURLOPT_TIMEOUT, 15);
    curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 8);
    curl_setopt($ch, CURLOPT_IPRESOLVE, CURL_IPRESOLVE_V4);
    curl_setopt($ch, CURLOPT_TCP_NODELAY, 1);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error    = curl_error($ch);
    $latencyMs = round((microtime(true) - $startTime) * 1000, 2);

    if ($response === false) {
        return [
            'success'    => false,
            'items'      => [],
            'count'      => 0,
            'error'      => $error,
            'latency_ms' => $latencyMs,
        ];
    }

    $decoded = json_decode($response, true);
    if (!is_array($decoded)) {
        return [
            'success'    => false,
            'items'      => [],
            'count'      => 0,
            'error'      => 'Invalid response from Razorpay: ' . $response,
            'latency_ms' => $latencyMs,
        ];
    }

    if ($httpCode >= 200 && $httpCode < 300) {
        return [
            'success'    => true,
            'count'      => (int)($decoded['count'] ?? count($decoded['items'] ?? [])),
            'items'      => $decoded['items'] ?? [],
            'data'       => $decoded,
            'error'      => null,
            'latency_ms' => $latencyMs,
        ];
    }

    $errMsg = $decoded['error']['description'] ?? ('Razorpay error HTTP ' . $httpCode);
    return [
        'success'    => false,
        'items'      => [],
        'count'      => 0,
        'error'      => $errMsg,
        'data'       => $decoded,
        'http_code'  => $httpCode,
        'latency_ms' => $latencyMs,
    ];
}

/**
 * Automatically ensures an existing vendor has a Razorpay Contact and Fund Account created.
 * Synchronizes existing vendors in the database.
 *
 * @param PDO $pdo
 * @param array $vendor Array with keys: id, full_name, email, phone, bank_name, account_holder_name, account_number, ifsc_code, razorpay_contact_id, razorpay_fund_account_id
 * @return array ['contact_id' => string|null, 'fund_account_id' => string|null, 'synced' => bool, 'messages' => array]
 */
function syncVendorRazorpayAccount(PDO $pdo, array $vendor): array {
    $vendorId = (int)($vendor['id'] ?? 0);
    if ($vendorId <= 0) {
        return ['contact_id' => null, 'fund_account_id' => null, 'synced' => false, 'messages' => ['Invalid vendor ID']];
    }

    $contactId     = trim((string)($vendor['razorpay_contact_id'] ?? ''));
    $fundAccountId = trim((string)($vendor['razorpay_fund_account_id'] ?? ''));
    $messages      = [];
    $updated       = false;

    // 1. Ensure Razorpay Contact ID
    if (empty($contactId)) {
        $contactPhone = preg_replace('/[^0-9]/', '', (string)($vendor['phone'] ?? ''));
        if (strlen($contactPhone) > 10) {
            $contactPhone = substr($contactPhone, -10);
        }
        if (strlen($contactPhone) < 10) {
            $contactPhone = '9' . str_pad($contactPhone, 9, '0', STR_PAD_RIGHT);
        }

        $contactRes = createRazorpayContact([
            'name'         => trim($vendor['full_name'] ?? 'Vendor #' . $vendorId),
            'email'        => trim($vendor['email'] ?? 'vendor' . $vendorId . '@hungrilyfoods.com'),
            'contact'      => $contactPhone,
            'type'         => 'vendor',
            'reference_id' => 'vendor_' . $vendorId,
            'notes'        => [
                'vendor_id'  => (string)$vendorId,
                'business'   => (string)($vendor['account_holder_name'] ?? $vendor['full_name'] ?? ''),
                'auto_sync'  => 'existing_vendor_db_migration',
            ],
        ]);

        if ($contactRes['success'] && !empty($contactRes['id'])) {
            $contactId = $contactRes['id'];
            $messages[] = "Created Razorpay Contact: $contactId";
            $updated = true;
        } else {
            $messages[] = "Contact creation: " . ($contactRes['error'] ?? 'Unknown error');
        }
    }

    // 2. Ensure Razorpay Fund Account ID (if bank details exist and contact exists)
    $hasBankDetails = !empty($vendor['account_number']) && !empty($vendor['ifsc_code']);
    if (!empty($contactId) && empty($fundAccountId) && $hasBankDetails) {
        $cleanIfsc  = strtoupper(trim($vendor['ifsc_code']));
        $accountNum = trim((string)$vendor['account_number']);
        $holderName = trim($vendor['account_holder_name'] ?? $vendor['full_name'] ?? 'Vendor Settlement Account');

        $fundRes = createRazorpayFundAccount([
            'contact_id'     => $contactId,
            'name'           => $holderName,
            'ifsc'           => $cleanIfsc,
            'account_number' => $accountNum,
        ]);

        if ($fundRes['success'] && !empty($fundRes['id'])) {
            $fundAccountId = $fundRes['id'];
            $messages[] = "Created Razorpay Fund Account: $fundAccountId (⚡ {$fundRes['latency_ms']}ms)";
            $updated = true;
        } else {
            $messages[] = "Fund account creation: " . ($fundRes['error'] ?? 'Unknown error');
        }
    }

    // 3. Update database if any IDs were created
    if ($updated) {
        $uStmt = $pdo->prepare("UPDATE vendors SET razorpay_contact_id = :cid, razorpay_fund_account_id = :faid WHERE id = :vid");
        $uStmt->execute([
            ':cid'  => $contactId ?: null,
            ':faid' => $fundAccountId ?: null,
            ':vid'  => $vendorId,
        ]);
    }

    return [
        'contact_id'      => $contactId ?: null,
        'fund_account_id' => $fundAccountId ?: null,
        'synced'          => $updated,
        'messages'        => $messages,
    ];
}

/**
 * Synchronizes all existing vendors in the database with Razorpay Contacts and Fund Accounts.
 *
 * @param PDO $pdo
 * @return array
 */
function syncAllExistingVendorsRazorpay(PDO $pdo): array {
    $stmt = $pdo->query("SELECT id, full_name, email, phone, bank_name, account_holder_name, account_number, ifsc_code, razorpay_contact_id, razorpay_fund_account_id FROM vendors ORDER BY id ASC");
    $vendors = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $results = [];
    $syncedCount = 0;
    foreach ($vendors as $v) {
        $needsContact     = empty($v['razorpay_contact_id']);
        $needsFundAccount = empty($v['razorpay_fund_account_id']) && !empty($v['account_number']) && !empty($v['ifsc_code']);

        if ($needsContact || $needsFundAccount) {
            $res = syncVendorRazorpayAccount($pdo, $v);
            $results[$v['id']] = $res;
            if ($res['synced']) {
                $syncedCount++;
            }
        } else {
            $results[$v['id']] = [
                'contact_id'      => $v['razorpay_contact_id'],
                'fund_account_id' => $v['razorpay_fund_account_id'],
                'synced'          => false,
                'messages'        => ['Already synchronized in Razorpay'],
            ];
        }
    }

    return [
        'total_vendors' => count($vendors),
        'synced_count'  => $syncedCount,
        'details'       => $results,
    ];
}

/**
 * Fetches Razorpay Banking Balances (GET /v1/banking_balances)
 *
 * @param string|null $accountNumber Optional account number to filter
 * @return array ['success' => bool, 'items' => array, 'primary_balance' => array|null, 'error' => string|null, 'latency_ms' => float]
 */
function getRazorpayBankingBalances(?string $accountNumber = null, bool $forceRefresh = false): array {
    $startTime = microtime(true);
    $cacheKey = md5($accountNumber ?? 'primary');
    $cacheFile = sys_get_temp_dir() . '/rzp_banking_bal_' . $cacheKey . '.json';

    // 1. Return fresh cached response if within 15 seconds
    if (!$forceRefresh && file_exists($cacheFile)) {
        $age = time() - filemtime($cacheFile);
        if ($age < 15) {
            $cachedData = json_decode(@file_get_contents($cacheFile), true);
            if (is_array($cachedData) && !empty($cachedData['success'])) {
                $cachedData['cached'] = true;
                $cachedData['latency_ms'] = round((microtime(true) - $startTime) * 1000, 2);
                return $cachedData;
            }
        }
    }

    $url = RAZORPAY_BASE_URL . '/banking_balances';
    if (!empty($accountNumber)) {
        $url .= '?account_number=' . urlencode(trim($accountNumber));
    }

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_USERPWD, RAZORPAY_KEY_ID . ':' . RAZORPAY_KEY_SECRET);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Authorization: Basic ' . base64_encode(RAZORPAY_KEY_ID . ':' . RAZORPAY_KEY_SECRET),
        'Connection: keep-alive',
    ]);
    curl_setopt($ch, CURLOPT_TIMEOUT, 15);
    curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 8);
    curl_setopt($ch, CURLOPT_IPRESOLVE, CURL_IPRESOLVE_V4);
    curl_setopt($ch, CURLOPT_TCP_NODELAY, 1);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error    = curl_error($ch);
    $latencyMs = round((microtime(true) - $startTime) * 1000, 2);

    if ($response === false) {
        error_log("[Razorpay Banking Balances] cURL Error in {$latencyMs}ms: " . $error);
        if (file_exists($cacheFile)) {
            $cachedData = json_decode(@file_get_contents($cacheFile), true);
            if (is_array($cachedData) && !empty($cachedData['success'])) {
                $cachedData['cached'] = true;
                $cachedData['latency_ms'] = $latencyMs;
                return $cachedData;
            }
        }
        return [
            'success'         => false,
            'items'           => [],
            'count'           => 0,
            'primary_balance' => null,
            'error'           => $error,
            'latency_ms'      => $latencyMs,
        ];
    }

    $decoded = json_decode($response, true);
    if (!is_array($decoded)) {
        if (file_exists($cacheFile)) {
            $cachedData = json_decode(@file_get_contents($cacheFile), true);
            if (is_array($cachedData) && !empty($cachedData['success'])) {
                $cachedData['cached'] = true;
                $cachedData['latency_ms'] = $latencyMs;
                return $cachedData;
            }
        }
        return [
            'success'         => false,
            'items'           => [],
            'count'           => 0,
            'primary_balance' => null,
            'error'           => 'Invalid JSON response from Razorpay: ' . $response,
            'latency_ms'      => $latencyMs,
        ];
    }

    if ($httpCode >= 200 && $httpCode < 300) {
        $items = $decoded['items'] ?? [];
        $primary = !empty($items) ? $items[0] : null;

        $result = [
            'success'         => true,
            'count'           => (int)($decoded['count'] ?? count($items)),
            'items'           => $items,
            'primary_balance' => $primary,
            'data'            => $decoded,
            'error'           => null,
            'latency_ms'      => $latencyMs,
        ];

        @file_put_contents($cacheFile, json_encode($result));
        return $result;
    }

    // Rate limited (429) or temporary provider throttle: fallback to last cached balance
    if (file_exists($cacheFile)) {
        $cachedData = json_decode(@file_get_contents($cacheFile), true);
        if (is_array($cachedData) && !empty($cachedData['success'])) {
            $cachedData['cached'] = true;
            $cachedData['latency_ms'] = $latencyMs;
            return $cachedData;
        }
    }

    $errMsg = $decoded['error']['description'] ?? ($decoded['message'] ?? ('Razorpay error HTTP ' . $httpCode));
    error_log("[Razorpay Banking Balances] API Error [HTTP $httpCode] in {$latencyMs}ms: " . $response);

    return [
        'success'         => false,
        'items'           => [],
        'count'           => 0,
        'primary_balance' => null,
        'error'           => $errMsg,
        'data'            => $decoded,
        'http_code'       => $httpCode,
        'latency_ms'      => $latencyMs,
    ];
}

/**
 * Creates a RazorpayX Vendor Payout (POST /v1/payouts)
 *
 * @param array $payload
 * @param string $idempotencyKey
 * @return array ['success' => bool, 'id' => string|null, 'data' => array|null, 'error' => string|null, 'latency_ms' => float]
 */
function createRazorpayXPayout(array $payload, string $idempotencyKey): array {
    $startTime = microtime(true);
    $url = RAZORPAY_BASE_URL . '/payouts';

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_USERPWD, RAZORPAY_KEY_ID . ':' . RAZORPAY_KEY_SECRET);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Authorization: Basic ' . base64_encode(RAZORPAY_KEY_ID . ':' . RAZORPAY_KEY_SECRET),
        'X-Payout-Idempotency: ' . substr(trim($idempotencyKey), 0, 36),
        'Connection: keep-alive',
    ]);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
    curl_setopt($ch, CURLOPT_TIMEOUT, 12);
    curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 4);
    curl_setopt($ch, CURLOPT_IPRESOLVE, CURL_IPRESOLVE_V4);
    curl_setopt($ch, CURLOPT_TCP_NODELAY, 1);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error    = curl_error($ch);
    $latencyMs = round((microtime(true) - $startTime) * 1000, 2);

    if ($response === false) {
        error_log("[RazorpayX Payout POST] cURL Error in {$latencyMs}ms: " . $error);
        return [
            'success'    => false,
            'id'         => null,
            'status'     => 'failed',
            'error'      => $error,
            'data'       => null,
            'latency_ms' => $latencyMs,
        ];
    }

    $decoded = json_decode($response, true);
    if (!is_array($decoded)) {
        return [
            'success'    => false,
            'id'         => null,
            'status'     => 'unknown',
            'error'      => 'Invalid response from Razorpay: ' . $response,
            'data'       => null,
            'latency_ms' => $latencyMs,
        ];
    }

    if ($httpCode >= 200 && $httpCode < 300 && !empty($decoded['id'])) {
        return [
            'success'    => true,
            'id'         => $decoded['id'],
            'status'     => $decoded['status'] ?? 'processing',
            'data'       => $decoded,
            'error'      => null,
            'latency_ms' => $latencyMs,
        ];
    }

    $errMsg = $decoded['error']['description'] ?? ($decoded['message'] ?? ('Razorpay error HTTP ' . $httpCode));
    $errCode = $decoded['error']['code'] ?? null;
    error_log("[RazorpayX Payout POST] API Error [HTTP $httpCode] in {$latencyMs}ms: " . $response);

    return [
        'success'    => false,
        'id'         => $decoded['id'] ?? null,
        'status'     => $decoded['status'] ?? 'failed',
        'error'      => $errMsg,
        'error_code' => $errCode,
        'data'       => $decoded,
        'http_code'  => $httpCode,
        'latency_ms' => $latencyMs,
    ];
}

/**
 * Fetches status of a specific RazorpayX Payout (GET /v1/payouts/{id})
 *
 * @param string $payoutId
 * @return array
 */
function getRazorpayXPayout(string $payoutId): array {
    $startTime = microtime(true);
    $payoutId = trim($payoutId);

    if (empty($payoutId)) {
        return [
            'success'    => false,
            'id'         => null,
            'error'      => 'Missing payout ID',
            'data'       => null,
            'latency_ms' => 0,
        ];
    }

    $url = RAZORPAY_BASE_URL . '/payouts/' . urlencode($payoutId);

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_USERPWD, RAZORPAY_KEY_ID . ':' . RAZORPAY_KEY_SECRET);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Authorization: Basic ' . base64_encode(RAZORPAY_KEY_ID . ':' . RAZORPAY_KEY_SECRET),
        'Connection: keep-alive',
    ]);
    curl_setopt($ch, CURLOPT_TIMEOUT, 15);
    curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 8);
    curl_setopt($ch, CURLOPT_IPRESOLVE, CURL_IPRESOLVE_V4);
    curl_setopt($ch, CURLOPT_TCP_NODELAY, 1);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error    = curl_error($ch);
    $latencyMs = round((microtime(true) - $startTime) * 1000, 2);

    if ($response === false) {
        error_log("[RazorpayX Payout GET] cURL Error in {$latencyMs}ms: " . $error);
        return [
            'success'    => false,
            'id'         => null,
            'error'      => $error,
            'data'       => null,
            'latency_ms' => $latencyMs,
        ];
    }

    $decoded = json_decode($response, true);
    if (!is_array($decoded)) {
        return [
            'success'    => false,
            'id'         => null,
            'error'      => 'Invalid response from Razorpay: ' . $response,
            'data'       => null,
            'latency_ms' => $latencyMs,
        ];
    }

    if ($httpCode >= 200 && $httpCode < 300 && !empty($decoded['id'])) {
        return [
            'success'    => true,
            'id'         => $decoded['id'],
            'status'     => $decoded['status'] ?? 'unknown',
            'data'       => $decoded,
            'error'      => null,
            'latency_ms' => $latencyMs,
        ];
    }

    $errMsg = $decoded['error']['description'] ?? ('Razorpay error HTTP ' . $httpCode);
    return [
        'success'    => false,
        'id'         => null,
        'error'      => $errMsg,
        'data'       => $decoded,
        'http_code'  => $httpCode,
        'latency_ms' => $latencyMs,
    ];
}

/**
 * Fetches all payouts from RazorpayX API:
 * GET https://api.razorpay.com/v1/payouts?account_number={account_number}&count={count}&skip={skip}
 *
 * @param string $accountNumber RazorpayX source account number (e.g. 2323230074781323)
 * @param int $count Number of records to return (1-100, default 50)
 * @param int $skip Number of records to skip for pagination
 * @return array ['success' => bool, 'count' => int, 'items' => array, 'error' => string|null, 'latency_ms' => float]
 */
function getRazorpayXPayoutsList(string $accountNumber = '', int $count = 50, int $skip = 0): array {
    $startTime = microtime(true);
    $accountNumber = trim($accountNumber);

    if (empty($accountNumber)) {
        // Default to configured account number
        $accountNumber = '2323230074781323';
    }

    $count = max(1, min(100, $count));
    $skip  = max(0, $skip);

    $url = RAZORPAY_BASE_URL . '/payouts?account_number=' . urlencode($accountNumber) . "&count={$count}&skip={$skip}";

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_USERPWD, RAZORPAY_KEY_ID . ':' . RAZORPAY_KEY_SECRET);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Authorization: Basic ' . base64_encode(RAZORPAY_KEY_ID . ':' . RAZORPAY_KEY_SECRET),
        'Connection: keep-alive',
    ]);
    curl_setopt($ch, CURLOPT_TIMEOUT, 15);
    curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 8);
    curl_setopt($ch, CURLOPT_IPRESOLVE, CURL_IPRESOLVE_V4);
    curl_setopt($ch, CURLOPT_TCP_NODELAY, 1);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error    = curl_error($ch);
    $latencyMs = round((microtime(true) - $startTime) * 1000, 2);

    if ($response === false) {
        error_log("[RazorpayX Payouts List GET] cURL Error in {$latencyMs}ms: " . $error);
        return [
            'success'    => false,
            'count'      => 0,
            'items'      => [],
            'error'      => $error,
            'latency_ms' => $latencyMs,
            'http_code'  => $httpCode,
        ];
    }

    $decoded = json_decode($response, true);

    if ($httpCode >= 200 && $httpCode < 300 && is_array($decoded)) {
        return [
            'success'        => true,
            'count'          => (int)($decoded['count'] ?? count($decoded['items'] ?? [])),
            'items'          => $decoded['items'] ?? [],
            'account_number' => $accountNumber,
            'error'          => null,
            'latency_ms'     => $latencyMs,
            'http_code'      => $httpCode,
            'data'           => $decoded,
        ];
    }

    $desc = $decoded['error']['description'] ?? $decoded['message'] ?? 'Failed to fetch payouts list from Razorpay';

    // If caller provided generic sample 7878780080316316 or invalid account, automatically fallback to real account
    if ($accountNumber !== '2323230074781323' && (strpos(strtolower($desc), 'invalid') !== false || $httpCode === 400)) {
        return getRazorpayXPayoutsList('2323230074781323', $count, $skip);
    }

    return [
        'success'        => false,
        'count'          => 0,
        'items'          => [],
        'account_number' => $accountNumber,
        'error'          => $desc,
        'latency_ms'     => $latencyMs,
        'http_code'      => $httpCode,
        'data'           => $decoded,
    ];
}


