<?php
// =============================================================================
// DiaCare Backend - Retrieve Patient Reminders
// =============================================================================

require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../utils/response.php';
require_once __DIR__ . '/../../utils/jwt.php';

$auth = requireAuth();
$userId = $auth['user_id'];

$type = trim($_GET['type'] ?? ''); // optional filter by 'medicine', 'sugar_check', etc.

try {
    $pdo = Database::getConnection();

    $sql = "
        SELECT id, user_id, title, type, dosage, time, repeat_type, repeat_days, is_enabled, created_at, updated_at
        FROM reminders
        WHERE user_id = :user_id
    ";
    $params = [':user_id' => $userId];

    if (!empty($type)) {
        $sql .= " AND type = :type";
        $params[':type'] = $type;
    }

    $sql .= " ORDER BY time ASC";

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $reminders = $stmt->fetchAll();

    // Find the next upcoming reminder for today
    $currentTime = date('H:i:s');
    $nextReminder = null;

    // First check reminders later than current time today
    foreach ($reminders as $r) {
        if ($r['is_enabled'] && $r['time'] >= $currentTime) {
            $nextReminder = $r;
            break;
        }
    }

    // If none left today, take the earliest enabled tomorrow
    if (!$nextReminder && !empty($reminders)) {
        foreach ($reminders as $r) {
            if ($r['is_enabled']) {
                $nextReminder = $r;
                break;
            }
        }
    }

    sendSuccess('Reminders retrieved successfully.', [
        'count'         => count($reminders),
        'next_reminder' => $nextReminder,
        'reminders'     => $reminders
    ]);

} catch (Exception $e) {
    sendError('Failed to fetch reminders: ' . $e->getMessage(), 500);
}
