import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:the_scheduler/core/ui/ui_exports.dart';
import 'package:the_scheduler/core/ui/components/components.dart' hide EmptyStateWidget;
import 'package:the_scheduler/core/utils/secure_error_handler.dart';
import 'package:the_scheduler/data/models/appointment.dart';

/// Premium calendar grid with warm stone background and sophisticated styling
/// Updated by Agent S1 (2025-11-30) - Modern Sophisticated Blue design system
class CalendarGrid extends StatelessWidget {
  const CalendarGrid({
    super.key,
    required this.appointmentsAsync,
    required this.calendarFormat,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onFormatChanged,
    required this.onPageChanged,
    required this.getEventsForDay,
    required this.primaryColor,
    required this.accentColor,
    required this.isDarkMode,
  });

  final AsyncValue<List<Appointment>> appointmentsAsync;
  final CalendarFormat calendarFormat;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final void Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final ValueChanged<CalendarFormat> onFormatChanged;
  final ValueChanged<DateTime> onPageChanged;
  final List<Appointment> Function(DateTime day, List<Appointment> allAppointments) getEventsForDay;
  final Color primaryColor;
  final Color accentColor;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return appointmentsAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.md,
        ),
        child: LoadingSkeleton(
          child: Container(
            height: 300,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? theme.colorScheme.surfaceContainerHigh
                  : theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
          ),
        ),
      ),
      error: (error, stackTrace) => Padding(
        padding: AppSpacing.pagePadding,
        child: const ErrorFeedback(
          message: SecureErrorHandler.loadingFailed,
        ),
      ),
      data: (appointments) => Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surfaceContainerHigh
              : theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? theme.colorScheme.outlineVariant.withValues(alpha: 0.3)
                : primaryColor.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.03),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: TableCalendar(
          firstDay: DateTime.now().subtract(const Duration(days: 365)),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: focusedDay,
          calendarFormat: calendarFormat,
          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
          eventLoader: (day) => getEventsForDay(day, appointments),
          availableCalendarFormats: const {
            CalendarFormat.week: 'Week',
            CalendarFormat.twoWeeks: '2 Weeks',
            CalendarFormat.month: 'Month',
          },
          onDaySelected: (selectedDay, updatedFocus) => onDaySelected(selectedDay, updatedFocus),
          onFormatChanged: (format) {
            if (calendarFormat != format) {
              onFormatChanged(format);
            }
          },
          onPageChanged: onPageChanged,
          headerVisible: false,
          daysOfWeekHeight: 36,
          rowHeight: 52,
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            cellMargin: const EdgeInsets.all(5),
            todayDecoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor.withValues(alpha: 0.15),
                  accentColor.withValues(alpha: 0.25),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: accentColor,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            todayTextStyle: theme.textTheme.bodyLarge!.copyWith(
              color: isDark
                  ? Colors.white
                  : accentColor,
              fontWeight: FontWeight.w700,
            ),
            selectedDecoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withValues(alpha: 0.9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            selectedTextStyle: theme.textTheme.bodyLarge!.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            defaultDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            weekendDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            markerDecoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.3),
                  blurRadius: 2,
                ),
              ],
            ),
            markerSize: 6,
            markersMaxCount: 3,
            markersAlignment: Alignment.bottomCenter,
            markerMargin: const EdgeInsets.symmetric(horizontal: 1.5),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: theme.textTheme.bodySmall!.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark
                  ? theme.colorScheme.onSurfaceVariant
                  : primaryColor.withValues(alpha: 0.7),
              letterSpacing: 0.5,
            ),
            weekendStyle: theme.textTheme.bodySmall!.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark
                  ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)
                  : primaryColor.withValues(alpha: 0.5),
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
