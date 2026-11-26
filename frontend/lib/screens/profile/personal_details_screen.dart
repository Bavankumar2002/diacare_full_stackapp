// =============================================================================
// DiaCare - Guided One-Question-at-a-Time Patient Profile Setup Flow
// =============================================================================
// Step 1 of 3: Personal Info & BMI (Questions 1 to 5)
//   Q1: Full Name
//   Q2: Age (Years)
//   Q3: Gender (Selectable Choice Cards)
//   Q4: Date of Birth (Optional Date Picker)
//   Q5: Height & Weight (with Live Auto-Calculated BMI Preview)
//
// Step 2 of 3: Diabetes Profile (Questions 1 to 4)
//   Q1: Diabetes Classification (Selectable Option Cards)
//   Q2: Year Diagnosed (Optional Quick Chips + Input)
//   Q3: Current Medications / Dosages (Optional Multi-Select Chips + Input)
//   Q4: Known Allergies (Optional Multi-Select Chips + Input)
//
// Step 3 of 3: Care Network & Goals (Questions 1 to 4)
//   Q1: Emergency Contact Details (Optional Name & Phone)
//   Q2: Doctor's Name (Optional Consulting Physician)
//   Q3: Hospital / Clinic Name (Optional Center)
//   Q4: Daily Calorie Target (Optional Quick Chips + Input) -> Save Profile!
// =============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../main_navigation_screen.dart';

class PersonalDetailsScreen extends StatefulWidget {
  final bool isInitialSetup;

  const PersonalDetailsScreen({super.key, this.isInitialSetup = true});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  // Page index (0 to 12 across the 3 main sections)
  int _currentPage = 0;
  static const int _totalPages = 13;

  // Step 1 Controllers (Q1 - Q5)
  final _fullNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _dobController = TextEditingController();
  String? _gender;
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  double _calculatedBmi = 0.0;

  // Step 2 Controllers (Q1 - Q4)
  String _diabetesType = 'Type 2';
  final _yearDiagnosedController = TextEditingController();
  final _medicinesController = TextEditingController();
  final _allergiesController = TextEditingController();

  // Step 3 Controllers (Q1 - Q4)
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _doctorNameController = TextEditingController();
  final _doctorHospitalController = TextEditingController();
  final _calorieGoalController = TextEditingController();

  final List<String> _genders = ['Male', 'Female', 'Other'];

