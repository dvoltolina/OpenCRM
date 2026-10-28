import 'dart:developer' as developer;
import 'dart:math' as math;

import '../../data/models/security_context.dart';
import '../../data/repositories/model_metrics_repository.dart';
import '../../data/repositories/prediction_outcomes_repository.dart';
import '../models/model_performance_snapshot.dart';
import '../models/prediction_outcome.dart';

/// Service for detecting model drift.
///
/// Monitors feature distributions over time to detect:
/// - Data drift: Feature distributions have shifted
/// - Concept drift: Relationship between features and outcome has changed
///
/// Agent AI-17: Model Monitoring & Retraining Automation
class DriftDetector {
  DriftDetector({
    required PredictionOutcomesRepository outcomesRepository,
    required ModelMetricsRepository metricsRepository,
  })  : _outcomesRepository = outcomesRepository,
        _metricsRepository = metricsRepository;

  final PredictionOutcomesRepository _outcomesRepository;
  final ModelMetricsRepository _metricsRepository;

  /// Detect drift by comparing recent predictions with baseline.
  Future<DriftAnalysis> detectDrift({
    required SecurityContext context,
    required String modelVersion,
    int recentDays = 7,
  }) async {
    // Get baseline statistics
    final baseline = await _metricsRepository.getBaseline(context, modelVersion);
    if (baseline == null) {
      developer.log(
        'No baseline found for model version: $modelVersion',
        name: 'DriftDetector',
      );
      return DriftAnalysis.noBaseline();
    }

    // Get recent outcomes
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: recentDays));

    final outcomes = await _outcomesRepository.getOutcomesForPeriod(
      context: context,
      startDate: startDate,
      endDate: endDate,
      modelVersion: modelVersion,
    );

    if (outcomes.length < 50) {
      developer.log(
        'Insufficient data for drift detection: ${outcomes.length} outcomes',
        name: 'DriftDetector',
      );
      return DriftAnalysis.insufficientData(outcomes.length);
    }

    // Detect data drift (prediction distribution shift)
    final dataDrift = _detectDataDrift(outcomes, baseline);

    // Detect concept drift (accuracy degradation)
    final conceptDrift = _detectConceptDrift(outcomes, baseline);

    // Combine results
    final driftType = _combineDriftTypes(dataDrift.hasDrift, conceptDrift.hasDrift);
    final overallScore = math.max(dataDrift.score, conceptDrift.score);

    return DriftAnalysis(
      hasDrift: driftType != DriftType.none,
      driftType: driftType,
      overallScore: overallScore,
      dataDrift: dataDrift,
      conceptDrift: conceptDrift,
      driftedFeatures: _identifyDriftedFeatures(outcomes, baseline),
      sampleSize: outcomes.length,
      analysisDate: DateTime.now(),
    );
  }

  /// Detect data drift by comparing prediction distributions.
  _DriftResult _detectDataDrift(
    List<PredictionOutcome> outcomes,
    ModelBaselineMetrics baseline,
  ) {
    if (outcomes.isEmpty) {
      return _DriftResult(hasDrift: false, score: 0, details: 'No data');
    }

    // Calculate current prediction distribution statistics
    final predictions = outcomes.map((o) => o.predictedProbability).toList();
    final currentMean = _mean(predictions);
    final currentStd = _stdDev(predictions, currentMean);

    // Compare with expected distribution (based on baseline calibration)
    // If baseline has prediction stats, compare; otherwise use expected values
    final baselineMean = baseline.featureStats['predicted_probability']?.mean ?? 0.3;
    final baselineStd = baseline.featureStats['predicted_probability']?.stdDev ?? 0.2;

    // Z-score of the distribution shift
    final meanShift = baselineStd > 0
        ? (currentMean - baselineMean).abs() / baselineStd
        : 0.0;

    // Variance ratio test
    final varianceRatio = baselineStd > 0 ? currentStd / baselineStd : 1.0;
    final varianceShift = (varianceRatio - 1.0).abs();

    // Combined drift score
    final driftScore = meanShift + varianceShift;

    // Threshold: 2 standard deviations indicates significant drift
    final hasDrift = driftScore > 2.0;

    return _DriftResult(
      hasDrift: hasDrift,
      score: driftScore,
      details: 'Mean shift: ${meanShift.toStringAsFixed(2)} std, '
          'Variance ratio: ${varianceRatio.toStringAsFixed(2)}',
    );
  }

  /// Detect concept drift by analyzing accuracy changes.
  _DriftResult _detectConceptDrift(
    List<PredictionOutcome> outcomes,
    ModelBaselineMetrics baseline,
  ) {
    // Only use evaluable outcomes
    final evaluable = outcomes.where((o) => o.canEvaluate).toList();

    if (evaluable.length < 30) {
      return _DriftResult(
        hasDrift: false,
        score: 0,
        details: 'Insufficient evaluable outcomes (${evaluable.length})',
      );
    }

    // Calculate current calibration
    final calibrationError = _calculateCalibrationError(evaluable);

    // Compare with baseline calibration
    final baselineCalibration = baseline.calibrationError;
    final calibrationIncrease = calibrationError - baselineCalibration;

    // Calculate accuracy difference
    final currentAccuracy = _calculateAccuracy(evaluable);
    final baselineAccuracy = baseline.precision; // Using precision as proxy
    final accuracyDrop = baselineAccuracy - currentAccuracy;

    // Concept drift score based on calibration and accuracy changes
    final driftScore = (calibrationIncrease * 10) + (accuracyDrop * 5);

    // Threshold: significant if calibration increased by 0.05 or accuracy dropped by 0.1
    final hasDrift = calibrationIncrease > 0.05 || accuracyDrop > 0.1;

    return _DriftResult(
      hasDrift: hasDrift,
      score: driftScore.clamp(0, 10),
      details: 'Calibration change: ${(calibrationIncrease * 100).toStringAsFixed(1)}%, '
          'Accuracy change: ${(-accuracyDrop * 100).toStringAsFixed(1)}%',
    );
  }

  /// Identify which features have drifted.
  List<String> _identifyDriftedFeatures(
    List<PredictionOutcome> outcomes,
    ModelBaselineMetrics baseline,
  ) {
    // Track feature occurrence frequency
    final featureCounts = <String, int>{};
    for (final outcome in outcomes) {
      for (final feature in outcome.topFeatures) {
        featureCounts[feature] = (featureCounts[feature] ?? 0) + 1;
      }
    }

    // Compare with baseline feature importances
    final driftedFeatures = <String>[];
    final baselineImportances = baseline.featureImportances;

    for (final entry in featureCounts.entries) {
      final feature = entry.key;
      final currentFreq = entry.value / outcomes.length;
      final baselineImportance = baselineImportances[feature] ?? 0.0;

      // If feature frequency differs significantly from baseline importance
      if ((currentFreq - baselineImportance).abs() > 0.2) {
        driftedFeatures.add(feature);
      }
    }

    return driftedFeatures.take(5).toList();
  }

  double _calculateCalibrationError(List<PredictionOutcome> outcomes) {
    const numBins = 10;
    final binCounts = List.filled(numBins, 0);
    final binSums = List.filled(numBins, 0.0);
    final binPositives = List.filled(numBins, 0);

    for (final outcome in outcomes) {
      if (outcome.actualNoShow == null) continue;
      final binIdx = (outcome.predictedProbability * numBins).floor().clamp(0, numBins - 1);
      binCounts[binIdx]++;
      binSums[binIdx] += outcome.predictedProbability;
      if (outcome.actualNoShow!) binPositives[binIdx]++;
    }

    double ece = 0.0;
    final total = outcomes.length;

    for (int b = 0; b < numBins; b++) {
      if (binCounts[b] == 0) continue;
      final avgPrediction = binSums[b] / binCounts[b];
      final actualRate = binPositives[b] / binCounts[b];
      ece += (binCounts[b] / total) * (avgPrediction - actualRate).abs();
    }

    return ece;
  }

  double _calculateAccuracy(List<PredictionOutcome> outcomes) {
    int correct = 0;
    int total = 0;

    for (final outcome in outcomes) {
      if (outcome.actualNoShow == null) continue;
      total++;
      final predicted = outcome.predictedProbability >= 0.5;
      if (predicted == outcome.actualNoShow) correct++;
    }

    return total > 0 ? correct / total : 0.0;
  }

  DriftType _combineDriftTypes(bool hasDataDrift, bool hasConceptDrift) {
    if (hasDataDrift && hasConceptDrift) return DriftType.both;
    if (hasDataDrift) return DriftType.dataDrift;
    if (hasConceptDrift) return DriftType.conceptDrift;
    return DriftType.none;
  }

  double _mean(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double _stdDev(List<double> values, double mean) {
    if (values.length < 2) return 0;
    final sumSquares = values.fold<double>(
      0,
      (sum, val) => sum + (val - mean) * (val - mean),
    );
    return math.sqrt(sumSquares / (values.length - 1));
  }
}

