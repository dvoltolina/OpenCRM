import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:the_scheduler/core/config/app_config.dart';
import 'package:the_scheduler/core/providers/providers.dart';
import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/modules/booking/presentation/widgets/booking_form_shell.dart';

import '../../../helpers/di_test_helpers.dart';
import '../../../helpers/test_data_factories.dart';

void main() {
  group('BookingFormShell DI Wiring', () {
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
    }) {
      return ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(testConfig),
          securityContextProvider.overrideWith(
            (ref) => Stream.value(securityContext),
          ),
          appointmentsRepositoryProvider.overrideWithValue(repos.appointments),
          clientsRepositoryProvider.overrideWithValue(repos.clients),
          providersRepositoryProvider.overrideWithValue(repos.providers),
          servicesRepositoryProvider.overrideWithValue(repos.services),
          locationsRepositoryProvider.overrideWithValue(repos.locations),
          availabilityRepositoryProvider.overrideWithValue(repos.availability),
          paymentRepositoryProvider.overrideWithValue(repos.payments),
        ],
      );
    }

    testWidgets('renders loading state while security context loads', (tester) async {
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
          child: const MaterialApp(
            home: Scaffold(body: BookingFormShell()),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      container.dispose();
    });

    testWidgets('renders sign-in message when no security context', (tester) async {
      final container = createTestContainer(securityContext: null);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: BookingFormShell()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sign in to manage bookings.'), findsOneWidget);

      container.dispose();
    });

    testWidgets('renders form when security context is available', (tester) async {
      final container = createTestContainer(securityContext: testSecurityContext);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: BookingFormShell()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should not show sign-in message
      expect(find.text('Sign in to manage bookings.'), findsNothing);
      // Should not show loading
      expect(find.byType(CircularProgressIndicator), findsNothing);

      container.dispose();
    });

    testWidgets('accepts debugSecurityContext override', (tester) async {
      // Even with null from provider, debugSecurityContext should work
      final container = createTestContainer(securityContext: null);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: BookingFormShell(
                debugSecurityContext: testSecurityContext,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render form, not sign-in message
      expect(find.text('Sign in to manage bookings.'), findsNothing);

      container.dispose();
    });

    testWidgets('consumes appConfigProvider for branding', (tester) async {
      final customConfig = testConfig.copyWith(
        branding: testConfig.branding.copyWith(productName: 'Test Scheduler'),
      );

      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(customConfig),
          securityContextProvider.overrideWith(
            (ref) => Stream.value(testSecurityContext),
          ),
          appointmentsRepositoryProvider.overrideWithValue(repos.appointments),
          clientsRepositoryProvider.overrideWithValue(repos.clients),
          providersRepositoryProvider.overrideWithValue(repos.providers),
          servicesRepositoryProvider.overrideWithValue(repos.services),
          locationsRepositoryProvider.overrideWithValue(repos.locations),
          availabilityRepositoryProvider.overrideWithValue(repos.availability),
          paymentRepositoryProvider.overrideWithValue(repos.payments),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: BookingFormShell()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Widget should render without errors when config is provided
      expect(find.byType(BookingFormShell), findsOneWidget);

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
        () => container.read(clientsRepositoryProvider),
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
      expect(
        () => container.read(appointmentsRepositoryProvider),
        returnsNormally,
      );
      expect(
        () => container.read(availabilityRepositoryProvider),
        returnsNormally,
      );
      expect(
        () => container.read(paymentRepositoryProvider),
        returnsNormally,
      );

      container.dispose();
    });
  });
}
