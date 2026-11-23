// =============================================================================
// DiaCare - Calorie & Meal State Management Provider
// =============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/api_service.dart';
import '../models/food_item_model.dart';
import '../models/meal_model.dart';

class CalorieProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  DailyCalorieSummary? _summary;
  List<FoodItemModel> _foodCatalog = [];
  List<String> _foodCategories = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;

  DailyCalorieSummary? get summary => _summary;
  List<FoodItemModel> get foodCatalog => _foodCatalog;
  List<String> get foodCategories => _foodCategories;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get formattedSelectedDate =>
      DateFormat('yyyy-MM-dd').format(_selectedDate);

  void setDate(DateTime date) {
    _selectedDate = date;
    fetchDailySummary(date);
  }

  /// Fetch meal log summary for selected date
  Future<void> fetchDailySummary([DateTime? date]) async {
    if (date != null) {
      _selectedDate = date;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final res = await _api.get('api/calories/get.php', queryParams: {
      'date': dateStr,
    });

    _isLoading = false;

    if (res.success && res.data != null) {
      _summary = DailyCalorieSummary.fromJson(res.data);
      notifyListeners();
    } else {
      _errorMessage = res.message;
      notifyListeners();
    }
  }

  /// Search Indian foods catalog
  Future<void> searchFoods({String query = '', String category = ''}) async {
    final queryParams = <String, dynamic>{};
    if (query.isNotEmpty) queryParams['q'] = query;
    if (category.isNotEmpty) queryParams['category'] = category;

    final res = await _api.get('api/calories/food-items.php',
        queryParams: queryParams);

    if (res.success && res.data != null) {
      final rawFoods = res.data['foods'] as List<dynamic>? ?? [];
      _foodCatalog = rawFoods.map((f) => FoodItemModel.fromJson(f)).toList();

      final rawCats = res.data['categories'] as List<dynamic>? ?? [];
      _foodCategories = rawCats.map((c) => c.toString()).toList();

      notifyListeners();
    }
  }

  /// Add a meal log entry
  Future<bool> addMeal({
    required String mealType,
    required String foodName,
    required int calories,
    double carbsG = 0.0,
    double servingQuantity = 1.0,
    required String date,
    required String time,
    String? notes,
    String? imageUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _api.post('api/calories/add.php', body: {
      'meal_type': mealType,
      'food_name': foodName,
      'calories': calories,
      'carbs_g': carbsG,
      'serving_quantity': servingQuantity,
      'meal_date': date,
      'meal_time': time,
      'notes': notes ?? '',
      'image_url': imageUrl ?? '',
    });

    _isLoading = false;

    if (res.success) {
      await fetchDailySummary(_selectedDate);
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  /// Delete meal entry
  Future<bool> deleteMeal(int id) async {
    final res = await _api.post('api/calories/delete.php', body: {'id': id});
    if (res.success) {
      await fetchDailySummary(_selectedDate);
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }
}
