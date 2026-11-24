<?php
// =============================================================================
// DiaCare Backend - Mark Notifications Read
// =============================================================================

require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../utils/response.php';
require_once __DIR__ . '/../../utils/jwt.php';

$userId = null;
$token = getBearerToken();
if ($token) {
    $payload = JWT::decode($token);
    if ($payload && isset($payload['user_id'])) {
        $userId = (int)$payload['user_id'];
    }
}

try {
    $pdo = Database::getConnection();
    $body = getRequestBody();
    $id = isset($body['id']) ? (int)$body['id'] : null;

    if ($userId) {
        if ($id) {
            $stmt = $pdo->prepare("UPDATE notifications SET is_read = 1 WHERE id = :id AND user_id = :user_id");
            $stmt->execute([':id' => $id, ':user_id' => $userId]);
        } else {
            // Mark all read
            $stmt = $pdo->prepare("UPDATE notifications SET is_read = 1 WHERE user_id = :user_id");
            $stmt->execute([':user_id' => $userId]);
        }
    }

    sendSuccess('Notifications updated successfully.');
} catch (Exception $e) {
    sendError('Failed to update notifications: ' . $e->getMessage(), 500);
}
