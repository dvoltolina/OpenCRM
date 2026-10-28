import 'package:flutter/material.dart';

/// Action bar for bulk timesheet operations.
///
/// Displays pending entry count and provides quick action buttons
/// like "Approve All" for batch processing.
class BulkActionsBar extends StatelessWidget {
  const BulkActionsBar({
    super.key,
    required this.pendingCount,
    required this.onApproveAll,
  });

  final int pendingCount;
  final VoidCallback onApproveAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_empty, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$pendingCount entries pending approval',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.orange.shade900,
              ),
            ),
          ),
          FilledButton(
            onPressed: onApproveAll,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
            ),
            child: const Text('Approve All'),
          ),
        ],
      ),
    );
  }
}
