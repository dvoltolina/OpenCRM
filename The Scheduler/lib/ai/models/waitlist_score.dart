import 'package:freezed_annotation/freezed_annotation.dart';

part 'waitlist_score.freezed.dart';
part 'waitlist_score.g.dart';

/// Detailed scoring breakdown for a waitlist entry.
///
/// Shows how each factor contributed to the overall match score
/// when filling a cancelled slot.
///
/// Agent AI-21: Waitlist Intelligence & Demand Forecasting
@freezed
abstract class WaitlistScore with _$WaitlistScore {
  const factory WaitlistScore({
    /// Overall match score (0-100).
    required double overallScore,

    /// Time flexibility score (0-30).
    /// Higher if entry's preferred times match the slot.
    required double timeFlexibilityScore,

    /// Geographic proximity score (0-20).
    /// For mobile services, closer clients score higher.
    required double proximityScore,

    /// Historical confirm rate score (0-30).
    /// Based on client's past waitlist offer acceptance rate.
    required double confirmRateScore,

    /// Revenue priority score (0-10).
    /// Higher-value services or loyal clients score higher.
    required double revenueScore,

    /// Wait time fairness score (0-10).
    /// Longer wait = higher priority (fairness factor).
    required double fairnessScore,

    /// Individual factor details for UI display.
    @Default([]) List<WaitlistScoreFactor> factors,
  }) = _WaitlistScore;

  const WaitlistScore._();

  factory WaitlistScore.fromJson(Map<String, dynamic> json) =>
      _$WaitlistScoreFromJson(json);

  /// Check if this is a strong match (score >= 70).
  bool get isStrongMatch => overallScore >= 70;

  /// Check if this is a good match (score >= 50).
  bool get isGoodMatch => overallScore >= 50;

  /// Get the primary factor (highest contribution).
  WaitlistScoreFactor? get primaryFactor {
    if (factors.isEmpty) return null;
    return factors.reduce((a, b) => a.impact > b.impact ? a : b);
  }

  /// Get display percentage.
  String get scoreDisplay => '${overallScore.round()}%';
}

/// Individual scoring factor for waitlist matching.
@freezed
abstract class WaitlistScoreFactor with _$WaitlistScoreFactor {
  const factory WaitlistScoreFactor({
    /// Factor type identifier.
    required WaitlistFactorType factorType,

    /// Human-readable description.
    required String description,

    /// Impact on overall score (0-100 scale contribution).
    required double impact,

    /// Maximum possible impact for this factor.
    required double maxImpact,

    /// Icon name for UI.
    @Default('info') String iconName,
  }) = _WaitlistScoreFactor;

  const WaitlistScoreFactor._();

  factory WaitlistScoreFactor.fromJson(Map<String, dynamic> json) =>
      _$WaitlistScoreFactorFromJson(json);

  /// Percentage of max impact achieved.
  double get percentOfMax => maxImpact > 0 ? (impact / maxImpact) * 100 : 0;

  /// Whether this factor contributed positively.
  bool get isPositive => impact > maxImpact * 0.5;
}

/// Types of factors used in waitlist scoring.
enum WaitlistFactorType {
  /// Time preference match.
  timeFlexibility,

  /// Geographic distance (for mobile services).
  proximity,

  /// Historical acceptance rate.
  confirmRate,

  /// Revenue/value priority.
  revenue,

  /// Time on waitlist (fairness).
  fairness,

  /// Service type match.
  serviceMatch,

  /// Provider preference match.
  providerPreference,
}

/// Ranked waitlist entry with match score.
///
/// Combines waitlist entry data with AI-calculated match score
/// for filling a specific cancelled slot.
@freezed
abstract class RankedWaitlistEntry with _$RankedWaitlistEntry {
  const factory RankedWaitlistEntry({
    /// Waitlist entry ID.
    required String entryId,

    /// Client ID.
    required String clientId,

    /// Client name for display.
    required String clientName,

    /// Client phone for contact.
    String? clientPhone,

    /// Requested service ID.
    required String serviceId,

    /// Service name for display.
    required String serviceName,

    /// Match score details.
    required WaitlistScore score,

    /// Rank in the matched list (1 = best).
    required int rank,

    /// When the entry was added to waitlist.
    required DateTime addedAt,

    /// Client's preferred time windows.
    @Default([]) List<TimeWindow> preferredTimes,

    /// Distance to service location (km), if applicable.
    double? distanceKm,

    /// Client's historical confirm rate (0-1).
    double? historicalConfirmRate,

    /// Estimated revenue if booked.
    double? estimatedRevenue,

    /// Notes from the waitlist entry.
    String? notes,

    /// Whether an offer has been sent.
    @Default(false) bool offerSent,

    /// When the offer was sent.
    DateTime? offerSentAt,

    /// Offer response (accepted, declined, expired, null).
    String? offerResponse,

    /// Short explanation of why this is a good/poor match.
    String? matchReasoning,
  }) = _RankedWaitlistEntry;

