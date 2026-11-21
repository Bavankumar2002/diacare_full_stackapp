// =============================================================================
// DiaCare - Daily Diabetes Health Tip Model
// =============================================================================

class HealthTipModel {
  final int id;
  final String title;
  final String tip;
  final String category;

  HealthTipModel({
    required this.id,
    required this.title,
    required this.tip,
    required this.category,
  });

  factory HealthTipModel.fromJson(Map<String, dynamic> json) {
    return HealthTipModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? 'Health Tip',
      tip: json['tip']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
    );
  }
}
