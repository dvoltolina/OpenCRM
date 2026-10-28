import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:the_scheduler/core/providers/providers.dart';
import 'package:the_scheduler/core/ui/ui_exports.dart';
import 'package:the_scheduler/core/ui/components/components.dart' hide EmptyStateWidget;
import 'package:the_scheduler/core/utils/secure_error_handler.dart';
import 'package:the_scheduler/data/models/appointment.dart';
import 'package:the_scheduler/data/models/provider.dart' as provider_model;
import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/data/models/service.dart';
import 'package:the_scheduler/data/models/location.dart';
import 'package:the_scheduler/modules/booking/presentation/booking_page.dart';
import 'widgets/calendar_grid.dart';
import 'widgets/calendar_header.dart';
import 'widgets/calendar_provider_filter.dart';
import 'widgets/day_appointments_section.dart';
import 'widgets/staff_appointment_detail_sheet.dart';

/// Calendar page showing appointments in day/week/month views with color coding
/// Updated by Agent S1 (2025-11-30) - Modern Sophisticated Blue design system
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedProviderId; // null means "All Providers"

  // Cached services and locations for appointment details
  List<Service> _services = [];
  List<Location> _locations = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  Future<void> _refresh() async {
    if (mounted) {
      setState(() {});
    }
  }

  void _goToToday() {
    setState(() {
      _focusedDay = DateTime.now();
      _selectedDay = DateTime.now();
    });
  }

  void _cycleCalendarFormat() {
    setState(() {
      switch (_calendarFormat) {
        case CalendarFormat.week:
          _calendarFormat = CalendarFormat.twoWeeks;
          break;
        case CalendarFormat.twoWeeks:
          _calendarFormat = CalendarFormat.month;
          break;
        case CalendarFormat.month:
          _calendarFormat = CalendarFormat.week;
          break;
      }
    });
  }

  String get _formatLabel {
    switch (_calendarFormat) {
      case CalendarFormat.week:
        return 'Week';
      case CalendarFormat.twoWeeks:
        return '2 Weeks';
      case CalendarFormat.month:
        return 'Month';
    }
  }

  void _addAppointment(BuildContext context, SecurityContext securityContext) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BookingPage(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = ref.watch(appConfigProvider);
    final isDark = theme.brightness == Brightness.dark;
    final securityContextAsync = ref.watch(securityContextProvider);

    return securityContextAsync.when(
      loading: () => Scaffold(
        backgroundColor: isDark
            ? theme.scaffoldBackgroundColor
            : theme.colorScheme.surfaceContainerLowest,
        body: SafeArea(
          child: Padding(
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonCard(height: 80),
                VSpace.md,
                const SkeletonCalendarCell(),
                VSpace.md,
                Expanded(
                  child: buildSkeletonList(count: 3, hasAvatar: true),
                ),
              ],
            ),
          ),
        ),
      ),
      error: (error, stackTrace) => const Scaffold(
        body: Center(child: Text(SecureErrorHandler.loadingFailed)),
      ),
      data: (securityContext) {
        if (securityContext == null) {
          return const Scaffold(
            body: Center(child: Text('Sign in to view calendar.')),
          );
        }

        final providersAsync = ref.watch(providersStreamProvider(securityContext));
        final servicesAsync = ref.watch(servicesStreamProvider(securityContext));
        final locationsAsync = ref.watch(locationsStreamProvider(securityContext));

        final filter = _buildRangeFilter(securityContext);
        final appointmentsAsync = ref.watch(appointmentsInRangeProvider(filter));

        servicesAsync.whenData((value) => _services = value);
        locationsAsync.whenData((value) => _locations = value);

        final isToday = isSameDay(_focusedDay, DateTime.now());

        return Scaffold(
          backgroundColor: isDark
              ? theme.scaffoldBackgroundColor
              : theme.colorScheme.surfaceContainerLowest,
          floatingActionButton: FloatingActionButton(
            onPressed: () => _addAppointment(context, securityContext),
            child: const Icon(Icons.add),
          ),
          body: SafeArea(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: CustomScrollView(
                  slivers: [
                  SliverToBoxAdapter(
                    child: CalendarHeader(
                      focusedDay: _focusedDay,
                      selectedDay: _selectedDay,
                      onTodayTap: _goToToday,
                      onFormatToggle: _cycleCalendarFormat,
                      formatLabel: _formatLabel,
                      primaryColor: config.branding.primaryColor,
                      accentColor: config.branding.accentColor,
                      isToday: isToday,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: providersAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (error, stackTrace) => const SizedBox.shrink(),
                      data: (providers) => CalendarProviderFilter(
                        providers: providers,
                        selectedProviderId: _selectedProviderId,
                        primaryColor: config.branding.primaryColor,
                        onSelectionChanged: (value) => setState(() => _selectedProviderId = value),
                        isDarkMode: isDark,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: CalendarGrid(
                      appointmentsAsync: appointmentsAsync,
                      calendarFormat: _calendarFormat,
                      focusedDay: _focusedDay,
                      selectedDay: _selectedDay,
                      primaryColor: config.branding.primaryColor,
                      accentColor: config.branding.accentColor,
                      isDarkMode: isDark,
                      onDaySelected: (selectedDay, focusedDay) {
                        if (!isSameDay(_selectedDay, selectedDay)) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        }
                      },
                      onFormatChanged: (format) => setState(() => _calendarFormat = format),
                      onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
                      getEventsForDay: _getEventsForDay,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      child: Divider(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  if (_selectedDay != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xs),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: AppIconSize.sm,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            HSpace.xs,
                            Text(
                              isSameDay(_selectedDay!, DateTime.now())
                                  ? "Today's Schedule"
                                  : DateFormat('EEEE\'s Schedule').format(_selectedDay!),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  DayAppointmentsSection(
                    selectedDay: _selectedDay,
                    appointmentsAsync: appointmentsAsync,
                    securityContext: securityContext,
                    providersAsync: providersAsync,
                    services: _services,
                    locations: _locations,
                    onCreateAppointment: () => _addAppointment(context, securityContext),
                    onAppointmentTap: (appointment, provider) => _showAppointmentDetail(
                      appointment,
                      provider,
                      securityContext,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Show appointment detail sheet with file management
  void _showAppointmentDetail(
    Appointment appointment,
    provider_model.Provider provider,
    SecurityContext securityContext,
  ) {
    // Find matching service and location for full details
    final service = _services.isEmpty
        ? null
        : _services.cast<Service?>().firstWhere(
              (s) => s?.id == appointment.serviceId,
              orElse: () => null,
            );
    final location = _locations.isEmpty
        ? null
        : _locations.cast<Location?>().firstWhere(
              (l) => l?.id == appointment.locationId,
              orElse: () => null,
            );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (sheetContext) => StaffAppointmentDetailSheet(
        securityContext: securityContext,
        appointment: appointment,
        provider: provider,
        service: service,
        location: location,
        onStatusChanged: _refresh,
      ),
    );
  }

  List<Appointment> _getEventsForDay(
    DateTime day,
    List<Appointment> allAppointments,
  ) {
    return allAppointments.where((appointment) {
      return isSameDay(appointment.startTime, day);
    }).toList();
  }

  AppointmentRangeFilter _buildRangeFilter(SecurityContext securityContext) {
    DateTime start;
    DateTime end;

    switch (_calendarFormat) {
      case CalendarFormat.month:
        start = DateTime(_focusedDay.year, _focusedDay.month, 1);
        end = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
        break;
      case CalendarFormat.twoWeeks:
        start = _focusedDay.subtract(Duration(days: _focusedDay.weekday - 1));
        end = start.add(const Duration(days: 14));
        break;
      case CalendarFormat.week:
        start = _focusedDay.subtract(Duration(days: _focusedDay.weekday - 1));
        end = start.add(const Duration(days: 7));
        break;
    }

    return AppointmentRangeFilter(
      securityContext: securityContext,
      start: start,
      end: end,
      providerId: _selectedProviderId,
    );
  }
}
