<?php
// =============================================================================
// DiaCare Backend - User Login
// =============================================================================

require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../utils/response.php';
require_once __DIR__ . '/../../utils/jwt.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendError('Method not allowed. Use POST.', 405);
}

$data = getRequestBody();

// Accept identifier as "email", "phone", or "identifier"
$identifier = trim($data['identifier'] ?? $data['email'] ?? $data['phone'] ?? '');
$password   = $data['password'] ?? '';

if (empty($identifier) || empty($password)) {
    sendError('Please provide your email/phone and password.');
}

try {
    $pdo = Database::getConnection();

    // Query user by email or phone
    $stmt = $pdo->prepare("
        SELECT id, name, email, phone, password_hash 
        FROM users 
        WHERE email = :email_id OR phone = :phone_id 
        LIMIT 1
    ");
    $stmt->execute([':email_id' => $identifier, ':phone_id' => $identifier]);
    $user = $stmt->fetch();

    if (!$user || !password_verify($password, $user['password_hash'])) {
        sendError('Invalid email/phone or password. Please try again.', 401);
    }

    // Check if profile exists
    $stmt = $pdo->prepare("SELECT * FROM profiles WHERE user_id = :user_id LIMIT 1");
    $stmt->execute([':user_id' => $user['id']]);
    $profile = $stmt->fetch();

    $tokenPayload = [
        'user_id' => (int)$user['id'],
        'email'   => $user['email'],
        'name'    => $user['name']
    ];
    $token = JWT::encode($tokenPayload);

    sendSuccess('Login successful. Welcome back!', [
        'token'       => $token,
        'user'        => [
            'id'    => (int)$user['id'],
            'name'  => $user['name'],
            'email' => $user['email'],
            'phone' => $user['phone']
        ],
        'has_profile' => ($profile !== false),
        'profile'     => $profile ? $profile : null
    ]);

} catch (Exception $e) {
    sendError('Login error: ' . $e->getMessage(), 500);
}
