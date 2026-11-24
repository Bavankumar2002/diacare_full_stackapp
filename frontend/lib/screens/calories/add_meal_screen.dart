// =============================================================================
// DiaCare - Add Meal with Enhanced Indian Food Catalog & Nutrition Cards
// =============================================================================

import 'dart:async';
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
  final FoodItemModel? initialFood;
  final String? initialMealType;

  const AddMealScreen({
    super.key,
    this.initialDate,
    this.initialFood,
    this.initialMealType,
  });

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _foodNameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _carbsController = TextEditingController();
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();

  String _mealType = 'breakfast';
  String _selectedCategory = 'All';
  double _servingQuantity = 1.0;
  late DateTime _mealDate;
  final TimeOfDay _mealTime = TimeOfDay.now();
  bool _isGridView = false;

  FoodItemModel? _selectedCatalogItem;
  Timer? _searchDebounce;

  final List<Map<String, String>> _mealTypes = [
    {'key': 'breakfast', 'label': '🌅 Breakfast'},
    {'key': 'lunch', 'label': '☀️ Lunch'},
    {'key': 'dinner', 'label': '🌙 Dinner'},
    {'key': 'snack', 'label': '☕ Snack / Drink'},
  ];

  final List<Map<String, String>> _categories = [
    {'key': 'All', 'label': '🍽️ All'},
    {'key': 'Breakfast', 'label': '🥞 Breakfast'},
    {'key': 'Lunch/Dinner', 'label': '🍲 Lunch/Dinner'},
    {'key': 'Breads & Roti', 'label': '🫓 Breads & Roti'},
    {'key': 'Rice & Biryani', 'label': '🍚 Rice & Biryani'},
    {'key': 'Dal & Pulses', 'label': '🥣 Dal & Pulses'},
    {'key': 'Curries & Sabzi', 'label': '🥘 Curries & Sabzi'},
    {'key': 'Non-Veg', 'label': '🍗 Non-Veg'},
    {'key': 'Snacks', 'label': '🥨 Snacks'},
    {'key': 'Fruits & Salads', 'label': '🥗 Fruits & Salads'},
    {'key': 'Beverages', 'label': '☕ Beverages'},
    {'key': 'Sweets', 'label': '🍮 Sweets'},
  ];

  @override
  void initState() {
    super.initState();
    _mealDate = widget.initialDate ?? DateTime.now();

    // Default meal type based on parameter or current hour
    if (widget.initialMealType != null) {
      _mealType = widget.initialMealType!.toLowerCase();
    } else {
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
    }

    if (widget.initialFood != null) {
      final f = widget.initialFood!;
      _selectedCatalogItem = f;
      _foodNameController.text = f.name;
      _caloriesController.text = (f.calories * _servingQuantity).round().toString();
      _carbsController.text = (f.carbsG * _servingQuantity).toStringAsFixed(1);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchFoods();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _foodNameController.dispose();
    _caloriesController.dispose();
    _carbsController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _fetchFoods() {
    context.read<CalorieProvider>().searchFoods(
          query: _searchController.text.trim(),
          category: _selectedCategory == 'All' ? '' : _selectedCategory,
        );
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _fetchFoods();
    });
  }

  void _onCategorySelected(String categoryKey) {
    setState(() {
      _selectedCategory = categoryKey;
    });
    _fetchFoods();
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

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Selected ${food.name} (${food.calories} kcal, ${food.carbsG}g carbs)',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF0D9488),
      ),
    );
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
      imageUrl: _selectedCatalogItem?.imageUrl,
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Meal Type Selector Chips
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

                // 2. Quick Select Header & View Mode Switcher
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quick Select from Indian Foods',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap an item to auto-fill calorie and carb information.',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isGridView ? Icons.view_carousel_rounded : Icons.grid_view_rounded,
                        color: const Color(0xFF0D9488),
                      ),
                      tooltip: _isGridView ? 'Horizontal row view' : '2-column grid view',
                      onPressed: () => setState(() => _isGridView = !_isGridView),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search 1,000+ foods (idli, dosa, roti, biryani, paneer...)',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0D9488)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              _fetchFoods();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 12),

                // Category Filter Chips (Horizontal Scroll)
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final cat = _categories[i];
                      final isSelected = _selectedCategory == cat['key'];
                      return FilterChip(
                        label: Text(cat['label']!),
                        selected: isSelected,
                        selectedColor: const Color(0xFFCCFBF1),
                        checkmarkColor: const Color(0xFF0D9488),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? const Color(0xFF0F766E) : Colors.black87,
                        ),
                        backgroundColor: Theme.of(context).cardColor,
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0),
                        ),
                        onSelected: (_) => _onCategorySelected(cat['key']!),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // Food Cards Section: Grid or Horizontal Scroll
                if (catalog.isEmpty)
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 36, color: Colors.grey.shade400),
                          const SizedBox(height: 6),
                          Text(
                            'No food items matching "${_searchController.text.trim()}"',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_isGridView)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.74,
                    ),
                    itemCount: catalog.length,
                    itemBuilder: (context, i) {
                      final food = catalog[i];
                      final isSel = _selectedCatalogItem?.id == food.id;
                      return _buildFoodCard(context, food, isSel);
                    },
                  )
                else
                  SizedBox(
                    height: 205,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: catalog.length > 30 ? 31 : catalog.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        if (i == 30) {
                          // View All Remaining Card
                          return InkWell(
                            onTap: () => setState(() => _isGridView = true),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 120,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDFA),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF99F6E4)),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.grid_view_rounded,
                                      color: Color(0xFF0D9488),
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '+${catalog.length - 30} more',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0D9488),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'View in Grid',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF14B8A6),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        final food = catalog[i];
                        final isSel = _selectedCatalogItem?.id == food.id;
                        return _buildFoodCard(context, food, isSel, width: 145);
                      },
                    ),
                  ),
                const SizedBox(height: 24),

                // 3. Food Name Field
                CustomTextField(
                  controller: _foodNameController,
                  label: 'Food / Meal Name *',
                  hint: 'e.g., Idli with vegetable sambar',
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
                    const Text(
                      'Serving Portion',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
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
                        hint: 'Enter calories',
                        prefixIcon: Icons.local_fire_department_rounded,
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty || int.tryParse(val.trim()) == null) {
                            return 'Enter calories';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: CustomTextField(
                        controller: _carbsController,
                        label: 'Carbs (grams)',
                        hint: 'Enter carbs',
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
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // COMPACT ROUNDED FOOD CARD WIDGET
  // ===========================================================================
  Widget _buildFoodCard(BuildContext context, FoodItemModel food, bool isSel,
      {double? width}) {
    return InkWell(
      onTap: () => _onFoodSelected(food),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFFECFDF5) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSel ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
            width: isSel ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSel
                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSel ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with serving badge & selection checkmark
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: food.imageUrl != null && food.imageUrl!.isNotEmpty
                      ? Image.network(
                          food.imageUrl!,
                          height: 95,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              height: 95,
                              color: const Color(0xFFF1F5F9),
                              child: const Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              _buildFallbackImage(food.category),
                        )
                      : _buildFallbackImage(food.category),
                ),
                // Serving Size Tag
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      food.servingSize,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Selected Checkmark Badge
                if (isSel)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            // Info section
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSel ? const Color(0xFF065F46) : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        size: 14,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${food.calories} kcal',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.grain_rounded,
                        size: 13,
                        color: Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${food.carbsG}g carbs',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // CONSISTENT POLISHED FALLBACK PLACEHOLDER
  // ===========================================================================
  Widget _buildFallbackImage(String category) {
    IconData icon = Icons.restaurant_rounded;
    if (category.contains('Breakfast')) icon = Icons.breakfast_dining_rounded;
    if (category.contains('Beverage')) icon = Icons.local_cafe_rounded;
    if (category.contains('Sweet')) icon = Icons.icecream_rounded;
    if (category.contains('Fruit')) icon = Icons.apple_rounded;
    if (category.contains('Roti') || category.contains('Bread')) {
      icon = Icons.bakery_dining_rounded;
    }
    if (category.contains('Rice')) icon = Icons.rice_bowl_rounded;
    if (category.contains('Non-Veg')) icon = Icons.set_meal_rounded;

    return Container(
      height: 95,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE6FFFA), Color(0xFFCCFBF1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: const Color(0xFF0D9488)),
            const SizedBox(height: 2),
            Text(
              category,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0D9488),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
