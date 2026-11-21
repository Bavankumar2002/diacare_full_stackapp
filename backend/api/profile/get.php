<?php
// =============================================================================
// DiaCare Backend - Get Patient Profile
// =============================================================================

require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../utils/response.php';
require_once __DIR__ . '/../../utils/jwt.php';

$auth = requireAuth();
$userId = $auth['user_id'];

try {
    $pdo = Database::getConnection();

    $stmt = $pdo->prepare("
        SELECT 
            u.id as user_id, u.name as account_name, u.email, u.phone,
            p.id as profile_id, p.full_name, p.age, p.dob, p.gender,
            p.height_cm, p.weight_kg, p.bmi, p.diabetes_type, p.year_diagnosed,
            p.current_medicines, p.allergies, p.emergency_contact_name,
            p.emergency_contact_phone, p.doctor_name, p.doctor_hospital,
            p.daily_calorie_goal, p.profile_photo, p.is_completed,
            p.created_at, p.updated_at
        FROM users u
        LEFT JOIN profiles p ON u.id = p.user_id
        WHERE u.id = :id
        LIMIT 1
    ");
    $stmt->execute([':id' => $userId]);
    $result = $stmt->fetch();

    if (!$result) {
        sendError('User not found.', 404);
    }

    $hasProfile = !empty($result['profile_id']);

    sendSuccess('Profile retrieved successfully.', [
        'has_profile' => $hasProfile,
        'profile'     => $hasProfile ? $result : null,
        'user'        => [
            'id'    => $result['user_id'],
            'name'  => $result['account_name'],
            'email' => $result['email'],
            'phone' => $result['phone']
        ]
    ]);

} catch (Exception $e) {
    sendError('Failed to fetch profile: ' . $e->getMessage(), 500);
}
