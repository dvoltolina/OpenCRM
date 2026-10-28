import 'dart:developer' as developer;
import 'dart:math' as math;

import '../../data/models/security_context.dart';
import '../../data/repositories/model_metrics_repository.dart';
import '../../data/repositories/prediction_outcomes_repository.dart';
import '../models/model_performance_snapshot.dart';
import '../models/prediction_outcome.dart';

/// Service for calculating and monitoring model performance metrics.
///
/// Computes rolling metrics like AUC, precision, recall, and calibration,
/// comparing current performance against baseline.
///
/// Agent AI-17: Model Monitoring & Retraining Automation
class ModelPerformanceService {
  ModelPerformanceService({
    required PredictionOutcomesRepository outcomesRepository,
    required ModelMetricsRepository metricsRepository,
  })  : _outcomesRepository = outcomesRepository,
        _metricsRepository = metricsRepository;

  final PredictionOutcomesRepository _outcomesRepository;
  final ModelMetricsRepository _metricsRepository;

  /// Calculate performance metrics for a time period.
  Future<ModelPerformanceSnapshot?> calculateMetrics({
    required SecurityContext context,
    required DateTime startDate,
    required DateTime endDate,
    String? modelVersion,
  }) async {
    // Get evaluable outcomes
    final outcomes = await _outcomesRepository.getEvaluableOutcomes(
      context: context,
      startDate: startDate,
      endDate: endDate,
      modelVersion: modelVersion,
    );

    if (outcomes.isEmpty) {
      developer.log(
        'No evaluable outcomes for period: $startDate - $endDate',
        name: 'ModelPerformanceService',
      );
      return null;
    }

    // Get thresholds and baseline
    final thresholds = await _metricsRepository.getThresholds(context);
    final usedModelVersion =
        modelVersion ?? outcomes.first.modelVersion;
    final baseline =
        await _metricsRepository.getBaseline(context, usedModelVersion);

    // Calculate metrics
    final metrics = _calculateMetrics(outcomes);

    // Determine status
    final status = _determineStatus(metrics, thresholds, baseline);

    // Generate alerts
    final alerts = _generateAlerts(metrics, thresholds, baseline);

    final snapshot = ModelPerformanceSnapshot(
      id: '',
      businessId: context.businessId,
      modelVersion: usedModelVersion,
      periodStart: startDate,
      periodEnd: endDate,
      createdAt: DateTime.now(),
      sampleSize: outcomes.length,
      aucRoc: metrics.aucRoc,
      precisionAt50: metrics.precision,
      recallAt50: metrics.recall,
      f1At50: metrics.f1,
      brierScore: metrics.brierScore,
      calibrationError: metrics.calibrationError,
      logLoss: metrics.logLoss,
      status: status,
      baseline: baseline,
      alerts: alerts,
    );

    developer.log(
      'Calculated metrics: AUC=${metrics.aucRoc.toStringAsFixed(3)}, '
      'Precision=${metrics.precision.toStringAsFixed(3)}, '
      'Status=${status.name}',
      name: 'ModelPerformanceService',
    );

    return snapshot;
  }

  /// Calculate and save a performance snapshot.
  Future<ModelPerformanceSnapshot?> createAndSaveSnapshot({
    required SecurityContext context,
    required DateTime startDate,
    required DateTime endDate,
    String? modelVersion,
  }) async {
    final snapshot = await calculateMetrics(
      context: context,
      startDate: startDate,
      endDate: endDate,
      modelVersion: modelVersion,
    );

    if (snapshot == null) return null;

    return _metricsRepository.saveSnapshot(
      context: context,
      snapshot: snapshot,
    );
  }

