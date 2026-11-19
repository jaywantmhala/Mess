<?php
/**
 * PayU Payment Gateway Configuration & Helper Utilities
 */

define('PAYU_MERCHANT_KEY', 'ddhaRc');
define('PAYU_SALT',         '16fwtFLqPJ3L3Bn3f1MdYFVEnJ2znGKP');
define('PAYU_ENVIRONMENT',  'PRODUCTION'); // Set to 'PRODUCTION' for live payments

define('PAYU_BASE_URL',     PAYU_ENVIRONMENT === 'PRODUCTION' 
                                ? 'https://secure.payu.in/_payment' 
                                : 'https://test.payu.in/_payment');

define('PAYU_VERIFY_URL',   PAYU_ENVIRONMENT === 'PRODUCTION' 
                                ? 'https://info.payu.in/merchant/postfinal_page.php?form=2' 
                                : 'https://test.payu.in/merchant/postfinal_page.php?form=2');

/**
 * Generate PayU SHA-512 request hash:
 * sha512(key|txnid|amount|productinfo|firstname|email|udf1|udf2|udf3|udf4|udf5||||||SALT)
 */
function generatePayUHash(array $params): string {
    $key         = PAYU_MERCHANT_KEY;
    $txnid       = $params['txnid'] ?? '';
    $amount      = number_format((float)($params['amount'] ?? 0), 2, '.', '');
    $productinfo = $params['productinfo'] ?? '';
    $firstname   = $params['firstname'] ?? '';
    $email       = $params['email'] ?? '';
    $udf1        = $params['udf1'] ?? '';
    $udf2        = $params['udf2'] ?? '';
    $udf3        = $params['udf3'] ?? '';
    $udf4        = $params['udf4'] ?? '';
    $udf5        = $params['udf5'] ?? '';

    $hashSequence = "{$key}|{$txnid}|{$amount}|{$productinfo}|{$firstname}|{$email}|{$udf1}|{$udf2}|{$udf3}|{$udf4}|{$udf5}||||||" . PAYU_SALT;
    return strtolower(hash('sha512', $hashSequence));
}

/**
 * Verify PayU response hash:
 * sha512(SALT|status||||||udf5|udf4|udf3|udf2|udf1|email|firstname|productinfo|amount|txnid|key)
 */
function verifyPayUResponseHash(array $params): bool {
    if (empty($params['hash'])) return false;

    $key         = PAYU_MERCHANT_KEY;
    $txnid       = $params['txnid'] ?? '';
    $amount      = number_format((float)($params['amount'] ?? 0), 2, '.', '');
    $productinfo = $params['productinfo'] ?? '';
    $firstname   = $params['firstname'] ?? '';
    $email       = $params['email'] ?? '';
    $udf1        = $params['udf1'] ?? '';
    $udf2        = $params['udf2'] ?? '';
    $udf3        = $params['udf3'] ?? '';
    $udf4        = $params['udf4'] ?? '';
    $udf5        = $params['udf5'] ?? '';
    $status      = $params['status'] ?? '';
    $receivedHash = strtolower($params['hash']);

    $additionalCharges = $params['additionalCharges'] ?? null;

    if ($additionalCharges) {
        $hashSequence = "{$additionalCharges}|" . PAYU_SALT . "|{$status}||||||{$udf5}|{$udf4}|{$udf3}|{$udf2}|{$udf1}|{$email}|{$firstname}|{$productinfo}|{$amount}|{$txnid}|{$key}";
    } else {
        $hashSequence = PAYU_SALT . "|{$status}||||||{$udf5}|{$udf4}|{$udf3}|{$udf2}|{$udf1}|{$email}|{$firstname}|{$productinfo}|{$amount}|{$txnid}|{$key}";
    }

    $calculatedHash = strtolower(hash('sha512', $hashSequence));
    return hash_equals($calculatedHash, $receivedHash);
}

/**
 * Execute server-side PayU transaction verification API (command=verify_payment)
 */
function verifyPayUTransaction(string $txnid): array {
    $hashString = PAYU_MERCHANT_KEY . '|verify_payment|' . $txnid . '|' . PAYU_SALT;
    $hash = strtolower(hash('sha512', $hashString));

    $postData = http_build_query([
        'key'     => PAYU_MERCHANT_KEY,
        'command' => 'verify_payment',
        'var1'    => $txnid,
        'hash'    => $hash,
    ]);

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, PAYU_VERIFY_URL);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $postData);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_TIMEOUT, 20);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error    = curl_error($ch);
    curl_close($ch);

    if ($response === false) {
        return [
            'success' => false,
            'message' => "cURL Error calling PayU verification: " . $error,
        ];
    }

    $decoded = json_decode($response, true);
    if (!is_array($decoded)) {
        return [
            'success' => false,
            'message' => "Invalid response from PayU verification API: " . $response,
        ];
    }

    return [
        'success'     => true,
        'status_code' => $httpCode,
        'data'        => $decoded,
    ];
}
