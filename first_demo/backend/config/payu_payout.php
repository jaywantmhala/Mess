<?php
/**
 * PayU Payouts Integration Configuration (LIVE PRODUCTION)
 * Merchant ID: 13720818
 */

$env    = getenv('PAYU_PAYOUT_ENV') ?: 'live';
$isLive = ($env === 'live');

return [
    'env'                  => $env,
    'payout_merchant_id'   => getenv('PAYU_PAYOUT_MERCHANT_ID') ?: '13720818',
    'client_id'            => getenv('PAYU_PAYOUT_CLIENT_ID') ?: 'PAYU_TEST_PUBLIC_CLIENT_ID',
    'client_secret'        => getenv('PAYU_PAYOUT_CLIENT_SECRET') ?: 'PAYU_TEST_CLIENT_SECRET',
    'username'             => getenv('PAYU_PAYOUT_USERNAME') ?: 'PAYU_PAYOUT_TEST_USERNAME',
    'password'             => getenv('PAYU_PAYOUT_PASSWORD') ?: 'PAYU_PAYOUT_TEST_PASSWORD',
    
    // PayU Endpoints (Live Production vs Sandbox)
    'auth_url'             => $isLive ? 'https://accounts.payu.in/oauth/token' : 'https://uat-accounts.payu.in/oauth/token',
    'beneficiary_url'      => $isLive ? 'https://oneapi.payu.in/payout/beneficiary' : 'https://uatoneapi.payu.in/payout/beneficiary',
    'transfer_url'         => $isLive ? 'https://oneapi.payu.in/payout/v2/payment' : 'https://uatoneapi.payu.in/payout/v2/payment',
    'status_check_url'     => $isLive ? 'https://oneapi.payu.in/payout/payment/listTransactions' : 'https://uatoneapi.payu.in/payout/payment/listTransactions',
    'account_balance_url'  => $isLive ? 'https://oneapi.payu.in/payout/merchant/account/balance' : 'https://uatoneapi.payu.in/payout/merchant/account/balance',
    
    'request_timeout_sec'  => 15,
];
