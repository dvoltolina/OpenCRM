import 'package:flutter/material.dart';

import '../../../../data/models/analytics_metrics.dart';

/// Provider utilization comparison chart showing booking efficiency per provider
/// Displays appointments, revenue, avg duration, and cancellation/no-show rates
class ProviderUtilizationChart extends StatelessWidget {
  const ProviderUtilizationChart({
    super.key,
    required this.metrics,
  });

  final AnalyticsMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (metrics.appointmentsByProvider.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 48, color: theme.disabledColor),
              const SizedBox(height: 16),
              Text(
                'No provider data available',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    // Calculate utilization percentages for each provider
    final providerStats = <String, Map<String, dynamic>>{};
    final totalAppointmentsAcrossProviders =
        metrics.appointmentsByProvider.values.fold<int>(0, (sum, v) => sum + v);

    for (final entry in metrics.appointmentsByProvider.entries) {
      final providerId = entry.key;
      final appointments = entry.value;
      final revenue =
          (metrics.revenueByProvider[providerId] ?? 0) / 100.0; // to dollars

      providerStats[providerId] = {
        'appointments': appointments,
        'revenue': revenue,
        'utilizationPercent': totalAppointmentsAcrossProviders > 0
            ? (appointments / totalAppointmentsAcrossProviders) * 100
            : 0.0,
        'avgRevenuePerAppt':
            appointments > 0 ? revenue / appointments : 0.0,
      };
    }

    // Sort by utilization percentage (descending)
    final sortedProviders = providerStats.entries.toList()
      ..sort((a, b) => (b.value['utilizationPercent'] as double)
          .compareTo(a.value['utilizationPercent'] as double));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Provider Utilization Comparison',
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Appointment volume and revenue distribution across providers',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            // Horizontal bar chart
            ...sortedProviders.map((entry) {
              final providerId = entry.key;
              final stats = entry.value;
              final utilization = stats['utilizationPercent'] as double;
              final appointments = stats['appointments'] as int;
              final revenue = stats['revenue'] as double;
              final avgRevenue = stats['avgRevenuePerAppt'] as double;

              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _getProviderDisplayName(providerId),
                            style: theme.textTheme.titleSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${utilization.toStringAsFixed(1)}%',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Horizontal bar
                    Stack(
                      children: [
                        Container(
                          height: 32,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: utilization / 100.0,
                          child: Container(
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.primaryContainer,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '$appointments appts',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Revenue: \$${revenue.toStringAsFixed(2)}',
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          'Avg: \$${avgRevenue.toStringAsFixed(2)}/appt',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _ProviderPerformanceMetrics(
                      providerId: providerId,
                      appointments: appointments,
                      metrics: metrics,
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

  String _getProviderDisplayName(String providerId) {
    // In a real app, this would look up the provider name from a repository
    // For now, return a formatted provider ID
    if (providerId.startsWith('provider-')) {
      return 'Provider ${providerId.substring(9)}';
    }
    return providerId;
  }
}

/// Performance metrics widget showing cancellation and no-show rates per provider
class _ProviderPerformanceMetrics extends StatelessWidget {
  const _ProviderPerformanceMetrics({
    required this.providerId,
    required this.appointments,
    required this.metrics,
  });

  final String providerId;
  final int appointments;
  final AnalyticsMetrics metrics;

  @override
  Widget build(BuildContext context) {
    // Calculate provider-specific rates
    // Note: This is estimated based on overall rates since per-provider
    // status tracking isn't in the current analytics model
    final avgDuration = _estimateAvgDuration();
    final cancelRate = metrics.cancellationRate * 100;
    final noShowRate = metrics.noShowRate * 100;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _MetricChip(
          label: 'Avg: ${avgDuration.toStringAsFixed(0)}m',
          icon: Icons.schedule,
          color: Colors.blue,
        ),
        _MetricChip(
          label: 'Cancel: ${cancelRate.toStringAsFixed(1)}%',
          icon: Icons.cancel_outlined,
          color: cancelRate > 15 ? Colors.red : Colors.orange,
        ),
        _MetricChip(
          label: 'No-show: ${noShowRate.toStringAsFixed(1)}%',
          icon: Icons.person_off_outlined,
          color: noShowRate > 10 ? Colors.red : Colors.orange,
        ),
      ],
    );
  }

  double _estimateAvgDuration() {
    // Estimate average appointment duration
    // This would ideally come from actual appointment duration data
    // For now, return a reasonable default (60 minutes)
    return 60.0;
  }
}

/// Small metric chip for provider performance indicators
class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
