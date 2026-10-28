import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/providers.dart';
import '../../../core/services/magic_link_service.dart';
import '../../../core/services/recurrence_service.dart';
import '../../../core/ui/components/components.dart';
import '../../../data/models/appointment.dart';
import '../../../data/models/client.dart';
import '../../../data/models/location.dart';
import '../../../data/models/magic_link_token.dart';
import '../../../data/models/provider.dart' as provider_model;
import '../../../data/models/security_context.dart';
import '../../../data/models/service.dart';
import '../../../data/repositories/appointments_repository.dart';
import '../../../data/repositories/clients_repository.dart';
import '../../../data/repositories/locations_repository.dart';
import '../../../data/repositories/providers_repository.dart';
import '../../../data/repositories/services_repository.dart';
import 'cancel_appointment_page.dart';
import 'reschedule_appointment_page.dart';
import 'widgets/appointment_actions_card.dart';
import 'widgets/appointment_details_card.dart';
import 'widgets/appointment_status_banner.dart';
import 'widgets/client_information_card.dart';
import 'widgets/recurring_series_card.dart';
import 'widgets/token_expiration_notice.dart';

/// View appointment page accessible via magic link token
///
/// Provides secure, login-free access to appointment details for customers.
/// This is the destination when customers click the magic link from their email/SMS.
///
/// Features:
/// - Token validation and expiration checking
/// - Appointment details display
/// - Quick actions: Reschedule, Cancel (coming soon via Agent 3)
/// - Support contact information
/// - Security: No authentication required, token-based access only
class ViewAppointmentPage extends ConsumerStatefulWidget {
  const ViewAppointmentPage({
    required this.tokenString,
    required this.businessId,
    this.magicLinkService,
    super.key,
  });

  final String tokenString;
  final String businessId;
  final MagicLinkService? magicLinkService;

  @override
  ConsumerState<ViewAppointmentPage> createState() => _ViewAppointmentPageState();
}

class _ViewAppointmentPageState extends ConsumerState<ViewAppointmentPage> {
  late final MagicLinkService _magicLinkService;
  late final RecurrenceService _recurrenceService;
  late final AppointmentsRepository _appointmentsRepository;
  late final ClientsRepository _clientsRepository;
  late final ProvidersRepository _providersRepository;
  late final ServicesRepository _servicesRepository;
  late final LocationsRepository _locationsRepository;

  MagicLinkToken? _token;
  Appointment? _appointment;
  Client? _client;
  provider_model.Provider? _provider;
  Service? _service;
  Location? _location;
  List<Appointment>? _seriesAppointments;
  int? _currentOccurrenceIndex;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _magicLinkService =
        widget.magicLinkService ?? ref.read(magicLinkServiceProvider);
    _recurrenceService = ref.read(recurrenceServiceProvider);
    _appointmentsRepository = ref.read(appointmentsRepositoryProvider);
    _clientsRepository = ref.read(clientsRepositoryProvider);
    _providersRepository = ref.read(providersRepositoryProvider);
    _servicesRepository = ref.read(servicesRepositoryProvider);
    _locationsRepository = ref.read(locationsRepositoryProvider);
    _loadAppointmentData();
  }

  Future<void> _loadAppointmentData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Validate token
      final token = await _magicLinkService.validateToken(
        tokenString: widget.tokenString,
        businessId: widget.businessId,
      );

      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid or expired link. Please request a new link.';
        });
        return;
      }

      _token = token;

      // Create a security context for this token
      // Note: This is a special context that only has access to the specific appointment
      final securityContext = SecurityContext(
        userId: token.clientId,
        businessId: token.businessId,
        role: UserRole.client,
        clientId: token.clientId,
      );

      // Load appointment
      final appointment = await _appointmentsRepository.getAppointment(
        context: securityContext,
        appointmentId: token.appointmentId,
      );

      if (appointment == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Appointment not found. It may have been deleted.';
        });
        return;
      }

      _appointment = appointment;

      // Load related data
      final results = await Future.wait([
        _clientsRepository.getClient(
          context: securityContext,
          clientId: appointment.clientId,
        ),
        _providersRepository.getProvider(
          context: securityContext,
          providerId: appointment.providerId,
        ),
        _servicesRepository.getService(
          context: securityContext,
          serviceId: appointment.serviceId,
        ),
        _locationsRepository.getLocation(
          context: securityContext,
          locationId: appointment.locationId,
        ),
      ]);

      _client = results[0] as Client?;
      _provider = results[1] as provider_model.Provider?;
      _service = results[2] as Service?;
      _location = results[3] as Location?;

      // Load series appointments if this is a recurring appointment
      if (appointment.isRecurring && appointment.recurrenceId != null) {
        await _loadSeriesAppointments(securityContext, appointment);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load appointment details. Please try again.';
      });
    }
  }

  Future<void> _loadSeriesAppointments(
    SecurityContext securityContext,
    Appointment appointment,
  ) async {
    try {
      final seriesAppointments = await _recurrenceService.getRecurringSeries(
        businessId: securityContext.businessId,
        recurrenceId: appointment.recurrenceId!,
      );
      
      // Sort by start time
      seriesAppointments.sort((a, b) => a.startTime.compareTo(b.startTime));
      
      // Find current occurrence index
      final currentIndex = seriesAppointments.indexWhere(
        (apt) => apt.id == appointment.id,
      );

      setState(() {
        _seriesAppointments = seriesAppointments;
        _currentOccurrenceIndex = currentIndex >= 0 ? currentIndex : null;
      });
    } catch (e) {
      // Silently fail - series info is non-critical
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final branding = config.branding;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Appointment'),
        centerTitle: true,
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_appointment == null ||
        _client == null ||
        _provider == null ||
        _service == null ||
        _location == null) {
      return _buildErrorState();
    }

    return _buildContent();
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            VSpace.md,
            Text(
              _errorMessage ?? 'Unable to load appointment',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            VSpace.lg,
            FilledButton.icon(
              onPressed: _loadAppointmentData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final dateFormat = DateFormat('EEEE, MMMM d, y');
    final timeFormat = DateFormat('h:mm a');
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _loadAppointmentData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status banner
            AppointmentStatusBanner(status: _appointment!.status),
            VSpace.lg,

            // Recurring series info
            if (_appointment!.isRecurring && _seriesAppointments != null) ...[
              RecurringSeriesCard(
                seriesAppointments: _seriesAppointments!,
                currentOccurrenceIndex: _currentOccurrenceIndex,
              ),
              VSpace.lg,
            ],

            // Appointment details card with premium styling
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: AppointmentDetailsCard(
                appointment: _appointment!,
                service: _service!,
                provider: _provider!,
                location: _location!,
                dateFormat: dateFormat,
                timeFormat: timeFormat,
              ),
            ),
            VSpace.lg,

            // Client information card with premium styling
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClientInformationCard(client: _client!),
            ),
            VSpace.lg,

            // Actions card with premium styling
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: AppointmentActionsCard(
                appointment: _appointment!,
                provider: _provider!,
                onReschedule: _openReschedule,
                onCancel: _openCancellation,
              ),
            ),
            VSpace.lg,

            // Token expiration notice
            if (_token != null) TokenExpirationNotice(token: _token!),
          ],
        ),
      ),
    );
  }

  void _openReschedule() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RescheduleAppointmentPage(
          tokenString: widget.tokenString,
          businessId: widget.businessId,
        ),
      ),
    );
  }

  void _openCancellation() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CancelAppointmentPage(
          tokenString: widget.tokenString,
          businessId: widget.businessId,
        ),
      ),
    );
  }
}
