// =============================================================================
// DiaCare - Add Reminder Screen
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/reminder_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddReminderScreen extends StatefulWidget {
  const AddReminderScreen({super.key});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _dosageController = TextEditingController();

  String _type = 'medicine';
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  String _repeatType = 'daily';

  final List<Map<String, dynamic>> _reminderTypes = [
    {'key': 'medicine', 'label': 'Medicine / Tablet', 'icon': Icons.medication_rounded, 'color': AppConstants.primaryTeal},
    {'key': 'sugar_check', 'label': 'Sugar Test', 'icon': Icons.bloodtype_rounded, 'color': const Color(0xFFEF4444)},
    {'key': 'water', 'label': 'Drink Water', 'icon': Icons.water_drop_rounded, 'color': const Color(0xFF0284C7)},
    {'key': 'meal', 'label': 'Meal / Snack Time', 'icon': Icons.restaurant_rounded, 'color': const Color(0xFF10B981)},
    {'key': 'exercise', 'label': 'Walk / Exercise', 'icon': Icons.directions_walk_rounded, 'color': const Color(0xFFF59E0B)},
    {'key': 'doctor', 'label': 'Doctor Appointment', 'icon': Icons.local_hospital_rounded, 'color': const Color(0xFF8B5CF6)},
  ];

  final List<Map<String, String>> _repeatOptions = [
    {'key': 'daily', 'label': 'Every Day'},
    {'key': 'weekdays', 'label': 'Mon - Fri'},
    {'key': 'weekends', 'label': 'Sat - Sun'},
    {'key': 'once', 'label': 'Once Only'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final dosage = _dosageController.text.trim();
    final timeStr =
        '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}:00';

    final remProv = context.read<ReminderProvider>();
    final success = await remProv.addReminder(
      title: title,
      type: _type,
      dosage: dosage,
      time: timeStr,
      repeatType: _repeatType,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder set successfully!'),
          backgroundColor: AppConstants.statusNormal,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(remProv.errorMessage ?? 'Failed to set reminder.'),
          backgroundColor: AppConstants.statusDanger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final remProv = context.watch<ReminderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Reminder'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Reminder Category Picker
                const Text(
                  'Reminder Category',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _reminderTypes.length,
                  itemBuilder: (context, i) {
                    final item = _reminderTypes[i];
                    final isSel = _type == item['key'];
                    final color = item['color'] as Color;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _type = item['key'] as String;
                          // Provide automatic title hint based on category
                          if (_type == 'sugar_check' && _titleController.text.isEmpty) {
                            _titleController.text = 'Morning Fasting Glucose Check';
                          } else if (_type == 'water' && _titleController.text.isEmpty) {
                            _titleController.text = 'Drink Glass of Water';
                          } else if (_type == 'exercise' && _titleController.text.isEmpty) {
                            _titleController.text = '15-Minute Post-Meal Walk';
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSel ? color.withValues(alpha: 0.12) : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSel ? color : const Color(0xFFE2E8F0),
                            width: isSel ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(item['icon'] as IconData, color: color, size: 28),
                            const SizedBox(height: 6),
                            Text(
                              item['label'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                color: isSel ? color : Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // 2. Reminder Title
                CustomTextField(
                  controller: _titleController,
                  label: 'Reminder Title *',
                  hint: _type == 'medicine' ? 'e.g. Metformin 500mg' : 'e.g. Check Sugar Before Dinner',
                  prefixIcon: Icons.edit_note_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter a title.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 3. Dosage / Instructions (if medicine)
                CustomTextField(
                  controller: _dosageController,
                  label: _type == 'medicine' ? 'Dosage & Instructions' : 'Notes / Instructions',
                  hint: _type == 'medicine' ? 'e.g. 1 tablet with warm water after food' : 'e.g. Record fasting value in app',
                  prefixIcon: Icons.info_outline_rounded,
                ),
                const SizedBox(height: 20),

                // 4. Time Picker
                const Text('Alarm Time', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickTime,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(14),
                      color: Theme.of(context).cardColor,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.alarm_rounded, color: AppConstants.primaryTeal, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              _time.format(context),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_drop_down_rounded),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Repeat Frequency
                const Text('Repeat Frequency', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _repeatOptions.map((r) {
                    final isSel = _repeatType == r['key'];
                    return ChoiceChip(
                      label: Text(r['label']!),
                      selected: isSel,
                      selectedColor: AppConstants.primaryTealLight,
                      labelStyle: TextStyle(
                        color: isSel ? AppConstants.primaryTealDark : Colors.black87,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _repeatType = r['key']!);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // Save Button
                CustomButton(
                  text: 'Set Alarm & Notification',
                  icon: Icons.check_circle_rounded,
                  isLoading: remProv.isLoading,
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