  const RankedWaitlistEntry._();

  factory RankedWaitlistEntry.fromJson(Map<String, dynamic> json) =>
      _$RankedWaitlistEntryFromJson(json);

  /// Days on waitlist.
  int get daysOnWaitlist => DateTime.now().difference(addedAt).inDays;

  /// Whether this is a top candidate (rank <= 3).
  bool get isTopCandidate => rank <= 3;

  /// Display-friendly distance.
  String? get distanceDisplay =>
      distanceKm != null ? '${distanceKm!.toStringAsFixed(1)} km' : null;

  /// Confirm rate as percentage.
  String? get confirmRateDisplay => historicalConfirmRate != null
      ? '${(historicalConfirmRate! * 100).round()}%'
      : null;
}

/// Time window for waitlist preferences.
@freezed
abstract class TimeWindow with _$TimeWindow {
  const factory TimeWindow({
    /// Day of week (1=Monday, 7=Sunday).
    required int dayOfWeek,

    /// Start hour (0-23).
    required int startHour,

    /// End hour (0-23).
    required int endHour,
  }) = _TimeWindow;

  const TimeWindow._();

  factory TimeWindow.fromJson(Map<String, dynamic> json) =>
      _$TimeWindowFromJson(json);

  /// Check if a datetime falls within this window.
  bool contains(DateTime dt) {
    if (dt.weekday != dayOfWeek) return false;
    return dt.hour >= startHour && dt.hour < endHour;
  }

  /// Display string.
  String get display {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = days[dayOfWeek - 1];
    final startStr = _formatHour(startHour);
    final endStr = _formatHour(endHour);
    return '$dayName $startStr-$endStr';
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }
}

/// Result of waitlist matching operation.
@freezed
abstract class WaitlistMatchResult with _$WaitlistMatchResult {
  const factory WaitlistMatchResult({
    /// Cancelled slot ID being filled.
    required String slotId,

    /// Service ID of the slot.
    required String serviceId,

    /// Provider ID of the slot.
    required String providerId,

    /// Slot date/time.
    required DateTime slotDateTime,

    /// Ranked candidates.
    required List<RankedWaitlistEntry> candidates,

    /// Top candidates (automatically offered).
    @Default([]) List<RankedWaitlistEntry> topCandidates,

    /// When this match was generated.
    required DateTime generatedAt,

    /// Total waitlist entries considered.
    required int totalConsidered,

    /// Whether any strong matches found.
    @Default(false) bool hasStrongMatches,

    /// Reason if no matches found.
    String? noMatchReason,
  }) = _WaitlistMatchResult;

  const WaitlistMatchResult._();

  factory WaitlistMatchResult.fromJson(Map<String, dynamic> json) =>
      _$WaitlistMatchResultFromJson(json);

  /// Number of candidates found.
  int get candidateCount => candidates.length;

  /// Has any candidates.
  bool get hasCandidates => candidates.isNotEmpty;

  /// Best match score.
  double? get bestMatchScore =>
      candidates.isNotEmpty ? candidates.first.score.overallScore : null;
}

/// Request for waitlist matching.
@freezed
abstract class WaitlistMatchRequest with _$WaitlistMatchRequest {
  const factory WaitlistMatchRequest({
    /// Slot ID to fill.
    required String slotId,

    /// Service ID.
    required String serviceId,

    /// Provider ID.
    required String providerId,

    /// Slot date/time.
    required DateTime slotDateTime,

    /// Location ID (for proximity scoring).
    String? locationId,

    /// Maximum candidates to return.
    @Default(10) int maxCandidates,

    /// Auto-send offers to top N candidates.
    @Default(3) int autoOfferCount,

    /// Minimum score to include (0-100).
    @Default(30) double minScore,
  }) = _WaitlistMatchRequest;

  factory WaitlistMatchRequest.fromJson(Map<String, dynamic> json) =>
      _$WaitlistMatchRequestFromJson(json);
}