class _DriftResult {
  final bool hasDrift;
  final double score;
  final String details;

  _DriftResult({
    required this.hasDrift,
    required this.score,
    required this.details,
  });
}

/// Result of drift analysis.
class DriftAnalysis {
  final bool hasDrift;
  final DriftType driftType;
  final double overallScore;
  final _DriftResult? dataDrift;
  final _DriftResult? conceptDrift;
  final List<String> driftedFeatures;
  final int sampleSize;
  final DateTime analysisDate;
  final bool hasBaseline;
  final bool hasSufficientData;

  DriftAnalysis({
    required this.hasDrift,
    required this.driftType,
    required this.overallScore,
    required this.dataDrift,
    required this.conceptDrift,
    required this.driftedFeatures,
    required this.sampleSize,
    required this.analysisDate,
    this.hasBaseline = true,
    this.hasSufficientData = true,
  });

  factory DriftAnalysis.noBaseline() => DriftAnalysis(
        hasDrift: false,
        driftType: DriftType.none,
        overallScore: 0,
        dataDrift: null,
        conceptDrift: null,
        driftedFeatures: [],
        sampleSize: 0,
        analysisDate: DateTime.now(),
        hasBaseline: false,
        hasSufficientData: false,
      );

  factory DriftAnalysis.insufficientData(int sampleSize) => DriftAnalysis(
        hasDrift: false,
        driftType: DriftType.none,
        overallScore: 0,
        dataDrift: null,
        conceptDrift: null,
        driftedFeatures: [],
        sampleSize: sampleSize,
        analysisDate: DateTime.now(),
        hasBaseline: true,
        hasSufficientData: false,
      );

  String get summaryText {
    if (!hasBaseline) return 'No baseline available for comparison';
    if (!hasSufficientData) return 'Insufficient data ($sampleSize samples)';
    if (!hasDrift) return 'No significant drift detected';
    return '${driftType.displayName} detected (score: ${overallScore.toStringAsFixed(2)})';
  }
}
