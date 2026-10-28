/// Predictions tab showing no-show risk and client scores.
///
/// Agent AI-12: AI Dashboard & UI Components
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../data/models/security_context.dart';
import '../../models/noshow_prediction.dart';
import '../../providers/prediction_providers.dart';
import 'prediction_widgets.dart';

/// Tab showing prediction overview and high-risk appointments.
class PredictionsTab extends ConsumerStatefulWidget {
  const PredictionsTab({
    super.key,
    required this.securityContext,
  });

  final SecurityContext securityContext;

  @override
  ConsumerState<PredictionsTab> createState() => _PredictionsTabState();
}

class _PredictionsTabState extends ConsumerState<PredictionsTab> {
  bool _showHighRiskOnly = false;

  @override
  Widget build(BuildContext context) {
    final predictionsAvailable = ref.watch(predictionsAvailableProvider);

    return predictionsAvailable.when(
      data: (available) {
        if (!available) {
          return _buildUnavailableState(context);
        }
        return _buildContent(context);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildUnavailableState(context),
    );
  }

  Widget _buildUnavailableState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'AI Predictions Unavailable',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'The prediction service is temporarily unavailable.\nPlease try again later.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () => ref.invalidate(predictionsAvailableProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(predictionsAvailableProvider);
      },
      child: CustomScrollView(
        slivers: [
          // Summary stats
          SliverToBoxAdapter(
            child: _PredictionsSummary(
              securityContext: widget.securityContext,
            ),
          ),

          // Filter chip
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Text(
                    'Upcoming Appointments',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  FilterChip(
                    label: const Text('High Risk Only'),
                    selected: _showHighRiskOnly,
                    onSelected: (selected) {
                      setState(() => _showHighRiskOnly = selected);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Predictions list
          _PredictionsList(
            securityContext: widget.securityContext,
            highRiskOnly: _showHighRiskOnly,
          ),

          // Bottom padding
          const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.xxl)),
        ],
      ),
    );
  }
}

/// Summary statistics for predictions.
class _PredictionsSummary extends ConsumerWidget {
  const _PredictionsSummary({
    required this.securityContext,
  });

  final SecurityContext securityContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(predictionStatsProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Prediction Overview',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      icon: Icons.event_outlined,
                      label: 'Total Predictions',
                      value: statsAsync['totalPredictions']?.toString() ?? '—',
                    ),
                  ),
                  Expanded(
                    child: _StatItem(
                      icon: Icons.warning_amber_outlined,
                      label: 'High Risk',
                      value: statsAsync['highRisk']?.toString() ?? '—',
                      valueColor: AppColors.error,
                    ),
                  ),
                  Expanded(
                    child: _StatItem(
                      icon: Icons.speed_outlined,
                      label: 'Avg Confidence',
                      value: _formatPercent(statsAsync['avgConfidence']),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPercent(dynamic value) {
    if (value == null) return '—';
    if (value is double) return '${(value * 100).round()}%';
    return value.toString();
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 20,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// List of predictions for upcoming appointments.
class _PredictionsList extends ConsumerWidget {
  const _PredictionsList({
    required this.securityContext,
    required this.highRiskOnly,
  });

  final SecurityContext securityContext;
  final bool highRiskOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get upcoming appointments
    final appointmentsRepo = ref.watch(appointmentsRepositoryProvider);
    final now = DateTime.now();
    final weekFromNow = now.add(const Duration(days: 7));

    return FutureBuilder(
      future: _getUpcomingAppointments(appointmentsRepo),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: Center(
              child: Text('Error loading appointments: ${snapshot.error}'),
            ),
          );
        }

        final appointments = snapshot.data ?? [];
        if (appointments.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_available_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No upcoming appointments',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          );
        }

        // Get predictions for appointments
        final predictionsAsync = ref.watch(
          batchPredictionsProvider((
            context: securityContext,
            appointments: appointments,
          )),
        );

        return predictionsAsync.when(
          data: (predictions) {
            // Filter if high risk only
            var items = appointments.map((apt) {
              final prediction = predictions[apt.id];
              return (appointment: apt, prediction: prediction);
            }).toList();

            if (highRiskOnly) {
              items = items
                  .where((item) =>
                      item.prediction?.riskLevel == RiskLevel.high ||
                      item.prediction?.riskLevel == RiskLevel.medium)
                  .toList();
            }

            // Sort by risk level (high first)
            items.sort((a, b) {
              final aRisk = a.prediction?.probability ?? 0;
              final bRisk = b.prediction?.probability ?? 0;
              return bRisk.compareTo(aRisk);
            });

            if (items.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No high-risk appointments',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = items[index];
                    final prediction =
                        item.prediction ?? NoshowPrediction.unavailable(item.appointment.id);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: PredictionCard(
                        prediction: prediction,
                        clientName: item.appointment.clientName,
                        serviceName: item.appointment.serviceName,
                        appointmentTime: item.appointment.startTime,
                        compact: true,
                        onTap: () => _showPredictionDetails(context, prediction),
                      ),
                    );
                  },
                  childCount: items.length,
                ),
              ),
            );
          },
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SliverFillRemaining(
            child: Center(child: Text('Error: $e')),
          ),
        );
      },
    );
  }

  Future<List<dynamic>> _getUpcomingAppointments(dynamic repo) async {
    // This would fetch from the appointments repository
    // For now, return empty list as we're demonstrating the structure
    return [];
  }

  void _showPredictionDetails(BuildContext context, NoshowPrediction prediction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: PredictionCard(
              prediction: prediction,
              compact: false,
              showActions: true,
            ),
          );
        },
      ),
    );
  }
}
