<?php
// =============================================================================
// DiaCare REST API - Root Health & Information Endpoint
// =============================================================================

require_once __DIR__ . '/utils/response.php';
require_once __DIR__ . '/config/db.php';

$dbConnected = false;
$portUsed = null;

try {
    $pdo = Database::getConnection();
    $dbConnected = true;
} catch (Exception $e) {
    $dbConnected = false;
}

sendSuccess('DiaCare Diabetes Patient Management REST API is running.', [
    'app'         => 'DiaCare',
    'version'     => '1.0.0',
    'status'      => 'online',
    'db_connected'=> $dbConnected,
    'server_time' => date('Y-m-d H:i:s'),
    'endpoints'   => [
        'auth' => [
            'POST /api/auth/register.php',
            'POST /api/auth/login.php',
            'POST /api/auth/forgot-password.php',
            'POST /api/auth/change-password.php',
            'POST /api/auth/delete-account.php'
        ],
        'profile' => [
            'GET /api/profile/get.php',
            'POST /api/profile/update.php'
        ],
        'sugar' => [
            'GET /api/sugar/get.php?period=all|today|week|month',
            'POST /api/sugar/add.php',
            'POST /api/sugar/delete.php'
        ],
        'calories' => [
            'GET /api/calories/get.php?date=YYYY-MM-DD',
            'GET /api/calories/food-items.php?q=&category=',
            'POST /api/calories/add.php',
            'POST /api/calories/delete.php'
        ],
        'reminders' => [
            'GET /api/reminders/get.php',
            'POST /api/reminders/add.php',
            'POST /api/reminders/update.php',
            'POST /api/reminders/toggle.php',
            'POST /api/reminders/delete.php'
        ],
        'tips' => [
            'GET /api/tips/daily.php'
        ]
    ]
]);
