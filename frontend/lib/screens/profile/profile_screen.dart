// =============================================================================
// DiaCare - Profile & Patient Settings Screen
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../models/profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/disclaimer_banner.dart';
import 'personal_details_screen.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchProfile();
    });
  }

  void _showChangePasswordDialog() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPassController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current Password'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newPassController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password (min 6 chars)'),
                validator: (val) => val == null || val.length < 6 ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmPassController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm New Password'),
                validator: (val) => val != newPassController.text ? 'Passwords do not match' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final auth = context.read<AuthProvider>();
              final success = await auth.changePassword(
                currentPassword: currentPassController.text,
                newPassword: newPassController.text,
              );
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Password updated successfully!' : (auth.errorMessage ?? 'Failed')),
                    backgroundColor: success ? AppConstants.statusNormal : AppConstants.statusDanger,
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showServerSettingsDialog() {
    final api = ApiService();
    final urlController = TextEditingController(text: api.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('API Base URL Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set the host where XAMPP Apache is running.\n• Real Phone (Wi-Fi): http://192.168.1.49/diacare_full_stack/backend\n• Android Emulator: http://10.0.2.2/diacare_full_stack/backend\n• Web / Windows: http://localhost/diacare_full_stack/backend',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(labelText: 'Base URL'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newUrl = urlController.text.trim();
              await api.setBaseUrl(newUrl);
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('API URL updated: $newUrl')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out?'),
        content: const Text('Are you sure you want to log out of DiaCare?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryTeal),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account Permanently?'),
        content: const Text(
          'This will permanently delete your DiaCare account, glucose readings, meal records, and medication reminders. This action CANNOT be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.statusDanger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<AuthProvider>().deleteAccount();
      if (mounted) {
        if (success) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete account.')),
          );
        }
      }
    }
  }

  Future<void> _callEmergencyContact(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri url = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot make call to $phone')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profileProv = context.watch<ProfileProvider>();
    final themeProv = context.watch<ThemeProvider>();

    final profile = profileProv.profile ?? auth.profile;
    final user = auth.user;

    final displayName = profile?.fullName.isNotEmpty == true
        ? profile!.fullName
        : (user?.name ?? 'DiaCare Patient');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            tooltip: 'Edit Profile',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PersonalDetailsScreen(isInitialSetup: false)),
              );
              profileProv.fetchProfile();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Patient Profile Header Card
            _buildProfileHeaderCard(profile, displayName, user?.email ?? ''),
            const SizedBox(height: 16),

            // 2. Health & Medical Summary Card
            _buildMedicalSummaryCard(profile),
            const SizedBox(height: 16),

            // 3. Edit Personal Details Button
            CustomButton(
              text: 'Edit Personal & Medical Details',
              icon: Icons.edit_rounded,
              isOutlined: true,
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PersonalDetailsScreen(isInitialSetup: false)),
                );
                profileProv.fetchProfile();
              },
            ),
            const SizedBox(height: 24),

            // 4. App Preferences Section
            const Text(
              'App Preferences',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Easy on the eyes for night viewing'),
                    secondary: const Icon(Icons.dark_mode_outlined, color: AppConstants.primaryTeal),
                    value: themeProv.isDarkMode,
                    activeThumbColor: AppConstants.primaryTeal,
                    onChanged: (val) => themeProv.toggleDarkMode(val),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.settings_ethernet_rounded, color: AppConstants.primaryTeal),
                    title: const Text('Backend API URL', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(ApiService().baseUrl, style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _showServerSettingsDialog,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.lock_outline_rounded, color: AppConstants.primaryTeal),
                    title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _showChangePasswordDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 5. Medical Disclaimer
            const DisclaimerBanner(),
            const SizedBox(height: 20),

            // 6. Account Actions (Sign Out & Delete Account)
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: Color(0xFF64748B)),
                    title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: _handleLogout,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_forever_rounded, color: AppConstants.statusDanger),
                    title: const Text(
                      'Delete Account & Data',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppConstants.statusDanger),
                    ),
                    onTap: _handleDeleteAccount,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Profile Header Card
  Widget _buildProfileHeaderCard(ProfileModel? profile, String displayName, String email) {
    final bmi = profile?.bmi ?? 0.0;
    final bmiCategory = profile?.bmiCategory ?? 'Normal';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppConstants.primaryTealLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'P',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppConstants.primaryTeal),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 6),
                  if (bmi > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryTealLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'BMI: $bmi ($bmiCategory)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryTealDark,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Medical Summary Card
  Widget _buildMedicalSummaryCard(ProfileModel? profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Medical Profile Overview',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildMedicalRow('Diabetes Type', profile?.diabetesType ?? 'Type 2'),
            const Divider(height: 16),
            _buildMedicalRow(
              'Age & Gender',
              '${profile?.age ?? '--'} yrs • ${profile?.gender ?? '--'}',
            ),
            const Divider(height: 16),
            _buildMedicalRow(
              'Height & Weight',
              '${profile?.heightCm ?? '--'} cm • ${profile?.weightKg ?? '--'} kg',
            ),
            const Divider(height: 16),
            _buildMedicalRow(
              'Current Medications',
              profile?.currentMedicines.isNotEmpty == true ? profile!.currentMedicines : 'None listed',
            ),
            const Divider(height: 16),
            _buildMedicalRow(
              'Doctor / Clinic',
              profile?.doctorName.isNotEmpty == true
                  ? '${profile!.doctorName} (${profile.doctorHospital})'
                  : 'Not added',
            ),
            if (profile?.emergencyContactPhone.isNotEmpty == true) ...[
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Emergency Contact',
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${profile!.emergencyContactName} (${profile.emergencyContactPhone})',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.phone_rounded, color: AppConstants.statusNormal, size: 20),
                    onPressed: () => _callEmergencyContact(profile.emergencyContactPhone),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
