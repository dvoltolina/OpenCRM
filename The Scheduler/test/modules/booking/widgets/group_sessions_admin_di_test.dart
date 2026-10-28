import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:the_scheduler/core/config/app_config.dart';
import 'package:the_scheduler/core/providers/providers.dart';
import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/data/models/service.dart';
import 'package:the_scheduler/data/models/provider.dart' as provider_model;
import 'package:the_scheduler/data/models/location.dart';
import 'package:the_scheduler/modules/booking/presentation/group_sessions_admin_page.dart';

import '../../../helpers/di_test_helpers.dart';
import '../../../helpers/test_data_factories.dart';

void main() {
  group('GroupSessionsAdminPage DI Wiring', () {
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
          // Repository providers
          appointmentsRepositoryProvider.overrideWithValue(repos.appointments),
          providersRepositoryProvider.overrideWithValue(repos.providers),
          servicesRepositoryProvider.overrideWithValue(repos.services),
          locationsRepositoryProvider.overrideWithValue(repos.locations),
          availabilityRepositoryProvider.overrideWithValue(repos.availability),
          paymentRepositoryProvider.overrideWithValue(repos.payments),
          waitlistRepositoryProvider.overrideWithValue(repos.waitlist),
          fileAttachmentRepositoryProvider.overrideWithValue(repos.fileAttachments),
          // Stream providers - override with empty streams for testing
          servicesStreamProvider.overrideWith(
            (ref, ctx) => Stream.value(<Service>[]),
          ),
          providersStreamProvider.overrideWith(
            (ref, ctx) => Stream.value(<provider_model.Provider>[]),
          ),
          locationsStreamProvider.overrideWith(
            (ref, ctx) => Stream.value(<Location>[]),
          ),
        ],
      );
    }

    testWidgets('renders loading state while security context loads', (tester) async {
      final container = createTestContainer(
        securityContext: null,
        emitSecurityContext: false,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: GroupSessionsAdminPage(),
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
            home: GroupSessionsAdminPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sign in to manage group sessions.'), findsOneWidget);

      container.dispose();
    });

    testWidgets('renders page when security context available', (tester) async {
      final container = createTestContainer(securityContext: testSecurityContext);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: GroupSessionsAdminPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should not show sign-in message
      expect(find.text('Sign in to manage group sessions.'), findsNothing);
      // Page should be rendered
      expect(find.byType(GroupSessionsAdminPage), findsOneWidget);

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
        () => container.read(paymentRepositoryProvider),
        returnsNormally,
      );
      expect(
        () => container.read(fileAttachmentRepositoryProvider),
        returnsNormally,
      );
      expect(
        () => container.read(waitlistRepositoryProvider),
        returnsNormally,
      );

      container.dispose();
    });

    test('stream providers are accessible', () {
      final container = createTestContainer(securityContext: testSecurityContext);

      // Verify stream providers work with security context
      expect(
        () => container.read(servicesStreamProvider(testSecurityContext)),
        returnsNormally,
      );
      expect(
        () => container.read(providersStreamProvider(testSecurityContext)),
        returnsNormally,
      );
      expect(
        () => container.read(locationsStreamProvider(testSecurityContext)),
        returnsNormally,
      );

      container.dispose();
    });
  });
}
