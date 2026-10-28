import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:staff_app/data/local/staff_database.dart';
import 'package:staff_app/modules/schedule/presentation/week_schedule_page.dart';
import 'package:staff_app/modules/schedule/providers/week_providers.dart';

void main() {
  testWidgets('WeekSchedulePage shows empty state when no data',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weekAppointmentsProvider.overrideWith(
            (ref) => Stream.value(<DateTime, List<AppointmentsTableData>>{}),
          ),
        ],
        child: const MaterialApp(home: WeekSchedulePage()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('No appointments this week'), findsOneWidget);
  });
}
