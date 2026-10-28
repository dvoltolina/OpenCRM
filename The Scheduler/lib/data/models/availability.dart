import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';

import '../converters/timestamp_converters.dart';

part 'availability.freezed.dart';
part 'availability.g.dart';

/// Day of week for recurring availability
enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  String get displayName {
    switch (this) {
      case DayOfWeek.monday:
        return 'Monday';
      case DayOfWeek.tuesday:
        return 'Tuesday';
      case DayOfWeek.wednesday:
        return 'Wednesday';
      case DayOfWeek.thursday:
        return 'Thursday';
      case DayOfWeek.friday:
        return 'Friday';
      case DayOfWeek.saturday:
        return 'Saturday';
      case DayOfWeek.sunday:
        return 'Sunday';
    }
  }

  String get shortName => displayName.substring(0, 3);

  /// Convert DateTime.weekday (1=Monday, 7=Sunday) to DayOfWeek
  static DayOfWeek fromDateTime(DateTime date) {
    return DayOfWeek.values[date.weekday - 1];
  }

  /// Get DateTime.weekday value (1=Monday, 7=Sunday)
  int get weekdayValue => index + 1;
}

/// Type of availability block
enum AvailabilityType {
  available, // Provider is available for booking
  blocked, // Time is blocked off (vacation, break, etc)
  override; // Override for a specific date

  String get displayName {
    switch (this) {
      case AvailabilityType.available:
        return 'Available';
      case AvailabilityType.blocked:
        return 'Blocked';
      case AvailabilityType.override:
        return 'Override';
    }
  }
}

/// Time block within a day (hours and minutes only)
final DateFormat _timeFormatter = DateFormat('h:mm a');

@freezed
abstract class TimeBlock with _$TimeBlock {
  const TimeBlock._();

  const factory TimeBlock({
    required int startHour, // 0-23
    required int startMinute, // 0-59
    required int endHour, // 0-23
    required int endMinute, // 0-59
  }) = _TimeBlock;

  factory TimeBlock.fromJson(Map<String, dynamic> json) =>
      _$TimeBlockFromJson(json);

  /// Create TimeBlock from DateTime objects (ignores date portion)
  factory TimeBlock.fromDateTimes(DateTime start, DateTime end) {
    return TimeBlock(
      startHour: start.hour,
      startMinute: start.minute,
      endHour: end.hour,
      endMinute: end.minute,
    );
  }

  /// Create TimeBlock from time strings in format "HH:mm"
  factory TimeBlock.fromStrings(String startTime, String endTime) {
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');
    return TimeBlock(
      startHour: int.parse(startParts[0]),
      startMinute: int.parse(startParts[1]),
      endHour: int.parse(endParts[0]),
      endMinute: int.parse(endParts[1]),
    );
  }

  /// Convert to DateTime on a specific date
  DateTime toStartDateTime(DateTime date) {
    return DateTime(date.year, date.month, date.day, startHour, startMinute);
  }

  DateTime toEndDateTime(DateTime date) {
    return DateTime(date.year, date.month, date.day, endHour, endMinute);
  }

  /// Format as "HH:mm - HH:mm"
  String get displayTime {
    return '${_formatTime(startHour, startMinute)} - ${_formatTime(endHour, endMinute)}';
  }

  String _formatTime(int hour, int minute) {
    final reference = DateTime(0, 1, 1, hour, minute);
    return _timeFormatter.format(reference);
  }

  /// Duration in minutes
  int get durationMinutes {
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;
    return endMinutes - startMinutes;
  }
}

/// Recurring weekly availability schedule for a provider
@freezed
abstract class WeeklySchedule with _$WeeklySchedule {
  const factory WeeklySchedule({
    required String id,
    required String providerId,
    required String locationId,
    required DayOfWeek dayOfWeek,
    required List<TimeBlock> timeBlocks,
    @Default(true) bool isActive,
    @TimestampConverter() required DateTime createdAt,
    @NullableTimestampConverter() DateTime? updatedAt,
  }) = _WeeklySchedule;

  factory WeeklySchedule.fromJson(Map<String, dynamic> json) =>
      _$WeeklyScheduleFromJson(json);
}

/// Availability entity representing when a provider is available at a location.
/// Can be one-time (specific date) or recurring (weekly pattern).
/// Multi-tenant: enforced via provider.businessId relationship.
@freezed
abstract class Availability with _$Availability {
  const Availability._();

  const factory Availability({
    required String id,
    required String providerId,
    required String locationId,
    @TimestampConverter() required DateTime startTime,
    @TimestampConverter() required DateTime endTime,
    required AvailabilityType type,
    String? reason, // Optional reason for blocked time
    bool? isRecurring, // Deprecated - use WeeklySchedule instead
    @NullableTimestampConverter()
    DateTime? specificDate, // If set, only applies to this date (override)
    @TimestampConverter() required DateTime createdAt,
    @NullableTimestampConverter() DateTime? updatedAt,
  }) = _Availability;

  factory Availability.fromJson(Map<String, dynamic> json) =>
      _$AvailabilityFromJson(json);

  /// Create a one-time availability block
  factory Availability.oneTime({
    required String id,
    required String providerId,
    required String locationId,
    required DateTime startTime,
    required DateTime endTime,
    AvailabilityType type = AvailabilityType.available,
    String? reason,
  }) {
    return Availability(
      id: id,
      providerId: providerId,
      locationId: locationId,
      startTime: startTime,
      endTime: endTime,
      type: type,
      reason: reason,
      specificDate: DateTime(startTime.year, startTime.month, startTime.day),
      createdAt: DateTime.now(),
    );
  }

  /// Create a blocked time (vacation, break, etc)
  factory Availability.blocked({
    required String id,
    required String providerId,
    required String locationId,
    required DateTime startTime,
    required DateTime endTime,
    String? reason,
  }) {
    return Availability.oneTime(
      id: id,
      providerId: providerId,
      locationId: locationId,
      startTime: startTime,
      endTime: endTime,
      type: AvailabilityType.blocked,
      reason: reason,
    );
  }

  /// Check if this availability is on a specific date
  bool isOnDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startDateOnly =
        DateTime(startTime.year, startTime.month, startTime.day);
    return startDateOnly == dateOnly;
  }

  /// Get duration in minutes
  int get durationMinutes {
    return endTime.difference(startTime).inMinutes;
  }

  /// Display string for the time range
  String get timeDisplay {
    return '${_timeFormatter.format(startTime)} - ${_timeFormatter.format(endTime)}';
  }
}
