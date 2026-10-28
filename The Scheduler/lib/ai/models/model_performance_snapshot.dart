import 'package:freezed_annotation/freezed_annotation.dart';

part 'model_performance_snapshot.freezed.dart';
part 'model_performance_snapshot.g.dart';

/// Status of model performance relative to baseline.
///
/// Agent AI-17: Model Monitoring & Retraining Automation
enum PerformanceStatus {
  /// Performance is within acceptable range
  @JsonValue('healthy')
  healthy,

  /// Performance has degraded but not critical
  @JsonValue('degraded')
  degraded,

  /// Performance is critically low, retraining needed
  @JsonValue('critical')
  critical,

  /// Not enough data to evaluate
  @JsonValue('insufficient_data')
  insufficientData,
}

extension PerformanceStatusExtension on PerformanceStatus {
  String get displayName {
    switch (this) {
      case PerformanceStatus.healthy:
        return 'Healthy';
      case PerformanceStatus.degraded:
        return 'Degraded';
      case PerformanceStatus.critical:
        return 'Critical';
      case PerformanceStatus.insufficientData:
        return 'Insufficient Data';
    }
  }

  int get colorValue {
    switch (this) {
      case PerformanceStatus.healthy:
        return 0xFF4CAF50; // Green
      case PerformanceStatus.degraded:
        return 0xFFFFC107; // Amber
      case PerformanceStatus.critical:
        return 0xFFF44336; // Red
      case PerformanceStatus.insufficientData:
        return 0xFF9E9E9E; // Grey
    }
  }

  bool get needsAttention =>
      this == PerformanceStatus.degraded || this == PerformanceStatus.critical;
}

/// Type of drift detected in the model.
enum DriftType {
  /// No significant drift detected
  @JsonValue('none')
  none,

  /// Feature distributions have shifted (data drift)
  @JsonValue('data_drift')
  dataDrift,

  /// Relationship between features and outcome has changed (concept drift)
  @JsonValue('concept_drift')
  conceptDrift,

  /// Both data and concept drift detected
  @JsonValue('both')
  both,
}

extension DriftTypeExtension on DriftType {
  String get displayName {
    switch (this) {
      case DriftType.none:
        return 'No Drift';
      case DriftType.dataDrift:
        return 'Data Drift';
      case DriftType.conceptDrift:
        return 'Concept Drift';
      case DriftType.both:
        return 'Data & Concept Drift';
    }
  }

  bool get hasDrift => this != DriftType.none;
}

/// Snapshot of model performance metrics at a point in time.
///
/// Captures key metrics for monitoring model health and triggering retraining.
@freezed
abstract class ModelPerformanceSnapshot with _$ModelPerformanceSnapshot {
  const factory ModelPerformanceSnapshot({
    /// Unique identifier for this snapshot
    required String id,

    /// Business this snapshot belongs to
    required String businessId,

    /// Model version being evaluated
    required String modelVersion,

    /// Start of the evaluation period
    required DateTime periodStart,

    /// End of the evaluation period
    required DateTime periodEnd,

    /// When this snapshot was created
    required DateTime createdAt,

    /// Number of predictions evaluated
    required int sampleSize,

    /// AUC-ROC score (0.0-1.0, higher is better)
    /// Area Under the Receiver Operating Characteristic curve
    required double aucRoc,

    /// Precision at 0.5 threshold
    required double precisionAt50,

    /// Recall at 0.5 threshold
    required double recallAt50,

    /// F1 score at 0.5 threshold
    required double f1At50,

    /// Brier score (0.0-1.0, lower is better)
    /// Measures calibration of probability predictions
    required double brierScore,

    /// Expected Calibration Error (0.0-1.0, lower is better)
    required double calibrationError,

    /// Log loss (lower is better)
    double? logLoss,

    /// Overall performance status
    required PerformanceStatus status,

    /// Type of drift detected
    @Default(DriftType.none) DriftType driftType,

    /// Drift score (standard deviations from baseline)
    @Default(0.0) double driftScore,

    /// Features showing significant drift
    @Default([]) List<String> driftedFeatures,

    /// Baseline metrics for comparison (from initial training)
    ModelBaselineMetrics? baseline,

    /// Whether retraining was triggered based on this snapshot
    @Default(false) bool retrainingTriggered,

    /// Notes or alerts generated for this snapshot
    @Default([]) List<String> alerts,
  }) = _ModelPerformanceSnapshot;

  factory ModelPerformanceSnapshot.fromJson(Map<String, dynamic> json) =>
      _$ModelPerformanceSnapshotFromJson(json);

  const ModelPerformanceSnapshot._();

  /// AUC change from baseline (negative = worse)
  double? get aucChangeFromBaseline {
    if (baseline == null) return null;
    return aucRoc - baseline!.aucRoc;
  }

