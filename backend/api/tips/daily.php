<?php
// =============================================================================
// DiaCare Backend - Daily Diabetes Health Tip
// =============================================================================

require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../utils/response.php';

try {
    $pdo = Database::getConnection();

    // Fetch all tips
    $stmt = $pdo->query("SELECT id, title, tip, category, language FROM health_tips ORDER BY id ASC");
    $tips = $stmt->fetchAll();

    if (empty($tips)) {
        sendSuccess('Health tip', [
            'tip' => [
                'id'       => 1,
                'title'    => 'Stay Active Daily',
                'tip'      => 'A 20-minute daily walk improves insulin sensitivity and general well-being.',
                'category' => 'Exercise'
            ]
        ]);
    }

    // Select deterministic tip based on day-of-year so all users on the same day see the daily tip
    $dayOfYear = (int)date('z');
    $selectedTip = $tips[$dayOfYear % count($tips)];

    sendSuccess('Daily health tip retrieved.', [
        'tip' => $selectedTip
    ]);

} catch (Exception $e) {
    sendError('Failed to fetch health tip: ' . $e->getMessage(), 500);
}
