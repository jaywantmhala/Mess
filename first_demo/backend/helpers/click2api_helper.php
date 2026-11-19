<?php
/**
 * Click2Api WhatsApp REST API Helper
 */

require_once __DIR__ . '/../config/whatsapp.php';

/**
 * Format phone number to 12 digits with country code 91 if 10-digit Indian number.
 */
function formatWhatsAppPhone(string $phone): string {
    $clean = preg_replace('/[^0-9]/', '', $phone);
    $clean = ltrim($clean, '0');
    if (strlen($clean) === 10) {
        return '91' . $clean;
    }
    if (strlen($clean) === 12 && substr($clean, 0, 2) === '91') {
        return $clean;
    }
    return $clean;
}

/**
 * Get exact access token for Click2Api Meta Authorization
 */
function getCleanAccessToken(): string {
    return CLICK2API_ACCESS_TOKEN;
}

/**
 * Send OTP via Click2Api WhatsApp API using Meta template hungrily_otp
 *
 * Payload format:
 * {
 *   "to": "919527243062",
 *   "recipient_type": "individual",
 *   "type": "template",
 *   "template": {
 *     "language": {
 *       "policy": "deterministic",
 *       "code": "en_US"
 *     },
 *     "name": "hungrily_otp",
 *     "components": [
 *       {
 *         "type": "body",
 *         "parameters": [
 *           {
 *             "type": "text",
 *             "text": "482913"
 *           }
 *         ]
 *       },
 *       {
 *         "type": "button",
 *         "sub_type": "url",
 *         "index": "0",
 *         "parameters": [
 *           {
 *             "type": "text",
 *             "text": "482913"
 *           }
 *         ]
 *       }
 *     ]
 *   }
 * }
 *
 * @param string $phone Customer or Vendor 10-digit mobile number
 * @param string $otp 6-digit verification code
 * @param string|null $templateName Optional WhatsApp template name
 * @return array ['success' => bool, 'message' => string, 'response' => mixed]
 */
function sendWhatsAppOTP(string $phone, string $otp, ?string $templateName = null): array {
    $formattedPhone = formatWhatsAppPhone($phone);
    $primaryUrl  = CLICK2API_BASE_URL . '/' . CLICK2API_VERSION . '/' . CLICK2API_PHONE_NUMBER_ID . '/messages';

    $templateToUse = $templateName ?? CLICK2API_DEFAULT_TEMPLATE;

    // Meta WhatsApp Template Payload
    $templatePayload = [
        'to'             => $formattedPhone,
        'recipient_type' => 'individual',
        'type'           => 'template',
        'template'       => [
            'language' => [
                'policy' => 'deterministic',
                'code'   => 'en_US'
            ],
            'name'       => $templateToUse,
            'components' => [
                [
                    'type'       => 'body',
                    'parameters' => [
                        [
                            'type' => 'text',
                            'text' => (string)$otp
                        ]
                    ]
                ],
                [
                    'type'       => 'button',
                    'sub_type'   => 'url',
                    'index'      => '0',
                    'parameters' => [
                        [
                            'type' => 'text',
                            'text' => (string)$otp
                        ]
                    ]
                ]
            ]
        ]
    ];

    // Attempt 1: Full payload (body + button components)
    $res = makeClick2ApiRequest($primaryUrl, $templatePayload);
    if ($res['success']) {
        return $res;
    }

    // Attempt 2: Body-only parameter fallback (if template does not have button parameter)
    $bodyOnlyPayload = $templatePayload;
    $bodyOnlyPayload['template']['components'] = [
        [
            'type'       => 'body',
            'parameters' => [
                [
                    'type' => 'text',
                    'text' => (string)$otp
                ]
            ]
        ]
    ];

    $resBodyOnly = makeClick2ApiRequest($primaryUrl, $bodyOnlyPayload);
    if ($resBodyOnly['success']) {
        return $resBodyOnly;
    }

    return $res;
}

/**
 * Execute HTTP POST Request to Click2Api / Meta endpoint using cURL
 */
