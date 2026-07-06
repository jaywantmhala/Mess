<?php
/**
 * Input Validation Helpers
 */

/**
 * Validate an email address.
 */
function isValidEmail(string $email): bool {
    return filter_var(trim($email), FILTER_VALIDATE_EMAIL) !== false;
}

/**
 * Validate password strength.
 * Minimum 8 characters, at least one letter and one number.
 */
function isValidPassword(string $password): bool {
    return strlen($password) >= 8
        && preg_match('/[A-Za-z]/', $password)
        && preg_match('/[0-9]/', $password);
}

/**
 * Sanitize a string: trim whitespace and strip HTML tags.
 */
function sanitize(string $value): string {
    return htmlspecialchars(strip_tags(trim($value)), ENT_QUOTES, 'UTF-8');
}

/**
 * Get and validate required JSON body fields.
 * Returns parsed body array or calls sendError() and exits.
 */
function requireJsonBody(array $requiredFields): array {
    $raw = file_get_contents('php://input');
    $body = json_decode($raw, true);

    if (json_last_error() !== JSON_ERROR_NONE || !is_array($body)) {
        sendError('Invalid JSON body.', 400);
    }

    foreach ($requiredFields as $field) {
        if (!isset($body[$field]) || (is_string($body[$field]) && trim($body[$field]) === '')) {
            sendError("Field '{$field}' is required.", 422);
        }
    }

    return $body;
}