  /// Calculate rolling metrics for the past N days.
  Future<ModelPerformanceSnapshot?> calculateRollingMetrics({
    required SecurityContext context,
    int days = 7,
    String? modelVersion,
  }) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    return calculateMetrics(
      context: context,
      startDate: startDate,
      endDate: endDate,
      modelVersion: modelVersion,
    );
  }

  /// Compare current performance with baseline.
  Future<PerformanceComparison?> compareWithBaseline({
    required SecurityContext context,
    required String modelVersion,
    int evaluationDays = 7,
  }) async {
    final baseline =
        await _metricsRepository.getBaseline(context, modelVersion);
    if (baseline == null) {
      developer.log(
        'No baseline found for model version: $modelVersion',
        name: 'ModelPerformanceService',
      );
      return null;
    }

    final current = await calculateRollingMetrics(
      context: context,
      days: evaluationDays,
      modelVersion: modelVersion,
    );

    if (current == null) return null;

    return PerformanceComparison(
      modelVersion: modelVersion,
      baseline: baseline,
      current: current,
      aucChange: current.aucRoc - baseline.aucRoc,
      aucPercentChange: ((current.aucRoc - baseline.aucRoc) / baseline.aucRoc) * 100,
      precisionChange: current.precisionAt50 - baseline.precision,
      recallChange: current.recallAt50 - baseline.recall,
      calibrationChange: current.calibrationError - baseline.calibrationError,
    );
  }

  /// Get the latest snapshot for display.
  Future<ModelPerformanceSnapshot?> getLatestSnapshot(
    SecurityContext context, {
    String? modelVersion,
  }) async {
    return _metricsRepository.getLatestSnapshot(
      context,
      modelVersion: modelVersion,
    );
  }

  /// Get AUC trend for dashboard.
  Future<List<Map<String, dynamic>>> getAucTrend(
    SecurityContext context, {
    int days = 30,
    String? modelVersion,
  }) async {
    return _metricsRepository.getAucTrend(
      context: context,
      days: days,
      modelVersion: modelVersion,
    );
  }

  _CalculatedMetrics _calculateMetrics(List<PredictionOutcome> outcomes) {
    if (outcomes.isEmpty) {
      return _CalculatedMetrics.empty();
    }

    // Prepare data for calculations
    final predictions = <double>[];
    final actuals = <bool>[];

    for (final outcome in outcomes) {
      if (outcome.actualNoShow == null) continue;
      predictions.add(outcome.predictedProbability);
      actuals.add(outcome.actualNoShow!);
    }

    if (predictions.isEmpty) {
      return _CalculatedMetrics.empty();
    }

    // Calculate confusion matrix at 0.5 threshold
    int tp = 0, tn = 0, fp = 0, fn = 0;
    for (int i = 0; i < predictions.length; i++) {
      final predicted = predictions[i] >= 0.5;
      final actual = actuals[i];

      if (predicted && actual) tp++;
      else if (!predicted && !actual) tn++;
      else if (predicted && !actual) fp++;
      else fn++;
    }

    // Basic metrics
    final precision = tp + fp > 0 ? tp / (tp + fp) : 0.0;
    final recall = tp + fn > 0 ? tp / (tp + fn) : 0.0;
    final f1 = precision + recall > 0
        ? 2 * (precision * recall) / (precision + recall)
        : 0.0;

    // Brier score
    double brierSum = 0.0;
    for (int i = 0; i < predictions.length; i++) {
      final actual = actuals[i] ? 1.0 : 0.0;
      brierSum += (predictions[i] - actual) * (predictions[i] - actual);
    }
    final brierScore = brierSum / predictions.length;

    // Log loss
    double logLossSum = 0.0;
    for (int i = 0; i < predictions.length; i++) {
      final p = predictions[i].clamp(1e-15, 1 - 1e-15);
      final y = actuals[i] ? 1.0 : 0.0;
      logLossSum -= y * math.log(p) + (1 - y) * math.log(1 - p);
    }
    final logLoss = logLossSum / predictions.length;

    // AUC-ROC (simplified approximation using Mann-Whitney U)
    final aucRoc = _calculateAuc(predictions, actuals);

    // Calibration error (simplified ECE)
    final calibrationError = _calculateCalibrationError(predictions, actuals);

    return _CalculatedMetrics(
      aucRoc: aucRoc,
      precision: precision,
      recall: recall,
      f1: f1,
      brierScore: brierScore,
      logLoss: logLoss,
      calibrationError: calibrationError,
    );
  }

  double _calculateAuc(List<double> predictions, List<bool> actuals) {
    // Mann-Whitney U statistic for AUC
    final positives = <double>[];
    final negatives = <double>[];

    for (int i = 0; i < predictions.length; i++) {
      if (actuals[i]) {
        positives.add(predictions[i]);
      } else {
        negatives.add(predictions[i]);
      }
    }

    if (positives.isEmpty || negatives.isEmpty) return 0.5;

    int concordant = 0;
    int discordant = 0;
    int tied = 0;

    for (final pos in positives) {
      for (final neg in negatives) {
        if (pos > neg) {
          concordant++;
        } else if (pos < neg) {
          discordant++;
        } else {
          tied++;
        }
      }
    }

    final total = concordant + discordant + tied;
    if (total == 0) return 0.5;

    return (concordant + 0.5 * tied) / total;
  }

  double _calculateCalibrationError(List<double> predictions, List<bool> actuals) {
    // Expected Calibration Error with 10 bins
    const numBins = 10;
    final bins = List.generate(numBins, (_) => <int>[]);
    final binSums = List.filled(numBins, 0.0);
    final binCounts = List.filled(numBins, 0);
    final binPositives = List.filled(numBins, 0);

    for (int i = 0; i < predictions.length; i++) {
      final binIdx = (predictions[i] * numBins).floor().clamp(0, numBins - 1);
      bins[binIdx].add(i);
      binSums[binIdx] += predictions[i];
      binCounts[binIdx]++;
      if (actuals[i]) binPositives[binIdx]++;
    }

    double ece = 0.0;
    for (int b = 0; b < numBins; b++) {
      if (binCounts[b] == 0) continue;
      final avgPrediction = binSums[b] / binCounts[b];
      final actualRate = binPositives[b] / binCounts[b];
      ece += (binCounts[b] / predictions.length) * (avgPrediction - actualRate).abs();
    }

    return ece;
  }

  PerformanceStatus _determineStatus(
    _CalculatedMetrics metrics,
    MonitoringThresholds thresholds,
    ModelBaselineMetrics? baseline,
  ) {
    if (metrics.aucRoc < thresholds.minAuc) {
      return PerformanceStatus.critical;
    }

    if (metrics.calibrationError > thresholds.maxCalibrationError) {
      return PerformanceStatus.critical;
    }

    if (baseline != null) {
      final aucDrop = (baseline.aucRoc - metrics.aucRoc) / baseline.aucRoc;
      if (aucDrop > thresholds.aucDropThreshold) {
        return PerformanceStatus.degraded;
      }
    }

    return PerformanceStatus.healthy;
  }

  List<String> _generateAlerts(
    _CalculatedMetrics metrics,
    MonitoringThresholds thresholds,
    ModelBaselineMetrics? baseline,
  ) {
    final alerts = <String>[];

    if (metrics.aucRoc < thresholds.minAuc) {
      alerts.add(
          'AUC-ROC (${(metrics.aucRoc * 100).toStringAsFixed(1)}%) below threshold (${(thresholds.minAuc * 100).toStringAsFixed(0)}%)');
    }

    if (metrics.calibrationError > thresholds.maxCalibrationError) {
      alerts.add(
          'Calibration error (${(metrics.calibrationError * 100).toStringAsFixed(1)}%) exceeds threshold (${(thresholds.maxCalibrationError * 100).toStringAsFixed(0)}%)');
    }

    if (baseline != null) {
      final aucDrop = (baseline.aucRoc - metrics.aucRoc) / baseline.aucRoc;
      if (aucDrop > thresholds.aucDropThreshold) {
        alerts.add(
            'AUC dropped ${(aucDrop * 100).toStringAsFixed(1)}% from baseline');
      }
    }

    return alerts;
  }
}

