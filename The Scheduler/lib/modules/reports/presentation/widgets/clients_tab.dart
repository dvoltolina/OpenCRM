import 'package:flutter/material.dart';

import '../../../../data/models/analytics_metrics.dart';
import 'metrics_widgets.dart';

/// Clients Tab - Client metrics and retention stats
class ClientsTab extends StatelessWidget {
  const ClientsTab({required this.metrics, super.key});

  final AnalyticsMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MetricsGrid(
            metrics: [
              MetricCard(
                title: 'Total Clients',
                value: metrics.totalClients.toString(),
                subtitle: '',
                icon: Icons.people,
                color: Colors.blue,
              ),
              MetricCard(
                title: 'New Clients',
                value: metrics.newClients.toString(),
                subtitle: 'In this period',
                icon: Icons.person_add,
                color: Colors.green,
              ),
              MetricCard(
                title: 'Returning Clients',
                value: metrics.returningClients.toString(),
                subtitle:
                    '${(metrics.clientRetentionRate * 100).toStringAsFixed(1)}% retention',
                icon: Icons.repeat,
                color: Colors.purple,
              ),
              MetricCard(
                title: 'Active Clients',
                value: metrics.activeClients.toString(),
                subtitle: '${metrics.inactiveClients} inactive',
                icon: Icons.check_circle,
                color: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
