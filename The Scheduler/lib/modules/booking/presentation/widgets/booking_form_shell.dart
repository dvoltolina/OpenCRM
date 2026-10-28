import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/user_messages.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/services/booking_rules_engine.dart';
import '../../../../core/services/availability_service.dart';
import '../../../../core/utils/safe_error_handler.dart';
import '../../../../core/ui/ui_exports.dart';
import '../../../../core/ui/components/components.dart';
import '../../../../data/models/appointment.dart';
import '../../../../data/models/client.dart';
import '../../../../data/models/location.dart';
import '../../../../data/models/magic_link_token.dart';
import '../../../../data/models/provider.dart' as provider_model;
import '../../../../data/models/security_context.dart';
import '../../../../data/models/service.dart';
import '../../../../data/models/recurrence_pattern.dart';
import '../../../../data/repositories/clients_repository.dart';
import '../../../../data/repositories/providers_repository.dart';
import '../booking_confirmation_page.dart';
import 'booking_form_sections.dart';
import 'booking_form_shared.dart';
import 'booking_form_side_panel.dart';

part 'booking_form_shell_actions.dart';

class BookingFormShell extends ConsumerStatefulWidget {
  const BookingFormShell({this.debugSecurityContext, super.key});

  final SecurityContext? debugSecurityContext;

  @override
  ConsumerState<BookingFormShell> createState() => _BookingFormShellState();
}

class _BookingFormShellState extends ConsumerState<BookingFormShell> {
  static const _uuid = Uuid();

  AvailabilityService get _availabilityService =>
      ref.read(availabilityServiceProvider);

  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedServiceId;
  String? _selectedProviderId;
  String? _selectedLocationId;
  String? _selectedClientId;
  AvailabilitySlot? _selectedSlot;
  DateTime _selectedDate = DateTime.now();
  RecurrencePattern? _recurrencePattern;

  BookingValidationResult? _lastValidation;
  bool _isSubmitting = false;
  bool _loadingSlots = false;
  List<AvailabilitySlot> _slots = [];

  List<Service> _services = [];
  List<Location> _locations = [];

  BookingRulesEngine get _rulesEngine => ref.read(bookingRulesEngineProvider);
  ClientsRepository get _clientsRepository =>
      ref.read(clientsRepositoryProvider);
  ProvidersRepository get _providersRepository =>
      ref.read(providersRepositoryProvider);

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final branding = config.branding;
    final securityContextAsync = ref.watch(securityContextProvider);

