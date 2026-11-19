<?php
/**
 * Firebase Cloud Messaging Helper — v1 HTTP API
 * Utilizes the Google Service Account key for authentication.
 * Optimized with OAuth token caching and fire-and-forget background execution.
 */

require_once __DIR__ . '/../config/database.php';

class FcmHelper {
    
    /**
     * Generate Google OAuth2 Access Token using RS256 JWT assertion.
     * Caches the token to avoid redundant network requests.
     */
    private static function getAccessToken(): ?string {
        $cacheFile = __DIR__ . '/../config/fcm_token_cache.json';
        
        // Try reading from cache first
        if (file_exists($cacheFile)) {
            $cache = json_decode(file_get_contents($cacheFile), true);
            if ($cache && isset($cache['access_token'], $cache['expires_at'])) {
                // If token is valid for at least another 60 seconds, use it
                if ($cache['expires_at'] > (time() + 60)) {
                    return $cache['access_token'];
                }
            }
        }

        $keyFile = __DIR__ . '/../config/firebase-service-account.json';
        if (!file_exists($keyFile)) {
            error_log("FcmHelper Error: firebase-service-account.json not found.");
            return null;
        }

        $config = json_decode(file_get_contents($keyFile), true);
        if (!$config || !isset($config['private_key'], $config['client_email'])) {
            error_log("FcmHelper Error: Invalid firebase-service-account.json format.");
            return null;
        }

        $privateKey = $config['private_key'];
        $clientEmail = $config['client_email'];

        $header = json_encode(['alg' => 'RS256', 'typ' => 'JWT']);
        $now = time();
        $payload = json_encode([
            'iss'   => $clientEmail,
            'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
            'aud'   => 'https://oauth2.googleapis.com/token',
            'exp'   => $now + 3600,
            'iat'   => $now
        ]);

        $base64UrlHeader = self::base64UrlEncode($header);
        $base64UrlPayload = self::base64UrlEncode($payload);

        $signatureInput = $base64UrlHeader . '.' . $base64UrlPayload;
        $signature = '';

        if (!openssl_sign($signatureInput, $signature, $privateKey, OPENSSL_ALGO_SHA256)) {
            error_log("FcmHelper Error: openssl_sign failed.");
            return null;
        }

        $base64UrlSignature = self::base64UrlEncode($signature);
        $assertion = $signatureInput . '.' . $base64UrlSignature;

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, 'https://oauth2.googleapis.com/token');
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion'  => $assertion
        ]));
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

        if ($httpCode !== 200) {
            error_log("FcmHelper Error: OAuth Token request failed with code $httpCode. Response: $response");
            return null;
        }

        $data = json_decode($response, true);
        $accessToken = $data['access_token'] ?? null;

        if ($accessToken) {
            // Cache token for 55 minutes (3300 seconds)
            $expiresAt = time() + 3300;
            @file_put_contents($cacheFile, json_encode([
                'access_token' => $accessToken,
                'expires_at'   => $expiresAt
            ]));
        }

        return $accessToken;
    }

    /**
     * Send push notification to a device token using Firebase v1 API.
     */
    public static function sendNotification(?string $token, string $title, string $body, array $data = []): bool {
        if (empty($token)) {
            return false;
        }

        $accessToken = self::getAccessToken();
        if (!$accessToken) {
            return false;
        }

        $keyFile = __DIR__ . '/../config/firebase-service-account.json';
        $config = json_decode(file_get_contents($keyFile), true);
        $projectId = $config['project_id'] ?? 'vendorandcustomermess';

        $stringData = new stdClass();
        foreach ($data as $key => $val) {
            $stringData->{$key} = is_scalar($val) ? (string)$val : json_encode($val);
        }
        $stringData->title = $title;
        $stringData->body = $body;

        // ── Zomato/Swiggy-style rich FCM payload ─────────────────────────────
        $imageUrl   = $data['image_url'] ?? $data['image'] ?? null;
        $actionBtns = [];
        if (!empty($data['action_buttons'])) {
            if (is_array($data['action_buttons'])) {
                $actionBtns = $data['action_buttons'];
            } elseif (is_string($data['action_buttons'])) {
                $decoded = json_decode($data['action_buttons'], true);
                if (is_array($decoded)) {
                    $actionBtns = $decoded;
                }
            }
        }
        $clickAction  = $data['click_action'] ?? 'HOME';
        $brandColor   = $data['brand_color'] ?? '#FF6B35';

        $payload = [
            'message' => [
                'token' => $token,
                'data'  => $stringData,

                // ── Android: Data-only high priority push (app handles display, avoids duplicate system tray popup) ───
                'android' => [
                    'priority' => 'HIGH',
                    'ttl'      => '86400s',
                ],

                // ── iOS: show on lockscreen immediately ──────────────────────
                'apns' => [
                    'headers' => [
                        'apns-priority'    => '10',
                        'apns-push-type'   => 'alert',
                    ],
                    'payload' => [
                        'aps' => [
                            'alert' => [
                                'title' => $title,
                                'body'  => $body,
                            ],
                            'sound'             => 'default',
                            'badge'             => 1,
                            'content-available' => 1,
                            'mutable-content'   => 1,
                        ],
                    ],
                    'fcm_options' => [
                        'analytics_label' => 'admin_broadcast',
                    ],
                ],
            ]
        ];

        // ── Attach Big Picture image if a valid HTTP/HTTPS URL is provided ─
        $validImageUrl = null;
        if (!empty($imageUrl) && is_string($imageUrl)) {
            $trimmedUrl = trim($imageUrl);
            if (filter_var($trimmedUrl, FILTER_VALIDATE_URL) && preg_match('~^https?://~i', $trimmedUrl)) {
                $validImageUrl = $trimmedUrl;
            }
        }
        if ($validImageUrl) {
            $stringData->image_url = $validImageUrl;
            $stringData->image     = $validImageUrl;
            $payload['message']['notification'] = [
                'title' => $title,
                'body'  => $body,
                'image' => $validImageUrl,
            ];
            $payload['message']['android']['notification'] = [
                'title'                   => $title,
                'body'                    => $body,
                'image'                   => $validImageUrl,
                'channel_id'              => 'high_importance_channel',
                'default_sound'           => true,
                'default_vibrate_timings' => true,
                'notification_priority'   => 'PRIORITY_MAX',
            ];
            $payload['message']['apns']['fcm_options']['image'] = $validImageUrl;
        }

        // Action buttons are passed strictly via data payload (data.action_buttons)
        // because FCM v1 android.notification does not support an 'actions' field.
        if (!empty($actionBtns)) {
            $stringData->action_buttons = json_encode(array_values($actionBtns));
        }

        // ── Collapse key for same-order grouping ─────────────────────────────
        if (isset($data['order_id'])) {
            $collapseKey = 'order_' . $data['order_id'];
            $payload['message']['android']['collapse_key'] = $collapseKey;
            $payload['message']['apns']['headers']['apns-collapse-id'] = $collapseKey;
        }

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, "https://fcm.googleapis.com/v1/projects/$projectId/messages:send");
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Authorization: Bearer ' . $accessToken,
            'Content-Type: application/json'
        ]);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

        if ($httpCode !== 200) {
            error_log("FcmHelper Error: FCM send failed with code $httpCode. Response: $response");
            if ($httpCode === 404 || strpos((string)$response, 'UNREGISTERED') !== false || strpos((string)$response, 'NotRegistered') !== false) {
                self::pruneInvalidToken($token);
            }
            return false;
        }

        return true;
    }

    /**
     * Remove invalid or expired FCM token from database tables.
     */
    public static function pruneInvalidToken(?string $token): void {
        if (empty($token)) return;
        try {
            $pdo = getDBConnection();
            $pdo->prepare("UPDATE customers SET fcm_token = NULL WHERE fcm_token = ?")->execute([$token]);
            $pdo->prepare("UPDATE vendors SET fcm_token = NULL WHERE fcm_token = ?")->execute([$token]);
            $pdo->prepare("UPDATE drivers SET fcm_token = NULL WHERE fcm_token = ?")->execute([$token]);
        } catch (Exception $e) {
            error_log("FcmHelper pruneInvalidToken Error: " . $e->getMessage());
        }
    }

    /**
     * Send push notifications in parallel (concurrently) to multiple FCM tokens using cURL multi.
     * Dramatically accelerates bulk broadcast delivery speed.
     */
    public static function sendBatchNotifications(array $tokens, string $title, string $body, array $data = []): int {
        $tokens = array_values(array_filter(array_unique($tokens)));
        if (empty($tokens)) {
            return 0;
        }

        // Fast & robust path for single recipient
        if (count($tokens) === 1) {
            return self::sendNotification($tokens[0], $title, $body, $data) ? 1 : 0;
        }

        $accessToken = self::getAccessToken();
        if (!$accessToken) {
            return 0;
        }

        $keyFile = __DIR__ . '/../config/firebase-service-account.json';
        if (!file_exists($keyFile)) {
            error_log("FcmHelper Error: firebase-service-account.json not found.");
            return 0;
        }

        $config = json_decode(file_get_contents($keyFile), true);
        $projectId = $config['project_id'] ?? 'vendorandcustomermess';
        $url = "https://fcm.googleapis.com/v1/projects/$projectId/messages:send";

        $stringData = new stdClass();
        foreach ($data as $key => $val) {
            $stringData->{$key} = is_scalar($val) ? (string)$val : json_encode($val);
        }
        $stringData->title = $title;
        $stringData->body = $body;

        $imageUrl   = $data['image_url'] ?? $data['image'] ?? null;
        $actionBtns = [];
        if (!empty($data['action_buttons'])) {
            if (is_array($data['action_buttons'])) {
                $actionBtns = $data['action_buttons'];
            } elseif (is_string($data['action_buttons'])) {
                $decoded = json_decode($data['action_buttons'], true);
                if (is_array($decoded)) {
                    $actionBtns = $decoded;
                }
            }
        }
        $clickAction  = $data['click_action'] ?? 'HOME';
        $brandColor   = $data['brand_color'] ?? '#FF6B35';

        $baseMessage = [
            'data'    => $stringData,
            'android' => [
                'priority' => 'HIGH',
                'ttl'      => '86400s',
            ],
            'apns' => [
                'headers' => [
                    'apns-priority'  => '10',
                    'apns-push-type' => 'alert',
                ],
                'payload' => [
                    'aps' => [
                        'alert' => [
                            'title' => $title,
                            'body'  => $body,
                        ],
                        'sound'             => 'default',
                        'badge'             => 1,
                        'content-available' => 1,
                        'mutable-content'   => 1,
                    ],
                ],
                'fcm_options' => [
                    'analytics_label' => 'admin_broadcast',
                ],
            ],
        ];

        // ── Attach Big Picture image if a valid HTTP/HTTPS URL is provided ─
        $validImageUrl = null;
        if (!empty($imageUrl) && is_string($imageUrl)) {
            $trimmedUrl = trim($imageUrl);
            if (filter_var($trimmedUrl, FILTER_VALIDATE_URL) && preg_match('~^https?://~i', $trimmedUrl)) {
                $validImageUrl = $trimmedUrl;
            }
        }
        if ($validImageUrl) {
            $baseMessage['data']->image_url = $validImageUrl;
            $baseMessage['data']->image     = $validImageUrl;
            $baseMessage['notification'] = [
                'title' => $title,
                'body'  => $body,
                'image' => $validImageUrl,
            ];
            $baseMessage['android']['notification'] = [
                'title'                   => $title,
                'body'                    => $body,
                'image'                   => $validImageUrl,
                'channel_id'              => 'high_importance_channel',
                'default_sound'           => true,
                'default_vibrate_timings' => true,
                'notification_priority'   => 'PRIORITY_MAX',
            ];
            $baseMessage['apns']['fcm_options']['image'] = $validImageUrl;
        }

        // Action buttons are passed strictly via data payload (data.action_buttons)
        // because FCM v1 android.notification does not support an 'actions' field.
        if (!empty($actionBtns)) {
            $stringData->action_buttons = json_encode(array_values($actionBtns));
        }

        if (isset($data['order_id'])) {
            $collapseKey = 'order_' . $data['order_id'];
            $baseMessage['android']['collapse_key'] = $collapseKey;
            $baseMessage['apns']['headers']['apns-collapse-id'] = $collapseKey;
        }

        $headers = [
            'Authorization: Bearer ' . $accessToken,
            'Content-Type: application/json'
        ];

        $chunks = array_chunk($tokens, 30);
        $successfulCount = 0;

        foreach ($chunks as $chunk) {
            $mh = curl_multi_init();
            $curlHandles = [];

            foreach ($chunk as $token) {
                $msg = $baseMessage;
                $msg['token'] = $token;
                $payloadJson = json_encode(['message' => $msg]);

                $ch = curl_init();
                curl_setopt($ch, CURLOPT_URL, $url);
                curl_setopt($ch, CURLOPT_POST, true);
                curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
                curl_setopt($ch, CURLOPT_POSTFIELDS, $payloadJson);
                curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
                curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
                curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);
                curl_setopt($ch, CURLOPT_TIMEOUT, 10);
                curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 5);

                curl_multi_add_handle($mh, $ch);
                $curlHandles[$token] = $ch;
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

            foreach ($curlHandles as $token => $ch) {
                $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
                $errResponse = curl_multi_getcontent($ch);
                if ($httpCode === 200) {
                    $successfulCount++;
                } else {
                    error_log("FcmHelper Batch Error ($httpCode): $errResponse");
                    if ($httpCode === 404 || strpos((string)$errResponse, 'UNREGISTERED') !== false || strpos((string)$errResponse, 'NotRegistered') !== false) {
                        self::pruneInvalidToken($token);
                    }
                }
                curl_multi_remove_handle($mh, $ch);
            }

            curl_multi_close($mh);
        }

        return $successfulCount;
    }

    private static function runInBackground(string $role, int $id, string $title, string $body, array $data = []): void {
        // Check if exec() is enabled and not listed in disable_functions
        $execEnabled = function_exists('exec');
        if ($execEnabled) {
            $disabledFunctions = array_map('trim', explode(',', ini_get('disable_functions')));
            if (in_array('exec', $disabledFunctions)) {
                $execEnabled = false;
            }
        }

        if (!$execEnabled) {
            // Fallback: Run synchronously if background execution is disabled (e.g., Hostinger shared hosting)
            switch ($role) {
                case 'customer':
                    self::sendToCustomerDirect($id, $title, $body, $data);
                    break;
                case 'vendor':
                    self::sendToVendorDirect($id, $title, $body, $data);
                    break;
                case 'driver':
                    self::sendToDriverDirect($id, $title, $body, $data);
                    break;
            }
            return;
        }

        $titleEncoded = base64_encode($title);
        $bodyEncoded = base64_encode($body);
        $dataEncoded = base64_encode(json_encode($data));
        
        $scriptPath = __DIR__ . '/fcm_bg.php';
        $phpBinary = (defined('PHP_BINARY') && PHP_BINARY) ? PHP_BINARY : 'php';
        
        $command = escapeshellarg($phpBinary) . " " . escapeshellarg($scriptPath) . " " . 
                   escapeshellarg($role) . " " . 
                   escapeshellarg($id) . " " . 
                   escapeshellarg($titleEncoded) . " " . 
                   escapeshellarg($bodyEncoded) . " " . 
                   escapeshellarg($dataEncoded);
        
        if (substr(php_uname(), 0, 7) === "Windows") {
            pclose(popen("start \"\" /B " . $command . " >> " . escapeshellarg(__DIR__ . '/fcm_bg.log') . " 2>&1", "r"));
        } else {
            exec($command . " > /dev/null 2>&1 &");
        }
    }

    /**
     * Send FCM push to Customer (Asynchronous wrapper).
     */
    public static function sendToCustomer(int $customerId, string $title, string $body, array $data = []): void {
        self::runInBackground('customer', $customerId, $title, $body, $data);
    }

    /**
     * Send FCM push to Vendor (Asynchronous wrapper).
     */
    public static function sendToVendor(int $vendorId, string $title, string $body, array $data = []): void {
        self::runInBackground('vendor', $vendorId, $title, $body, $data);
    }

    /**
     * Send FCM push to Driver (Asynchronous wrapper).
     */
    public static function sendToDriver(int $driverId, string $title, string $body, array $data = []): void {
        self::runInBackground('driver', $driverId, $title, $body, $data);
    }

    /**
     * Send FCM push to Customer directly (Synchronous, called by background process).
     */
    public static function sendToCustomerDirect(int $customerId, string $title, string $body, array $data = []): bool {
        try {
            $pdo = getDBConnection();
            $stmt = $pdo->prepare("SELECT fcm_token FROM customers WHERE id = ? LIMIT 1");
            $stmt->execute([$customerId]);
            $token = $stmt->fetchColumn();
            return self::sendNotification($token, $title, $body, $data);
        } catch (Exception $e) {
            error_log("FcmHelper Direct Error: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Send FCM push to Vendor directly (Synchronous, called by background process).
     */
    public static function sendToVendorDirect(int $vendorId, string $title, string $body, array $data = []): bool {
        try {
            $pdo = getDBConnection();
            $stmt = $pdo->prepare("SELECT fcm_token FROM vendors WHERE id = ? LIMIT 1");
            $stmt->execute([$vendorId]);
            $token = $stmt->fetchColumn();
            return self::sendNotification($token, $title, $body, $data);
        } catch (Exception $e) {
            error_log("FcmHelper Direct Error: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Send FCM push to Driver directly (Synchronous, called by background process).
     */
    public static function sendToDriverDirect(int $driverId, string $title, string $body, array $data = []): bool {
        try {
            $pdo = getDBConnection();
            $stmt = $pdo->prepare("SELECT fcm_token FROM drivers WHERE id = ? LIMIT 1");
            $stmt->execute([$driverId]);
            $token = $stmt->fetchColumn();
            return self::sendNotification($token, $title, $body, $data);
        } catch (Exception $e) {
            error_log("FcmHelper Direct Error: " . $e->getMessage());
            return false;
        }
    }

    private static function base64UrlEncode(string $data): string {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }
}
