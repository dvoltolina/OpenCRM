import 'package:freezed_annotation/freezed_annotation.dart';

import '../converters/timestamp_converters.dart';

part 'prediction_feedback.freezed.dart';
part 'prediction_feedback.g.dart';

/// Type of feedback provided on a prediction.
///
/// Agent AI-18: A/B Testing & Feedback Loop Framework
enum FeedbackType {
  /// Prediction was helpful/accurate
  @JsonValue('positive')
  positive,

  /// Prediction was not helpful/inaccurate
  @JsonValue('negative')
  negative,

  /// User skipped providing feedback
  @JsonValue('skipped')
  skipped,
}

extension FeedbackTypeExtension on FeedbackType {
  String get displayName {
    switch (this) {
      case FeedbackType.positive:
        return 'Helpful';
      case FeedbackType.negative:
        return 'Not Helpful';
      case FeedbackType.skipped:
        return 'Skipped';
    }
  }

  String get emoji {
    switch (this) {
      case FeedbackType.positive:
        return '👍';
      case FeedbackType.negative:
        return '👎';
      case FeedbackType.skipped:
        return '⏭️';
    }
  }

  /// Weight for feedback aggregation (admin feedback counts more)
  double get baseWeight {
    switch (this) {
      case FeedbackType.positive:
        return 1.0;
      case FeedbackType.negative:
        return 1.0;
      case FeedbackType.skipped:
        return 0.0; // Skipped doesn't count
    }
  }
}

/// Reason for negative feedback.
enum NegativeFeedbackReason {
  /// Prediction probability was too high
  @JsonValue('probability_too_high')
  probabilityTooHigh,

  /// Prediction probability was too low
  @JsonValue('probability_too_low')
  probabilityTooLow,

  /// Wrong risk factors highlighted
  @JsonValue('wrong_factors')
  wrongFactors,

  /// Prediction didn't match known behavior
  @JsonValue('doesnt_match_behavior')
  doesntMatchBehavior,

  /// Recommended action wasn't appropriate
  @JsonValue('inappropriate_action')
  inappropriateAction,

  /// Other reason (see comment)
  @JsonValue('other')
  other,
}

extension NegativeFeedbackReasonExtension on NegativeFeedbackReason {
  String get displayName {
    switch (this) {
      case NegativeFeedbackReason.probabilityTooHigh:
        return 'Probability too high';
      case NegativeFeedbackReason.probabilityTooLow:
        return 'Probability too low';
      case NegativeFeedbackReason.wrongFactors:
        return 'Wrong risk factors shown';
      case NegativeFeedbackReason.doesntMatchBehavior:
        return "Doesn't match client behavior";
      case NegativeFeedbackReason.inappropriateAction:
        return 'Suggested action not appropriate';
      case NegativeFeedbackReason.other:
        return 'Other';
    }
  }
}

/// Role of the user providing feedback (affects weight).
enum FeedbackUserRole {
  /// Business owner/admin
  @JsonValue('admin')
  admin,

  /// Manager
  @JsonValue('manager')
  manager,

  /// Regular staff member
  @JsonValue('staff')
  staff,

  /// Guest or limited user
  @JsonValue('guest')
  guest,
}

extension FeedbackUserRoleExtension on FeedbackUserRole {
  String get displayName {
    switch (this) {
      case FeedbackUserRole.admin:
        return 'Admin';
      case FeedbackUserRole.manager:
        return 'Manager';
      case FeedbackUserRole.staff:
        return 'Staff';
      case FeedbackUserRole.guest:
        return 'Guest';
    }
  }

  /// Weight multiplier based on role (admin feedback counts more)
  double get roleWeight {
    switch (this) {
      case FeedbackUserRole.admin:
        return 2.0;
      case FeedbackUserRole.manager:
        return 1.5;
      case FeedbackUserRole.staff:
        return 1.0;
      case FeedbackUserRole.guest:
        return 0.5;
    }
  }
}

/// User feedback on a prediction.
///
/// Records whether a prediction was helpful and any details about why.
/// Used to improve model quality and identify systematic issues.
@freezed
abstract class PredictionFeedback with _$PredictionFeedback {
  const factory PredictionFeedback({
    /// Unique identifier for this feedback
    required String id,

    /// Business this feedback belongs to
    required String businessId,

    /// Appointment ID the prediction was for
    required String appointmentId,

    /// Client ID for the appointment
    required String clientId,

    /// Prediction ID this feedback is about
    String? predictionId,

    /// User who provided the feedback
    required String userId,

    /// Role of the user providing feedback
    required FeedbackUserRole userRole,

    /// Type of feedback (positive, negative, skipped)
    required FeedbackType feedbackType,

    /// Reason for negative feedback (only for negative)
    NegativeFeedbackReason? negativeReason,

    /// Free-form comment explaining feedback
    String? comment,

    /// Model version that made the prediction
    required String modelVersion,

    /// Predicted probability when feedback was given
    required double predictedProbability,

    /// Risk level when feedback was given
    required String predictedRiskLevel,

    /// When the feedback was submitted
    @TimestampConverter() required DateTime submittedAt,

    /// Experiment variant ID (if from an experiment)
    String? experimentVariantId,

    /// Experiment ID (if from an experiment)
    String? experimentId,

    /// Calculated weight for this feedback (role * base weight)
    @Default(1.0) double weight,

    /// Whether this feedback has been processed for training
    @Default(false) bool processedForTraining,

    /// When this feedback was processed
    @NullableTimestampConverter() DateTime? processedAt,
  }) = _PredictionFeedback;

