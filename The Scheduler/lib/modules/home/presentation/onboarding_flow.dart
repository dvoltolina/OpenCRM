import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/onboarding_completion_service.dart';
import '../../../core/services/onboarding_controller.dart';
import '../../../core/ui/components/components.dart';
import '../../../data/models/onboarding_state.dart';
import '../../../data/models/security_context.dart';
import '../../../data/models/self_booking_access.dart';
import 'widgets/onboarding_availability_step.dart';
import 'widgets/onboarding_booking_preferences_step.dart';
import 'widgets/onboarding_business_profile_step.dart';
import 'widgets/onboarding_notifications_step.dart';
import 'widgets/onboarding_services_step.dart';
import 'widgets/onboarding_summary_step.dart';

Future<void> showOnboardingFlow({
  required BuildContext context,
  required WidgetRef ref,
  required AppConfig config,
  required String businessId,
  required OnboardingController controller,
  required SecurityContext securityContext,
}) async {
  final result = await showDialog<OnboardingState>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final size = MediaQuery.sizeOf(dialogContext);
      final isSmallScreen = size.width < 600;
      return Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16 : 40,
          vertical: isSmallScreen ? 24 : 40,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 640,
            maxHeight: size.height * 0.9,
            minHeight: 400,
          ),
          child: _OnboardingFlow(
            config: config,
            businessId: businessId,
            initialState: controller.state.value,
          ),
        ),
      );
    },
  );

  if (result != null) {
    // Save onboarding state
    await controller.save(result);

    // Sync to actual entities (services, locations)
    if (result.isComplete) {
      final completionService = OnboardingCompletionService(
        servicesRepository: ref.read(servicesRepositoryProvider),
        locationsRepository: ref.read(locationsRepositoryProvider),
      );
      await completionService.syncOnboardingData(
        state: result,
        securityContext: securityContext,
      );
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isComplete
              ? 'Setup complete! Services and location created.'
              : 'Onboarding updated',
        ),
      ),
    );
  }
}

class _OnboardingFlow extends StatefulWidget {
  const _OnboardingFlow({
    required this.config,
    required this.businessId,
    this.initialState,
  });

  final AppConfig config;
  final String businessId;
  final OnboardingState? initialState;

