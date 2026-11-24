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

  // Meal suggestions (morning / afternoon / dinner)
  FoodItemModel? _morningSuggestion;
  FoodItemModel? _afternoonSuggestion;
  FoodItemModel? _dinnerSuggestion;
  bool _suggestionsLoading = false;

  DailyCalorieSummary? get summary => _summary;
  List<FoodItemModel> get foodCatalog => _foodCatalog;
  List<String> get foodCategories => _foodCategories;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  FoodItemModel? get morningSuggestion => _morningSuggestion;
  FoodItemModel? get afternoonSuggestion => _afternoonSuggestion;
  FoodItemModel? get dinnerSuggestion => _dinnerSuggestion;
  bool get suggestionsLoading => _suggestionsLoading;

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

  /// Fetch personalized meal suggestions (morning / afternoon / dinner)
  Future<void> fetchMealSuggestions() async {
    _suggestionsLoading = true;
    notifyListeners();

    try {
      final res = await _api.get('api/calories/meal-suggestions.php');

      if (res.success && res.data != null) {
        final m = res.data['morning'];
        final a = res.data['afternoon'];
        final d = res.data['dinner'];
        _morningSuggestion = m != null ? FoodItemModel.fromJson(m) : null;
        _afternoonSuggestion = a != null ? FoodItemModel.fromJson(a) : null;
        _dinnerSuggestion = d != null ? FoodItemModel.fromJson(d) : null;
      }
    } catch (_) {}

    // Graceful fallback if backend was unavailable or returned empty
    if (_morningSuggestion == null && _afternoonSuggestion == null && _dinnerSuggestion == null) {
      _applyFallbackSuggestions();
    }

    _suggestionsLoading = false;
    notifyListeners();
  }

  void _applyFallbackSuggestions() {
    _morningSuggestion = FoodItemModel(
      id: 1,
      name: 'Idli with Vegetable Sambar (2 pcs)',
      category: 'Breakfast',
      servingSize: '2 idlis + 1 cup sambar',
      calories: 210,
      carbsG: 38.0,
      proteinG: 7.5,
      fatG: 2.0,
      imageUrl: 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=300&fit=crop&q=80',
      description: 'Steamed, fermented & gentle on blood sugar',
    );
    _afternoonSuggestion = FoodItemModel(
      id: 2,
      name: 'Multigrain Roti with Dal Tadka & Salad',
      category: 'Lunch/Dinner',
      servingSize: '2 rotis + 1 bowl dal',
      calories: 340,
      carbsG: 45.0,
      proteinG: 12.0,
      fatG: 6.0,
      imageUrl: 'https://images.unsplash.com/photo-1546833998-877b37c2e5c6?w=300&fit=crop&q=80',
      description: 'High-fiber complex carbs for steady energy',
    );
    _dinnerSuggestion = FoodItemModel(
      id: 3,
      name: 'Palak Paneer with Methi Roti',
      category: 'Curries & Sabzi',
      servingSize: '1 bowl curry + 1 roti',
      calories: 280,
      carbsG: 22.0,
      proteinG: 14.0,
      fatG: 11.0,
      imageUrl: 'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=300&fit=crop&q=80',
      description: 'Low carb, nutrient-rich spinach & paneer',
    );
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
