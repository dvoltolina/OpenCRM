import 'package:freezed_annotation/freezed_annotation.dart';

part 'demand_forecast.freezed.dart';
part 'demand_forecast.g.dart';

/// Daily demand forecast prediction.
///
/// Predicts expected booking volume for a specific day
/// using time series analysis (Prophet).
///
/// Agent AI-21: Waitlist Intelligence & Demand Forecasting
@freezed
abstract class DemandForecast with _$DemandForecast {
  const factory DemandForecast({
    /// Date of the forecast.
    required DateTime date,

    /// Predicted booking count.
    required double predictedCount,

    /// Lower bound of confidence interval.
    required double lowerBound,

    /// Upper bound of confidence interval.
    required double upperBound,

    /// Demand level classification.
    required DemandLevel demandLevel,

    /// Confidence score (0-1).
    required double confidence,

    /// Day of week (1=Monday, 7=Sunday).
    required int dayOfWeek,

    /// Whether this is a holiday.
    @Default(false) bool isHoliday,

    /// Holiday name if applicable.
    String? holidayName,

    /// Year-over-year change percentage.
    double? yearOverYearChange,

    /// Week-over-week change percentage.
    double? weekOverWeekChange,

    /// Breakdown by service type.
    @Default({}) Map<String, double> serviceBreakdown,

    /// Breakdown by time of day.
    @Default({}) Map<String, double> hourlyBreakdown,
  }) = _DemandForecast;

  const DemandForecast._();

  factory DemandForecast.fromJson(Map<String, dynamic> json) =>
      _$DemandForecastFromJson(json);

  /// Confidence interval width.
  double get intervalWidth => upperBound - lowerBound;

  /// Relative uncertainty (interval / prediction).
  double get relativeUncertainty =>
      predictedCount > 0 ? intervalWidth / predictedCount : 1.0;

  /// Display string for predicted count.
  String get predictedCountDisplay => predictedCount.round().toString();

  /// Display string for confidence interval.
  String get intervalDisplay =>
      '${lowerBound.round()}-${upperBound.round()}';

  /// Day name.
  String get dayName {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dayOfWeek - 1];
  }

  /// Is high confidence (>= 0.7).
  bool get isHighConfidence => confidence >= 0.7;

  /// Is low confidence (< 0.5).
  bool get isLowConfidence => confidence < 0.5;
}

/// Demand level classification.
enum DemandLevel {
  /// Very low demand (< 25% of average).
  veryLow,

  /// Below average demand (25-75% of average).
  low,

  /// Normal demand (75-125% of average).
  normal,

  /// Above average demand (125-175% of average).
  high,

  /// Very high demand (> 175% of average).
  veryHigh,
}

/// Extension for DemandLevel display.
extension DemandLevelExtension on DemandLevel {
  String get displayName {
    switch (this) {
      case DemandLevel.veryLow:
        return 'Very Low';
      case DemandLevel.low:
        return 'Low';
      case DemandLevel.normal:
        return 'Normal';
      case DemandLevel.high:
        return 'High';
      case DemandLevel.veryHigh:
        return 'Very High';
    }
  }

  String get colorName {
    switch (this) {
      case DemandLevel.veryLow:
        return 'grey';
      case DemandLevel.low:
        return 'blue';
      case DemandLevel.normal:
        return 'green';
      case DemandLevel.high:
        return 'orange';
      case DemandLevel.veryHigh:
        return 'red';
    }
  }
}

/// Staffing recommendation based on demand forecast.
@freezed
abstract class StaffingRecommendation with _$StaffingRecommendation {
  const factory StaffingRecommendation({
    /// Date of recommendation.
    required DateTime date,

    /// The demand forecast this is based on.
    required DemandForecast forecast,

    /// Current staff capacity (appointments per day).
    required int currentCapacity,

    /// Recommended capacity.
    required int recommendedCapacity,

    /// Recommendation type.
    required StaffingAction action,

    /// Urgency level (1-5, 5 = most urgent).
    required int urgency,

    /// Explanation of the recommendation.
    required String reasoning,

    /// Specific suggestions.
    @Default([]) List<StaffingSuggestion> suggestions,

    /// Expected revenue impact.
    double? revenueImpact,

    /// Confidence in recommendation (0-1).
    required double confidence,
  }) = _StaffingRecommendation;

  const StaffingRecommendation._();

  factory StaffingRecommendation.fromJson(Map<String, dynamic> json) =>
      _$StaffingRecommendationFromJson(json);

  /// Capacity gap (positive = understaffed, negative = overstaffed).
  int get capacityGap => recommendedCapacity - currentCapacity;

