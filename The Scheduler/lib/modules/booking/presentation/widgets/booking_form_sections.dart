import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../../../core/services/availability_service.dart';
import '../../../../core/services/booking_rules_engine.dart';
import '../../../../core/ui/components/components.dart';
import '../../../../core/ui/ui_exports.dart';
import '../../../../data/models/client.dart';
import '../../../../data/models/location.dart';
import '../../../../data/models/provider.dart' as models;
import '../../../../data/models/recurrence_pattern.dart';
import '../../../../data/models/service.dart';
import 'booking_form_dropdowns.dart';
import 'booking_form_selectors.dart';

/// Booking form fields widget with Modern Sophisticated Blue theme
/// Updated with premium styling and warm backgrounds

class BookingFormFields extends ConsumerWidget {
  const BookingFormFields({super.key, 
    required this.formKey,
    required this.services,
    required this.providers,
    required this.locations,
    required this.clients,
    required this.selectedServiceId,
    required this.selectedProviderId,
    required this.selectedLocationId,
    required this.onServiceChanged,
    required this.onProviderChanged,
    required this.onLocationChanged,
    required this.selectedDate,
    required this.onPickDate,
    required this.slots,
    required this.loadingSlots,
    required this.selectedSlot,
    required this.onSlotSelected,
    required this.canManageClients,
    required this.selectedClientId,
    required this.onClientChanged,
    required this.onQuickAddClient,
    required this.notesController,
    required this.recurrencePattern,
    required this.onRecurrenceChanged,
    required this.validationResult,
    required this.onValidate,
    required this.onSubmit,
    required this.isSubmitting,
  });

  final GlobalKey<FormState> formKey;
  final List<Service> services;
  final List<models.Provider> providers;
  final List<Location> locations;
  final List<Client> clients;
  final String? selectedServiceId;
  final String? selectedProviderId;
  final String? selectedLocationId;
  final ValueChanged<String?> onServiceChanged;
  final ValueChanged<String?> onProviderChanged;
  final ValueChanged<String?> onLocationChanged;
  final DateTime selectedDate;
  final VoidCallback onPickDate;
  final List<AvailabilitySlot> slots;
  final bool loadingSlots;
  final AvailabilitySlot? selectedSlot;
  final ValueChanged<AvailabilitySlot> onSlotSelected;
  final bool canManageClients;
  final String? selectedClientId;
  final ValueChanged<String?> onClientChanged;
  final VoidCallback onQuickAddClient;
  final TextEditingController notesController;
  final RecurrencePattern? recurrencePattern;
  final ValueChanged<RecurrencePattern?> onRecurrenceChanged;
  final BookingValidationResult? validationResult;
  final VoidCallback onValidate;
  final VoidCallback onSubmit;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(appConfigProvider).branding;
    final theme = Theme.of(context);

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceDropdown(
            services: services,
            selectedServiceId: selectedServiceId,
            onChanged: onServiceChanged,
          ),
          VSpace.md,
          ProviderDropdown(
            providers: providers,
            selectedProviderId: selectedProviderId,
            onChanged: onProviderChanged,
          ),
          VSpace.md,
          LocationDropdown(
            locations: locations,
            selectedLocationId: selectedLocationId,
            onChanged: onLocationChanged,
          ),
          VSpace.md,
          DateSelector(
            selectedDate: selectedDate,
            onPickDate: onPickDate,
          ),
          VSpace.lg,
          SlotSelector(
            slots: slots,
            loading: loadingSlots,
            selectedSlot: selectedSlot,
            onSelected: onSlotSelected,
          ),
          VSpace.lg,
          RecurrenceSection(
            baseDate: _resolveStartDate(),
            pattern: recurrencePattern,
            onChanged: onRecurrenceChanged,
          ),
          VSpace.md,
          ClientSection(
            canManageClients: canManageClients,
            clients: clients,
            selectedClientId: selectedClientId,
            onClientChanged: onClientChanged,
            onQuickAddClient: onQuickAddClient,
          ),
          VSpace.md,
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: branding.primaryColor.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextFormField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: 'Notes / special requirements',
                labelStyle: TextStyle(color: branding.primaryColor),
                hintText: 'Optional details shared with provider',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: branding.accentColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              minLines: 2,
              maxLines: 5,
            ),
          ),
          VSpace.lg,
          ValidationSummary(validation: validationResult),
          VSpace.lg,
          Semantics(
            label: 'Booking actions',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                TouchTargets.ensure(
                  child: GradientButton(
                    onPressed: isSubmitting ? null : onValidate,
                    isLoading: false,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search),
                        SizedBox(width: 8),
                        Text('Validate availability'),
                      ],
                    ),
                  ),
                ),
                GradientButton(
                  onPressed: isSubmitting ? null : onSubmit,
                  isLoading: isSubmitting,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isSubmitting) const Icon(Icons.check_circle),
                      if (!isSubmitting) const SizedBox(width: 8),
                      const Text('Confirm booking'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          VSpace.lg,
        ],
      ),
    );
  }

  DateTime _resolveStartDate() {
    if (selectedSlot != null) return selectedSlot!.start;
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      9,
      0,
    );
  }
}
