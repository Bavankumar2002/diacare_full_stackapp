<?php
// =============================================================================
// DiaCare Backend - Delete Sugar Reading
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
$readingId = (int)($data['id'] ?? $_GET['id'] ?? 0);

if ($readingId <= 0) {
    sendError('Valid reading ID is required.');
}

try {
    $pdo = Database::getConnection();

    $stmt = $pdo->prepare("DELETE FROM sugar_readings WHERE id = :id AND user_id = :user_id");
    $stmt->execute([':id' => $readingId, ':user_id' => $userId]);

    if ($stmt->rowCount() > 0) {
        sendSuccess('Sugar reading deleted successfully.');
    } else {
        sendError('Reading not found or already deleted.', 404);
    }

} catch (Exception $e) {
    sendError('Failed to delete reading: ' . $e->getMessage(), 500);
}
