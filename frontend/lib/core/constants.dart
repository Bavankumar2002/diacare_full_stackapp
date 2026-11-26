// =============================================================================
// DiaCare - Core Application Constants
// =============================================================================

import 'package:flutter/material.dart';

class AppConstants {
  // App Information
  static const String appName = 'DiaCare';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Track Health. Build Habits. Live Better.';
  static const String medicalDisclaimer =
      'DiaCare is for tracking only and does not replace professional medical advice. Always consult your doctor for medical decisions.';

  // Default Backend API Base URL
  // Live GoDaddy Host: https://shreetechhub.com/demosite/diacare
  static String get defaultBaseUrl {
    return 'https://shreetechhub.com/demosite/diacare';
  }

  // Local Storage Keys
  static const String keyJwtToken = 'diacare_jwt_token';
  static const String keyUserData = 'diacare_user_data';
  static const String keyDarkMode = 'diacare_dark_mode';
  static const String keyBaseUrl = 'diacare_custom_base_url';
  static const String keyHasSeenOnboarding = 'diacare_has_seen_onboarding';

  // Primary Theme Colors (Professional Medical Palette)
  static const Color primaryTeal = Color(0xFF0FA3B1); // Clean Medical Teal
  static const Color primaryTealDark = Color(0xFF0C828E);
  static const Color primaryTealLight = Color(0xFFE2F6F8);
  static const Color primaryNavy = Color(0xFF1E293B);

  // Glucose & Clinical Status Colors
  static const Color statusNormal = Color(0xFF10B981); // Emerald Green (70-140 mg/dL)
  static const Color statusWarning = Color(0xFFF59E0B); // Amber Warning
  static const Color statusDanger = Color(0xFFEF4444);  // Red Danger (<70 or >140 mg/dL)

  // Surface & Background Colors
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Colors.white;
  static const Color bgDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);

  // Border Radius
  static const double cardRadius = 16.0;
  static const double buttonRadius = 14.0;
}
