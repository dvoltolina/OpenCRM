import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/onboarding_controller.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/ui_exports.dart';
import '../../../core/utils/secure_error_handler.dart';
import '../../../data/models/analytics_metrics.dart';
import '../../../data/models/onboarding_state.dart';
import '../../../data/models/security_context.dart';
import '../../home/presentation/onboarding_flow.dart';
import 'widgets/dashboard_feature_status.dart';
import 'widgets/dashboard_hero_header.dart';
import 'widgets/dashboard_metric_card.dart';
import 'widgets/dashboard_onboarding_callout.dart';
import 'widgets/dashboard_service_highlights.dart';

/// Dashboard page showing business metrics and KPIs.
/// Updated by Agent U2 (2025-11-29) - HIPAA-compliant error handling
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  AnalyticsMetrics? _todayMetrics;
  AnalyticsMetrics? _weekMetrics;
  AnalyticsMetrics? _monthMetrics;
  bool _isLoading = true;
  SecurityContext? _currentContext;


  Future<void> _loadMetrics(SecurityContext context) async {
    setState(() => _isLoading = true);

    try {
      final analyticsService = ref.read(analyticsServiceProvider);

      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final startOfWeek = now.subtract(Duration(days: 7));
      final startOfMonth = now.subtract(Duration(days: 30));

      final today = await analyticsService.computeMetrics(
        context: context,
        startDate: startOfToday,
        endDate: endOfToday,
      );

      final week = await analyticsService.computeMetrics(
        context: context,
        startDate: startOfWeek,
        endDate: now,
      );

      final month = await analyticsService.computeMetrics(
        context: context,
        startDate: startOfMonth,
        endDate: now,
      );

      setState(() {
        _todayMetrics = today;
        _weekMetrics = week;
        _monthMetrics = month;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for security context changes to load metrics
    ref.listen<AsyncValue<SecurityContext?>>(
      securityContextProvider,
      (previous, next) {
        final ctx = next.valueOrNull;
        if (ctx != null && ctx != _currentContext) {
          _currentContext = ctx;
          _loadMetrics(ctx);
        }
        if (ctx == null && _currentContext != null) {
          setState(() {
            _currentContext = null;
            _isLoading = false;
            _todayMetrics = null;
            _weekMetrics = null;
            _monthMetrics = null;
          });
        }
      },
    );

    final config = ref.watch(appConfigProvider);
    final onboardingController = OnboardingController.instance;
    final securityContextAsync = ref.watch(securityContextProvider);

    return securityContextAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(SecureErrorHandler.loadingFailed)),
      data: (securityContext) {
        if (securityContext == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Use actual business ID from authenticated security context
        final businessId = securityContext.businessId;

        // Initialize onboarding controller to fetch state from Firestore
        onboardingController.init(businessId);

        return Semantics(
          label: 'Dashboard page',
          child: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = _gridColumnsForWidth(constraints.maxWidth);
                final featureChips = <String, bool>{
                  'Client Portal': config.featureFlags.enableClientPortal,
                  'Automations': config.featureFlags.enableAutomatedReminders,
                  'Payments': config.featureFlags.enablePayments,
                  'Multi-location': config.featureFlags.enableMultiLocation,
                  'Reporting': config.featureFlags.enableReporting,
                };

                final metrics = _buildMetricCards(config);

                return RefreshIndicator(
                  onRefresh: () async {
                    final ctx = _currentContext ?? securityContext;
                    await _loadMetrics(ctx);
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: AppSpacing.pagePadding,
                          child: DashboardHeroHeader(config: config).fadeIn(),
                        ),
                      ),
                      ValueListenableBuilder<OnboardingState?>(
                        valueListenable: onboardingController.state,
                        builder: (context, onboardingState, _) {
                          // Hide onboarding callout once completed
                          if (onboardingState?.isComplete ?? false) {
                            return const SliverToBoxAdapter(
                              child: SizedBox.shrink(),
                            );
                          }

                          return SliverToBoxAdapter(
                            child: Padding(
                              padding: AppSpacing.pagePadding.copyWith(top: AppSpacing.md),
                              child: DashboardOnboardingCallout(
                                config: config,
                                onStart: () => showOnboardingFlow(
                                  context: context,
                                  ref: ref,
                                  config: config,
                                  businessId: businessId,
                                  controller: onboardingController,
                                  securityContext: securityContext,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: AppSpacing.pagePadding.copyWith(top: AppSpacing.lg),
                          child: SectionHeader(
                            title: 'Today\'s Overview',
                            subtitle: 'Key metrics at a glance',
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (_isLoading)
                        SliverPadding(
                          padding: AppSpacing.pagePadding,
                          sliver: SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisExtent: 180,
                              crossAxisSpacing: AppSpacing.md,
                              mainAxisSpacing: AppSpacing.md,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => const SkeletonCard(height: 180),
                              childCount: 4,
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: AppSpacing.pagePadding,
                          sliver: SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisExtent: 180,
                              crossAxisSpacing: AppSpacing.md,
                              mainAxisSpacing: AppSpacing.md,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) =>
                                  AnimatedListItem(index: index, child: DashboardMetricCard(data: metrics[index])),
                              childCount: metrics.length,
                            ),
                          ),
                        ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: AppSpacing.pagePadding.copyWith(top: AppSpacing.lg),
                          child: DashboardFeatureStatus(status: featureChips),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: AppSpacing.pagePadding.copyWith(
                            top: AppSpacing.lg,
                            bottom: AppSpacing.lg,
                          ),
                          child: DashboardServiceHighlights(
                            services: config.serviceCatalog,
                            timeZone: config.defaultTimeZone,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  int _gridColumnsForWidth(double width) {
    if (width >= 1280) return 4;
    if (width >= 960) return 3;
    if (width >= 640) return 2;
    return 1;
  }

  List<MetricCardData> _buildMetricCards(AppConfig config) {
    if (_isLoading || _todayMetrics == null) {
      return [];
    }

    final today = _todayMetrics!;
    final week = _weekMetrics!;
    final month = _monthMetrics!;

    // Calculate trends (compare week vs month averages)
    final weekNoShowRate = week.noShowRate;
    final monthNoShowRate = month.noShowRate;
    final noShowTrend = monthNoShowRate > 0
        ? ((weekNoShowRate - monthNoShowRate) / monthNoShowRate) * 100
        : 0.0;

    final cards = <MetricCardData>[
      MetricCardData(
        title: "Today's Appointments",
        value: today.totalAppointments.toString(),
        subtitle:
            '${today.completedAppointments} done • ${today.pendingAppointments} pending',
        icon: Icons.event,
        color: AppColors.info,
        trend: null,
      ),
      MetricCardData(
        title: 'Week Revenue',
        value: '\$${week.totalRevenueDollars.toStringAsFixed(0)}',
        subtitle: 'Month: \$${month.totalRevenueDollars.toStringAsFixed(0)}',
        icon: Icons.attach_money,
        color: AppColors.success,
        trend: null,
      ),
      MetricCardData(
        title: 'No-Show Rate',
        value: '${(week.noShowRate * 100).toStringAsFixed(1)}%',
        subtitle: '${week.noShowAppointments} no-shows this week',
        icon: Icons.cancel_outlined,
        color: noShowTrend > 0 ? AppColors.error : AppColors.success,
        trend: noShowTrend,
      ),
      MetricCardData(
        title: 'Default slot',
        value: '${config.bookingPolicies.defaultSlotLength.inMinutes}m',
        subtitle:
            'Buffer ${config.bookingPolicies.bufferBetweenAppointments.inMinutes}m',
        icon: Icons.schedule,
        color: AppColors.accentPurple,
        trend: null,
      ),
    ];

    // Group Session Metrics
    if (week.totalGroupSessions > 0) {
      cards.add(
        MetricCardData(
          title: 'Group Sessions',
          value: week.totalGroupSessions.toString(),
          subtitle:
              '${week.totalGroupSessionAttendees} attendees • ${(week.groupSessionUtilizationRate * 100).toStringAsFixed(0)}% fill',
          icon: Icons.groups,
          color: AppColors.accentTeal,
          trend: null,
        ),
      );
    }

    return cards;
  }
}
