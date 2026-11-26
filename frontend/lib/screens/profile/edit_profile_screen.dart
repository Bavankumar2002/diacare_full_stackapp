// =============================================================================
// DiaCare - Dedicated Edit Profile & Medical Details Screen
// =============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Personal Info
  final _fullNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _dobController = TextEditingController();
  String _gender = 'Male';

  // Body & BMI
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  double _calculatedBmi = 0.0;

  // Diabetes Classification & History
  String _diabetesType = 'Type 2';
  final _yearDiagnosedController = TextEditingController();
  final _medicinesController = TextEditingController();
  final _allergiesController = TextEditingController();

  // Care Network
  final _doctorNameController = TextEditingController();
  final _doctorHospitalController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  // Goals
  final _calorieGoalController = TextEditingController();

  bool _isSaving = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];

  final List<Map<String, String>> _diabetesTypeOptions = [
    {
      'title': 'Type 1',
      'desc': 'Insulin-dependent, autoimmune',
    },
    {
      'title': 'Type 2',
      'desc': 'Lifestyle & insulin resistance',
    },
    {
      'title': 'Gestational',
      'desc': 'Occurs during pregnancy',
    },
    {
      'title': 'Pre-diabetes',
      'desc': 'Borderline elevated sugar',
    },
  ];

  final List<String> _commonMedications = [
    'Karela Jamun Juice',
    'Gurmar (Gymnema)',
    'Vijaysar',
    'Methi (Fenugreek)',
    'Chandraprabha Vati',
    'Neem & Giloy',
    'Metformin',
    'Glimepiride',
    'Insulin Glargine',
    'Januvia (Sitagliptin)',
    'Empagliflozin',
    'Vildagliptin',
    'None / Lifestyle',
  ];

  final List<String> _commonAllergies = [
    'No Known Allergies',
    'Penicillin',
    'Sulfa Drugs',
    'Aspirin',
    'Peanuts',
    'Latex',
  ];

  final List<Map<String, String>> _calorieGoalPresets = [
    {'label': '1500 kcal', 'val': '1500'},
    {'label': '1800 kcal', 'val': '1800'},
    {'label': '2000 kcal', 'val': '2000'},
    {'label': '2200 kcal', 'val': '2200'},
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();

    _heightController.addListener(_recalculateBmi);
    _weightController.addListener(_recalculateBmi);
  }

  void _loadProfileData() {
    final profile = context.read<ProfileProvider>().profile ??
        context.read<AuthProvider>().profile;
    final user = context.read<AuthProvider>().user;

    if (profile != null) {
      _fullNameController.text = profile.fullName;
      _ageController.text = profile.age > 0 ? profile.age.toString() : '';
      _dobController.text = profile.dob ?? '';
      _gender = profile.gender.isNotEmpty ? profile.gender : 'Male';
      _heightController.text =
          profile.heightCm > 0 ? profile.heightCm.toString() : '';
      _weightController.text =
          profile.weightKg > 0 ? profile.weightKg.toString() : '';
      _calculatedBmi = profile.bmi;
      _diabetesType = profile.diabetesType.isNotEmpty ? profile.diabetesType : 'Type 2';
      _yearDiagnosedController.text =
          profile.yearDiagnosed != null ? profile.yearDiagnosed.toString() : '';
      _medicinesController.text = profile.currentMedicines;
      _allergiesController.text = profile.allergies;
      _doctorNameController.text = profile.doctorName;
      _doctorHospitalController.text = profile.doctorHospital;
      _emergencyNameController.text = profile.emergencyContactName;
      _emergencyPhoneController.text = profile.emergencyContactPhone;
      _calorieGoalController.text = profile.dailyCalorieGoal > 0
          ? profile.dailyCalorieGoal.toString()
          : '1800';
    } else if (user != null) {
      if (!user.name.startsWith('Patient ')) {
        _fullNameController.text = user.name;
      }
      _calorieGoalController.text = '1800';
    }

    _recalculateBmi();
  }

  void _recalculateBmi() {
    final h = double.tryParse(_heightController.text.trim()) ?? 0.0;
    final w = double.tryParse(_weightController.text.trim()) ?? 0.0;
    final bmi = ProfileProvider.calculateBMI(h, w);
    if (mounted && bmi != _calculatedBmi) {
      setState(() {
        _calculatedBmi = bmi;
      });
    }
  }

  Future<void> _selectDob() async {
    final now = DateTime.now();
    DateTime initial = DateTime(now.year - 30);
    if (_dobController.text.isNotEmpty) {
      try {
        initial = DateTime.parse(_dobController.text.trim());
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
        final age = now.year - picked.year;
        if (_ageController.text.isEmpty || _ageController.text == '0') {
          _ageController.text = age.toString();
        }
      });
    }
  }

  void _toggleMedication(String med) {
    if (med == 'None / Lifestyle') {
      setState(() {
        _medicinesController.text = 'None';
      });
      return;
    }

    final current = _medicinesController.text.trim();
    List<String> items = current.isEmpty
        ? []
        : current
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty && e.toLowerCase() != 'none')
            .toList();

    if (items.contains(med)) {
      items.remove(med);
    } else {
      items.add(med);
    }

    setState(() {
      _medicinesController.text = items.join(', ');
    });
  }

  void _toggleAllergy(String allergy) {
    if (allergy == 'No Known Allergies') {
      setState(() {
        _allergiesController.text = 'None';
      });
      return;
    }

    final current = _allergiesController.text.trim();
    List<String> items = current.isEmpty
        ? []
        : current
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty && e.toLowerCase() != 'none')
            .toList();

    if (items.contains(allergy)) {
      items.remove(allergy);
    } else {
      items.add(allergy);
    }

    setState(() {
      _allergiesController.text = items.join(', ');
    });
  }

  String _getBmiStatusText(double bmi) {
    if (bmi <= 0) return 'Enter height & weight';
    if (bmi < 18.5) return 'Underweight (BMI: $bmi)';
    if (bmi <= 24.9) return 'Normal Weight (BMI: $bmi)';
    if (bmi <= 29.9) return 'Overweight (BMI: $bmi)';
    return 'Obese (BMI: $bmi)';
  }

  Color _getBmiColor(double bmi) {
    if (bmi <= 0) return Colors.grey;
    if (bmi < 18.5) return const Color(0xFF0284C7);
    if (bmi <= 24.9) return const Color(0xFF10B981);
    if (bmi <= 29.9) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional validations
    final fullName = _fullNameController.text.trim();
    if (fullName.isEmpty) {
      _showErrorSnackBar('Please enter your full name.');
      return;
    }

    final age = int.tryParse(_ageController.text.trim()) ?? 0;
    if (age <= 0 || age > 130) {
      _showErrorSnackBar('Please enter a valid age (1-130).');
      return;
    }

    final height = double.tryParse(_heightController.text.trim()) ?? 0.0;
    if (height < 50 || height > 260) {
      _showErrorSnackBar('Please enter a valid height in cm (50-260).');
      return;
    }

    final weight = double.tryParse(_weightController.text.trim()) ?? 0.0;
    if (weight < 20 || weight > 300) {
      _showErrorSnackBar('Please enter a valid weight in kg (20-300).');
      return;
    }

    final emergencyPhone = _emergencyPhoneController.text.trim();
    if (emergencyPhone.isNotEmpty && emergencyPhone.length < 7) {
      _showErrorSnackBar('Emergency contact phone should be at least 7 digits.');
      return;
    }

    final calorieGoal = int.tryParse(_calorieGoalController.text.trim()) ?? 1800;

    setState(() => _isSaving = true);

    final profileData = {
      'full_name': fullName,
      'age': age,
      'dob': _dobController.text.trim().isNotEmpty ? _dobController.text.trim() : null,
      'gender': _gender,
      'height_cm': height,
      'weight_kg': weight,
      'diabetes_type': _diabetesType,
      'year_diagnosed': int.tryParse(_yearDiagnosedController.text.trim()),
      'current_medicines': _medicinesController.text.trim(),
      'allergies': _allergiesController.text.trim(),
      'emergency_contact_name': _emergencyNameController.text.trim(),
      'emergency_contact_phone': emergencyPhone,
      'doctor_name': _doctorNameController.text.trim(),
      'doctor_hospital': _doctorHospitalController.text.trim(),
      'daily_calorie_goal': calorieGoal > 0 ? calorieGoal : 1800,
    };

    final profileProv = context.read<ProfileProvider>();
    final success = await profileProv.saveProfile(profileData);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      context.read<AuthProvider>().setHasProfile(true, profileProv.profile);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile & medical details updated successfully!'),
          backgroundColor: AppConstants.statusNormal,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else {
      _showErrorSnackBar(profileProv.errorMessage ?? 'Failed to update profile.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.statusDanger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _heightController.removeListener(_recalculateBmi);
    _weightController.removeListener(_recalculateBmi);
    _fullNameController.dispose();
    _ageController.dispose();
    _dobController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _yearDiagnosedController.dispose();
    _medicinesController.dispose();
    _allergiesController.dispose();
    _doctorNameController.dispose();
    _doctorHospitalController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _calorieGoalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile & Medical Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.primaryTeal),
                  )
                : const Icon(Icons.check_rounded, size: 28),
            tooltip: 'Save Changes',
            onPressed: _isSaving ? null : _handleSave,
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Personal Identity Section Card
                _buildSectionCard(
                  context: context,
                  icon: Icons.person_rounded,
                  iconColor: const Color(0xFF6366F1),
                  title: 'Personal Information',
                  subtitle: 'Basic details used across clinical records',
                  children: [
                    CustomTextField(
                      controller: _fullNameController,
                      label: 'Full Name *',
                      hint: 'e.g. Bavan Kumar',
                      prefixIcon: Icons.badge_outlined,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _ageController,
                            label: 'Age (Years) *',
                            hint: 'e.g. 21',
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.calendar_today_outlined,
                            validator: (v) {
                              final age = int.tryParse(v?.trim() ?? '');
                              if (age == null || age <= 0 || age > 130) {
                                return 'Valid age (1-130)';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _dobController,
                            label: 'Date of Birth',
                            hint: 'YYYY-MM-DD',
                            readOnly: true,
                            onTap: _selectDob,
                            prefixIcon: Icons.cake_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Gender *',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: _genders.map((g) {
                        final isSelected = _gender == g;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => setState(() => _gender = g),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppConstants.primaryTealLight
                                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppConstants.primaryTeal
                                        : const Color(0xFFCBD5E1),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    g,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected
                                          ? AppConstants.primaryTealDark
                                          : (isDark ? Colors.white70 : Colors.black87),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. Physical & BMI Section Card
                _buildSectionCard(
                  context: context,
                  icon: Icons.straighten_rounded,
                  iconColor: const Color(0xFF0284C7),
                  title: 'Height, Weight & BMI',
                  subtitle: 'Body metrics for calorie and dosage calculation',
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _heightController,
                            label: 'Height (cm) *',
                            hint: 'e.g. 180.0',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            prefixIcon: Icons.height_rounded,
                            validator: (v) {
                              final h = double.tryParse(v?.trim() ?? '');
                              if (h == null || h < 50 || h > 260) {
                                return 'Height 50-260 cm';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _weightController,
                            label: 'Weight (kg) *',
                            hint: 'e.g. 85.0',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            prefixIcon: Icons.monitor_weight_outlined,
                            validator: (v) {
                              final w = double.tryParse(v?.trim() ?? '');
                              if (w == null || w < 20 || w > 300) {
                                return 'Weight 20-300 kg';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Live BMI Preview Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _getBmiColor(_calculatedBmi).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _getBmiColor(_calculatedBmi).withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.speed_rounded,
                            color: _getBmiColor(_calculatedBmi),
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Body Mass Index (BMI)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _getBmiStatusText(_calculatedBmi),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _getBmiColor(_calculatedBmi),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. Diabetes Profile Section Card
                _buildSectionCard(
                  context: context,
                  icon: Icons.water_drop_rounded,
                  iconColor: const Color(0xFF0FA3B1),
                  title: 'Diabetes Classification & Medicines',
                  subtitle: 'Clinical diagnosis and daily management',
                  children: [
                    const Text(
                      'Diabetes Classification *',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _diabetesTypeOptions.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.1,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemBuilder: (context, i) {
                        final opt = _diabetesTypeOptions[i];
                        final isSelected = _diabetesType == opt['title'];
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setState(() => _diabetesType = opt['title']!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppConstants.primaryTealLight
                                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppConstants.primaryTeal
                                    : const Color(0xFFCBD5E1),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isSelected
                                          ? Icons.radio_button_checked_rounded
                                          : Icons.radio_button_off_rounded,
                                      size: 16,
                                      color: isSelected
                                          ? AppConstants.primaryTeal
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      opt['title']!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? AppConstants.primaryTealDark
                                            : (isDark ? Colors.white : Colors.black87),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  opt['desc']!,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: _yearDiagnosedController,
                      label: 'Year Diagnosed (Optional)',
                      hint: 'e.g. 2018',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.event_note_outlined,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: _medicinesController,
                      label: 'Current Medications',
                      hint: 'e.g. Metformin 500mg, Glimepiride',
                      prefixIcon: Icons.medication_outlined,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap to quick-add common medications:',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _commonMedications.map((med) {
                        final isAdded = _medicinesController.text.contains(med);
                        final isAyurvedic = [
                          'Karela Jamun Juice',
                          'Gurmar (Gymnema)',
                          'Vijaysar',
                          'Methi (Fenugreek)',
                          'Chandraprabha Vati',
                          'Neem & Giloy',
                        ].contains(med);
                        return FilterChip(
                          avatar: isAyurvedic
                              ? const Icon(Icons.eco, size: 13, color: Color(0xFF15803D))
                              : null,
                          label: Text(med, style: const TextStyle(fontSize: 11)),
                          selected: isAdded,
                          onSelected: (_) => _toggleMedication(med),
                          selectedColor: AppConstants.primaryTealLight,
                          checkmarkColor: AppConstants.primaryTeal,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: _allergiesController,
                      label: 'Known Allergies (Optional)',
                      hint: 'e.g. Penicillin, Peanuts (or None)',
                      prefixIcon: Icons.warning_amber_rounded,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _commonAllergies.map((allergy) {
                        final isAdded = _allergiesController.text.contains(allergy);
                        return FilterChip(
                          label: Text(allergy, style: const TextStyle(fontSize: 11)),
                          selected: isAdded,
                          onSelected: (_) => _toggleAllergy(allergy),
                          selectedColor: const Color(0xFFFEE2E2),
                          checkmarkColor: AppConstants.statusDanger,
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 4. Care Network Section Card (Doctor, Hospital & Emergency Contact)
                _buildSectionCard(
                  context: context,
                  icon: Icons.local_hospital_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Doctor & Emergency Contact',
                  subtitle: 'Emergency care details and consulting clinician',
                  children: [
                    CustomTextField(
                      controller: _doctorNameController,
                      label: 'Doctor / Physician Name',
                      hint: 'e.g. Dr. Rajesh Sharma, MD',
                      prefixIcon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: _doctorHospitalController,
                      label: 'Hospital / Clinic Name',
                      hint: 'e.g. Apollo Diabetes Center',
                      prefixIcon: Icons.apartment_rounded,
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 24),
                    const Text(
                      'Emergency Contact',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Shown prominently on your profile for quick emergency dialing',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _emergencyNameController,
                      label: 'Contact Person Name',
                      hint: 'e.g. Hema (Spouse / Parent)',
                      prefixIcon: Icons.person_pin_circle_outlined,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: _emergencyPhoneController,
                      label: 'Emergency Phone Number',
                      hint: 'e.g. 8754032789',
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_in_talk_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 5. Daily Calorie Goal Section Card
                _buildSectionCard(
                  context: context,
                  icon: Icons.local_fire_department_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: 'Daily Nutrition Target',
                  subtitle: 'Target daily calorie intake for meal tracking',
                  children: [
                    CustomTextField(
                      controller: _calorieGoalController,
                      label: 'Daily Calorie Goal (kcal)',
                      hint: 'e.g. 1800',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.fireplace_rounded,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: _calorieGoalPresets.map((preset) {
                        final isSelected =
                            _calorieGoalController.text == preset['val'];
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => setState(() {
                                _calorieGoalController.text = preset['val']!;
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFD1FAE5)
                                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    preset['label']!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected
                                          ? const Color(0xFF065F46)
                                          : (isDark ? Colors.white70 : Colors.black87),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Save Action Button
                CustomButton(
                  text: 'Save Changes',
                  icon: Icons.check_circle_rounded,
                  backgroundColor: AppConstants.primaryTeal,
                  isLoading: _isSaving,
                  height: 54,
                  onPressed: _handleSave,
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
