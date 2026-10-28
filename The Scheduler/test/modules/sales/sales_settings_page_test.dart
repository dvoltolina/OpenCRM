import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:the_scheduler/core/config/app_config.dart';
import 'package:the_scheduler/core/providers/providers.dart';
import 'package:the_scheduler/data/models/user_role.dart';
import 'package:the_scheduler/modules/sales/presentation/sales_settings_page.dart';

import '../../helpers/test_data_factories.dart';

void main() {
  group('SalesSettingsPage', () {
    late AppConfig testConfig;

    setUp(() {
      testConfig = TestData.createTestConfig();
    });

    testWidgets(
      'describes CRM as a configurable web handoff instead of a live sync state',
      (tester) async {
        final profile = UserProfile(
          id: 'sales-user',
          businessId: TestData.businessId,
          role: UserRole.sales,
          email: 'sales@example.com',
          displayName: 'Sales User',
          createdAt: TestData.testDate,
        );

        final container = ProviderContainer(
          overrides: [
            appConfigProvider.overrideWithValue(testConfig),
            currentUserProfileProvider.overrideWith(
              (ref) => Stream.value(profile),
            ),
            securityContextProvider.overrideWith(
              (ref) =>
                  Stream.value(TestData.securityContext(role: UserRole.sales)),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: SalesSettingsPage()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('CRM Web App'), findsOneWidget);
        expect(
          find.text(
            'Leads, deals, routes, and reporting stay in the CRM web app.',
          ),
          findsOneWidget,
        );
        expect(find.text('Open CRM Web App'), findsOneWidget);
        expect(find.text('Connected to CRM'), findsNothing);
        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Open CRM Web App'),
        );
        expect(button.onPressed, isNotNull);
      },
    );
  });
}
