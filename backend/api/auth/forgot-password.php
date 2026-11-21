<?php
// =============================================================================
// DiaCare Backend - Password Reset Handling
// =============================================================================

require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../utils/response.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendError('Method not allowed. Use POST.', 405);
}

$data = getRequestBody();
$action = $data['action'] ?? 'request'; // 'request' or 'verify_and_reset'

$pdo = Database::getConnection();

if ($action === 'request') {
    $identifier = trim($data['identifier'] ?? $data['email'] ?? $data['phone'] ?? '');
    if (empty($identifier)) {
        sendError('Please provide your registered email or phone number.');
    }

    $stmt = $pdo->prepare("SELECT id, name, email FROM users WHERE email = :email_id OR phone = :phone_id LIMIT 1");
    $stmt->execute([':email_id' => $identifier, ':phone_id' => $identifier]);
    $user = $stmt->fetch();

    if (!$user) {
        // Return friendly message even if user not found for security, or explicit for usability
        sendError('No account found with this email or phone number.', 404);
    }

    // Generate 6-digit OTP code
    $otpCode = (string)random_int(100000, 999999);
    $expiry = date('Y-m-d H:i:s', time() + 900); // 15 mins expiry

    $update = $pdo->prepare("UPDATE users SET reset_token = :token, reset_token_expiry = :expiry WHERE id = :id");
    $update->execute([
        ':token'  => $otpCode,
        ':expiry' => $expiry,
        ':id'     => $user['id']
    ]);

    sendSuccess('Password reset verification code generated.', [
        'email'      => $user['email'],
        'reset_code' => $otpCode // Returned directly for testing & direct UX
    ]);

} elseif ($action === 'verify_and_reset') {
    $identifier  = trim($data['identifier'] ?? $data['email'] ?? '');
    $code        = trim($data['code'] ?? '');
    $newPassword = $data['new_password'] ?? '';

    if (empty($identifier) || empty($code) || empty($newPassword)) {
        sendError('Email/phone, reset code, and new password are required.');
    }

    if (strlen($newPassword) < 6) {
        sendError('New password must be at least 6 characters long.');
    }

    $stmt = $pdo->prepare("
        SELECT id, reset_token, reset_token_expiry 
        FROM users 
        WHERE (email = :email_id OR phone = :phone_id) AND reset_token = :code
        LIMIT 1
    ");
    $stmt->execute([':email_id' => $identifier, ':phone_id' => $identifier, ':code' => $code]);
    $user = $stmt->fetch();

    if (!$user) {
        sendError('Invalid reset code or identifier.');
    }

    if (strtotime($user['reset_token_expiry']) < time()) {
        sendError('Reset code has expired. Please request a new one.');
    }

    $newHash = password_hash($newPassword, PASSWORD_BCRYPT);
    $update = $pdo->prepare("UPDATE users SET password_hash = :hash, reset_token = NULL, reset_token_expiry = NULL WHERE id = :id");
    $update->execute([':hash' => $newHash, ':id' => $user['id']]);

    sendSuccess('Password reset successfully. You can now login with your new password.');
} else {
    sendError('Invalid action specified.');
}
