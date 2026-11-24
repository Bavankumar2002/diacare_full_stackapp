<?php
// =============================================================================
// DiaCare Backend - Get User Notifications
// =============================================================================

require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../utils/response.php';
require_once __DIR__ . '/../../utils/jwt.php';

$userId = null;
$token = getBearerToken();
if ($token) {
    $payload = JWT::decode($token);
    if ($payload && isset($payload['user_id'])) {
        $userId = (int)$payload['user_id'];
    }
}

try {
    $pdo = Database::getConnection();

    if ($userId) {
        // Check if user has notifications
        $countStmt = $pdo->prepare("SELECT COUNT(*) FROM notifications WHERE user_id = :user_id");
        $countStmt->execute([':user_id' => $userId]);
        $hasNotifications = $countStmt->fetchColumn() > 0;

        // If newly created user with no notifications, seed realistic initial notifications
        if (!$hasNotifications) {
            $initials = [
                [
                    'title'   => 'Welcome to DiaCare!',
                    'message' => 'Track your blood glucose readings, monitor meal calories & carbs, and stay consistent with daily health habits.',
                    'type'    => 'welcome',
                    'is_read' => 0,
                    'created' => date('Y-m-d H:i:s', strtotime('-1 hour')),
                ],
                [
                    'title'   => 'Fasting Sugar Check Reminder',
                    'message' => 'Consistent morning blood glucose logs help predict trends and maintain optimal A1C control.',
                    'type'    => 'sugar',
                    'is_read' => 0,
                    'created' => date('Y-m-d H:i:s', strtotime('-3 hours')),
                ],
                [
                    'title'   => 'Personalized Meal Suggestions Ready',
                    'message' => 'Check your home dashboard for diabetic-friendly morning, lunch, and dinner food options.',
                    'type'    => 'meal',
                    'is_read' => 1,
                    'created' => date('Y-m-d H:i:s', strtotime('-1 day')),
                ]
            ];

            $insStmt = $pdo->prepare("INSERT INTO notifications (user_id, title, message, type, is_read, created_at) VALUES (:user_id, :title, :message, :type, :is_read, :created_at)");
            foreach ($initials as $n) {
                $insStmt->execute([
                    ':user_id'    => $userId,
                    ':title'      => $n['title'],
                    ':message'    => $n['message'],
                    ':type'       => $n['type'],
                    ':is_read'    => $n['is_read'],
                    ':created_at' => $n['created'],
                ]);
            }
        }

        $stmt = $pdo->prepare("SELECT id, title, message, type, is_read, created_at FROM notifications WHERE user_id = :user_id ORDER BY created_at DESC LIMIT 50");
        $stmt->execute([':user_id' => $userId]);
        $notifications = $stmt->fetchAll();

    } else {
        // Fallback demo/guest notifications if token missing
        $notifications = [
            [
                'id'         => 1,
                'title'      => 'Welcome to DiaCare!',
                'message'    => 'Track your blood glucose readings, monitor meal calories & carbs, and stay consistent with daily health habits.',
                'type'       => 'welcome',
                'is_read'    => 0,
                'created_at' => date('Y-m-d H:i:s', strtotime('-1 hour')),
            ],
            [
                'id'         => 2,
                'title'      => 'Daily Health Tip Available',
                'message'    => 'A brisk 15-minute walk after lunch or dinner helps muscles absorb glucose and prevents sudden spikes.',
                'type'       => 'tip',
                'is_read'    => 0,
                'created_at' => date('Y-m-d H:i:s', strtotime('-3 hours')),
            ],
        ];
    }

    $unreadCount = 0;
    foreach ($notifications as $n) {
        if (empty($n['is_read'])) $unreadCount++;
    }

    sendSuccess('Notifications retrieved successfully.', [
        'notifications' => $notifications,
        'unread_count'  => $unreadCount,
    ]);

} catch (Exception $e) {
    sendError('Failed to fetch notifications: ' . $e->getMessage(), 500);
}
