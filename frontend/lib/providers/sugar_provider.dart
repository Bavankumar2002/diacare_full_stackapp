// =============================================================================
// DiaCare - Blood Sugar State Management Provider
// =============================================================================

import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/notification_service.dart';
import '../models/sugar_reading_model.dart';

class SugarProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  final NotificationService _notifications = NotificationService();

  List<SugarReadingModel> _readings = [];
  SugarStatsModel _stats = SugarStatsModel();
  SugarReadingModel? _latestReading;
  String _selectedPeriod = 'all'; // all, today, week, month
  bool _isLoading = false;
  String? _errorMessage;

  List<SugarReadingModel> get readings => _readings;
  SugarStatsModel get stats => _stats;
  SugarReadingModel? get latestReading => _latestReading;
  String get selectedPeriod => _selectedPeriod;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetch readings and stats filtered by period
  Future<void> fetchReadings([String? period]) async {
    if (period != null) {
      _selectedPeriod = period;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _api.get('api/sugar/get.php', queryParams: {
      'period': _selectedPeriod,
    });

    _isLoading = false;

    if (res.success && res.data != null) {
      final rawList = res.data['readings'] as List<dynamic>? ?? [];
      _readings = rawList.map((r) => SugarReadingModel.fromJson(r)).toList();

      if (res.data['stats'] != null) {
        _stats = SugarStatsModel.fromJson(res.data['stats']);
      }

      if (res.data['latest'] != null) {
        _latestReading = SugarReadingModel.fromJson(res.data['latest']);
      } else if (_readings.isNotEmpty) {
        _latestReading = _readings.first;
      } else {
        _latestReading = null;
      }

      notifyListeners();
    } else {
      _errorMessage = res.message;
      notifyListeners();
    }
  }

  /// Add new glucose reading
  Future<SugarAlertModel?> addReading({
    required double value,
    required String type,
    required String date,
    required String time,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _api.post('api/sugar/add.php', body: {
      'reading_value': value,
      'reading_type': type,
      'date': date,
      'time': time,
      'notes': notes ?? '',
    });

    _isLoading = false;

    if (res.success && res.data != null) {
      // Refresh readings list & statistics
      await fetchReadings(_selectedPeriod);

      SugarAlertModel? alert;
      if (res.data['alert'] != null) {
        alert = SugarAlertModel.fromJson(res.data['alert']);

        if (alert.isDanger) {
          // Trigger urgent local notification alert
          await _notifications.showInstantNotification(
            id: DateTime.now().millisecondsSinceEpoch % 100000,
            title: alert.severity == 'low'
                ? '⚠️ Glucose Alert: Low Blood Sugar (${value.toStringAsFixed(0)} mg/dL)'
                : '⚠️ Glucose Alert: High Blood Sugar (${value.toStringAsFixed(0)} mg/dL)',
            body: alert.advice,
            isUrgent: true,
          );
        }
      }

      notifyListeners();
      return alert;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return null;
    }
  }

  /// Delete reading
  Future<bool> deleteReading(int id) async {
    final res = await _api.post('api/sugar/delete.php', body: {'id': id});
    if (res.success) {
      _readings.removeWhere((r) => r.id == id);
      await fetchReadings(_selectedPeriod);
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }
}
