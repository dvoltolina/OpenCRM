import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/user_messages.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/availability_service.dart' as availability;
import '../../../core/services/waitlist_service.dart';
import '../../../core/ui/components/components.dart';
import '../../../data/models/appointment.dart';
import '../../../data/models/audit_log.dart';
import '../../../data/models/group_attendee.dart';
import '../../../data/models/location.dart';
import '../../../data/models/provider.dart' as provider_model;
import '../../../data/models/security_context.dart';
import '../../../data/models/service.dart';
import '../../../data/repositories/appointments_repository.dart';
import '../../../data/repositories/payment_repository.dart';
import 'create_group_session_page.dart';
import 'widgets/group_session_admin_widgets.dart';
import 'utils/group_session_billing.dart'
    show GroupSessionBillingHelper, GroupCancellationPolicy;

/// Admin page for managing group sessions and classes

class GroupSessionsAdminPage extends ConsumerStatefulWidget {
  const GroupSessionsAdminPage({super.key});

  @override
  ConsumerState<GroupSessionsAdminPage> createState() =>
      _GroupSessionsAdminPageState();
}

class _GroupSessionsAdminPageState
    extends ConsumerState<GroupSessionsAdminPage> {
  GroupSessionBillingHelper? _billingHelper;

  AppointmentsRepository get _appointmentsRepository =>
      ref.read(appointmentsRepositoryProvider);
  PaymentRepository get _paymentRepository =>
      ref.read(paymentRepositoryProvider);
  WaitlistService get _waitlistService => ref.read(waitlistServiceProvider);
  List<Service> _services = [];
  String? _serviceFilter;
  String? _providerFilter;
  String? _locationFilter;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now().add(const Duration(days: 60)),
  );

  @override
  Widget build(BuildContext context) {
    final securityContextAsync = ref.watch(securityContextProvider);

    return securityContextAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => const Scaffold(
        body: Center(child: Text(UserMessages.authError)),
      ),
      data: (securityContext) {
        if (securityContext == null) {
          return const Scaffold(
            body: Center(child: Text('Sign in to manage group sessions.')),
          );
        }

        final servicesAsync = ref.watch(servicesStreamProvider(securityContext));
        final providersAsync = ref.watch(providersStreamProvider(securityContext));
        final locationsAsync = ref.watch(locationsStreamProvider(securityContext));

        servicesAsync.whenData((value) => _services = value);

        if (servicesAsync.hasError ||
            providersAsync.hasError ||
            locationsAsync.hasError) {
          return const Scaffold(
            body: Center(child: Text('Error loading data.')),
          );
        }

        if (servicesAsync.isLoading ||
            providersAsync.isLoading ||
            locationsAsync.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final services = servicesAsync.value ?? [];
        final providers = providersAsync.value ?? [];
        final locations = locationsAsync.value ?? [];

        final providerOptions = _visibleProviders(
          securityContext,
          providers,
        );
        final effectiveProviderFilter =
            (!securityContext.role.canManageAllAppointments &&
                    !securityContext.role.canManageClients)
                ? securityContext.providerId
                : _providerFilter;

        return AppPageScaffold(
          title: 'Group Sessions',
          addPagePadding: false,
          actions: [
            IconButton(
              tooltip: 'Create session',
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreateGroupSessionPage(),
                  ),
                );
              },
            ),
          ],
          body: Column(
            children: [
              GroupSessionFiltersRow(
                dateRange: _dateRange,
                onDateRangeChanged: (range) {
                  setState(() => _dateRange = range);
                },
                onReset: () {
                  setState(() {
                    _serviceFilter = null;
                    _providerFilter = null;
                    _locationFilter = null;
                    _dateRange = DateTimeRange(
                      start: DateTime.now(),
                      end: DateTime.now().add(const Duration(days: 60)),
                    );
                  });
                },
                services: services,
                providers: providerOptions,
                locations: locations,
                onServiceChanged: (value) =>
                    setState(() => _serviceFilter = value),
                onProviderChanged: (value) =>
                    setState(() => _providerFilter = value),
                onLocationChanged: (value) =>
                    setState(() => _locationFilter = value),
                serviceValue: _serviceFilter,
                providerValue: effectiveProviderFilter,
                locationValue: _locationFilter,
              ),
              Expanded(
                child: StreamBuilder<List<Appointment>>(
                  stream: _appointmentsRepository.watchGroupSessions(
                    context: securityContext,
                    startingAfter: _dateRange.start,
                    endingBefore: _dateRange.end,
                    serviceId: _serviceFilter,
                    providerId: effectiveProviderFilter,
                    locationId: _locationFilter,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    final sessions = snapshot.data!
                        .where(
                          (session) =>
                              session.startTime.isAfter(
                                _dateRange.start,
                              ) &&
                              session.startTime.isBefore(
                                _dateRange.end,
                              ),
                        )
                        .toList();
                    if (sessions.isEmpty) {
                      return const Center(
                        child: Text('No group sessions found.'),
                      );
                    }
                    return ListView.separated(
                      padding: AppSpacing.pagePadding,
                      itemCount: sessions.length,
                      separatorBuilder: (context, _) => VSpace.sm,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        return GroupSessionCard(
                          appointment: session,
                          services: services,
                          providers: providers,
                          locations: locations,
                          onCopyIcs: () => _copyIcs(
                            context,
                            securityContext,
                            session,
                            services,
                            providers,
                            locations,
                          ),
                          attendeesBuilder: (_) =>
                              StreamBuilder<List<GroupAttendee>>(
                            stream: _appointmentsRepository.watchGroupAttendees(
                              context: securityContext,
                              appointmentId: session.id,
                            ),
                            builder: (context, attendeeSnapshot) {
                              if (!attendeeSnapshot.hasData) {
                                return const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: LinearProgressIndicator(),
                                );
                              }
                              final attendees = attendeeSnapshot.data!;
                              if (attendees.isEmpty) {
                                return const Padding(
                                  padding: AppSpacing.cardPadding,
                                  child: Text('No attendees yet'),
                                );
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: AppSpacing.cardPadding,
                                    child: Text(
                                      'Attendees (${attendees.length})',
                                      style: Theme.of(context).textTheme.titleSmall,
                                    ),
                                  ),
                                  ...attendees.map((attendee) => AppListTile(
                                    dense: true,
                                    leading: CircleAvatar(
                                      radius: 16,
                                      child: Text(
                                        attendee.displayName.isNotEmpty
                                            ? attendee.displayName[0].toUpperCase()
                                            : '?',
                                      ),
                                    ),
                                    title: attendee.displayName,
                                    subtitle: attendee.status.name,
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (value) => _handleAttendeeAction(
                                        value: value,
                                        attendee: attendee,
                                        appointment: session,
                                        securityContext: securityContext,
                                      ),
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'mark_paid',
                                          child: Text('Mark Paid'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'mark_refunded',
                                          child: Text('Mark Refunded'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'mark_attended',
                                          child: Text('Mark Attended'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'mark_no_show',
                                          child: Text('Mark No-Show'),
                                        ),
                                        const PopupMenuDivider(),
                                        const PopupMenuItem(
                                          value: 'remove',
                                          child: Text('Remove'),
                                        ),
                                      ],
                                    ),
                                  )),
                                ],
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  GroupSessionBillingHelper _ensureBillingHelper(AppConfig config) {
    if (_billingHelper != null) {
      return _billingHelper!;
    }
    _billingHelper = GroupSessionBillingHelper(
      paymentRepository: _paymentRepository,
      attendeesRepository: _appointmentsRepository.attendeesRepository,
      currency: config.paymentConfig.currency.toUpperCase(),
      cancellationPolicy:
          GroupCancellationPolicy.fromBookingPolicies(config.bookingPolicies),
    );
    return _billingHelper!;
  }

  Future<void> _maybeTriggerWaitlist(
    Appointment appointment,
    SecurityContext actorContext,
  ) async {
    await _waitlistService.handleReleasedSlot(
      actorContext: actorContext,
      appointment: appointment,
      slot: availability.AvailabilitySlot(
        providerId: appointment.providerId,
        locationId: appointment.locationId,
        start: appointment.startTime,
        end: appointment.endTime,
      ),
    );
  }

  Future<void> _copyIcs(
    BuildContext context,
    SecurityContext securityContext,
    Appointment session,
    List<Service> services,
    List<provider_model.Provider> providers,
    List<Location> locations,
  ) async {
    final serviceName = _lookupServiceName(session.serviceId, services);
    final providerName = _lookupProviderName(session.providerId, providers);
    final locationName = _lookupLocationName(session.locationId, locations);
    final startUtc = session.startTime.toUtc();
    final endUtc = session.endTime.toUtc();
    final messenger = ScaffoldMessenger.of(context);
    final dateFormat = DateFormat("yyyyMMdd'T'HHmmss'Z'");
    final buffer = StringBuffer()
      ..writeln('BEGIN:VCALENDAR')
      ..writeln('VERSION:2.0')
      ..writeln('PRODID:-//The Scheduler//Group Session//EN')
      ..writeln('BEGIN:VEVENT')
      ..writeln('UID:${session.id}@scheduler.example.com')
      ..writeln('DTSTAMP:${dateFormat.format(DateTime.now().toUtc())}')
      ..writeln('DTSTART:${dateFormat.format(startUtc)}')
      ..writeln('DTEND:${dateFormat.format(endUtc)}')
      ..writeln('SUMMARY:$serviceName')
      ..writeln('DESCRIPTION:Provider: $providerName\\nNotes omitted for privacy')
      ..writeln('LOCATION:$locationName')
      ..writeln('END:VEVENT')
      ..writeln('END:VCALENDAR');

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('ICS copied to clipboard.')),
      );
    }

    final auditLogRepository = ref.read(auditLogRepositoryProvider);
    unawaited(
      auditLogRepository
          .logEvent(
            AuditLogEntry(
              businessId: securityContext.businessId,
              userId: securityContext.userId,
              actionType: AuditActionType.dataExport,
              entityType: 'Appointment',
              entityId: session.id,
              metadata: {
                'source': 'copyIcs',
                'exportType': 'ics',
                'serviceId': session.serviceId,
                'providerId': session.providerId,
                'locationId': session.locationId,
                'startTime': session.startTime.toIso8601String(),
              },
            ),
          )
          .catchError(
        (error) => developer.log(
          'Failed to log ICS export',
          name: 'GroupSessionsAdminPage',
          error: error,
        ),
      ),
    );
  }

  String _lookupServiceName(String id, List<Service> services) {
    for (final service in services) {
      if (service.id == id) {
        return service.name;
      }
    }
    return id;
  }

  String _lookupProviderName(String id, List<provider_model.Provider> providers) {
    final match = providers.where((provider) => provider.id == id);
    if (match.isEmpty) return id;
    return match.first.fullName;
  }

  String _lookupLocationName(String id, List<Location> locations) {
    final match = locations.where((location) => location.id == id);
    if (match.isEmpty) return id;
    return match.first.name ?? id;
  }

  /// Filter providers based on security context permissions.
  List<provider_model.Provider> _visibleProviders(
    SecurityContext securityContext,
    List<provider_model.Provider> allProviders,
  ) {
    // Admins/managers can see all providers
    if (securityContext.role.canManageAllAppointments ||
        securityContext.role.canManageClients) {
      return allProviders;
    }
    // Staff can only see themselves
    if (securityContext.providerId != null) {
      return allProviders
          .where((p) => p.id == securityContext.providerId)
          .toList();
    }
    return allProviders;
  }

  /// Handle attendee action menu selections.
  Future<void> _handleAttendeeAction({
    required String value,
    required GroupAttendee attendee,
    required Appointment appointment,
    required SecurityContext securityContext,
  }) async {
    final config = ref.read(appConfigProvider);
    final billingHelper = _ensureBillingHelper(config);

    switch (value) {
      case 'mark_paid':
        // Calculate amount from service price
        final service = _services.firstWhere(
          (s) => s.id == appointment.serviceId,
          orElse: () => _services.first,
        );
        final amountCents = (service.price * 100).round();
        await billingHelper.markPaid(
          actorContext: securityContext,
          appointment: appointment,
          attendee: attendee,
          amountCents: amountCents,
        );
        if (mounted) setState(() {});
        break;

      case 'mark_refunded':
        // Fetch original payment amount if available
        int refundCents = 0;
        if (attendee.paymentId != null) {
          final payment = await _paymentRepository.getPaymentById(
            securityContext,
            attendee.paymentId!,
          );
          refundCents = payment?.amountCents ?? 0;
        }
        await billingHelper.markRefunded(
          actorContext: securityContext,
          appointment: appointment,
          attendee: attendee,
          refundAmountCents: refundCents,
        );
        if (mounted) setState(() {});
        break;

      case 'mark_attended':
        await _appointmentsRepository.updateGroupAttendeeStatuses(
          context: securityContext,
          appointmentId: appointment.id,
          attendeeId: attendee.id,
          status: GroupAttendeeStatus.attended,
        );
        if (mounted) setState(() {});
        break;

      case 'mark_no_show':
        await _appointmentsRepository.updateGroupAttendeeStatuses(
          context: securityContext,
          appointmentId: appointment.id,
          attendeeId: attendee.id,
          status: GroupAttendeeStatus.noShow,
        );
        if (mounted) setState(() {});
        break;

      case 'remove':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Remove attendee?'),
            content: Text('Remove ${attendee.displayName} from this session?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Remove'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await _appointmentsRepository.removeAttendeeFromGroupSession(
            context: securityContext,
            appointmentId: appointment.id,
            clientId: attendee.clientId,
            attendeeId: attendee.id,
          );
          await _maybeTriggerWaitlist(appointment, securityContext);
        }
        break;
    }
  }
}
