<?php
// =============================================================================
// DiaCare Backend - Retrieve Blood Sugar Readings & Analytics
// =============================================================================

require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../utils/response.php';
require_once __DIR__ . '/../../utils/jwt.php';

$auth = requireAuth();
$userId = $auth['user_id'];

$period = $_GET['period'] ?? 'all'; // 'today', 'week', 'month', 'all'

try {
    $pdo = Database::getConnection();

    $whereClause = "WHERE user_id = :user_id";
    $params = [':user_id' => $userId];

    if ($period === 'today') {
        $whereClause .= " AND DATE(measured_at) = CURDATE()";
    } elseif ($period === 'week') {
        $whereClause .= " AND measured_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)";
    } elseif ($period === 'month') {
        $whereClause .= " AND measured_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)";
    }

    // 1. Fetch readings list
    $stmt = $pdo->prepare("
        SELECT id, reading_value, reading_type, reading_status, measured_at, notes, created_at
        FROM sugar_readings
        {$whereClause}
        ORDER BY measured_at DESC
    ");
    $stmt->execute($params);
    $readings = $stmt->fetchAll();

    // 2. Compute statistics
    $statStmt = $pdo->prepare("
        SELECT 
            COUNT(*) as total_count,
            ROUND(AVG(reading_value), 1) as avg_value,
            MAX(reading_value) as max_value,
            MIN(reading_value) as min_value,
            SUM(CASE WHEN reading_status = 'Low' THEN 1 ELSE 0 END) as low_count,
            SUM(CASE WHEN reading_status = 'Normal' THEN 1 ELSE 0 END) as normal_count,
            SUM(CASE WHEN reading_status = 'High' THEN 1 ELSE 0 END) as high_count
        FROM sugar_readings
        {$whereClause}
    ");
    $statStmt->execute($params);
    $stats = $statStmt->fetch();

    // 3. Fetch latest overall reading
    $latestStmt = $pdo->prepare("
        SELECT id, reading_value, reading_type, reading_status, measured_at, notes
        FROM sugar_readings
        WHERE user_id = :user_id
        ORDER BY measured_at DESC
        LIMIT 1
    ");
    $latestStmt->execute([':user_id' => $userId]);
    $latestReading = $latestStmt->fetch();

    sendSuccess('Readings retrieved successfully.', [
        'period'   => $period,
        'stats'    => [
            'count'        => (int)($stats['total_count'] ?? 0),
            'average'      => $stats['avg_value'] !== null ? (float)$stats['avg_value'] : null,
            'highest'      => $stats['max_value'] !== null ? (float)$stats['max_value'] : null,
            'lowest'       => $stats['min_value'] !== null ? (float)$stats['min_value'] : null,
            'low_count'    => (int)($stats['low_count'] ?? 0),
            'normal_count' => (int)($stats['normal_count'] ?? 0),
            'high_count'   => (int)($stats['high_count'] ?? 0)
        ],
        'latest'   => $latestReading ? $latestReading : null,
        'readings' => $readings
    ]);

} catch (Exception $e) {
    sendError('Failed to fetch readings: ' . $e->getMessage(), 500);
}