  @override
  State<_OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<_OnboardingFlow> {
  late final TextEditingController _businessName;
  late final TextEditingController _tagline;
  late final TextEditingController _location;
  late final TextEditingController _serviceInput;

  late final Set<String> _selectedOperatingDays;
  final List<String> _services = [];

  late String _industry;
  late SelfBookingAccess _selfBookingAccess;
  late bool _requireDeposit;
  late bool _emailReminders;
  late bool _smsReminders;
  late Duration _reminderLeadTime;
  int _currentStep = 0;

  List<Step> get _steps => [
        Step(
          title: const Text('Business Profile'),
          content: OnboardingBusinessProfileStep(
            businessName: _businessName,
            tagline: _tagline,
            location: _location,
          ),
        ),
        Step(
          title: const Text('Availability'),
          content: OnboardingAvailabilityStep(
            selectedDays: _selectedOperatingDays,
            onChanged: (day) {
              setState(() {
                if (_selectedOperatingDays.contains(day)) {
                  _selectedOperatingDays.remove(day);
                } else {
                  _selectedOperatingDays.add(day);
                }
              });
            },
          ),
        ),
        Step(
          title: const Text('Services'),
          content: OnboardingServicesStep(
            services: _services,
            serviceInput: _serviceInput,
            onAddService: _handleAddService,
            onRemoveService: (service) {
              setState(() => _services.remove(service));
            },
          ),
        ),
        Step(
          title: const Text('Booking Preferences'),
          content: OnboardingBookingPreferencesStep(
            selfBookingAccess: _selfBookingAccess,
            requireDeposit: _requireDeposit,
            onPreferenceChanged: (access, requireDeposit) {
              setState(() {
                _selfBookingAccess = access;
                _requireDeposit = requireDeposit;
              });
            },
          ),
        ),
        Step(
          title: const Text('Notifications'),
          content: OnboardingNotificationsStep(
            emailReminders: _emailReminders,
            smsReminders: _smsReminders,
            reminderLeadTime: _reminderLeadTime,
            onChanged: (email, sms, lead) {
              setState(() {
                _emailReminders = email;
                _smsReminders = sms;
                _reminderLeadTime = lead;
              });
            },
          ),
        ),
        Step(
          title: const Text('Summary'),
          content: OnboardingSummaryStep(
            industry: _industry,
            businessName: _businessName.text.isEmpty
                ? widget.config.branding.productName
                : _businessName.text,
            tagline: _tagline.text.isEmpty
                ? widget.config.branding.tagline
                : _tagline.text,
            location:
                _location.text.isEmpty ? 'Not set' : _location.text.trim(),
            selectedDays: _selectedOperatingDays.toList()..sort(),
            services: _services.isEmpty ? widget.config.serviceCatalog : _services,
            selfBookingAccess: _selfBookingAccess,
            requireDeposit: _requireDeposit,
            emailReminders: _emailReminders,
            smsReminders: _smsReminders,
            reminderLeadTime: _reminderLeadTime,
          ),
        ),
      ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialState;

    _businessName = TextEditingController(
      text: initial?.businessName ?? widget.config.branding.productName,
    );
    _tagline = TextEditingController(
      text: initial?.tagline ?? widget.config.branding.tagline,
    );
    _location = TextEditingController(text: initial?.location ?? '');
    _serviceInput = TextEditingController();

    _selectedOperatingDays = initial != null
        ? {...initial.operatingDays}
        : {'Mon', 'Tue', 'Wed', 'Thu'};
    _services.addAll(initial?.services ?? const []);

    _industry = initial?.industry ?? 'Therapy';
    _selfBookingAccess =
        initial?.selfBookingAccess ?? SelfBookingAccess.allCustomers;
    _requireDeposit = initial?.requireDeposit ?? false;
    _emailReminders = initial?.emailReminders ?? true;
    _smsReminders = initial?.smsReminders ?? false;
    _reminderLeadTime =
        Duration(hours: initial?.reminderLeadTimeHours ?? 24);
  }

  @override
  void dispose() {
    _businessName.dispose();
    _tagline.dispose();
    _location.dispose();
    _serviceInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        ListTile(
          title: const Text('Business Onboarding'),
          subtitle: Text(
            'Guided setup based on ${widget.config.branding.productName}',
          ),
          trailing: IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Stepper(
            type: StepperType.vertical,
            currentStep: _currentStep,
            controlsBuilder: (context, details) {
              final isLast = _currentStep == _steps.length - 1;
              return Row(
                children: [
                  GradientButton(
                    onPressed: isLast ? _handleComplete : details.onStepContinue,
                    child: Text(isLast ? 'Finish' : 'Next'),
                  ),
                  HSpace.sm,
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                ],
              );
            },
            onStepTapped: (index) => setState(() => _currentStep = index),
            onStepContinue: () {
              if (_currentStep < _steps.length - 1) {
                setState(() => _currentStep += 1);
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() => _currentStep -= 1);
              }
            },
            steps: _steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              return Step(
                title: step.title,
                subtitle: step.subtitle,
                content: step.content,
                isActive: _currentStep == index,
                state: _currentStep > index
                    ? StepState.complete
                    : StepState.indexed,
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: AppSpacing.cardPadding,
          child: Text(
            'You can revisit onboarding anytime from the dashboard.',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  void _handleAddService() {
    final value = _serviceInput.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _services.add(value);
      _serviceInput.clear();
    });
  }

  void _handleComplete() {
    final services =
        _services.isEmpty ? widget.config.serviceCatalog : _services;
    final result = OnboardingState.create(
      businessId: widget.businessId,
      industry: _industry,
      businessName: _businessName.text.isEmpty
          ? widget.config.branding.productName
          : _businessName.text,
      tagline: _tagline.text.isEmpty
          ? widget.config.branding.tagline
          : _tagline.text,
      location: _location.text,
      operatingDays: _selectedOperatingDays.toList()..sort(),
      services: services,
      selfBookingAccess: _selfBookingAccess,
      requireDeposit: _requireDeposit,
      emailReminders: _emailReminders,
      smsReminders: _smsReminders,
      reminderLeadTimeHours: _reminderLeadTime.inHours,
    );

    Navigator.of(context).pop(result);
  }
}
