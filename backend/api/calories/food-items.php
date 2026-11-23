<?php
// =============================================================================
// DiaCare Backend - Food Items Reference Catalog (Indian Foods)
// =============================================================================

require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../utils/response.php';
require_once __DIR__ . '/../../utils/jwt.php';

// Allow authenticated users to fetch/search Indian foods
requireAuth();

$query    = trim($_GET['q'] ?? '');
$category = trim($_GET['category'] ?? '');

try {
    $pdo = Database::getConnection();

    $limit = isset($_GET['limit']) ? intval($_GET['limit']) : 250;
    if ($limit <= 0 || $limit > 1000) $limit = 250;

    $sql = "SELECT id, name, category, serving_size, calories, carbs_g, protein_g, fat_g, image_url FROM food_items WHERE 1=1";
    $params = [];

    if (!empty($query)) {
        $sql .= " AND (name LIKE :query OR category LIKE :query_cat)";
        $params[':query'] = "%{$query}%";
        $params[':query_cat'] = "%{$query}%";
    }

    if (!empty($category) && strtolower($category) !== 'all') {
        $sql .= " AND category = :category";
        $params[':category'] = $category;
    }

    $sql .= " ORDER BY (category = 'Breakfast') DESC, (category = 'Lunch/Dinner') DESC, name ASC";

    $sql .= " LIMIT " . $limit;

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $items = $stmt->fetchAll();

    // Also get distinct categories
    $catStmt = $pdo->query("SELECT DISTINCT category FROM food_items WHERE category IS NOT NULL AND category != '' ORDER BY category ASC");
    $categories = $catStmt->fetchAll(PDO::FETCH_COLUMN);

    sendSuccess('Food catalog retrieved.', [
        'count'      => count($items),
        'categories' => $categories,
        'foods'      => $items
    ]);

} catch (Exception $e) {
    sendError('Failed to fetch food items: ' . $e->getMessage(), 500);
}
