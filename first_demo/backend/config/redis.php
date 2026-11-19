<?php
/**
 * Redis Configuration - Powered by Upstash Serverless Redis
 * Supports Localhost, Hostinger Shared Hosting, and Cloud Production.
 * 
 * Auto-detects availability: When Redis is online, it accelerates menu caching,
 * driver GPS tracking, and atomic wallet mutex locks.
 * If unreachable, it safely and transparently falls back to MySQL.
 */

if (!defined('REDIS_ENABLED')) {
    $envEnabled = getenv('REDIS_ENABLED');
    define('REDIS_ENABLED', $envEnabled !== false ? filter_var($envEnabled, FILTER_VALIDATE_BOOLEAN) : true);
}

// Upstash Cloud Redis Host & Port
if (!defined('REDIS_HOST')) {
    define('REDIS_HOST', getenv('REDIS_HOST') ?: 'gentle-firefly-125356.upstash.io');
}

if (!defined('REDIS_PORT')) {
    define('REDIS_PORT', (int)(getenv('REDIS_PORT') ?: 6379));
}

// Upstash requires TLS encryption
if (!defined('REDIS_TLS')) {
    $envTls = getenv('REDIS_TLS');
    define('REDIS_TLS', $envTls !== false ? filter_var($envTls, FILTER_VALIDATE_BOOLEAN) : true);
}

// Upstash Redis Token / Password
if (!defined('REDIS_PASSWORD')) {
    $envPass = getenv('REDIS_PASSWORD');
    define('REDIS_PASSWORD', ($envPass !== false && $envPass !== '') 
        ? $envPass 
        : 'gQAAAAAAAemsAAIgcDFiNTUzZmE1YjdiMTQ0Mjk3OGM4NjRiYmU1Mzg5NmE2ZQ');
}

if (!defined('REDIS_TIMEOUT')) {
    // 2.5s timeout allows reliable TLS handshake to Upstash Cloud
    define('REDIS_TIMEOUT', (float)(getenv('REDIS_TIMEOUT') ?: 2.5));
}

if (!defined('REDIS_PREFIX')) {
    define('REDIS_PREFIX', getenv('REDIS_PREFIX') ?: 'omni:');
}

if (!defined('REDIS_DEFAULT_TTL')) {
    define('REDIS_DEFAULT_TTL', 900); // 15 minutes default cache TTL
}
