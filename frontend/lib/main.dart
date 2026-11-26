// =============================================================================
// DiaCare - Diabetes Patient Management System (Main Entry Point)
// =============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/api_service.dart';
import 'core/constants.dart';
import 'core/notification_service.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/sugar_provider.dart';
import 'providers/calorie_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/onboarding/splash_screen.dart';

/// Custom HttpOverrides to prevent SSL certificate handshake errors on older Android devices
class DiaCareHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        return host.contains('shreetechhub.com') ||
            host.contains('192.168.') ||
            host == 'localhost' ||
            host == '10.0.2.2';
      };
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 0. Ensure SSL compatibility on older Android devices
  HttpOverrides.global = DiaCareHttpOverrides();

  // 1. Initialize API Client with saved tokens and base URLs
  await ApiService().init();

  // 2. Initialize local notifications and reminder alarms
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermissions();

  // 3. Initialize theme provider for dark mode preferences
  final themeProvider = ThemeProvider();
  await themeProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<ProfileProvider>(create: (_) => ProfileProvider()),
        ChangeNotifierProvider<SugarProvider>(create: (_) => SugarProvider()),
        ChangeNotifierProvider<CalorieProvider>(create: (_) => CalorieProvider()),
        ChangeNotifierProvider<ReminderProvider>(create: (_) => ReminderProvider()),
        ChangeNotifierProvider<NotificationProvider>(create: (_) => NotificationProvider()),
      ],
      child: const DiaCareApp(),
    ),
  );
}

class DiaCareApp extends StatelessWidget {
  const DiaCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProv.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
