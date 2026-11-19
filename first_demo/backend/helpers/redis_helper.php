<?php
/**
 * Omnichannel Redis Helper
 * 
 * Provides production-grade Redis capabilities:
 * 1. Menu & Hotel Caching (Cache-aside with instant invalidation)
 * 2. Driver Live GPS Geospatial Tracking (GEOADD & GEOPOS)
 * 3. Wallet & Order Concurrency Locks (SETNX atomic mutex)
 * 
 * Architecture:
 * - Uses native php-redis C extension when available, with automatic fallback
 *   to pure PHP RESP stream sockets (zero external dependencies).
 * - Implements a 150ms Circuit Breaker: If Redis server is offline or unreachable,
 *   all operations degrade gracefully with zero crashes and fall back to MySQL.
 */

require_once __DIR__ . '/../config/redis.php';

class RedisHelper {
    private static $instance = null;
    private static $checked = false;
    private static $available = false;

    private $extRedis = null;
    private $socket = null;
    private $isSocket = false;

    private function __construct() {
        if (!REDIS_ENABLED) {
            self::$available = false;
            return;
        }

        // 1. Try native PHP Redis extension first
        if (extension_loaded('redis')) {
            try {
                $r = new \Redis();
                $host = (defined('REDIS_TLS') && REDIS_TLS) ? 'tls://' . REDIS_HOST : REDIS_HOST;
                $connected = @$r->connect($host, REDIS_PORT, REDIS_TIMEOUT);
                if ($connected) {
                    if (REDIS_PASSWORD) {
                        @$r->auth(REDIS_PASSWORD);
                    }
                    $this->extRedis = $r;
                    self::$available = true;
                    return;
                }
            } catch (\Throwable $e) {
                // Fall through to socket client
            }
        }

        // 2. Pure PHP RESP stream socket fallback
        try {
            $errno = 0;
            $errstr = '';
            $protocol = (defined('REDIS_TLS') && REDIS_TLS) ? 'tls://' : 'tcp://';
            $context = stream_context_create([
                'ssl' => [
                    'verify_peer' => false,
                    'verify_peer_name' => false,
                ]
            ]);
            $socket = @stream_socket_client(
                $protocol . REDIS_HOST . ':' . REDIS_PORT,
                $errno,
                $errstr,
                REDIS_TIMEOUT,
                STREAM_CLIENT_CONNECT,
                $context
            );

            if ($socket) {
                stream_set_timeout($socket, 2);
                $this->socket = $socket;
                $this->isSocket = true;

                // Authenticate if password provided
                if (REDIS_PASSWORD) {
                    $authRes = $this->rawCommand(['AUTH', REDIS_PASSWORD]);
                    if ($authRes !== 'OK') {
                        @fclose($this->socket);
                        $this->socket = null;
                        self::$available = false;
                        return;
                    }
                }

                // Verify with PING
                $pingRes = $this->rawCommand(['PING']);
                if ($pingRes === 'PONG') {
                    self::$available = true;
                    return;
                }
            }
        } catch (\Throwable $e) {
            // Redis offline - circuit breaker tripped
        }

        self::$available = false;
    }

    /**
     * Get singleton instance
     */
    public static function getInstance(): ?RedisHelper {
        if (self::$instance === null) {
            self::$instance = new self();
            self::$checked = true;
        }
        return self::$available ? self::$instance : null;
    }

    /**
     * Check if Redis is online and connected
     */
    public static function isConnected(): bool {
        if (!self::$checked) {
            self::getInstance();
        }
        return self::$available;
    }

