// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/secure_error_handler.dart';
import '../../../core/services/availability_service.dart' show AvailabilitySlot;
import '../../../core/services/file_storage_service.dart';
import '../../../core/ui/components/components.dart';
import '../../../data/models/appointment.dart';
import '../../../data/models/group_attendee.dart' show GroupAttendee;
import '../../../data/models/location.dart';
import '../../../data/models/provider.dart' as provider_model;
import '../../../data/models/security_context.dart';
import '../../../data/models/service.dart';
import '../../../data/repositories/appointments_repository.dart';
import '../../../data/repositories/file_attachment_repository.dart';
import '../../../data/repositories/clients_repository.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../booking/presentation/widgets/group_session_materials_section.dart';
import '../../booking/presentation/utils/group_session_billing.dart'
    show GroupSessionBillingHelper, GroupCancellationPolicy;
import 'providers.dart';
import 'utils/group_session_utils.dart';
import 'widgets/group_session_cancel_dialog.dart';
import 'widgets/client_group_session_card.dart';
import 'widgets/group_session_filters.dart';

/// Public-facing list of group sessions/classes that clients can join.
class GroupSessionsPage extends ConsumerStatefulWidget {
  const GroupSessionsPage({super.key, this.config});

  final AppConfig? config;

  @override
  ConsumerState<GroupSessionsPage> createState() => _GroupSessionsPageState();
}

class _GroupSessionsPageState extends ConsumerState<GroupSessionsPage> {
  late final AppointmentsRepository _appointmentsRepository;
  late final ClientsRepository _clientsRepository;
  late final PaymentRepository _paymentRepository;
  late final FileAttachmentRepository _fileAttachmentRepository;
  late final FileStorageService _fileStorageService;
  GroupSessionBillingHelper? _billingHelper;

  late AppConfig _config;

