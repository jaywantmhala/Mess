<?php
require_once 'd:/flutter/first_demo/backend/config/whatsapp.php';

$url = CLICK2API_BASE_URL . '/' . CLICK2API_VERSION . '/' . CLICK2API_WABA_ID . '/message_templates?limit=50';
$ch = curl_init($url);
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => [
        'Authorization: Bearer ' . CLICK2API_ACCESS_TOKEN,
        'Content-Type: application/json'
    ],
    CURLOPT_SSL_VERIFYPEER => false,
]);
$res = curl_exec($ch);
$code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);
echo "HTTP $code:\n$res\n";