function makeClick2ApiRequest(string $url, array $payload): array {
    $token = getCleanAccessToken();
    $ch = curl_init($url);
    $jsonPayload = json_encode($payload);

    curl_setopt_array($ch, [
        CURLOPT_POST           => true,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER     => [
            'Authorization: Bearer ' . $token,
            'Content-Type: application/json'
        ],
        CURLOPT_POSTFIELDS     => $jsonPayload,
        CURLOPT_TIMEOUT        => 15,
        CURLOPT_SSL_VERIFYPEER => false,
    ]);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlErr  = curl_error($ch);
    if (PHP_VERSION_ID < 80000) {
        @curl_close($ch);
    }

    if ($curlErr) {
        return [
            'success'  => false,
            'message'  => 'Connection Error: ' . $curlErr,
            'response' => null
        ];
    }

    $decoded = json_decode($response, true);

    if ($httpCode >= 200 && $httpCode < 300) {
        return [
            'success'  => true,
            'message'  => 'WhatsApp message dispatched successfully.',
            'response' => $decoded
        ];
    }

    $rawErr = $decoded['error']['message'] ?? ($decoded['message'] ?? ($decoded['error'] ?? 'HTTP ' . $httpCode));
    $errMsgStr = is_array($rawErr) ? json_encode($rawErr) : (string)$rawErr;

    error_log("[WhatsApp Click2Api Error] HTTP $httpCode: " . $response);

    if (stripos($errMsgStr, 'channel is not active') !== false || stripos($errMsgStr, 'channel inactive') !== false) {
        $userFriendlyMsg = 'WhatsApp channel is currently inactive on Meta/Click2Api server. Please re-activate channel in Meta Dashboard or contact admin.';
    } else {
        $userFriendlyMsg = $errMsgStr;
    }

    return [
        'success'  => false,
        'message'  => $userFriendlyMsg,
        'response' => $decoded
    ];
}

/**
 * Send text message via Click2Api WhatsApp API
 */
function sendWhatsAppTextMessage(string $phone, string $textMessage): array {
    $formattedPhone = formatWhatsAppPhone($phone);
    $primaryUrl = CLICK2API_BASE_URL . '/' . CLICK2API_VERSION . '/' . CLICK2API_PHONE_NUMBER_ID . '/messages';

    $payload = [
        'to'             => $formattedPhone,
        'recipient_type' => 'individual',
        'type'           => 'text',
        'text'           => [
            'body'       => $textMessage
        ]
    ];

    $res = makeClick2ApiRequest($primaryUrl, $payload);
    if ($res['success']) {
        return $res;
    }

    // Fallback: If raw text message is rejected outside 24h Meta window,
    // dispatch via approved hungrily_broadcast template
    $fallbackComponents = [
        [
            'type' => 'body',
            'parameters' => [
                ['type' => 'text', 'text' => 'Hungrily User'],
                ['type' => 'text', 'text' => $textMessage]
            ]
        ]
    ];
    $fallbackRes = sendWhatsAppTemplateMessage($phone, 'hungrily_broadcast', $fallbackComponents, 'en', $textMessage);
    if (!empty($fallbackRes['success'])) {
        return $fallbackRes;
    }

    return $res;
}

/**
 * Send template message via Click2Api WhatsApp API
 */
function sendWhatsAppTemplateMessage(
    string $phone,
    string $templateName = 'welcome',
    array $components = [],
    string $langCode = 'en',
    string $textMessage = ''
): array {
    $formattedPhone = formatWhatsAppPhone($phone);
    $primaryUrl = CLICK2API_BASE_URL . '/' . CLICK2API_VERSION . '/' . CLICK2API_PHONE_NUMBER_ID . '/messages';

    if (strtolower($templateName) === 'text') {
        return sendWhatsAppTextMessage($phone, $textMessage);
    }

    $templateToUse = !empty($templateName) ? $templateName : 'welcome';
    $effectiveComponents = is_array($components) ? $components : [];

    $payload = [
        'to'             => $formattedPhone,
        'recipient_type' => 'individual',
        'type'           => 'template',
        'template'       => [
            'language' => [
                'policy' => 'deterministic',
                'code'   => $langCode ?: 'en'
            ],
            'name'       => $templateToUse,
            'components' => $effectiveComponents
        ]
    ];

    return makeClick2ApiRequest($primaryUrl, $payload);
}

/**
 * Send driver notifications or onboarding credentials via Meta approved hungrily_broadcast template.
 * Guarantees delivery outside the 24h Meta conversation window.
 *
 * @param string $phone Driver 10-digit or 12-digit mobile number
 * @param string $driverName Driver full name
 * @param string $detailsMessage Detailed credentials/notification text
 * @return array ['success' => bool, 'message' => string, 'response' => mixed]
 */
