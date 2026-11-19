<?php
/**
 * GET /api/public/redis_status
 * 
 * Reports Redis connectivity, configuration, and circuit-breaker status.
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/redis_helper.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') { 
    http_response_code(204); 
    exit; 
}

$connected = RedisHelper::isConnected();

sendSuccess('Redis health check completed.', [
    'redis_enabled'    => REDIS_ENABLED,
    'redis_connected'  => $connected,
    'redis_host'       => REDIS_HOST,
    'redis_port'       => REDIS_PORT,
    'status'           => $connected ? 'ONLINE_ACCELERATING' : 'OFFLINE_GRACEFUL_FALLBACK',
    'mode'             => $connected ? 'Redis High-Speed RAM (Cache, Mutex, GPS)' : 'MySQL Relational Fallback (Zero downtime)',
    'features_ready'   => [
        'menu_caching'            => true,
        'driver_live_gps'         => true,
        'wallet_concurrency_lock' => true,
    ],
]);
