import 'package:flutter/material.dart';

import '../../../../data/models/analytics_metrics.dart';

/// Group Sessions Tab - Group session metrics and utilization reporting
class GroupSessionsTab extends StatelessWidget {
  const GroupSessionsTab({required this.metrics, super.key});

  final AnalyticsMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (metrics.totalGroupSessions == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text(
              'No Group Sessions',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'No group sessions were found in the selected date range.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Group Session Metrics', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          _GroupMetricsGrid(metrics: metrics),
          const SizedBox(height: 32),
          Text('Utilization Insights', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          _GroupSessionInsightCard(
            title: 'Average Attendees per Session',
            value: metrics.averageAttendeesPerGroupSession.toStringAsFixed(1),
            icon: Icons.person,
          ),
          _GroupSessionInsightCard(
            title: 'Average Capacity per Session',
            value: metrics.averageCapacityPerGroupSession.toStringAsFixed(1),
            icon: Icons.event_seat_outlined,
          ),
          if (metrics.topGroupSessionService != null)
            _GroupSessionInsightCard(
              title: 'Most Popular Service',
              value: metrics.topGroupSessionService!,
              icon: Icons.star,
            ),
          const SizedBox(height: 32),
          Text('Revenue & Performance', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          _RevenueComparisonCard(metrics: metrics),
          const SizedBox(height: 16),
          _CapacityUtilizationChart(metrics: metrics),
          const SizedBox(height: 32),
          if (metrics.groupSessionsByService.isNotEmpty) ...[
            Text('Sessions by Service', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            ...metrics.groupSessionsByService.entries.map((entry) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.withValues(alpha: 0.1),
                    child: const Icon(Icons.design_services, color: Colors.teal),
                  ),
                  title: Text(entry.key),
                  trailing: Chip(
                    label: Text('${entry.value} sessions'),
                    backgroundColor: Colors.teal.withValues(alpha: 0.1),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

/// Grid of group session metric cards
class _GroupMetricsGrid extends StatelessWidget {
  const _GroupMetricsGrid({required this.metrics});

  final AnalyticsMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _GroupMetricCard(
          title: 'Total Sessions',
          value: metrics.totalGroupSessions.toString(),
          subtitle: 'In selected period',
          icon: Icons.groups,
          color: Colors.teal,
        ),
        _GroupMetricCard(
          title: 'Total Attendees',
          value: metrics.totalGroupSessionAttendees.toString(),
          subtitle: 'Across all sessions',
          icon: Icons.people,
          color: Colors.blue,
        ),
        _GroupMetricCard(
          title: 'Total Capacity',
          value: metrics.totalGroupSessionCapacity.toString(),
          subtitle: 'Available seats',
          icon: Icons.event_seat,
          color: Colors.purple,
        ),
        _GroupMetricCard(
          title: 'Fill Rate',
          value:
              '${(metrics.groupSessionUtilizationRate * 100).toStringAsFixed(1)}%',
          subtitle: 'Seats filled vs available',
          icon: Icons.pie_chart,
          color: metrics.groupSessionUtilizationRate >= 0.7
              ? Colors.green
              : metrics.groupSessionUtilizationRate >= 0.4
                  ? Colors.orange
                  : Colors.red,
        ),
      ],
    );
  }
}

/// Metric card for group session stats
class _GroupMetricCard extends StatelessWidget {
  const _GroupMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(color: color),
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}

/// Insight card for group session metrics
class _GroupSessionInsightCard extends StatelessWidget {
  const _GroupSessionInsightCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal),
        title: Text(title),
        trailing: Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.teal,
          ),
        ),
      ),
    );
  }
}

/// Revenue comparison card comparing group sessions vs 1:1 appointments
class _RevenueComparisonCard extends StatelessWidget {
  const _RevenueComparisonCard({required this.metrics});

  final AnalyticsMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate revenue from group sessions vs regular appointments
    // This is a simplified estimation based on service data
    final totalRevenue = metrics.totalRevenueDollars;
    final groupSessionRevenue = _estimateGroupSessionRevenue();
    final regularRevenue = totalRevenue - groupSessionRevenue;

    final groupPercentage = totalRevenue > 0
        ? (groupSessionRevenue / totalRevenue) * 100
        : 0.0;
    final regularPercentage = 100 - groupPercentage;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attach_money, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Revenue Distribution',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.teal,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Group Sessions', style: theme.textTheme.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${groupSessionRevenue.toStringAsFixed(2)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.teal,
                        ),
                      ),
                      Text(
                        '${groupPercentage.toStringAsFixed(1)}% of total',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('1:1 Appointments', style: theme.textTheme.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${regularRevenue.toStringAsFixed(2)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        '${regularPercentage.toStringAsFixed(1)}% of total',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Visual bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Row(
                children: [
                  if (groupPercentage > 0)
                    Expanded(
                      flex: groupPercentage.round(),
                      child: Container(
                        height: 8,
                        color: Colors.teal,
                      ),
                    ),
                  if (regularPercentage > 0)
                    Expanded(
                      flex: regularPercentage.round(),
                      child: Container(
                        height: 8,
                        color: Colors.blue,
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

  double _estimateGroupSessionRevenue() {
    // Estimate revenue from group sessions based on service data
    // This is a simplified calculation
    double total = 0.0;
    for (final entry in metrics.groupSessionsByService.entries) {
      final serviceName = entry.key;
      final revenuePerService = metrics.revenueByService[serviceName] ?? 0;
      // Estimate: assume revenue is proportional to session count
      total += (revenuePerService / 100.0);
    }
    return total;
  }
}

/// Capacity utilization chart showing fill rates per session
class _CapacityUtilizationChart extends StatelessWidget {
  const _CapacityUtilizationChart({required this.metrics});

  final AnalyticsMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (metrics.attendeesByGroupSession.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate fill rate for each session
    final sessionFillRates = <String, double>{};
    for (final entry in metrics.attendeesByGroupSession.entries) {
      final sessionId = entry.key;
      final attendees = entry.value;
      // Estimate capacity (this would ideally come from appointment data)
      final estimatedCapacity = (attendees / metrics.groupSessionUtilizationRate).ceil();
      final fillRate = estimatedCapacity > 0 ? attendees / estimatedCapacity : 0.0;
      sessionFillRates[sessionId] = fillRate;
    }

    // Sort by fill rate
    final sortedSessions = sessionFillRates.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Session Capacity Utilization',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Percentage of seats filled per group session',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            ...sortedSessions.take(10).map((entry) {
              final sessionId = entry.key;
              final fillRate = entry.value;
              final attendees = metrics.attendeesByGroupSession[sessionId] ?? 0;
              final color = fillRate >= 0.8
                  ? Colors.green
                  : fillRate >= 0.5
                      ? Colors.orange
                      : Colors.red;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Session ${sessionId.substring(0, 8)}...',
                            style: theme.textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${(fillRate * 100).toStringAsFixed(0)}% ($attendees)',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: fillRate,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      color: color,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
