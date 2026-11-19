<?php
/**
 * CLI Background script to send FCM notifications
 * Usage: php fcm_bg.php <customer|vendor|driver> <targetId> <titleEncoded> <bodyEncoded> <dataJsonEncoded>
 */

// Set infinite execution limit
set_time_limit(0);

// Prevent output buffering
ob_implicit_flush();

if ($argc < 6) {
    exit("FcmBg Error: Missing arguments. Usage: php fcm_bg.php <role> <id> <titleEncoded> <bodyEncoded> <dataJsonEncoded>\n");
}

$role = $argv[1];
$id = (int)$argv[2];

// Base64 decode to preserve spaces, quotes, and special characters passed via CLI
$title = base64_decode($argv[3]) ?: $argv[3];
$body = base64_decode($argv[4]) ?: $argv[4];
$dataJson = base64_decode($argv[5]) ?: $argv[5];
$data = json_decode($dataJson, true) ?: [];

require_once __DIR__ . '/fcm.php';

if ($role === 'customer') {
    $res = FcmHelper::sendToCustomerDirect($id, $title, $body, $data);
    echo "[" . date('Y-m-d H:i:s') . "] Customer direct send result: " . ($res ? "SUCCESS" : "FAILED") . "\n";
} elseif ($role === 'vendor') {
    $res = FcmHelper::sendToVendorDirect($id, $title, $body, $data);
    echo "[" . date('Y-m-d H:i:s') . "] Vendor direct send result: " . ($res ? "SUCCESS" : "FAILED") . "\n";
} elseif ($role === 'driver') {
    $res = FcmHelper::sendToDriverDirect($id, $title, $body, $data);
    echo "[" . date('Y-m-d H:i:s') . "] Driver direct send result: " . ($res ? "SUCCESS" : "FAILED") . "\n";
}
