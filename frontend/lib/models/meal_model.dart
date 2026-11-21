// =============================================================================
// DiaCare - Daily Meal and Calorie Log Models
// =============================================================================

class MealModel {
  final int id;
  final String mealType; // breakfast, lunch, dinner, snack
  final String foodName;
  final int calories;
  final double carbsG;
  final double servingQuantity;
  final String mealDate;
  final String mealTime;
  final String? notes;

  MealModel({
    required this.id,
    required this.mealType,
    required this.foodName,
    required this.calories,
    required this.carbsG,
    required this.servingQuantity,
    required this.mealDate,
    required this.mealTime,
    this.notes,
  });

  factory MealModel.fromJson(Map<String, dynamic> json) {
    return MealModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      mealType: json['meal_type']?.toString() ?? 'breakfast',
      foodName: json['food_name']?.toString() ?? '',
      calories: int.tryParse(json['calories']?.toString() ?? '0') ?? 0,
      carbsG: double.tryParse(json['carbs_g']?.toString() ?? '0') ?? 0.0,
      servingQuantity:
          double.tryParse(json['serving_quantity']?.toString() ?? '1.0') ?? 1.0,
      mealDate: json['meal_date']?.toString() ?? '',
      mealTime: json['meal_time']?.toString() ?? '',
      notes: json['notes']?.toString(),
    );
  }

  String get typeLabel {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      default:
        return 'Snacks & Beverages';
    }
  }
}

class DailyCalorieSummary {
  final String date;
  final int dailyGoal;
  final int totalCalories;
  final double totalCarbs;
  final int remainingCalories;
  final double percentage;
  final Map<String, int> breakdown;
  final List<MealModel> meals;
  final List<WeeklyCaloriePoint> weeklyChart;

  DailyCalorieSummary({
    required this.date,
    required this.dailyGoal,
    required this.totalCalories,
    required this.totalCarbs,
    required this.remainingCalories,
    required this.percentage,
    required this.breakdown,
    required this.meals,
    required this.weeklyChart,
  });

  factory DailyCalorieSummary.fromJson(Map<String, dynamic> json) {
    final rawBreakdown = json['breakdown'] as Map<String, dynamic>? ?? {};
    final breakdown = {
      'breakfast': int.tryParse(rawBreakdown['breakfast']?.toString() ?? '0') ?? 0,
      'lunch': int.tryParse(rawBreakdown['lunch']?.toString() ?? '0') ?? 0,
      'dinner': int.tryParse(rawBreakdown['dinner']?.toString() ?? '0') ?? 0,
      'snack': int.tryParse(rawBreakdown['snack']?.toString() ?? '0') ?? 0,
    };

    final rawMeals = json['meals'] as List<dynamic>? ?? [];
    final meals = rawMeals.map((m) => MealModel.fromJson(m)).toList();

    final rawChart = json['weekly_chart'] as List<dynamic>? ?? [];
    final weeklyChart =
        rawChart.map((c) => WeeklyCaloriePoint.fromJson(c)).toList();

    return DailyCalorieSummary(
      date: json['date']?.toString() ?? '',
      dailyGoal: int.tryParse(json['daily_goal']?.toString() ?? '1800') ?? 1800,
      totalCalories:
          int.tryParse(json['total_calories']?.toString() ?? '0') ?? 0,
      totalCarbs:
          double.tryParse(json['total_carbs']?.toString() ?? '0') ?? 0.0,
      remainingCalories:
          int.tryParse(json['remaining_calories']?.toString() ?? '0') ?? 0,
      percentage:
          double.tryParse(json['percentage']?.toString() ?? '0') ?? 0.0,
      breakdown: breakdown,
      meals: meals,
      weeklyChart: weeklyChart,
    );
  }
}

class WeeklyCaloriePoint {
  final String date;
  final String day;
  final int calories;
  final double carbsG;
  final int goal;

  WeeklyCaloriePoint({
    required this.date,
    required this.day,
    required this.calories,
    required this.carbsG,
    required this.goal,
  });

  factory WeeklyCaloriePoint.fromJson(Map<String, dynamic> json) {
    return WeeklyCaloriePoint(
      date: json['date']?.toString() ?? '',
      day: json['day']?.toString() ?? '',
      calories: int.tryParse(json['calories']?.toString() ?? '0') ?? 0,
      carbsG: double.tryParse(json['carbs_g']?.toString() ?? '0') ?? 0.0,
      goal: int.tryParse(json['goal']?.toString() ?? '1800') ?? 1800,
    );
  }
}
