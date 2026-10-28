import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:the_scheduler/core/config/app_config.dart';
import 'package:the_scheduler/core/providers/providers.dart';
import 'package:the_scheduler/data/models/user_role.dart';
import 'package:the_scheduler/modules/provider/presentation/provider_home_shell.dart';
import 'package:the_scheduler/modules/provider_mode/presentation/provider_mode_page.dart';

import '../../helpers/test_data_factories.dart';

void main() {
  group('ProviderHomeShell', () {
    late AppConfig testConfig;

    setUp(() {
      testConfig = TestData.createTestConfig();
    });

    testWidgets('forwards legacy provider shell to Provider Mode', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
          appConfigProvider.overrideWithValue(testConfig),
          securityContextProvider.overrideWith(
            (ref) => Stream.value(
              TestData.securityContext(
                role: UserRole.provider,
                providerId: 'provider-1',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ProviderHomeShell()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProviderModePage), findsOneWidget);
      expect(find.text('Welcome to Provider Mode'), findsOneWidget);
    });
  });
}
