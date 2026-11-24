// =============================================================================
// DiaCare - Redesigned Profile & Patient Settings Screen
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../models/profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/disclaimer_banner.dart';
import 'edit_profile_screen.dart';
import '../auth/phone_login_screen.dart';

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

  Future<void> _navigateToEditProfile() async {
    final profileProv = context.read<ProfileProvider>();
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const EditProfileScreen(),
      ),
    );
    if (updated == true && mounted) {
      await profileProv.fetchProfile();
      if (mounted) setState(() {});
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out of DiaCare?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
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
          MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Account Permanently?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'This will permanently delete your DiaCare account, glucose readings, meal records, and medication reminders. This action CANNOT be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.statusDanger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
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
            MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
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
        title: const Text(
          'Profile & Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            tooltip: 'Edit Profile',
            onPressed: _navigateToEditProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Patient Profile Header Card
            _buildProfileHeaderCard(context, profile, displayName, user?.email ?? ''),
            const SizedBox(height: 18),

            // 2. Health & Medical Summary Card
            _buildMedicalSummaryCard(context, profile),
            const SizedBox(height: 16),

            // 3. Prominent, Accessible Edit Personal & Medical Details Button
            CustomButton(
              text: 'Edit Personal & Medical Details',
              icon: Icons.edit_rounded,
              backgroundColor: AppConstants.primaryTeal,
              height: 52,
              onPressed: _navigateToEditProfile,
            ),
            const SizedBox(height: 24),

            // 4. App Preferences Section
            _buildAppPreferencesSection(context, themeProv),
            const SizedBox(height: 20),

            // 5. Account & Security Section
            _buildAccountActionsSection(context),
            const SizedBox(height: 20),

            // 6. Medical Disclaimer Banner
            const DisclaimerBanner(),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. POLISHED PATIENT PROFILE HEADER CARD
  // ===========================================================================
  Widget _buildProfileHeaderCard(
    BuildContext context,
    ProfileModel? profile,
    String displayName,
    String email,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bmi = profile?.bmi ?? 0.0;
    final bmiCategory = profile?.bmiCategory ?? 'Normal';

    // Dynamic BMI color styling
    Color bmiColor = const Color(0xFF10B981); // Emerald
    Color bmiBg = const Color(0xFFECFDF5);
    Color bmiBorder = const Color(0xFFA7F3D0);

    if (bmi >= 25.0 && bmi <= 29.9) {
      bmiColor = const Color(0xFFD97706); // Amber
      bmiBg = const Color(0xFFFFFBEB);
      bmiBorder = const Color(0xFFFDE68A);
    } else if (bmi >= 30.0) {
      bmiColor = const Color(0xFFDC2626); // Red
      bmiBg = const Color(0xFFFEF2F2);
      bmiBorder = const Color(0xFFFECACA);
    } else if (bmi > 0 && bmi < 18.5) {
      bmiColor = const Color(0xFF0284C7); // Sky Blue
      bmiBg = const Color(0xFFF0F9FF);
      bmiBorder = const Color(0xFFBAE6FD);
    }

    if (isDark) {
      bmiBg = bmiColor.withValues(alpha: 0.15);
      bmiBorder = bmiColor.withValues(alpha: 0.35);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar with subtle teal border ring
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE0F7FA), Color(0xFFCCFBF1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppConstants.primaryTeal.withValues(alpha: 0.35),
                width: 2.5,
              ),
            ),
            child: Center(
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'P',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppConstants.primaryTealDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // User info and badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),

                // BMI Status Badge
                if (bmi > 0)
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: bmiBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: bmiBorder, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.monitor_weight_outlined, size: 13, color: bmiColor),
                            const SizedBox(width: 4),
                            Text(
                              'BMI: $bmi ($bmiCategory)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: bmiColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. STRUCTURED MEDICAL PROFILE OVERVIEW CARD
  // ===========================================================================
  Widget _buildMedicalSummaryCard(BuildContext context, ProfileModel? profile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasEmergency = profile?.emergencyContactPhone.isNotEmpty == true;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Title Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryTealLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.health_and_safety_rounded,
                    color: AppConstants.primaryTeal,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Medical Profile Overview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Key health details and clinical records',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Clinical Summary Items
            _buildDetailTile(
              context: context,
              icon: Icons.water_drop_rounded,
              iconColor: const Color(0xFF0FA3B1),
              label: 'Diabetes Classification',
              value: profile?.diabetesType.isNotEmpty == true
                  ? profile!.diabetesType
                  : 'Type 2',
            ),
            _buildDivider(),

            _buildDetailTile(
              context: context,
              icon: Icons.person_rounded,
              iconColor: const Color(0xFF6366F1),
              label: 'Age & Gender',
              value: (profile?.age ?? 0) > 0 && (profile?.gender.isNotEmpty == true)
                  ? '${profile!.age} yrs • ${profile.gender}'
                  : 'Not provided',
            ),
            _buildDivider(),

            _buildDetailTile(
              context: context,
              icon: Icons.straighten_rounded,
              iconColor: const Color(0xFF0284C7),
              label: 'Height & Weight',
              value: (profile?.heightCm ?? 0) > 0 && (profile?.weightKg ?? 0) > 0
                  ? '${profile!.heightCm} cm • ${profile.weightKg} kg'
                  : 'Not provided',
            ),
            _buildDivider(),

            _buildDetailTile(
              context: context,
              icon: Icons.medication_rounded,
              iconColor: const Color(0xFF10B981),
              label: 'Current Medications',
              value: profile?.currentMedicines.isNotEmpty == true
                  ? profile!.currentMedicines
                  : 'None listed',
            ),
            _buildDivider(),

            _buildDetailTile(
              context: context,
              icon: Icons.local_hospital_rounded,
              iconColor: const Color(0xFFF59E0B),
              label: 'Doctor / Clinic',
              value: profile?.doctorName.isNotEmpty == true
                  ? (profile!.doctorHospital.isNotEmpty
                      ? '${profile.doctorName} (${profile.doctorHospital})'
                      : profile.doctorName)
                  : 'Not added',
            ),
            const SizedBox(height: 14),

            // Integrated Emergency Contact Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2E191C) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF5B2228) : const Color(0xFFFECACA),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.phone_in_talk_rounded,
                      color: Color(0xFFDC2626),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EMERGENCY CONTACT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasEmergency
                              ? '${profile!.emergencyContactName} (${profile.emergencyContactPhone})'
                              : 'No emergency contact set',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (hasEmergency)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.phone_rounded, size: 14),
                      label: const Text(
                        'Call',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _callEmergencyContact(profile!.emergencyContactPhone),
                    )
                  else
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: _navigateToEditProfile,
                      child: const Text(
                        'Add',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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

  // ===========================================================================
  // 3. APP PREFERENCES SECTION (VISUALLY CONSISTENT WITH MEDICAL CARD)
  // ===========================================================================
  Widget _buildAppPreferencesSection(BuildContext context, ThemeProvider themeProv) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppConstants.primaryTealLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: AppConstants.primaryTeal,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'App Preferences',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // Dark Mode Switch
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                secondary: _buildIconBox(
                  icon: Icons.dark_mode_outlined,
                  color: const Color(0xFF6366F1),
                  isDark: isDark,
                ),
                title: const Text(
                  'Dark Mode',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Easy on the eyes for night viewing',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                value: themeProv.isDarkMode,
                activeThumbColor: AppConstants.primaryTeal,
                onChanged: (val) => themeProv.toggleDarkMode(val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 4. ACCOUNT & SECURITY SECTION
  // ===========================================================================
  Widget _buildAccountActionsSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: _buildIconBox(
              icon: Icons.logout_rounded,
              color: const Color(0xFF64748B),
              isDark: isDark,
            ),
            title: const Text(
              'Sign Out',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Log out from this device',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            onTap: _handleLogout,
          ),
          _buildListDivider(),

          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: _buildIconBox(
              icon: Icons.delete_forever_rounded,
              color: AppConstants.statusDanger,
              isDark: isDark,
            ),
            title: const Text(
              'Delete Account & Data',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppConstants.statusDanger,
              ),
            ),
            subtitle: const Text(
              'Permanently delete records and health data',
              style: TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppConstants.statusDanger),
            onTap: _handleDeleteAccount,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // REUSABLE UI HELPERS
  // ===========================================================================
  Widget _buildDetailTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMuted = value == 'Not added' || value == 'None listed' || value == 'Not provided';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isMuted ? FontWeight.w500 : FontWeight.w700,
                    color: isMuted
                        ? Colors.grey.shade500
                        : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    fontStyle: isMuted ? FontStyle.italic : FontStyle.normal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconBox({
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 19, color: color),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Divider(height: 1, thickness: 0.7, color: Color(0xFFF1F5F9)),
    );
  }

  Widget _buildListDivider() {
    return const Divider(height: 1, thickness: 0.7, indent: 68, color: Color(0xFFF1F5F9));
  }
}
