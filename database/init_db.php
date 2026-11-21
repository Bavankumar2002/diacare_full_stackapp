<?php
try {
    // Try port 3305 first (XAMPP default on this machine), then 3306
    $ports = [3305, 3306];
    $connected = false;
    $pdo = null;

    foreach ($ports as $port) {
        try {
            $pdo = new PDO("mysql:host=127.0.0.1;port={$port}", "root", "", [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION
            ]);
            echo "Connected to MySQL on port {$port}\n";
            $connected = true;
            break;
        } catch (Exception $e) {
            // continue
        }
    }

    if (!$connected) {
        die("Could not connect to MySQL on ports 3305 or 3306.\n");
    }

    $sql = file_get_contents(__DIR__ . '/diacare_db.sql');
    // Multi-query execution
    $pdo->exec($sql);
    echo "diacare_db schema and seeds imported successfully!\n";

    // Verify tables
    $pdo->exec("USE diacare_db");
    $stmt = $pdo->query("SHOW TABLES");
    $tables = $stmt->fetchAll(PDO::FETCH_COLUMN);
    echo "Tables in diacare_db: " . implode(', ', $tables) . "\n";

    // Verify seed count
    $stmt = $pdo->query("SELECT COUNT(*) FROM food_items");
    echo "Seed food items count: " . $stmt->fetchColumn() . "\n";

    $stmt = $pdo->query("SELECT COUNT(*) FROM health_tips");
    echo "Seed health tips count: " . $stmt->fetchColumn() . "\n";

} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
    exit(1);
}
