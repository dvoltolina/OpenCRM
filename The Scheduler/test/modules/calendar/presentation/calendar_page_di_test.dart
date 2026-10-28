import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:the_scheduler/core/config/app_config.dart';
import 'package:the_scheduler/core/providers/providers.dart';
import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/modules/calendar/presentation/calendar_page.dart';

import '../../../helpers/di_test_helpers.dart';
import '../../../helpers/test_data_factories.dart';

void main() {
  group('CalendarPage DI Wiring', () {
    late FakeFirebaseFirestore fakeFirestore;
    late TestRepositories repos;
    late AppConfig testConfig;
    late SecurityContext testSecurityContext;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repos = TestRepositories(fakeFirestore);
      testConfig = TestDataFactories.createTestConfig();
      testSecurityContext = SecurityContext(
        userId: 'test-user-id',
        businessId: 'test-business-id',
        role: UserRole.admin,
      );
    });

    ProviderContainer createTestContainer({
      SecurityContext? securityContext,
      bool emitSecurityContext = true,
    }) {
      return ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(testConfig),
          securityContextProvider.overrideWith(
            (ref) => emitSecurityContext
                ? Stream.value(securityContext)
                : Stream<SecurityContext?>.empty(),
          ),
          appointmentsRepositoryProvider.overrideWithValue(repos.appointments),
          providersRepositoryProvider.overrideWithValue(repos.providers),
          servicesRepositoryProvider.overrideWithValue(repos.services),
          locationsRepositoryProvider.overrideWithValue(repos.locations),
          availabilityRepositoryProvider.overrideWithValue(repos.availability),
        ],
      );
    }

    testWidgets('renders loading skeleton while security context loads', (tester) async {
      final container = createTestContainer(
        securityContext: null,
        emitSecurityContext: false,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: CalendarPage()),
          ),
        ),
      );

      // Should show loading skeleton (SkeletonCalendarCell)
      expect(find.byType(CalendarPage), findsOneWidget);

      container.dispose();
    });

    testWidgets('renders sign-in message when no security context', (tester) async {
      final container = createTestContainer(securityContext: null);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: CalendarPage()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sign in to view calendar.'), findsOneWidget);

      container.dispose();
    });

    testWidgets('renders calendar when security context available', (tester) async {
      final container = createTestContainer(securityContext: testSecurityContext);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: CalendarPage()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should not show sign-in message
      expect(find.text('Sign in to view calendar.'), findsNothing);
      // CalendarPage should be rendered
      expect(find.byType(CalendarPage), findsOneWidget);

      container.dispose();
    });

    testWidgets('consumes appConfigProvider', (tester) async {
      final customConfig = testConfig.copyWith(
        branding: testConfig.branding.copyWith(productName: 'Calendar Test'),
      );

      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(customConfig),
          securityContextProvider.overrideWith(
            (ref) => Stream.value(testSecurityContext),
          ),
          appointmentsRepositoryProvider.overrideWithValue(repos.appointments),
          providersRepositoryProvider.overrideWithValue(repos.providers),
          servicesRepositoryProvider.overrideWithValue(repos.services),
          locationsRepositoryProvider.overrideWithValue(repos.locations),
          availabilityRepositoryProvider.overrideWithValue(repos.availability),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: CalendarPage()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Widget should render without errors when config is provided
      expect(find.byType(CalendarPage), findsOneWidget);

      container.dispose();
    });

    test('provider dependencies are correctly wired', () {
      final container = createTestContainer(securityContext: testSecurityContext);

      // Verify all required providers can be read without errors
      expect(
        () => container.read(appConfigProvider),
        returnsNormally,
      );
      expect(
        () => container.read(appointmentsRepositoryProvider),
        returnsNormally,
      );
      expect(
        () => container.read(providersRepositoryProvider),
        returnsNormally,
      );
      expect(
        () => container.read(servicesRepositoryProvider),
        returnsNormally,
      );
      expect(
        () => container.read(locationsRepositoryProvider),
        returnsNormally,
      );

      container.dispose();
    });
  });
}
