<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

$uri    = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$uri    = rtrim($uri, '/');
$method = $_SERVER['REQUEST_METHOD'];

$routes = [
    // ── Auth ──────────────────────────────────────────────────────────────
    'POST /api/auth/signup'   => __DIR__ . '/api/auth/signup.php',
    'POST /api/auth/login'    => __DIR__ . '/api/auth/login.php',
    'GET  /api/auth/me'       => __DIR__ . '/api/auth/me.php',
    'POST /api/auth/logout'   => __DIR__ . '/api/auth/logout.php',
    'GET  /api/auth/address'  => __DIR__ . '/api/auth/address.php',
    'POST /api/auth/address'  => __DIR__ . '/api/auth/address.php',

    // ── Vendor ────────────────────────────────────────────────────────────
    'POST /api/vendor/signup'       => __DIR__ . '/api/vendor/signup.php',
    'POST /api/vendor/login'        => __DIR__ . '/api/vendor/login.php',
    'POST /api/vendor/add_hotel'    => __DIR__ . '/api/vendor/add_hotel.php',
    'GET  /api/vendor/hotels'       => __DIR__ . '/api/vendor/hotels.php',
    'POST /api/vendor/edit_hotel'   => __DIR__ . '/api/vendor/edit_hotel.php',
    'POST /api/vendor/delete_hotel' => __DIR__ . '/api/vendor/delete_hotel.php',
    'POST /api/vendor/menu/add'     => __DIR__ . '/api/vendor/menu/add.php',
    'GET  /api/vendor/menu/list'    => __DIR__ . '/api/vendor/menu/list.php',
    'POST /api/vendor/menu/edit'    => __DIR__ . '/api/vendor/menu/edit.php',
    'POST /api/vendor/menu/delete'  => __DIR__ . '/api/vendor/menu/delete.php',
    'GET  /api/vendor/orders'        => __DIR__ . '/api/vendor/orders/list.php',
    'POST /api/vendor/orders/status' => __DIR__ . '/api/vendor/orders/status.php',

    // ── Hotels (public) ───────────────────────────────────────────────────
    'GET  /api/hotels/nearby' => __DIR__ . '/api/hotels/nearby.php',
    'GET  /api/hotels/menu'   => __DIR__ . '/api/hotels/menu.php',

    // ── Wallet ────────────────────────────────────────────────────────────
    'GET  /api/wallet/balance'      => __DIR__ . '/api/wallet/balance.php',
    'POST /api/wallet/recharge'     => __DIR__ . '/api/wallet/recharge.php',
    'GET  /api/wallet/transactions' => __DIR__ . '/api/wallet/transactions.php',

    // ── Cart ──────────────────────────────────────────────────────────────
    'POST /api/cart/add'    => __DIR__ . '/api/cart/add.php',
    'GET  /api/cart/list'   => __DIR__ . '/api/cart/list.php',
    'POST /api/cart/update' => __DIR__ . '/api/cart/update.php',
    'POST /api/cart/clear'  => __DIR__ . '/api/cart/clear.php',

    // ── Orders ────────────────────────────────────────────────────────────
    'POST /api/orders/place'   => __DIR__ . '/api/orders/place.php',
    'GET  /api/orders/history' => __DIR__ . '/api/orders/history.php',
    'GET  /api/orders/details' => __DIR__ . '/api/orders/details.php',
];

foreach ($routes as $pattern => $file) {
    [$routeMethod, $routePath] = explode(' ', $pattern, 2);
    if (trim($routeMethod) === $method && trim($routePath) === $uri) {
        if (file_exists($file)) {
            require $file;
            exit;
        }
        http_response_code(500);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode(['success' => false, 'message' => "Handler file not found: $file"]);
        exit;
    }
}

// ── Root health-check ──────────────────────────────────────────────────────
if ($uri === '' || $uri === '/') {
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode(
        [
            'success' => true,
            'service' => 'first_demo PHP REST API',
            'version' => '2.0.0',
            'status'  => 'running',
        ],
        JSON_PRETTY_PRINT
    );
    exit;
}

// ── 404 ────────────────────────────────────────────────────────────────────
http_response_code(404);
header('Content-Type: application/json; charset=utf-8');
echo json_encode(
    [
        'success'          => false,
        'message'          => "Route not found: $method $uri",
        'available_routes' => array_keys($routes),
    ],
    JSON_PRETTY_PRINT
);
