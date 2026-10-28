import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/models/recurrence_pattern.dart';

/// Widget for selecting recurrence pattern for appointments
///
/// Allows users to configure:
/// - Frequency (daily, weekly, biweekly, monthly, custom)
/// - Days of week (for weekly patterns)
/// - End condition (never, after N occurrences, on specific date)
/// - Preview of generated dates
class RecurrencePicker extends StatefulWidget {
  const RecurrencePicker({
    super.key,
    this.initialPattern,
    required this.onChanged,
    required this.startDate,
  });

  final RecurrencePattern? initialPattern;
  final ValueChanged<RecurrencePattern?> onChanged;
  final DateTime startDate;

  @override
  State<RecurrencePicker> createState() => _RecurrencePickerState();
}

class _RecurrencePickerState extends State<RecurrencePicker> {
  static const _uuid = Uuid();

  late RecurrenceFrequency _frequency;
  late Set<DayOfWeek> _selectedDays;
  late RecurrenceEndType _endType;
  int _numberOfOccurrences = 10;
  DateTime? _endDate;
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPattern != null) {
      _enabled = true;
      _frequency = widget.initialPattern!.frequency;
      _selectedDays = Set.from(widget.initialPattern!.daysOfWeek);
      _endType = widget.initialPattern!.endType;
      _numberOfOccurrences = widget.initialPattern!.numberOfOccurrences ?? 10;
      _endDate = widget.initialPattern!.endDate;
    } else {
      _frequency = RecurrenceFrequency.weekly;
      _selectedDays = {};
      _endType = RecurrenceEndType.afterOccurrences;
      _endDate = widget.startDate.add(const Duration(days: 90));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: Text(
            'Recurring Appointment',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: const Text('Create a series of repeating appointments'),
          value: _enabled,
          onChanged: (value) {
            setState(() {
              _enabled = value;
            });
            _notifyChange();
          },
        ),
        if (_enabled) ...[
          const SizedBox(height: 16),
          _buildFrequencySelector(theme),
          const SizedBox(height: 16),
          if (_frequency == RecurrenceFrequency.weekly ||
              _frequency == RecurrenceFrequency.biweekly)
            _buildDaysOfWeekSelector(theme),
          if (_frequency == RecurrenceFrequency.weekly ||
              _frequency == RecurrenceFrequency.biweekly)
            const SizedBox(height: 16),
          _buildEndConditionSelector(theme),
          const SizedBox(height: 16),
          _buildPreview(theme),
        ],
      ],
    );
  }

  Widget _buildFrequencySelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Repeats',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        SegmentedButton<RecurrenceFrequency>(
          segments: const [
            ButtonSegment(
              value: RecurrenceFrequency.weekly,
              label: Text('Weekly'),
            ),
            ButtonSegment(
              value: RecurrenceFrequency.biweekly,
              label: Text('Biweekly'),
            ),
            ButtonSegment(
              value: RecurrenceFrequency.monthly,
              label: Text('Monthly'),
            ),
          ],
          selected: {_frequency},
          onSelectionChanged: (Set<RecurrenceFrequency> selected) {
            setState(() {
              _frequency = selected.first;
            });
            _notifyChange();
          },
        ),
      ],
    );
  }

  Widget _buildDaysOfWeekSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Repeat on',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DayOfWeek.values.map((day) {
            final isSelected = _selectedDays.contains(day);
            return FilterChip(
              label: Text(_getDayShortName(day)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedDays.add(day);
                  } else {
                    _selectedDays.remove(day);
                  }
                });
                _notifyChange();
              },
            );
          }).toList(),
        ),
        if (_selectedDays.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Select at least one day',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEndConditionSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ends',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        RadioGroup<RecurrenceEndType>(
          groupValue: _endType,
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _endType = value;
              if (value == RecurrenceEndType.onDate) {
                _endDate ??= widget.startDate.add(const Duration(days: 90));
              }
            });
            _notifyChange();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RadioListTile<RecurrenceEndType>(
                title: const Text('After a number of occurrences'),
                value: RecurrenceEndType.afterOccurrences,
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              if (_endType == RecurrenceEndType.afterOccurrences)
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Count',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          controller: TextEditingController(
                            text: _numberOfOccurrences.toString(),
                          ),
                          onChanged: (value) {
                            final count = int.tryParse(value);
                            if (count != null && count > 0 && count <= 52) {
                              setState(() {
                                _numberOfOccurrences = count;
                              });
                              _notifyChange();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('appointments'),
                    ],
                  ),
                ),
              RadioListTile<RecurrenceEndType>(
                title: const Text('On a specific date'),
                value: RecurrenceEndType.onDate,
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        if (_endType == RecurrenceEndType.onDate)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                _endDate != null
                    ? '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}'
                    : 'Select end date',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? widget.startDate.add(const Duration(days: 90)),
                  firstDate: widget.startDate.add(const Duration(days: 1)),
                  lastDate: widget.startDate.add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() {
                    _endDate = picked;
                  });
                  _notifyChange();
                }
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPreview(ThemeData theme) {
    final pattern = _buildPattern();
    if (pattern == null) {
      return const SizedBox.shrink();
    }

    return Card(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Preview',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              pattern.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              pattern.endDescription,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayShortName(DayOfWeek day) {
    switch (day) {
      case DayOfWeek.monday:
        return 'Mon';
      case DayOfWeek.tuesday:
        return 'Tue';
      case DayOfWeek.wednesday:
        return 'Wed';
      case DayOfWeek.thursday:
        return 'Thu';
      case DayOfWeek.friday:
        return 'Fri';
      case DayOfWeek.saturday:
        return 'Sat';
      case DayOfWeek.sunday:
        return 'Sun';
    }
  }

  RecurrencePattern? _buildPattern() {
    if (!_enabled) return null;

    // Validate days of week for weekly/biweekly
    if ((_frequency == RecurrenceFrequency.weekly ||
            _frequency == RecurrenceFrequency.biweekly) &&
        _selectedDays.isEmpty) {
      return null;
    }

    return RecurrencePattern(
      id: _uuid.v4(),
      frequency: _frequency,
      daysOfWeek: _selectedDays.toList(),
      endType: _endType,
      numberOfOccurrences:
          _endType == RecurrenceEndType.afterOccurrences ? _numberOfOccurrences : null,
      endDate: _endType == RecurrenceEndType.onDate ? _endDate : null,
      createdAt: DateTime.now(),
    );
  }

  void _notifyChange() {
    widget.onChanged(_buildPattern());
  }
}
