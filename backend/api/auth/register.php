<?php
// =============================================================================
// DiaCare Backend - User Registration
// =============================================================================

require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../utils/response.php';
require_once __DIR__ . '/../../utils/jwt.php';
require_once __DIR__ . '/../../utils/validation.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendError('Method not allowed. Use POST.', 405);
}

$data = getRequestBody();

$name     = trim($data['name'] ?? '');
$email    = strtolower(trim($data['email'] ?? ''));
$phone    = trim($data['phone'] ?? '');
$password = $data['password'] ?? '';
$confirm  = $data['confirm_password'] ?? '';

// Validation
if (empty($name) || empty($email) || empty($phone) || empty($password)) {
    sendError('All fields (name, email, phone, password) are required.');
}

if (!Validator::isValidEmail($email)) {
    sendError('Please enter a valid email address.');
}

if (!Validator::isValidPhone($phone)) {
    sendError('Please enter a valid phone number (at least 7 digits).');
}

if (strlen($password) < 6) {
    sendError('Password must be at least 6 characters long.');
}

if (!empty($confirm) && $password !== $confirm) {
    sendError('Passwords do not match.');
}

try {
    $pdo = Database::getConnection();

    // Check if email or phone already exists
    $stmt = $pdo->prepare("SELECT id, email, phone FROM users WHERE email = :email OR phone = :phone LIMIT 1");
    $stmt->execute([':email' => $email, ':phone' => $phone]);
    $existing = $stmt->fetch();

    if ($existing) {
        if ($existing['email'] === $email) {
            sendError('An account with this email address already exists.', 409);
        } else {
            sendError('An account with this phone number already exists.', 409);
        }
    }

    $passwordHash = password_hash($password, PASSWORD_BCRYPT);

    $stmt = $pdo->prepare("
        INSERT INTO users (name, email, phone, password_hash) 
        VALUES (:name, :email, :phone, :password_hash)
    ");
    $stmt->execute([
        ':name'          => $name,
        ':email'         => $email,
        ':phone'         => $phone,
        ':password_hash' => $passwordHash
    ]);

    $userId = (int)$pdo->lastInsertId();

    $tokenPayload = [
        'user_id' => $userId,
        'email'   => $email,
        'name'    => $name
    ];
    $token = JWT::encode($tokenPayload);

    sendSuccess('Registration successful. Welcome to DiaCare!', [
        'token'       => $token,
        'user'        => [
            'id'    => $userId,
            'name'  => $name,
            'email' => $email,
            'phone' => $phone
        ],
        'has_profile' => false
    ], 201);

} catch (Exception $e) {
    sendError('Registration failed: ' . $e->getMessage(), 500);
}
