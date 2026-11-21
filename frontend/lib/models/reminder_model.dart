// =============================================================================
// DiaCare - Patient Reminders Model
// =============================================================================

import 'package:flutter/material.dart';

class ReminderModel {
  final int id;
  final String title;
  final String type; // medicine, sugar_check, water, meal, exercise, doctor
  final String? dosage;
  final String time; // HH:MM:SS
  final String repeatType; // daily, weekdays, weekends, custom, once
  final String repeatDays;
  final bool isEnabled;

  ReminderModel({
    required this.id,
    required this.title,
    required this.type,
    this.dosage,
    required this.time,
    this.repeatType = 'daily',
    this.repeatDays = '1,2,3,4,5,6,7',
    this.isEnabled = true,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      type: json['type']?.toString() ?? 'medicine',
      dosage: json['dosage']?.toString(),
      time: json['time']?.toString() ?? '08:00:00',
      repeatType: json['repeat_type']?.toString() ?? 'daily',
      repeatDays: json['repeat_days']?.toString() ?? '1,2,3,4,5,6,7',
      isEnabled: json['is_enabled'] == 1 || json['is_enabled'] == true,
    );
  }

  ReminderModel copyWith({bool? isEnabled}) {
    return ReminderModel(
      id: id,
      title: title,
      type: type,
      dosage: dosage,
      time: time,
      repeatType: repeatType,
      repeatDays: repeatDays,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  IconData get icon {
    switch (type.toLowerCase()) {
      case 'medicine':
        return Icons.medication_rounded;
      case 'sugar_check':
        return Icons.bloodtype_rounded;
      case 'water':
        return Icons.water_drop_rounded;
      case 'meal':
        return Icons.restaurant_rounded;
      case 'exercise':
        return Icons.directions_walk_rounded;
      case 'doctor':
        return Icons.local_hospital_rounded;
      default:
        return Icons.alarm_rounded;
    }
  }

  Color get color {
    switch (type.toLowerCase()) {
      case 'medicine':
        return const Color(0xFF0FA3B1);
      case 'sugar_check':
        return const Color(0xFFEF4444);
      case 'water':
        return const Color(0xFF0284C7);
      case 'meal':
        return const Color(0xFF10B981);
      case 'exercise':
        return const Color(0xFFF59E0B);
      case 'doctor':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF64748B);
    }
  }

  String get typeLabel {
    switch (type.toLowerCase()) {
      case 'medicine':
        return 'Medicine';
      case 'sugar_check':
        return 'Sugar Check';
      case 'water':
        return 'Drink Water';
      case 'meal':
        return 'Meal Time';
      case 'exercise':
        return 'Exercise / Walk';
      case 'doctor':
        return 'Doctor Visit';
      default:
        return 'Reminder';
    }
  }

  String get formattedTime {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final displayMinute = minute.toString().padLeft(2, '0');
      return '$displayHour:$displayMinute $period';
    } catch (_) {
      return time;
    }
  }
}
