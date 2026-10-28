import 'package:flutter/material.dart';

enum ScheduleView { day, week }

class ScheduleViewToggle extends StatelessWidget {
  const ScheduleViewToggle({
    super.key,
    required this.currentView,
    required this.onViewChanged,
  });

  final ScheduleView currentView;
  final ValueChanged<ScheduleView> onViewChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SegmentedButton<ScheduleView>(
        segments: const [
          ButtonSegment(
            value: ScheduleView.day,
            label: Text('Day'),
            icon: Icon(Icons.calendar_view_day),
          ),
          ButtonSegment(
            value: ScheduleView.week,
            label: Text('Week'),
            icon: Icon(Icons.calendar_view_week),
          ),
        ],
        selected: {currentView},
        onSelectionChanged: (Set<ScheduleView> selection) {
          onViewChanged(selection.first);
        },
      ),
    );
  }
}
