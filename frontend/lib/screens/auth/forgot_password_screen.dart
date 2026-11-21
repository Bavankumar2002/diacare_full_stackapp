// =============================================================================
// DiaCare - Forgot Password Screen
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _identifierController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _step = 1; // 1 = Request code, 2 = Verify & Reset
  bool _obscureNewPass = true;
  String? _generatedCodeHint;

  @override
  void dispose() {
    _identifierController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRequestCode() async {
    final identifier = _identifierController.text.trim();
    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email or phone number.')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final data = await auth.forgotPasswordRequest(identifier);

    if (!mounted) return;

    if (data != null) {
      setState(() {
        _step = 2;
        _generatedCodeHint = data['reset_code']?.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification code generated: ${_generatedCodeHint ?? ''}'),
          backgroundColor: AppConstants.statusNormal,
          duration: const Duration(seconds: 8),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Failed to send reset code.'),
          backgroundColor: AppConstants.statusDanger,
        ),
      );
    }
  }

  Future<void> _handleResetPassword() async {
    final code = _codeController.text.trim();
    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (code.isEmpty || newPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the code and your new password.')),
      );
      return;
    }

    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password must be at least 6 characters.')),
      );
      return;
    }

    if (newPass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.forgotPasswordReset(
      identifier: _identifierController.text.trim(),
      code: code,
      newPassword: newPass,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successfully! Please log in with your new password.'),
          backgroundColor: AppConstants.statusNormal,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Password reset failed.'),
          backgroundColor: AppConstants.statusDanger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppConstants.primaryTealLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  size: 34,
                  color: AppConstants.primaryTeal,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _step == 1 ? 'Forgot Your Password?' : 'Create New Password',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _step == 1
                    ? 'Enter your registered email or phone. We will provide a 6-digit verification code to reset your password.'
                    : 'Enter the 6-digit verification code and set your new secure password.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
              ),
              const SizedBox(height: 28),

              if (_step == 1) ...[
                CustomTextField(
                  controller: _identifierController,
                  label: 'Registered Email or Phone',
                  hint: 'e.g. patient@gmail.com or 9876543210',
                  prefixIcon: Icons.account_circle_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Send Verification Code',
                  icon: Icons.send_rounded,
                  isLoading: auth.isLoading,
                  onPressed: _handleRequestCode,
                ),
              ] else ...[
                if (_generatedCodeHint != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.vpn_key_rounded, color: AppConstants.statusNormal, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your Demo Verification Code: $_generatedCodeHint',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                CustomTextField(
                  controller: _codeController,
                  label: '6-Digit Verification Code',
                  hint: 'e.g. 123456',
                  prefixIcon: Icons.security_rounded,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _newPasswordController,
                  label: 'New Password',
                  hint: 'At least 6 characters',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _obscureNewPass,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: const Color(0xFF64748B),
                    ),
                    onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
                  ),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm New Password',
                  hint: 'Re-enter new password',
                  prefixIcon: Icons.lock_reset_rounded,
                  obscureText: _obscureNewPass,
                ),
                const SizedBox(height: 24),

                CustomButton(
                  text: 'Update Password & Log In',
                  icon: Icons.check_circle_rounded,
                  isLoading: auth.isLoading,
                  onPressed: _handleResetPassword,
                ),
                const SizedBox(height: 12),

                TextButton(
                  onPressed: () => setState(() => _step = 1),
                  child: const Center(
                    child: Text('Change Email / Phone Number'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
