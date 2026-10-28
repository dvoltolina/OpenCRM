import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/availability_service.dart';

/// Widget for displaying and selecting available time slots
class TimeSlotsWidget extends StatelessWidget {
  const TimeSlotsWidget({
    required this.loadingSlots,
    required this.slots,
    required this.selectedSlot,
    required this.onSlotSelected,
    super.key,
  });

  final bool loadingSlots;
  final List<AvailabilitySlot> slots;
  final AvailabilitySlot? selectedSlot;
  final ValueChanged<AvailabilitySlot> onSlotSelected;

  @override
  Widget build(BuildContext context) {
    if (loadingSlots) {
      return const Center(child: CircularProgressIndicator());
    }

    if (slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: const Text(
          'No open times on the selected day. Choose another date.',
        ),
      );
    }

    final timeFormatter = DateFormat('h:mm a');

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: slots.map((slot) {
        final label = timeFormatter.format(slot.start);
        final selected = selectedSlot == slot;
        return ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onSlotSelected(slot),
        );
      }).toList(),
    );
  }
}
