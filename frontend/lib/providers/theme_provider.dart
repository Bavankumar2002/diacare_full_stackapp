// =============================================================================
// DiaCare - Theme, Localization & Daily Tips Provider
// =============================================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_service.dart';
import '../core/constants.dart';
import '../models/health_tip_model.dart';

class ThemeProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isDarkMode = false;
  String _language = 'en'; // 'en' or 'ta' (Tamil)
  HealthTipModel? _dailyTip;
  bool _isLoadingTip = false;

  bool get isDarkMode => _isDarkMode;
  String get language => _language;
  HealthTipModel? get dailyTip => _dailyTip;
  bool get isLoadingTip => _isLoadingTip;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(AppConstants.keyDarkMode) ?? false;
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool enabled) async {
    _isDarkMode = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyDarkMode, _isDarkMode);
    notifyListeners();
  }

  void setLanguage(String lang) {
    _language = lang;
    notifyListeners();
  }

  /// Fetch daily diabetes health tip
  Future<void> fetchDailyTip() async {
    _isLoadingTip = true;
    notifyListeners();

    final res = await _api.get('api/tips/daily.php');
    _isLoadingTip = false;

    if (res.success && res.data != null && res.data['tip'] != null) {
      _dailyTip = HealthTipModel.fromJson(res.data['tip']);
      notifyListeners();
    } else {
      _dailyTip = HealthTipModel(
        id: 1,
        title: 'Walk After Meals',
        tip: 'A brisk 10 to 15-minute walk after meals helps insulin work more efficiently and significantly reduces post-meal glucose spikes.',
        category: 'Exercise',
      );
      notifyListeners();
    }
  }
}