    /**
     * Prefix helper
     */
    private static function key(string $k): string {
        return REDIS_PREFIX . $k;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // RAW RESP PROTOCOL CLIENT (Zero Dependencies)
    // ─────────────────────────────────────────────────────────────────────────

    private function rawCommand(array $args) {
        if (!$this->isSocket || !$this->socket) return null;

        $cmd = '*' . count($args) . "\r\n";
        foreach ($args as $arg) {
            $arg = (string)$arg;
            $cmd .= '$' . strlen($arg) . "\r\n" . $arg . "\r\n";
        }

        $written = @fwrite($this->socket, $cmd);
        if ($written === false) {
            self::$available = false;
            return null;
        }

        return $this->parseResp();
    }

    private function parseResp() {
        if (!$this->socket) return null;
        $type = fgetc($this->socket);
        if ($type === false) return null;
        $line = fgets($this->socket);
        if ($line === false) return null;
        $payload = rtrim($line, "\r\n");

        switch ($type) {
            case '+': // Simple string (+OK)
                return $payload;
            case '-': // Error (-ERR ...)
                return null;
            case ':': // Integer (:1)
                return (int)$payload;
            case '$': // Bulk string ($6\r\nfoobar\r\n or $-1)
                $len = (int)$payload;
                if ($len === -1) return null;
                $data = '';
                $remaining = $len;
                while ($remaining > 0) {
                    $chunk = fread($this->socket, min($remaining, 8192));
                    if ($chunk === false) break;
                    $data .= $chunk;
                    $remaining -= strlen($chunk);
                }
                fread($this->socket, 2); // Discard \r\n
                return $data;
            case '*': // Array (*2\r\n...)
                $count = (int)$payload;
                if ($count === -1) return null;
                $arr = [];
                for ($i = 0; $i < $count; $i++) {
                    $arr[] = $this->parseResp();
                }
                return $arr;
            default:
                return null;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // FEATURE 1: MENU & DATA CACHING (Cache-Aside Pattern)
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Retrieve cached value by key
     */
    public static function get(string $key) {
        $redis = self::getInstance();
        if (!$redis) return null;

        $prefixedKey = self::key($key);
        try {
            if ($redis->extRedis) {
                $val = $redis->extRedis->get($prefixedKey);
            } else {
                $val = $redis->rawCommand(['GET', $prefixedKey]);
            }
            if ($val === null || $val === false) return null;

            // Attempt JSON decode
            $decoded = json_decode($val, true);
            return (json_last_error() === JSON_ERROR_NONE) ? $decoded : $val;
        } catch (\Throwable $e) {
            return null;
        }
    }

    /**
     * Store key-value in Redis with optional TTL (default 15 mins)
     */
    public static function set(string $key, $value, ?int $ttl = null): bool {
        $redis = self::getInstance();
        if (!$redis) return false;

        $ttl = $ttl ?? REDIS_DEFAULT_TTL;
        $prefixedKey = self::key($key);
        $encoded = is_array($value) || is_object($value) ? json_encode($value) : (string)$value;

        try {
            if ($redis->extRedis) {
                return (bool)$redis->extRedis->setex($prefixedKey, $ttl, $encoded);
            } else {
                $res = $redis->rawCommand(['SET', $prefixedKey, $encoded, 'EX', (string)$ttl]);
                return $res === 'OK';
            }
        } catch (\Throwable $e) {
            return false;
        }
    }

    /**
     * Delete one or more keys
     */
    public static function del(string ...$keys): int {
        $redis = self::getInstance();
        if (!$redis || empty($keys)) return 0;

        $prefixed = array_map(function($k) { return self::key($k); }, $keys);
        try {
            if ($redis->extRedis) {
                return (int)$redis->extRedis->del($prefixed);
            } else {
                $args = array_merge(['DEL'], $prefixed);
                $res = $redis->rawCommand($args);
                return is_int($res) ? $res : 0;
            }
        } catch (\Throwable $e) {
            return 0;
        }
    }

    /**
     * Cache-Aside Helper: Returns cached data or computes and stores it
     */
    public static function remember(string $key, int $ttl, callable $callback) {
        $cached = self::get($key);
        if ($cached !== null) {
            return $cached;
        }

        $fresh = $callback();
        if ($fresh !== null) {
            self::set($key, $fresh, $ttl);
        }
        return $fresh;
    }

    /**
     * Invalidate hotel menu cache
     */
    public static function invalidateHotelMenu(int $hotelId, ?string $date = null) {
        $date = $date ?: date('Y-m-d');
        self::del(
            "menu:hotel:{$hotelId}:{$date}",
            "menu:hotel:{$hotelId}:all",
            "hotels:nearby:all"
        );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // FEATURE 2: DRIVER LIVE GPS TRACKING (Geospatial & In-Memory Coords)
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Update driver's live GPS coordinates in Redis
     * Sets in GEO index and updates driver cache with 120s TTL
     */
    public static function updateDriverLocation(int $driverId, float $lat, float $lng, array $meta = []): bool {
        $redis = self::getInstance();
        if (!$redis) return false;

        $geoKey = self::key('drivers:active:geo');
        $driverMember = "driver:{$driverId}";
        $locKey = "driver:{$driverId}:location";

        $locData = array_merge([
            'driver_id'  => $driverId,
            'latitude'   => $lat,
            'longitude'  => $lng,
            'updated_at' => date('Y-m-d H:i:s'),
            'timestamp'  => time(),
        ], $meta);

        try {
            // 1. Update GEO index (longitude first in Redis GEOADD)
            if ($redis->extRedis) {
                $redis->extRedis->geoAdd($geoKey, $lng, $lat, $driverMember);
            } else {
                $redis->rawCommand(['GEOADD', $geoKey, (string)$lng, (string)$lat, $driverMember]);
            }

            // 2. Cache driver's rich location record with 2-minute TTL
            self::set($locKey, $locData, 120);
            return true;
        } catch (\Throwable $e) {
            return false;
        }
    }

    /**
     * Get driver's live GPS coordinates from Redis
     * Returns array with latitude & longitude or null if not found
     */
    public static function getDriverLocation(int $driverId): ?array {
        $cached = self::get("driver:{$driverId}:location");
        if ($cached && is_array($cached)) {
            return $cached;
        }

        $redis = self::getInstance();
        if (!$redis) return null;

        $geoKey = self::key('drivers:active:geo');
        $driverMember = "driver:{$driverId}";

        try {
            if ($redis->extRedis) {
                $pos = $redis->extRedis->geoPos($geoKey, $driverMember);
                if (!empty($pos[0])) {
                    return [
                        'driver_id' => $driverId,
                        'longitude' => (float)$pos[0][0],
                        'latitude'  => (float)$pos[0][1],
                    ];
                }
            } else {
                $pos = $redis->rawCommand(['GEOPOS', $geoKey, $driverMember]);
                if (is_array($pos) && !empty($pos[0]) && is_array($pos[0])) {
                    return [
                        'driver_id' => $driverId,
                        'longitude' => (float)$pos[0][0],
                        'latitude'  => (float)$pos[0][1],
                    ];
                }
            }
        } catch (\Throwable $e) {
            return null;
        }

        return null;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // FEATURE 3: WALLET & ORDER CONCURRENCY LOCK (Atomic Distributed Mutex)
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Acquire atomic lock for a given resource
     * Uses: SET key token NX EX ttl
     * 
     * @param string $lockKey Key to lock (e.g., "customer:123:wallet" or "order:place:123")
     * @param int $ttlSeconds Expiration in seconds (default 3s)
     * @param string|null &$token Outputs unique token for safe release
     * @return bool True if lock acquired (or Redis offline); False if already locked
     */
    public static function lock(string $lockKey, int $ttlSeconds = 3, ?string &$token = null): bool {
        $redis = self::getInstance();
        if (!$redis) {
            // Safe fallback: If Redis is offline, allow transaction without blocking
            return true;
        }

        $token = bin2hex(random_bytes(16));
        $key = self::key("lock:{$lockKey}");

        try {
            if ($redis->extRedis) {
                return (bool)$redis->extRedis->set($key, $token, ['NX', 'EX' => $ttlSeconds]);
            } else {
                $res = $redis->rawCommand(['SET', $key, $token, 'NX', 'EX', (string)$ttlSeconds]);
                return $res === 'OK';
            }
        } catch (\Throwable $e) {
            return true; // Fallback to allowing request
        }
    }

    /**
     * Release atomic lock safely (only deletes if token matches)
     */
    public static function unlock(string $lockKey, ?string $token = null): bool {
        $redis = self::getInstance();
        if (!$redis) return true;

        $key = self::key("lock:{$lockKey}");

        try {
            if ($token !== null) {
                // Safe Lua script or get check to prevent releasing another client's acquired lock
                $current = self::get("lock:{$lockKey}");
                if ($current !== $token) {
                    return false;
                }
            }
            return (bool)self::del("lock:{$lockKey}");
        } catch (\Throwable $e) {
            return false;
        }
    }
}
