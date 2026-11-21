// =============================================================================
// DiaCare - Blood Sugar Tracker & Interactive Line Chart Screen
// =============================================================================

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/sugar_reading_model.dart';
import '../../providers/sugar_provider.dart';
import '../../widgets/status_badge.dart';
import 'add_sugar_screen.dart';

class SugarTrackerScreen extends StatefulWidget {
  const SugarTrackerScreen({super.key});

  @override
  State<SugarTrackerScreen> createState() => _SugarTrackerScreenState();
}

class _SugarTrackerScreenState extends State<SugarTrackerScreen> {
  String _selectedFilter = 'all'; // 'today', 'week', 'month', 'all'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SugarProvider>().fetchReadings(_selectedFilter);
    });
  }

  void _onFilterChanged(String filter) {
    setState(() => _selectedFilter = filter);
    context.read<SugarProvider>().fetchReadings(filter);
  }

  Future<void> _confirmDelete(SugarReadingModel reading) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Sugar Reading?'),
        content: Text(
          'Are you sure you want to delete the reading of ${reading.readingValue.toStringAsFixed(0)} mg/dL from ${DateFormat('d MMM yyyy, hh:mm a').format(reading.measuredAt)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.statusDanger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<SugarProvider>().deleteReading(reading.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sugarProv = context.watch<SugarProvider>();
    final readings = sugarProv.readings;
    final stats = sugarProv.stats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Sugar Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => sugarProv.fetchReadings(_selectedFilter),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppConstants.primaryTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Reading', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddSugarScreen()),
          );
          sugarProv.fetchReadings(_selectedFilter);
        },
      ),
      body: RefreshIndicator(
        onRefresh: () => sugarProv.fetchReadings(_selectedFilter),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Period Selector Filter Chips
              _buildFilterChips(),
              const SizedBox(height: 16),

              // 2. Statistical Metrics Row (Average, Highest, Lowest, Logs)
              _buildStatsRow(stats),
              const SizedBox(height: 16),

              // 3. Interactive Line Chart (fl_chart)
              _buildChartCard(readings),
              const SizedBox(height: 20),

              // 4. History List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Reading History',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${readings.length} entries',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 5. History List Items
              if (sugarProv.isLoading && readings.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (readings.isEmpty)
                _buildEmptyState()
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: readings.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = readings[index];
                    return _buildReadingCard(context, item);
                  },
                ),
              const SizedBox(height: 80), // Fab padding
            ],
          ),
        ),
      ),
    );
  }

  // Filter Chips
  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'All Time'},
      {'key': 'today', 'label': 'Today'},
      {'key': 'week', 'label': 'Last 7 Days'},
      {'key': 'month', 'label': 'Last 30 Days'},
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
                if (selected) _onFilterChanged(f['key']!);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // Stats Row
  Widget _buildStatsRow(SugarStatsModel stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            label: 'Average',
            value: stats.average != null ? stats.average!.toStringAsFixed(0) : '--',
            unit: 'mg/dL',
            color: AppConstants.primaryTeal,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatItem(
            label: 'Highest',
            value: stats.highest != null ? stats.highest!.toStringAsFixed(0) : '--',
            unit: 'mg/dL',
            color: AppConstants.statusDanger,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatItem(
            label: 'Lowest',
            value: stats.lowest != null ? stats.lowest!.toStringAsFixed(0) : '--',
            unit: 'mg/dL',
            color: const Color(0xFF0284C7),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          Text(unit, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  // Interactive Line Chart
  Widget _buildChartCard(List<SugarReadingModel> readings) {
    if (readings.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Add at least one reading to view chart analytics.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ),
      );
    }

    // Sort chronologically for chart display
    final sortedReadings = List<SugarReadingModel>.from(readings)
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

    final spots = <FlSpot>[];
    for (int i = 0; i < sortedReadings.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedReadings[i].readingValue));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Glucose Trend (mg/dL)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    _buildLegendPill('Normal (70-140)', AppConstants.statusNormal),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 40,
                  maxY: 300,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 50,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: const Color(0xFFE2E8F0),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        interval: 50,
                        getTitlesWidget: (val, meta) => Text(
                          val.toInt().toString(),
                          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: (spots.length / 4).clamp(1.0, 10.0),
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < sortedReadings.length) {
                            return Text(
                              DateFormat('dd/MM').format(sortedReadings[idx].measuredAt),
                              style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: AppConstants.primaryTeal,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2.5,
                          strokeColor: AppConstants.primaryTeal,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppConstants.primaryTeal.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendPill(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
      ],
    );
  }

  // History Reading Item Card
  Widget _buildReadingCard(BuildContext context, SugarReadingModel item) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Reading Value & Status Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.statusColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bloodtype_rounded,
                color: item.statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${item.readingValue.toStringAsFixed(0)} mg/dL',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: item.statusColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(status: item.readingStatus, fontSize: 10),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.typeLabel,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('hh:mm a, d MMM').format(item.measuredAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  if (item.notes != null && item.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.notes!,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
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
        child: Column(
          children: [
            Icon(Icons.water_drop_outlined, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'No readings found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap "+ Add Reading" to record your blood sugar.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