class _CalculatedMetrics {
  final double aucRoc;
  final double precision;
  final double recall;
  final double f1;
  final double brierScore;
  final double logLoss;
  final double calibrationError;

  _CalculatedMetrics({
    required this.aucRoc,
    required this.precision,
    required this.recall,
    required this.f1,
    required this.brierScore,
    required this.logLoss,
    required this.calibrationError,
  });

  factory _CalculatedMetrics.empty() => _CalculatedMetrics(
        aucRoc: 0.5,
        precision: 0,
        recall: 0,
        f1: 0,
        brierScore: 0.25,
        logLoss: 0.69, // -ln(0.5)
        calibrationError: 0,
      );
}

/// Comparison of current performance with baseline.
class PerformanceComparison {
  final String modelVersion;
  final ModelBaselineMetrics baseline;
  final ModelPerformanceSnapshot current;
  final double aucChange;
  final double aucPercentChange;
  final double precisionChange;
  final double recallChange;
  final double calibrationChange;

  PerformanceComparison({
    required this.modelVersion,
    required this.baseline,
    required this.current,
    required this.aucChange,
    required this.aucPercentChange,
    required this.precisionChange,
    required this.recallChange,
    required this.calibrationChange,
  });

  bool get hasSignificantDegradation => aucPercentChange < -5.0;

  String get summaryText {
    final direction = aucChange >= 0 ? 'up' : 'down';
    return 'AUC ${direction} ${aucPercentChange.abs().toStringAsFixed(1)}% '
        'from baseline (${(baseline.aucRoc * 100).toStringAsFixed(1)}% → '
        '${(current.aucRoc * 100).toStringAsFixed(1)}%)';
  }
}
