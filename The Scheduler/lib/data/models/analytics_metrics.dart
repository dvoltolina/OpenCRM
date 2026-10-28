import 'package:freezed_annotation/freezed_annotation.dart';

import '../converters/timestamp_converters.dart';

part 'analytics_metrics.freezed.dart';
part 'analytics_metrics.g.dart';

/// Comprehensive analytics metrics for reporting dashboard
@freezed
abstract class AnalyticsMetrics with _$AnalyticsMetrics {
  const AnalyticsMetrics._();

  const factory AnalyticsMetrics({
    required String businessId,
    @TimestampConverter() required DateTime startDate,
    @TimestampConverter() required DateTime endDate,

    // Appointment Metrics
    required int totalAppointments,
    required int confirmedAppointments,
    required int canceledAppointments,
    required int completedAppointments,
    required int pendingAppointments,
    required int noShowAppointments,

    // Revenue Metrics (in cents)
    required int totalRevenueCents,
    required int paidRevenueCents,
    required int pendingRevenueCents,
    required int refundedRevenueCents,

    // Client Metrics
    required int totalClients,
    required int newClients,
    required int returningClients,
    required int activeClients,
    required int inactiveClients,

    // Provider Metrics
    required Map<String, int> appointmentsByProvider,
    required Map<String, int> revenueByProvider, // in cents

    // Service Metrics
    required Map<String, int> appointmentsByService,
    required Map<String, int> revenueByService, // in cents

    // Time-based Metrics
    required Map<String, int> appointmentsByDayOfWeek, // Monday: 5, etc
    required Map<int, int> appointmentsByHourOfDay, // 9: 12, 14: 8, etc
    required Map<String, int> appointmentsByDate, // 2025-11-22: 8, etc

    // Performance Metrics
    required double averageBookingLeadDays,
    required double cancellationRate,
    required double noShowRate,
    required double utilizationRate,

    // Group Session Metrics
    @Default(0) int totalGroupSessions,
    @Default(0) int totalGroupSessionAttendees,
    @Default(0) int totalGroupSessionCapacity,
    @Default(0.0) double groupSessionUtilizationRate,
    @Default({}) Map<String, int> groupSessionsByService,
    @Default({}) Map<String, int> attendeesByGroupSession,
  }) = _AnalyticsMetrics;

  factory AnalyticsMetrics.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsMetricsFromJson(json);

  /// Empty metrics for initialization
  factory AnalyticsMetrics.empty({
    required String businessId,
    required DateTime startDate,
    required DateTime endDate,
  }) =>
      AnalyticsMetrics(
        businessId: businessId,
        startDate: startDate,
        endDate: endDate,
        totalAppointments: 0,
        confirmedAppointments: 0,
        canceledAppointments: 0,
        completedAppointments: 0,
        pendingAppointments: 0,
        noShowAppointments: 0,
        totalRevenueCents: 0,
        paidRevenueCents: 0,
        pendingRevenueCents: 0,
        refundedRevenueCents: 0,
        totalClients: 0,
        newClients: 0,
        returningClients: 0,
        activeClients: 0,
        inactiveClients: 0,
        appointmentsByProvider: const {},
        revenueByProvider: const {},
        appointmentsByService: const {},
        revenueByService: const {},
        appointmentsByDayOfWeek: const {},
        appointmentsByHourOfDay: const {},
        appointmentsByDate: const {},
        averageBookingLeadDays: 0.0,
        cancellationRate: 0.0,
        noShowRate: 0.0,
        utilizationRate: 0.0,
      );

  /// Total revenue in dollars
  double get totalRevenueDollars => totalRevenueCents / 100.0;

  /// Paid revenue in dollars
  double get paidRevenueDollars => paidRevenueCents / 100.0;

  /// Pending revenue in dollars
  double get pendingRevenueDollars => pendingRevenueCents / 100.0;

  /// Average revenue per appointment (in dollars)
  double get averageRevenuePerAppointment {
    if (totalAppointments == 0) return 0.0;
    return totalRevenueDollars / totalAppointments;
  }

  /// Client retention rate (returning / total)
  double get clientRetentionRate {
    if (totalClients == 0) return 0.0;
    return returningClients / totalClients;
  }

  /// Completion rate (completed / total)
  double get completionRate {
    if (totalAppointments == 0) return 0.0;
    return completedAppointments / totalAppointments;
  }

