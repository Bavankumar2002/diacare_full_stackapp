<?php
// =============================================================================
// DiaCare Backend - Verify Mobile OTP & Auto Login/Register
// =============================================================================

require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../utils/response.php';
require_once __DIR__ . '/../../utils/jwt.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendError('Method not allowed. Use POST.', 405);
}

$data = getRequestBody();
$rawPhone = trim($data['phone'] ?? '');
$otp      = trim($data['otp'] ?? '');

$phone = preg_replace('/[^\d]/', '', $rawPhone);
if (strlen($phone) > 10 && substr($phone, 0, 2) === '91') {
    $phone = substr($phone, 2);
}

if (strlen($phone) !== 10) {
    sendError('Please enter a valid 10-digit mobile number.');
}

if (empty($otp)) {
    sendError('Please enter the 4-digit OTP.');
}

// User explicitly requested static OTP 1234
if ($otp !== '1234') {
    sendError('Invalid OTP. Please enter 1234.', 401);
}

try {
    $pdo = Database::getConnection();

    // Check if user with this phone exists
    $stmt = $pdo->prepare("SELECT id, name, email, phone FROM users WHERE phone = :phone LIMIT 1");
    $stmt->execute([':phone' => $phone]);
    $user = $stmt->fetch();

    if (!$user) {
        // Create new patient account automatically
        $email = $phone . '@diacare.app';
        $defaultName = 'Patient ' . substr($phone, -4);
        $passwordHash = password_hash('otp_' . $phone, PASSWORD_BCRYPT);

        $insertStmt = $pdo->prepare("
            INSERT INTO users (name, email, phone, password_hash)
            VALUES (:name, :email, :phone, :password_hash)
        ");
        $insertStmt->execute([
            ':name'          => $defaultName,
            ':email'         => $email,
            ':phone'         => $phone,
            ':password_hash' => $passwordHash
        ]);

        $userId = (int)$pdo->lastInsertId();
        $user = [
            'id'    => $userId,
            'name'  => $defaultName,
            'email' => $email,
            'phone' => $phone
        ];
    }

    // Check if profile details already exist for this user
    $profStmt = $pdo->prepare("SELECT * FROM profiles WHERE user_id = :user_id LIMIT 1");
    $profStmt->execute([':user_id' => $user['id']]);
    $profile = $profStmt->fetch();

    $hasProfile = ($profile !== false && !empty($profile['full_name']));

    // Generate JWT Auth Token
    $tokenPayload = [
        'user_id' => (int)$user['id'],
        'email'   => $user['email'],
        'name'    => $user['name']
    ];
    $token = JWT::encode($tokenPayload);

    sendSuccess('OTP verified successfully. Welcome to DiaCare!', [
        'token'       => $token,
        'user'        => [
            'id'    => (int)$user['id'],
            'name'  => $user['name'],
            'email' => $user['email'],
            'phone' => $user['phone']
        ],
        'has_profile' => $hasProfile,
        'profile'     => $hasProfile ? $profile : null
    ]);

} catch (Exception $e) {
    sendError('OTP verification failed: ' . $e->getMessage(), 500);
}
