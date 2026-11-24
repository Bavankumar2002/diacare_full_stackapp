<?php
// =============================================================================
// DiaCare - Meal Suggestions API
// Returns one diabetic-friendly food suggestion each for Morning, Afternoon, Dinner
// =============================================================================

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../middleware/auth.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Authorization, Content-Type');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

$user = requireAuth();
if (!$user) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Unauthorized']);
    exit;
}

try {
    $db = getDBConnection();

    // Helper: pick one random food from given categories, preferring lower calories
    function pickSuggestion(PDO $db, array $categories, int $maxCalories = 500): ?array {
        $placeholders = implode(',', array_fill(0, count($categories), '?'));
        $stmt = $db->prepare(
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
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        return $row ?: null;
    }

    // Morning: Breakfast items (light – ≤ 350 kcal)
    $morning = pickSuggestion($db, ['Breakfast', 'Beverages'], 350);

    // Afternoon: Lunch/Dinner, Dal & Pulses (moderate – ≤ 500 kcal)
    $afternoon = pickSuggestion($db, ['Lunch/Dinner', 'Dal & Pulses', 'Rice & Biryani'], 500);

    // Dinner: Curries & Sabzi, Non-Veg, or Lunch/Dinner (lighter – ≤ 450 kcal)
    $dinner = pickSuggestion($db, ['Curries & Sabzi', 'Non-Veg', 'Lunch/Dinner'], 450);

    // Format a food row into a clean response object
    function formatFood(?array $row): ?array {
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
        ];
    }

    echo json_encode([
        'success'   => true,
        'morning'   => formatFood($morning),
        'afternoon' => formatFood($afternoon),
        'dinner'    => formatFood($dinner),
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}
