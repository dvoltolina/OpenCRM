import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/core/config/app_config.dart';
import 'package:the_scheduler/core/providers/app_providers.dart';
import 'package:the_scheduler/core/providers/repository_providers.dart';
import 'package:the_scheduler/data/models/business_industry.dart';
import 'package:the_scheduler/data/models/user_role.dart' as user_role;
import 'package:the_scheduler/data/repositories/auth_repository.dart';
import 'package:the_scheduler/data/repositories/workspace_repository.dart';
import 'package:the_scheduler/modules/auth/presentation/register_page.dart';

class _FakeAuthRepository extends Fake implements AuthRepository {
  bool? configuredRequiresHipaa;

  @override
  Future<void> configurePersistence({required bool requiresHipaa}) async {
    configuredRequiresHipaa = requiresHipaa;
  }

  @override
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String businessId,
    required user_role.UserRole role,
    required String displayName,
    String? providerId,
    String? clientId,
  }) async {
    return _FakeUserCredential();
  }
}

class _FakeWorkspaceRepository extends Fake implements WorkspaceRepository {
  _FakeWorkspaceRepository({required this.requiresHipaa});

  final bool requiresHipaa;

  @override
  Future<CreateWorkspaceResponse> createWorkspace({
    required String businessName,
    required String ownerEmail,
    required String ownerDisplayName,
    String? industry,
    String? slug,
    bool? requiresHipaaCompliance,
    bool? mfaEnabled,
  }) async {
    return CreateWorkspaceResponse(
      workspaceId: 'ws1',
      businessId: 'biz1',
      inviteCode: 'INVITE',
      publicSlug: 'biz',
      publicBookingUrl: 'https://example.com',
      requiresHipaaCompliance: requiresHipaa,
      mfaEnabled: mfaEnabled ?? false,
    );
  }
}

class _FakeUserCredential extends Fake implements UserCredential {}

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
  testWidgets(
      'RegisterPage applies HIPAA session persistence for HIPAA industry',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final authRepo = _FakeAuthRepository();
    final workspaceRepo = _FakeWorkspaceRepository(requiresHipaa: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(_FakeAppConfig()),
          authRepositoryProvider.overrideWithValue(authRepo),
          workspaceRepositoryProvider.overrideWithValue(workspaceRepo),
        ],
        child: const MaterialApp(
          home: RegisterPage(initialIndustry: BusinessIndustry.healthcareMedical),
        ),
      ),
    );

    await tester.enterText(find.bySemanticsLabel('Full Name'), 'Owner');
    await tester.enterText(find.bySemanticsLabel('Email'), 'owner@example.com');
    await tester.enterText(find.bySemanticsLabel('Password'), 'password123');
    await tester.enterText(find.bySemanticsLabel('Confirm Password'), 'password123');
    await tester.enterText(find.bySemanticsLabel('Business Name'), 'Clinic');

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -800));
    await tester.pump();
    await tester.ensureVisible(find.text('Create Account').last);
    await tester.tap(find.text('Create Account').last);
    await tester.pumpAndSettle();
    // Allow async callbacks to complete
    for (var i = 0; i < 5 && authRepo.configuredRequiresHipaa == null; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(authRepo.configuredRequiresHipaa, isTrue);
  }, skip: true);

  testWidgets('RegisterPage uses local persistence for non-HIPAA industry',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final authRepo = _FakeAuthRepository();
    final workspaceRepo = _FakeWorkspaceRepository(requiresHipaa: false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(_FakeAppConfig()),
          authRepositoryProvider.overrideWithValue(authRepo),
          workspaceRepositoryProvider.overrideWithValue(workspaceRepo),
        ],
        child: const MaterialApp(
          home: RegisterPage(initialIndustry: BusinessIndustry.other),
        ),
      ),
    );

    await tester.enterText(find.bySemanticsLabel('Full Name'), 'Owner');
    await tester.enterText(find.bySemanticsLabel('Email'), 'owner@example.com');
    await tester.enterText(find.bySemanticsLabel('Password'), 'password123');
    await tester.enterText(find.bySemanticsLabel('Confirm Password'), 'password123');
    await tester.enterText(find.bySemanticsLabel('Business Name'), 'Clinic');

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -800));
    await tester.pump();
    await tester.ensureVisible(find.text('Create Account').last);
    await tester.tap(find.text('Create Account').last);
    await tester.pumpAndSettle();
    for (var i = 0; i < 5 && authRepo.configuredRequiresHipaa == null; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(authRepo.configuredRequiresHipaa, isFalse);
  }, skip: true);
}
