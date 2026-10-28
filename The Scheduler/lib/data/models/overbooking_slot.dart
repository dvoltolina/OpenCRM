import 'package:freezed_annotation/freezed_annotation.dart';

import '../converters/timestamp_converters.dart';

part 'overbooking_slot.freezed.dart';
part 'overbooking_slot.g.dart';

/// Status of an overbooking recommendation.
enum OverbookingStatus {
  /// Slot can accept overbookings
  available,

  /// Slot is at capacity (no overbooking recommended)
  atCapacity,

  /// Slot has pending overbook decision
  pending,

  /// Overbook was accepted and filled
  filled,

  /// Overbook was declined
  declined,

  /// Original appointment showed (no-show didn't occur)
  resolved,
}

/// Outcome of an overbooking decision for model improvement.
enum OverbookingOutcome {
  /// No-show occurred, overbook appointment was served
  noshowOccurred,

  /// All appointments showed, had to handle double-book
  doubleBooked,

  /// Overbook cancelled before appointment
  overbookCancelled,

  /// Original appointment cancelled
  originalCancelled,

  /// Pending - outcome not yet determined
  pending,
}

/// Represents a time slot's overbooking capacity and recommendation.
///
/// Used by the yield management system to track overbooking
/// decisions and outcomes for continuous model improvement.
///
/// Agent AI-16: Yield Management & Overbooking Engine
@freezed
abstract class OverbookingSlot with _$OverbookingSlot {
  const factory OverbookingSlot({
    /// Unique identifier for this overbooking slot record
    required String id,

    /// Business this slot belongs to
    required String businessId,

    /// Provider for this slot
    required String providerId,

    /// Location for this slot (if applicable)
    String? locationId,

    /// Date of the slot
    @TimestampConverter() required DateTime slotDate,

    /// Start time of the slot
    @TimestampConverter() required DateTime slotStartTime,

    /// End time of the slot
    @TimestampConverter() required DateTime slotEndTime,

    /// Service ID (if slot is service-specific)
    String? serviceId,

    /// Current number of bookings in this slot
    required int currentBookings,

    /// Maximum capacity for this slot (before overbooking)
    required int baseCapacity,

    /// Calculated safe overbooking count
    required int safeOverbookCount,

    /// Number of accepted overbooks
    @Default(0) int acceptedOverbooks,

    /// Weighted average no-show probability for appointments in slot
    required double weightedNoshowProbability,

    /// Average confidence of predictions
    required double averageConfidence,

    /// Historical no-show rate for this slot pattern
    double? historicalNoshowRate,

    /// Current status of this overbooking slot
    @Default(OverbookingStatus.available) OverbookingStatus status,

    /// Outcome after slot time passed (for model improvement)
    @Default(OverbookingOutcome.pending) OverbookingOutcome outcome,

    /// Expected revenue if all show (cents)
    required int expectedRevenueCents,

    /// Expected revenue with overbooking strategy (cents)
    required int projectedRevenueCents,

    /// Potential revenue at risk if double-book occurs (cents)
    required int riskRevenueCents,

    /// IDs of appointments in this slot
    required List<String> appointmentIds,

    /// IDs of overbooked appointments (if any)
    @Default([]) List<String> overbookedAppointmentIds,

    /// Whether this slot contains VIP clients (excluded from overbooking)
    @Default(false) bool hasVipClients,

    /// Whether this is a group session (never overbook)
    @Default(false) bool isGroupSession,

    /// Provider opted out of overbooking
    @Default(false) bool providerOptedOut,

    /// Reason if overbooking not recommended
    String? exclusionReason,

    /// When this analysis was calculated
    @TimestampConverter() required DateTime calculatedAt,

    /// When this record was last updated
    @NullableTimestampConverter() DateTime? updatedAt,

    /// Version of the yield algorithm used
    @Default('1.0.0') String algorithmVersion,
  }) = _OverbookingSlot;

  factory OverbookingSlot.fromJson(Map<String, dynamic> json) =>
      _$OverbookingSlotFromJson(json);

  const OverbookingSlot._();

  /// Whether overbooking is recommended for this slot
  bool get isOverbookingRecommended =>
      safeOverbookCount > 0 &&
      status == OverbookingStatus.available &&
      !hasVipClients &&
      !isGroupSession &&
      !providerOptedOut;

