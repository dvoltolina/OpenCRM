import 'package:intl/intl.dart';

/// Centralized date and time formatters for consistent formatting across the app.
///
/// Usage:
/// ```dart
/// import 'package:the_scheduler/core/utils/date_formatters.dart';
///
/// final formatted = AppDateFormatters.dateShort.format(DateTime.now());
/// ```
///
/// Benefits:
/// - Consistent date/time display throughout the app
/// - Single point of change for localization
/// - Reduces code duplication
/// - Prevents format string typos
class AppDateFormatters {
  AppDateFormatters._(); // Private constructor - use static formatters

  // ============================================================
  // Time Formatters
  // ============================================================

  /// 12-hour time: "3:30 PM"
  static final time12Hour = DateFormat('h:mm a');

  /// 24-hour time: "15:30"
  static final time24Hour = DateFormat('HH:mm');

  /// Time range display: "3:30 PM - 4:30 PM"
  static String timeRange(DateTime start, DateTime end) {
    return '${time12Hour.format(start)} - ${time12Hour.format(end)}';
  }

  // ============================================================
  // Date Formatters
  // ============================================================

  /// Short date: "Nov 26, 2025"
  static final dateShort = DateFormat('MMM d, yyyy');

  /// Medium date: "Nov 26, y"
  static final dateMedium = DateFormat('MMM d, y');

  /// Long date: "November 26, 2025"
  static final dateLong = DateFormat('MMMM d, yyyy');

  /// Full date with day of week: "Wednesday, November 26, 2025"
  static final dateFull = DateFormat('EEEE, MMMM d, y');

  /// Day and short month: "Wednesday, Nov 26"
  static final dateDayMonth = DateFormat('EEEE, MMM d');

  /// ISO date for filenames/APIs: "2025-11-26"
  static final dateIso = DateFormat('yyyy-MM-dd');

  /// Day of month only: "26"
  static final dayOfMonth = DateFormat('d');

  /// Month and day: "Nov 26"
  static final monthDay = DateFormat('MMM d');

  /// Day of week: "Wednesday"
  static final dayOfWeek = DateFormat('EEEE');

  /// Short day of week: "Wed"
  static final dayOfWeekShort = DateFormat('E');

  // ============================================================
  // Combined Date-Time Formatters
  // ============================================================

  /// Date and time: "Nov 26, 2025 3:30 PM"
  static final dateTime = DateFormat('MMM d, yyyy h:mm a');

  /// Date and time with separator: "Nov 26, 2025 • 3:30 PM"
  static String dateTimeSeparated(DateTime dateTime) {
    return '${dateShort.format(dateTime)} • ${time12Hour.format(dateTime)}';
  }

  /// Full date and time: "Wednesday, November 26, 2025 at 3:30 PM"
  static String dateTimeFull(DateTime dateTime) {
    return '${dateFull.format(dateTime)} at ${time12Hour.format(dateTime)}';
  }

  /// Medium date and time: "Nov 26, y - 3:30 PM"
  static final dateTimeMedium = DateFormat('MMM d, y - h:mm a');

  // ============================================================
  // Special Formats
  // ============================================================

  /// iCalendar format: "20251126T153000Z"
  static final iCalendar = DateFormat("yyyyMMdd'T'HHmmss'Z'");

  /// Timestamp for filenames: "2025-11-26_153000"
  static String filenameTimestamp(DateTime dateTime) {
    return '${dateIso.format(dateTime)}_${DateFormat('HHmmss').format(dateTime)}';
  }

  /// Relative date description (Today, Yesterday, or formatted date)
  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (dateOnly == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else {
      return dateShort.format(date);
    }
  }

  /// Date range: "Nov 26 - Nov 30" or "Nov 26 - Dec 2"
  static String dateRange(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month) {
      // Same month: "Nov 26 - 30"
      return '${monthDay.format(start)} - ${dayOfMonth.format(end)}';
    } else {
      // Different months: "Nov 26 - Dec 2"
      return '${monthDay.format(start)} - ${monthDay.format(end)}';
    }
  }
}
