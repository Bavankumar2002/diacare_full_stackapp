// =============================================================================
// DiaCare - Step-by-Step Personal & Medical Details Wizard
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

  const PersonalDetailsScreen({super.key, this.isInitialSetup = false});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  int _currentStep = 1; // 1, 2, 3

  // Step 1 Controllers
  final _fullNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _dobController = TextEditingController();
  String _gender = 'Male';
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  double _calculatedBmi = 0.0;

  // Step 2 Controllers
  String _diabetesType = 'Type 2';
  final _yearDiagnosedController = TextEditingController();
  final _medicinesController = TextEditingController();
  final _allergiesController = TextEditingController();

  // Step 3 Controllers
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _doctorNameController = TextEditingController();
  final _doctorHospitalController = TextEditingController();
  final _calorieGoalController = TextEditingController(text: '1800');

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _diabetesTypes = [
    'Type 1',
    'Type 2',
    'Gestational',
    'Pre-diabetes'
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  void _loadExistingProfile() {
    final existing = context.read<AuthProvider>().profile ??
        context.read<ProfileProvider>().profile;
    final user = context.read<AuthProvider>().user;

    if (existing != null) {
      _fullNameController.text = existing.fullName;
      _ageController.text = existing.age > 0 ? existing.age.toString() : '';
      _dobController.text = existing.dob ?? '';
      _gender = existing.gender;
      _heightController.text =
          existing.heightCm > 0 ? existing.heightCm.toString() : '';
      _weightController.text =
          existing.weightKg > 0 ? existing.weightKg.toString() : '';
      _calculatedBmi = existing.bmi;
      _diabetesType = existing.diabetesType;
      _yearDiagnosedController.text =
          existing.yearDiagnosed != null ? existing.yearDiagnosed.toString() : '';
      _medicinesController.text = existing.currentMedicines;
      _allergiesController.text = existing.allergies;
      _emergencyNameController.text = existing.emergencyContactName;
      _emergencyPhoneController.text = existing.emergencyContactPhone;
      _doctorNameController.text = existing.doctorName;
      _doctorHospitalController.text = existing.doctorHospital;
      _calorieGoalController.text = existing.dailyCalorieGoal.toString();
    } else if (user != null) {
      _fullNameController.text = user.name;
    }
  }

  void _recalculateBmi() {
    final h = double.tryParse(_heightController.text) ?? 0.0;
    final w = double.tryParse(_weightController.text) ?? 0.0;
    setState(() {
      _calculatedBmi = ProfileProvider.calculateBMI(h, w);
    });
  }

  Future<void> _selectDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 45),
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
        // Auto-calculate approximate age from DOB
        final age = now.year - picked.year;
        _ageController.text = age.toString();
      });
    }
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

  bool _validateStep1() {
    if (_fullNameController.text.trim().isEmpty) {
      _showToast('Please enter your full name.');
      return false;
    }
    final age = int.tryParse(_ageController.text) ?? 0;
    if (age <= 0 || age > 130) {
      _showToast('Please enter a valid age.');
      return false;
    }
    final height = double.tryParse(_heightController.text) ?? 0;
    final weight = double.tryParse(_weightController.text) ?? 0;
    if (height < 50 || height > 260) {
      _showToast('Please enter a valid height in cm (50-260).');
      return false;
    }
    if (weight < 20 || weight > 300) {
      _showToast('Please enter a valid weight in kg (20-300).');
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    return true; // Optional fields with sensible defaults
  }

  bool _validateStep3() {
    if (_emergencyPhoneController.text.trim().isNotEmpty &&
        _emergencyPhoneController.text.trim().length < 7) {
      _showToast('Emergency phone number should be at least 7 digits.');
      return false;
    }
    return true;
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppConstants.statusDanger),
    );
  }

  Future<void> _handleSave() async {
    if (!_validateStep3()) return;

    final profileData = {
      'full_name': _fullNameController.text.trim(),
      'age': int.tryParse(_ageController.text) ?? 0,
      'dob': _dobController.text.trim().isNotEmpty ? _dobController.text.trim() : null,
      'gender': _gender,
      'height_cm': double.tryParse(_heightController.text) ?? 0.0,
      'weight_kg': double.tryParse(_weightController.text) ?? 0.0,
      'diabetes_type': _diabetesType,
      'year_diagnosed': int.tryParse(_yearDiagnosedController.text),
      'current_medicines': _medicinesController.text.trim(),
      'allergies': _allergiesController.text.trim(),
      'emergency_contact_name': _emergencyNameController.text.trim(),
      'emergency_contact_phone': _emergencyPhoneController.text.trim(),
      'doctor_name': _doctorNameController.text.trim(),
      'doctor_hospital': _doctorHospitalController.text.trim(),
      'daily_calorie_goal': int.tryParse(_calorieGoalController.text) ?? 1800,
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
    final progress = _currentStep / 3.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isInitialSetup ? 'Patient Profile Setup' : 'Edit Profile'),
        automaticallyImplyLeading: !widget.isInitialSetup,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar & Step Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              color: Theme.of(context).cardColor,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step $_currentStep of 3: ${_getStepTitle(_currentStep)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryTeal,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}% Complete',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.primaryTeal),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: _buildCurrentStepContent(),
              ),
            ),

            // Navigation Buttons (Back & Next/Save)
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
                  if (_currentStep > 1) ...[
                    Expanded(
                      flex: 1,
                      child: CustomButton(
                        text: 'Back',
                        isOutlined: true,
                        onPressed: () => setState(() => _currentStep--),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: _currentStep == 3 ? 'Save Profile' : 'Continue',
                      icon: _currentStep == 3 ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                      isLoading: profileProv.isLoading,
                      onPressed: () {
                        if (_currentStep == 1) {
                          if (_validateStep1()) setState(() => _currentStep = 2);
                        } else if (_currentStep == 2) {
                          if (_validateStep2()) setState(() => _currentStep = 3);
                        } else {
                          _handleSave();
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

  String _getStepTitle(int step) {
    switch (step) {
      case 1:
        return 'Personal Info & BMI';
      case 2:
        return 'Diabetes Profile';
      case 3:
      default:
        return 'Care Network & Goals';
    }
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
      default:
        return _buildStep3();
    }
  }

  // STEP 1: Personal Info & Height/Weight/BMI
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tell us about yourself',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'This helps calculate your Body Mass Index (BMI) and tailor recommendations.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 20),

        CustomTextField(
          controller: _fullNameController,
          label: 'Full Name *',
          hint: 'e.g. Ramesh Kumar',
          prefixIcon: Icons.badge_outlined,
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _ageController,
                label: 'Age (Years) *',
                hint: 'e.g. 58',
                prefixIcon: Icons.cake_outlined,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gender *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(14),
                      color: Theme.of(context).cardColor,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _gender,
                        isExpanded: true,
                        items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (val) => setState(() => _gender = val ?? 'Male'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        CustomTextField(
          controller: _dobController,
          label: 'Date of Birth (Optional)',
          hint: 'YYYY-MM-DD',
          prefixIcon: Icons.calendar_month_outlined,
          readOnly: true,
          onTap: _selectDob,
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _heightController,
                label: 'Height (cm) *',
                hint: 'e.g. 172',
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
                hint: 'e.g. 74.5',
                prefixIcon: Icons.monitor_weight_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _recalculateBmi(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Auto-calculated BMI Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getBmiColor(_calculatedBmi).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _getBmiColor(_calculatedBmi).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getBmiColor(_calculatedBmi).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.speed_rounded, color: _getBmiColor(_calculatedBmi), size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Auto-Calculated BMI',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getBmiStatusText(_calculatedBmi),
                      style: TextStyle(
                        fontSize: 16,
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
    );
  }

  // STEP 2: Diabetes Details & Medicines
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Diabetes & Health Background',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Knowing your diabetes condition helps ensure accurate reminders and tips.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),

        const Text('Diabetes Classification *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _diabetesTypes.map((type) {
            final isSelected = _diabetesType == type;
            return ChoiceChip(
              label: Text(type),
              selected: isSelected,
              selectedColor: AppConstants.primaryTealLight,
              labelStyle: TextStyle(
                color: isSelected ? AppConstants.primaryTealDark : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (selected) {
                if (selected) setState(() => _diabetesType = type);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        CustomTextField(
          controller: _yearDiagnosedController,
          label: 'Year Diagnosed (Optional)',
          hint: 'e.g. 2018',
          prefixIcon: Icons.history_edu_rounded,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),

        CustomTextField(
          controller: _medicinesController,
          label: 'Current Medicines / Dosages',
          hint: 'e.g. Metformin 500mg (twice daily), Glimepiride 1mg',
          prefixIcon: Icons.medication_outlined,
          maxLines: 2,
        ),
        const SizedBox(height: 16),

        CustomTextField(
          controller: _allergiesController,
          label: 'Known Allergies (if any)',
          hint: 'e.g. Penicillin, Sulfa drugs, Peanuts',
          prefixIcon: Icons.warning_amber_rounded,
        ),
      ],
    );
  }

  // STEP 3: Care Network & Daily Targets
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Care Network & Daily Goals',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Add your emergency contact and doctor so help is just one tap away during sudden sugar spikes or drops.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 20),

        CustomTextField(
          controller: _emergencyNameController,
          label: 'Emergency Contact Name',
          hint: 'e.g. Priya (Daughter) or Spouse',
          prefixIcon: Icons.contact_emergency_outlined,
        ),
        const SizedBox(height: 16),

        CustomTextField(
          controller: _emergencyPhoneController,
          label: 'Emergency Contact Phone Number',
          hint: 'e.g. 9840012345 (One-tap call on alert)',
          prefixIcon: Icons.phone_in_talk_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),

        CustomTextField(
          controller: _doctorNameController,
          label: "Doctor's Name",
          hint: 'e.g. Dr. A. Subramanian',
          prefixIcon: Icons.local_hospital_outlined,
        ),
        const SizedBox(height: 16),

        CustomTextField(
          controller: _doctorHospitalController,
          label: 'Hospital / Clinic Name',
          hint: 'e.g. Apollo Hospital / City Diabetes Center',
          prefixIcon: Icons.apartment_rounded,
        ),
        const SizedBox(height: 16),

        CustomTextField(
          controller: _calorieGoalController,
          label: 'Daily Calorie Target (kcal)',
          hint: 'e.g. 1800',
          prefixIcon: Icons.local_fire_department_outlined,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }
}
