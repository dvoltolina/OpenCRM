import 'package:freezed_annotation/freezed_annotation.dart';

part 'prediction_outcome.freezed.dart';
part 'prediction_outcome.g.dart';

/// Outcome of an appointment after it was predicted.
///
/// Used to track prediction accuracy by comparing predicted probability
/// with actual show/no-show outcome.
///
/// Agent AI-17: Model Monitoring & Retraining Automation
enum AppointmentOutcome {
  /// Client attended the appointment
  @JsonValue('attended')
  attended,

  /// Client did not show up (no-show)
  @JsonValue('noshow')
  noshow,

  /// Client cancelled before appointment
  @JsonValue('cancelled')
  cancelled,

  /// Appointment was rescheduled
  @JsonValue('rescheduled')
  rescheduled,

  /// Outcome not yet determined
  @JsonValue('pending')
  pending,
}

extension AppointmentOutcomeExtension on AppointmentOutcome {
  /// Whether this outcome counts as a "no-show" for model training
  bool get isNoShow => this == AppointmentOutcome.noshow;

  /// Whether this outcome is usable for model evaluation
  /// Cancelled and rescheduled are excluded as they're distinct behaviors
  bool get isUsableForEvaluation =>
      this == AppointmentOutcome.attended || this == AppointmentOutcome.noshow;

  /// Binary outcome for model evaluation (true = no-show)
  bool? get binaryOutcome {
    if (!isUsableForEvaluation) return null;
    return isNoShow;
  }

  String get displayName {
    switch (this) {
      case AppointmentOutcome.attended:
        return 'Attended';
      case AppointmentOutcome.noshow:
        return 'No-Show';
      case AppointmentOutcome.cancelled:
        return 'Cancelled';
      case AppointmentOutcome.rescheduled:
        return 'Rescheduled';
      case AppointmentOutcome.pending:
        return 'Pending';
    }
  }
}

/// Recorded prediction with its actual outcome.
///
/// Links a no-show prediction to the eventual appointment outcome,
/// enabling accuracy tracking and model performance evaluation.
@freezed
abstract class PredictionOutcome with _$PredictionOutcome {
  const factory PredictionOutcome({
    /// Unique identifier for this record
    required String id,

    /// Business this prediction belongs to
    required String businessId,

    /// Appointment ID that was predicted
    required String appointmentId,

    /// Client ID for the appointment
    required String clientId,

    /// Predicted no-show probability (0.0-1.0)
    required double predictedProbability,

    /// Risk level assigned at prediction time
    required String predictedRiskLevel,

    /// Model version that made the prediction
    required String modelVersion,

    /// Confidence score of the prediction (0.0-1.0)
    required double confidence,

    /// When the prediction was made
    required DateTime predictedAt,

    /// Scheduled time of the appointment
    required DateTime appointmentTime,

    /// Actual outcome of the appointment
    @Default(AppointmentOutcome.pending) AppointmentOutcome outcome,

    /// When the outcome was recorded
    DateTime? outcomeRecordedAt,

    /// Whether prediction was correct (only set when outcome is usable)
    /// True if high-risk prediction and no-show, or low-risk and attended
    bool? predictionCorrect,

    /// Absolute prediction error (|predicted - actual|)
    /// Only set when outcome is usable for evaluation
    double? predictionError,

    /// Top feature names that contributed to this prediction
    @Default([]) List<String> topFeatures,

    /// Optional provider ID for the appointment
    String? providerId,

    /// Optional service ID for the appointment
    String? serviceId,
  }) = _PredictionOutcome;

  factory PredictionOutcome.fromJson(Map<String, dynamic> json) =>
      _$PredictionOutcomeFromJson(json);

  const PredictionOutcome._();

  /// Check if this prediction can be evaluated (has usable outcome)
  bool get canEvaluate => outcome.isUsableForEvaluation;

  /// Get the binary actual outcome (true = no-show, false = attended)
  bool? get actualNoShow => outcome.binaryOutcome;

  /// Calculate the Brier score component for this prediction
  /// Lower is better: (predicted - actual)^2
  double? get brierComponent {
    final actual = actualNoShow;
    if (actual == null) return null;
    final actualValue = actual ? 1.0 : 0.0;
    return (predictedProbability - actualValue) *
        (predictedProbability - actualValue);
  }

  /// Whether the predicted risk level matches the outcome
  /// High/Medium risk + no-show = correct, Low risk + attended = correct
  bool? get riskLevelCorrect {
    final actual = actualNoShow;
    if (actual == null) return null;

    final isHighRisk =
        predictedRiskLevel == 'high' || predictedRiskLevel == 'medium';
    return (isHighRisk && actual) || (!isHighRisk && !actual);
  }

  /// Days between prediction and appointment
  int get daysUntilAppointment {
    return appointmentTime.difference(predictedAt).inDays;
  }

  /// Create a new outcome with evaluation metrics calculated
  PredictionOutcome withEvaluation() {
    if (!canEvaluate) return this;

    final actual = actualNoShow!;
    final actualValue = actual ? 1.0 : 0.0;
    final error = (predictedProbability - actualValue).abs();

    return copyWith(
      predictionCorrect: riskLevelCorrect,
      predictionError: error,
    );
  }
}

/// Summary of prediction outcomes for a time period.
///
/// Aggregated metrics without individual appointment details.
@freezed
abstract class PredictionOutcomeSummary with _$PredictionOutcomeSummary {
  const factory PredictionOutcomeSummary({
    /// Time period start
    required DateTime periodStart,

    /// Time period end
    required DateTime periodEnd,

    /// Total predictions made
    required int totalPredictions,

    /// Predictions with outcomes (attended or no-show)
    required int evaluatedPredictions,

    /// Number of correct predictions
    required int correctPredictions,

    /// Number of actual no-shows
    required int actualNoShows,

    /// Number of predicted high-risk that were no-shows (true positives)
    required int truePositives,

    /// Number of predicted low-risk that attended (true negatives)
    required int trueNegatives,

    /// Number of predicted high-risk that attended (false positives)
    required int falsePositives,

    /// Number of predicted low-risk that were no-shows (false negatives)
    required int falseNegatives,

    /// Model version(s) evaluated
    required List<String> modelVersions,
  }) = _PredictionOutcomeSummary;

  factory PredictionOutcomeSummary.fromJson(Map<String, dynamic> json) =>
      _$PredictionOutcomeSummaryFromJson(json);

  const PredictionOutcomeSummary._();

  /// Accuracy: (TP + TN) / total
  double get accuracy {
    if (evaluatedPredictions == 0) return 0;
    return (truePositives + trueNegatives) / evaluatedPredictions;
  }

  /// Precision: TP / (TP + FP)
  double get precision {
    final denominator = truePositives + falsePositives;
    if (denominator == 0) return 0;
    return truePositives / denominator;
  }

  /// Recall: TP / (TP + FN)
  double get recall {
    final denominator = truePositives + falseNegatives;
    if (denominator == 0) return 0;
    return truePositives / denominator;
  }

  /// F1 Score: 2 * (precision * recall) / (precision + recall)
  double get f1Score {
    final p = precision;
    final r = recall;
    if (p + r == 0) return 0;
    return 2 * (p * r) / (p + r);
  }

  /// No-show rate in this period
  double get noShowRate {
    if (evaluatedPredictions == 0) return 0;
    return actualNoShows / evaluatedPredictions;
  }
}
