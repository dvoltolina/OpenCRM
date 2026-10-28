import 'package:flutter_test/flutter_test.dart';

import 'package:staff_app/modules/schedule/providers/week_providers.dart';

void main() {
  group('startOfWeek', () {
    test('returns Monday for mid-week date', () {
      final date = DateTime(2024, 11, 27); // Wednesday
      final start = startOfWeek(date);
      expect(start.weekday, DateTime.monday);
      expect(start.day, 25);
    });
  });

  group('week navigation bounds', () {
    test('earliest and latest windows are consistent', () {
      final now = DateTime(2024, 11, 27); // Wednesday
      final earliest = startOfWeek(now);
      final latest = startOfWeek(now.add(const Duration(days: 7)));
      expect(latest.isAfter(earliest), isTrue);
    });
  });
}
