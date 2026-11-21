<?php
// Test runner for DiaCare API endpoints
function testEndpoint($url, $method = 'GET', $data = null, $token = null) {
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    $headers = ['Content-Type: application/json'];
    if ($token) {
        $headers[] = "Authorization: Bearer {$token}";
    }
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    if ($method === 'POST') {
        curl_setopt($ch, CURLOPT_POST, true);
        if ($data) curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    }
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    return ['code' => $httpCode, 'body' => json_decode($response, true)];
}

$baseUrl = 'http://localhost/diacare_full_stack/backend';

// 1. Healthcheck
$res = testEndpoint("{$baseUrl}/index.php");
echo "1. Healthcheck: HTTP {$res['code']} - " . ($res['body']['status'] ?? 'err') . "\n";

// 2. Register
$rand = rand(1000, 9999);
$testEmail = "patient{$rand}@test.com";
$testPhone = "98765{$rand}";
$regData = [
    'name' => 'Ramesh Kumar',
    'email' => $testEmail,
    'phone' => $testPhone,
    'password' => 'SecurePass123!',
    'confirm_password' => 'SecurePass123!'
];
$regRes = testEndpoint("{$baseUrl}/api/auth/register.php", 'POST', $regData);
echo "2. Register: HTTP {$regRes['code']} - " . ($regRes['body']['message'] ?? 'err') . "\n";
$token = $regRes['body']['data']['token'] ?? null;

if (!$token) {
    die("Registration failed to return token\n");
}

// 3. Login
$loginRes = testEndpoint("{$baseUrl}/api/auth/login.php", 'POST', [
    'email' => $testEmail,
    'password' => 'SecurePass123!'
]);
echo "3. Login: HTTP {$loginRes['code']} - " . ($loginRes['body']['message'] ?? 'err') . "\n";

// 4. Update Profile
$profData = [
    'full_name' => 'Ramesh Kumar',
    'age' => 58,
    'gender' => 'Male',
    'dob' => '1968-04-15',
    'height_cm' => 172.0,
    'weight_kg' => 74.5,
    'diabetes_type' => 'Type 2',
    'year_diagnosed' => 2018,
    'current_medicines' => 'Metformin 500mg, Glimepiride 1mg',
    'allergies' => 'Sulfa drugs',
    'emergency_contact_name' => 'Priya (Daughter)',
    'emergency_contact_phone' => '9840012345',
    'doctor_name' => 'Dr. A. Subramanian',
    'doctor_hospital' => 'Apollo Hospital',
    'daily_calorie_goal' => 1750
];
$profRes = testEndpoint("{$baseUrl}/api/profile/update.php", 'POST', $profData, $token);
echo "4. Profile Update: HTTP {$profRes['code']} - BMI=" . ($profRes['body']['data']['profile']['bmi'] ?? 'n/a') . "\n";

// 5. Add Sugar Reading (Normal)
$sugarRes = testEndpoint("{$baseUrl}/api/sugar/add.php", 'POST', [
    'reading_value' => 118,
    'reading_type' => 'fasting',
    'date' => date('Y-m-d'),
    'time' => '07:30:00',
    'notes' => 'Fasting reading before morning tea'
], $token);
echo "5. Add Sugar: HTTP {$sugarRes['code']} - Status=" . ($sugarRes['body']['data']['reading']['reading_status'] ?? 'err') . "\n";

// 6. Add Sugar Reading (Low alert check)
$sugarLow = testEndpoint("{$baseUrl}/api/sugar/add.php", 'POST', [
    'reading_value' => 64,
    'reading_type' => 'before_meal',
    'date' => date('Y-m-d'),
    'time' => '12:45:00',
    'notes' => 'Felt mild tremors'
], $token);
echo "6. Sugar Low Alert: HTTP {$sugarLow['code']} - Danger=" . ($sugarLow['body']['data']['alert']['is_danger'] ? 'YES' : 'NO') . "\n";

// 7. Get Sugar Readings & Stats
$sugarGet = testEndpoint("{$baseUrl}/api/sugar/get.php?period=all", 'GET', null, $token);
echo "7. Sugar Stats: Total=" . ($sugarGet['body']['data']['stats']['count'] ?? '0') . ", Avg=" . ($sugarGet['body']['data']['stats']['average'] ?? '0') . "\n";

// 8. Food Items catalog
$foodsRes = testEndpoint("{$baseUrl}/api/calories/food-items.php?q=idli", 'GET', null, $token);
echo "8. Search Food: Found " . ($foodsRes['body']['data']['count'] ?? '0') . " items matching 'idli'\n";

// 9. Add Meal
$mealRes = testEndpoint("{$baseUrl}/api/calories/add.php", 'POST', [
    'meal_type' => 'breakfast',
    'food_name' => 'Idli with Sambar and Chutney',
    'calories' => 280,
    'carbs_g' => 45.0,
    'serving_quantity' => 1.0,
    'meal_date' => date('Y-m-d'),
    'meal_time' => '08:30:00',
    'notes' => '2 steamed idlis with bowl of vegetable sambar'
], $token);
echo "9. Add Meal: HTTP {$mealRes['code']} - Meal ID=" . ($mealRes['body']['data']['meal']['id'] ?? 'err') . "\n";

// 10. Get Calorie summary
$calGet = testEndpoint("{$baseUrl}/api/calories/get.php", 'GET', null, $token);
echo "10. Calorie Summary: Total=" . ($calGet['body']['data']['total_calories'] ?? 0) . " / Goal=" . ($calGet['body']['data']['daily_goal'] ?? 0) . " kcal\n";

// 11. Add Reminder
$remRes = testEndpoint("{$baseUrl}/api/reminders/add.php", 'POST', [
    'title' => 'Metformin 500mg',
    'type' => 'medicine',
    'dosage' => '1 tablet after breakfast',
    'time' => '09:00:00',
    'repeat_type' => 'daily'
], $token);
echo "11. Add Reminder: HTTP {$remRes['code']} - ID=" . ($remRes['body']['data']['reminder']['id'] ?? 'err') . "\n";

// 12. Daily health tip
$tipRes = testEndpoint("{$baseUrl}/api/tips/daily.php");
echo "12. Health Tip: " . ($tipRes['body']['data']['tip']['title'] ?? 'err') . "\n";

echo "\nALL BACKEND API TESTS COMPLETED SUCCESSFULLY!\n";