    return securityContextAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => const Center(child: Text(UserMessages.authError)),
      data: (securityContext) {
        final effectiveContext = widget.debugSecurityContext ?? securityContext;
        if (effectiveContext == null) {
          return const Center(child: Text('Sign in to manage bookings.'));
        }

        return Container(
          color: branding.backgroundColor,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showSidePanel = constraints.maxWidth > 1024;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildFormArea(context, effectiveContext),
                    ),
                    if (showSidePanel) const SizedBox(width: 24),
                    if (showSidePanel)
                      Flexible(
                        flex: 2,
                        child: BookingFormSidePanel(
                          policies: config.bookingPolicies,
                          validation: _lastValidation,
                          onRefreshPolicies: () =>
                              _validateDraft(effectiveContext),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormArea(BuildContext context, SecurityContext securityContext) {
    final branding = ref.watch(appConfigProvider).branding;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: branding.primaryColor.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create a booking',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: branding.primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select a service, provider, and slot to confirm an appointment.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close form',
                  icon: Icon(Icons.close, color: branding.primaryColor),
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).maybePop();
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildDataStreams(
            context: context,
            securityContext: securityContext,
            childBuilder: (services, providers, locations, clients) {
              _services = services;
              _locations = locations;
              _selectedLocationId ??= locations.isNotEmpty
                  ? locations.first.id
                  : null;

              return BookingFormFields(
                formKey: _formKey,
                services: services,
                providers: providers,
                locations: locations,
                clients: clients,
                selectedServiceId: _selectedServiceId,
                selectedProviderId: _selectedProviderId,
                selectedLocationId: _selectedLocationId,
                onServiceChanged: (value) {
                  setState(() {
                    _selectedServiceId = value;
                    _selectedSlot = null;
                    _recurrencePattern = null;
                  });
                  _fetchSlotsIfReady(securityContext);
                },
                onProviderChanged: (value) {
                  setState(() {
                    _selectedProviderId = value;
                    _selectedSlot = null;
                    _recurrencePattern = null;
                  });
                  _fetchSlotsIfReady(securityContext);
                },
                onLocationChanged: (value) {
                  setState(() {
                    _selectedLocationId = value;
                    _selectedSlot = null;
                    _recurrencePattern = null;
                  });
                  _fetchSlotsIfReady(securityContext);
                },
                selectedDate: _selectedDate,
                onPickDate: () => _pickDate(context, securityContext),
                slots: _slots,
                loadingSlots: _loadingSlots,
                selectedSlot: _selectedSlot,
                onSlotSelected: (slot) {
                  setState(() => _selectedSlot = slot);
                  _validateDraft(securityContext);
                },
                canManageClients: securityContext.role.canManageClients,
                selectedClientId: _selectedClientId,
                onClientChanged: (value) {
                  setState(() => _selectedClientId = value);
                },
                onQuickAddClient: () =>
                    _showQuickAddDialog(securityContext, clients),
                notesController: _notesController,
                recurrencePattern: _recurrencePattern,
                onRecurrenceChanged: (pattern) {
                  setState(() => _recurrencePattern = pattern);
                  _validateDraft(securityContext);
                },
                validationResult: _lastValidation,
                onValidate: () => _validateDraft(securityContext),
                onSubmit: () => _submitBooking(securityContext),
                isSubmitting: _isSubmitting,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDataStreams({
    required BuildContext context,
    required SecurityContext securityContext,
    required Widget Function(
      List<Service> services,
      List<provider_model.Provider> providers,
      List<Location> locations,
      List<Client> clients,
    )
    childBuilder,
  }) {
    final servicesAsync = ref.watch(servicesStreamProvider(securityContext));
    final providersAsync = ref.watch(providersStreamProvider(securityContext));
    final locationsAsync = ref.watch(locationsStreamProvider(securityContext));
    final clientsAsync = securityContext.role.canManageClients
        ? ref.watch(clientsStreamProvider(securityContext))
        : const AsyncValue.data(<Client>[]);

    return servicesAsync.when(
      loading: () => Center(
        child: Padding(
          padding: responsivePadding(context),
          child: Column(
            children: const [
              SkeletonFormField(hasLabel: true),
              SizedBox(height: 16),
              SkeletonFormField(hasLabel: true),
              SizedBox(height: 16),
              SkeletonFormField(hasLabel: true),
            ],
          ),
        ),
      ),
      error: (error, _) => const Center(child: Text(UserMessages.loadError)),
      data: (services) {
        if (services.isEmpty) {
          return const BookingEmptyState(
            icon: Icons.design_services,
            message:
                'Add services in Settings → Services to start booking appointments.',
          );
        }

        return providersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              const Center(child: Text(UserMessages.loadError)),
          data: (providers) {
            return locationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  const Center(child: Text(UserMessages.loadError)),
              data: (locations) {
                _services = services;
                _locations = locations;
                _selectedLocationId ??= locations.isNotEmpty
                    ? locations.first.id
                    : null;
                if (_selectedProviderId == null &&
                    securityContext.providerId != null &&
                    providers.any(
                      (provider) => provider.id == securityContext.providerId,
                    )) {
                  _selectedProviderId = securityContext.providerId;
                }
                _selectedProviderId ??= providers.isNotEmpty
                    ? providers.first.id
                    : null;

                return clientsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) =>
                      const Center(child: Text(UserMessages.loadError)),
                  data: (clients) {
                    return childBuilder(
                      services,
                      providers,
                      locations,
                      clients,
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
}
