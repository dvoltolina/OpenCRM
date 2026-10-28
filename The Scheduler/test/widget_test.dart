// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:the_scheduler/app.dart';
import 'package:the_scheduler/core/config/app_config.dart';

void main() {
  // Integration test - requires Firebase initialization
  // Run with: flutter test --tags=integration
  testWidgets(
    'bootstraps SchedulerApp without crashing',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: SchedulerApp(config: AppConfig.defaultClinic()),
        ),
      );
      await tester.pump();

      expect(find.byType(SchedulerApp), findsOneWidget);
    },
    skip: true,  // Requires Firebase initialization - run as integration test
  );
}
