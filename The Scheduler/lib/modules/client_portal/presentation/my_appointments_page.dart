import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/components/components.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/safe_error_handler.dart';
import '../../../data/models/appointment.dart';
import '../../../data/models/provider.dart' as provider_model;
import '../../../data/models/service.dart';
import '../../../data/models/location.dart';
import '../../../data/models/security_context.dart';
import 'view_appointment_page.dart';
import 'widgets/appointment_cards.dart';
import 'widgets/appointment_history_export.dart';

/// My Appointments Page - Customer portal view of all appointments
///
/// Features:
/// - List all appointments (upcoming, past, cancelled)
/// - Filter by status
/// - Sort by date
/// - Quick actions: View details, Reschedule, Cancel
/// - Download receipts (if payment integration enabled)
/// - Join telehealth session button for virtual appointments
///
/// Requires authenticated customer with SecurityContext
class MyAppointmentsPage extends ConsumerStatefulWidget {
  const MyAppointmentsPage({required this.securityContext, super.key});

  final SecurityContext securityContext;

  @override
  ConsumerState<MyAppointmentsPage> createState() => _MyAppointmentsPageState();
}

class _MyAppointmentsPageState extends ConsumerState<MyAppointmentsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Cache for providers, services, locations
  final Map<String, provider_model.Provider> _providersCache = {};
  final Map<String, Service> _servicesCache = {};
  final Map<String, Location> _locationsCache = {};
  List<Appointment> _latestAppointments = const [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _preloadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _preloadData() async {
    // Preload providers, services, locations for faster rendering
    try {
      final providersRepository = ref.read(providersRepositoryProvider);
      final servicesRepository = ref.read(servicesRepositoryProvider);
      final locationsRepository = ref.read(locationsRepositoryProvider);

      final providers = await providersRepository.getProviders(
        context: widget.securityContext,
      );
      final services = await servicesRepository.getServices(
        context: widget.securityContext,
      );
      final locations = await locationsRepository.getLocations(
        context: widget.securityContext,
      );

      setState(() {
        for (final provider in providers) {
          _providersCache[provider.id] = provider;
        }
        for (final service in services) {
          _servicesCache[service.id] = service;
        }
        for (final location in locations) {
          _locationsCache[location.id] = location;
        }
      });
    } catch (e) {
      // Continue without cache
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        actions: [
          IconButton(
            tooltip: 'Export PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _exportAppointmentsPdf,
          ),
          IconButton(
            tooltip: 'Export CSV',
            icon: const Icon(Icons.table_view_outlined),
            onPressed: _exportAppointmentsCsv,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming', icon: Icon(Icons.event_available_outlined)),
            Tab(text: 'Past', icon: Icon(Icons.history_outlined)),
            Tab(text: 'Cancelled', icon: Icon(Icons.cancel_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentsList(
            filterStatuses: [
              AppointmentStatus.pending,
              AppointmentStatus.confirmed,
            ],
            isUpcoming: true,
          ),
          _buildAppointmentsList(
            filterStatuses: [
              AppointmentStatus.completed,
              AppointmentStatus.noShow,
            ],
            isUpcoming: false,
          ),
          _buildAppointmentsList(
            filterStatuses: [AppointmentStatus.cancelled],
            isUpcoming: false,
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList({
    required List<AppointmentStatus> filterStatuses,
    required bool isUpcoming,
  }) {
    return StreamBuilder<List<Appointment>>(
      stream: ref.read(appointmentsRepositoryProvider).watchClientAppointments(
        context: widget.securityContext,
        clientId: widget.securityContext.clientId!,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(SafeErrorHandler.handle(snapshot.error!));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allAppointments = snapshot.data!;
        _latestAppointments = allAppointments;
        final allAppointmentsById = {
          for (final appointment in allAppointments)
            appointment.id: appointment,
        };

        final filteredAppointments = allAppointments
            .where((apt) => filterStatuses.contains(apt.status))
            .toList();

        final entries = _buildListEntries(
          filteredAppointments,
          allAppointmentsById,
          isUpcoming,
        );

        if (entries.isEmpty) {
          return _buildEmptyState(isUpcoming);
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Stream will automatically refresh
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: AppSpacing.pagePadding,
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              if (entry.type == _AppointmentEntryType.series) {
                final occurrences = entry.occurrences ?? [];
                final service = occurrences.isNotEmpty
                    ? _servicesCache[occurrences.first.serviceId]
                    : null;
                final parent = entry.parent;
                return RecurringSeriesCard(
                  occurrences: occurrences,
                  parent: parent,
                  isUpcoming: isUpcoming,
                  service: service,
                  providers: _providersCache,
                  locations: _locationsCache,
                  onTap: _viewAppointmentDetails,
                );
              }
              final appointment = entry.appointment!;
              final provider = _providersCache[appointment.providerId];
              final service = _servicesCache[appointment.serviceId];
              final location = _locationsCache[appointment.locationId];
              return AppointmentCardTile(
                appointment: appointment,
                provider: provider,
                service: service,
                location: location,
                isUpcoming: isUpcoming,
                onTap: () => _viewAppointmentDetails(appointment),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isUpcoming) {
    return EmptyStateWidget(
      icon: isUpcoming
          ? Icons.event_available_outlined
          : Icons.history_outlined,
      title: isUpcoming ? 'No Upcoming Appointments' : 'No Past Appointments',
      subtitle: isUpcoming
          ? 'When you book an appointment, it will appear here'
          : 'Your completed appointments will appear here',
    );
  }

  Widget _buildErrorState(String error) {
    return EmptyStateWidget(
      icon: Icons.error_outline,
      title: 'Failed to Load Appointments',
      subtitle: error,
    );
  }

  Future<void> _viewAppointmentDetails(Appointment appointment) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Use userId as the email for magic link (userId is the Firebase Auth UID/email)
      final clientEmail = widget.securityContext.userId;

      // Generate a magic link token for this appointment
      final magicLinkService = ref.read(magicLinkServiceProvider);
      final token = await magicLinkService.generateToken(
        context: widget.securityContext,
        appointmentId: appointment.id,
        clientId: widget.securityContext.clientId!,
        clientEmail: clientEmail,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Remove loading dialog

      // Navigate to ViewAppointmentPage with the token
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ViewAppointmentPage(
            tokenString: token.token,
            businessId: widget.securityContext.businessId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Remove loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(SafeErrorHandler.handle(e))),
      );
    }
  }

  List<_AppointmentListEntry> _buildListEntries(
    List<Appointment> filtered,
    Map<String, Appointment> allById,
    bool isUpcoming,
  ) {
    final seriesMap = <String, List<Appointment>>{};
    final singles = <Appointment>[];

    for (final appointment in filtered) {
      if (appointment.isRecurring && appointment.recurrenceId != null) {
        seriesMap
            .putIfAbsent(appointment.recurrenceId!, () => [])
            .add(appointment);
      } else {
        singles.add(appointment);
      }
    }

    final entries = <_AppointmentListEntry>[];

    seriesMap.forEach((recurrenceId, appointments) {
      appointments.sort((a, b) => a.startTime.compareTo(b.startTime));
      final parent = allById[recurrenceId];
      entries.add(
        _AppointmentListEntry.series(
          recurrenceId: recurrenceId,
          appointments: appointments,
          parent: parent,
        ),
      );
    });

    for (final appointment in singles) {
      entries.add(_AppointmentListEntry.single(appointment));
    }

    entries.sort((a, b) {
      final aKey = a.sortKey(isUpcoming);
      final bKey = b.sortKey(isUpcoming);
      return isUpcoming ? aKey.compareTo(bKey) : bKey.compareTo(aKey);
    });

    return entries;
  }

  Future<void> _exportAppointmentsCsv() async {
    await AppointmentHistoryExport.exportCsv(
      context: context,
      appointments: _latestAppointments,
      servicesCache: _servicesCache,
      providersCache: _providersCache,
      locationsCache: _locationsCache,
      onExportComplete: (recordCount) => _logExportAudit('csv', recordCount),
    );
  }

  Future<void> _exportAppointmentsPdf() async {
    await AppointmentHistoryExport.exportPdf(
      context: context,
      appointments: _latestAppointments,
      servicesCache: _servicesCache,
      providersCache: _providersCache,
      locationsCache: _locationsCache,
      onExportComplete: (recordCount) => _logExportAudit('pdf', recordCount),
    );
  }

  Future<void> _logExportAudit(String format, int recordCount) async {
    try {
      final auditLogRepo = ref.read(auditLogRepositoryProvider);
      await auditLogRepo.log(
        context: widget.securityContext,
        action: 'dataExport',
        entityType: 'AppointmentHistory',
        entityId: widget.securityContext.userId,
        details: {'format': format, 'recordCount': recordCount},
        source: 'client_portal',
      );
    } catch (_) {
      // Swallow audit failures to avoid blocking user flow
    }
  }
}

enum _AppointmentEntryType { single, series }

class _AppointmentListEntry {
  _AppointmentListEntry.single(this.appointment)
    : type = _AppointmentEntryType.single,
      occurrences = null,
      recurrenceId = null,
      parent = null;

  _AppointmentListEntry.series({
    required this.recurrenceId,
    required List<Appointment> appointments,
    required this.parent,
  }) : type = _AppointmentEntryType.series,
       occurrences = List<Appointment>.from(appointments),
       appointment = null;

  final _AppointmentEntryType type;
  final Appointment? appointment;
  final List<Appointment>? occurrences;
  final String? recurrenceId;
  final Appointment? parent;

  DateTime sortKey(bool isUpcoming) {
    if (type == _AppointmentEntryType.single) {
      return appointment!.startTime;
    }
    final items = List<Appointment>.from(occurrences!);
    items.sort((a, b) => a.startTime.compareTo(b.startTime));
    return isUpcoming ? items.first.startTime : items.last.startTime;
  }
}
