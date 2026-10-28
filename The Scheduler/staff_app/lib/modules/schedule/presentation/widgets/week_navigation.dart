import 'package:flutter/material.dart';

/// Week navigation controls.
class WeekNavigation extends StatelessWidget {
  const WeekNavigation({
    super.key,
    required this.weekStart,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final DateTime weekStart;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: canGoPrevious ? onPrevious : null,
            tooltip: 'Previous week',
          ),
          Expanded(
            child: Center(
              child: Text(
                _formatRange(weekStart),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: canGoNext ? onNext : null,
            tooltip: 'Next week',
          ),
          TextButton(
            onPressed: onToday,
            child: const Text('Today'),
          ),
        ],
      ),
    );
  }

  String _formatRange(DateTime start) {
    final end = start.add(const Duration(days: 6));
    return '${start.month}/${start.day} - ${end.month}/${end.day}';
  }
}
