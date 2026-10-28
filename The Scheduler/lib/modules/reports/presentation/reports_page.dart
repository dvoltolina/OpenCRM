import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/providers.dart';
import '../../../data/models/user_role.dart';
import '../../../core/ui/ui_exports.dart';
import '../../../core/ui/components/components.dart';
import '../../../data/models/analytics_metrics.dart';
import 'widgets/appointment_volume_chart.dart';
import 'widgets/clients_tab.dart';
import 'widgets/group_sessions_tab.dart';
import 'widgets/metrics_widgets.dart';
import 'widgets/peak_times_heatmap.dart';
import 'widgets/performance_tab.dart';
import 'widgets/revenue_breakdown_chart.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateRangePeriod _selectedPeriod = DateRangePeriod.last30Days;
  late DateRangeFilter _dateRange;
  AnalyticsMetrics? _metrics;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _dateRange = _selectedPeriod.toDateRange();
    _loadMetrics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = ref.read(authStateServiceProvider);
      final context = await authService.getCurrentSecurityContext();
      if (context == null) throw Exception('Not authenticated');

      final analyticsService = ref.read(analyticsServiceProvider);

      final metrics = await analyticsService.computeMetrics(
        context: context,
        startDate: _dateRange.startDate,
        endDate: _dateRange.endDate,
      );

      setState(() {
        _metrics = metrics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onPeriodChanged(DateRangePeriod? period) {
    if (period == null) return;
    setState(() {
      _selectedPeriod = period;
      _dateRange = period.toDateRange();
    });
    _loadMetrics();
  }

  Future<void> _showCustomDatePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: _dateRange.startDate,
        end: _dateRange.endDate,
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedPeriod = DateRangePeriod.custom;
        _dateRange = DateRangeFilter(
          startDate: picked.start,
          endDate: picked.end,
          period: DateRangePeriod.custom,
        );
      });
      _loadMetrics();
    }
  }

  Future<void> _exportToCSV(BuildContext context) async {
    if (_metrics == null) return;

    try {
      final authService = ref.read(authStateServiceProvider);
      final securityContext = await authService.getCurrentSecurityContext();
      if (securityContext == null) {
        throw Exception('Not authenticated');
      }

      final exportService = ref.read(exportServiceProvider);
      final filename =
          'analytics-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.csv';

      final file = await exportService.exportToCsv(
        _metrics!,
        filename: filename,
        context: securityContext,
      );

      if (context.mounted) {
        ScreenReaderAnnouncements.announceSuccess(
          context,
          'Report exported successfully',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to ${file.path}'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScreenReaderAnnouncements.announceError(context, 'Export failed');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final securityContextAsync = ref.watch(securityContextProvider);

    // RBAC check: only admin/owner can access reports
    return securityContextAsync.when(
      data: (securityContext) {
        if (securityContext == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!securityContext.role.canManageAllAppointments) {
          return const Center(
            child: Text('Access denied. Admin privileges required.'),
          );
        }

        return _buildReportsContent(context, config);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('Error loading security context: $error'),
      ),
    );
  }

  Widget _buildReportsContent(BuildContext context, dynamic config) {
    final theme = Theme.of(context);

    if (!config.featureFlags.enableReporting) {
      return Scaffold(
        body: SafeArea(
          top: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics_outlined, size: AppIconSize.xl, color: theme.disabledColor),
                VSpace.md,
                Text(
                  'Reporting is disabled',
                  style: theme.textTheme.titleLarge,
                ),
                VSpace.xs,
                Text(
                  'Upgrade to Professional or Enterprise to access reports',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Controls row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  // Date range dropdown
                  Expanded(
                    child: DropdownButton<DateRangePeriod>(
                      value: _selectedPeriod,
                      onChanged: _onPeriodChanged,
                      isExpanded: true,
                      items: DateRangePeriod.values
                          .where((p) => p != DateRangePeriod.custom)
                          .map((period) => DropdownMenuItem(
                                value: period,
                                child: Text(period.displayName),
                              ))
                          .toList(),
                    ),
                  ),
                  // Custom date range button
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    tooltip: _selectedPeriod == DateRangePeriod.custom
                        ? '${DateFormat('MMM d').format(_dateRange.startDate)} - ${DateFormat('MMM d').format(_dateRange.endDate)}'
                        : 'Custom date range',
                    onPressed: _showCustomDatePicker,
                  ),
                  // Export button
                  if (_metrics != null)
                    IconButton(
                      icon: const Icon(Icons.file_download),
                      tooltip: 'Export CSV',
                      onPressed: () => _exportToCSV(context),
                    ),
                  // Refresh button
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadMetrics,
                    tooltip: 'Refresh data',
                  ),
                ],
              ),
            ),
            // Tab bar
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Overview', icon: Icon(Icons.dashboard, size: AppIconSize.sm)),
                Tab(text: 'Volume', icon: Icon(Icons.bar_chart, size: AppIconSize.sm)),
                Tab(text: 'Revenue', icon: Icon(Icons.attach_money, size: AppIconSize.sm)),
                Tab(text: 'Clients', icon: Icon(Icons.people, size: AppIconSize.sm)),
                Tab(text: 'Performance', icon: Icon(Icons.speed, size: AppIconSize.sm)),
                Tab(text: 'Group Sessions', icon: Icon(Icons.groups, size: AppIconSize.sm)),
              ],
            ),
            // Content
            Expanded(
              child: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? RefreshIndicator(
                  onRefresh: _loadMetrics,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ErrorFeedback(message: _error!),
                  ),
                )
              : _metrics == null
                  ? const Center(child: Text('No data available'))
                  : RefreshIndicator(
                      onRefresh: _loadMetrics,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _OverviewTab(metrics: _metrics!),
                          _VolumeTab(metrics: _metrics!),
                          _RevenueTab(metrics: _metrics!),
                          ClientsTab(metrics: _metrics!),
                          PerformanceTab(metrics: _metrics!),
                          GroupSessionsTab(metrics: _metrics!),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Semantics(
      label: 'Loading analytics data',
      child: SingleChildScrollView(
        padding: responsivePadding(context),
        child: Column(
          children: [
            const SkeletonCard(height: 150),
            VSpace.md,
            const SkeletonChart(height: 300),
            VSpace.md,
            buildSkeletonGrid(count: 4, cardHeight: 120),
          ],
        ),
      ),
    );
  }
}

