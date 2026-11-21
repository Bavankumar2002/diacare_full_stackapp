// =============================================================================
// DiaCare - Reminders & Medication Alarms Screen
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/reminder_model.dart';
import '../../providers/reminder_provider.dart';
import 'add_reminder_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  String _selectedFilter = 'all'; // 'all', 'medicine', 'sugar_check', 'lifestyle'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReminderProvider>().fetchReminders();
    });
  }

  Future<void> _confirmDelete(ReminderModel reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reminder?'),
        content: Text('Are you sure you want to remove reminder "${reminder.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.statusDanger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<ReminderProvider>().deleteReminder(reminder.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remProv = context.watch<ReminderProvider>();
    final allReminders = remProv.reminders;

    // Filter reminders
    final filtered = allReminders.where((r) {
      if (_selectedFilter == 'all') return true;
      if (_selectedFilter == 'medicine') return r.type == 'medicine';
      if (_selectedFilter == 'sugar_check') return r.type == 'sugar_check';
      return r.type != 'medicine' && r.type != 'sugar_check';
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication & Checkup Alarms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => remProv.fetchReminders(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppConstants.primaryTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('Add Reminder', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddReminderScreen()),
          );
          remProv.fetchReminders();
        },
      ),
      body: RefreshIndicator(
        onRefresh: () => remProv.fetchReminders(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Filter Chips
              _buildFilterChips(),
              const SizedBox(height: 16),

              // 2. Info Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.primaryTealLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppConstants.primaryTeal.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded, color: AppConstants.primaryTealDark, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Reminders ring on time with sound & vibration even in the background.',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Reminder List
              if (remProv.isLoading && allReminders.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (filtered.isEmpty)
                _buildEmptyState()
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _buildReminderCard(context, item, remProv);
                  },
                ),
              const SizedBox(height: 80), // Fab space
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'All Reminders'},
      {'key': 'medicine', 'label': 'Medicines'},
      {'key': 'sugar_check', 'label': 'Sugar Checks'},
      {'key': 'lifestyle', 'label': 'Water / Lifestyle'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f['label']!),
              selected: isSelected,
              selectedColor: AppConstants.primaryTealLight,
              labelStyle: TextStyle(
                color: isSelected ? AppConstants.primaryTealDark : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              onSelected: (selected) {
                if (selected) setState(() => _selectedFilter = f['key']!);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReminderCard(
    BuildContext context,
    ReminderModel item,
    ReminderProvider remProv,
  ) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Category Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.color, size: 26),
            ),
            const SizedBox(width: 14),

            // Reminder Information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: item.isEnabled ? null : TextDecoration.lineThrough,
                            color: item.isEnabled ? null : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (item.dosage != null && item.dosage!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.dosage!,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryTealLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.formattedTime,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.primaryTealDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.repeatType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Enable / Disable Switch Toggle
            Switch(
              value: item.isEnabled,
              activeThumbColor: AppConstants.primaryTeal,
              onChanged: (_) => remProv.toggleReminder(item.id),
            ),

            // Delete Button
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF94A3B8), size: 20),
              onPressed: () => _confirmDelete(item),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.alarm_off_rounded, size: 52, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'No reminders in this category',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap "+ Add Reminder" to set medicine, sugar check, or water alarms.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
