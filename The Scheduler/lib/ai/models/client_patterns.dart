import 'package:freezed_annotation/freezed_annotation.dart';

part 'client_patterns.freezed.dart';
part 'client_patterns.g.dart';

/// Historical booking patterns for a client.
///
/// Extracted from appointment history to inform slot suggestions
/// and predict no-show risk for specific time slots.
///
/// Agent AI-20: Smart Scheduling Suggestions
@freezed
abstract class ClientPatterns with _$ClientPatterns {
  const ClientPatterns._();

  const factory ClientPatterns({
    /// Client ID these patterns belong to
    required String clientId,

    /// Business ID for multi-tenant isolation
    required String businessId,

    /// No-show rate by day of week (1=Monday, 7=Sunday)
    /// Key: day number, Value: no-show rate (0.0-1.0)
    required Map<int, double> dayOfWeekNoshowRates,

    /// No-show rate by hour of day (0-23)
    /// Key: hour, Value: no-show rate (0.0-1.0)
    required Map<int, double> hourOfDayNoshowRates,

    /// No-show rate by provider ID
    /// Key: provider ID, Value: no-show rate (0.0-1.0)
    required Map<String, double> providerNoshowRates,

    /// Completed appointment count by provider
    /// Key: provider ID, Value: completed count
    required Map<String, int> providerCompletedCounts,

    /// No-show rate by booking lead time bucket
    /// Key: bucket name ("same_day", "1-3_days", "4-7_days", "8-14_days", "15+_days")
    /// Value: no-show rate (0.0-1.0)
    required Map<String, double> leadTimeNoshowRates,

    /// Overall statistics
    required int totalAppointments,
    required int totalNoshows,
    required int totalCancellations,
    required double overallNoshowRate,

    /// Preferred booking patterns (derived from successful appointments)
    @Default([]) List<int> preferredDaysOfWeek,
    @Default([]) List<int> preferredHours,
    @Default([]) List<String> preferredProviders,

    /// When these patterns were last calculated
    required DateTime calculatedAt,

    /// How many appointments were used to calculate these patterns
    required int sampleSize,
  }) = _ClientPatterns;

  factory ClientPatterns.fromJson(Map<String, dynamic> json) =>
      _$ClientPatternsFromJson(json);

  /// Create empty patterns for a new client.
  factory ClientPatterns.empty({
    required String clientId,
    required String businessId,
  }) =>
      ClientPatterns(
        clientId: clientId,
        businessId: businessId,
        dayOfWeekNoshowRates: const {},
        hourOfDayNoshowRates: const {},
        providerNoshowRates: const {},
        providerCompletedCounts: const {},
        leadTimeNoshowRates: const {},
        totalAppointments: 0,
        totalNoshows: 0,
        totalCancellations: 0,
        overallNoshowRate: 0.0,
        calculatedAt: DateTime.now(),
        sampleSize: 0,
      );

  /// Check if we have enough data for reliable patterns.
  bool get hasReliableData => sampleSize >= 5;

  /// Get no-show rate for a specific day of week.
  /// Returns overall rate if no day-specific data.
  double getNoshowRateForDay(int dayOfWeek) {
    return dayOfWeekNoshowRates[dayOfWeek] ?? overallNoshowRate;
  }

  /// Get no-show rate for a specific hour.
  /// Returns overall rate if no hour-specific data.
  double getNoshowRateForHour(int hour) {
    return hourOfDayNoshowRates[hour] ?? overallNoshowRate;
  }

  /// Get no-show rate for a specific provider.
  /// Returns overall rate if no provider-specific data.
  double getNoshowRateForProvider(String providerId) {
    return providerNoshowRates[providerId] ?? overallNoshowRate;
  }

  /// Get completed appointment count with a provider.
  int getCompletedCountForProvider(String providerId) {
    return providerCompletedCounts[providerId] ?? 0;
  }

  /// Get no-show rate for a booking lead time (in days).
  double getNoshowRateForLeadTime(int leadDays) {
    final bucket = _getLeadTimeBucket(leadDays);
    return leadTimeNoshowRates[bucket] ?? overallNoshowRate;
  }

  /// Get the best day of week for this client (lowest no-show rate).
  int? get bestDayOfWeek {
    if (dayOfWeekNoshowRates.isEmpty) return null;
    return dayOfWeekNoshowRates.entries
        .reduce((a, b) => a.value < b.value ? a : b)
        .key;
  }

  /// Get the worst day of week for this client (highest no-show rate).
  int? get worstDayOfWeek {
    if (dayOfWeekNoshowRates.isEmpty) return null;
    return dayOfWeekNoshowRates.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Get the best hour for this client (lowest no-show rate).
  int? get bestHour {
    if (hourOfDayNoshowRates.isEmpty) return null;
    return hourOfDayNoshowRates.entries
        .reduce((a, b) => a.value < b.value ? a : b)
        .key;
  }

  /// Get the best provider for this client (lowest no-show rate with history).
  String? get bestProvider {
    if (providerNoshowRates.isEmpty) return null;
    // Only consider providers with at least 2 appointments
    final eligibleProviders = providerNoshowRates.entries
        .where((e) => (providerCompletedCounts[e.key] ?? 0) >= 2)
        .toList();
    if (eligibleProviders.isEmpty) return null;
    return eligibleProviders.reduce((a, b) => a.value < b.value ? a : b).key;
  }

  String _getLeadTimeBucket(int leadDays) {
    if (leadDays == 0) return 'same_day';
    if (leadDays <= 3) return '1-3_days';
    if (leadDays <= 7) return '4-7_days';
    if (leadDays <= 14) return '8-14_days';
    return '15+_days';
  }
}

/// Day of week statistics for pattern analysis.
@freezed
abstract class DayOfWeekStats with _$DayOfWeekStats {
  const factory DayOfWeekStats({
    required int dayOfWeek,
    required String dayName,
    required int appointmentCount,
    required int noshowCount,
    required double noshowRate,
    required bool isPreferred,
  }) = _DayOfWeekStats;

  factory DayOfWeekStats.fromJson(Map<String, dynamic> json) =>
      _$DayOfWeekStatsFromJson(json);
}

/// Hour of day statistics for pattern analysis.
@freezed
abstract class HourOfDayStats with _$HourOfDayStats {
  const factory HourOfDayStats({
    required int hour,
    required String timeLabel,
    required int appointmentCount,
    required int noshowCount,
    required double noshowRate,
    required bool isPreferred,
  }) = _HourOfDayStats;

  factory HourOfDayStats.fromJson(Map<String, dynamic> json) =>
      _$HourOfDayStatsFromJson(json);
}

/// Provider history with a specific client.
@freezed
abstract class ProviderClientHistory with _$ProviderClientHistory {
  const ProviderClientHistory._();

  const factory ProviderClientHistory({
    required String providerId,
    required String providerName,
    required int completedAppointments,
    required int noshowCount,
    required int cancellationCount,
    required double noshowRate,
    required double satisfactionScore,
    DateTime? lastAppointment,
  }) = _ProviderClientHistory;

  factory ProviderClientHistory.fromJson(Map<String, dynamic> json) =>
      _$ProviderClientHistoryFromJson(json);

  /// Check if this is a strong relationship (many successful appointments).
  bool get isStrongRelationship => completedAppointments >= 5 && noshowRate < 0.15;

  /// Check if this provider should be recommended.
  bool get shouldRecommend => completedAppointments >= 2 && noshowRate < 0.25;
}
