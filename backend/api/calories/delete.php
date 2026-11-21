<?php
// =============================================================================
// DiaCare Backend - Delete Meal Entry
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
$mealId = (int)($data['id'] ?? $_GET['id'] ?? 0);

if ($mealId <= 0) {
    sendError('Valid meal ID is required.');
}

try {
    $pdo = Database::getConnection();

    $stmt = $pdo->prepare("DELETE FROM meals WHERE id = :id AND user_id = :user_id");
    $stmt->execute([':id' => $mealId, ':user_id' => $userId]);

    if ($stmt->rowCount() > 0) {
        sendSuccess('Meal deleted successfully.');
    } else {
        sendError('Meal not found or already deleted.', 404);
    }

} catch (Exception $e) {
    sendError('Failed to delete meal: ' . $e->getMessage(), 500);
}
