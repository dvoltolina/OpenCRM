import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Date picker row for selecting a new date
class DatePickerRow extends StatelessWidget {
  const DatePickerRow({
    required this.selectedDate,
    required this.onPickDate,
    super.key,
  });

  final DateTime selectedDate;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Select a new date',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        TextButton.icon(
          onPressed: onPickDate,
          icon: const Icon(Icons.calendar_today),
          label: Text(DateFormat('MMM d').format(selectedDate)),
        ),
      ],
    );
  }
}
