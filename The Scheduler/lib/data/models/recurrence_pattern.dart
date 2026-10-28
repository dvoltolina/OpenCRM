import 'package:freezed_annotation/freezed_annotation.dart';

import '../converters/timestamp_converters.dart';

part 'recurrence_pattern.freezed.dart';
part 'recurrence_pattern.g.dart';

/// Recurrence frequency options
enum RecurrenceFrequency {
  daily,
  weekly,
  biweekly,
  monthly,
  custom,
}

/// Recurrence end condition type
enum RecurrenceEndType {
  never, // Indefinite recurrence
  afterOccurrences, // End after N occurrences
  onDate, // End on specific date
}

/// Days of week for weekly recurrence patterns
enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}

/// RecurrencePattern defines how appointments repeat over time.
/// Used for therapy sessions, regular checkups, and other repeated bookings.
@freezed
abstract class RecurrencePattern with _$RecurrencePattern {
  const factory RecurrencePattern({
    /// Unique identifier for this recurrence pattern
    required String id,

    /// How often the appointment recurs
    required RecurrenceFrequency frequency,

    /// For weekly/biweekly: which days of the week
    /// For monthly: which day of month (stored as int in customInterval)
    @Default([]) List<DayOfWeek> daysOfWeek,

    /// Custom interval (e.g., every 3 days, every 2 weeks)
    /// Only used when frequency is 'custom'
    int? customInterval,

    /// Custom interval unit (days, weeks, months) for custom frequency
    String? customIntervalUnit,

    /// How the recurrence ends
    required RecurrenceEndType endType,

    /// Number of occurrences before stopping (used if endType is afterOccurrences)
    int? numberOfOccurrences,

    /// End date for recurrence (used if endType is onDate)
    @NullableTimestampConverter() DateTime? endDate,

    /// Dates to exclude from recurrence (holidays, provider time off)
    @TimestampListConverter() @Default([]) List<DateTime> exclusionDates,

    /// Whether this pattern is currently active
    @Default(true) bool isActive,

    /// When this pattern was created
    @TimestampConverter() required DateTime createdAt,

    /// When this pattern was last modified
    @NullableTimestampConverter() DateTime? updatedAt,
  }) = _RecurrencePattern;

  factory RecurrencePattern.fromJson(Map<String, dynamic> json) =>
      _$RecurrencePatternFromJson(json);
}

/// Extension methods for RecurrencePattern
extension RecurrencePatternExtensions on RecurrencePattern {
  /// Gets a human-readable description of the recurrence pattern
  String get description {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return 'Daily';
      case RecurrenceFrequency.weekly:
        if (daysOfWeek.isEmpty) return 'Weekly';
        final dayNames = daysOfWeek.map((d) => _dayName(d)).join(', ');
        return 'Every $dayNames';
      case RecurrenceFrequency.biweekly:
        if (daysOfWeek.isEmpty) return 'Every 2 weeks';
        final dayNames = daysOfWeek.map((d) => _dayName(d)).join(', ');
        return 'Every 2 weeks on $dayNames';
      case RecurrenceFrequency.monthly:
        return 'Monthly';
      case RecurrenceFrequency.custom:
        if (customInterval != null && customIntervalUnit != null) {
          return 'Every $customInterval $customIntervalUnit';
        }
        return 'Custom schedule';
    }
  }

  /// Gets the end condition description
  String get endDescription {
    switch (endType) {
      case RecurrenceEndType.never:
        return 'No end date';
      case RecurrenceEndType.afterOccurrences:
        if (numberOfOccurrences != null) {
          return 'After $numberOfOccurrences occurrences';
        }
        return 'Limited occurrences';
      case RecurrenceEndType.onDate:
        if (endDate != null) {
          return 'Until ${endDate!.year}-${endDate!.month}-${endDate!.day}';
        }
        return 'End date set';
    }
  }

  String _dayName(DayOfWeek day) {
    switch (day) {
      case DayOfWeek.monday:
        return 'Mon';
      case DayOfWeek.tuesday:
        return 'Tue';
      case DayOfWeek.wednesday:
        return 'Wed';
      case DayOfWeek.thursday:
        return 'Thu';
      case DayOfWeek.friday:
        return 'Fri';
      case DayOfWeek.saturday:
        return 'Sat';
      case DayOfWeek.sunday:
        return 'Sun';
    }
  }

  /// Checks if a specific date is excluded from recurrence
  bool isDateExcluded(DateTime date) {
    return exclusionDates.any((excluded) =>
        excluded.year == date.year &&
        excluded.month == date.month &&
        excluded.day == date.day);
  }

  /// Gets the maximum number of future occurrences to generate
  /// (defaults to 52 weeks/1 year if no limit specified)
  int get maxOccurrences {
    if (endType == RecurrenceEndType.afterOccurrences &&
        numberOfOccurrences != null) {
      return numberOfOccurrences!;
    }
    // Default maximum to prevent infinite generation
    return 52;
  }
}