function sendDriverCredentialsWhatsApp(string $phone, string $driverName, string $detailsMessage): array {
    $formattedPhone = formatWhatsAppPhone($phone);
    $primaryUrl = CLICK2API_BASE_URL . '/' . CLICK2API_VERSION . '/' . CLICK2API_PHONE_NUMBER_ID . '/messages';

    $cleanName = trim($driverName ?: 'Delivery Partner');

    // Meta approved template: hungrily_broadcast
    // Header: "Hungrily Foods Update"
    // Body: "Hello {{1}},\n\n{{2}}\n\nThank you for choosing Hungrily Foods!"
    $payload = [
        'to'             => $formattedPhone,
        'recipient_type' => 'individual',
        'type'           => 'template',
        'template'       => [
            'language' => [
                'policy' => 'deterministic',
                'code'   => 'en'
            ],
            'name'       => 'hungrily_broadcast',
            'components' => [
                [
                    'type' => 'body',
                    'parameters' => [
                        [
                            'type' => 'text',
                            'text' => $cleanName
                        ],
                        [
                            'type' => 'text',
                            'text' => $detailsMessage
                        ]
                    ]
                ]
            ]
        ]
    ];

    $res = makeClick2ApiRequest($primaryUrl, $payload);
    if (!empty($res['success'])) {
        return $res;
    }

    // Secondary fallback: Direct text message if template fails
    $textPayload = [
        'to'             => $formattedPhone,
        'recipient_type' => 'individual',
        'type'           => 'text',
        'text'           => [
            'body'       => "Hello " . $cleanName . ",\n\n" . $detailsMessage . "\n\nThank you for choosing Hungrily Foods!"
        ]
    ];

    $textRes = makeClick2ApiRequest($primaryUrl, $textPayload);
    if (!empty($textRes['success'])) {
        return $textRes;
    }

    return $res;
}

/**
 * Send bulk WhatsApp template/text messages in parallel using cURL multi
 * Default template name: "welcome", language code: "en"
 */
