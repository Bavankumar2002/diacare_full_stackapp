// =============================================================================
// DiaCare - Home Dashboard Screen (Redesigned)
// =============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/food_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/sugar_provider.dart';
import '../../providers/calorie_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/disclaimer_banner.dart';
import '../../widgets/status_badge.dart';
import '../tracker/add_sugar_screen.dart';
import '../tracker/sugar_tracker_screen.dart';
import '../calories/add_meal_screen.dart';
import '../calories/calorie_tracker_screen.dart';
import '../reminders/add_reminder_screen.dart';
import '../reminders/reminders_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/notifications_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    context.read<SugarProvider>().fetchReadings('today');
    context.read<CalorieProvider>().fetchDailySummary(DateTime.now());
    context.read<CalorieProvider>().fetchMealSuggestions();
    context.read<ReminderProvider>().fetchReminders();
    context.read<ThemeProvider>().fetchDailyTip();
    context.read<NotificationProvider>().fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>().profile ?? auth.profile;
    final sugarProv = context.watch<SugarProvider>();
    final calProv = context.watch<CalorieProvider>();
    final remProv = context.watch<ReminderProvider>();
    final themeProv = context.watch<ThemeProvider>();
    final notifProv = context.watch<NotificationProvider>();

    final patientName = profile?.fullName.isNotEmpty == true
        ? profile!.fullName.split(' ').first
        : (auth.user?.name.split(' ').first ?? 'User');

    final patientInitial = patientName.isNotEmpty
        ? patientName.substring(0, 1).toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: const Color(0xFF161920),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppConstants.primaryTeal,
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Prominent Promotional Banner with 3D Gift Box
                _buildPromotionalBanner(context, notifProv),

                // 2. Rounded Dashboard Panel Container
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag Handle Pill
                        Center(
                          child: Container(
                            width: 38,
                            height: 4,
                            margin: const EdgeInsets.only(top: 12, bottom: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        // Top Shortcut Row: Avatar + Name + Calendar
                        _buildTopShortcutBar(context, patientInitial, patientName),
                        const SizedBox(height: 24),

                        // "Your Trackers" Section Heading
                        const Text(
                          'Your Trackers',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tracker 1: Track Food (Calories, Snap Banner, Macros)
                        _buildTrackFoodCard(context, calProv),
                        const SizedBox(height: 20),

                        // Tracker 2: Track Blood Sugar
                        _buildTrackSugarCard(context, sugarProv),
                        const SizedBox(height: 20),

                        // Tracker 3: Medication & Alarms
                        _buildTrackRemindersCard(context, remProv),
                        const SizedBox(height: 28),

                        // Personalized Meal Suggestions
                        _buildMealSuggestionsSection(context, calProv),
                        const SizedBox(height: 28),

                        // Daily Diabetes Health Tip
                        _buildDailyTipCard(themeProv),
                        const SizedBox(height: 26),

                        // Medical Disclaimer Banner
                        const DisclaimerBanner(),
                        const SizedBox(height: 36),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. Promotional Banner (Matches reference screenshot)
  // ===========================================================================
  Widget _buildPromotionalBanner(BuildContext context, NotificationProvider notifProv) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF262C36),
            Color(0xFF161920),
            Color(0xFF0F1115),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Subtle warm glow behind gift box
          Positioned(
            right: -20,
            top: 10,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFEF4444).withValues(alpha: 0.28),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top App Branding + Action Icons Row
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        width: 30,
                        height: 30,
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, e, st) => Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryTeal.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.monitor_heart_rounded,
                            color: AppConstants.primaryTeal,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      AppConstants.appName,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    // Refresh Button
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 22),
                      tooltip: 'Refresh',
                      onPressed: _loadDashboardData,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                    ),
                    const SizedBox(width: 6),
                    // Notification Button with Unread Badge
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                          if (notifProv.unreadCount > 0)
                            Positioned(
                              right: -3,
                              top: -3,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                                child: Text(
                                  notifProv.unreadCount > 9 ? '9+' : notifProv.unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      tooltip: 'Notifications',
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        );
                        _loadDashboardData();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Promotional Banner Content Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Text Column
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Exclusive 2026\nDeal Is Here!',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.2,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Claim your benefits now',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.75),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 14),
                          // "Unlock Deal" CTA Button
                          GestureDetector(
                            onTap: () => _showExclusiveDealSheet(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDE047), // Golden Yellow
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFDE047).withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Unlock Deal',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Carousel Dots Indicator
                          Row(
                            children: [
                              Container(
                                width: 18,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: Colors.white38,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Right 3D Gift Box
                    Expanded(
                      flex: 4,
                      child: Center(
                        child: _build3DGiftBox(),
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

  // Pure-Flutter layered 3D Gift Box matching screenshot visual
  Widget _build3DGiftBox() {
    return Transform.rotate(
      angle: -0.12,
      child: SizedBox(
        width: 116,
        height: 124,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ambient Box Drop Shadow
            Positioned(
              bottom: 4,
              child: Container(
                width: 90,
                height: 14,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.55),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),

            // Main Red Box Body
            Positioned(
              bottom: 8,
              child: Container(
                width: 96,
                height: 86,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFF5252),
                      Color(0xFFE53935),
                      Color(0xFFC62828),
                      Color(0xFF8E0000),
                    ],
                    stops: [0.0, 0.35, 0.75, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Vertical Gold Ribbon Strip
                    Center(
                      child: Container(
                        width: 18,
                        height: 86,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFFFFFBEB),
                              Color(0xFFFDE68A),
                              Color(0xFFF59E0B),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 2,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Horizontal Gold Ribbon Strip
                    Center(
                      child: Container(
                        width: 96,
                        height: 18,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xFFFFFBEB),
                              Color(0xFFFDE68A),
                              Color(0xFFF59E0B),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 2,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3D Gift Box Lid
            Positioned(
              top: 14,
              child: Container(
                width: 104,
                height: 22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFF7675),
                      Color(0xFFD63031),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 20,
                    height: 22,
                    color: const Color(0xFFFDE68A),
                  ),
                ),
              ),
            ),

            // Golden Bow Loops on Top
            Positioned(
              top: 0,
              child: SizedBox(
                width: 80,
                height: 32,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Left Bow Loop
                    Positioned(
                      left: 12,
                      top: 4,
                      child: Transform.rotate(
                        angle: -0.38,
                        child: Container(
                          width: 26,
                          height: 16,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFEF3C7), Color(0xFFFBBF24)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Right Bow Loop
                    Positioned(
                      right: 12,
                      top: 4,
                      child: Transform.rotate(
                        angle: 0.38,
                        child: Container(
                          width: 26,
                          height: 16,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFEF3C7), Color(0xFFFBBF24)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Center Bow Knot
                    Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Color(0xFFFFFBEB), Color(0xFFD97706)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. Top Shortcut Row (Avatar + Calendar)
  // ===========================================================================
  Widget _buildTopShortcutBar(BuildContext context, String patientInitial, String patientName) {
    return Row(
      children: [
        // Profile Avatar Shortcut (Green circle with first initial)
        GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
            _loadDashboardData();
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFF558B2F), // Green as in screenshot
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x22558B2F),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    patientInitial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, $patientName 👋',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Profile & Settings',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const Spacer(),

        // Calendar Shortcut Button
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              builder: (ctx, child) {
                return Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppConstants.primaryTeal,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null && context.mounted) {
              context.read<CalorieProvider>().setDate(picked);
            }
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: Color(0xFF0F766E),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 3. Tracker Card 1: Track Food (Calories, Snap Banner, Macros)
  // ===========================================================================
  Widget _buildTrackFoodCard(BuildContext context, CalorieProvider calProv) {
    final summary = calProv.summary;
    final totalCals = summary?.totalCalories ?? 0;
    final goal = summary?.dailyGoal ?? 2250;
    final totalCarbs = summary?.totalCarbs ?? 0.0;

    // Macro percentages (safe computation)
    final carbPercent = goal > 0 ? math.min(100, ((totalCarbs * 4) / goal * 100).round()) : 0;
    const proteinPercent = 0;
    const fatPercent = 0;
    const fibrePercent = 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CalorieTrackerScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Cutlery Icon + Track Food Title + Camera/Add buttons
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(
                      Icons.restaurant_outlined,
                      color: Color(0xFF1E293B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Track Food',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Eat ${NumberFormat('#,###').format(goal)} cal • $totalCals cal consumed',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Camera / Snap Shortcut Button
                  GestureDetector(
                    onTap: () => _showSnapFoodSheet(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: const Icon(
                        Icons.photo_camera_outlined,
                        size: 20,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Orange Add Button (+)
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddMealScreen()),
                      );
                      _loadDashboardData();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF97316), width: 1.2),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        size: 20,
                        color: Color(0xFFEA580C),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // In-Card Feature Banner: "Auto Track Calories from gallery with Snap"
              GestureDetector(
                onTap: () => _showSnapFoodSheet(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED), // Soft warm peach
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: Row(
                    children: [
                      // Dish Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFED7AA),
                          ),
                          child: const Center(
                            child: Text(
                              '🍛',
                              style: TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Auto Track Calories\nfrom gallery with Snap',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF431407),
                            height: 1.25,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xFFEA580C),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Macros Breakdown Row (2 columns x 2 rows)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Protein: $proteinPercent%',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Carb: $carbPercent%',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Fat: $fatPercent%',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Fibre: $fibrePercent%',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. Tracker Card 2: Track Blood Sugar
  // ===========================================================================
  Widget _buildTrackSugarCard(BuildContext context, SugarProvider sugarProv) {
    final reading = sugarProv.latestReading;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SugarTrackerScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Red Water Drop + Title + Plus Button (+)
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.water_drop_rounded,
                      color: Color(0xFFEF4444),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Track Blood Sugar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Target: 70–140 mg/dL',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  // Add Sugar Button (+)
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddSugarScreen()),
                      );
                      _loadDashboardData();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDFA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppConstants.primaryTeal, width: 1.2),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        size: 20,
                        color: AppConstants.primaryTeal,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Reading Value & Status Display
              if (reading != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      reading.readingValue.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: reading.statusColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'mg/dL',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    StatusBadge(status: reading.readingStatus),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        reading.typeLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      'Measured ${DateFormat('hh:mm a, d MMM').format(reading.measuredAt)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  'No readings logged yet today.',
                  style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddSugarScreen()),
                    );
                    _loadDashboardData();
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Log Fasting Reading'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    backgroundColor: AppConstants.primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 5. Tracker Card 3: Medication & Alarms
  // ===========================================================================
  Widget _buildTrackRemindersCard(BuildContext context, ReminderProvider remProv) {
    final next = remProv.nextReminder;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RemindersScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Alarm Icon + Title + Plus Button (+)
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppConstants.primaryTealLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.alarm_rounded,
                      color: AppConstants.primaryTeal,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Medication & Alarms',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Never miss your dose',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  // Add Reminder Button (+)
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddReminderScreen()),
                      );
                      _loadDashboardData();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDFA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppConstants.primaryTeal, width: 1.2),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        size: 20,
                        color: AppConstants.primaryTeal,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (next != null) ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: next.color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(next.icon, color: next.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            next.title,
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (next.dosage != null && next.dosage!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              next.dosage!,
                              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryTealLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        next.formattedTime,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryTealDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  'No upcoming reminders scheduled today.',
                  style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 6. Personalized Meal Suggestions Section
  // ===========================================================================
  Widget _buildMealSuggestionsSection(BuildContext context, CalorieProvider calProv) {
    final loading = calProv.suggestionsLoading;
    final morning = calProv.morningSuggestion;
    final afternoon = calProv.afternoonSuggestion;
    final dinner = calProv.dinnerSuggestion;

    final slots = [
      (label: 'Morning',   emoji: '🌅', food: morning,   color: const Color(0xFFFFF7ED), accent: const Color(0xFFF97316)),
      (label: 'Afternoon', emoji: '☀️', food: afternoon, color: const Color(0xFFF0FDF4), accent: const Color(0xFF10B981)),
      (label: 'Dinner',    emoji: '🌙', food: dinner,    color: const Color(0xFFEEF2FF), accent: const Color(0xFF6366F1)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '🍽️ Meal Suggestions',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const Spacer(),
            if (!loading)
              GestureDetector(
                onTap: () => calProv.fetchMealSuggestions(),
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 3),
                    Text(
                      'Refresh',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Diabetic-friendly ideas for today',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 14),
        if (loading)
          _buildSuggestionsShimmer()
        else if (morning == null && afternoon == null && dinner == null)
          _buildSuggestionsEmpty(calProv)
        else
          SizedBox(
            height: 228,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: slots.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final slot = slots[i];
                return _buildSuggestionCard(
                  context: context,
                  label: slot.label,
                  emoji: slot.emoji,
                  food: slot.food,
                  bgColor: slot.color,
                  accent: slot.accent,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestionCard({
    required BuildContext context,
    required String label,
    required String emoji,
    required FoodItemModel? food,
    required Color bgColor,
    required Color accent,
  }) {
    final cardWidth = (MediaQuery.of(context).size.width * 0.74).clamp(260.0, 320.0);

    if (food == null) {
      return SizedBox(
        width: cardWidth,
        child: Card(
          color: bgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMealTimeChip(emoji: emoji, label: label, accent: accent),
                const Spacer(),
                Text(
                  'No suggestion available',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final hasImage = food.imageUrl != null && food.imageUrl!.isNotEmpty;
    final String mealTypeParam = label == 'Morning'
        ? 'breakfast'
        : (label == 'Afternoon' ? 'lunch' : 'dinner');

    return SizedBox(
      width: cardWidth,
      child: Card(
        color: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: accent.withValues(alpha: 0.2), width: 1),
        ),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddMealScreen(
                  initialFood: food,
                  initialMealType: mealTypeParam,
                ),
              ),
            );
            _loadDashboardData();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Meal time chip + Log Meal action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMealTimeChip(emoji: emoji, label: label, accent: accent),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 13, color: accent),
                          const SizedBox(width: 2),
                          Text(
                            'Log Meal',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Food thumbnail + name row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 54,
                        height: 54,
                        child: hasImage
                            ? Image.network(
                                food.imageUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder: (ctx, child, progress) {
                                  if (progress == null) return child;
                                  return Container(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (ctx, e, st) => _buildFoodFallback(accent),
                              )
                            : _buildFoodFallback(accent),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            food.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            food.servingSize,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Short description
                Text(
                  food.description ?? 'Balanced diabetic-friendly portion',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),

                // Nutrition pills
                Row(
                  children: [
                    _nutritionPill(
                      icon: Icons.local_fire_department_rounded,
                      value: '${food.calories} kcal',
                      color: const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 8),
                    _nutritionPill(
                      icon: Icons.grain_rounded,
                      value: '${food.carbsG.toStringAsFixed(1)}g carbs',
                      color: const Color(0xFF0284C7),
                    ),
                    if (food.proteinG > 0) ...[
                      const SizedBox(width: 8),
                      _nutritionPill(
                        icon: Icons.fitness_center_rounded,
                        value: '${food.proteinG.toStringAsFixed(1)}g pro',
                        color: const Color(0xFF16A34A),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMealTimeChip({required String emoji, required String label, required Color accent}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$emoji $label',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accent),
      ),
    );
  }

  Widget _nutritionPill({required IconData icon, required String value, required Color color}) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodFallback(Color accent) {
    return Container(
      color: accent.withValues(alpha: 0.1),
      child: Center(child: Icon(Icons.restaurant_rounded, color: accent, size: 24)),
    );
  }

  Widget _buildSuggestionsShimmer() {
    return SizedBox(
      height: 228,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return Container(
            width: (MediaQuery.of(context).size.width * 0.74).clamp(260.0, 320.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuggestionsEmpty(CalorieProvider calProv) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(Icons.restaurant_menu_rounded, size: 36, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'Unable to load meal suggestions.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => calProv.fetchMealSuggestions(),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Load Suggestions', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 7. Daily Diabetes Health Tip
  // ===========================================================================
  Widget _buildDailyTipCard(ThemeProvider themeProv) {
    final tip = themeProv.dailyTip;

    return Card(
      color: const Color(0xFFF0FDF4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFBBF7D0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tips_and_updates_rounded, color: Color(0xFF16A34A), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Daily Health Tip • ${tip?.category ?? 'Diabetes Care'}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15803D),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tip?.title ?? 'Stay Active Daily',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF166534),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tip?.tip ??
                  'A brisk 15-minute walk after lunch or dinner helps muscles absorb glucose and prevents sudden sugar spikes.',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF14532D),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 8. Exclusive Deal Bottom Sheet Modal
  // ===========================================================================
  void _showExclusiveDealSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF08A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFB45309), size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DiaCare Plus 2026 Deal',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          'Exclusive member benefits unlocked',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              _buildDealFeatureItem(
                icon: Icons.camera_alt_rounded,
                title: 'Snap Food Calorie AI',
                desc: 'Instant macro & carbohydrate breakdown from Indian food photos.',
              ),
              const SizedBox(height: 12),
              _buildDealFeatureItem(
                icon: Icons.insights_rounded,
                title: 'Continuous Glucose Insights',
                desc: 'Smart predictive alerts for fasting & post-prandial spikes.',
              ),
              const SizedBox(height: 12),
              _buildDealFeatureItem(
                icon: Icons.picture_as_pdf_rounded,
                title: 'Doctor PDF Clinical Reports',
                desc: 'One-tap export of 30-day sugar charts & medication logs.',
              ),
              const SizedBox(height: 22),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Row(
                  children: [
                    Text('🎉', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Special 2026 Offer: 60% OFF',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF15803D)),
                          ),
                          Text(
                            'Just ₹499/year (Was ₹1,299). Cancel anytime.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF166534)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('DiaCare Plus 2026 offer activated for your account!'),
                      backgroundColor: AppConstants.primaryTeal,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Claim Exclusive 2026 Deal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDealFeatureItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDFA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF0F766E), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(desc, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 9. Snap & Track Food Modal Sheet
  // ===========================================================================
  void _showSnapFoodSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.camera_alt_rounded, color: AppConstants.primaryTeal, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Snap & Auto Track Calories',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Capture or choose Indian food dishes to estimate calories and carbs instantly.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryTealLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppConstants.primaryTeal),
                ),
                title: const Text('Browse 1,000+ Indian Food Catalog', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Select dishes with verified calorie & carb ratings', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddMealScreen()),
                  );
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: Color(0xFFD97706)),
                ),
                title: const Text('Photo AI Food Scanner (Beta)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Point camera at roti, rice, sabzi or dal', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddMealScreen()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
