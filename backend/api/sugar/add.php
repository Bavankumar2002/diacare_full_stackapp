<?php
// =============================================================================
// DiaCare Backend - Add Blood Sugar Reading
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

$value = isset($data['reading_value']) ? (float)$data['reading_value'] : 0.0;
$type  = trim($data['reading_type'] ?? 'fasting');
$notes = trim($data['notes'] ?? '');

// Format measured_at date/time
$measuredDate = trim($data['date'] ?? date('Y-m-d'));
$measuredTime = trim($data['time'] ?? date('H:i:s'));
$measuredAt   = "{$measuredDate} {$measuredTime}";

if ($value <= 20 || $value > 700) {
    sendError('Please enter a valid blood sugar reading between 20 and 700 mg/dL.');
}

$allowedTypes = ['fasting', 'before_meal', 'after_meal', 'bedtime', 'random'];
if (!in_array($type, $allowedTypes)) {
    $type = 'fasting';
}

$status = Validator::determineSugarStatus($value);

try {
    $pdo = Database::getConnection();

    $stmt = $pdo->prepare("
        INSERT INTO sugar_readings (user_id, reading_value, reading_type, reading_status, measured_at, notes)
        VALUES (:user_id, :value, :type, :status, :measured_at, :notes)
    ");
    $stmt->execute([
        ':user_id'     => $userId,
        ':value'       => $value,
        ':type'        => $type,
        ':status'      => $status,
        ':measured_at' => $measuredAt,
        ':notes'       => $notes
    ]);

    $readingId = (int)$pdo->lastInsertId();

    // Check if dangerous level (<70 mg/dL hypoglycemia or >250 mg/dL severe hyperglycemia)
    $isDanger = false;
    $dangerSeverity = 'info'; // 'low' or 'critical_high'
    $advice = '';

    if ($value < 70) {
        $isDanger = true;
        $dangerSeverity = 'low';
        $advice = 'Hypoglycemia detected! Follow the 15-15 rule: consume 15 grams of fast-acting carbs (half glass fruit juice, 3-4 glucose candies, or 1 tablespoon honey). Recheck sugar in 15 minutes.';
    } elseif ($value >= 250) {
        $isDanger = true;
        $dangerSeverity = 'critical_high';
        $advice = 'Severe hyperglycemia! Drink plenty of water immediately to stay hydrated. Check for ketones if instructed by your doctor, take prescribed insulin/medication, and consult your doctor.';
    }

    // Retrieve emergency contact if available
    $profStmt = $pdo->prepare("SELECT emergency_contact_name, emergency_contact_phone FROM profiles WHERE user_id = :user_id LIMIT 1");
    $profStmt->execute([':user_id' => $userId]);
    $prof = $profStmt->fetch();

    sendSuccess('Sugar reading saved successfully.', [
        'reading' => [
            'id'             => $readingId,
            'reading_value'  => $value,
            'reading_type'   => $type,
            'reading_status' => $status,
            'measured_at'    => $measuredAt,
            'notes'          => $notes
        ],
        'alert' => [
            'is_danger'       => $isDanger,
            'severity'        => $dangerSeverity,
            'advice'          => $advice,
            'emergency_name'  => $prof['emergency_contact_name'] ?? '',
            'emergency_phone' => $prof['emergency_contact_phone'] ?? ''
        ]
    ], 201);

} catch (Exception $e) {
    sendError('Failed to record sugar reading: ' . $e->getMessage(), 500);
}
