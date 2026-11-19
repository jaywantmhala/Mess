<?php
require_once 'd:/flutter/first_demo/backend/config/whatsapp.php';
require_once 'd:/flutter/first_demo/backend/helpers/click2api_helper.php';

// Test with a sample mobile number or dummy number to observe Meta response
$phone = '919527243062'; // or any number from database
$url = CLICK2API_BASE_URL . '/' . CLICK2API_VERSION . '/' . CLICK2API_PHONE_NUMBER_ID . '/messages';

echo "=== TEST 1: Sending type 'text' ===\n";
$textPayload = [
    'to' => $phone,
    'recipient_type' => 'individual',
    'type' => 'text',
    'text' => ['body' => 'Test dynamic broadcast message']
];
$res1 = makeClick2ApiRequest($url, $textPayload);
print_r($res1);

echo "\n=== TEST 2: Sending template 'hungrily_broadcast' ===\n";
$templatePayload = [
    'to' => $phone,
    'recipient_type' => 'individual',
    'type' => 'template',
    'template' => [
        'language' => [
            'policy' => 'deterministic',
            'code'   => 'en'
        ],
        'name' => 'hungrily_broadcast',
        'components' => [
            [
                'type' => 'body',
                'parameters' => [
                    ['type' => 'text', 'text' => 'Jay'],
                    ['type' => 'text', 'text' => 'Welcome to Hungrily! Your special offer is live.']
                ]
            ]
        ]
    ]
];
$res2 = makeClick2ApiRequest($url, $templatePayload);
print_r($res2);
