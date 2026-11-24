// =============================================================================
// DiaCare - Animated Splash Screen & Authentication Route Dispatcher
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/diabetic_illustration.dart';
import '../auth/phone_login_screen.dart';
import '../profile/personal_details_screen.dart';
import '../main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.forward();
    _checkInitialRoute();
  }

  /// Smooth bottom-to-top ("down to up") slide transition
  PageRouteBuilder _buildDownToUpRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0); // Starts from bottom
        const end = Offset.zero;         // Moves to top
        const curve = Curves.easeOutCubic;
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 700),
    );
  }

  Future<void> _checkInitialRoute() async {
    // Artificial minimum duration to allow splash animation to play smoothly
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    // Initialize themes & tips
    context.read<ThemeProvider>().fetchDailyTip();

    final authProvider = context.read<AuthProvider>();
    final isLoggedIn = await authProvider.tryAutoLogin();

    if (!mounted) return;

    if (isLoggedIn) {
      if (!authProvider.hasProfile) {
        Navigator.of(context).pushReplacement(
          _buildDownToUpRoute(const PersonalDetailsScreen(isInitialSetup: true)),
        );
      } else {
        Navigator.of(context).pushReplacement(
          _buildDownToUpRoute(const MainNavigationScreen()),
        );
      }
    } else {
      // Transition from pre-loader smoothly down-to-up into the Phone Page
      Navigator.of(context).pushReplacement(
        _buildDownToUpRoute(const PhoneLoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 1. Official DiaCare App Logo
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          width: 140,
                          height: 140,
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, e, st) => const DiabeticIllustration(
                            size: 200,
                            animate: true,
                            showBadges: true,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 2. App Title with Modern Branding
                      RichText(
                        text: const TextSpan(
                          text: 'DiaCare',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                          children: [
                            TextSpan(
                              text: '.',
                              style: TextStyle(
                                color: AppConstants.primaryTeal,
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 6),

                      // 3. Subtitle
                      const Text(
                        'Diabetes Care Backed by Science',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // 4. Modern Medical Pill Progress Bar
                      Container(
                        width: 150,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          child: LinearProgressIndicator(
                            backgroundColor: Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryTeal),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Initializing care protocol...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 48),

                      // 5. Medical Trust Seal
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_user_rounded,
                              color: AppConstants.primaryTeal,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Clinically Verified Diabetes Tracking',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
