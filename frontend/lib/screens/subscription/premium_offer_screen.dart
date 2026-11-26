// =============================================================================
// DiaCare - Premium & Free Plan Offer Screen (50% Festive Offer)
// Inspired by Healthify/DiaCare Paywall Design Reference
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../auth/otp_verification_screen.dart';

class PremiumOfferScreen extends StatefulWidget {
  final String? phone;
  final bool isRegistrationFlow;
  final bool isAdMode;

  const PremiumOfferScreen({
    super.key,
    this.phone,
    this.isRegistrationFlow = false,
    this.isAdMode = false,
  });

  @override
  State<PremiumOfferScreen> createState() => _PremiumOfferScreenState();
}

class _PremiumOfferScreenState extends State<PremiumOfferScreen> {
  // Plan selection: 'premium' or 'free'
  String _selectedPlan = 'premium';

  // Live countdown timer (Starts at 05D 01H 49M 43S)
  int _secondsLeft = (5 * 86400) + (1 * 3600) + (49 * 60) + 43;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        if (mounted) {
          setState(() => _secondsLeft--);
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  // Format countdown
  String get _daysStr => (_secondsLeft ~/ 86400).toString().padLeft(2, '0');
  String get _hoursStr => ((_secondsLeft % 86400) ~/ 3600).toString().padLeft(2, '0');
  String get _minsStr => ((_secondsLeft % 3600) ~/ 60).toString().padLeft(2, '0');
  String get _secsStr => (_secondsLeft % 60).toString().padLeft(2, '0');

  Future<void> _handleProceed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_subscription_plan', _selectedPlan);

    if (!mounted) return;

    if (widget.isRegistrationFlow && widget.phone != null) {
      // First-time flow: go from Cost Page to OTP Verification Page
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              OtpVerificationScreen(
            phone: widget.phone!,
            selectedPlan: _selectedPlan,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;
            final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    } else {
      // Ad mode or in-app modal: dismiss and apply
      Navigator.of(context).pop();
      if (_selectedPlan == 'premium') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 DiaCare Plus 50% Festive Offer Activated!'),
            backgroundColor: AppConstants.primaryTeal,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleDismissOrContinueFree() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_subscription_plan', 'free');

    if (!mounted) return;

    if (widget.isRegistrationFlow && widget.phone != null) {
      // Continue to OTP with free plan
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              OtpVerificationScreen(
            phone: widget.phone!,
            selectedPlan: 'free',
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;
            final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFBE4E7), // Soft champagne-rose
              Color(0xFFFCECEE),
              Color(0xFFFFF2F4),
              Color(0xFFF7E6E9),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. Top Header Bar with DIACARE branding and Close (X) button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 16, 8),
                child: Row(
                  children: [
                    const SizedBox(width: 32),
                    const Expanded(
                      child: Text(
                        'D I A C A R E',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4.5,
                          color: Color(0xFF881337),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _handleDismissOrContinueFree,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Festive Offer Ribbon Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6.5),
                color: const Color(0xFF881337), // Rich deep burgundy
                child: const Text(
                  '/MONTH  ✦  GIFT YOURSELF  ✦  FESTIVE OFFER  ✦',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              // Main Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 3. Headline & Countdown Timer Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            child: Text(
                              'AI CALORIE &\nGLUCOSE COUNTER',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E1114),
                                letterSpacing: -0.5,
                                height: 1.15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Live Countdown Timer
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'ENDS IN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF881337),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildTimerUnit(_daysStr, 'D'),
                                  const SizedBox(width: 4),
                                  _buildTimerUnit(_hoursStr, 'H'),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildTimerUnit(_minsStr, 'M'),
                                  const SizedBox(width: 4),
                                  _buildTimerUnit(_secsStr, 'S'),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // 4. Strikethrough Original Price: ₹300/month
                      const Text(
                        '₹300/month',
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Color(0xFF881337),
                          decorationThickness: 2.2,
                          color: Color(0xFF9E3A4B),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // 5. Huge Promotional Price Display: ₹150 / MONTH
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF881337), Color(0xFFBE123C)],
                            ).createShader(bounds),
                            child: const Text(
                              '₹',
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 0.9,
                              ),
                            ),
                          ),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF881337), Color(0xFFBE123C)],
                            ).createShader(bounds),
                            child: const Text(
                              '150',
                              style: TextStyle(
                                fontSize: 72,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -2,
                                height: 0.92,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PER\nMONTH',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1E1114),
                                  letterSpacing: 0.5,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF881337).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'LOWEST PRICE\nEVER · 50% OFF',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF881337),
                                    height: 1.15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 6. Free vs Premium Selector Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildPlanOptionCard(
                              id: 'free',
                              title: 'Free Plan',
                              priceText: '₹0 / mo',
                              desc: 'Basic Sugar Tracking & Medicine Alarms',
                              isSelected: _selectedPlan == 'free',
                              badgeText: 'STANDARD',
                              accentColor: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildPlanOptionCard(
                              id: 'premium',
                              title: 'DiaCare Plus',
                              priceText: '₹150 / mo',
                              desc: 'AI Calorie Snap, Spikes Alert & Reports',
                              isSelected: _selectedPlan == 'premium',
                              badgeText: '50% OFF',
                              accentColor: const Color(0xFF881337),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 7. Demo Food Snapped Card (Matching Reference Screenshot)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Food Thumbnail Container
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFED7AA), Color(0xFFFDBA74)],
                                ),
                              ),
                              child: const Center(
                                child: Text('🍛', style: TextStyle(fontSize: 32)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.check_rounded, color: Color(0xFF059669), size: 14),
                                      const SizedBox(width: 3),
                                      Text(
                                        'SNAPPED · LOGGED IN 2s',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.green.shade700,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: const [
                                      Text(
                                        '612',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'KCAL',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF881337),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Rajma chawal, one bowl',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 8. Dark Macro Breakdown Pill Card (Matching Screenshot)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1114), // Dark chocolate/wine
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMacroColumn('PROTEIN', '34g', const Color(0xFFEF4444)),
                            _buildMacroColumn('CARBS', '78g', const Color(0xFFF59E0B)),
                            _buildMacroColumn('FAT', '19g', const Color(0xFF10B981)),
                            _buildMacroColumn('MICROS', '23', Colors.white),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 9. Feature Checklist Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildFeatureBullet('Snap to log', const Color(0xFFEF4444))),
                                Expanded(child: _buildFeatureBullet('Calorie tracking', const Color(0xFFF97316))),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: _buildFeatureBullet('Macros + micros', const Color(0xFFBE123C))),
                                Expanded(child: _buildFeatureBullet('AI nutritionist', const Color(0xFF10B981))),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: _buildFeatureBullet('Glucose spikes', const Color(0xFF0284C7))),
                                Expanded(child: _buildFeatureBullet('Doctor PDF reports', const Color(0xFF8B5CF6))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 10. Social Proof Counter
                      const Center(
                        child: Text(
                          '10k+ people joined in last 7 days',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF881337),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 11. Big Pill CTA Button (Matching Screenshot)
                      GestureDetector(
                        onTap: _handleProceed,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1114), // Dark deep wine
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1E1114).withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Circular Arrow Button on Left
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFBE4E7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Color(0xFF1E1114),
                                  size: 20,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _selectedPlan == 'premium'
                                      ? 'SUBSCRIBE @ ₹150'
                                      : 'CONTINUE WITH FREE',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 44), // To balance the arrow circle
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 12. Subtitle: Recurring / Cancel Anytime
                      const Center(
                        child: Text(
                          'RECURRING MONTHLY · CANCEL ANYTIME',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF881337),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Continue with Free Plan Option
                      Center(
                        child: TextButton(
                          onPressed: _handleDismissOrContinueFree,
                          child: const Text(
                            'or Continue with Free Plan',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Timer Digit Widget
  Widget _buildTimerUnit(String val, String unit) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          val,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E1114),
          ),
        ),
        Text(
          unit,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Color(0xFF881337),
          ),
        ),
      ],
    );
  }

  // Plan Option Selector Card (Free vs Premium)
  Widget _buildPlanOptionCard({
    required String id,
    required String title,
    required String priceText,
    required String desc,
    required bool isSelected,
    required String badgeText,
    required Color accentColor,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : Colors.grey.shade300,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: accentColor.withValues(alpha: 0.16),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  size: 18,
                  color: isSelected ? accentColor : Colors.grey.shade400,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              priceText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isSelected ? accentColor : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600, height: 1.2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Macro Column Item
  Widget _buildMacroColumn(String label, String value, Color lineColor) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: Colors.white70,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 32,
          height: 3,
          decoration: BoxDecoration(
            color: lineColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  // Feature Bullet Item
  static Widget _buildFeatureBullet(String text, Color dotColor) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E1114),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
