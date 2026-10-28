import 'package:freezed_annotation/freezed_annotation.dart';

part 'slot_suggestion.freezed.dart';
part 'slot_suggestion.g.dart';

/// A time slot with risk score and recommendation status.
///
/// Used to rank available slots for a specific client based on
/// their historical booking patterns.
///
/// Agent AI-20: Smart Scheduling Suggestions
@freezed
abstract class ScoredSlot with _$ScoredSlot {
  const ScoredSlot._();

  const factory ScoredSlot({
    /// Unique slot identifier
    required String slotId,

    /// Provider ID for this slot
    required String providerId,

    /// Provider name for display
    required String providerName,

    /// Start time of the slot
    required DateTime startTime,

    /// End time of the slot
    required DateTime endTime,

    /// Predicted no-show risk for this client in this slot (0.0-1.0)
    required double predictedNoshowRisk,

    /// Overall score (higher is better) combining all factors
    required double score,

    /// Whether this slot is recommended for the client
    required bool isRecommended,

    /// Risk level classification
    required SlotRiskLevel riskLevel,

    /// Factors contributing to this score
    required List<SlotScoreFactor> scoreFactors,

    /// Human-readable reasoning for recommendation
    String? recommendationReason,

    /// How much better/worse than baseline (percentage)
    double? riskDifferencePercent,

    /// Service ID if specific to a service
    String? serviceId,

    /// Location ID if relevant
    String? locationId,

    /// Whether the slot is currently available
    @Default(true) bool isAvailable,
  }) = _ScoredSlot;

  factory ScoredSlot.fromJson(Map<String, dynamic> json) =>
      _$ScoredSlotFromJson(json);

  /// Format the start time for display.
  String get formattedTime {
    final hour = startTime.hour;
    final minute = startTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  /// Get the day of week name.
  String get dayName {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[startTime.weekday - 1];
  }

  /// Get full date string.
  String get formattedDate {
    return '${startTime.month}/${startTime.day}/${startTime.year}';
  }

  /// Check if this is significantly better than average.
  bool get isSignificantlyBetter =>
      riskDifferencePercent != null && riskDifferencePercent! < -15;

  /// Check if this is significantly worse than average.
  bool get isSignificantlyWorse =>
      riskDifferencePercent != null && riskDifferencePercent! > 15;
}

/// Risk level classification for slots.
enum SlotRiskLevel {
  low,
  medium,
  high,
  unknown,
}

/// A factor contributing to the slot score.
@freezed
abstract class SlotScoreFactor with _$SlotScoreFactor {
  const factory SlotScoreFactor({
    /// Factor type (e.g., "day_of_week", "hour", "provider", "lead_time")
    required String factorType,

    /// Human-readable description
    required String description,

    /// Impact on score (-1.0 to 1.0, negative is bad, positive is good)
    required double impact,

    /// Weight of this factor in overall score (0.0-1.0)
    required double weight,

    /// Icon name for UI display
    String? iconName,
  }) = _SlotScoreFactor;

  factory SlotScoreFactor.fromJson(Map<String, dynamic> json) =>
      _$SlotScoreFactorFromJson(json);
}

/// A slot suggestion with full reasoning.
@freezed
abstract class SlotSuggestion with _$SlotSuggestion {
  const SlotSuggestion._();

  const factory SlotSuggestion({
    /// The scored slot
    required ScoredSlot slot,

    /// Rank in the suggestion list (1 = best)
    required int rank,

    /// Main recommendation text
    required String headline,

    /// Detailed reasoning for this suggestion
    required String reasoning,

    /// Comparison to client's baseline risk
    String? comparisonText,

    /// Alternative slots if this one is high risk
    @Default([]) List<ScoredSlot> alternatives,

    /// Confidence in this suggestion (0.0-1.0)
    required double confidence,
  }) = _SlotSuggestion;

  factory SlotSuggestion.fromJson(Map<String, dynamic> json) =>
      _$SlotSuggestionFromJson(json);

  /// Check if alternatives should be shown.
  bool get shouldShowAlternatives =>
      slot.riskLevel == SlotRiskLevel.high && alternatives.isNotEmpty;
}

/// Collection of slot suggestions for a booking request.
@freezed
abstract class SlotSuggestionResult with _$SlotSuggestionResult {
  const SlotSuggestionResult._();

  const factory SlotSuggestionResult({
    /// Client ID these suggestions are for
    required String clientId,

    /// Service being booked
    required String serviceId,

    /// All scored slots, sorted by score (best first)
    required List<ScoredSlot> scoredSlots,

    /// Top recommendations (typically top 3)
    required List<SlotSuggestion> topSuggestions,

    /// Slots to avoid (high risk)
    required List<ScoredSlot> slotsToAvoid,

    /// Client's baseline no-show rate for comparison
    required double clientBaselineNoshowRate,

    /// Average risk across all available slots
    required double averageSlotRisk,

    /// Best available slot
    ScoredSlot? bestSlot,

    /// When this result was generated
    required DateTime generatedAt,

    /// Whether client has enough history for reliable suggestions
    required bool hasReliableHistory,

    /// Message if no reliable history
    String? insufficientHistoryMessage,
  }) = _SlotSuggestionResult;

  factory SlotSuggestionResult.fromJson(Map<String, dynamic> json) =>
      _$SlotSuggestionResultFromJson(json);

  /// Get recommended slots only.
  List<ScoredSlot> get recommendedSlots =>
      scoredSlots.where((s) => s.isRecommended).toList();

  /// Get count of low-risk slots.
  int get lowRiskSlotCount =>
      scoredSlots.where((s) => s.riskLevel == SlotRiskLevel.low).length;

  /// Get count of high-risk slots.
  int get highRiskSlotCount =>
      scoredSlots.where((s) => s.riskLevel == SlotRiskLevel.high).length;

  /// Check if there are any recommended slots.
  bool get hasRecommendations => recommendedSlots.isNotEmpty;

  /// Get improvement percentage of best slot vs baseline.
  double? get bestSlotImprovementPercent {
    if (bestSlot == null || clientBaselineNoshowRate == 0) return null;
    return ((clientBaselineNoshowRate - bestSlot!.predictedNoshowRisk) /
            clientBaselineNoshowRate) *
        100;
  }
}

/// Request for slot suggestions.
@freezed
abstract class SlotSuggestionRequest with _$SlotSuggestionRequest {
  const factory SlotSuggestionRequest({
    /// Client to get suggestions for
    required String clientId,

    /// Service being booked
    required String serviceId,

    /// Date range to search
    required DateTime startDate,
    required DateTime endDate,

    /// Specific provider (optional)
    String? providerId,

    /// Location filter (optional)
    String? locationId,

    /// Maximum number of suggestions
    @Default(10) int maxSuggestions,

    /// Whether to include high-risk slots in results
    @Default(true) bool includeHighRisk,
  }) = _SlotSuggestionRequest;

  factory SlotSuggestionRequest.fromJson(Map<String, dynamic> json) =>
      _$SlotSuggestionRequestFromJson(json);
}
