import 'package:flutter/material.dart';

/// A reusable dropdown filter widget for session filtering.
class SessionDropdownFilter<T> extends StatelessWidget {
  const SessionDropdownFilter({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<T>(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
        initialValue: value,
        items: [
          DropdownMenuItem<T>(
            value: null,
            child: Text('All $label'),
          ),
          ...items,
        ],
        onChanged: onChanged,
      ),
    );
  }
}