  final List<Map<String, String>> _diabetesTypeOptions = [
    {
      'title': 'Type 1',
      'desc': 'Insulin-dependent, body produces little or no insulin'
    },
    {
      'title': 'Type 2',
      'desc': 'Most common lifestyle & adult-onset insulin resistance'
    },
    {
      'title': 'Gestational',
      'desc': 'Diagnosed during pregnancy, requires careful tracking'
    },
    {
      'title': 'Pre-diabetes',
      'desc': 'Borderline elevated blood glucose, reversible with habits'
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
    'None / Lifestyle Only',
  ];

  final List<String> _commonAllergies = [
    'No Known Allergies',
    'Penicillin',
    'Sulfa Drugs',
    'Aspirin / NSAIDs',
    'Peanuts',
    'Latex',
  ];

  final List<Map<String, String>> _calorieGoalPresets = [
    {'label': '1500 kcal', 'desc': 'Weight Loss / Calorie Deficit', 'val': '1500'},
    {'label': '1800 kcal', 'desc': 'Recommended Standard Diabetic', 'val': '1800'},
    {'label': '2000 kcal', 'desc': 'Moderate Daily Activity', 'val': '2000'},
    {'label': '2200 kcal', 'desc': 'Active Lifestyle / Muscle Gain', 'val': '2200'},
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  void _loadExistingProfile() {
    if (widget.isInitialSetup) {
      // In initial setup, start completely empty with clean placeholders
      _fullNameController.clear();
      _ageController.clear();
      _dobController.clear();
      _gender = null;
      _heightController.clear();
      _weightController.clear();
      _calculatedBmi = 0.0;
      _diabetesType = 'Type 2';
      _yearDiagnosedController.clear();
      _medicinesController.clear();
      _allergiesController.clear();
      _emergencyNameController.clear();
      _emergencyPhoneController.clear();
      _doctorNameController.clear();
      _doctorHospitalController.clear();
      _calorieGoalController.clear();
      return;
    }

    final existing = context.read<AuthProvider>().profile ??
        context.read<ProfileProvider>().profile;
    final user = context.read<AuthProvider>().user;

    if (existing != null) {
      _fullNameController.text = existing.fullName;
      _ageController.text = existing.age > 0 ? existing.age.toString() : '';
      _dobController.text = existing.dob ?? '';
      _gender = existing.gender.isNotEmpty ? existing.gender : null;
      _heightController.text =
          existing.heightCm > 0 ? existing.heightCm.toString() : '';
      _weightController.text =
          existing.weightKg > 0 ? existing.weightKg.toString() : '';
      _calculatedBmi = existing.bmi;
      _diabetesType = existing.diabetesType.isNotEmpty ? existing.diabetesType : 'Type 2';
      _yearDiagnosedController.text =
          existing.yearDiagnosed != null ? existing.yearDiagnosed.toString() : '';
      _medicinesController.text = existing.currentMedicines;
      _allergiesController.text = existing.allergies;
      _emergencyNameController.text = existing.emergencyContactName;
      _emergencyPhoneController.text = existing.emergencyContactPhone;
      _doctorNameController.text = existing.doctorName;
      _doctorHospitalController.text = existing.doctorHospital;
      _calorieGoalController.text = existing.dailyCalorieGoal > 0
          ? existing.dailyCalorieGoal.toString()
          : '';
    } else if (user != null && !user.name.startsWith('Patient ')) {
      _fullNameController.text = user.name;
    }
  }

  void _recalculateBmi() {
    final h = double.tryParse(_heightController.text.trim()) ?? 0.0;
    final w = double.tryParse(_weightController.text.trim()) ?? 0.0;
    setState(() {
      _calculatedBmi = ProfileProvider.calculateBMI(h, w);
    });
  }

  Future<void> _selectDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 40),
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
    if (med == 'None / Lifestyle Only') {
      setState(() {
        _medicinesController.text = 'None';
      });
      return;
    }

    final currentText = _medicinesController.text.trim();
    List<String> items = currentText.isEmpty
        ? []
        : currentText
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

    final currentText = _allergiesController.text.trim();
    List<String> items = currentText.isEmpty
        ? []
        : currentText
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
    if (bmi < 18.5) return Colors.orange;
    if (bmi <= 24.9) return AppConstants.statusNormal;
    if (bmi <= 29.9) return Colors.amber.shade700;
    return AppConstants.statusDanger;
  }

  // ===========================================================================
  // SECTION & QUESTION NAVIGATION HELPERS
  // ===========================================================================
  int get _stepNumber {
    if (_currentPage < 5) return 1;
    if (_currentPage < 9) return 2;
    return 3;
  }

  String get _stepTitle {
    switch (_stepNumber) {
      case 1:
        return 'Personal Info & BMI';
      case 2:
        return 'Diabetes Profile';
      case 3:
      default:
        return 'Care Network & Goals';
    }
  }

  int get _questionNumberInStep {
    if (_currentPage < 5) return _currentPage + 1;
    if (_currentPage < 9) return _currentPage - 5 + 1;
    return _currentPage - 9 + 1;
  }

  int get _totalQuestionsInStep {
    if (_currentPage < 5) return 5;
    if (_currentPage < 9) return 4;
    return 4;
  }

  String get _stepProgressHeader =>
      'Step $_stepNumber of 3: $_stepTitle';

  String get _questionProgressBadge =>
      'Step $_stepNumber of 3 · Question $_questionNumberInStep of $_totalQuestionsInStep';

  double get _progress => (_currentPage + 1) / _totalPages;

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0: // Q1: Full Name
        if (_fullNameController.text.trim().isEmpty) {
          _showToast('Please enter your full name.');
          return false;
        }
        return true;

      case 1: // Q2: Age
        final age = int.tryParse(_ageController.text.trim()) ?? 0;
        if (age <= 0 || age > 130) {
          _showToast('Please enter a valid age (1-130).');
          return false;
        }
        return true;

