// =============================================================================
// DiaCare - Patient Reminders State Management Provider
// =============================================================================

import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/notification_service.dart';
import '../models/reminder_model.dart';

class ReminderProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  final NotificationService _notifications = NotificationService();

  List<ReminderModel> _reminders = [];
  ReminderModel? _nextReminder;
  bool _isLoading = false;
  String? _errorMessage;

  List<ReminderModel> get reminders => _reminders;
  ReminderModel? get nextReminder => _nextReminder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetch reminders and schedule enabled ones
  Future<void> fetchReminders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _api.get('api/reminders/get.php');
    _isLoading = false;

    if (res.success && res.data != null) {
      final rawList = res.data['reminders'] as List<dynamic>? ?? [];
      _reminders = rawList.map((r) => ReminderModel.fromJson(r)).toList();

      if (res.data['next_reminder'] != null) {
        _nextReminder = ReminderModel.fromJson(res.data['next_reminder']);
      } else {
        _nextReminder = null;
      }

      // Sync active reminders with local notifications
      _syncNotifications();

      notifyListeners();
    } else {
      _errorMessage = res.message;
      notifyListeners();
    }
  }

  /// Create new reminder
  Future<bool> addReminder({
    required String title,
    required String type,
    String? dosage,
    required String time,
    String repeatType = 'daily',
    String repeatDays = '1,2,3,4,5,6,7',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _api.post('api/reminders/add.php', body: {
      'title': title,
      'type': type,
      'dosage': dosage ?? '',
      'time': time,
      'repeat_type': repeatType,
      'repeat_days': repeatDays,
      'is_enabled': 1,
    });

    _isLoading = false;

    if (res.success) {
      await fetchReminders();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  /// Update existing reminder
  Future<bool> updateReminder({
    required int id,
    required String title,
    required String type,
    String? dosage,
    required String time,
    String repeatType = 'daily',
    String repeatDays = '1,2,3,4,5,6,7',
    required bool isEnabled,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _api.post('api/reminders/update.php', body: {
      'id': id,
      'title': title,
      'type': type,
      'dosage': dosage ?? '',
      'time': time,
      'repeat_type': repeatType,
      'repeat_days': repeatDays,
      'is_enabled': isEnabled ? 1 : 0,
    });

    _isLoading = false;

    if (res.success) {
      await fetchReminders();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  /// Toggle reminder on / off
  Future<bool> toggleReminder(int id) async {
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx != -1) {
      // Optimistic update
      final current = _reminders[idx];
      _reminders[idx] = current.copyWith(isEnabled: !current.isEnabled);
      notifyListeners();

      final res = await _api.post('api/reminders/toggle.php', body: {'id': id});
      if (res.success) {
        if (_reminders[idx].isEnabled) {
          _scheduleLocalNotification(_reminders[idx]);
        } else {
          _notifications.cancelNotification(id);
        }
        await fetchReminders();
        return true;
      } else {
        // Rollback
        _reminders[idx] = current;
        _errorMessage = res.message;
        notifyListeners();
        return false;
      }
    }
    return false;
  }

  /// Delete reminder
  Future<bool> deleteReminder(int id) async {
    final res = await _api.post('api/reminders/delete.php', body: {'id': id});
    if (res.success) {
      _notifications.cancelNotification(id);
      _reminders.removeWhere((r) => r.id == id);
      await fetchReminders();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  void _syncNotifications() {
    for (final reminder in _reminders) {
      if (reminder.isEnabled) {
        _scheduleLocalNotification(reminder);
      } else {
        _notifications.cancelNotification(reminder.id);
      }
    }
  }

  void _scheduleLocalNotification(ReminderModel reminder) {
    try {
      final parts = reminder.time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final body = reminder.dosage != null && reminder.dosage!.isNotEmpty
          ? '${reminder.typeLabel}: ${reminder.dosage}'
          : 'Time for your ${reminder.typeLabel.toLowerCase()}!';

      _notifications.scheduleDailyReminder(
        id: reminder.id,
        title: 'DiaCare Reminder: ${reminder.title}',
        body: body,
        hour: hour,
        minute: minute,
      );
    } catch (e) {
      debugPrint('Error scheduling notification for reminder ${reminder.id}: $e');
    }
  }
}
