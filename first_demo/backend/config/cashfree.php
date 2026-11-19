<?php
/**
 * Cashfree Payment Gateway Configuration
 */

define('CASHFREE_APP_ID',     'TEST1114421912847b0de4ef6a83832891244111');
define('CASHFREE_SECRET_KEY', 'cfsk_ma_test_c9e816049d99d9221335ca1b075a46cd_9b339e19');
define('CASHFREE_ENV',        'TEST'); // 'TEST' or 'PRODUCTION'
define('CASHFREE_BASE_URL',   'https://sandbox.cashfree.com/pg'); // Use https://api.cashfree.com/pg for production
define('CASHFREE_API_VERSION','2023-08-01');

/**
 * Helper function to execute Cashfree REST API requests
 */
function callCashfreeAPI(string $endpoint, string $method = 'GET', array $data = []): array {
    $url = rtrim(CASHFREE_BASE_URL, '/') . '/' . ltrim($endpoint, '/');
    
    $headers = [
        'Content-Type: application/json',
        'x-client-id: ' . CASHFREE_APP_ID,
        'x-client-secret: ' . CASHFREE_SECRET_KEY,
        'x-api-version: ' . CASHFREE_API_VERSION,
    ];

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, strtoupper($method));
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);

    if (in_array(strtoupper($method), ['POST', 'PUT', 'PATCH']) && !empty($data)) {
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    }

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error    = curl_error($ch);
    curl_close($ch);

    if ($response === false) {
        throw new Exception("Cashfree API cURL Error: " . $error, 500);
    }

    $decoded = json_decode($response, true);
    if (!is_array($decoded)) {
        throw new Exception("Invalid response from Cashfree API: " . $response, 500);
    }

    return [
        'status_code' => $httpCode,
        'body'        => $decoded,
    ];
}
