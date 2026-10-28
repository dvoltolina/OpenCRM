import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/core/config/app_config.dart';
import 'package:the_scheduler/core/providers/app_providers.dart';
import 'package:the_scheduler/core/providers/repository_providers.dart';
import 'package:the_scheduler/data/repositories/auth_repository.dart';
import 'package:the_scheduler/modules/auth/presentation/staff_join_page.dart';

class _FakeAuthRepository extends Fake implements AuthRepository {
  bool? configuredRequiresHipaa;

  @override
  Future<void> configurePersistence({required bool requiresHipaa}) async {
    configuredRequiresHipaa = requiresHipaa;
  }
}

class _FakeFirebaseAuth extends Fake implements FirebaseAuth {
  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return _FakeUserCredential();
  }
}

class _FakeUserCredential extends Fake implements UserCredential {
  @override
  final User? user = _FakeUser();
}

class _FakeUser extends Fake implements User {
  @override
  Future<void> updateDisplayName(String? displayName) async {}
}

class _FakeAppConfig extends AppConfig {
  _FakeAppConfig()
      : super(
          branding: AppConfig.defaultClinic().branding,
          featureFlags: AppConfig.defaultClinic().featureFlags,
          bookingPolicies: AppConfig.defaultClinic().bookingPolicies,
          modules: AppConfig.defaultClinic().modules,
          serviceCatalog: const [],
          defaultTimeZone: 'UTC',
          communicationConfig: AppConfig.defaultClinic().communicationConfig,
          paymentConfig: AppConfig.defaultClinic().paymentConfig,
          integrationConfig: AppConfig.defaultClinic().integrationConfig,
        );
}

void main() {
  testWidgets('StaffJoinPage validates code and applies HIPAA persistence',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final authRepo = _FakeAuthRepository();
    Map<String, dynamic>? capturedJoinPayload;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(_FakeAppConfig()),
          authRepositoryProvider.overrideWithValue(authRepo),
        ],
        child: MaterialApp(
          home: StaffJoinPage(
            isAdmin: true,
            firebaseAuthOverride: _FakeFirebaseAuth(),
            validateInviteCodeOverride: (_) async => {
              'valid': true,
              'businessName': 'Clinic',
              'requiresHipaaCompliance': true,
              'mfaEnabled': false,
            },
            requestJoinOverride: (payload) async {
              capturedJoinPayload = payload;
              return {'success': true, 'requiresApproval': false};
            },
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, 'INVITE');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Account form should be visible after validation
    expect(find.text('Create Your Account'), findsOneWidget);

    // Fill account form
    await tester.enterText(find.bySemanticsLabel('Full Name'), 'Admin');
    await tester.enterText(find.bySemanticsLabel('Email'), 'admin@example.com');
    await tester.enterText(find.bySemanticsLabel('Password'), 'password123');
    await tester.enterText(find.bySemanticsLabel('Confirm Password'), 'password123');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create Account'));
    await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
    await tester.pumpAndSettle();

    // Persistence should be configured for HIPAA
    expect(authRepo.configuredRequiresHipaa, isTrue);
    // Request payload should capture the uppercase code and email
    expect(capturedJoinPayload?['code'], 'INVITE');
    expect(capturedJoinPayload?['email'], 'admin@example.com');
  });
}
