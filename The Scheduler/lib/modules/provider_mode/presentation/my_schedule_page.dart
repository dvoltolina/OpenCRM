import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/providers.dart';
import '../../../core/offline/offline_banner.dart';
import '../../../core/ui/components/components.dart';
import '../../../data/models/appointment.dart';
import '../../../data/models/security_context.dart';
import 'widgets/schedule_list_widgets.dart';
import 'widgets/schedule_view_toggle.dart';

/// My Schedule page for Provider Mode.
///
/// Shows provider's appointments with ability to:
/// - Switch between day/week views
/// - Check-in appointments
/// - Complete appointments
/// - Mark no-show
/// - Add staff notes
///
/// Filters appointments by current provider's ID from SecurityContext.
/// Audit logs are handled by AppointmentsRepository.
class MySchedulePage extends ConsumerStatefulWidget {
  const MySchedulePage({super.key});

  @override
  ConsumerState<MySchedulePage> createState() => _MySchedulePageState();
}

class _MySchedulePageState extends ConsumerState<MySchedulePage> {
  DateTime _selectedDate = DateTime.now();
  ScheduleView _viewMode = ScheduleView.day;

  @override
  Widget build(BuildContext context) {
    final securityContext = ref.watch(securityContextProvider).valueOrNull;

    if (securityContext == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedule'),
        actions: [
          const OfflineIndicator(),
          ScheduleViewToggle(
            currentView: _viewMode,
            onViewChanged: (view) {
              setState(() => _viewMode = view);
            },
          ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() => _selectedDate = DateTime.now());
            },
            tooltip: 'Today',
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          _DateNavigator(
            selectedDate: _selectedDate,
            viewMode: _viewMode,
            onDateChanged: (date) {
              setState(() => _selectedDate = date);
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: _ScheduleContent(
              securityContext: securityContext,
              selectedDate: _selectedDate,
              viewMode: _viewMode,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateNavigator extends StatelessWidget {
  const _DateNavigator({
    required this.selectedDate,
    required this.viewMode,
    required this.onDateChanged,
  });

  final DateTime selectedDate;
  final ScheduleView viewMode;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = viewMode == ScheduleView.day
        ? DateFormat('EEEE, MMMM d, y')
        : DateFormat('MMM d - MMM d, y');

    final displayText = viewMode == ScheduleView.day
        ? dateFormat.format(selectedDate)
        : '${dateFormat.format(_getWeekStart(selectedDate))} - ${dateFormat.format(_getWeekEnd(selectedDate))}';

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              final newDate = viewMode == ScheduleView.day
                  ? selectedDate.subtract(const Duration(days: 1))
                  : selectedDate.subtract(const Duration(days: 7));
              onDateChanged(newDate);
            },
          ),
          Expanded(
            child: Text(
              displayText,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              final newDate = viewMode == ScheduleView.day
                  ? selectedDate.add(const Duration(days: 1))
                  : selectedDate.add(const Duration(days: 7));
              onDateChanged(newDate);
            },
          ),
        ],
      ),
    );
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  DateTime _getWeekEnd(DateTime date) {
    final weekday = date.weekday;
    return date.add(Duration(days: 7 - weekday));
  }
}

class _ScheduleContent extends ConsumerWidget {
  const _ScheduleContent({
    required this.securityContext,
    required this.selectedDate,
    required this.viewMode,
  });

  final SecurityContext securityContext;
  final DateTime selectedDate;
  final ScheduleView viewMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsRepo = ref.watch(appointmentsRepositoryProvider);

    // Build date range based on view mode
    final startDate = viewMode == ScheduleView.day
        ? DateTime(selectedDate.year, selectedDate.month, selectedDate.day)
        : _getWeekStart(selectedDate);
    final endDate = viewMode == ScheduleView.day
        ? DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59)
        : _getWeekEnd(selectedDate).add(const Duration(hours: 23, minutes: 59, seconds: 59));

    return StreamBuilder<List<Appointment>>(
      stream: appointmentsRepo.watchAppointmentsInRange(
        context: securityContext,
        start: startDate,
        end: endDate,
        providerId: securityContext.providerId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading appointments: ${snapshot.error}'),
          );
        }

        final appointments = snapshot.data ?? [];

        if (appointments.isEmpty) {
          return EmptySchedule(viewMode: viewMode);
        }

        return viewMode == ScheduleView.day
            ? DayScheduleList(
                appointments: appointments,
                securityContext: securityContext,
              )
            : WeekScheduleList(
                appointments: appointments,
                selectedDate: selectedDate,
                securityContext: securityContext,
              );
      },
    );
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  DateTime _getWeekEnd(DateTime date) {
    final weekday = date.weekday;
    return date.add(Duration(days: 7 - weekday));
  }
}
