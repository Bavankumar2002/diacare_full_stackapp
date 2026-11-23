// =============================================================================
// DiaCare - Food Items Reference Catalog Model
// =============================================================================

class FoodItemModel {
  final int id;
  final String name;
  final String category;
  final String servingSize;
  final int calories;
  final double carbsG;
  final double proteinG;
  final double fatG;
  final String? imageUrl;

  FoodItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.servingSize,
    required this.calories,
    required this.carbsG,
    required this.proteinG,
    required this.fatG,
    this.imageUrl,
  });

  factory FoodItemModel.fromJson(Map<String, dynamic> json) {
    return FoodItemModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      servingSize: json['serving_size']?.toString() ?? '1 serving',
      calories: int.tryParse(json['calories']?.toString() ?? '0') ?? 0,
      carbsG: double.tryParse(json['carbs_g']?.toString() ?? '0') ?? 0.0,
      proteinG: double.tryParse(json['protein_g']?.toString() ?? '0') ?? 0.0,
      fatG: double.tryParse(json['fat_g']?.toString() ?? '0') ?? 0.0,
      imageUrl: json['image_url']?.toString(),
    );
  }
}
