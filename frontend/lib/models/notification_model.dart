// =============================================================================
// DiaCare - Notification Model
// =============================================================================

import 'package:flutter/material.dart';

class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return NotificationModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString().toLowerCase() ?? 'general',
      isRead: json['is_read'] == 1 || json['is_read'] == true || json['is_read'] == '1',
      createdAt: parsedDate,
    );
  }

  IconData get icon {
    switch (type) {
      case 'sugar':
        return Icons.bloodtype_rounded;
      case 'meal':
        return Icons.restaurant_rounded;
      case 'medicine':
        return Icons.medication_rounded;
      case 'tip':
        return Icons.tips_and_updates_rounded;
      case 'alert':
        return Icons.warning_amber_rounded;
      case 'welcome':
        return Icons.favorite_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color get color {
    switch (type) {
      case 'sugar':
        return const Color(0xFFEF4444);
      case 'meal':
        return const Color(0xFF10B981);
      case 'medicine':
        return const Color(0xFF0FA3B1);
      case 'tip':
        return const Color(0xFFF59E0B);
      case 'alert':
        return const Color(0xFFDC2626);
      case 'welcome':
        return const Color(0xFF0FA3B1);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color get bgColor {
    return color.withValues(alpha: 0.12);
  }
}
