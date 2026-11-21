<?php
// =============================================================================
// DiaCare Backend - Create or Update Patient Profile
// =============================================================================

require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../utils/response.php';
require_once __DIR__ . '/../../utils/jwt.php';
require_once __DIR__ . '/../../utils/validation.php';

$auth = requireAuth();
$userId = $auth['user_id'];

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendError('Method not allowed. Use POST.', 405);
}

$data = getRequestBody();

$fullName       = trim($data['full_name'] ?? '');
$age            = isset($data['age']) ? (int)$data['age'] : 0;
$dob            = !empty($data['dob']) ? trim($data['dob']) : null;
$gender         = trim($data['gender'] ?? 'Male');
$heightCm       = isset($data['height_cm']) ? (float)$data['height_cm'] : 0.0;
$weightKg       = isset($data['weight_kg']) ? (float)$data['weight_kg'] : 0.0;
$diabetesType   = trim($data['diabetes_type'] ?? 'Type 2');
$yearDiagnosed  = !empty($data['year_diagnosed']) ? (int)$data['year_diagnosed'] : null;
$medicines      = trim($data['current_medicines'] ?? '');
$allergies      = trim($data['allergies'] ?? '');
$emergencyName  = trim($data['emergency_contact_name'] ?? '');
$emergencyPhone = trim($data['emergency_contact_phone'] ?? '');
$doctorName     = trim($data['doctor_name'] ?? '');
$doctorHospital = trim($data['doctor_hospital'] ?? '');
$dailyCalories  = isset($data['daily_calorie_goal']) ? (int)$data['daily_calorie_goal'] : 1800;
$photo          = trim($data['profile_photo'] ?? '');

// Basic validations
if (empty($fullName)) {
    sendError('Full name is required.');
}
if ($age <= 0 || $age > 130) {
    sendError('Please enter a valid age.');
}
if ($heightCm <= 0 || $weightKg <= 0) {
    sendError('Please provide valid height (cm) and weight (kg).');
}

// Calculate BMI
$bmi = Validator::calculateBMI($heightCm, $weightKg);

// Ensure valid enum choices
$allowedGenders = ['Male', 'Female', 'Other'];
if (!in_array($gender, $allowedGenders)) {
    $gender = 'Male';
}

$allowedTypes = ['Type 1', 'Type 2', 'Gestational', 'Pre-diabetes'];
if (!in_array($diabetesType, $allowedTypes)) {
    $diabetesType = 'Type 2';
}

try {
    $pdo = Database::getConnection();

    // Check if profile exists
    $checkStmt = $pdo->prepare("SELECT id FROM profiles WHERE user_id = :user_id LIMIT 1");
    $checkStmt->execute([':user_id' => $userId]);
    $existing = $checkStmt->fetch();

    if ($existing) {
        $stmt = $pdo->prepare("
            UPDATE profiles SET
                full_name               = :full_name,
                age                     = :age,
                dob                     = :dob,
                gender                  = :gender,
                height_cm               = :height_cm,
                weight_kg               = :weight_kg,
                bmi                     = :bmi,
                diabetes_type           = :diabetes_type,
                year_diagnosed          = :year_diagnosed,
                current_medicines       = :current_medicines,
                allergies               = :allergies,
                emergency_contact_name  = :emergency_contact_name,
                emergency_contact_phone = :emergency_contact_phone,
                doctor_name             = :doctor_name,
                doctor_hospital         = :doctor_hospital,
                daily_calorie_goal      = :daily_calorie_goal,
                profile_photo           = :profile_photo,
                is_completed            = 1,
                updated_at              = CURRENT_TIMESTAMP
            WHERE user_id = :user_id
        ");
    } else {
        $stmt = $pdo->prepare("
            INSERT INTO profiles (
                user_id, full_name, age, dob, gender, height_cm, weight_kg, bmi,
                diabetes_type, year_diagnosed, current_medicines, allergies,
                emergency_contact_name, emergency_contact_phone, doctor_name, doctor_hospital,
                daily_calorie_goal, profile_photo, is_completed
            ) VALUES (
                :user_id, :full_name, :age, :dob, :gender, :height_cm, :weight_kg, :bmi,
                :diabetes_type, :year_diagnosed, :current_medicines, :allergies,
                :emergency_contact_name, :emergency_contact_phone, :doctor_name, :doctor_hospital,
                :daily_calorie_goal, :profile_photo, 1
            )
        ");
    }

    $params = [
        ':user_id'                 => $userId,
        ':full_name'               => $fullName,
        ':age'                     => $age,
        ':dob'                     => $dob,
        ':gender'                  => $gender,
        ':height_cm'               => $heightCm,
        ':weight_kg'               => $weightKg,
        ':bmi'                     => $bmi,
        ':diabetes_type'           => $diabetesType,
        ':year_diagnosed'          => $yearDiagnosed,
        ':current_medicines'       => $medicines,
        ':allergies'               => $allergies,
        ':emergency_contact_name'  => $emergencyName,
        ':emergency_contact_phone' => $emergencyPhone,
        ':doctor_name'             => $doctorName,
        ':doctor_hospital'         => $doctorHospital,
        ':daily_calorie_goal'      => $dailyCalories,
        ':profile_photo'           => $photo
    ];

    $stmt->execute($params);

    // Return updated profile
    $getStmt = $pdo->prepare("SELECT * FROM profiles WHERE user_id = :user_id LIMIT 1");
    $getStmt->execute([':user_id' => $userId]);
    $updatedProfile = $getStmt->fetch();

    sendSuccess('Profile saved successfully.', [
        'profile' => $updatedProfile
    ]);

} catch (Exception $e) {
    sendError('Failed to save profile: ' . $e->getMessage(), 500);
}
