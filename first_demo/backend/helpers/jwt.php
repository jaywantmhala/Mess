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

        // Never expire tokens — session remains active until user manually logs out (like WhatsApp / Instagram)
        return $decodedPayload;
    }

    /**
     * Extract Bearer token from the Authorization header.
     */
    public static function getBearerToken(): ?string {
        $authHeader = $_SERVER['HTTP_AUTHORIZATION']
            ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION']
            ?? (function_exists('getallheaders') ? (getallheaders()['Authorization'] ?? getallheaders()['authorization'] ?? null) : null)
            ?? (function_exists('apache_request_headers') ? (apache_request_headers()['Authorization'] ?? null) : null)
            ?? null;

        if ($authHeader && preg_match('/Bearer\s+(.+)/i', $authHeader, $matches)) {
            return trim($matches[1]);
        }

        return null;
    }

    /**
     * Generate a long-lived Refresh Token and store its hash in database.
     */
    public static function generateRefreshToken(int $userId, string $role, PDO $pdo): string {
        $rawToken = bin2hex(random_bytes(32));
        $hash = hash('sha256', $rawToken);
        $expiry = date('Y-m-d H:i:s', time() + JWT_REFRESH_EXPIRY);

        // Delete old refresh tokens for this user & role
        $stmt = $pdo->prepare("DELETE FROM refresh_tokens WHERE user_id = :user_id AND role = :role");
        $stmt->execute([':user_id' => $userId, ':role' => $role]);

        // Insert new refresh token
        $stmt = $pdo->prepare("
            INSERT INTO refresh_tokens (user_id, role, token_hash, expires_at, created_at)
            VALUES (:user_id, :role, :token_hash, :expires_at, NOW())
        ");
        $stmt->execute([
            ':user_id'    => $userId,
            ':role'       => $role,
            ':token_hash' => $hash,
            ':expires_at' => $expiry,
        ]);

        return $rawToken;
    }

    /**
     * Verify a Refresh Token from DB and return user payload if valid.
     */
    public static function verifyRefreshToken(string $rawToken, PDO $pdo): ?array {
        if (empty($rawToken)) {
            return null;
        }

        $hash = hash('sha256', $rawToken);
        $stmt = $pdo->prepare("
            SELECT id, user_id, role, expires_at
            FROM refresh_tokens
            WHERE token_hash = :hash AND expires_at > NOW()
            LIMIT 1
        ");
        $stmt->execute([':hash' => $hash]);
        $row = $stmt->fetch();

        if (!$row) {
            return null;
        }

        return [
            'user_id' => (int) $row['user_id'],
            'role'    => $row['role'],
        ];
    }

    /**
     * Revoke a Refresh Token.
     */
    public static function revokeRefreshToken(string $rawToken, PDO $pdo): void {
        if (empty($rawToken)) return;
        $hash = hash('sha256', $rawToken);
        $stmt = $pdo->prepare("DELETE FROM refresh_tokens WHERE token_hash = :hash");
        $stmt->execute([':hash' => $hash]);
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private static function base64UrlEncode(string $data): string {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    private static function base64UrlDecode(string $data): string {
        return base64_decode(strtr($data, '-_', '+/'));
    }
}