  /// Top performing provider by appointments
  String? get topProviderByAppointments {
    if (appointmentsByProvider.isEmpty) return null;
    return appointmentsByProvider.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Top performing service by appointments
  String? get topServiceByAppointments {
    if (appointmentsByService.isEmpty) return null;
    return appointmentsByService.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Busiest day of week
  String? get busiestDayOfWeek {
    if (appointmentsByDayOfWeek.isEmpty) return null;
    return appointmentsByDayOfWeek.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Peak hour of day (24-hour format)
  int? get peakHourOfDay {
    if (appointmentsByHourOfDay.isEmpty) return null;
    return appointmentsByHourOfDay.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Average attendees per group session
  double get averageAttendeesPerGroupSession {
    if (totalGroupSessions == 0) return 0.0;
    return totalGroupSessionAttendees / totalGroupSessions;
  }

  /// Average capacity per group session
  double get averageCapacityPerGroupSession {
    if (totalGroupSessions == 0) return 0.0;
    return totalGroupSessionCapacity / totalGroupSessions;
  }

  /// Top group session service by attendance
  String? get topGroupSessionService {
    if (groupSessionsByService.isEmpty) return null;
    return groupSessionsByService.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}

/// Date range filter for reports
@freezed
abstract class DateRangeFilter with _$DateRangeFilter {
  const factory DateRangeFilter({
    @TimestampConverter() required DateTime startDate,
    @TimestampConverter() required DateTime endDate,
    required DateRangePeriod period,
  }) = _DateRangeFilter;

  factory DateRangeFilter.fromJson(Map<String, dynamic> json) =>
      _$DateRangeFilterFromJson(json);
}

/// Predefined date range periods
enum DateRangePeriod {
  today,
  yesterday,
  last7Days,
  last30Days,
  thisMonth,
  lastMonth,
  thisQuarter,
  lastQuarter,
  thisYear,
  lastYear,
  custom,
}

extension DateRangePeriodX on DateRangePeriod {
  String get displayName {
    switch (this) {
      case DateRangePeriod.today:
        return 'Today';
      case DateRangePeriod.yesterday:
        return 'Yesterday';
      case DateRangePeriod.last7Days:
        return 'Last 7 Days';
      case DateRangePeriod.last30Days:
        return 'Last 30 Days';
      case DateRangePeriod.thisMonth:
        return 'This Month';
      case DateRangePeriod.lastMonth:
        return 'Last Month';
      case DateRangePeriod.thisQuarter:
        return 'This Quarter';
      case DateRangePeriod.lastQuarter:
        return 'Last Quarter';
      case DateRangePeriod.thisYear:
        return 'This Year';
      case DateRangePeriod.lastYear:
        return 'Last Year';
      case DateRangePeriod.custom:
        return 'Custom Range';
    }
  }

  DateRangeFilter toDateRange() {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    switch (this) {
      case DateRangePeriod.today:
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case DateRangePeriod.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        start = DateTime(yesterday.year, yesterday.month, yesterday.day);
        end = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
        break;
      case DateRangePeriod.last7Days:
        start = now.subtract(const Duration(days: 7));
        end = now;
        break;
      case DateRangePeriod.last30Days:
        start = now.subtract(const Duration(days: 30));
        end = now;
        break;
      case DateRangePeriod.thisMonth:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case DateRangePeriod.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1);
        start = DateTime(lastMonth.year, lastMonth.month, 1);
        end = DateTime(lastMonth.year, lastMonth.month + 1, 0, 23, 59, 59);
        break;
      case DateRangePeriod.thisQuarter:
        final quarter = ((now.month - 1) / 3).floor();
        start = DateTime(now.year, quarter * 3 + 1, 1);
        end = DateTime(now.year, quarter * 3 + 4, 0, 23, 59, 59);
        break;
      case DateRangePeriod.lastQuarter:
        final quarter = ((now.month - 1) / 3).floor() - 1;
        final year = quarter < 0 ? now.year - 1 : now.year;
        final adjustedQuarter = quarter < 0 ? 3 : quarter;
        start = DateTime(year, adjustedQuarter * 3 + 1, 1);
        end = DateTime(year, adjustedQuarter * 3 + 4, 0, 23, 59, 59);
        break;
      case DateRangePeriod.thisYear:
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case DateRangePeriod.lastYear:
        start = DateTime(now.year - 1, 1, 1);
        end = DateTime(now.year - 1, 12, 31, 23, 59, 59);
        break;
      case DateRangePeriod.custom:
        // Return today as default for custom
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
    }

    return DateRangeFilter(
      startDate: start,
      endDate: end,
      period: this,
    );
  }
}
