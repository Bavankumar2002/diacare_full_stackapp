<?php
// =============================================================================
// DiaCare Backend - Delete Account & Purge User Data
// =============================================================================

require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../utils/response.php';
require_once __DIR__ . '/../../utils/jwt.php';

$auth = requireAuth();
$userId = $auth['user_id'];

if ($_SERVER['REQUEST_METHOD'] !== 'POST' && $_SERVER['REQUEST_METHOD'] !== 'DELETE') {
    sendError('Method not allowed. Use POST or DELETE.', 405);
}

try {
    $pdo = Database::getConnection();

    // With ON DELETE CASCADE, deleting from users will clean up profiles, sugar_readings, meals, reminders
    $stmt = $pdo->prepare("DELETE FROM users WHERE id = :id");
    $stmt->execute([':id' => $userId]);

    sendSuccess('Your DiaCare account and all associated health data have been permanently deleted.');

} catch (Exception $e) {
    sendError('Failed to delete account: ' . $e->getMessage(), 500);
}
