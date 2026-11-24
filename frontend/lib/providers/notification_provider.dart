// =============================================================================
// DiaCare - Notification State Management Provider
// =============================================================================

import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetch notifications from backend
  Future<void> fetchNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.get('api/notifications/get.php');

      if (res.success && res.data != null) {
        final rawList = res.data['notifications'] as List<dynamic>? ?? [];
        _notifications = rawList.map((item) => NotificationModel.fromJson(item)).toList();
        _unreadCount = int.tryParse(res.data['unread_count']?.toString() ?? '0') ?? 0;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Mark single notification or all as read
  Future<void> markAsRead([int? id]) async {
    // Optimistic local update
    if (id != null) {
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx != -1 && !_notifications[idx].isRead) {
        _notifications[idx] = NotificationModel(
          id: _notifications[idx].id,
          title: _notifications[idx].title,
          message: _notifications[idx].message,
          type: _notifications[idx].type,
          isRead: true,
          createdAt: _notifications[idx].createdAt,
        );
        _unreadCount = (_unreadCount - 1).clamp(0, 999);
      }
    } else {
      _notifications = _notifications
          .map((n) => NotificationModel(
                id: n.id,
                title: n.title,
                message: n.message,
                type: n.type,
                isRead: true,
                createdAt: n.createdAt,
              ))
          .toList();
      _unreadCount = 0;
    }
    notifyListeners();

    try {
      final body = id != null ? {'id': id} : <String, dynamic>{};
      await _api.post('api/notifications/mark-read.php', body: body);
    } catch (_) {}
  }

  /// Delete a single notification
  Future<void> deleteNotification(int id) async {
    _notifications.removeWhere((n) => n.id == id);
    _recalculateUnread();
    notifyListeners();

    try {
      await _api.post('api/notifications/clear.php', body: {'id': id});
    } catch (_) {}
  }

  /// Clear all notifications
  Future<void> clearAll() async {
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();

    try {
      await _api.post('api/notifications/clear.php');
    } catch (_) {}
  }

  void _recalculateUnread() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }
}
