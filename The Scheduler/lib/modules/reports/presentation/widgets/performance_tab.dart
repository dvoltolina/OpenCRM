import 'package:flutter/material.dart';

import '../../../../data/models/analytics_metrics.dart';
import 'provider_utilization_chart.dart';

/// Performance Tab - KPI metrics and performance indicators
class PerformanceTab extends StatelessWidget {
  const PerformanceTab({required this.metrics, super.key});

  final AnalyticsMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Key Performance Indicators', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          PerformanceMetricCard(
            title: 'Utilization Rate',
            value: '${(metrics.utilizationRate * 100).toStringAsFixed(1)}%',
            description:
                'Percentage of scheduled appointments that were completed',
          ),
          PerformanceMetricCard(
            title: 'Cancellation Rate',
            value: '${(metrics.cancellationRate * 100).toStringAsFixed(1)}%',
            description: 'Percentage of appointments that were cancelled',
          ),
          PerformanceMetricCard(
            title: 'No-Show Rate',
            value: '${(metrics.noShowRate * 100).toStringAsFixed(1)}%',
            description: 'Percentage of appointments marked as no-show',
          ),
          PerformanceMetricCard(
            title: 'Client Retention',
            value: '${(metrics.clientRetentionRate * 100).toStringAsFixed(1)}%',
            description: 'Percentage of clients with multiple appointments',
          ),
          PerformanceMetricCard(
            title: 'Average Lead Time',
            value: '${metrics.averageBookingLeadDays.toStringAsFixed(1)} days',
            description:
                'Average days between booking and appointment',
          ),
          PerformanceMetricCard(
            title: 'Average Revenue',
            value: '\$${metrics.averageRevenuePerAppointment.toStringAsFixed(2)}',
            description: 'Average revenue per appointment',
          ),
          const SizedBox(height: 32),
          Text('Top Performers', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          if (metrics.topProviderByAppointments != null)
            ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: const Text('Top Provider'),
              subtitle: Text(metrics.topProviderByAppointments!),
            ),
          if (metrics.topServiceByAppointments != null)
            ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: const Text('Top Service'),
              subtitle: Text(metrics.topServiceByAppointments!),
            ),
          if (metrics.busiestDayOfWeek != null)
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.blue),
              title: const Text('Busiest Day'),
              subtitle: Text(metrics.busiestDayOfWeek!),
            ),
          if (metrics.peakHourOfDay != null)
            ListTile(
              leading: const Icon(Icons.schedule, color: Colors.green),
              title: const Text('Peak Hour'),
              subtitle: Text('${metrics.peakHourOfDay}:00'),
            ),
          const SizedBox(height: 32),
          ProviderUtilizationChart(metrics: metrics),
        ],
      ),
    );
  }
}

/// Reusable Performance Metric Card Widget
class PerformanceMetricCard extends StatelessWidget {
  const PerformanceMetricCard({
    required this.title,
    required this.value,
    required this.description,
    super.key,
  });

  final String title;
  final String value;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