function sendWhatsAppBatchMessages(
    array $recipientsOrPhones,
    string $textMessage = '',
    string $templateName = 'text',
    array $components = [],
    string $langCode = 'en'
): array {
    $normalizedRecipients = [];
    foreach ($recipientsOrPhones as $item) {
        if (is_array($item)) {
            $rawPhone = $item['phone'] ?? ($item['phone_number'] ?? '');
            $formatted = formatWhatsAppPhone((string)$rawPhone);
            if (strlen($formatted) >= 10 && strlen($formatted) <= 15) {
                $normalizedRecipients[] = [
                    'phone'         => $formatted,
                    'name'          => !empty($item['name']) ? $item['name'] : 'Customer',
                    'role'          => !empty($item['role']) ? $item['role'] : 'User',
                    'message'       => !empty($item['message']) ? $item['message'] : $textMessage,
                    'template_name' => !empty($item['template_name']) ? $item['template_name'] : $templateName,
                    'components'    => isset($item['components']) && is_array($item['components']) ? $item['components'] : $components,
                    'lang_code'     => !empty($item['language_code']) ? $item['language_code'] : $langCode,
                ];
            }
        } elseif (is_string($item) || is_numeric($item)) {
            $formatted = formatWhatsAppPhone((string)$item);
            if (strlen($formatted) >= 10 && strlen($formatted) <= 15) {
                $normalizedRecipients[] = [
                    'phone'         => $formatted,
                    'name'          => 'Customer',
                    'role'          => 'User',
                    'message'       => $textMessage,
                    'template_name' => $templateName,
                    'components'    => $components,
                    'lang_code'     => $langCode,
                ];
            }
        }
    }

    // Deduplicate by phone
    $uniqueRecipients = [];
    $seenPhones = [];
    foreach ($normalizedRecipients as $r) {
        if (!isset($seenPhones[$r['phone']])) {
            $seenPhones[$r['phone']] = true;
            $uniqueRecipients[] = $r;
        }
    }

    if (empty($uniqueRecipients)) {
        return ['sent' => 0, 'failed' => 0, 'total' => 0];
    }

    $token = getCleanAccessToken();
    $url = CLICK2API_BASE_URL . '/' . CLICK2API_VERSION . '/' . CLICK2API_PHONE_NUMBER_ID . '/messages';

    $headers = [
        'Authorization: Bearer ' . $token,
        'Content-Type: application/json'
    ];

    $chunks = array_chunk($uniqueRecipients, 20);
    $sentCount = 0;
    $failedCount = 0;

    foreach ($chunks as $chunk) {
        $mh = curl_multi_init();
        $handles = [];

        foreach ($chunk as $idx => $recipient) {
            $phone = $recipient['phone'];
            $msg   = $recipient['message'];
            $recName = !empty($recipient['name']) ? $recipient['name'] : 'Customer';
            $tpl   = !empty($recipient['template_name']) ? $recipient['template_name'] : 'text';
            $effComponents = $recipient['components'];
            $code  = $recipient['lang_code'] ?: 'en';

            // Auto-populate components for hungrily_broadcast if empty
            if ($tpl === 'hungrily_broadcast' && empty($effComponents)) {
                $effComponents = [
                    [
                        'type' => 'body',
                        'parameters' => [
                            ['type' => 'text', 'text' => $recName],
                            ['type' => 'text', 'text' => $msg]
                        ]
                    ]
                ];
            }

            // If template is 'welcome' or empty, but user entered a dynamic custom message,
            // Meta's 'welcome' template has NO parameters ("Hello, welcome to Hungrily Foods. Notification!").
            // To ensure the custom message is delivered to WhatsApp, send as direct text!
            $isTextOnly = (strtolower($tpl) === 'text');
            if (!$isTextOnly && $tpl === 'welcome' && !empty($msg) && $msg !== 'Template Broadcast: welcome') {
                $isTextOnly = true;
            }

            if ($isTextOnly) {
                $payload = [
                    'to'             => $phone,
                    'recipient_type' => 'individual',
                    'type'           => 'text',
                    'text'           => [
                        'body'       => $msg
                    ]
                ];
            } else {
                $payload = [
                    'to'             => $phone,
                    'recipient_type' => 'individual',
                    'type'           => 'template',
                    'template'       => [
                        'language' => [
                            'policy' => 'deterministic',
                            'code'   => $code
                        ],
                        'name'       => $tpl,
                        'components' => $effComponents
                    ]
                ];
            }

            $ch = curl_init();
            curl_setopt_array($ch, [
                CURLOPT_URL            => $url,
                CURLOPT_POST           => true,
                CURLOPT_HTTPHEADER     => $headers,
                CURLOPT_POSTFIELDS     => json_encode($payload),
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_TIMEOUT        => 15,
                CURLOPT_SSL_VERIFYPEER => false,
            ]);

            curl_multi_add_handle($mh, $ch);
            $handles[$idx] = [
                'ch'         => $ch,
                'phone'      => $phone,
                'name'       => $recName,
                'tpl'        => $tpl,
                'code'       => $code,
                'message'    => $msg,
                'components' => $effComponents,
                'isTextOnly' => $isTextOnly
            ];
        }

        $running = null;
        do {
            $mrc = curl_multi_exec($mh, $running);
        } while ($mrc == CURLM_CALL_MULTI_PERFORM);

        while ($running && $mrc == CURLM_OK) {
            if (curl_multi_select($mh, 0.05) === -1) {
                usleep(10000);
            }
            do {
                $mrc = curl_multi_exec($mh, $running);
            } while ($mrc == CURLM_CALL_MULTI_PERFORM);
        }

        foreach ($handles as $info) {
            $ch = $info['ch'];
            $phone = $info['phone'];
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            $resContent = curl_multi_getcontent($ch);

            if ($httpCode >= 200 && $httpCode < 300) {
                $sentCount++;
            } else {
                // If direct text was rejected, fallback to hungrily_broadcast template
                if ($info['isTextOnly']) {
                    $fallbackComponents = [
                        [
                            'type' => 'body',
                            'parameters' => [
                                ['type' => 'text', 'text' => $info['name'] ?: 'Customer'],
                                ['type' => 'text', 'text' => $info['message']]
                            ]
                        ]
                    ];
                    $fallbackRes = sendWhatsAppTemplateMessage($phone, 'hungrily_broadcast', $fallbackComponents, 'en', $info['message']);
                    if ($fallbackRes['success']) {
                        $sentCount++;
                    } else {
                        // Fallback attempt to welcome template
                        $fallbackRes2 = sendWhatsAppTemplateMessage($phone, 'welcome', [], 'en', $info['message']);
                        if ($fallbackRes2['success']) {
                            $sentCount++;
                        } else {
                            $failedCount++;
                            error_log("[WhatsApp Bulk Error] Phone: $phone | HTTP $httpCode: $resContent");
                        }
                    }
                } else {
                    $fallbackRes = sendWhatsAppTemplateMessage($phone, $info['tpl'], $info['components'] ?: [], $info['code'], $info['message']);
                    if ($fallbackRes['success']) {
                        $sentCount++;
                    } else {
                        $failedCount++;
                        error_log("[WhatsApp Bulk Error] Phone: $phone | HTTP $httpCode: $resContent");
                    }
                }
            }
            curl_multi_remove_handle($mh, $ch);
            if (PHP_VERSION_ID < 80000) {
                @curl_close($ch);
            }
        }

        curl_multi_close($mh);
    }

    return [
        'sent'   => $sentCount,
        'failed' => $failedCount,
        'total'  => count($uniqueRecipients)
    ];
}


