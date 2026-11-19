<?php
/**
 * Admin API: Payout Run Batch History
 * GET /api/admin/payouts/runs
 */

require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../helpers/cors.php';
require_once __DIR__ . '/../../../helpers/jwt.php';
require_once __DIR__ . '/../../../helpers/response.php';

header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

try {
    // 1. Authenticate Admin Token
    $token = JWT::getBearerToken();
    $payload = $token ? JWT::verify($token) : null;
    if (!$payload || !isset($payload['sub']) || ($payload['role'] ?? '') !== 'admin') {
        sendError('Unauthorized. Admin access required.', 401);
    }

    $pdo = getDBConnection();

    $page = isset($_GET['page']) ? max(1, (int)$_GET['page']) : 1;
    $limit = isset($_GET['limit']) ? max(1, min(100, (int)$_GET['limit'])) : 10;
    $offset = ($page - 1) * $limit;

    $totalItems = (int)$pdo->query("SELECT COUNT(*) FROM `payout_runs`")->fetchColumn();
    $totalPages = ceil($totalItems / $limit);

    $stmt = $pdo->prepare("
        SELECT *
        FROM `payout_runs`
        ORDER BY id DESC
        LIMIT :limit OFFSET :offset
    ");
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();
    $runs = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success'    => true,
        'runs'       => $runs,
        'pagination' => [
            'current_page' => $page,
            'limit'        => $limit,
            'total_items'  => $totalItems,
            'total_pages'  => $totalPages,
        ],
    ]);

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
