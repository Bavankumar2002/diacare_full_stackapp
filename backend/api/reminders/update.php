<?php
// =============================================================================
// DiaCare Backend - Update Patient Reminder
// =============================================================================

require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../utils/response.php';
require_once __DIR__ . '/../../utils/jwt.php';

$auth = requireAuth();
$userId = $auth['user_id'];

if ($_SERVER['REQUEST_METHOD'] !== 'POST' && $_SERVER['REQUEST_METHOD'] !== 'PUT') {
    sendError('Method not allowed. Use POST or PUT.', 405);
}

$data = getRequestBody();
$id = (int)($data['id'] ?? 0);

if ($id <= 0) {
    sendError('Valid reminder ID is required.');
}

$title      = trim($data['title'] ?? '');
$type       = trim($data['type'] ?? 'medicine');
$dosage     = trim($data['dosage'] ?? '');
$time       = trim($data['time'] ?? '08:00:00');
$repeatType = trim($data['repeat_type'] ?? 'daily');
$repeatDays = trim($data['repeat_days'] ?? '1,2,3,4,5,6,7');
$isEnabled  = isset($data['is_enabled']) ? (int)$data['is_enabled'] : 1;

if (empty($title)) {
    sendError('Reminder title cannot be empty.');
}

if (strlen($time) === 5) {
    $time .= ':00';
}

try {
    $pdo = Database::getConnection();

    $stmt = $pdo->prepare("
        UPDATE reminders SET
            title       = :title,
            type        = :type,
            dosage      = :dosage,
            time        = :time,
            repeat_type = :repeat_type,
            repeat_days = :repeat_days,
            is_enabled  = :is_enabled,
            updated_at  = CURRENT_TIMESTAMP
        WHERE id = :id AND user_id = :user_id
    ");
    $stmt->execute([
        ':title'       => $title,
        ':type'        => $type,
        ':dosage'      => $dosage,
        ':time'        => $time,
        ':repeat_type' => $repeatType,
        ':repeat_days' => $repeatDays,
        ':is_enabled'  => $isEnabled,
        ':id'          => $id,
        ':user_id'     => $userId
    ]);

    sendSuccess('Reminder updated successfully.');

} catch (Exception $e) {
    sendError('Failed to update reminder: ' . $e->getMessage(), 500);
}
