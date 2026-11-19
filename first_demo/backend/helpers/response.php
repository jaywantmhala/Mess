<?php
/**
 * Standardised JSON Response Helper
 */

// Disable displaying PHP warnings/errors in the response output stream
ini_set('display_errors', '0');

function sendResponse(bool $success, string $message, array $data = [], int $httpCode = 200): void {
    if (ob_get_length()) {
        ob_clean();
    }
    http_response_code($httpCode);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode([
        'success' => $success,
        'message' => $message,
        'data'    => $data,
    ], JSON_UNESCAPED_UNICODE | JSON_INVALID_UTF8_SUBSTITUTE);
    exit;
}

function sendSuccess(string $message, array $data = [], int $httpCode = 200): void {
    sendResponse(true, $message, $data, $httpCode);
}

function sendError(string $message, int $httpCode = 400, array $data = []): void {
    sendResponse(false, $message, $data, $httpCode);
}