  /// Remaining overbook capacity
  int get remainingOverbookCapacity =>
      (safeOverbookCount - acceptedOverbooks).clamp(0, safeOverbookCount);

  /// Whether more overbooks can be accepted
  bool get canAcceptMoreOverbooks =>
      isOverbookingRecommended && remainingOverbookCapacity > 0;

  /// Fill rate (bookings / capacity)
  double get fillRate => baseCapacity > 0 ? currentBookings / baseCapacity : 0;

  /// Overbooking utilization (accepted / safe count)
  double get overbookUtilization =>
      safeOverbookCount > 0 ? acceptedOverbooks / safeOverbookCount : 0;

  /// Expected yield improvement percentage
  double get expectedYieldImprovement {
    if (expectedRevenueCents <= 0) return 0;
    return ((projectedRevenueCents - expectedRevenueCents) /
            expectedRevenueCents *
            100)
        .clamp(0, 100);
  }

  /// Risk-adjusted revenue (projected minus risk)
  int get riskAdjustedRevenueCents =>
      projectedRevenueCents - (riskRevenueCents * 0.1).round();

  /// Human-readable slot time description
  String get slotDescription {
    final start = '${slotStartTime.hour}:${slotStartTime.minute.toString().padLeft(2, '0')}';
    final end = '${slotEndTime.hour}:${slotEndTime.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }
}

/// Summary of overbooking analysis for a provider's day.
@freezed
abstract class DailyOverbookingSummary with _$DailyOverbookingSummary {
  const factory DailyOverbookingSummary({
    /// Provider ID
    required String providerId,

    /// Business ID
    required String businessId,

    /// Date of the summary
    @TimestampConverter() required DateTime date,

    /// Total slots analyzed
    required int totalSlots,

    /// Slots with overbooking opportunity
    required int slotsWithOpportunity,

    /// Total safe overbook capacity across all slots
    required int totalSafeOverbookCapacity,

    /// Total accepted overbooks
    required int totalAcceptedOverbooks,

    /// Expected additional revenue from overbooking (cents)
    required int expectedAdditionalRevenueCents,

    /// Average no-show probability across slots
    required double averageNoshowProbability,

    /// Slots excluded from overbooking
    required int excludedSlots,

    /// When this summary was calculated
    @TimestampConverter() required DateTime calculatedAt,
  }) = _DailyOverbookingSummary;

  factory DailyOverbookingSummary.fromJson(Map<String, dynamic> json) =>
      _$DailyOverbookingSummaryFromJson(json);

  const DailyOverbookingSummary._();

  /// Overbooking opportunity rate
  double get opportunityRate =>
      totalSlots > 0 ? slotsWithOpportunity / totalSlots : 0;

  /// Utilization rate of overbooking capacity
  double get utilizationRate => totalSafeOverbookCapacity > 0
      ? totalAcceptedOverbooks / totalSafeOverbookCapacity
      : 0;
}

/// Historical overbooking outcome for model improvement tracking.
@freezed
abstract class OverbookingOutcomeRecord with _$OverbookingOutcomeRecord {
  const factory OverbookingOutcomeRecord({
    /// Unique identifier
    required String id,

    /// Reference to the overbooking slot
    required String overbookingSlotId,

    /// Business ID
    required String businessId,

    /// Provider ID
    required String providerId,

    /// Slot date and time
    @TimestampConverter() required DateTime slotDateTime,

    /// Predicted no-show probability at decision time
    required double predictedNoshowProbability,

    /// Actual outcome
    required OverbookingOutcome actualOutcome,

    /// Whether prediction was accurate (no-show occurred as predicted)
    required bool predictionAccurate,

    /// Revenue impact (positive = gained, negative = lost)
    required int revenueImpactCents,

    /// Number of appointments that were overbooked
    required int overbookedCount,

    /// Number that actually no-showed
    required int actualNoshowCount,

    /// Algorithm version used
    required String algorithmVersion,

    /// When the outcome was recorded
    @TimestampConverter() required DateTime recordedAt,
  }) = _OverbookingOutcomeRecord;

  factory OverbookingOutcomeRecord.fromJson(Map<String, dynamic> json) =>
      _$OverbookingOutcomeRecordFromJson(json);
}
