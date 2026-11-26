// =============================================================================
// DiaCare - Traya-Style Phone Number Login & Sign Up Screen
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/diabetic_illustration.dart';
import '../subscription/premium_offer_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  bool _isPhoneValid = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
  }

  void _onPhoneChanged() {
    final text = _phoneController.text.trim();
    final isValid = text.length == 10 && RegExp(r'^[6-9]\d{9}$').hasMatch(text);
    if (isValid != _isPhoneValid) {
      setState(() {
        _isPhoneValid = isValid;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleGetOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit mobile number'),
          backgroundColor: AppConstants.statusDanger,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.sendOtp(phone);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('OTP sent! Use demo code: ${result['otp'] ?? '1234'}'),
              ),
            ],
          ),
          backgroundColor: AppConstants.primaryTeal,
          duration: const Duration(seconds: 4),
        ),
      );

      // Navigate to Cost / Premium Offer Screen first, which then proceeds to OTP Verification Screen
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              PremiumOfferScreen(
            phone: phone,
            isRegistrationFlow: true,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;
            final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    } else {
      final errorMsg = authProvider.errorMessage ?? 'Unable to send OTP. Check connection.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppConstants.statusDanger,
          action: SnackBarAction(
            label: 'Server IP',
            textColor: Colors.white,
            onPressed: _showServerIpDialog,
          ),
        ),
      );
    }
  }

  void _showServerIpDialog() {
    final apiService = ApiService();
    final ipController = TextEditingController(text: apiService.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Backend Server URL', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Backend API URL (Hosted on GoDaddy):',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ipController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Base URL',
                hintText: 'https://shreetechhub.com/demosite/diacare',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryTeal,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newUrl = ipController.text.trim();
              await apiService.setBaseUrl(newUrl);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Server URL set to: ${apiService.baseUrl}')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 26,
                height: 26,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(
                text: 'DiaCare',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
                children: [
                  TextSpan(
                    text: '.',
                    style: TextStyle(
                      color: AppConstants.primaryTeal,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Server Settings',
            icon: const Icon(Icons.wifi_tethering_rounded, color: Color(0xFF94A3B8)),
            onPressed: _showServerIpDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: size.height - MediaQuery.of(context).padding.top - kToolbarHeight - 20,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Hero Illustration Banner
                  if (!isKeyboardOpen)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Container(
                        height: size.height * 0.32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFE6F7F8),
                              Color(0xFFF0FDF4),
                              Color(0xFFE0F2FE),
                            ],
                          ),
                        ),
                        child: const Center(
                          child: DiabeticIllustration(
                            size: 210,
                            animate: true,
                            showBadges: true,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // 2. Headline
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Diabetes Care Backed by Science',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                        height: 1.25,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Log in or Sign up Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Row(
                      children: [
                        const Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'Log in or Sign up',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B).withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. Mobile Number Input Box (+91 | Mobile number)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _phoneFocusNode.hasFocus
                              ? AppConstants.primaryTeal
                              : const Color(0xFFCBD5E1),
                          width: _phoneFocusNode.hasFocus ? 1.8 : 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          // +91 Prefix container
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: const Text(
                              '+91',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          // Subtle vertical separator
                          Container(
                            height: 26,
                            width: 1.2,
                            color: const Color(0xFFE2E8F0),
                          ),
                          const SizedBox(width: 12),
                          // Phone Input Field
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              focusNode: _phoneFocusNode,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                                letterSpacing: 1.2,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Mobile number',
                                hintStyle: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 0,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onFieldSubmitted: (_) {
                                if (_isPhoneValid) _handleGetOtp();
                              },
                            ),
                          ),
                          if (_phoneController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: Color(0xFF94A3B8)),
                              onPressed: () {
                                _phoneController.clear();
                                setState(() => _isPhoneValid = false);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 5. "Get OTP" Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isPhoneValid
                              ? AppConstants.primaryTeal
                              : const Color(0xFFE2E8F0),
                          foregroundColor: _isPhoneValid
                              ? Colors.white
                              : const Color(0xFF94A3B8),
                          elevation: _isPhoneValid ? 2 : 0,
                          shadowColor: AppConstants.primaryTeal.withValues(alpha: 0.35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: (_isPhoneValid && !_isLoading) ? _handleGetOtp : null,
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
                                'Get OTP',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // 6. Consent & Privacy Disclaimer
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
                    child: Column(
                      children: [
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            text: 'By proceeding, you consent to share your information with DiaCare and agree to DiaCare’s ',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              height: 1.45,
                            ),
                            children: const [
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              TextSpan(text: '.'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppConstants.medicalDisclaimer,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: const Color(0xFF94A3B8).withValues(alpha: 0.9),
                            height: 1.3,
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
    );
  }
}
