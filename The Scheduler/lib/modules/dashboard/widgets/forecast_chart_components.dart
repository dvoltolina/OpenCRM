import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ai/models/demand_forecast.dart';
import '../../../core/providers/providers.dart';
import '../../../core/ui/components/components.dart';

/// Simple bar chart for forecasts.
/// Updated with Modern Sophisticated Blue design system - gradient bars.
class SimpleForecastChart extends ConsumerWidget {
  const SimpleForecastChart({
    super.key,
    required this.forecasts,
    this.onDaySelected,
  });

  final List<DemandForecast> forecasts;
  final void Function(DemandForecast)? onDaySelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (forecasts.isEmpty) {
      return const Center(child: Text('No forecast data'));
    }

    final maxValue = forecasts
        .map((f) => f.upperBound)
        .reduce((a, b) => a > b ? a : b);

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = (constraints.maxWidth - 20) / forecasts.length - 2;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: forecasts.map((forecast) {
            return ForecastBar(
              forecast: forecast,
              maxValue: maxValue,
              width: barWidth.clamp(8.0, 40.0),
              height: constraints.maxHeight - 20,
              onTap: onDaySelected != null
                  ? () => onDaySelected!(forecast)
                  : null,
            );
          }).toList(),
        );
      },
    );
  }
}

/// Individual forecast bar.
/// Updated with Modern Sophisticated Blue design system - subtle gradient on bars.
class ForecastBar extends ConsumerWidget {
  const ForecastBar({
    super.key,
    required this.forecast,
    required this.maxValue,
    required this.width,
    required this.height,
    this.onTap,
  });

  final DemandForecast forecast;
  final double maxValue;
  final double width;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final config = ref.watch(appConfigProvider);
    final branding = config.branding;

    final predictedHeight =
        maxValue > 0 ? (forecast.predictedCount / maxValue) * height : 0.0;
    final lowerHeight =
        maxValue > 0 ? (forecast.lowerBound / maxValue) * height : 0.0;
    final upperHeight =
        maxValue > 0 ? (forecast.upperBound / maxValue) * height : 0.0;

    final colors = _getDemandColors(forecast.demandLevel, branding);

    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message:
            '${forecast.date.day}/${forecast.date.month}: ${forecast.predictedCount.round()} '
            '(${forecast.lowerBound.round()}-${forecast.upperBound.round()})',
        child: SizedBox(
          width: width,
          height: height + 20,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Confidence interval
              Container(
                width: 2,
                height: upperHeight - lowerHeight,
                margin: EdgeInsets.only(bottom: lowerHeight),
                color: colors.$1.withValues(alpha: 0.3),
              ),
              // Main bar with gradient
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: width - 2,
                height: predictedHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [colors.$1, colors.$2],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.$1.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              // Day label
              const SizedBox(height: 4),
              Text(
                forecast.dayName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, Color) _getDemandColors(DemandLevel level, branding) {
    switch (level) {
      case DemandLevel.veryLow:
        return (Colors.grey.shade400, Colors.grey.shade300);
      case DemandLevel.low:
        return (branding.accentColor.withValues(alpha: 0.7), branding.accentColor.withValues(alpha: 0.5));
      case DemandLevel.normal:
        return (Colors.green.shade500, Colors.green.shade400);
      case DemandLevel.high:
        return (Colors.orange.shade500, Colors.orange.shade400);
      case DemandLevel.veryHigh:
        return (Colors.red.shade500, Colors.red.shade400);
    }
  }
}

/// Chart legend.
class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      children: [
        LegendItem(
          color: Colors.grey.shade400,
          label: 'Very Low',
        ),
        LegendItem(
          color: Colors.blue.shade300,
          label: 'Low',
        ),
        LegendItem(
          color: Colors.green.shade400,
          label: 'Normal',
        ),
        LegendItem(
          color: Colors.orange.shade400,
          label: 'High',
        ),
        LegendItem(
          color: Colors.red.shade400,
          label: 'Very High',
        ),
      ],
    );
  }
}

/// Legend item.
class LegendItem extends StatelessWidget {
  const LegendItem({
    super.key,
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }
}

/// Stat chip widget.
/// Updated with Modern Sophisticated Blue design system - subtle gradient background.
class StatChip extends ConsumerWidget {
  const StatChip({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final MaterialColor color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.shade50,
            color.shade100.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: color.shade200.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          HSpace.xxs,
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Capacity chip.
/// Updated with Modern Sophisticated Blue design system - subtle gradient background.
class CapacityChip extends ConsumerWidget {
  const CapacityChip({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final MaterialColor color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.shade50,
            color.shade100.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: color.shade300.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          HSpace.xxs,
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
