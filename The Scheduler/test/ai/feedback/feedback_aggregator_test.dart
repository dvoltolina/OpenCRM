@Tags(['ai'])
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/ai/feedback/feedback_aggregator.dart';
import 'package:the_scheduler/data/models/prediction_feedback.dart';

void main() {
  final testStart = DateTime(2024, 1, 1);
  final testEnd = DateTime(2024, 1, 31);

  group('AggregateMetrics', () {
    test('calculates actionable feedback correctly', () {
      final metrics = AggregateMetrics(
        modelVersion: 'v1.0',
        periodStart: testStart,
        periodEnd: testEnd,
        totalFeedback: 100,
        positiveCount: 60,
        negativeCount: 30,
        skippedCount: 10,
        positiveRate: 0.67,
        negativeRate: 0.33,
        responseRate: 0.9,
        netScore: 33.3,
        averageWeightedScore: 0.33,
      );

      expect(metrics.actionableFeedback, equals(90));
    });
  });

  group('ModelComparison', () {
    test('identifies better model correctly', () {
      final metricsA = AggregateMetrics(
        modelVersion: 'v1.0',
        periodStart: testStart,
        periodEnd: testEnd,
        totalFeedback: 100,
        positiveCount: 60,
        negativeCount: 40,
        skippedCount: 0,
        positiveRate: 0.60,
        negativeRate: 0.40,
        responseRate: 1.0,
        netScore: 20.0,
        averageWeightedScore: 0.20,
      );

      final metricsB = AggregateMetrics(
        modelVersion: 'v2.0',
        periodStart: testStart,
        periodEnd: testEnd,
        totalFeedback: 100,
        positiveCount: 75,
        negativeCount: 25,
        skippedCount: 0,
        positiveRate: 0.75,
        negativeRate: 0.25,
        responseRate: 1.0,
        netScore: 50.0,
        averageWeightedScore: 0.50,
      );

      final comparison = ModelComparison(
        modelVersionA: 'v1.0',
        modelVersionB: 'v2.0',
        metricsA: metricsA,
        metricsB: metricsB,
        positiveRateDiff: 0.15,
        netScoreDiff: 30.0,
        isStatisticallySignificant: true,
      );

      expect(comparison.isBBetter, isTrue);
      expect(comparison.improvementPercent, closeTo(25, 1)); // 15% / 60% = 25%
    });
  });

  group('TrendDirection', () {
    test('has all expected values', () {
      expect(TrendDirection.values, contains(TrendDirection.increasing));
      expect(TrendDirection.values, contains(TrendDirection.decreasing));
      expect(TrendDirection.values, contains(TrendDirection.stable));
    });
  });

  group('TrendAnalysis', () {
    test('noData factory creates empty analysis', () {
      final analysis = TrendAnalysis.noData('v1.0');

      expect(analysis.modelVersion, equals('v1.0'));
      expect(analysis.periodDays, equals(0));
      expect(analysis.dailySummaries, isEmpty);
      expect(analysis.positiveRateTrend, equals(TrendDirection.stable));
      expect(analysis.isImproving, isFalse);
      expect(analysis.isDeclining, isFalse);
      expect(analysis.isStable, isTrue);
    });

    test('identifies stable trend correctly', () {
      final analysis = TrendAnalysis(
        modelVersion: 'v1.0',
        periodDays: 7,
        dailySummaries: const [],
        positiveRateTrend: TrendDirection.stable,
        netScoreTrend: TrendDirection.stable,
        averagePositiveRate: 0.75,
        averageNetScore: 50.0,
        volatility: 0.02,
        anomalyDates: const [],
        isImproving: false,
        isDeclining: false,
      );

      expect(analysis.isStable, isTrue);
      expect(analysis.hasAnomalies, isFalse);
    });

    test('identifies anomalies correctly', () {
      final analysis = TrendAnalysis(
        modelVersion: 'v1.0',
        periodDays: 7,
        dailySummaries: const [],
        positiveRateTrend: TrendDirection.stable,
        netScoreTrend: TrendDirection.stable,
        averagePositiveRate: 0.75,
        averageNetScore: 50.0,
        volatility: 0.1,
        anomalyDates: [DateTime(2024, 1, 15)],
        isImproving: false,
        isDeclining: false,
      );

      expect(analysis.hasAnomalies, isTrue);
    });
  });

  group('CalibrationAnalysis', () {
    test('identifies overconfident model', () {
      final analysis = CalibrationAnalysis(
        modelVersion: 'v1.0',
        periodStart: testStart,
        periodEnd: testEnd,
        totalFeedback: 100,
        tooHighCount: 30,
        tooLowCount: 5,
        correctCount: 65,
        calibrationBias: 0.25,
        primaryIssue: CalibrationIssue.overconfident,
        isWellCalibrated: false,
      );

      expect(analysis.primaryIssue, equals(CalibrationIssue.overconfident));
      expect(analysis.isWellCalibrated, isFalse);
    });

    test('identifies underconfident model', () {
      final analysis = CalibrationAnalysis(
        modelVersion: 'v1.0',
        periodStart: testStart,
        periodEnd: testEnd,
        totalFeedback: 100,
        tooHighCount: 5,
        tooLowCount: 30,
        correctCount: 65,
        calibrationBias: -0.25,
        primaryIssue: CalibrationIssue.underconfident,
        isWellCalibrated: false,
      );

      expect(analysis.primaryIssue, equals(CalibrationIssue.underconfident));
      expect(analysis.isWellCalibrated, isFalse);
    });

    test('identifies well-calibrated model', () {
      final analysis = CalibrationAnalysis(
        modelVersion: 'v1.0',
        periodStart: testStart,
        periodEnd: testEnd,
        totalFeedback: 100,
        tooHighCount: 5,
        tooLowCount: 5,
        correctCount: 90,
        calibrationBias: 0.0,
        primaryIssue: null,
        isWellCalibrated: true,
      );

      expect(analysis.primaryIssue, isNull);
      expect(analysis.isWellCalibrated, isTrue);
    });
  });

  group('VariantComparison', () {
    test('identifies winning treatment', () {
      final controlSummary = FeedbackSummary(
        modelVersion: 'v1.0',
        periodStart: DateTime(2024, 1, 1),
        periodEnd: DateTime(2024, 1, 31),
        totalFeedback: 100,
        positiveCount: 60,
        negativeCount: 40,
        skippedCount: 0,
        weightedScoreSum: 20,
        totalWeight: 100,
      );

      final treatmentSummary = FeedbackSummary(
        modelVersion: 'v1.0',
        periodStart: DateTime(2024, 1, 1),
        periodEnd: DateTime(2024, 1, 31),
        totalFeedback: 100,
        positiveCount: 75,
        negativeCount: 25,
        skippedCount: 0,
        weightedScoreSum: 50,
        totalWeight: 100,
      );

      final comparison = VariantComparison(
        experimentId: 'exp_123',
        variantSummaries: {
          'control': controlSummary,
          'treatment_a': treatmentSummary,
        },
        controlVariantId: 'control',
        bestVariantId: 'treatment_a',
        treatmentLift: 25.0,
        isSignificant: true,
      );

      expect(comparison.treatmentWins, isTrue);
      expect(comparison.treatmentLift, equals(25.0));
    });

    test('identifies control as winner when treatment underperforms', () {
      final controlSummary = FeedbackSummary(
        modelVersion: 'v1.0',
        periodStart: DateTime(2024, 1, 1),
        periodEnd: DateTime(2024, 1, 31),
        totalFeedback: 100,
        positiveCount: 75,
        negativeCount: 25,
        skippedCount: 0,
        weightedScoreSum: 50,
        totalWeight: 100,
      );

      final treatmentSummary = FeedbackSummary(
        modelVersion: 'v1.0',
        periodStart: DateTime(2024, 1, 1),
        periodEnd: DateTime(2024, 1, 31),
        totalFeedback: 100,
        positiveCount: 60,
        negativeCount: 40,
        skippedCount: 0,
        weightedScoreSum: 20,
        totalWeight: 100,
      );

      final comparison = VariantComparison(
        experimentId: 'exp_123',
        variantSummaries: {
          'control': controlSummary,
          'treatment_a': treatmentSummary,
        },
        controlVariantId: 'control',
        bestVariantId: 'control',
        treatmentLift: -20.0,
        isSignificant: true,
      );

      expect(comparison.treatmentWins, isFalse);
      expect(comparison.treatmentLift, equals(-20.0));
    });
  });

  group('WeeklySummary', () {
    test('stores week information correctly', () {
      final summary = FeedbackSummary(
        modelVersion: 'v1.0',
        periodStart: DateTime(2024, 1, 1),
        periodEnd: DateTime(2024, 1, 7),
        totalFeedback: 50,
        positiveCount: 40,
        negativeCount: 10,
        skippedCount: 0,
        weightedScoreSum: 30,
        totalWeight: 50,
      );

      final weekly = WeeklySummary(
        weekNumber: 1,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 7),
        summary: summary,
      );

      expect(weekly.weekNumber, equals(1));
      expect(weekly.summary.totalFeedback, equals(50));
      expect(weekly.summary.positiveRate, closeTo(0.8, 0.01));
    });
  });
}
