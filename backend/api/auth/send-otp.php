<?php
// =============================================================================
// DiaCare Backend - Send Mobile OTP (Static OTP: 1234)
// =============================================================================

require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../utils/response.php';
require_once __DIR__ . '/../../utils/validation.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendError('Method not allowed. Use POST.', 405);
}

$data = getRequestBody();
$rawPhone = trim($data['phone'] ?? '');

// Clean phone digits
$phone = preg_replace('/[^\d]/', '', $rawPhone);
if (strlen($phone) > 10 && substr($phone, 0, 2) === '91') {
    $phone = substr($phone, 2);
}

if (strlen($phone) !== 10) {
    sendError('Please enter a valid 10-digit mobile number.');
}

// Static OTP as requested by the user
$staticOtp = '1234';

sendSuccess('OTP sent successfully to +91 ' . $phone, [
    'phone' => $phone,
    'otp'   => $staticOtp // Static OTP 1234
]);
