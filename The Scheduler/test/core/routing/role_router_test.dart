import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:the_scheduler/core/config/app_config.dart';
import 'package:the_scheduler/core/providers/providers.dart';
import 'package:the_scheduler/core/routing/role_router.dart';
import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/data/models/user_role.dart';
import 'package:the_scheduler/modules/auth/presentation/login_page.dart';
import 'package:the_scheduler/modules/provider_mode/presentation/provider_mode_page.dart';

import '../../helpers/test_data_factories.dart';

void main() {
  group('RoleRouter', () {
    late AppConfig testConfig;

    setUp(() {
      testConfig = TestData.createTestConfig();
    });

    testWidgets('shows login page when no authenticated profile exists', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(testConfig),
          currentUserProfileProvider.overrideWith((ref) => Stream.value(null)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: RoleRouter()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('routes provider role into Provider Mode', (tester) async {
      await _pumpRoleRouter(
        tester,
        testConfig: testConfig,
        profile: _buildProfile(UserRole.provider, providerId: 'provider-1'),
        securityContext: TestData.securityContext(
          role: UserRole.provider,
          providerId: 'provider-1',
        ),
      );

      expect(find.byType(ProviderModePage), findsOneWidget);
      expect(find.text('Welcome to Provider Mode'), findsOneWidget);
    });

    testWidgets('routes staff role into Provider Mode', (tester) async {
      await _pumpRoleRouter(
        tester,
        testConfig: testConfig,
        profile: _buildProfile(UserRole.staff, providerId: 'provider-1'),
        securityContext: TestData.securityContext(
          role: UserRole.staff,
          providerId: 'provider-1',
        ),
      );

      expect(find.byType(ProviderModePage), findsOneWidget);
      expect(find.text('Welcome to Provider Mode'), findsOneWidget);
    });
  });
}

Future<void> _pumpRoleRouter(
  WidgetTester tester, {
  required AppConfig testConfig,
  required UserProfile profile,
  required SecurityContext securityContext,
}) async {
  final container = ProviderContainer(
    overrides: [
      firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
      appConfigProvider.overrideWithValue(testConfig),
      currentUserProfileProvider.overrideWith((ref) => Stream.value(profile)),
      securityContextProvider.overrideWith(
        (ref) => Stream.value(securityContext),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: RoleRouter()),
    ),
  );
  await tester.pumpAndSettle();
}

UserProfile _buildProfile(UserRole role, {String? providerId}) {
  return UserProfile(
    id: 'user-${role.name}',
    businessId: TestData.businessId,
    role: role,
    providerId: providerId,
    createdAt: TestData.testDate,
  );
}
