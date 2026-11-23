<?php
// =============================================================================
// DiaCare Backend - Log Meal Entry
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

$mealType = strtolower(trim($data['meal_type'] ?? 'breakfast'));
$foodName = trim($data['food_name'] ?? '');
$calories = isset($data['calories']) ? (int)$data['calories'] : 0;
$carbs    = isset($data['carbs_g']) ? (float)$data['carbs_g'] : 0.0;
$quantity = isset($data['serving_quantity']) ? (float)$data['serving_quantity'] : 1.0;
$date     = trim($data['meal_date'] ?? date('Y-m-d'));
$time     = trim($data['meal_time'] ?? date('H:i:s'));
$notes    = trim($data['notes'] ?? '');
$imageUrl = trim($data['image_url'] ?? '');

$allowedTypes = ['breakfast', 'lunch', 'dinner', 'snack'];
if (!in_array($mealType, $allowedTypes)) {
    $mealType = 'breakfast';
}

if (empty($foodName)) {
    sendError('Food name is required.');
}

if ($calories < 0 || $calories > 5000) {
    sendError('Please enter a realistic calorie amount (0 - 5000 kcal).');
}

try {
    $pdo = Database::getConnection();

    $stmt = $pdo->prepare("
        INSERT INTO meals (user_id, meal_type, food_name, calories, carbs_g, serving_quantity, meal_date, meal_time, notes, image_url)
        VALUES (:user_id, :meal_type, :food_name, :calories, :carbs_g, :serving_quantity, :meal_date, :meal_time, :notes, :image_url)
    ");
    $stmt->execute([
        ':user_id'          => $userId,
        ':meal_type'        => $mealType,
        ':food_name'        => $foodName,
        ':calories'         => $calories,
        ':carbs_g'          => $carbs,
        ':serving_quantity' => $quantity,
        ':meal_date'        => $date,
        ':meal_time'        => $time,
        ':notes'            => $notes,
        ':image_url'        => !empty($imageUrl) ? $imageUrl : null
    ]);

    $mealId = (int)$pdo->lastInsertId();

    sendSuccess('Meal recorded successfully.', [
        'meal' => [
            'id'               => $mealId,
            'meal_type'        => $mealType,
            'food_name'        => $foodName,
            'calories'         => $calories,
            'carbs_g'          => $carbs,
            'serving_quantity' => $quantity,
            'meal_date'        => $date,
            'meal_time'        => $time,
            'notes'            => $notes,
            'image_url'        => !empty($imageUrl) ? $imageUrl : null
        ]
    ], 201);

} catch (Exception $e) {
    sendError('Failed to record meal: ' . $e->getMessage(), 500);
}
