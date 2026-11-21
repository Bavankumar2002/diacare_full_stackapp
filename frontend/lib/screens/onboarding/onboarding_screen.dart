// =============================================================================
// DiaCare - Elderly-Friendly 3-Step Onboarding Slides
// =============================================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../widgets/custom_button.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Smart Sugar Tracking',
      'subtitle':
          'Log your blood glucose in seconds. Clear green, yellow, and red color codes help you understand your health immediately.',
      'icon': Icons.water_drop_rounded,
      'color': AppConstants.primaryTeal,
      'bgColor': AppConstants.primaryTealLight,
    },
    {
      'title': 'Indian Calorie Counter',
      'subtitle':
          'Built-in list of everyday Indian foods—idli, dosa, rice, chapati, sambar, and snacks. Track calories and stay in control.',
      'icon': Icons.restaurant_rounded,
      'color': const Color(0xFF10B981),
      'bgColor': const Color(0xFFD1FAE5),
    },
    {
      'title': 'Never Miss Your Medicines',
      'subtitle':
          'Set simple daily reminders for your tablets, insulin, and glucose checks. Critical alerts keep you and your family safe.',
      'icon': Icons.alarm_on_rounded,
      'color': const Color(0xFF0284C7),
      'bgColor': const Color(0xFFE0F2FE),
    },
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyHasSeenOnboarding, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_currentPage < _slides.length - 1)
            TextButton(
              onPressed: _completeOnboarding,
              child: const Text(
                'Skip',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (idx) => setState(() => _currentPage = idx),
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final item = _slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Large Friendly Graphic
                        Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            color: item['bgColor'] as Color,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              item['icon'] as IconData,
                              size: 85,
                              color: item['color'] as Color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          item['title'] as String,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item['subtitle'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF64748B),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Page Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppConstants.primaryTeal
                          : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Action Button
              CustomButton(
                text: _currentPage == _slides.length - 1
                    ? 'Get Started'
                    : 'Next',
                icon: _currentPage == _slides.length - 1
                    ? Icons.check_circle_rounded
                    : Icons.arrow_forward_rounded,
                onPressed: () {
                  if (_currentPage == _slides.length - 1) {
                    _completeOnboarding();
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