  /// Is urgent (urgency >= 4).
  bool get isUrgent => urgency >= 4;

  /// Percentage capacity change needed.
  double get capacityChangePercent =>
      currentCapacity > 0 ? (capacityGap / currentCapacity) * 100 : 0;
}

/// Staffing action recommendation type.
enum StaffingAction {
  /// Add more staff/hours.
  addStaff,

  /// Run a promotion to fill slots.
  runPromotion,

  /// Current staffing is optimal.
  optimal,

  /// Reduce staff/hours.
  reduceStaff,

  /// Consider closing early.
  reduceHours,
}

/// Extension for StaffingAction display.
extension StaffingActionExtension on StaffingAction {
  String get displayName {
    switch (this) {
      case StaffingAction.addStaff:
        return 'Add Staff';
      case StaffingAction.runPromotion:
        return 'Run Promotion';
      case StaffingAction.optimal:
        return 'Optimal';
      case StaffingAction.reduceStaff:
        return 'Reduce Staff';
      case StaffingAction.reduceHours:
        return 'Reduce Hours';
    }
  }

  String get iconName {
    switch (this) {
      case StaffingAction.addStaff:
        return 'person_add';
      case StaffingAction.runPromotion:
        return 'campaign';
      case StaffingAction.optimal:
        return 'check_circle';
      case StaffingAction.reduceStaff:
        return 'person_remove';
      case StaffingAction.reduceHours:
        return 'schedule';
    }
  }
}

/// Specific staffing suggestion.
@freezed
abstract class StaffingSuggestion with _$StaffingSuggestion {
  const factory StaffingSuggestion({
    /// Suggestion type.
    required String type,

    /// Description.
    required String description,

    /// Priority (1-5).
    required int priority,

    /// Estimated impact.
    String? impact,

    /// Action to take.
    String? actionUrl,
  }) = _StaffingSuggestion;

  factory StaffingSuggestion.fromJson(Map<String, dynamic> json) =>
      _$StaffingSuggestionFromJson(json);
}

/// Demand forecast result for a date range.
@freezed
abstract class DemandForecastResult with _$DemandForecastResult {
  const factory DemandForecastResult({
    /// Business ID.
    required String businessId,

    /// Location ID (if specific).
    String? locationId,

    /// Service ID (if specific).
    String? serviceId,

    /// Start date of forecast.
    required DateTime startDate,

    /// End date of forecast.
    required DateTime endDate,

    /// Daily forecasts.
    required List<DemandForecast> forecasts,

    /// Staffing recommendations.
    @Default([]) List<StaffingRecommendation> staffingRecommendations,

    /// When this forecast was generated.
    required DateTime generatedAt,

    /// Model version used.
    String? modelVersion,

    /// Average daily demand in forecast period.
    required double averageDemand,

    /// Peak demand day.
    DemandForecast? peakDay,

    /// Lowest demand day.
    DemandForecast? valleyDay,

    /// Days with high/very high demand.
    @Default([]) List<DemandForecast> highDemandDays,

    /// Days needing attention (urgent staffing).
    @Default([]) List<StaffingRecommendation> urgentDays,
  }) = _DemandForecastResult;

  const DemandForecastResult._();

  factory DemandForecastResult.fromJson(Map<String, dynamic> json) =>
      _$DemandForecastResultFromJson(json);

  /// Number of forecast days.
  int get forecastDays => forecasts.length;

  /// Has any urgent staffing needs.
  bool get hasUrgentNeeds => urgentDays.isNotEmpty;

  /// Total predicted appointments in range.
  double get totalPredicted =>
      forecasts.fold(0.0, (sum, f) => sum + f.predictedCount);
}

/// Request for demand forecast.
@freezed
abstract class DemandForecastRequest with _$DemandForecastRequest {
  const factory DemandForecastRequest({
    /// Business ID.
    required String businessId,

    /// Location ID (optional, for specific location).
    String? locationId,

    /// Service ID (optional, for specific service).
    String? serviceId,

    /// Start date for forecast.
    required DateTime startDate,

    /// Number of days to forecast.
    @Default(30) int forecastDays,

    /// Include staffing recommendations.
    @Default(true) bool includeStaffing,

    /// Current staff capacity per day.
    int? currentCapacity,

    /// Include hourly breakdown.
    @Default(false) bool includeHourly,

    /// Include service breakdown.
    @Default(false) bool includeServiceBreakdown,
  }) = _DemandForecastRequest;

  factory DemandForecastRequest.fromJson(Map<String, dynamic> json) =>
      _$DemandForecastRequestFromJson(json);
}