  bool _busy = false;
  String? _error;
  String? _serviceFilter;
  String? _providerFilter;
  String? _locationFilter;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now().add(const Duration(days: 30)),
  );

  @override
  void initState() {
    super.initState();
    _appointmentsRepository = ref.read(appointmentsRepositoryProvider);
    _clientsRepository = ref.read(clientsRepositoryProvider);
    _paymentRepository = ref.read(paymentRepositoryProvider);
    _fileAttachmentRepository = FileAttachmentRepository();
    _fileStorageService = FileStorageService();
  }

  @override
  Widget build(BuildContext context) {
    _config = widget.config ?? ref.watch(appConfigProvider);
    if (_billingHelper != null &&
        _billingHelper!.currency != _config.paymentConfig.currency.toUpperCase()) {
      _billingHelper = null;
    }
    final securityContextAsync = ref.watch(securityContextProvider);

    return securityContextAsync.when(
      loading: () => const Scaffold(
        body: LoadingStateWidget(
          message: 'Loading group sessions...',
        ),
      ),
      error: (error, _) => Scaffold(
        body: ErrorStateWidget(
          error: error,
          message: 'Unable to load sessions',
        ),
      ),
      data: (securityContext) {
        if (securityContext == null || securityContext.clientId == null) {
          return const Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Sign in with your client link to browse and join group sessions.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final servicesAsync = ref.watch(portalServicesProvider(securityContext));
        final providersAsync =
            ref.watch(portalProvidersProvider(securityContext));
        final locationsAsync =
            ref.watch(portalLocationsProvider(securityContext));

        return servicesAsync.when(
          loading: () => const Scaffold(
            body: LoadingStateWidget(
              message: 'Loading services...',
            ),
          ),
          error: (error, _) => Scaffold(
            body: ErrorStateWidget(
              error: error,
              message: 'Unable to load services',
            ),
          ),
          data: (services) {
            return providersAsync.when(
              loading: () => const Scaffold(
                body: LoadingStateWidget(
                  message: 'Loading providers...',
                ),
              ),
              error: (error, _) => Scaffold(
                body: ErrorStateWidget(
                  error: error,
                  message: 'Unable to load providers',
                ),
              ),
              data: (providers) {
                return locationsAsync.when(
                  loading: () => const Scaffold(
                    body: LoadingStateWidget(
                      message: 'Loading locations...',
                    ),
                  ),
                  error: (error, _) => Scaffold(
                    body: ErrorStateWidget(
                      error: error,
                      message: 'Unable to load locations',
                    ),
                  ),
                  data: (locations) {
                    return _buildScaffold(
                      context,
                      securityContext,
                      services,
                      providers,
                      locations,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    SecurityContext securityContext,
    List<Service> services,
    List<provider_model.Provider> providers,
    List<Location> locations,
  ) {
    final theme = Theme.of(context);
    final config = ref.watch(appConfigProvider);
    final branding = config.branding;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Sessions & Classes'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [branding.primaryColor, branding.accentColor],
            ),
          ),
        ),
      ),
      backgroundColor: branding.backgroundColor,
      body: Column(
        children: [
          // Modern filter section with premium card styling
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: GroupSessionFilters(
              services: services,
              providers: providers,
              locations: locations,
              serviceFilter: _serviceFilter,
              providerFilter: _providerFilter,
              locationFilter: _locationFilter,
              dateRange: _dateRange,
              onServiceChanged: (value) => setState(() => _serviceFilter = value),
              onProviderChanged: (value) => setState(() => _providerFilter = value),
              onLocationChanged: (value) => setState(() => _locationFilter = value),
              onDateRangeChanged: (range) => setState(() => _dateRange = range),
              onReset: () {
                setState(() {
                  _serviceFilter = null;
                  _providerFilter = null;
                  _locationFilter = null;
                  _dateRange = DateTimeRange(
                    start: DateTime.now(),
                    end: DateTime.now().add(const Duration(days: 30)),
                  );
                });
              },
            ),
          ),
          if (_error != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                    color: theme.colorScheme.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<List<Appointment>>(
              stream: _appointmentsRepository.watchPublicGroupSessions(
                context: securityContext,
                startingAfter: _dateRange.start,
                endingBefore: _dateRange.end,
                serviceId: _serviceFilter,
                providerId: _providerFilter,
                locationId: _locationFilter,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ErrorStateWidget(
                    error: snapshot.error!,
                    message: 'Unable to load group sessions',
                  );
                }
                if (!snapshot.hasData) {
                  return const LoadingStateWidget(
                    message: 'Loading available sessions...',
                  );
                }

                final sessions = snapshot.data!
                    .where(
                      (session) =>
                          session.startTime.isAfter(_dateRange.start) &&
                          session.startTime.isBefore(_dateRange.end),
                    )
                    .toList();

                if (sessions.isEmpty) {
                  final hasFilters = _serviceFilter != null ||
                      _providerFilter != null ||
                      _locationFilter != null;

                  return EmptyStateWidget(
                    icon: Icons.event_available_outlined,
                    title: hasFilters
                        ? 'No sessions match your filters'
                        : 'No upcoming group sessions',
                    subtitle: hasFilters
                        ? 'Try adjusting your filters or reset them to see all available sessions'
                        : 'Check back soon for new classes and group sessions',
                    actionLabel: hasFilters ? 'Reset Filters' : null,
                    onAction: hasFilters
                        ? () {
                            setState(() {
                              _serviceFilter = null;
                              _providerFilter = null;
                              _locationFilter = null;
                              _dateRange = DateTimeRange(
                                start: DateTime.now(),
                                end: DateTime.now().add(const Duration(days: 30)),
                              );
                            });
                          }
                        : null,
                  );
                }

                return ListView.separated(
                  padding: AppSpacing.pagePadding,
                  itemCount: sessions.length,
                  separatorBuilder: (context, _) => VSpace.sm,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final serviceName = GroupSessionUtils.lookupServiceName(
                      session.serviceId,
                      services,
                    );
                    final providerName = GroupSessionUtils.lookupProviderName(
                      session.providerId,
                      providers,
                    );
                    final locationName = GroupSessionUtils.lookupLocationName(
                      session.locationId,
                      locations,
                    );

                    final remaining = session.remainingSeats;
                    final deadline = session.registrationDeadline;
                    final deadlinePassed =
                        deadline != null && deadline.isBefore(DateTime.now());
                    final full = session.isFull || deadlinePassed;
                    final capacity = session.capacity;
                    final servicePriceCents = _servicePriceCents(
                      session.serviceId,
                      services,
                    );
                    final joined =
                        session.attendeeIds.contains(securityContext.clientId);

                    return ClientGroupSessionCard(
                      session: session,
                      securityContext: securityContext,
                      serviceName: serviceName,
                      providerName: providerName,
                      locationName: locationName,
                      remainingSeats: remaining,
                      capacity: capacity,
                      registrationDeadline: deadline,
                      deadlinePassed: deadlinePassed,
                      isFull: full,
                      busy: _busy,
                      joined: joined,
                      servicePriceCents: servicePriceCents,
                      onCopyIcs: () => GroupSessionUtils.copyIcsToClipboard(
                        context: context,
                        session: session,
                        serviceName: serviceName,
                        providerName: providerName,
                        locationName: locationName,
                      ),
                      onJoin: full || _busy || joined
                          ? null
                          : () => _joinSession(
                                securityContext,
                                session.id,
                                securityContext.clientId!,
                              ),
                      onCancel: joined
                          ? () => _cancelSession(
                                securityContext,
                                session,
                                securityContext.clientId!,
                                servicePriceCents,
                              )
                          : null,
                      loadAttendee: () => _appointmentsRepository.getGroupAttendee(
                        context: securityContext,
                        appointmentId: session.id,
                        attendeeId: securityContext.clientId!,
                      ),
                      materialsSection: joined
                          ? Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: GroupSessionMaterialsSection(
                                securityContext: securityContext,
                                session: session,
                                repository: _fileAttachmentRepository,
                                storageService: _fileStorageService,
                                canUpload: false,
                                canDelete: false,
                                wrapInCard: false,
                                title: 'Materials for attendees',
                                emptyMessage:
                                    'Materials will appear here when staff share them.',
                              ),
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinSession(
    SecurityContext securityContext,
    String appointmentId,
    String clientId,
  ) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final rulesEngine = ref.read(bookingRulesEngineProvider);
      final validation = await rulesEngine.validateGroupJoin(
        context: securityContext,
        appointmentId: appointmentId,
        clientId: clientId,
      );
      if (!validation.isValid) {
        const message = SecureErrorHandler.operationFailed;
        if (mounted) {
          setState(() => _error = message);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
        return;
      }

      final client = await _clientsRepository.getClient(
        context: securityContext,
        clientId: clientId,
      );
      final attendee = GroupAttendee(
        id: clientId,
        clientId: clientId,
        displayName: client?.fullName ?? 'Guest',
        email: client?.email,
        phone: client?.phone,
      );

      await _appointmentsRepository.addAttendeeToGroupSession(
        context: securityContext,
        appointmentId: appointmentId,
        clientId: clientId,
        attendee: attendee,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are registered for this session.')),
      );
    } catch (e) {
      if (!mounted) return;
      const errorMessage = SecureErrorHandler.operationFailed;
      setState(() => _error = errorMessage);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _cancelSession(
    SecurityContext securityContext,
    Appointment session,
    String clientId,
    int servicePriceCents,
  ) async {
    // First get the attendee and preview what will happen
    final attendee = await _appointmentsRepository.getGroupAttendee(
      context: securityContext,
      appointmentId: session.id,
      attendeeId: clientId,
    );

    if (attendee == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(SecureErrorHandler.operationFailed)),
        );
      }
      return;
    }

    // Show confirmation dialog with refund preview
    final billingHelper = _ensureBillingHelper();
    final preview = billingHelper.previewCancellation(
      appointment: session,
      attendee: attendee,
      originalPaymentCents: servicePriceCents,
    );

    final confirmed = await GroupSessionCancelDialog.show(
      context: context,
      session: session,
      preview: preview,
    );

    if (!confirmed || !mounted) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      // Process the cancellation with proper refund/fee handling
      final result = await billingHelper.processAttendeeCancellation(
        actorContext: securityContext,
        appointment: session,
        attendee: attendee,
        originalPaymentCents: servicePriceCents,
        cancellationReason: 'Client-initiated cancellation',
      );

      // Remove from attendee list
      await _appointmentsRepository.removeAttendeeFromGroupSession(
        context: securityContext,
        appointmentId: session.id,
        clientId: clientId,
        attendeeId: attendee.id,
      );

      await _triggerWaitlist(session, securityContext);
      if (!mounted) return;

      // Show result message
      final message = result.message ?? 'Your spot has been cancelled.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      const errorMessage = SecureErrorHandler.operationFailed;
      setState(() => _error = errorMessage);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  GroupSessionBillingHelper _ensureBillingHelper() {
    if (_billingHelper != null) {
      return _billingHelper!;
    }
    _billingHelper = GroupSessionBillingHelper(
      paymentRepository: _paymentRepository,
      attendeesRepository: _appointmentsRepository.attendeesRepository,
      currency: _config.paymentConfig.currency.toUpperCase(),
      cancellationPolicy:
          GroupCancellationPolicy.fromBookingPolicies(_config.bookingPolicies),
    );
    return _billingHelper!;
  }

  Future<void> _triggerWaitlist(
    Appointment session,
    SecurityContext actorContext,
  ) async {
    final waitlistService = ref.read(waitlistServiceProvider);
    await waitlistService.handleReleasedSlot(
      actorContext: actorContext,
      appointment: session,
      slot: AvailabilitySlot(
        providerId: session.providerId,
        locationId: session.locationId,
        start: session.startTime,
        end: session.endTime,
      ),
    );
  }

  int _servicePriceCents(String serviceId, List<Service> services) =>
      ((services.firstWhere((s) => s.id == serviceId,
        orElse: () => Service(id: '', businessId: '', name: '', price: 0, durationMinutes: 0, createdAt: DateTime.now())
      ).price) * 100).round();
}
