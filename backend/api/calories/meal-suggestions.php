<?php
// =============================================================================
// DiaCare Backend - Personalized Meal Suggestions API
// Returns diabetic-friendly food suggestions for Morning, Afternoon, and Dinner
// =============================================================================

require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../utils/response.php';
require_once __DIR__ . '/../../utils/jwt.php';

// Optional Authentication: supports both authenticated users and guest access
$userId = null;
$token = getBearerToken();
if ($token) {
    $payload = JWT::decode($token);
    if ($payload && isset($payload['user_id'])) {
        $userId = $payload['user_id'];
    }
}

try {
    $pdo = Database::getConnection();

    // Helper: generate friendly diabetic nutrition description based on nutrients
    function generateDescription(array $food, string $mealTime): string {
        $cals = (int)($food['calories'] ?? 0);
        $carbs = (float)($food['carbs_g'] ?? 0);
        $protein = (float)($food['protein_g'] ?? 0);
        $category = $food['category'] ?? '';

        if ($carbs <= 15 && $carbs > 0) {
            return "Low carb & gentle on blood sugar";
        } elseif ($protein >= 8) {
            return "Protein-rich • Helps steady energy";
        } elseif ($cals <= 150) {
            return "Light portion • Low glycemic impact";
        } elseif ($category === 'Dal & Pulses') {
            return "High fiber & plant protein";
        } elseif ($category === 'Fruits & Salads') {
            return "Nutrient-dense with natural vitamins";
        } elseif ($mealTime === 'Morning') {
            return "Balanced morning start for glucose stability";
        } elseif ($mealTime === 'Afternoon') {
            return "Satisfying lunch with steady carbs";
        } else {
            return "Light dinner to prevent overnight sugar spikes";
        }
    }

    // Helper: pick one suggestion from specified categories, preferring lower calories
    function pickSuggestion(PDO $pdo, array $categories, int $maxCalories, string $mealTime): ?array {
        $placeholders = implode(',', array_fill(0, count($categories), '?'));
        
        // Try to pick a healthy option within calorie budget
        $stmt = $pdo->prepare(
            "SELECT id, name, category, serving_size, calories, carbs_g, protein_g, fat_g, image_url
             FROM food_items
             WHERE category IN ($placeholders)
               AND calories <= ?
               AND calories > 0
             ORDER BY RAND()
             LIMIT 1"
        );
        $params = array_merge($categories, [$maxCalories]);
        $stmt->execute($params);
        $row = $stmt->fetch();

        // Fallback if no item matched the calorie ceiling
        if (!$row) {
            $stmt = $pdo->prepare(
                "SELECT id, name, category, serving_size, calories, carbs_g, protein_g, fat_g, image_url
                 FROM food_items
                 WHERE category IN ($placeholders)
                 ORDER BY RAND()
                 LIMIT 1"
            );
            $stmt->execute($categories);
            $row = $stmt->fetch();
        }

        if (!$row) return null;

        return [
            'id'           => (int)$row['id'],
            'name'         => $row['name'],
            'category'     => $row['category'],
            'serving_size' => $row['serving_size'],
            'calories'     => (int)$row['calories'],
            'carbs_g'      => (float)$row['carbs_g'],
            'protein_g'    => (float)$row['protein_g'],
            'fat_g'        => (float)$row['fat_g'],
            'image_url'    => $row['image_url'] ?? null,
            'description'  => generateDescription($row, $mealTime),
        ];
    }

    // Morning: Breakfast, Beverages, Fruits & Salads (light ≤ 350 kcal)
    $morning = pickSuggestion($pdo, ['Breakfast', 'Beverages', 'Fruits & Salads'], 350, 'Morning');

    // Afternoon: Lunch/Dinner, Dal & Pulses, Rice & Biryani, Breads & Roti (≤ 500 kcal)
    $afternoon = pickSuggestion($pdo, ['Lunch/Dinner', 'Dal & Pulses', 'Rice & Biryani', 'Breads & Roti'], 500, 'Afternoon');

    // Dinner: Curries & Sabzi, Lunch/Dinner, Non-Veg, Dal & Pulses (light ≤ 450 kcal)
    $dinner = pickSuggestion($pdo, ['Curries & Sabzi', 'Lunch/Dinner', 'Non-Veg', 'Dal & Pulses'], 450, 'Dinner');

    sendSuccess('Meal suggestions retrieved successfully.', [
        'morning'   => $morning,
        'afternoon' => $afternoon,
        'dinner'    => $dinner,
    ]);

} catch (Exception $e) {
    sendError('Failed to fetch meal suggestions: ' . $e->getMessage(), 500);
}