  factory PredictionFeedback.fromJson(Map<String, dynamic> json) =>
      _$PredictionFeedbackFromJson(json);

  const PredictionFeedback._();

  /// Calculate the weighted score for this feedback
  /// +1 for positive, -1 for negative, 0 for skipped
  double get weightedScore {
    switch (feedbackType) {
      case FeedbackType.positive:
        return weight;
      case FeedbackType.negative:
        return -weight;
      case FeedbackType.skipped:
        return 0;
    }
  }

  /// Whether this is actionable feedback (not skipped)
  bool get isActionable => feedbackType != FeedbackType.skipped;

  /// Whether this indicates a model problem
  bool get indicatesModelProblem =>
      feedbackType == FeedbackType.negative &&
      negativeReason != NegativeFeedbackReason.other;

  /// Create feedback with calculated weight
  static PredictionFeedback create({
    required String id,
    required String businessId,
    required String appointmentId,
    required String clientId,
    required String userId,
    required FeedbackUserRole userRole,
    required FeedbackType feedbackType,
    required String modelVersion,
    required double predictedProbability,
    required String predictedRiskLevel,
    NegativeFeedbackReason? negativeReason,
    String? comment,
    String? predictionId,
    String? experimentId,
    String? experimentVariantId,
  }) {
    final weight = feedbackType.baseWeight * userRole.roleWeight;

    return PredictionFeedback(
      id: id,
      businessId: businessId,
      appointmentId: appointmentId,
      clientId: clientId,
      predictionId: predictionId,
      userId: userId,
      userRole: userRole,
      feedbackType: feedbackType,
      negativeReason: negativeReason,
      comment: comment,
      modelVersion: modelVersion,
      predictedProbability: predictedProbability,
      predictedRiskLevel: predictedRiskLevel,
      submittedAt: DateTime.now(),
      experimentId: experimentId,
      experimentVariantId: experimentVariantId,
      weight: weight,
    );
  }
}

/// Aggregated feedback metrics for a model version or time period.
@freezed
abstract class FeedbackSummary with _$FeedbackSummary {
  const factory FeedbackSummary({
    /// Model version these metrics are for
    required String modelVersion,

    /// Time period start
    @TimestampConverter() required DateTime periodStart,

    /// Time period end
    @TimestampConverter() required DateTime periodEnd,

    /// Total feedback submissions
    required int totalFeedback,

    /// Positive feedback count
    required int positiveCount,

    /// Negative feedback count
    required int negativeCount,

    /// Skipped count
    required int skippedCount,

    /// Sum of weighted scores
    required double weightedScoreSum,

    /// Sum of weights (for averaging)
    required double totalWeight,

    /// Breakdown by negative reason
    @Default({}) Map<String, int> negativeReasonCounts,

    /// Most common negative reasons
    @Default([]) List<String> topNegativeReasons,

    /// Business ID (if scoped to one business)
    String? businessId,

    /// Experiment ID (if scoped to an experiment)
    String? experimentId,

    /// Variant ID (if scoped to a variant)
    String? variantId,
  }) = _FeedbackSummary;

  factory FeedbackSummary.fromJson(Map<String, dynamic> json) =>
      _$FeedbackSummaryFromJson(json);

  const FeedbackSummary._();

  /// Actionable feedback (positive + negative, excluding skipped)
  int get actionableFeedback => positiveCount + negativeCount;

  /// Positive rate among actionable feedback
  double get positiveRate {
    if (actionableFeedback == 0) return 0;
    return positiveCount / actionableFeedback;
  }

  /// Negative rate among actionable feedback
  double get negativeRate {
    if (actionableFeedback == 0) return 0;
    return negativeCount / actionableFeedback;
  }

  /// Average weighted score (-1 to +1 scale)
  double get averageWeightedScore {
    if (totalWeight == 0) return 0;
    return weightedScoreSum / totalWeight;
  }

  /// Feedback score as percentage (0-100)
  double get scorePercentage {
    return (averageWeightedScore + 1) / 2 * 100;
  }

  /// Response rate (actionable / total)
  double get responseRate {
    if (totalFeedback == 0) return 0;
    return actionableFeedback / totalFeedback;
  }

  /// Net Promoter-style score (-100 to +100)
  double get netScore {
    if (actionableFeedback == 0) return 0;
    return ((positiveCount - negativeCount) / actionableFeedback) * 100;
  }

  /// Create an empty summary for a period
  static FeedbackSummary empty({
    required String modelVersion,
    required DateTime periodStart,
    required DateTime periodEnd,
    String? businessId,
    String? experimentId,
    String? variantId,
  }) {
    return FeedbackSummary(
      modelVersion: modelVersion,
      periodStart: periodStart,
      periodEnd: periodEnd,
      totalFeedback: 0,
      positiveCount: 0,
      negativeCount: 0,
      skippedCount: 0,
      weightedScoreSum: 0,
      totalWeight: 0,
      businessId: businessId,
      experimentId: experimentId,
      variantId: variantId,
    );
  }
}
