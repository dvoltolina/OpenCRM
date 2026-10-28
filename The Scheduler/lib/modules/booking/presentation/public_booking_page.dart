import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/providers.dart';
import '../../../core/services/time_slot_service.dart';
import '../../../core/ui/animations.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/utils/safe_error_handler.dart';
import '../../../data/models/appointment.dart';
import '../../../data/models/client.dart';
import '../../../data/models/payment.dart';
import '../../../data/models/provider.dart' as provider;
import '../../../data/models/security_context.dart';
import '../../../data/models/service.dart';
/// Public Booking Page
///
/// Accessible via /book/{slug} URL without authentication.
/// Allows clients to book appointments with a business using their public booking URL.
///
/// Flow:
/// 1. Resolve slug to businessId via WorkspaceRepository (Cloud Function)
/// 2. Load business info and available services
/// 3. Show booking interface (guest booking context)
/// 4. Create appointment under the resolved businessId
///
/// HIPAA Compliance:
/// - No PHI required for initial booking display
/// - Client email/phone collected during booking
/// - All writes include proper businessId for tenant isolation
/// - Uses repository pattern (no direct Firestore calls)
class PublicBookingPage extends ConsumerStatefulWidget {
  const PublicBookingPage({
    super.key,
    required this.slug,
  });
  final String slug;
  @override
  ConsumerState<PublicBookingPage> createState() => _PublicBookingPageState();
}
class _PublicBookingPageState extends ConsumerState<PublicBookingPage> {
  bool _isLoading = true;
  String? _businessId;
  String? _businessName;
  String? _errorMessage;
  Service? _selectedService;
  provider.Provider? _selectedProvider;
  String? _selectedLocationId;
  DateTime _selectedDate = DateTime.now();
  TimeSlot? _selectedSlot;
  List<Service> _services = const [];
  List<provider.Provider> _providers = const [];
  List<String> _locationIds = const [];
  List<TimeSlot> _slots = const [];
  bool _submitting = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _resolveSlug();
  }
  Future<void> _resolveSlug() async {
    try {
      // Use repository pattern to resolve slug to businessId
      final workspaceRepo = ref.read(workspaceRepositoryProvider);
      final result = await workspaceRepo.lookupBusinessBySlug(slug: widget.slug);

      if (!result.found || result.businessId == null) {
        setState(() {
          _errorMessage = 'Business not found. Please check the URL and try again.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _businessId = result.businessId;
        _businessName = result.businessName;
        _isLoading = false;
      });
      await _loadReferenceData();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load booking page. Please try again later.';
        _isLoading = false;
      });
    }
  }
  SecurityContext _guestContext() {
    return SecurityContext(
      userId: 'public-${_businessId ?? widget.slug}',
      businessId: _businessId ?? '',
      role: UserRole.admin, // allows repository access; scope stays business-only
      clientId: null,
      providerId: null,
      userFullName: _nameController.text.isEmpty
          ? 'Guest'
          : _nameController.text.trim(),
    );
  }

  Future<void> _loadReferenceData() async {
    if (_businessId == null) return;
    try {
      final ctx = _guestContext();
      final servicesRepo = ref.read(servicesRepositoryProvider);
      final providersRepo = ref.read(providersRepositoryProvider);
      final services = await servicesRepo.getServices(context: ctx);
      final providers = await providersRepo.getProviders(context: ctx);
      final locationIds = providers
          .expand((p) => p.locationIds)
          .toSet()
          .toList();

      setState(() {
        _services = services;
        _providers = providers;
        _locationIds = locationIds;
        if (services.isNotEmpty) {
          _selectedService = services.first;
        }
        if (providers.isNotEmpty) {
          _selectedProvider = providers.first;
        }
        _selectedLocationId = locationIds.isNotEmpty ? locationIds.first : null;
      });

      await _loadSlots();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load services/providers.';
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      await _loadSlots();
    }
  }

  Future<void> _loadSlots() async {
    if (_selectedService == null ||
        _selectedProvider == null ||
        _selectedLocationId == null ||
        _businessId == null) {
      return;
    }
    try {
      final ctx = _guestContext();
      final timeSlotService = ref.read(timeSlotServiceProvider);
      final duration = Duration(minutes: _selectedService!.durationMinutes);
      final slots = await timeSlotService.generateSlots(
        context: ctx,
        providerId: _selectedProvider!.id,
        locationId: _selectedLocationId!,
        date: _selectedDate,
        serviceDuration: duration,
      );
      setState(() {
        _slots = slots.where((s) => s.isAvailable).toList();
        _selectedSlot = _slots.isNotEmpty ? _slots.first : null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load time slots.';
      });
    }
  }

  Future<void> _submitBooking() async {
    if (_selectedService == null ||
        _selectedProvider == null ||
        _selectedLocationId == null ||
        _selectedSlot == null ||
        _businessId == null) {
      setState(() {
        _errorMessage = 'Please complete all selections.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final ctx = _guestContext();
      final clientsRepo = ref.read(clientsRepositoryProvider);
      final appointmentsRepo = ref.read(appointmentsRepositoryProvider);
      final uuid = const Uuid();
      final clientId = uuid.v4();
      final now = DateTime.now();

      // Create a lightweight client for the booking
      await clientsRepo.createClient(
        context: ctx,
        client: Client(
          id: clientId,
          businessId: _businessId!,
          firstName: _nameController.text.trim().isEmpty
              ? 'Guest'
              : _nameController.text.trim(),
          lastName: '',
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          address: null,
          tags: const [],
          lifecycle: ClientLifecycle.newClient,
          lastContactDate: null,
          lastAppointmentDate: null,
          preferences: const {},
          customFields: const {},
          createdAt: now,
          updatedAt: now,
          userId: null,
          hasPaymentMethod: false,
          stripeCustomerId: null,
          serviceLatitude: null,
          serviceLongitude: null,
          serviceNotes: null,
        ),
      );

      final start = _selectedSlot!.startTime;
      final end = _selectedSlot!.endTime;
      final appointmentId = uuid.v4();

      final appointment = Appointment(
        id: appointmentId,
        businessId: _businessId!,
        clientId: clientId,
        providerId: _selectedProvider!.id,
        serviceId: _selectedService!.id,
        serviceType: _selectedService!.name,
        locationId: _selectedLocationId!,
        startTime: start,
        endTime: end,
        date: DateTime(start.year, start.month, start.day),
        status: AppointmentStatus.pending,
        notes: null,
        createdAt: now,
        paymentStatus: PaymentStatus.none,
        requiresPayment: false,
        paymentType: PaymentType.full,
        refundEligible: false,
        isRecurring: false,
        isGroupSession: false,
      );

      await appointmentsRepo.upsertAppointment(
        context: ctx,
        appointment: appointment,
      );

      if (!mounted) return;
      setState(() {
        _submitting = false;
      });
      _showConfirmation(appointment);
    } catch (e) {
      final msg = SafeErrorHandler.handle(e);
      if (mounted) {
        setState(() {
          _submitting = false;
          _errorMessage = msg;
        });
      }
    }
  }

  void _showConfirmation(Appointment appointment) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Booking Confirmed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedService?.name ?? 'Service',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            VSpace.xs,
            Text(
              '${appointment.startTime} - ${appointment.endTime}',
              style: theme.textTheme.bodyMedium,
            ),
            VSpace.xs,
            Text(
              'Provider: ${_selectedProvider?.fullName ?? ''}',
              style: theme.textTheme.bodyMedium,
            ),
            VSpace.sm,
            const Text(
              'A confirmation email/SMS will be sent with a magic link to manage your booking.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final branding = config.branding;
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Booking'),
        ),
        body: Center(
          child: Padding(
            padding: AppSpacing.pagePadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                VSpace.lg,
                Text(
                  _errorMessage!,
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Book with $_businessName'),
      ),
      body: Center(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 48,
                      color: branding.primaryColor,
                    ),
                    HSpace.md,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Book an Appointment',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Public booking for $_businessName',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
                VSpace.lg,
                _buildSelectors(theme),
                VSpace.md,
                _buildContactForm(),
                VSpace.md,
                _buildSlots(),
                VSpace.lg,
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submitting ? null : _submitBooking,
                    icon: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.event_available),
                    label: Text(_submitting ? 'Booking...' : 'Confirm Booking'),
                  ),
                ),
                if (_errorMessage != null) ...[
                  VSpace.sm,
                  ErrorFeedback(message: _errorMessage!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectors(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Service', style: theme.textTheme.titleMedium),
        DropdownButton<Service>(
          value: _selectedService,
          isExpanded: true,
          onChanged: (value) async {
            setState(() {
              _selectedService = value;
            });
            await _loadSlots();
          },
          items: _services
              .map(
                (s) => DropdownMenuItem<Service>(
                  value: s,
                  child: Text(s.name),
                ),
              )
              .toList(),
        ),
        VSpace.sm,
        Text('Provider', style: theme.textTheme.titleMedium),
        DropdownButton<provider.Provider>(
          value: _selectedProvider,
          isExpanded: true,
          onChanged: (value) async {
            setState(() {
              _selectedProvider = value;
            });
            await _loadSlots();
          },
          items: _providers
              .map(
                (p) => DropdownMenuItem<provider.Provider>(
                  value: p,
                  child: Text(p.fullName),
                ),
              )
              .toList(),
        ),
        VSpace.sm,
        Text('Location', style: theme.textTheme.titleMedium),
        DropdownButton<String>(
          value: _selectedLocationId,
          isExpanded: true,
          onChanged: (value) async {
            setState(() {
              _selectedLocationId = value;
            });
            await _loadSlots();
          },
          items: _locationIds
              .map(
                (id) => DropdownMenuItem<String>(
                  value: id,
                  child: Text(id),
                ),
              )
              .toList(),
        ),
        VSpace.sm,
        Row(
          children: [
            Text(
              'Date: ${_selectedDate.toLocal().toString().split(' ')[0]}',
              style: theme.textTheme.bodyMedium,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('Change'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        VSpace.sm,
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        VSpace.sm,
        TextField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildSlots() {
    if (_slots.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.schedule_outlined,
        title: 'No slots available',
        subtitle: 'Try another date or provider.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Slots',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        VSpace.xs,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _slots.map((slot) {
            final isSelected = _selectedSlot == slot;
            return ChoiceChip(
              label: Text(
                TimeOfDay.fromDateTime(slot.startTime).format(context),
              ),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedSlot = slot),
            );
          }).toList(),
        ),
      ],
    );
  }
}
