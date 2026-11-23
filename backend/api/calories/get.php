<?php
// =============================================================================
// DiaCare Backend - Retrieve Meal Logs & Calorie Analytics
// =============================================================================

require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../utils/response.php';
require_once __DIR__ . '/../../utils/jwt.php';

$auth = requireAuth();
$userId = $auth['user_id'];

$targetDate = $_GET['date'] ?? date('Y-m-d');

try {
    $pdo = Database::getConnection();

    // 1. Fetch user's daily calorie goal from profile
    $profStmt = $pdo->prepare("SELECT daily_calorie_goal FROM profiles WHERE user_id = :user_id LIMIT 1");
    $profStmt->execute([':user_id' => $userId]);
    $profile = $profStmt->fetch();
    $dailyGoal = !empty($profile['daily_calorie_goal']) ? (int)$profile['daily_calorie_goal'] : 1800;

    // 2. Fetch meals for target date
    $mealStmt = $pdo->prepare("
        SELECT 
            m.id, m.meal_type, m.food_name, m.calories, m.carbs_g, m.serving_quantity, m.meal_date, m.meal_time, m.notes, m.created_at,
            COALESCE(
                NULLIF(m.image_url, ''),
                (
                    SELECT f.image_url FROM food_items f 
                    WHERE LOWER(f.name) = LOWER(m.food_name) 
                       OR LOWER(m.food_name) LIKE CONCAT('%', LOWER(f.name), '%') 
                       OR LOWER(f.name) LIKE CONCAT('%', SUBSTRING_INDEX(LOWER(m.food_name), ' ', 1), '%')
                    LIMIT 1
                )
            ) AS image_url
        FROM meals m
        WHERE m.user_id = :user_id AND m.meal_date = :meal_date
        ORDER BY m.meal_time ASC
    ");
    $mealStmt->execute([':user_id' => $userId, ':meal_date' => $targetDate]);
    $meals = $mealStmt->fetchAll();

    // 3. Totals and category breakdown
    $totalCalories = 0;
    $totalCarbs = 0.0;
    $breakdown = [
        'breakfast' => 0,
        'lunch'     => 0,
        'dinner'    => 0,
        'snack'     => 0
    ];

    foreach ($meals as $m) {
        $cals = (int)$m['calories'];
        $carbs = (float)$m['carbs_g'];
        $totalCalories += $cals;
        $totalCarbs += $carbs;

        $t = strtolower($m['meal_type']);
        if (isset($breakdown[$t])) {
            $breakdown[$t] += $cals;
        } else {
            $breakdown['snack'] += $cals;
        }
    }

    $remainingCalories = max(0, $dailyGoal - $totalCalories);
    $percentage = $dailyGoal > 0 ? round(($totalCalories / $dailyGoal) * 100, 1) : 0;

    // 4. Weekly summary for chart (last 7 days including target date)
    $weekStmt = $pdo->prepare("
        SELECT 
            meal_date, 
            SUM(calories) as total_cals,
            SUM(carbs_g) as total_carbs
        FROM meals
        WHERE user_id = :user_id AND meal_date >= DATE_SUB(:meal_date_start, INTERVAL 6 DAY) AND meal_date <= :meal_date_end
        GROUP BY meal_date
        ORDER BY meal_date ASC
    ");
    $weekStmt->execute([':user_id' => $userId, ':meal_date_start' => $targetDate, ':meal_date_end' => $targetDate]);
    $weekRows = $weekStmt->fetchAll();

    // Fill missing days with 0 so the chart has all 7 continuous data points
    $weeklySummary = [];
    $indexedRows = [];
    foreach ($weekRows as $r) {
        $indexedRows[$r['meal_date']] = $r;
    }

    for ($i = 6; $i >= 0; $i--) {
        $d = date('Y-m-d', strtotime("{$targetDate} -{$i} days"));
        $dayName = date('D', strtotime($d)); // Mon, Tue, etc.
        $cals = isset($indexedRows[$d]) ? (int)$indexedRows[$d]['total_cals'] : 0;
        $carbs = isset($indexedRows[$d]) ? (float)$indexedRows[$d]['total_carbs'] : 0.0;

        $weeklySummary[] = [
            'date'     => $d,
            'day'      => $dayName,
            'calories' => $cals,
            'carbs_g'  => $carbs,
            'goal'     => $dailyGoal
        ];
    }

    sendSuccess('Calorie summary retrieved successfully.', [
        'date'               => $targetDate,
        'daily_goal'         => $dailyGoal,
        'total_calories'     => $totalCalories,
        'total_carbs'        => round($totalCarbs, 1),
        'remaining_calories' => $remainingCalories,
        'percentage'         => $percentage,
        'breakdown'          => $breakdown,
        'meals'              => $meals,
        'weekly_chart'       => $weeklySummary
    ]);

} catch (Exception $e) {
    sendError('Failed to fetch calorie data: ' . $e->getMessage(), 500);
}
