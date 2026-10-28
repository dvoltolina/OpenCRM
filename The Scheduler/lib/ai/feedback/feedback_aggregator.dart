import 'dart:math' as math;

import '../../data/models/prediction_feedback.dart';
import '../../data/models/security_context.dart';
import '../../data/repositories/prediction_feedback_repository.dart';

/// Aggregates and analyzes prediction feedback for model improvement.
///
/// Provides statistical analysis, trend detection, and comparison
/// across model versions and experiment variants.
///
/// Agent AI-18: A/B Testing & Feedback Loop Framework
class FeedbackAggregator {
  FeedbackAggregator({
    required PredictionFeedbackRepository repository,
  }) : _repository = repository;

  final PredictionFeedbackRepository _repository;

  // ===== AGGREGATE METRICS =====

  /// Calculate aggregate metrics for a model version.
  Future<AggregateMetrics> calculateMetrics(
    SecurityContext context, {
    required String modelVersion,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final periodStart = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final periodEnd = endDate ?? DateTime.now();

    final summary = await _repository.getFeedbackSummary(
      context,
      modelVersion: modelVersion,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );

    return AggregateMetrics(
      modelVersion: modelVersion,
      periodStart: periodStart,
      periodEnd: periodEnd,
      totalFeedback: summary.totalFeedback,
      positiveCount: summary.positiveCount,
      negativeCount: summary.negativeCount,
      skippedCount: summary.skippedCount,
      positiveRate: summary.positiveRate,
      negativeRate: summary.negativeRate,
      responseRate: summary.responseRate,
      netScore: summary.netScore,
      averageWeightedScore: summary.averageWeightedScore,
    );
  }

  /// Compare metrics between two model versions.
  Future<ModelComparison> compareModels(
    SecurityContext context, {
    required String modelVersionA,
    required String modelVersionB,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final metricsA = await calculateMetrics(
      context,
      modelVersion: modelVersionA,
      startDate: startDate,
      endDate: endDate,
    );

    final metricsB = await calculateMetrics(
      context,
      modelVersion: modelVersionB,
      startDate: startDate,
      endDate: endDate,
    );

    return ModelComparison(
      modelVersionA: modelVersionA,
      modelVersionB: modelVersionB,
      metricsA: metricsA,
      metricsB: metricsB,
      positiveRateDiff: metricsB.positiveRate - metricsA.positiveRate,
      netScoreDiff: metricsB.netScore - metricsA.netScore,
      isStatisticallySignificant: _calculateSignificance(metricsA, metricsB),
    );
  }

  /// Compare experiment variants.
  Future<VariantComparison> compareVariants(
    SecurityContext context, {
    required String experimentId,
    required String modelVersion,
  }) async {
    final summaries = <String, FeedbackSummary>{};

    // This would need variant IDs from the experiment
    // For now, we compare control vs treatment
    final controlSummary = await _repository.getFeedbackSummary(
      context,
      modelVersion: modelVersion,
      periodStart: DateTime.now().subtract(const Duration(days: 30)),
      periodEnd: DateTime.now(),
      experimentId: experimentId,
      variantId: 'control',
    );

    final treatmentSummary = await _repository.getFeedbackSummary(
      context,
      modelVersion: modelVersion,
      periodStart: DateTime.now().subtract(const Duration(days: 30)),
      periodEnd: DateTime.now(),
      experimentId: experimentId,
      variantId: 'treatment_a',
    );

    summaries['control'] = controlSummary;
    summaries['treatment_a'] = treatmentSummary;

    // Calculate lift
    double lift = 0;
    if (controlSummary.positiveRate > 0) {
      lift = (treatmentSummary.positiveRate - controlSummary.positiveRate) /
          controlSummary.positiveRate *
          100;
    }

    return VariantComparison(
      experimentId: experimentId,
      variantSummaries: summaries,
      controlVariantId: 'control',
      bestVariantId: treatmentSummary.positiveRate > controlSummary.positiveRate
          ? 'treatment_a'
          : 'control',
      treatmentLift: lift,
      isSignificant: _calculateVariantSignificance(controlSummary, treatmentSummary),
    );
  }

  // ===== TREND ANALYSIS =====

  /// Detect trends in feedback over time.
  Future<TrendAnalysis> analyzeTrends(
    SecurityContext context, {
    required String modelVersion,
    int days = 30,
  }) async {
    final trends = await _repository.getDailyFeedbackTrends(
      context,
      modelVersion: modelVersion,
      startDate: DateTime.now().subtract(Duration(days: days)),
      endDate: DateTime.now(),
    );

    if (trends.isEmpty) {
      return TrendAnalysis.noData(modelVersion);
    }

    // Calculate moving averages
    final positiveRates = trends.map((s) => s.positiveRate).toList();
    final netScores = trends.map((s) => s.netScore).toList();

    final ma7Positive = _movingAverage(positiveRates, 7);
    final ma7NetScore = _movingAverage(netScores, 7);

    // Detect trend direction
    final trendDirection = _detectTrendDirection(ma7Positive);
    final scoreTrend = _detectTrendDirection(ma7NetScore);

    // Calculate volatility
    final volatility = _calculateVolatility(positiveRates);

    // Find anomalies
    final anomalies = _detectAnomalies(positiveRates, trends);

    return TrendAnalysis(
      modelVersion: modelVersion,
      periodDays: days,
      dailySummaries: trends,
      positiveRateTrend: trendDirection,
      netScoreTrend: scoreTrend,
      averagePositiveRate: _mean(positiveRates),
      averageNetScore: _mean(netScores),
      volatility: volatility,
      anomalyDates: anomalies,
      isImproving: trendDirection == TrendDirection.increasing,
      isDeclining: trendDirection == TrendDirection.decreasing,
    );
  }

  /// Get weekly summary of feedback.
  Future<List<WeeklySummary>> getWeeklySummaries(
    SecurityContext context, {
    required String modelVersion,
    int weeks = 4,
  }) async {
    final summaries = <WeeklySummary>[];
    final now = DateTime.now();

    for (var i = 0; i < weeks; i++) {
      final weekEnd = now.subtract(Duration(days: i * 7));
      final weekStart = weekEnd.subtract(const Duration(days: 7));

      final summary = await _repository.getFeedbackSummary(
        context,
        modelVersion: modelVersion,
        periodStart: weekStart,
        periodEnd: weekEnd,
      );

      summaries.add(WeeklySummary(
        weekNumber: weeks - i,
        startDate: weekStart,
        endDate: weekEnd,
        summary: summary,
      ));
    }

    return summaries.reversed.toList();
  }

  // ===== SEGMENTATION =====

  /// Segment feedback by risk level.
  Future<Map<String, FeedbackSummary>> segmentByRiskLevel(
    SecurityContext context, {
    required String modelVersion,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final periodStart = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final periodEnd = endDate ?? DateTime.now();

    final allFeedback = await _repository.getFeedbackForModelVersion(
      context,
      modelVersion: modelVersion,
      startDate: periodStart,
      endDate: periodEnd,
    );

    // Group by risk level
    final grouped = <String, List<PredictionFeedback>>{};
    for (final feedback in allFeedback) {
      final level = feedback.predictedRiskLevel;
      grouped.putIfAbsent(level, () => []);
      grouped[level]!.add(feedback);
    }

    // Create summaries for each segment
    final summaries = <String, FeedbackSummary>{};
    for (final entry in grouped.entries) {
      summaries[entry.key] = _createSummaryFromList(
        entry.value,
        modelVersion: modelVersion,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );
    }

    return summaries;
  }

  /// Segment feedback by probability bucket.
  Future<Map<String, FeedbackSummary>> segmentByProbabilityBucket(
    SecurityContext context, {
    required String modelVersion,
    DateTime? startDate,
    DateTime? endDate,
    int buckets = 5,
  }) async {
    final periodStart = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final periodEnd = endDate ?? DateTime.now();

    final allFeedback = await _repository.getFeedbackForModelVersion(
      context,
      modelVersion: modelVersion,
      startDate: periodStart,
      endDate: periodEnd,
    );

    // Create buckets (0-20%, 20-40%, etc.)
    final bucketSize = 100 / buckets;
    final grouped = <String, List<PredictionFeedback>>{};

    for (final feedback in allFeedback) {
      final probability = feedback.predictedProbability * 100;
      final bucketIndex = (probability / bucketSize).floor().clamp(0, buckets - 1);
      final bucketLabel = '${(bucketIndex * bucketSize).toInt()}-${((bucketIndex + 1) * bucketSize).toInt()}%';

      grouped.putIfAbsent(bucketLabel, () => []);
      grouped[bucketLabel]!.add(feedback);
    }

    // Create summaries
    final summaries = <String, FeedbackSummary>{};
    for (final entry in grouped.entries) {
      summaries[entry.key] = _createSummaryFromList(
        entry.value,
        modelVersion: modelVersion,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );
    }

    return summaries;
  }

  // ===== CALIBRATION ANALYSIS =====

  /// Analyze prediction calibration based on feedback.
  Future<CalibrationAnalysis> analyzeCalibration(
    SecurityContext context, {
    required String modelVersion,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final periodStart = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final periodEnd = endDate ?? DateTime.now();

    final allFeedback = await _repository.getFeedbackForModelVersion(
      context,
      modelVersion: modelVersion,
      startDate: periodStart,
      endDate: periodEnd,
    );

    // Count probability issues
    int tooHighCount = 0;
    int tooLowCount = 0;
    int correctCount = 0;

    for (final feedback in allFeedback) {
      if (feedback.feedbackType == FeedbackType.negative) {
        if (feedback.negativeReason == NegativeFeedbackReason.probabilityTooHigh) {
          tooHighCount++;
        } else if (feedback.negativeReason == NegativeFeedbackReason.probabilityTooLow) {
          tooLowCount++;
        }
      } else if (feedback.feedbackType == FeedbackType.positive) {
        correctCount++;
      }
    }

    final total = tooHighCount + tooLowCount + correctCount;
    final calibrationBias = total > 0
        ? (tooHighCount - tooLowCount) / total
        : 0.0;

    CalibrationIssue? primaryIssue;
    if (calibrationBias > 0.1) {
      primaryIssue = CalibrationIssue.overconfident;
    } else if (calibrationBias < -0.1) {
      primaryIssue = CalibrationIssue.underconfident;
    }

    return CalibrationAnalysis(
      modelVersion: modelVersion,
      periodStart: periodStart,
      periodEnd: periodEnd,
      totalFeedback: total,
      tooHighCount: tooHighCount,
      tooLowCount: tooLowCount,
      correctCount: correctCount,
      calibrationBias: calibrationBias,
      primaryIssue: primaryIssue,
      isWellCalibrated: primaryIssue == null,
    );
  }

  // ===== HELPER METHODS =====

  FeedbackSummary _createSummaryFromList(
    List<PredictionFeedback> feedbackList, {
    required String modelVersion,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    int positiveCount = 0;
    int negativeCount = 0;
    int skippedCount = 0;
    double weightedScoreSum = 0;
    double totalWeight = 0;
    final reasonCounts = <String, int>{};

    for (final feedback in feedbackList) {
      switch (feedback.feedbackType) {
        case FeedbackType.positive:
          positiveCount++;
          weightedScoreSum += feedback.weight;
          totalWeight += feedback.weight;
          break;
        case FeedbackType.negative:
          negativeCount++;
          weightedScoreSum -= feedback.weight;
          totalWeight += feedback.weight;
          if (feedback.negativeReason != null) {
            final reason = feedback.negativeReason!.name;
            reasonCounts[reason] = (reasonCounts[reason] ?? 0) + 1;
          }
          break;
        case FeedbackType.skipped:
          skippedCount++;
          break;
      }
    }

    final sorted = reasonCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topReasons = sorted.take(5).map((e) => e.key).toList();

    return FeedbackSummary(
      modelVersion: modelVersion,
      periodStart: periodStart,
      periodEnd: periodEnd,
      totalFeedback: feedbackList.length,
      positiveCount: positiveCount,
      negativeCount: negativeCount,
      skippedCount: skippedCount,
      weightedScoreSum: weightedScoreSum,
      totalWeight: totalWeight,
      negativeReasonCounts: reasonCounts,
      topNegativeReasons: topReasons,
    );
  }

  bool _calculateSignificance(AggregateMetrics a, AggregateMetrics b) {
    // Simple significance check: need at least 30 samples each
    // and a meaningful difference
    if (a.totalFeedback < 30 || b.totalFeedback < 30) {
      return false;
    }

    final diff = (b.positiveRate - a.positiveRate).abs();
    return diff > 0.05; // 5% difference threshold
  }

  bool _calculateVariantSignificance(FeedbackSummary control, FeedbackSummary treatment) {
    if (control.actionableFeedback < 30 || treatment.actionableFeedback < 30) {
      return false;
    }

    final diff = (treatment.positiveRate - control.positiveRate).abs();
    return diff > 0.05;
  }

  List<double> _movingAverage(List<double> values, int window) {
    if (values.length < window) return values;

    final result = <double>[];
    for (var i = window - 1; i < values.length; i++) {
      var sum = 0.0;
      for (var j = 0; j < window; j++) {
        sum += values[i - j];
      }
      result.add(sum / window);
    }
    return result;
  }

  TrendDirection _detectTrendDirection(List<double> values) {
    if (values.length < 3) return TrendDirection.stable;

    // Simple linear regression slope
    final n = values.length;
    var sumX = 0.0;
    var sumY = 0.0;
    var sumXY = 0.0;
    var sumX2 = 0.0;

    for (var i = 0; i < n; i++) {
      sumX += i;
      sumY += values[i];
      sumXY += i * values[i];
      sumX2 += i * i;
    }

    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);

    if (slope > 0.01) return TrendDirection.increasing;
    if (slope < -0.01) return TrendDirection.decreasing;
    return TrendDirection.stable;
  }

  double _calculateVolatility(List<double> values) {
    if (values.length < 2) return 0;

    final mean = _mean(values);
    var sumSquaredDiff = 0.0;

    for (final value in values) {
      sumSquaredDiff += (value - mean) * (value - mean);
    }

    return math.sqrt(sumSquaredDiff / values.length);
  }

  double _mean(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  List<DateTime> _detectAnomalies(
    List<double> values,
    List<FeedbackSummary> summaries,
  ) {
    if (values.length < 7) return [];

    final mean = _mean(values);
    final stdDev = _calculateVolatility(values);
    final anomalies = <DateTime>[];

    for (var i = 0; i < values.length; i++) {
      final zScore = stdDev > 0 ? (values[i] - mean).abs() / stdDev : 0;
      if (zScore > 2) {
        // More than 2 standard deviations
        anomalies.add(summaries[i].periodStart);
      }
    }

    return anomalies;
  }
}

/// Aggregate metrics for a model version.
class AggregateMetrics {
  const AggregateMetrics({
    required this.modelVersion,
    required this.periodStart,
    required this.periodEnd,
    required this.totalFeedback,
    required this.positiveCount,
    required this.negativeCount,
    required this.skippedCount,
    required this.positiveRate,
    required this.negativeRate,
    required this.responseRate,
    required this.netScore,
    required this.averageWeightedScore,
  });

  final String modelVersion;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalFeedback;
  final int positiveCount;
  final int negativeCount;
  final int skippedCount;
  final double positiveRate;
  final double negativeRate;
  final double responseRate;
  final double netScore;
  final double averageWeightedScore;

  int get actionableFeedback => positiveCount + negativeCount;
}

/// Comparison between two model versions.
class ModelComparison {
  const ModelComparison({
    required this.modelVersionA,
    required this.modelVersionB,
    required this.metricsA,
    required this.metricsB,
    required this.positiveRateDiff,
    required this.netScoreDiff,
    required this.isStatisticallySignificant,
  });

  final String modelVersionA;
  final String modelVersionB;
  final AggregateMetrics metricsA;
  final AggregateMetrics metricsB;
  final double positiveRateDiff;
  final double netScoreDiff;
  final bool isStatisticallySignificant;

  bool get isBBetter => positiveRateDiff > 0;
  double get improvementPercent =>
      metricsA.positiveRate > 0
          ? positiveRateDiff / metricsA.positiveRate * 100
          : 0;
}

/// Comparison between experiment variants.
class VariantComparison {
  const VariantComparison({
    required this.experimentId,
    required this.variantSummaries,
    required this.controlVariantId,
    required this.bestVariantId,
    required this.treatmentLift,
    required this.isSignificant,
  });

  final String experimentId;
  final Map<String, FeedbackSummary> variantSummaries;
  final String controlVariantId;
  final String bestVariantId;
  final double treatmentLift;
  final bool isSignificant;

  bool get treatmentWins => bestVariantId != controlVariantId && isSignificant;
}

/// Trend analysis results.
class TrendAnalysis {
  const TrendAnalysis({
    required this.modelVersion,
    required this.periodDays,
    required this.dailySummaries,
    required this.positiveRateTrend,
    required this.netScoreTrend,
    required this.averagePositiveRate,
    required this.averageNetScore,
    required this.volatility,
    required this.anomalyDates,
    required this.isImproving,
    required this.isDeclining,
  });

  factory TrendAnalysis.noData(String modelVersion) {
    return TrendAnalysis(
      modelVersion: modelVersion,
      periodDays: 0,
      dailySummaries: [],
      positiveRateTrend: TrendDirection.stable,
      netScoreTrend: TrendDirection.stable,
      averagePositiveRate: 0,
      averageNetScore: 0,
      volatility: 0,
      anomalyDates: [],
      isImproving: false,
      isDeclining: false,
    );
  }

  final String modelVersion;
  final int periodDays;
  final List<FeedbackSummary> dailySummaries;
  final TrendDirection positiveRateTrend;
  final TrendDirection netScoreTrend;
  final double averagePositiveRate;
  final double averageNetScore;
  final double volatility;
  final List<DateTime> anomalyDates;
  final bool isImproving;
  final bool isDeclining;

  bool get isStable =>
      positiveRateTrend == TrendDirection.stable &&
      netScoreTrend == TrendDirection.stable;
  bool get hasAnomalies => anomalyDates.isNotEmpty;
}

/// Direction of a trend.
enum TrendDirection {
  increasing,
  decreasing,
  stable,
}

/// Weekly summary of feedback.
class WeeklySummary {
  const WeeklySummary({
    required this.weekNumber,
    required this.startDate,
    required this.endDate,
    required this.summary,
  });

  final int weekNumber;
  final DateTime startDate;
  final DateTime endDate;
  final FeedbackSummary summary;
}

/// Analysis of prediction calibration.
class CalibrationAnalysis {
  const CalibrationAnalysis({
    required this.modelVersion,
    required this.periodStart,
    required this.periodEnd,
    required this.totalFeedback,
    required this.tooHighCount,
    required this.tooLowCount,
    required this.correctCount,
    required this.calibrationBias,
    required this.isWellCalibrated,
    this.primaryIssue,
  });

  final String modelVersion;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalFeedback;
  final int tooHighCount;
  final int tooLowCount;
  final int correctCount;
  final double calibrationBias;
  final CalibrationIssue? primaryIssue;
  final bool isWellCalibrated;
}

/// Type of calibration issue.
enum CalibrationIssue {
  overconfident,
  underconfident,
}