// Overview Tab - Key metrics summary
class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.metrics});

  final AnalyticsMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Key Metrics', style: theme.textTheme.titleLarge),
          VSpace.md,
          MetricsGrid(
            metrics: [
              MetricCard(
                title: 'Total Appointments',
                value: metrics.totalAppointments.toString(),
                subtitle: '${metrics.completedAppointments} completed',
                icon: Icons.event,
                color: Colors.blue,
              ),
              MetricCard(
                title: 'Total Revenue',
                value: '\$${metrics.totalRevenueDollars.toStringAsFixed(2)}',
                subtitle: '\$${metrics.paidRevenueDollars.toStringAsFixed(2)} paid',
                icon: Icons.attach_money,
                color: Colors.green,
              ),
              MetricCard(
                title: 'Total Clients',
                value: metrics.totalClients.toString(),
                subtitle: '${metrics.newClients} new',
                icon: Icons.people,
                color: Colors.purple,
              ),
              MetricCard(
                title: 'No-Show Rate',
                value: '${(metrics.noShowRate * 100).toStringAsFixed(1)}%',
                subtitle: '${metrics.noShowAppointments} appointments',
                icon: Icons.cancel_outlined,
                color: Colors.orange,
              ),
            ],
          ),
          VSpace.xl,
          Text('Quick Insights', style: theme.textTheme.titleLarge),
          VSpace.md,
          _InsightCard(
            title: 'Top Service',
            value: metrics.topServiceByAppointments ?? 'N/A',
            icon: Icons.star,
          ),
          _InsightCard(
            title: 'Top Provider',
            value: metrics.topProviderByAppointments ?? 'N/A',
            icon: Icons.person,
          ),
          _InsightCard(
            title: 'Busiest Day',
            value: metrics.busiestDayOfWeek ?? 'N/A',
            icon: Icons.calendar_today,
          ),
          _InsightCard(
            title: 'Peak Hour',
            value: metrics.peakHourOfDay != null
                ? '${metrics.peakHourOfDay}:00'
                : 'N/A',
            icon: Icons.schedule,
          ),
        ],
      ),
    );
  }
}

// Volume Tab - Appointment volume charts
class _VolumeTab extends StatelessWidget {
  const _VolumeTab({required this.metrics});

  final AnalyticsMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppointmentVolumeChart(metrics: metrics),
          VSpace.xl,
          PeakTimesHeatmap(metrics: metrics),
        ],
      ),
    );
  }
}

// Revenue Tab - Revenue breakdown
class _RevenueTab extends StatelessWidget {
  const _RevenueTab({required this.metrics});

  final AnalyticsMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RevenueBreakdownChart(metrics: metrics),
          VSpace.xl,
          Text('Revenue by Service', style: theme.textTheme.titleMedium),
          VSpace.md,
          ...metrics.revenueByService.entries.map((entry) {
            final revenue = entry.value / 100.0;
            return ListTile(
              title: Text(entry.key),
              trailing: Text(
                '\$${revenue.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium,
              ),
            );
          }),
        ],
      ),
    );
  }
}


// Insight Card Widget
class _InsightCard extends StatelessWidget {
  const _InsightCard({
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

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          leading: Icon(icon, color: theme.colorScheme.primary),
          title: Text(title),
          trailing: Text(
            value,
            style: theme.textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}


