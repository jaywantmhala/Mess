<?php
/**
 * Standardised JSON Response Helper
 */

function sendResponse(bool $success, string $message, array $data = [], int $httpCode = 200): void {
    http_response_code($httpCode);
    echo json_encode([
        'success' => $success,
        'message' => $message,
        'data'    => $data,
    ], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    exit;
}

function sendSuccess(string $message, array $data = [], int $httpCode = 200): void {
    sendResponse(true, $message, $data, $httpCode);
}

function sendError(string $message, int $httpCode = 400, array $data = []): void {
    sendResponse(false, $message, $data, $httpCode);
}
