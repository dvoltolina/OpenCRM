import 'package:freezed_annotation/freezed_annotation.dart';

part 'business_stats.freezed.dart';
part 'business_stats.g.dart';

/// Business statistics for admin dashboard.
/// Provides high-level overview of business health and performance.
@freezed
abstract class BusinessStats with _$BusinessStats {
  const factory BusinessStats({
    /// Number of appointments scheduled for today
    required int appointmentsToday,

    /// Change in appointments compared to same day last week
    required int appointmentsChange,

    /// Revenue earned today (in cents)
    required int revenueTodayCents,

    /// Percentage change in revenue compared to same day last week
    required double revenueChangePercent,

    /// Number of staff members currently on duty (clocked in)
    required int staffOnDuty,

    /// Total number of active staff members
    required int staffTotal,

    /// Number of completed appointments today
    @Default(0) int appointmentsCompleted,

    /// Number of cancelled appointments today
    @Default(0) int appointmentsCancelled,

    /// Number of no-show appointments today
    @Default(0) int appointmentsNoShow,
  }) = _BusinessStats;

  factory BusinessStats.fromJson(Map<String, dynamic> json) =>
      _$BusinessStatsFromJson(json);

  const BusinessStats._();

  /// Revenue in dollars
  double get revenueTodayDollars => revenueTodayCents / 100.0;

  /// Format revenue as currency string
  String get revenueTodayFormatted => '\$${revenueTodayDollars.toStringAsFixed(2)}';

  /// Get trend indicator for appointments
  String get appointmentsTrend {
    if (appointmentsChange > 0) return '📈 +$appointmentsChange';
    if (appointmentsChange < 0) return '📉 $appointmentsChange';
    return '━ 0';
  }

  /// Get trend indicator for revenue
  String get revenueTrend {
    if (revenueChangePercent > 0) {
      return '📈 +${revenueChangePercent.toStringAsFixed(1)}%';
    }
    if (revenueChangePercent < 0) {
      return '📉 ${revenueChangePercent.toStringAsFixed(1)}%';
    }
    return '━ 0%';
  }
}
