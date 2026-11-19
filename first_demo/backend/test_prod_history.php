<?php
$token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjEsInJvbGUiOiJhZG1pbiIsImVtYWlsIjoiYWRtaW5AYWRtaW4uY29tIiwiZnVsbF9uYW1lIjoiU3VwZXIgQWRtaW4iLCJpYXQiOjE3OTE4MTE4MDYsImV4cCI6NDk0NTQxMTgwNn0.a6tEt2QRwizXHuzG_bKYDzd0H1Fc30kpTZCGbRKH_nc';

$ch = curl_init('https://hungrilyfoods.com/api/admin/whatsapp/history?limit=5');
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => [
        'Authorization: Bearer ' . $token,
        'Content-Type: application/json'
    ],
    CURLOPT_SSL_VERIFYPEER => false,
]);
$res = curl_exec($ch);
$code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP $code:\n$res\n";
