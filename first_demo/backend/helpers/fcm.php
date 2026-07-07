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

        $payload = [
            'message' => [
                'token' => $token,
                'notification' => [
                    'title' => $title,
                    'body'  => $body
                ],
                'data' => $stringData,
                'android' => [
                    'notification' => [
                        'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                        'sound' => 'default'
                    ]
                ]
            ]
        ];

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
            return false;
        }

        return true;
    }

    /**
     * Spawn background process to send notification asynchronously (Fire-and-forget).
     */
    private static function runInBackground(string $role, int $id, string $title, string $body, array $data = []): void {
        $titleEncoded = base64_encode($title);
        $bodyEncoded = base64_encode($body);
        $dataEncoded = base64_encode(json_encode($data));
        
        $scriptPath = __DIR__ . '/fcm_bg.php';
        
        $command = "php " . escapeshellarg($scriptPath) . " " . 
                   escapeshellarg($role) . " " . 
                   escapeshellarg($id) . " " . 
                   escapeshellarg($titleEncoded) . " " . 
                   escapeshellarg($bodyEncoded) . " " . 
                   escapeshellarg($dataEncoded);
        
        if (substr(php_uname(), 0, 7) === "Windows") {
            pclose(popen("start /B " . $command . " > NUL 2>&1", "r"));
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
