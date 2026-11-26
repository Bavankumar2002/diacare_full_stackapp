// =============================================================================
// DiaCare - 4-Digit OTP Verification Screen (Static OTP: 1234)
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../profile/personal_details_screen.dart';
import '../main_navigation_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phone;
  final String selectedPlan;

  const OtpVerificationScreen({
    super.key,
    required this.phone,
    this.selectedPlan = 'free',
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  int _resendCountdown = 30;
  Timer? _timer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _resendCountdown = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _enteredOtp => _controllers.map((c) => c.text).join();

  void _autoFillDemoOtp() {
    const demo = '1234';
    for (int i = 0; i < 4; i++) {
      _controllers[i].text = demo[i];
    }
    _focusNodes.last.unfocus();
    setState(() {});
  }

  Future<void> _handleResendOtp() async {
    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.sendOtp(widget.phone);

    if (!mounted) return;

    if (result != null) {
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New OTP sent! Code is 1234'),
          backgroundColor: AppConstants.primaryTeal,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Failed to resend OTP.'),
          backgroundColor: AppConstants.statusDanger,
        ),
      );
    }
  }

  Future<void> _handleVerify() async {
    final otp = _enteredOtp;
    if (otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter all 4 digits of the OTP'),
          backgroundColor: AppConstants.statusDanger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyOtp(
      phone: widget.phone,
      otp: otp,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_subscription_plan', widget.selectedPlan);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.selectedPlan == 'premium'
                ? 'Welcome to DiaCare Plus! 50% Festive Offer (₹150/mo) active.'
                : 'Mobile verified successfully! Welcome to DiaCare.',
          ),
          backgroundColor: AppConstants.statusNormal,
        ),
      );

      // Check if user has completed profile setup
      if (!authProvider.hasProfile) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const PersonalDetailsScreen(isInitialSetup: true),
          ),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const MainNavigationScreen(),
          ),
          (route) => false,
        );
      }
    } else {
      final msg = authProvider.errorMessage ?? 'Invalid OTP. Please enter 1234.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppConstants.statusDanger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final otp = _enteredOtp;
    final isOtpComplete = otp.length == 4;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Verification',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              // Friendly Header Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryTealLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_rounded,
                    color: AppConstants.primaryTeal,
                    size: 40,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Title
              const Text(
                'Enter Verification Code',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle with Phone Number
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sent to +91 ${widget.phone}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Change',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppConstants.primaryTeal,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Demo OTP Helper Banner (Static 1234)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.key_rounded, color: Color(0xFF16A34A), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Demo Static OTP',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF166534),
                            ),
                          ),
                          Text(
                            'Your 4-digit code is 1234',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF14532D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFDCFCE7),
                        foregroundColor: const Color(0xFF15803D),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _autoFillDemoOtp,
                      icon: const Icon(Icons.touch_app_rounded, size: 16),
                      label: const Text(
                        'Auto Fill',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 4 Individual OTP Input Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) {
                  return SizedBox(
                    width: 62,
                    height: 68,
                    child: TextFormField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: _controllers[index].text.isNotEmpty
                            ? AppConstants.primaryTealLight.withValues(alpha: 0.5)
                            : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: _controllers[index].text.isNotEmpty
                                ? AppConstants.primaryTeal
                                : const Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppConstants.primaryTeal,
                            width: 2.2,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {});
                        if (value.isNotEmpty) {
                          if (index < 3) {
                            _focusNodes[index + 1].requestFocus();
                          } else {
                            _focusNodes[index].unfocus();
                            _handleVerify();
                          }
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),

              const SizedBox(height: 28),

              // Resend OTP / Timer
              Center(
                child: _resendCountdown > 0
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text(
                            'Resend OTP in ${_resendCountdown}s',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    : TextButton(
                        onPressed: _handleResendOtp,
                        child: const Text(
                          'Resend OTP',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.primaryTeal,
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 32),

              // "Verify & Proceed" Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOtpComplete
                        ? AppConstants.primaryTeal
                        : const Color(0xFFE2E8F0),
                    foregroundColor: isOtpComplete
                        ? Colors.white
                        : const Color(0xFF94A3B8),
                    elevation: isOtpComplete ? 2 : 0,
                    shadowColor: AppConstants.primaryTeal.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: (isOtpComplete && !_isLoading) ? _handleVerify : null,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Verify & Proceed',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
