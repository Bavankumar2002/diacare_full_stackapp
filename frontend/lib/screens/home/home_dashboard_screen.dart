// =============================================================================
// DiaCare - Home Dashboard Screen
// =============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/sugar_provider.dart';
import '../../providers/calorie_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/disclaimer_banner.dart';
import '../../widgets/status_badge.dart';
import '../tracker/add_sugar_screen.dart';
import '../calories/add_meal_screen.dart';
import '../reminders/add_reminder_screen.dart';

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
    context.read<ReminderProvider>().fetchReminders();
    context.read<ThemeProvider>().fetchDailyTip();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>().profile ?? auth.profile;
    final sugarProv = context.watch<SugarProvider>();
    final calProv = context.watch<CalorieProvider>();
    final remProv = context.watch<ReminderProvider>();
    final themeProv = context.watch<ThemeProvider>();

    final patientName = profile?.fullName.isNotEmpty == true
        ? profile!.fullName.split(' ').first
        : (auth.user?.name.split(' ').first ?? 'Friend');

    final todayStr = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppConstants.primaryTealLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.monitor_heart_rounded, color: AppConstants.primaryTeal, size: 24),
            ),
            const SizedBox(width: 10),
            const Text(
              AppConstants.appName,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Dashboard',
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Personalized Greeting & Date
              Text(
                '${_getGreeting()}, $patientName! 👋',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    todayStr,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 2. Quick-Add Action Buttons Row
              _buildQuickActionsRow(context),
              const SizedBox(height: 18),

              // 3. Latest Blood Sugar Card
              _buildLatestSugarCard(context, sugarProv),
              const SizedBox(height: 14),

              // 4. Today's Calorie Summary Card
              _buildCalorieCard(context, calProv),
              const SizedBox(height: 14),

              // 5. Next Medicine / Checkup Reminder Card
              _buildNextReminderCard(context, remProv),
              const SizedBox(height: 14),

              // 6. Daily Diabetes Health Tip
              _buildDailyTipCard(themeProv),
              const SizedBox(height: 14),

              // 7. Medical Disclaimer
              const DisclaimerBanner(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Quick Action Buttons
  Widget _buildQuickActionsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            label: '+ Sugar',
            icon: Icons.bloodtype_rounded,
            color: const Color(0xFFEF4444),
            bgColor: const Color(0xFFFEE2E2),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddSugarScreen()),
              );
              _loadDashboardData();
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildQuickActionButton(
            label: '+ Meal',
            icon: Icons.restaurant_rounded,
            color: const Color(0xFF10B981),
            bgColor: const Color(0xFFD1FAE5),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddMealScreen()),
              );
              _loadDashboardData();
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildQuickActionButton(
            label: '+ Reminder',
            icon: Icons.alarm_add_rounded,
            color: AppConstants.primaryTeal,
            bgColor: AppConstants.primaryTealLight,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddReminderScreen()),
              );
              _loadDashboardData();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Latest Blood Sugar Card
  Widget _buildLatestSugarCard(BuildContext context, SugarProvider sugarProv) {
    final reading = sugarProv.latestReading;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.water_drop_rounded, color: Color(0xFFEF4444), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Latest Blood Sugar',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (reading != null)
                  StatusBadge(status: reading.readingStatus),
              ],
            ),
            const SizedBox(height: 14),

            if (reading != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    reading.readingValue.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: reading.statusColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'mg/dL',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
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
                  Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade500),
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
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 10),
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
                  minimumSize: const Size.fromHeight(42),
                  backgroundColor: AppConstants.primaryTeal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Today's Calorie Summary Card
  Widget _buildCalorieCard(BuildContext context, CalorieProvider calProv) {
    final summary = calProv.summary;
    final totalCals = summary?.totalCalories ?? 0;
    final goal = summary?.dailyGoal ?? 1800;
    final remaining = summary?.remainingCalories ?? goal;
    final double percent = goal > 0 ? (totalCals / goal).clamp(0.0, 1.0) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.local_fire_department_rounded, color: Color(0xFF10B981), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Today's Calories",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  'Goal: $goal kcal',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Circular Progress Ring
                SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: percent,
                        strokeWidth: 8,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      ),
                      Center(
                        child: Text(
                          '${(percent * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$totalCals kcal consumed',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$remaining kcal remaining today',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Carbs: ${summary?.totalCarbs.toStringAsFixed(1) ?? 0.0} g',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0284C7),
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
    );
  }

  // Next Medicine Reminder Card
  Widget _buildNextReminderCard(BuildContext context, ReminderProvider remProv) {
    final next = remProv.nextReminder;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryTealLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.alarm_rounded, color: AppConstants.primaryTeal, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Next Reminder',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                    child: Icon(next.icon, color: next.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          next.title,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        if (next.dosage != null && next.dosage!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            next.dosage!,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryTealLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      next.formattedTime,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryTealDark,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'No upcoming reminders scheduled.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Daily Diabetes Health Tip
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
                Text(
                  'Daily Health Tip • ${tip?.category ?? 'Diabetes Care'}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF15803D),
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
}
