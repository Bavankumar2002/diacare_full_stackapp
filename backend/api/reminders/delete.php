<?php
// =============================================================================
// DiaCare Backend - Delete Reminder
// =============================================================================

require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../utils/response.php';
require_once __DIR__ . '/../../utils/jwt.php';

$auth = requireAuth();
$userId = $auth['user_id'];

if ($_SERVER['REQUEST_METHOD'] !== 'POST' && $_SERVER['REQUEST_METHOD'] !== 'DELETE') {
    sendError('Method not allowed. Use POST or DELETE.', 405);
}

$data = getRequestBody();
$id = (int)($data['id'] ?? $_GET['id'] ?? 0);

if ($id <= 0) {
    sendError('Valid reminder ID is required.');
}

try {
    $pdo = Database::getConnection();

    $stmt = $pdo->prepare("DELETE FROM reminders WHERE id = :id AND user_id = :user_id");
    $stmt->execute([':id' => $id, ':user_id' => $userId]);

    if ($stmt->rowCount() > 0) {
        sendSuccess('Reminder deleted successfully.');
    } else {
        sendError('Reminder not found or already deleted.', 404);
    }

} catch (Exception $e) {
    sendError('Failed to delete reminder: ' . $e->getMessage(), 500);
}
