<?php
// =============================================================================
// DiaCare Backend - Validation and Medical Calculation Utilities
// =============================================================================

class Validator {
    public static function isValidEmail(string $email): bool {
        return filter_var(trim($email), FILTER_VALIDATE_EMAIL) !== false;
    }

    public static function isValidPhone(string $phone): bool {
        // Strip out spaces, dashes, parentheses
        $cleaned = preg_replace('/[^\d+]/', '', $phone);
        return strlen($cleaned) >= 7 && strlen($cleaned) <= 15;
    }

    /**
     * Compute BMI = weight(kg) / (height(m))^2
     */
    public static function calculateBMI(float $heightCm, float $weightKg): float {
        if ($heightCm <= 0 || $weightKg <= 0) {
            return 0.0;
        }
        $heightMeters = $heightCm / 100.0;
        $bmi = $weightKg / ($heightMeters * $heightMeters);
        return round($bmi, 1);
    }

    /**
     * Determine Sugar Reading Status based on standard ADA guidelines
     * Low: < 70 mg/dL (Hypoglycemia risk)
     * Normal: 70 - 140 mg/dL (Target glycemic control)
     * High: > 140 mg/dL (Hyperglycemia risk)
     */
    public static function determineSugarStatus(float $value): string {
        if ($value < 70.0) {
            return 'Low';
        } elseif ($value <= 140.0) {
            return 'Normal';
        } else {
            return 'High';
        }
    }
}