  /// Percentage change in AUC from baseline
  double? get aucPercentChange {
    if (baseline == null || baseline!.aucRoc == 0) return null;
    return (aucRoc - baseline!.aucRoc) / baseline!.aucRoc * 100;
  }

  /// Whether AUC has dropped significantly (>5%)
  bool get hasSignificantAucDrop {
    final change = aucPercentChange;
    if (change == null) return false;
    return change < -5.0;
  }

  /// Whether metrics indicate retraining is needed
  bool get needsRetraining {
    if (status == PerformanceStatus.critical) return true;
    if (aucRoc < 0.75) return true;
    if (calibrationError > 0.1) return true;
    if (driftType.hasDrift && driftScore > 2.0) return true;
    return false;
  }

  /// Summary string for display
  String get summaryText {
    if (sampleSize < 50) return 'Insufficient data for evaluation';
    return 'AUC: ${(aucRoc * 100).toStringAsFixed(1)}%, '
        'Precision: ${(precisionAt50 * 100).toStringAsFixed(1)}%, '
        'Calibration Error: ${(calibrationError * 100).toStringAsFixed(1)}%';
  }
}

/// Baseline metrics from model training for comparison.
@freezed
abstract class ModelBaselineMetrics with _$ModelBaselineMetrics {
  const factory ModelBaselineMetrics({
    /// Model version
    required String modelVersion,

    /// When baseline was established
    required DateTime establishedAt,

    /// Baseline AUC-ROC
    required double aucRoc,

    /// Baseline precision
    required double precision,

    /// Baseline recall
    required double recall,

    /// Baseline F1 score
    required double f1,

    /// Baseline Brier score
    required double brierScore,

    /// Baseline calibration error
    required double calibrationError,

    /// Training sample size
    required int trainingSampleSize,

    /// Feature importance rankings at training time
    @Default({}) Map<String, double> featureImportances,

    /// Feature distribution statistics at training time
    @Default({}) Map<String, FeatureStats> featureStats,
  }) = _ModelBaselineMetrics;

  factory ModelBaselineMetrics.fromJson(Map<String, dynamic> json) =>
      _$ModelBaselineMetricsFromJson(json);

  const ModelBaselineMetrics._();
}

/// Statistics for a feature (for drift detection).
@freezed
abstract class FeatureStats with _$FeatureStats {
  const factory FeatureStats({
    /// Feature name
    required String featureName,

    /// Mean value (for numeric features)
    double? mean,

    /// Standard deviation (for numeric features)
    double? stdDev,

    /// Minimum value
    double? min,

    /// Maximum value
    double? max,

    /// Distribution of values (for categorical features)
    @Default({}) Map<String, double> distribution,

    /// Number of samples
    required int sampleCount,
  }) = _FeatureStats;

  factory FeatureStats.fromJson(Map<String, dynamic> json) =>
      _$FeatureStatsFromJson(json);

  const FeatureStats._();

  /// Calculate z-score for a new value
  double? zScore(double value) {
    if (mean == null || stdDev == null || stdDev == 0) return null;
    return (value - mean!) / stdDev!;
  }
}

/// Alert thresholds for model monitoring.
@freezed
abstract class MonitoringThresholds with _$MonitoringThresholds {
  const factory MonitoringThresholds({
    /// Minimum acceptable AUC (default: 0.75)
    @Default(0.75) double minAuc,

    /// Maximum acceptable calibration error (default: 0.1)
    @Default(0.1) double maxCalibrationError,

    /// AUC drop percentage to trigger alert (default: 5%)
    @Default(0.05) double aucDropThreshold,

    /// Drift score threshold in standard deviations (default: 2.0)
    @Default(2.0) double driftThreshold,

    /// Minimum sample size for evaluation (default: 50)
    @Default(50) int minSampleSize,

    /// Minimum outcomes needed before triggering retraining (default: 1000)
    @Default(1000) int minOutcomesForRetraining,
  }) = _MonitoringThresholds;

  factory MonitoringThresholds.fromJson(Map<String, dynamic> json) =>
      _$MonitoringThresholdsFromJson(json);

  const MonitoringThresholds._();

  /// Evaluate a snapshot against these thresholds
  PerformanceStatus evaluateStatus(ModelPerformanceSnapshot snapshot) {
    if (snapshot.sampleSize < minSampleSize) {
      return PerformanceStatus.insufficientData;
    }

    if (snapshot.aucRoc < minAuc || snapshot.calibrationError > maxCalibrationError) {
      return PerformanceStatus.critical;
    }

    if (snapshot.hasSignificantAucDrop || snapshot.driftScore > driftThreshold) {
      return PerformanceStatus.degraded;
    }

    return PerformanceStatus.healthy;
  }
}
