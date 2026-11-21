// =============================================================================
// DiaCare - Add Blood Sugar Reading Screen
// =============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/sugar_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/danger_alert_dialog.dart';
import '../../widgets/status_badge.dart';

class AddSugarScreen extends StatefulWidget {
  const AddSugarScreen({super.key});

  @override
  State<AddSugarScreen> createState() => _AddSugarScreenState();
}

class _AddSugarScreenState extends State<AddSugarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController(text: '110');
  final _notesController = TextEditingController();

  String _readingType = 'fasting';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  final List<Map<String, String>> _types = [
    {'key': 'fasting', 'label': 'Fasting (Morning)'},
    {'key': 'before_meal', 'label': 'Before Meal'},
    {'key': 'after_meal', 'label': 'After Meal (2 hrs)'},
    {'key': 'bedtime', 'label': 'Bedtime'},
    {'key': 'random', 'label': 'Random Check'},
  ];

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _calculateStatus(double val) {
    if (val < 70) return 'Low';
    if (val <= 140) return 'Normal';
    return 'High';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final double readingValue = double.parse(_valueController.text.trim());
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final timeStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00';

    final sugarProv = context.read<SugarProvider>();
    final alert = await sugarProv.addReading(
      value: readingValue,
      type: _readingType,
      date: dateStr,
      time: timeStr,
      notes: _notesController.text.trim(),
    );

    if (!mounted) return;

    if (alert != null && alert.isDanger) {
      // Show Urgent Alert Dialog with instructions & emergency dialer
      await DangerAlertDialog.show(
        context,
        alert: alert,
        readingValue: readingValue,
      );
      if (mounted) Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reading saved successfully!'),
          backgroundColor: AppConstants.statusNormal,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sugarProv = context.watch<SugarProvider>();
    final currentVal = double.tryParse(_valueController.text) ?? 110.0;
    final currentStatus = _calculateStatus(currentVal);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Sugar Reading'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reading Input with Large Accessible Controls
                const Text(
                  'Blood Glucose Level',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton.filledTonal(
                            icon: const Icon(Icons.remove_rounded, size: 28),
                            onPressed: () {
                              final v = (double.tryParse(_valueController.text) ?? 100) - 5;
                              if (v >= 30) {
                                setState(() => _valueController.text = v.toInt().toString());
                              }
                            },
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 120,
                            child: TextFormField(
                              controller: _valueController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: AppConstants.primaryTeal,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (val) {
                                final n = double.tryParse(val ?? '');
                                if (n == null || n < 20 || n > 700) {
                                  return '20-700 mg/dL';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.add_rounded, size: 28),
                            onPressed: () {
                              final v = (double.tryParse(_valueController.text) ?? 100) + 5;
                              if (v <= 600) {
                                setState(() => _valueController.text = v.toInt().toString());
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'mg/dL',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 12),
                      StatusBadge(status: currentStatus, fontSize: 13),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Reading Type Selector
                const Text(
                  'Reading Context / Time',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _types.map((t) {
                    final isSelected = _readingType == t['key'];
                    return ChoiceChip(
                      label: Text(t['label']!),
                      selected: isSelected,
                      selectedColor: AppConstants.primaryTealLight,
                      labelStyle: TextStyle(
                        color: isSelected ? AppConstants.primaryTealDark : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _readingType = t['key']!);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Date & Time Selectors
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(14),
                            color: Theme.of(context).cardColor,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 20, color: AppConstants.primaryTeal),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  DateFormat('d MMM yyyy').format(_selectedDate),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _pickTime,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(14),
                            color: Theme.of(context).cardColor,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 20, color: AppConstants.primaryTeal),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedTime.format(context),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Note Field
                CustomTextField(
                  controller: _notesController,
                  label: 'Notes (Optional)',
                  hint: 'e.g. Felt slightly dizzy, ate extra sweet at wedding',
                  prefixIcon: Icons.notes_rounded,
                  maxLines: 2,
                ),
                const SizedBox(height: 32),

                // Save Button
                CustomButton(
                  text: 'Save Glucose Reading',
                  icon: Icons.check_circle_rounded,
                  isLoading: sugarProv.isLoading,
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