      case 2: // Q3: Gender
        if (_gender == null || _gender!.isEmpty) {
          _showToast('Please select your gender.');
          return false;
        }
        return true;

      case 3: // Q4: Birthday (Optional)
        return true;

      case 4: // Q5: Height & Weight
        final height = double.tryParse(_heightController.text.trim()) ?? 0;
        final weight = double.tryParse(_weightController.text.trim()) ?? 0;
        if (height < 50 || height > 260) {
          _showToast('Please enter a valid height in cm (50-260).');
          return false;
        }
        if (weight < 20 || weight > 300) {
          _showToast('Please enter a valid weight in kg (20-300).');
          return false;
        }
        return true;

      case 5: // Q1: Diabetes Classification
        if (_diabetesType.isEmpty) {
          _showToast('Please select your diabetes classification.');
          return false;
        }
        return true;

      case 6: // Q2: Year Diagnosed (Optional)
        if (_yearDiagnosedController.text.trim().isNotEmpty) {
          final year = int.tryParse(_yearDiagnosedController.text.trim()) ?? 0;
          final currentYear = DateTime.now().year;
          if (year < 1920 || year > currentYear) {
            _showToast('Please enter a valid 4-digit diagnosis year.');
            return false;
          }
        }
        return true;

      case 7: // Q3: Current Medicines (Optional)
        return true;

      case 8: // Q4: Known Allergies (Optional)
        return true;

      case 9: // Q1: Emergency Contact (Optional)
        if (_emergencyPhoneController.text.trim().isNotEmpty &&
            _emergencyPhoneController.text.trim().length < 7) {
          _showToast('Emergency phone number should be at least 7 digits.');
          return false;
        }
        return true;

      case 10: // Q2: Doctor's Name (Optional)
        return true;

      case 11: // Q3: Hospital / Clinic Name (Optional)
        return true;

      case 12: // Q4: Daily Calorie Target (Optional)
        if (_calorieGoalController.text.trim().isNotEmpty) {
          final calories = int.tryParse(_calorieGoalController.text.trim()) ?? 0;
          if (calories < 500 || calories > 6000) {
            _showToast('Please enter a realistic calorie goal (500-6000 kcal).');
            return false;
          }
        }
        return true;

