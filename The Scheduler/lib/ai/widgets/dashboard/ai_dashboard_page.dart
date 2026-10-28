/// AI Dashboard page with tab navigation.
///
/// Provides a unified view of AI predictions, routes, and automation.
///
/// Agent AI-12: AI Dashboard & UI Components
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/security_context.dart';
import '../../providers/prediction_providers.dart';
import '../predictions/predictions_tab.dart';
import '../routes/routes_tab.dart';
import '../automation/automation_tab.dart';

/// Main AI Dashboard page with tabbed navigation.
class AiDashboardPage extends ConsumerStatefulWidget {
  const AiDashboardPage({
    super.key,
    required this.securityContext,
    this.initialTab = 0,
  });

  final SecurityContext securityContext;
  final int initialTab;

  @override
  ConsumerState<AiDashboardPage> createState() => _AiDashboardPageState();
}

class _AiDashboardPageState extends ConsumerState<AiDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final healthAsync = ref.watch(aiHealthStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Insights'),
        actions: [
          // AI Health indicator
          healthAsync.when(
            data: (health) => _HealthIndicator(
              isHealthy: health.overallStatus == AiServiceStatus.healthy,
            ),
            loading: () => const _HealthIndicator(isHealthy: null),
            error: (_, __) => const _HealthIndicator(isHealthy: false),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.analytics_outlined),
              text: 'Predictions',
            ),
            Tab(
              icon: Icon(Icons.route_outlined),
              text: 'Routes',
            ),
            Tab(
              icon: Icon(Icons.auto_awesome_outlined),
              text: 'Automation',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          PredictionsTab(securityContext: widget.securityContext),
          RoutesTab(securityContext: widget.securityContext),
          AutomationTab(securityContext: widget.securityContext),
        ],
      ),
    );
  }
}

/// Health status indicator widget.
class _HealthIndicator extends StatelessWidget {
  const _HealthIndicator({required this.isHealthy});

  final bool? isHealthy;

  @override
  Widget build(BuildContext context) {
    final color = switch (isHealthy) {
      true => Colors.green,
      false => Colors.red,
      null => Colors.grey,
    };

    final tooltip = switch (isHealthy) {
      true => 'AI Services Healthy',
      false => 'AI Services Degraded',
      null => 'Checking AI Status...',
    };

    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'AI',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).appBarTheme.foregroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// AI service status enum for health checks.
enum AiServiceStatus {
  healthy,
  degraded,
  unavailable,
}
