import 'package:freezed_annotation/freezed_annotation.dart';

part 'prediction_explanation.freezed.dart';
part 'prediction_explanation.g.dart';

/// A single factor contributing to a prediction explanation.
///
/// Each factor represents one feature that significantly influenced
/// the no-show prediction, with a human-readable explanation.
///
/// Agent AI-19: Prediction Explainability
@freezed
abstract class ExplanationFactor with _$ExplanationFactor {
  const factory ExplanationFactor({
    /// Internal feature name (e.g., "clientHistoricalNoshowRate")
    required String feature,

    /// Human-readable feature name (e.g., "Client's Past No-Show Rate")
    @JsonKey(name: 'display_name') required String displayName,

    /// Impact direction: "increases" or "decreases" risk
    required String impact,

    /// Normalized magnitude of impact (0.0 to 1.0)
    required double magnitude,

    /// Human-readable explanation (e.g., "Client has 40% historical no-show rate")
    required String explanation,

    /// Original feature value for display
    @JsonKey(name: 'feature_value') dynamic featureValue,
  }) = _ExplanationFactor;

  factory ExplanationFactor.fromJson(Map<String, dynamic> json) =>
      _$ExplanationFactorFromJson(json);
}

/// Complete explanation for a no-show prediction.
///
/// Contains the top contributing factors and a summary explaining
/// why the prediction was made.
///
/// Agent AI-19: Prediction Explainability
@freezed
abstract class PredictionExplanation with _$PredictionExplanation {
  const PredictionExplanation._();

  const factory PredictionExplanation({
    /// Appointment ID this explanation is for
    required String appointmentId,

    /// Predicted no-show probability (0.0 to 1.0)
    required double probability,

    /// Risk level: "high", "medium", "low"
    required String riskLevel,

    /// One-sentence summary of the prediction
    required String summary,

    /// Top factors contributing to this prediction (typically 3)
    required List<ExplanationFactor> topFactors,

    /// Model version that made this prediction
    required String modelVersion,

    /// Explanation algorithm version
    @Default('1.0.0') String explanationVersion,

    /// When this explanation was generated
    DateTime? generatedAt,
  }) = _PredictionExplanation;

  factory PredictionExplanation.fromJson(Map<String, dynamic> json) =>
      _$PredictionExplanationFromJson(json);

  /// Get factors that increase risk.
  List<ExplanationFactor> get riskIncreasingFactors =>
      topFactors.where((f) => f.impact == 'increases').toList();

  /// Get factors that decrease risk.
  List<ExplanationFactor> get riskDecreasingFactors =>
      topFactors.where((f) => f.impact == 'decreases').toList();

  /// Get the primary factor driving this prediction.
  ExplanationFactor? get primaryFactor =>
      topFactors.isNotEmpty ? topFactors.first : null;

  /// Check if this is a high-risk prediction.
  bool get isHighRisk => riskLevel.toLowerCase() == 'high';

  /// Check if this is a medium-risk prediction.
  bool get isMediumRisk => riskLevel.toLowerCase() == 'medium';

  /// Check if this is a low-risk prediction.
  bool get isLowRisk => riskLevel.toLowerCase() == 'low';

  /// Get probability as percentage string.
  String get probabilityPercent => '${(probability * 100).toStringAsFixed(0)}%';

  /// Generate a short explanation suitable for tooltips.
  String get shortExplanation {
    if (topFactors.isEmpty) return summary;
    return topFactors.first.explanation;
  }
}

/// Request to fetch explanation for a prediction.
@freezed
abstract class ExplanationRequest with _$ExplanationRequest {
  const factory ExplanationRequest({
    /// Appointment ID to explain
    @JsonKey(name: 'appointment_id') required String appointmentId,

    /// Include all factors, not just top 3
    @JsonKey(name: 'include_all_factors') @Default(false) bool includeAllFactors,

    /// Number of factors to return (default 3)
    @JsonKey(name: 'num_factors') @Default(3) int numFactors,
  }) = _ExplanationRequest;

  factory ExplanationRequest.fromJson(Map<String, dynamic> json) =>
      _$ExplanationRequestFromJson(json);
}

/// Cached explanation with expiry.
@freezed
abstract class CachedExplanation with _$CachedExplanation {
  const CachedExplanation._();

  const factory CachedExplanation({
    required PredictionExplanation explanation,
    required DateTime cachedAt,
    required DateTime expiresAt,
  }) = _CachedExplanation;

  factory CachedExplanation.fromJson(Map<String, dynamic> json) =>
      _$CachedExplanationFromJson(json);

  /// Check if this cached explanation has expired.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check if this cached explanation is still valid.
  bool get isValid => !isExpired;
}
