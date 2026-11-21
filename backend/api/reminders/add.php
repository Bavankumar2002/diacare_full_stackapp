<?php
// =============================================================================
// DiaCare Backend - Create Patient Reminder
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

$title      = trim($data['title'] ?? '');
$type       = trim($data['type'] ?? 'medicine');
$dosage     = trim($data['dosage'] ?? '');
$time       = trim($data['time'] ?? '08:00:00');
$repeatType = trim($data['repeat_type'] ?? 'daily');
$repeatDays = trim($data['repeat_days'] ?? '1,2,3,4,5,6,7');
$isEnabled  = isset($data['is_enabled']) ? (int)$data['is_enabled'] : 1;

if (empty($title)) {
    sendError('Reminder title is required (e.g. Metformin 500mg or Morning Sugar Check).');
}

$allowedTypes = ['medicine', 'sugar_check', 'water', 'meal', 'exercise', 'doctor'];
if (!in_array($type, $allowedTypes)) {
    $type = 'medicine';
}

$allowedRepeats = ['daily', 'weekdays', 'weekends', 'custom', 'once'];
if (!in_array($repeatType, $allowedRepeats)) {
    $repeatType = 'daily';
}

// Normalize time to HH:MM:SS
if (strlen($time) === 5) {
    $time .= ':00';
}

try {
    $pdo = Database::getConnection();

    $stmt = $pdo->prepare("
        INSERT INTO reminders (user_id, title, type, dosage, time, repeat_type, repeat_days, is_enabled)
        VALUES (:user_id, :title, :type, :dosage, :time, :repeat_type, :repeat_days, :is_enabled)
    ");
    $stmt->execute([
        ':user_id'     => $userId,
        ':title'       => $title,
        ':type'        => $type,
        ':dosage'      => $dosage,
        ':time'        => $time,
        ':repeat_type' => $repeatType,
        ':repeat_days' => $repeatDays,
        ':is_enabled'  => $isEnabled
    ]);

    $id = (int)$pdo->lastInsertId();

    sendSuccess('Reminder created successfully.', [
        'reminder' => [
            'id'          => $id,
            'title'       => $title,
            'type'        => $type,
            'dosage'      => $dosage,
            'time'        => $time,
            'repeat_type' => $repeatType,
            'repeat_days' => $repeatDays,
            'is_enabled'  => $isEnabled
        ]
    ], 201);

} catch (Exception $e) {
    sendError('Failed to create reminder: ' . $e->getMessage(), 500);
}
