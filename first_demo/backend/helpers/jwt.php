<?php
/**
 * Lightweight JWT (JSON Web Token) Helper
 * Implements HS256 signing — no external library needed.
 */

require_once __DIR__ . '/../config/database.php';

class JWT {

    /**
     * Generate a JWT token for the given payload.
     *
     * @param  array  $payload  Data to encode (do NOT include sensitive info like password)
     * @return string           Signed JWT string
     */
    public static function generate(array $payload): string {
        $header = self::base64UrlEncode(json_encode([
            'alg' => 'HS256',
            'typ' => 'JWT',
        ]));

        $payload['iat'] = time();
        $payload['exp'] = time() + JWT_EXPIRY;

        $encodedPayload = self::base64UrlEncode(json_encode($payload));

        $signature = hash_hmac(
            'sha256',
            $header . '.' . $encodedPayload,
            JWT_SECRET,
            true
        );

        $encodedSignature = self::base64UrlEncode($signature);

        return $header . '.' . $encodedPayload . '.' . $encodedSignature;
    }

    /**
     * Validate and decode a JWT token.
     *
     * @param  string  $token  Raw JWT string
     * @return array|null      Decoded payload on success, null on failure
     */
    public static function verify(string $token): ?array {
        $parts = explode('.', $token);
        if (count($parts) !== 3) {
            return null;
        }

        [$header, $payload, $signature] = $parts;

        // Recompute signature and compare
        $expectedSignature = self::base64UrlEncode(
            hash_hmac('sha256', $header . '.' . $payload, JWT_SECRET, true)
        );

        if (!hash_equals($expectedSignature, $signature)) {
            return null; // Signature mismatch — tampered token
        }

        $decodedPayload = json_decode(self::base64UrlDecode($payload), true);

        if (!$decodedPayload) {
            return null;
        }

        // Check expiry
        if (isset($decodedPayload['exp']) && $decodedPayload['exp'] < time()) {
            return null; // Token expired
        }

        return $decodedPayload;
    }

    /**
     * Extract Bearer token from the Authorization header.
     */
    public static function getBearerToken(): ?string {
        $authHeader = $_SERVER['HTTP_AUTHORIZATION']
            ?? apache_request_headers()['Authorization']
            ?? null;

        if ($authHeader && preg_match('/Bearer\s+(.+)/i', $authHeader, $matches)) {
            return trim($matches[1]);
        }

        return null;
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private static function base64UrlEncode(string $data): string {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    private static function base64UrlDecode(string $data): string {
        return base64_decode(strtr($data, '-_', '+/'));
    }
}
