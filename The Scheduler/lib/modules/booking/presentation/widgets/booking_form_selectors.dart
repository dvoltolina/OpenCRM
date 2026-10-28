import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/providers.dart';
import '../../../../core/services/availability_service.dart';
import '../../../../core/services/booking_rules_engine.dart';
import '../../../../core/ui/components/components.dart';
import '../../../../core/ui/ui_exports.dart';
import '../../../../data/models/recurrence_pattern.dart';
import 'recurrence_picker.dart';

/// Date selection widget with premium styling.
class DateSelector extends ConsumerWidget {
  const DateSelector({
    super.key,
    required this.selectedDate,
    required this.onPickDate,
  });

  final DateTime selectedDate;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(appConfigProvider).branding;
    final theme = Theme.of(context);
    final dateLabel = DateFormat('yyyy-MM-dd').format(selectedDate);

    return Container(
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
        readOnly: true,
        decoration: InputDecoration(
          labelText: 'Appointment date',
          labelStyle: TextStyle(color: branding.primaryColor),
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
          suffixIcon: IconButton(
            icon: Icon(Icons.edit_calendar_outlined, color: branding.accentColor),
            onPressed: onPickDate,
          ),
        ),
        controller: TextEditingController(text: dateLabel),
      ),
    );
  }
}

/// Time slot selection widget with premium styling.
class SlotSelector extends ConsumerWidget {
  const SlotSelector({
    super.key,
    required this.slots,
    required this.loading,
    required this.selectedSlot,
    required this.onSelected,
  });

  final List<AvailabilitySlot> slots;
  final bool loading;
  final AvailabilitySlot? selectedSlot;
  final ValueChanged<AvailabilitySlot> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(appConfigProvider).branding;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (loading) {
      return Center(
        child: Column(
          children: [
            VSpace.xs,
            buildSkeletonGrid(count: 6, cardHeight: 60),
          ],
        ),
      );
    }

    if (slots.isEmpty) {
      return Container(
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
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(
              Icons.schedule,
              size: AppIconSize.lg,
              color: colorScheme.onSurfaceVariant,
            ),
            HSpace.md,
            Expanded(
              child: Text(
                'Select a service and provider to load available time slots.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available slots',
          style: theme.textTheme.titleMedium?.copyWith(
            color: branding.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        VSpace.sm,
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: slots
              .map(
                (slot) => _SlotChip(
                  slot: slot,
                  isSelected: selectedSlot == slot,
                  onSelected: () => onSelected(slot),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _SlotChip extends ConsumerWidget {
  const _SlotChip({
    required this.slot,
    required this.isSelected,
    required this.onSelected,
  });

  final AvailabilitySlot slot;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(appConfigProvider).branding;
    final theme = Theme.of(context);

    return Material(
      color: isSelected ? branding.accentColor : Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: isSelected ? 4 : 0,
      shadowColor: isSelected
          ? branding.accentColor.withValues(alpha: 0.4)
          : Colors.transparent,
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? branding.accentColor
                  : theme.colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            DateFormat('HH:mm').format(slot.start),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isSelected ? Colors.white : branding.primaryColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

/// Recurrence pattern selection section.
class RecurrenceSection extends StatelessWidget {
  const RecurrenceSection({
    super.key,
    required this.baseDate,
    required this.pattern,
    required this.onChanged,
  });

  final DateTime baseDate;
  final RecurrencePattern? pattern;
  final ValueChanged<RecurrencePattern?> onChanged;

  @override
  Widget build(BuildContext context) {
    return RecurrencePicker(
      key: ValueKey(
        '${baseDate.toIso8601String()}_${pattern?.id ?? 'none'}',
      ),
      startDate: baseDate,
      initialPattern: pattern,
      onChanged: onChanged,
    );
  }
}

/// Validation summary display with premium styling.
class ValidationSummary extends ConsumerWidget {
  const ValidationSummary({super.key, required this.validation});

  final BookingValidationResult? validation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(appConfigProvider).branding;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (validation == null) {
      return Container(
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
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          'Validation status will appear here once all booking fields are selected.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final bgColor = validation!.isValid
        ? colorScheme.primaryContainer
        : colorScheme.errorContainer;
    final textColor = validation!.isValid
        ? colorScheme.onPrimaryContainer
        : colorScheme.onErrorContainer;
    final borderColor = validation!.isValid
        ? branding.accentColor
        : colorScheme.error;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                validation!.isValid
                    ? Icons.verified_outlined
                    : Icons.warning_amber_rounded,
                color: textColor,
                size: AppIconSize.md,
              ),
              HSpace.xs,
              Expanded(
                child: Text(
                  validation!.isValid
                      ? 'Booking ready to confirm'
                      : 'Resolve conflicts before booking',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (validation!.requiresDeposit) ...[
            VSpace.xs,
            Text(
              'Deposit required: \$${validation!.depositAmount?.toStringAsFixed(2) ?? '0'}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
              ),
            ),
          ],
          if (validation!.conflicts.isNotEmpty) ...[
            VSpace.sm,
            for (final conflict in validation!.conflicts)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  '• ${conflict.message}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
