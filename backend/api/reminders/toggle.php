<?php
// =============================================================================
// DiaCare Backend - Toggle Reminder Active/Inactive
// =============================================================================

require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../utils/response.php';
require_once __DIR__ . '/../../utils/jwt.php';

$auth = requireAuth();
$userId = $auth['user_id'];

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendError('Method not allowed. Use POST.', 405);
}

$data = getRequestBody();
$id = (int)($data['id'] ?? 0);

if ($id <= 0) {
    sendError('Valid reminder ID is required.');
}

try {
    $pdo = Database::getConnection();

    // Check current state
    $stmt = $pdo->prepare("SELECT is_enabled FROM reminders WHERE id = :id AND user_id = :user_id LIMIT 1");
    $stmt->execute([':id' => $id, ':user_id' => $userId]);
    $curr = $stmt->fetch();

    if (!$curr) {
        sendError('Reminder not found.', 404);
    }

    $newState = $curr['is_enabled'] ? 0 : 1;

    $update = $pdo->prepare("UPDATE reminders SET is_enabled = :state WHERE id = :id AND user_id = :user_id");
    $update->execute([':state' => $newState, ':id' => $id, ':user_id' => $userId]);

    sendSuccess('Reminder status updated.', [
        'id'         => $id,
        'is_enabled' => $newState
    ]);

} catch (Exception $e) {
    sendError('Failed to toggle reminder: ' . $e->getMessage(), 500);
}
