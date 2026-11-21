<?php
// =============================================================================
// DiaCare Backend - Standalone HMAC-SHA256 JWT Implementation
// =============================================================================

require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/response.php';

class JWT {
    private static function base64UrlEncode(string $data): string {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    private static function base64UrlDecode(string $data): string {
        return base64_decode(strtr($data, '-_', '+/'));
    }

    /**
     * Generate signed JWT token
     */
    public static function encode(array $payload, int $expiry = JWT_EXPIRY_SECONDS): string {
        $header = json_encode(['typ' => 'JWT', 'alg' => 'HS256']);
        
        $now = time();
        $payload['iat'] = $now;
        $payload['exp'] = $now + $expiry;
        
        $base64Header = self::base64UrlEncode($header);
        $base64Payload = self::base64UrlEncode(json_encode($payload));

        $signature = hash_hmac('sha256', "{$base64Header}.{$base64Payload}", JWT_SECRET_KEY, true);
        $base64Signature = self::base64UrlEncode($signature);

        return "{$base64Header}.{$base64Payload}.{$base64Signature}";
    }

    /**
     * Validate and decode token. Returns payload array or null on failure.
     */
    public static function decode(string $token): ?array {
        $parts = explode('.', $token);
        if (count($parts) !== 3) {
            return null;
        }

        list($base64Header, $base64Payload, $base64Signature) = $parts;

        // Verify signature
        $expectedSignature = hash_hmac('sha256', "{$base64Header}.{$base64Payload}", JWT_SECRET_KEY, true);
        $actualSignature = self::base64UrlDecode($base64Signature);

        if (!hash_equals($expectedSignature, $actualSignature)) {
            return null;
        }

        $payload = json_decode(self::base64UrlDecode($base64Payload), true);
        if (!$payload || !isset($payload['exp'])) {
            return null;
        }

        // Check expiration
        if (time() >= $payload['exp']) {
            return null; // Expired
        }

        return $payload;
    }
}

/**
 * Extract Bearer token from HTTP headers
 */
function getBearerToken(): ?string {
    $headers = null;
    if (isset($_SERVER['HTTP_AUTHORIZATION'])) {
        $headers = trim($_SERVER['HTTP_AUTHORIZATION']);
    } elseif (isset($_SERVER['Authorization'])) {
        $headers = trim($_SERVER['Authorization']);
    } elseif (function_exists('apache_request_headers')) {
        $requestHeaders = apache_request_headers();
        if (isset($requestHeaders['Authorization'])) {
            $headers = trim($requestHeaders['Authorization']);
        } elseif (isset($requestHeaders['authorization'])) {
            $headers = trim($requestHeaders['authorization']);
        }
    }

    if (!empty($headers)) {
        if (preg_match('/Bearer\s(\S+)/i', $headers, $matches)) {
            return $matches[1];
        }
    }
    return null;
}

/**
 * Enforce authentication on protected API endpoints.
 * Returns array payload with user_id, email, etc.
 */
function requireAuth(): array {
    $token = getBearerToken();
    if (!$token) {
        sendError('Authorization token is missing. Please log in.', 401);
    }

    $payload = JWT::decode($token);
    if (!$payload || !isset($payload['user_id'])) {
        sendError('Invalid or expired authorization token.', 401);
    }

    return $payload;
}
