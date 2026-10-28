import 'package:firebase_core/firebase_core.dart';

import '../../data/models/business.dart';
import '../../data/models/business_industry.dart';
import '../../data/models/security_context.dart';
import '../../data/models/user_role.dart';

class DemoConfig {
  static const bool isDemoMode = bool.fromEnvironment(
    'DEMO_MODE',
    defaultValue: false,
  );

  static const String demoBusinessId = String.fromEnvironment(
    'DEMO_BUSINESS_ID',
    defaultValue: 'demo-business-001',
  );

  static const String demoUserId = 'demo-user-001';
  static const String demoUserEmail = 'demo@example.com';
  static const String demoUserName = 'Demo User';
  static const String demoBusinessName = 'Scheduler Demo Studio';
  static const String demoBannerText =
      'Demo Mode - Sample data only. No changes will be saved.';
  static const String demoDisabledMessage =
      'This action is disabled in demo mode.';

  static const String demoSignUpUrl = String.fromEnvironment(
    'DEMO_SIGN_UP_URL',
    defaultValue: '',
  );

  static const String _apiKey = String.fromEnvironment(
    'DEMO_FIREBASE_API_KEY',
    defaultValue: '',
  );
  static const String _appId = String.fromEnvironment(
    'DEMO_FIREBASE_APP_ID',
    defaultValue: '',
  );
  static const String _messagingSenderId = String.fromEnvironment(
    'DEMO_FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '',
  );
  static const String _projectId = String.fromEnvironment(
    'DEMO_FIREBASE_PROJECT_ID',
    defaultValue: '',
  );
  static const String _authDomain = String.fromEnvironment(
    'DEMO_FIREBASE_AUTH_DOMAIN',
    defaultValue: '',
  );
  static const String _storageBucket = String.fromEnvironment(
    'DEMO_FIREBASE_STORAGE_BUCKET',
    defaultValue: '',
  );
  static const String _databaseUrl = String.fromEnvironment(
    'DEMO_FIREBASE_DATABASE_URL',
    defaultValue: '',
  );
  static const String _iosBundleId = String.fromEnvironment(
    'DEMO_FIREBASE_IOS_BUNDLE_ID',
    defaultValue: '',
  );
  static const String _androidClientId = String.fromEnvironment(
    'DEMO_FIREBASE_ANDROID_CLIENT_ID',
    defaultValue: '',
  );
  static const String _iosClientId = String.fromEnvironment(
    'DEMO_FIREBASE_IOS_CLIENT_ID',
    defaultValue: '',
  );

  static bool get hasFirebaseOverrides =>
      _apiKey.isNotEmpty &&
      _appId.isNotEmpty &&
      _messagingSenderId.isNotEmpty &&
      _projectId.isNotEmpty;

  static FirebaseOptions get firebaseOptions {
    if (!hasFirebaseOverrides) {
      throw StateError(
        'Demo Firebase configuration is missing. Provide DEMO_FIREBASE_* '
        'dart-defines before launching demo mode.',
      );
    }

    return FirebaseOptions(
      apiKey: _apiKey,
      appId: _appId,
      messagingSenderId: _messagingSenderId,
      projectId: _projectId,
      authDomain: _authDomain.isEmpty ? null : _authDomain,
      storageBucket: _storageBucket.isEmpty ? null : _storageBucket,
      databaseURL: _databaseUrl.isEmpty ? null : _databaseUrl,
      iosBundleId: _iosBundleId.isEmpty ? null : _iosBundleId,
      androidClientId: _androidClientId.isEmpty ? null : _androidClientId,
      iosClientId: _iosClientId.isEmpty ? null : _iosClientId,
    );
  }

  static UserProfile buildDemoUserProfile() {
    return UserProfile(
      id: demoUserId,
      businessId: demoBusinessId,
      role: UserRole.owner,
      email: demoUserEmail,
      displayName: demoUserName,
      createdAt: DateTime.utc(2026, 3, 8),
    );
  }

  static SecurityContext buildDemoSecurityContext() {
    return SecurityContext.fromUserProfile(buildDemoUserProfile());
  }

  static Business buildDemoBusiness() {
    return Business(
      id: demoBusinessId,
      name: demoBusinessName,
      description: 'Public read-only demo tenant',
      contactEmail: demoUserEmail,
      createdAt: DateTime.utc(2026, 3, 8),
      industry: BusinessIndustry.other,
      requiresHipaaCompliance: false,
      mfaEnabled: false,
    );
  }
}