      default:
        return true;
    }
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppConstants.statusDanger),
    );
  }

  Future<void> _handleSave() async {
    final calorieGoal = int.tryParse(_calorieGoalController.text.trim()) ?? 1800;

    final profileData = {
      'full_name': _fullNameController.text.trim(),
      'age': int.tryParse(_ageController.text.trim()) ?? 0,
      'dob': _dobController.text.trim().isNotEmpty ? _dobController.text.trim() : null,
      'gender': _gender ?? 'Other',
      'height_cm': double.tryParse(_heightController.text.trim()) ?? 0.0,
      'weight_kg': double.tryParse(_weightController.text.trim()) ?? 0.0,
      'diabetes_type': _diabetesType,
      'year_diagnosed': int.tryParse(_yearDiagnosedController.text.trim()),
      'current_medicines': _medicinesController.text.trim(),
      'allergies': _allergiesController.text.trim(),
      'emergency_contact_name': _emergencyNameController.text.trim(),
      'emergency_contact_phone': _emergencyPhoneController.text.trim(),
      'doctor_name': _doctorNameController.text.trim(),
      'doctor_hospital': _doctorHospitalController.text.trim(),
      'daily_calorie_goal': calorieGoal > 0 ? calorieGoal : 1800,
    };

    final profileProv = context.read<ProfileProvider>();
    final success = await profileProv.saveProfile(profileData);

    if (!mounted) return;

    if (success) {
      context.read<AuthProvider>().setHasProfile(true, profileProv.profile);

      if (widget.isInitialSetup) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppConstants.statusNormal,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      _showToast(profileProv.errorMessage ?? 'Failed to save profile.');
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _ageController.dispose();
    _dobController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _yearDiagnosedController.dispose();
    _medicinesController.dispose();
    _allergiesController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _doctorNameController.dispose();
    _doctorHospitalController.dispose();
    _calorieGoalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileProv = context.watch<ProfileProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isInitialSetup ? 'Patient Profile Setup' : 'Edit Profile'),
        automaticallyImplyLeading: !widget.isInitialSetup,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Progress Bar & Step Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: Theme.of(context).cardColor,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _stepProgressHeader,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.primaryTeal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(_progress * 100).toInt()}% Complete',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 7,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.primaryTeal),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Active One-Question Content Card
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0.0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<int>(_currentPage),
                    child: _buildCurrentQuestionPage(),
                  ),
                ),
              ),
            ),

            // 3. Pinned Bottom Navigation Bar (Back & Continue / Save)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentPage > 0) ...[
                    Expanded(
                      flex: 1,
                      child: CustomButton(
                        text: 'Back',
                        isOutlined: true,
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          setState(() => _currentPage--);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: _currentPage == (_totalPages - 1)
                          ? 'Save Profile'
                          : 'Continue',
                      icon: _currentPage == (_totalPages - 1)
                          ? Icons.check_circle_rounded
                          : Icons.arrow_forward_rounded,
                      isLoading: profileProv.isLoading,
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        if (_validateCurrentPage()) {
                          if (_currentPage < (_totalPages - 1)) {
                            setState(() => _currentPage++);
                          } else {
                            _handleSave();
                          }
                        }
                      },
                    ),
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
  // QUESTION CONTENT BUILDER (13 DISTINCT ONE-BY-ONE QUESTIONS)
  // ===========================================================================
  Widget _buildCurrentQuestionPage() {
    switch (_currentPage) {
      // -----------------------------------------------------------------------
      // STEP 1: PERSONAL INFO & BMI (Questions 1 to 5)
      // -----------------------------------------------------------------------
      case 0:
        return _buildCardWrapper(
          icon: Icons.badge_outlined,
          badgeText: _questionProgressBadge,
          title: 'What is your full name?',
          subtitle: 'We will use this to address you and personalize your clinical records.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: _fullNameController,
                label: 'Full Name *',
                hint: 'e.g. Bavan Kumar',
                prefixIcon: Icons.person_rounded,
              ),
            ],
          ),
        );

      case 1:
        return _buildCardWrapper(
          icon: Icons.cake_outlined,
          badgeText: _questionProgressBadge,
          title: 'How old are you?',
          subtitle: 'Your age helps calibrate baseline metabolic and glucose targets.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: _ageController,
                label: 'Age (Years) *',
                hint: 'Enter your age',
                prefixIcon: Icons.cake_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              const Text(
                'Quick Select Age Range:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['20', '25', '30', '40', '50', '60'].map((age) {
                  return ActionChip(
                    label: Text('$age yrs'),
                    onPressed: () {
                      setState(() {
                        _ageController.text = age;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );

      case 2:
        return _buildCardWrapper(
          icon: Icons.people_outline_rounded,
          badgeText: _questionProgressBadge,
          title: 'What is your gender?',
          subtitle: 'Selected gender helps calculate accurate nutritional and BMI parameters.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Gender *',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: _genders.map((g) {
                  final isSelected = _gender == g;
                  IconData gIcon = Icons.male_rounded;
                  if (g == 'Female') gIcon = Icons.female_rounded;
                  if (g == 'Other') gIcon = Icons.person_outline_rounded;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () => setState(() => _gender = g),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: isSelected ? AppConstants.primaryTealLight : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppConstants.primaryTeal : const Color(0xFFE2E8F0),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isSelected ? 0.05 : 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                gIcon,
                                size: 32,
                                color: isSelected ? AppConstants.primaryTealDark : Colors.grey.shade500,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                g,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? AppConstants.primaryTealDark : Colors.black87,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(height: 4),
                                const Icon(Icons.check_circle_rounded, size: 16, color: AppConstants.primaryTeal),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );

      case 3:
        return _buildCardWrapper(
          icon: Icons.calendar_today_rounded,
          badgeText: _questionProgressBadge,
          title: 'When is your birthday?',
          subtitle: 'Optional: Automatically keeps your age up to date in DiaCare.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: _dobController,
                label: 'Date of Birth (Optional)',
                hint: 'YYYY-MM-DD',
                prefixIcon: Icons.calendar_month_rounded,
                readOnly: true,
                onTap: _selectDob,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.edit_calendar_rounded, color: AppConstants.primaryTeal),
                  onPressed: _selectDob,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Tap the field or calendar icon to select your date of birth.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        );

      case 4:
        return _buildCardWrapper(
          icon: Icons.straighten_rounded,
          badgeText: _questionProgressBadge,
          title: 'What is your height & weight?',
          subtitle: 'We use these to calculate your Body Mass Index (BMI) and daily energy burn.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _heightController,
                      label: 'Height (cm) *',
                      hint: 'e.g. 172.0',
                      prefixIcon: Icons.height_rounded,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => _recalculateBmi(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: CustomTextField(
                      controller: _weightController,
                      label: 'Weight (kg) *',
                      hint: 'e.g. 70.0',
                      prefixIcon: Icons.scale_rounded,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => _recalculateBmi(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Live BMI Preview Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _calculatedBmi > 0
                      ? _getBmiColor(_calculatedBmi).withValues(alpha: 0.08)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _calculatedBmi > 0
                        ? _getBmiColor(_calculatedBmi).withValues(alpha: 0.35)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _calculatedBmi > 0
                            ? _getBmiColor(_calculatedBmi).withValues(alpha: 0.15)
                            : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.monitor_weight_outlined,
                        color: _getBmiColor(_calculatedBmi),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Body Mass Index (BMI)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getBmiStatusText(_calculatedBmi),
                            style: TextStyle(
                              fontSize: 15,
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
        );

      // -----------------------------------------------------------------------
      // STEP 2: DIABETES PROFILE (Questions 1 to 4)
      // -----------------------------------------------------------------------
      case 5:
        return _buildCardWrapper(
          icon: Icons.water_drop_rounded,
          badgeText: _questionProgressBadge,
          title: 'What type of diabetes do you have?',
          subtitle: 'Select your diabetes classification so DiaCare can tailor glucose targets and safety alerts.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Diabetes Classification *',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Column(
                children: _diabetesTypeOptions.map((opt) {
                  final isSelected = _diabetesType == opt['title'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => setState(() => _diabetesType = opt['title']!),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppConstants.primaryTealLight : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppConstants.primaryTeal : const Color(0xFFE2E8F0),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isSelected ? 0.05 : 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? AppConstants.primaryTeal : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? AppConstants.primaryTeal : const Color(0xFF94A3B8),
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    opt['title']!,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? AppConstants.primaryTealDark : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    opt['desc']!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected ? const Color(0xFF0F766E) : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );

      case 6:
        return _buildCardWrapper(
          icon: Icons.event_note_rounded,
          badgeText: _questionProgressBadge,
          title: 'When were you diagnosed?',
          subtitle: 'Optional: Enter the year you were first diagnosed with diabetes.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: _yearDiagnosedController,
                label: 'Year Diagnosed (Optional)',
                hint: 'YYYY (e.g. 2018)',
                prefixIcon: Icons.calendar_today_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              const Text(
                'Quick Select Year:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['2026', '2025', '2024', '2022', '2020', '2015', '2010'].map((yr) {
                  return ActionChip(
                    label: Text(yr),
                    onPressed: () {
                      setState(() {
                        _yearDiagnosedController.text = yr;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );

      case 7:
        return _buildCardWrapper(
          icon: Icons.medication_rounded,
          badgeText: _questionProgressBadge,
          title: 'What medications do you take?',
          subtitle: 'Optional: Select common diabetes medications or type your exact daily prescriptions.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Common Diabetes Medications (Tap to Add):',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _commonMedications.map((med) {
                  final isSelected = _medicinesController.text.contains(med);
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
                        ? const Icon(Icons.eco, size: 14, color: Color(0xFF15803D))
                        : null,
                    label: Text(med),
                    selected: isSelected,
                    selectedColor: const Color(0xFFCCFBF1),
                    checkmarkColor: const Color(0xFF0D9488),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? const Color(0xFF0F766E) : Colors.black87,
                    ),
                    onSelected: (_) => _toggleMedication(med),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              CustomTextField(
                controller: _medicinesController,
                label: 'Current Medicines / Dosages (Optional)',
                hint: 'e.g. Metformin 500mg (twice daily), Glimepiride 1mg',
                prefixIcon: Icons.medical_services_outlined,
              ),
            ],
          ),
        );

      case 8:
        return _buildCardWrapper(
          icon: Icons.warning_amber_rounded,
          badgeText: _questionProgressBadge,
          title: 'Do you have any known allergies?',
          subtitle: 'Optional: Mention any pharmaceutical, food, or chemical sensitivities.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Common Allergies (Tap to Add):',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _commonAllergies.map((allergy) {
                  final isSelected = _allergiesController.text.contains(allergy);
                  return FilterChip(
                    label: Text(allergy),
                    selected: isSelected,
                    selectedColor: const Color(0xFFFEE2E2),
                    checkmarkColor: const Color(0xFFDC2626),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? const Color(0xFFB91C1C) : Colors.black87,
                    ),
                    onSelected: (_) => _toggleAllergy(allergy),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              CustomTextField(
                controller: _allergiesController,
                label: 'Known Allergies (Optional)',
                hint: 'e.g. Penicillin, Sulfa drugs, Peanuts (or None)',
                prefixIcon: Icons.warning_amber_rounded,
              ),
            ],
          ),
        );

      // -----------------------------------------------------------------------
      // STEP 3: CARE NETWORK & GOALS (Questions 1 to 4)
      // -----------------------------------------------------------------------
      case 9:
        return _buildCardWrapper(
          icon: Icons.emergency_rounded,
          badgeText: _questionProgressBadge,
          title: 'Who is your emergency contact?',
          subtitle: 'Optional: A family member or friend to reach during sudden sugar spikes or drops.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: _emergencyNameController,
                label: 'Emergency Contact Name (Optional)',
                hint: 'e.g. Hema (Spouse / Parent)',
                prefixIcon: Icons.contact_phone_outlined,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emergencyPhoneController,
                label: 'Emergency Contact Phone Number (Optional)',
                hint: 'e.g. 9876543210',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        );

      case 10:
        return _buildCardWrapper(
          icon: Icons.person_add_alt_1_rounded,
          badgeText: _questionProgressBadge,
          title: 'Who is your consulting doctor?',
          subtitle: 'Optional: Name of your primary diabetologist, endocrinologist, or physician.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: _doctorNameController,
                label: "Doctor's Name (Optional)",
                hint: 'e.g. Dr. Baskar',
                prefixIcon: Icons.medical_services_outlined,
              ),
            ],
          ),
        );

      case 11:
        return _buildCardWrapper(
          icon: Icons.local_hospital_rounded,
          badgeText: _questionProgressBadge,
          title: 'Which hospital or clinic do you visit?',
          subtitle: 'Optional: The medical center or hospital where you receive checkups.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: _doctorHospitalController,
                label: 'Hospital / Clinic Name (Optional)',
                hint: 'e.g. Apollo Hospital, City Diabetes Center',
                prefixIcon: Icons.business_outlined,
              ),
            ],
          ),
        );

      case 12:
        return _buildCardWrapper(
          icon: Icons.local_fire_department_rounded,
          badgeText: _questionProgressBadge,
          title: 'What is your daily calorie target?',
          subtitle: 'Set your daily energy target. You can change this anytime from your profile settings.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recommended Calorie Targets:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Column(
                children: _calorieGoalPresets.map((preset) {
                  final isSelected = _calorieGoalController.text == preset['val'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _calorieGoalController.text = preset['val']!;
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFCCFBF1) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  preset['label']!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? const Color(0xFF0F766E) : Colors.black87,
                                  ),
                                ),
                                Text(
                                  preset['desc']!,
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF0D9488), size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _calorieGoalController,
                label: 'Daily Calorie Target (kcal)',
                hint: '1800',
                prefixIcon: Icons.local_fire_department_rounded,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        );

      default:
        return const SizedBox();
    }
  }

  // ===========================================================================
  // REUSABLE QUESTION CARD WRAPPER
  // ===========================================================================
  Widget _buildCardWrapper({
    required IconData icon,
    required String badgeText,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step & Question Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryTealLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: AppConstants.primaryTeal),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Question Title & Subtitle
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),

          // Question Content
          child,
        ],
      ),
    );
  }
}
