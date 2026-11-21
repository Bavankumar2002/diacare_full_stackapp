<?php
// =============================================================================
// DiaCare Backend - Change Password
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
$currentPassword = $data['current_password'] ?? '';
$newPassword     = $data['new_password'] ?? '';

if (empty($currentPassword) || empty($newPassword)) {
    sendError('Both current password and new password are required.');
}

if (strlen($newPassword) < 6) {
    sendError('New password must be at least 6 characters long.');
}

try {
    $pdo = Database::getConnection();

    $stmt = $pdo->prepare("SELECT password_hash FROM users WHERE id = :id LIMIT 1");
    $stmt->execute([':id' => $userId]);
    $user = $stmt->fetch();

    if (!$user || !password_verify($currentPassword, $user['password_hash'])) {
        sendError('Incorrect current password.');
    }

    $newHash = password_hash($newPassword, PASSWORD_BCRYPT);
    $update = $pdo->prepare("UPDATE users SET password_hash = :hash WHERE id = :id");
    $update->execute([':hash' => $newHash, ':id' => $userId]);

    sendSuccess('Password updated successfully.');

} catch (Exception $e) {
    sendError('Failed to change password: ' . $e->getMessage(), 500);
}
