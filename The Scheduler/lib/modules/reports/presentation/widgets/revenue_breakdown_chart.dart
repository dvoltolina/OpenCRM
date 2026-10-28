import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../data/models/analytics_metrics.dart';

/// Pie chart showing revenue breakdown by service or provider
class RevenueBreakdownChart extends StatefulWidget {
  const RevenueBreakdownChart({super.key, required this.metrics});

  final AnalyticsMetrics metrics;

  @override
  State<RevenueBreakdownChart> createState() => _RevenueBreakdownChartState();
}

class _RevenueBreakdownChartState extends State<RevenueBreakdownChart> {
  bool _showByService = true;
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final revenueData = _showByService
        ? widget.metrics.revenueByService
        : widget.metrics.revenueByProvider;

    if (revenueData.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No revenue data available',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    // Calculate total revenue
    final totalRevenue =
        revenueData.values.fold<int>(0, (sum, value) => sum + value);

    // Prepare pie chart sections
    final sections = <PieChartSectionData>[];
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    var colorIndex = 0;
    var sectionIndex = 0;
    for (final entry in revenueData.entries) {
      final percentage = totalRevenue > 0 ? (entry.value / totalRevenue) * 100 : 0.0;

      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: entry.value.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: _touchedIndex == sectionIndex ? 110 : 100,
          titleStyle: theme.textTheme.bodyMedium?.copyWith(
            fontSize: _touchedIndex == sectionIndex ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );

      colorIndex++;
      sectionIndex++;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Revenue Breakdown',
                  style: theme.textTheme.titleMedium,
                ),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      label: Text('By Service'),
                      icon: Icon(Icons.local_offer, size: 16),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text('By Provider'),
                      icon: Icon(Icons.person, size: 16),
                    ),
                  ],
                  selected: {_showByService},
                  onSelectionChanged: (Set<bool> selected) {
                    setState(() {
                      _showByService = selected.first;
                      _touchedIndex = -1;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                // Pie chart
                Expanded(
                  flex: 2,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                _touchedIndex = -1;
                                return;
                              }
                              _touchedIndex =
                                  pieTouchResponse.touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: sections,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Legend
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...revenueData.entries.toList().asMap().entries.map((mapEntry) {
                        final index = mapEntry.key;
                        final entry = mapEntry.value;
                        final revenue = entry.value / 100.0;
                        final color = colors[index % colors.length];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: theme.textTheme.bodySmall,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '\$${revenue.toStringAsFixed(2)}',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
