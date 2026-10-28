import 'package:flutter/material.dart';

import 'widgets/provider_appointment_card.dart';
import 'provider_today_page.dart';

class ProviderWeekPage extends StatefulWidget {
  const ProviderWeekPage({super.key});

  @override
  State<ProviderWeekPage> createState() => _ProviderWeekPageState();
}

class _ProviderWeekPageState extends State<ProviderWeekPage> {
  DateTime _anchor = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final weekStart = _anchor.subtract(Duration(days: _anchor.weekday - 1));
    final weekDays = List.generate(
      7,
      (i) => DateTime(weekStart.year, weekStart.month, weekStart.day + i),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_weekLabel(weekStart)),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() => _anchor = _anchor.subtract(const Duration(days: 7))),
          ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () => setState(() => _anchor = DateTime.now()),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() => _anchor = _anchor.add(const Duration(days: 7))),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: weekDays.length,
        itemBuilder: (context, index) {
          final day = weekDays[index];
          final dayAppointments = _weekAppointments
              .where((a) =>
                  a.start.year == day.year &&
                  a.start.month == day.month &&
                  a.start.day == day.day)
              .toList();

          return ExpansionTile(
            initiallyExpanded: _isSameDay(day, DateTime.now()),
            title: Row(
              children: [
                Expanded(child: Text(_dayLabel(day))),
                if (dayAppointments.isNotEmpty)
                  Chip(
                    label: Text('${dayAppointments.length}'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            children: dayAppointments.isEmpty
                ? [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No appointments'),
                    )
                  ]
                : dayAppointments
                    .map(
                      (appt) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: ProviderAppointmentCard(
                          appointment: appt,
                          onTap: () {},
                          onNavigate: () {},
                        ),
                      ),
                    )
                    .toList(),
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _weekLabel(DateTime start) {
    final end = start.add(const Duration(days: 6));
    return '${_monthDay(start)} - ${_monthDay(end)}';
  }

  String _monthDay(DateTime d) => '${d.month}/${d.day}';

  String _dayLabel(DateTime d) {
    const weekdayNames = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    final name = weekdayNames[d.weekday - 1];
    return '$name ${d.month}/${d.day}';
  }
}

// Sample data reused from today view
final _now = DateTime.now();
final _weekAppointments = [
  SampleAppointment(
    id: 'w1',
    service: 'Home Cleaning',
    clientName: 'Jordan Lee',
    address: '123 Main St, Springfield',
    start: DateTime(_now.year, _now.month, _now.day, 9, 0),
    end: DateTime(_now.year, _now.month, _now.day, 10, 0),
    status: 'confirmed',
  ),
  SampleAppointment(
    id: 'w2',
    service: 'Window Wash',
    clientName: 'Avery Chen',
    address: '456 Pine Ave, Springfield',
    start: DateTime(_now.year, _now.month, _now.day + 1, 11, 0),
    end: DateTime(_now.year, _now.month, _now.day + 1, 12, 0),
    status: 'pending',
  ),
  SampleAppointment(
    id: 'w3',
    service: 'Deep Clean',
    clientName: 'Sam Patel',
    address: '789 Oak Rd, Springfield',
    start: DateTime(_now.year, _now.month, _now.day + 2, 14, 0),
    end: DateTime(_now.year, _now.month, _now.day + 2, 15, 30),
    status: 'confirmed',
  ),
];
