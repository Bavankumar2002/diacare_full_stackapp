// =============================================================================
// DiaCare - Blood Sugar Reading Models & Analytics
// =============================================================================

import 'package:flutter/material.dart';
import '../core/constants.dart';

class SugarReadingModel {
  final int id;
  final double readingValue;
  final String readingType; // fasting, before_meal, after_meal, bedtime, random
  final String readingStatus; // Low, Normal, High
  final DateTime measuredAt;
  final String? notes;

  SugarReadingModel({
    required this.id,
    required this.readingValue,
    required this.readingType,
    required this.readingStatus,
    required this.measuredAt,
    this.notes,
  });

  factory SugarReadingModel.fromJson(Map<String, dynamic> json) {
    return SugarReadingModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      readingValue:
          double.tryParse(json['reading_value']?.toString() ?? '0') ?? 0.0,
      readingType: json['reading_type']?.toString() ?? 'fasting',
      readingStatus: json['reading_status']?.toString() ?? 'Normal',
      measuredAt: json['measured_at'] != null
          ? DateTime.tryParse(json['measured_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      notes: json['notes']?.toString(),
    );
  }

  Color get statusColor {
    switch (readingStatus.toLowerCase()) {
      case 'low':
        return AppConstants.statusDanger; // Red warning for hypoglycemia
      case 'normal':
        return AppConstants.statusNormal; // Emerald Green
      case 'high':
        return AppConstants.statusDanger; // High warning
      default:
        return AppConstants.statusNormal;
    }
  }

  String get typeLabel {
    switch (readingType) {
      case 'fasting':
        return 'Fasting';
      case 'before_meal':
        return 'Before Meal';
      case 'after_meal':
        return 'After Meal (PP)';
      case 'bedtime':
        return 'Bedtime';
      default:
        return 'Random';
    }
  }
}

class SugarStatsModel {
  final int count;
  final double? average;
  final double? highest;
  final double? lowest;
  final int lowCount;
  final int normalCount;
  final int highCount;

  SugarStatsModel({
    this.count = 0,
    this.average,
    this.highest,
    this.lowest,
    this.lowCount = 0,
    this.normalCount = 0,
    this.highCount = 0,
  });

  factory SugarStatsModel.fromJson(Map<String, dynamic> json) {
    return SugarStatsModel(
      count: int.tryParse(json['count']?.toString() ?? '0') ?? 0,
      average: json['average'] != null
          ? double.tryParse(json['average'].toString())
          : null,
      highest: json['highest'] != null
          ? double.tryParse(json['highest'].toString())
          : null,
      lowest: json['lowest'] != null
          ? double.tryParse(json['lowest'].toString())
          : null,
      lowCount: int.tryParse(json['low_count']?.toString() ?? '0') ?? 0,
      normalCount: int.tryParse(json['normal_count']?.toString() ?? '0') ?? 0,
      highCount: int.tryParse(json['high_count']?.toString() ?? '0') ?? 0,
    );
  }
}

class SugarAlertModel {
  final bool isDanger;
  final String severity; // 'low' or 'critical_high'
  final String advice;
  final String emergencyName;
  final String emergencyPhone;

  SugarAlertModel({
    required this.isDanger,
    required this.severity,
    required this.advice,
    required this.emergencyName,
    required this.emergencyPhone,
  });

  factory SugarAlertModel.fromJson(Map<String, dynamic> json) {
    return SugarAlertModel(
      isDanger: json['is_danger'] == true,
      severity: json['severity']?.toString() ?? '',
      advice: json['advice']?.toString() ?? '',
      emergencyName: json['emergency_name']?.toString() ?? '',
      emergencyPhone: json['emergency_phone']?.toString() ?? '',
    );
  }
}
