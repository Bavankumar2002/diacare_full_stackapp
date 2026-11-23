// =============================================================================
// DiaCare - Calorie Tracker & Weekly Nutrition Analytics Screen
// =============================================================================

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/meal_model.dart';
import '../../providers/calorie_provider.dart';
import 'add_meal_screen.dart';

class CalorieTrackerScreen extends StatefulWidget {
  const CalorieTrackerScreen({super.key});

  @override
  State<CalorieTrackerScreen> createState() => _CalorieTrackerScreenState();
}

class _CalorieTrackerScreenState extends State<CalorieTrackerScreen> {
  DateTime _currentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CalorieProvider>().fetchDailySummary(_currentDate);
    });
  }

  void _changeDate(int daysDelta) {
    setState(() {
      _currentDate = _currentDate.add(Duration(days: daysDelta));
    });
    context.read<CalorieProvider>().setDate(_currentDate);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _currentDate = picked);
      if (mounted) context.read<CalorieProvider>().setDate(picked);
    }
  }

  Future<void> _confirmDeleteMeal(MealModel meal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Meal Entry?'),
        content: Text('Remove "${meal.foodName}" (${meal.calories} kcal) from your log?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.statusDanger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<CalorieProvider>().deleteMeal(meal.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final calProv = context.watch<CalorieProvider>();
    final summary = calProv.summary;

    final totalCals = summary?.totalCalories ?? 0;
    final goal = summary?.dailyGoal ?? 1800;
    final remaining = summary?.remainingCalories ?? goal;
    final carbs = summary?.totalCarbs ?? 0.0;
    final double percent = goal > 0 ? (totalCals / goal).clamp(0.0, 1.0) : 0.0;
    final meals = summary?.meals ?? [];

    final bool isToday = DateFormat('yyyy-MM-dd').format(_currentDate) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calorie & Carb Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => calProv.fetchDailySummary(_currentDate),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.restaurant_rounded),
        label: const Text('Add Meal', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddMealScreen(initialDate: _currentDate),
            ),
          );
          calProv.fetchDailySummary(_currentDate);
        },
      ),
      body: RefreshIndicator(
        onRefresh: () => calProv.fetchDailySummary(_currentDate),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Date Selector Navigator
              _buildDateNavigator(isToday),
              const SizedBox(height: 16),

              // 2. Daily Goal Progress Ring Card
              _buildProgressRingCard(totalCals, goal, remaining, carbs, percent),
              const SizedBox(height: 16),

              // 3. Weekly Trend Chart (fl_chart)
              _buildWeeklyChartCard(summary?.weeklyChart ?? []),
              const SizedBox(height: 20),

              // 4. Meal Breakdown List (Breakfast, Lunch, Dinner, Snack)
              _buildMealsSection(meals, calProv),
              const SizedBox(height: 80), // Fab spacing
            ],
          ),
        ),
      ),
    );
  }

  // Date Navigator
  Widget _buildDateNavigator(bool isToday) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => _changeDate(-1),
          ),
          InkWell(
            onTap: _pickDate,
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: AppConstants.primaryTeal),
                const SizedBox(width: 8),
                Text(
                  isToday ? 'Today, ${DateFormat('d MMM').format(_currentDate)}' : DateFormat('EEEE, d MMM yyyy').format(_currentDate),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () => _changeDate(1),
          ),
        ],
      ),
    );
  }

  // Daily Calorie Ring Card
  Widget _buildProgressRingCard(
    int totalCals,
    int goal,
    int remaining,
    double carbs,
    double percent,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Daily Calorie Target',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Goal: $goal kcal',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF065F46),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                // Circular Progress Ring
                SizedBox(
                  width: 90,
                  height: 90,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: percent,
                        strokeWidth: 9,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      ),
                      Center(
                        child: Text(
                          '${(percent * 100).toInt()}%',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$totalCals kcal',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      Text(
                        '$remaining kcal remaining',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Total Carbs: ${carbs.toStringAsFixed(1)} g',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0369A1),
                          ),
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

  // Weekly Nutrition Trend Chart
  Widget _buildWeeklyChartCard(List<WeeklyCaloriePoint> points) {
    if (points.isEmpty) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '7-Day Calorie History (kcal)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  maxY: 2800,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 700,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: const Color(0xFFF1F5F9),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        interval: 700,
                        getTitlesWidget: (val, _) => Text(
                          val.toInt().toString(),
                          style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (val, _) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < points.length) {
                            return Text(
                              points[idx].day,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(points.length, (i) {
                    final p = points[i];
                    final isOver = p.calories > p.goal;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: p.calories.toDouble(),
                          color: isOver ? AppConstants.statusDanger : const Color(0xFF10B981),
                          width: 14,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Meals Section Grouped
  Widget _buildMealsSection(List<MealModel> meals, CalorieProvider calProv) {
    if (meals.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.restaurant_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Text(
                  'No meals logged for this day.',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap "+ Add Meal" to track your breakfast, lunch, dinner, or snacks.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final categories = ['breakfast', 'lunch', 'dinner', 'snack'];
    final titles = {
      'breakfast': '🌅 Breakfast',
      'lunch': '☀️ Lunch',
      'dinner': '🌙 Dinner',
      'snack': '☕ Snacks & Beverages',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categories.map((cat) {
        final catMeals = meals.where((m) => m.mealType.toLowerCase() == cat).toList();
        if (catMeals.isEmpty) return const SizedBox();

        final catCalories = catMeals.fold<int>(0, (sum, m) => sum + m.calories);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    titles[cat]!,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$catCalories kcal',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
                  ),
                ],
              ),
            ),
            ...catMeals.map((meal) => _buildMealItemCard(meal)),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMealItemCard(MealModel meal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr =
        meal.mealTime.length >= 5 ? meal.mealTime.substring(0, 5) : meal.mealTime;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Food Item Image Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 56,
                height: 56,
                child: meal.imageUrl != null && meal.imageUrl!.isNotEmpty
                    ? Image.network(
                        meal.imageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: const Color(0xFFF1F5F9),
                            child: const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            _buildMealFallbackIcon(meal.mealType),
                      )
                    : _buildMealFallbackIcon(meal.mealType),
              ),
            ),
            const SizedBox(width: 12),

            // Food Name & Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.foodName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        '${meal.calories} kcal',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '•',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${meal.carbsG.toStringAsFixed(1)}g carbs',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                      if (timeStr.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          '•',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 11),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Delete Action Button
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFF94A3B8),
                size: 21,
              ),
              tooltip: 'Delete Meal',
              onPressed: () => _confirmDeleteMeal(meal),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealFallbackIcon(String mealType) {
    IconData icon = Icons.restaurant_rounded;
    final t = mealType.toLowerCase();
    if (t == 'breakfast') icon = Icons.breakfast_dining_rounded;
    if (t == 'lunch') icon = Icons.lunch_dining_rounded;
    if (t == 'dinner') icon = Icons.dinner_dining_rounded;
    if (t == 'snack') icon = Icons.local_cafe_rounded;

    return Container(
      color: const Color(0xFFE6FFFA),
      child: Center(
        child: Icon(icon, color: const Color(0xFF0D9488), size: 24),
      ),
    );
  }
}
