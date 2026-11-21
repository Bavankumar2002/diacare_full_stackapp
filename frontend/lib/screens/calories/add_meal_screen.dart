// =============================================================================
// DiaCare - Add Meal with Built-in Indian Food Catalog
// =============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/food_item_model.dart';
import '../../providers/calorie_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddMealScreen extends StatefulWidget {
  final DateTime? initialDate;

  const AddMealScreen({super.key, this.initialDate});

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _foodNameController = TextEditingController();
  final _caloriesController = TextEditingController(text: '200');
  final _carbsController = TextEditingController(text: '30');
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();

  String _mealType = 'breakfast';
  double _servingQuantity = 1.0;
  late DateTime _mealDate;
  final TimeOfDay _mealTime = TimeOfDay.now();

  FoodItemModel? _selectedCatalogItem;

  final List<Map<String, String>> _mealTypes = [
    {'key': 'breakfast', 'label': '🌅 Breakfast'},
    {'key': 'lunch', 'label': '☀️ Lunch'},
    {'key': 'dinner', 'label': '🌙 Dinner'},
    {'key': 'snack', 'label': '☕ Snack / Drink'},
  ];

  @override
  void initState() {
    super.initState();
    _mealDate = widget.initialDate ?? DateTime.now();
    // Default meal type based on hour
    final hour = DateTime.now().hour;
    if (hour < 11) {
      _mealType = 'breakfast';
    } else if (hour < 16) {
      _mealType = 'lunch';
    } else if (hour < 21) {
      _mealType = 'dinner';
    } else {
      _mealType = 'snack';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CalorieProvider>().searchFoods();
    });
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _caloriesController.dispose();
    _carbsController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onFoodSelected(FoodItemModel food) {
    setState(() {
      _selectedCatalogItem = food;
      _foodNameController.text = food.name;
      _caloriesController.text =
          (food.calories * _servingQuantity).round().toString();
      _carbsController.text =
          (food.carbsG * _servingQuantity).toStringAsFixed(1);
    });
  }

  void _updateServingQuantity(double qty) {
    setState(() {
      _servingQuantity = qty;
      if (_selectedCatalogItem != null) {
        _caloriesController.text =
            (_selectedCatalogItem!.calories * _servingQuantity).round().toString();
        _carbsController.text =
            (_selectedCatalogItem!.carbsG * _servingQuantity).toStringAsFixed(1);
      }
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final foodName = _foodNameController.text.trim();
    final calories = int.tryParse(_caloriesController.text.trim()) ?? 0;
    final carbs = double.tryParse(_carbsController.text.trim()) ?? 0.0;
    final dateStr = DateFormat('yyyy-MM-dd').format(_mealDate);
    final timeStr =
        '${_mealTime.hour.toString().padLeft(2, '0')}:${_mealTime.minute.toString().padLeft(2, '0')}:00';

    final calProv = context.read<CalorieProvider>();
    final success = await calProv.addMeal(
      mealType: _mealType,
      foodName: foodName,
      calories: calories,
      carbsG: carbs,
      servingQuantity: _servingQuantity,
      date: dateStr,
      time: timeStr,
      notes: _notesController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meal logged successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(calProv.errorMessage ?? 'Failed to log meal.'),
          backgroundColor: AppConstants.statusDanger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final calProv = context.watch<CalorieProvider>();
    final catalog = calProv.foodCatalog;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Meal'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Meal Type Selector
                const Text(
                  'Meal Type',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _mealTypes.map((t) {
                    final isSelected = _mealType == t['key'];
                    return ChoiceChip(
                      label: Text(t['label']!),
                      selected: isSelected,
                      selectedColor: const Color(0xFFD1FAE5),
                      labelStyle: TextStyle(
                        color: isSelected ? const Color(0xFF065F46) : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _mealType = t['key']!);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // 2. Indian Food Catalog Picker (Instant Search)
                const Text(
                  'Quick Select from Indian Foods',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap an item to auto-fill calorie and carb information.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 10),

                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search idli, dosa, chapati, dal, sambar...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              calProv.searchFoods();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: (q) => calProv.searchFoods(query: q.trim()),
                ),
                const SizedBox(height: 10),

                // Food Items Horizontal Scroll / Chips
                if (catalog.isNotEmpty)
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: catalog.length > 12 ? 12 : catalog.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final food = catalog[i];
                        final isSel = _selectedCatalogItem?.id == food.id;

                        return InkWell(
                          onTap: () => _onFoodSelected(food),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 140,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFFD1FAE5) : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSel ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                                width: isSel ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  food.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${food.calories} kcal',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                                Text(
                                  '${food.carbsG}g carbs',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF0284C7)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 24),

                // 3. Food Name Field
                CustomTextField(
                  controller: _foodNameController,
                  label: 'Food / Meal Name *',
                  hint: 'e.g. 2 Idlis with Vegetable Sambar',
                  prefixIcon: Icons.fastfood_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter food name.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 4. Serving Quantity Stepper
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Serving Portion', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        IconButton.filledTonal(
                          icon: const Icon(Icons.remove_rounded, size: 20),
                          onPressed: () {
                            if (_servingQuantity > 0.5) {
                              _updateServingQuantity(_servingQuantity - 0.5);
                            }
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '${_servingQuantity}x',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.add_rounded, size: 20),
                          onPressed: () {
                            if (_servingQuantity < 10) {
                              _updateServingQuantity(_servingQuantity + 0.5);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 5. Calories & Carbs Inputs
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _caloriesController,
                        label: 'Calories (kcal) *',
                        hint: 'e.g. 280',
                        prefixIcon: Icons.local_fire_department_rounded,
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || int.tryParse(val) == null) return 'Enter calories';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: CustomTextField(
                        controller: _carbsController,
                        label: 'Carbs (grams)',
                        hint: 'e.g. 42.5',
                        prefixIcon: Icons.grain_rounded,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 6. Notes Field
                CustomTextField(
                  controller: _notesController,
                  label: 'Notes (Optional)',
                  hint: 'e.g. Low oil, homemade chutney',
                  prefixIcon: Icons.notes_rounded,
                ),
                const SizedBox(height: 28),

                // Save Meal Button
                CustomButton(
                  text: 'Save Meal Log',
                  icon: Icons.check_circle_rounded,
                  backgroundColor: const Color(0xFF10B981),
                  isLoading: calProv.isLoading,
                  onPressed: _handleSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
