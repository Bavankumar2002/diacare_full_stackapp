<?php
// =============================================================================
// DiaCare Backend - Database & Application Configuration
// =============================================================================

// Ensure timezone is set
date_default_timezone_set('Asia/Kolkata');

class Database {
    private static $instance = null;
    private $pdo;

    // Configurable defaults
    private $host = '127.0.0.1';
    private $dbName = 'diacare_db';
    private $username = 'root';
    private $password = '';
    // XAMPP MySQL may run on port 3305 or 3306
    private $preferredPorts = [3305, 3306];

    private function __construct() {
        // Allow environment overrides if defined
        if (getenv('DB_HOST')) $this->host = getenv('DB_HOST');
        if (getenv('DB_NAME')) $this->dbName = getenv('DB_NAME');
        if (getenv('DB_USER')) $this->username = getenv('DB_USER');
        if (getenv('DB_PASS') !== false) $this->password = getenv('DB_PASS');

        $explicitPort = getenv('DB_PORT');
        $portsToTry = $explicitPort ? [(int)$explicitPort] : $this->preferredPorts;

        $lastException = null;
        foreach ($portsToTry as $port) {
            try {
                $dsn = "mysql:host={$this->host};port={$port};dbname={$this->dbName};charset=utf8mb4";
                $options = [
                    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                    PDO::ATTR_EMULATE_PREPARES   => false,
                    PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci"
                ];
                $this->pdo = new PDO($dsn, $this->username, $this->password, $options);
                return; // successfully connected
            } catch (PDOException $e) {
                $lastException = $e;
            }
        }

        // If we reach here, connection failed on all attempted ports
        http_response_code(500);
        header('Content-Type: application/json; charset=UTF-8');
        echo json_encode([
            'status'  => 'error',
            'message' => 'Database connection failed: ' . ($lastException ? $lastException->getMessage() : 'Unknown error'),
            'data'    => null
        ]);
        exit;
    }

    public static function getConnection(): PDO {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance->pdo;
    }
}

// Global JWT Secret Key
define('JWT_SECRET_KEY', 'diacare_super_secure_jwt_secret_key_2026_medical_app_token');
define('JWT_EXPIRY_SECONDS', 60 * 60 * 24 * 30); // 30 days valid
