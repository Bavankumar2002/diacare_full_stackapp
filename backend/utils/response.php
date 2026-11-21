<?php
// =============================================================================
// DiaCare Backend - Standardized JSON Response & CORS Handler
// =============================================================================

// Always enable CORS for mobile app and web access
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept');
header('Access-Control-Max-Age: 86400'); // 24 hours cache

// Pre-flight OPTIONS request responder
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

/**
 * Send standard JSON response and terminate script
 */
function sendResponse(int $statusCode, string $status, string $message, $data = null): void {
    http_response_code($statusCode);
    header('Content-Type: application/json; charset=UTF-8');
    echo json_encode([
        'status'  => $status,
        'message' => $message,
        'data'    => $data
    ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    exit;
}

function sendSuccess(string $message, $data = null, int $statusCode = 200): void {
    sendResponse($statusCode, 'success', $message, $data);
}

function sendError(string $message, int $statusCode = 400, $data = null): void {
    sendResponse($statusCode, 'error', $message, $data);
}

/**
 * Retrieve JSON payload or regular POST data
 */
function getRequestBody(): array {
    $rawInput = file_get_contents('php://input');
    if (!empty($rawInput)) {
        $decoded = json_decode($rawInput, true);
        if (json_last_error() === JSON_ERROR_NONE && is_array($decoded)) {
            return $decoded;
        }
    }
    return !empty($_POST) ? $_POST : [];
}
