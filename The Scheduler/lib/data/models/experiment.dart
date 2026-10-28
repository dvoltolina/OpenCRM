import 'package:freezed_annotation/freezed_annotation.dart';

import '../converters/timestamp_converters.dart';

part 'experiment.freezed.dart';
part 'experiment.g.dart';

/// Status of an experiment.
///
/// Agent AI-18: A/B Testing & Feedback Loop Framework
enum ExperimentStatus {
  /// Experiment is created but not yet running
  @JsonValue('draft')
  draft,

  /// Experiment is actively running and assigning variants
  @JsonValue('active')
  active,

  /// Experiment is paused (no new assignments)
  @JsonValue('paused')
  paused,

  /// Experiment has completed and results are final
  @JsonValue('completed')
  completed,

  /// Experiment was cancelled before completion
  @JsonValue('cancelled')
  cancelled,
}

extension ExperimentStatusExtension on ExperimentStatus {
  String get displayName {
    switch (this) {
      case ExperimentStatus.draft:
        return 'Draft';
      case ExperimentStatus.active:
        return 'Active';
      case ExperimentStatus.paused:
        return 'Paused';
      case ExperimentStatus.completed:
        return 'Completed';
      case ExperimentStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isRunning => this == ExperimentStatus.active;

  bool get canBeActivated =>
      this == ExperimentStatus.draft || this == ExperimentStatus.paused;

  bool get canBePaused => this == ExperimentStatus.active;

  bool get canBeCompleted =>
      this == ExperimentStatus.active || this == ExperimentStatus.paused;
}

/// Type of experiment being run.
enum ExperimentType {
  /// Compare different model versions
  @JsonValue('model_comparison')
  modelComparison,

  /// Test different risk thresholds
  @JsonValue('threshold_testing')
  thresholdTesting,

  /// Test different UI treatments
  @JsonValue('ui_treatment')
  uiTreatment,

  /// Test with/without specific features
  @JsonValue('feature_testing')
  featureTesting,
}

extension ExperimentTypeExtension on ExperimentType {
  String get displayName {
    switch (this) {
      case ExperimentType.modelComparison:
        return 'Model Comparison';
      case ExperimentType.thresholdTesting:
        return 'Threshold Testing';
      case ExperimentType.uiTreatment:
        return 'UI Treatment';
      case ExperimentType.featureTesting:
        return 'Feature Testing';
    }
  }

  String get description {
    switch (this) {
      case ExperimentType.modelComparison:
        return 'Compare different AI model versions (e.g., v1 vs v2)';
      case ExperimentType.thresholdTesting:
        return 'Test different risk threshold values';
      case ExperimentType.uiTreatment:
        return 'Test different UI presentations';
      case ExperimentType.featureTesting:
        return 'Test with or without specific features';
    }
  }
}

/// Configuration for an experiment variant.
@freezed
abstract class ExperimentVariant with _$ExperimentVariant {
  const factory ExperimentVariant({
    /// Unique identifier for this variant
    required String id,

    /// Human-readable name (e.g., "Control", "Treatment A")
    required String name,

    /// Description of what this variant does
    String? description,

    /// Percentage of traffic allocated to this variant (0-100)
    /// All variants in an experiment should sum to 100
    required int trafficPercentage,

    /// Whether this is the control variant (baseline)
    @Default(false) bool isControl,

    /// Variant-specific configuration
    /// For model_comparison: {"model_version": "v2.0"}
    /// For threshold_testing: {"high_risk_threshold": 0.5}
    /// For ui_treatment: {"show_explanation": true}
    /// For feature_testing: {"enable_weather": true}
    @Default({}) Map<String, dynamic> config,

    /// Number of users assigned to this variant
    @Default(0) int assignmentCount,

    /// Number of conversions (positive outcomes)
    @Default(0) int conversionCount,
  }) = _ExperimentVariant;

  factory ExperimentVariant.fromJson(Map<String, dynamic> json) =>
      _$ExperimentVariantFromJson(json);

  const ExperimentVariant._();

  /// Conversion rate for this variant
  double get conversionRate {
    if (assignmentCount == 0) return 0;
    return conversionCount / assignmentCount;
  }

  /// Create the control variant with default config
  static ExperimentVariant control({
    required int trafficPercentage,
    Map<String, dynamic>? config,
  }) {
    return ExperimentVariant(
      id: 'control',
      name: 'Control',
      description: 'Baseline experience (no changes)',
      trafficPercentage: trafficPercentage,
      isControl: true,
      config: config ?? {},
    );
  }

  /// Create a treatment variant
  static ExperimentVariant treatment({
    required String id,
    required String name,
    required int trafficPercentage,
    String? description,
    Map<String, dynamic>? config,
  }) {
    return ExperimentVariant(
      id: id,
      name: name,
      description: description,
      trafficPercentage: trafficPercentage,
      isControl: false,
      config: config ?? {},
    );
  }
}

/// An A/B experiment definition.
///
/// Experiments allow testing different AI configurations, model versions,
/// thresholds, or UI treatments to measure impact on user outcomes.
@freezed
abstract class Experiment with _$Experiment {
  const factory Experiment({
    /// Unique identifier for this experiment
    required String id,

    /// Business this experiment belongs to
    required String businessId,

    /// Human-readable name
    required String name,

    /// Detailed description of the experiment
    String? description,

    /// Type of experiment
    required ExperimentType type,

    /// Current status
    @Default(ExperimentStatus.draft) ExperimentStatus status,

    /// List of variants in this experiment
    required List<ExperimentVariant> variants,

    /// When the experiment was created
    @TimestampConverter() required DateTime createdAt,

    /// User who created the experiment
    required String createdBy,

    /// When the experiment was last updated
    @NullableTimestampConverter() DateTime? updatedAt,

    /// When the experiment was activated
    @NullableTimestampConverter() DateTime? startedAt,

    /// When the experiment ended
    @NullableTimestampConverter() DateTime? endedAt,

    /// Target sample size (optional)
    int? targetSampleSize,

    /// Minimum days to run before concluding
    @Default(7) int minimumRunDays,

    /// Maximum days to run
    @Default(30) int maximumRunDays,

    /// Key metric to measure (e.g., "prediction_accuracy", "user_satisfaction")
    @Default('prediction_accuracy') String primaryMetric,

    /// Additional metrics to track
    @Default([]) List<String> secondaryMetrics,

    /// Winning variant ID (set when experiment completes)
    String? winningVariantId,

    /// Statistical significance level required (default 95%)
    @Default(0.95) double requiredConfidence,

    /// Tags for categorization
    @Default([]) List<String> tags,
  }) = _Experiment;

  factory Experiment.fromJson(Map<String, dynamic> json) =>
      _$ExperimentFromJson(json);

  const Experiment._();

  /// Total assignments across all variants
  int get totalAssignments {
    return variants.fold(0, (sum, v) => sum + v.assignmentCount);
  }

  /// Whether the experiment has reached target sample size
  bool get hasReachedTargetSampleSize {
    if (targetSampleSize == null) return false;
    return totalAssignments >= targetSampleSize!;
  }

  /// Days since experiment started
  int? get daysRunning {
    if (startedAt == null) return null;
    return DateTime.now().difference(startedAt!).inDays;
  }

  /// Whether minimum run duration has passed
  bool get hasReachedMinimumDuration {
    final days = daysRunning;
    if (days == null) return false;
    return days >= minimumRunDays;
  }

  /// Whether maximum run duration has passed
  bool get hasExceededMaximumDuration {
    final days = daysRunning;
    if (days == null) return false;
    return days > maximumRunDays;
  }

  /// Get the control variant
  ExperimentVariant? get controlVariant {
    try {
      return variants.firstWhere((v) => v.isControl);
    } catch (_) {
      return null;
    }
  }

  /// Get treatment variants (non-control)
  List<ExperimentVariant> get treatmentVariants {
    return variants.where((v) => !v.isControl).toList();
  }

  /// Get variant by ID
  ExperimentVariant? getVariant(String variantId) {
    try {
      return variants.firstWhere((v) => v.id == variantId);
    } catch (_) {
      return null;
    }
  }

  /// Validate that traffic percentages sum to 100
  bool get hasValidTrafficAllocation {
    final total = variants.fold(0, (sum, v) => sum + v.trafficPercentage);
    return total == 100;
  }

  /// Get the best performing variant based on conversion rate
  ExperimentVariant? get bestPerformingVariant {
    if (variants.isEmpty) return null;
    return variants.reduce((a, b) => a.conversionRate > b.conversionRate ? a : b);
  }

  /// Check if a specific variant is winning with required confidence
  /// This is a simplified check - real implementation should use statistical tests
  bool isVariantWinning(String variantId) {
    final variant = getVariant(variantId);
    final control = controlVariant;

    if (variant == null || control == null) return false;
    if (variant.assignmentCount < 30 || control.assignmentCount < 30) return false;

    // Simple check: variant rate significantly higher than control
    final lift = (variant.conversionRate - control.conversionRate) / control.conversionRate;
    return lift > 0.05; // At least 5% lift
  }
}

/// Assignment of a user to an experiment variant.
@freezed
abstract class ExperimentAssignment with _$ExperimentAssignment {
  const factory ExperimentAssignment({
    /// Unique identifier for this assignment
    required String id,

    /// Business ID
    required String businessId,

    /// Experiment this assignment belongs to
    required String experimentId,

    /// Variant the user was assigned to
    required String variantId,

    /// User ID (staff member)
    required String userId,

    /// When the assignment was made
    @TimestampConverter() required DateTime assignedAt,

    /// Entity that the experiment applies to (e.g., appointment ID)
    String? entityId,

    /// Entity type (e.g., "appointment", "client")
    String? entityType,

    /// Whether the user converted (positive outcome)
    bool? converted,

    /// When conversion was recorded
    @NullableTimestampConverter() DateTime? convertedAt,

    /// Metadata about the conversion
    @Default({}) Map<String, dynamic> conversionMetadata,
  }) = _ExperimentAssignment;

  factory ExperimentAssignment.fromJson(Map<String, dynamic> json) =>
      _$ExperimentAssignmentFromJson(json);

  const ExperimentAssignment._();

  /// Whether this assignment has been evaluated
  bool get hasOutcome => converted != null;

  /// Time from assignment to conversion (if converted)
  Duration? get timeToConversion {
    if (convertedAt == null) return null;
    return convertedAt!.difference(assignedAt);
  }
}
