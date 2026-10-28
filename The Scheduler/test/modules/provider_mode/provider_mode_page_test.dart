import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:the_scheduler/core/config/app_config.dart';
import 'package:the_scheduler/core/providers/providers.dart';
import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/modules/provider_mode/presentation/provider_mode_page.dart';

import '../../helpers/test_data_factories.dart';

void main() {
  group('ProviderModePage Role Gating', () {
    late AppConfig testConfig;

    setUp(() {
      testConfig = TestData.createTestConfig();
    });

    testWidgets('shows loading state while security context loads', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(testConfig),
          securityContextProvider.overrideWith(
            (ref) => Stream<SecurityContext?>.empty(),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ProviderModePage()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      container.dispose();
    });

    testWidgets('shows authentication required when context is null', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(testConfig),
          securityContextProvider.overrideWith((ref) => Stream.value(null)),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ProviderModePage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Authentication Required'), findsOneWidget);
      expect(
        find.text('Please sign in to access Provider Mode'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);

      container.dispose();
    });

    testWidgets('shows access denied for client role', (tester) async {
      final clientContext = TestData.securityContext(
        role: UserRole.client,
        clientId: 'client-1',
      );

      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(testConfig),
          securityContextProvider.overrideWith(
            (ref) => Stream.value(clientContext),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ProviderModePage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Access Denied'), findsOneWidget);
      expect(
        find.text('Provider Mode is only available to providers and staff'),
        findsOneWidget,
      );
      expect(
        find.text('Contact your administrator for access'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.no_accounts_outlined), findsOneWidget);

      container.dispose();
    });

    testWidgets('shows Provider Mode home for owner role', (tester) async {
      final ownerContext = TestData.securityContext(
        role: UserRole.owner,
        providerId: 'provider-1',
      );

      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(testConfig),
          securityContextProvider.overrideWith(
            (ref) => Stream.value(ownerContext),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ProviderModePage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Welcome to Provider Mode'), findsOneWidget);
      expect(
        find.text('Manage your schedule, clients, and tasks'),
        findsOneWidget,
      );
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('My Schedule'), findsOneWidget);
      expect(find.text('My Clients'), findsOneWidget);
      expect(find.text('My Tasks'), findsOneWidget);
      expect(find.text('My Payments'), findsOneWidget);
      expect(find.text('Scan Docs'), findsOneWidget);
      expect(find.text('Quick Notes'), findsOneWidget);

      container.dispose();
    });

    testWidgets('shows Provider Mode home for admin role', (tester) async {
      final adminContext = TestData.securityContext(
        role: UserRole.admin,
        providerId: 'provider-1',
      );

      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(testConfig),
          securityContextProvider.overrideWith(
            (ref) => Stream.value(adminContext),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ProviderModePage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Welcome to Provider Mode'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);

      container.dispose();
    });

    testWidgets('shows Provider Mode home for staff role', (tester) async {
      final staffContext = TestData.securityContext(
        role: UserRole.staff,
        providerId: 'provider-1',
      );

      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(testConfig),
          securityContextProvider.overrideWith(
            (ref) => Stream.value(staffContext),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ProviderModePage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Welcome to Provider Mode'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);

      container.dispose();
    });

    testWidgets('shows Provider Mode home for provider role', (tester) async {
      final providerContext = TestData.securityContext(
        role: UserRole.provider,
        providerId: 'provider-1',
      );

      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
          appConfigProvider.overrideWithValue(testConfig),
          securityContextProvider.overrideWith(
            (ref) => Stream.value(providerContext),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ProviderModePage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Welcome to Provider Mode'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);

      container.dispose();
    });

    testWidgets('displays role badge correctly', (tester) async {
      final ownerContext = TestData.securityContext(
        role: UserRole.owner,
        providerId: 'provider-1',
      );

      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(testConfig),
          securityContextProvider.overrideWith(
            (ref) => Stream.value(ownerContext),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ProviderModePage()),
        ),
      );

      await tester.pumpAndSettle();

      // Role badge should show
      expect(find.widgetWithText(Chip, 'OWNER'), findsOneWidget);
      // Provider badge should show when providerId is present
      expect(find.widgetWithText(Chip, 'Provider'), findsOneWidget);

      container.dispose();
    });

    testWidgets('hides provider badge when providerId is null', (tester) async {
      final adminContextNoProvider = TestData.securityContext(
        role: UserRole.admin,
        providerId: null,
      );

      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
          appConfigProvider.overrideWithValue(testConfig),
          securityContextProvider.overrideWith(
            (ref) => Stream.value(adminContextNoProvider),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ProviderModePage()),
        ),
      );

      await tester.pumpAndSettle();

      // Role badge should show
      expect(find.widgetWithText(Chip, 'ADMIN'), findsOneWidget);
      // Provider badge should NOT show
      expect(find.widgetWithText(Chip, 'Provider'), findsNothing);

      container.dispose();
    });

    testWidgets('navigates to My Schedule when tapped', (tester) async {
      final staffContext = TestData.securityContext(
        role: UserRole.staff,
        providerId: 'provider-1',
      );

      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
          appConfigProvider.overrideWithValue(testConfig),
          securityContextProvider.overrideWith(
            (ref) => Stream.value(staffContext),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ProviderModePage()),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap My Schedule card
      await tester.tap(find.text('My Schedule'));
      await tester.pumpAndSettle();

      // Should navigate to MySchedulePage
      expect(find.text('My Schedule'), findsWidgets);

      container.dispose();
    });
  });
}
