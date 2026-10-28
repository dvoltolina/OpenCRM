import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../config/demo_config.dart';
import '../../data/models/security_context.dart';
import '../../data/models/user_role.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/business_repository.dart';
import '../../data/repositories/user_repository.dart';
import 'encryption_service.dart';

/// Exception thrown when a user needs to enroll in MFA before continuing.
/// This keeps the user signed in so they can complete enrollment.
class MfaEnrollmentRequiredException implements Exception {
  const MfaEnrollmentRequiredException({
    required this.userId,
    required this.userRole,
  });

  final String userId;
  final UserRole userRole;

  @override
  String toString() =>
      'MfaEnrollmentRequiredException: MFA enrollment required';
}

/// Service for managing authentication state and security context.
/// Provides a stream of SecurityContext that updates when auth state changes.
class AuthStateService {
  AuthStateService({
    AuthRepository? authRepository,
    UserRepository? userRepository,
    BusinessRepository? businessRepository,
    FirebaseFunctions? firebaseFunctions,
  }) : _authRepository = authRepository ?? AuthRepository(),
       _userRepository = userRepository ?? UserRepository(),
       _businessRepository = businessRepository ?? BusinessRepository(),
       _functions = firebaseFunctions ?? FirebaseFunctions.instance;

  /// Singleton instance for convenience access
  static final AuthStateService instance = AuthStateService();

  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final BusinessRepository _businessRepository;
  final FirebaseFunctions _functions;

  /// Stream of current authentication state.
  /// Emits User when authenticated, null when not authenticated.
  Stream<User?> get authStateChanges => _authRepository.watchUser();

  /// Get current Firebase Auth user (synchronous).
  User? get currentUser => _authRepository.currentUser;

  /// Get current user profile with security context.
  /// Returns null if not authenticated or profile not found.
  Future<UserProfile?> getCurrentUserProfile() async {
    if (DemoConfig.isDemoMode) {
      return DemoConfig.buildDemoUserProfile();
    }
    return _authRepository.getCurrentUserProfile();
  }

  /// Get current security context.
  /// Returns null if not authenticated or profile not found.
  Future<SecurityContext?> getCurrentSecurityContext() async {
    if (DemoConfig.isDemoMode) {
      return DemoConfig.buildDemoSecurityContext();
    }
    return _authRepository.getCurrentSecurityContext();
  }

  /// Stream that emits SecurityContext when user is authenticated with profile.
  /// Emits null when user is not authenticated or profile is missing.
  Stream<SecurityContext?> watchSecurityContext() async* {
    if (DemoConfig.isDemoMode) {
      yield DemoConfig.buildDemoSecurityContext();
      return;
    }

    await for (final user in authStateChanges) {
      if (user == null) {
        yield null;
      } else {
        final profile = await _authRepository.getCurrentUserProfile();
        if (profile != null) {
          yield SecurityContext.fromUserProfile(profile);
        } else {
          // User authenticated but no profile - this shouldn't happen
          // in production, but can occur during development
          yield null;
        }
      }
    }
  }

  /// Check if current user is authenticated.
  bool get isAuthenticated => DemoConfig.isDemoMode || currentUser != null;

  /// Sign out current user.
  Future<void> signOut() async {
    if (DemoConfig.isDemoMode) return;
    EncryptionKeyManager.clearCache();
    await _authRepository.signOut();
  }

  /// Register a new user and create their profile.
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String businessId,
    required UserRole role,
    required String displayName,
    String? providerId,
    String? clientId,
  }) async {
    if (DemoConfig.isDemoMode) {
      throw FirebaseAuthException(
        code: 'demo-mode-disabled',
        message: 'Account creation is disabled in demo mode.',
      );
    }
    return _authRepository.registerWithEmail(
      email: email,
      password: password,
      businessId: businessId,
      role: role,
      displayName: displayName,
      providerId: providerId,
      clientId: clientId,
    );
  }

  /// Sign in with email and password.
  /// Configures session persistence based on business HIPAA requirements:
  /// - HIPAA businesses: session-based (logged out when browser closes)
  /// - Non-HIPAA businesses: local persistence (stay logged in)
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (DemoConfig.isDemoMode) {
      throw FirebaseAuthException(
        code: 'demo-mode-disabled',
        message: 'Authentication is bypassed in demo mode.',
      );
    }
    try {
      final credential = await _authRepository.signInWithEmail(
        email: email,
        password: password,
      );

      // Configure persistence based on business HIPAA status
      await _configurePersistenceForUser(credential.user);

      await _enforceMfaIfRequired(credential);
      unawaited(
        _logAuthenticationEvent(
          status: 'success',
          userId: credential.user?.uid,
        ),
      );
      return credential;
    } on FirebaseAuthException catch (error) {
      unawaited(
        _logAuthenticationEvent(
          status: 'failure',
          userId: _authRepository.currentUser?.uid,
          failureReason: error.code,
        ),
      );
      rethrow;
    } catch (_) {
      unawaited(
        _logAuthenticationEvent(
          status: 'failure',
          userId: _authRepository.currentUser?.uid,
          failureReason: 'unknown',
        ),
      );
      rethrow;
    }
  }

  /// Configure session persistence based on user's business HIPAA requirements.
  Future<void> _configurePersistenceForUser(User? user) async {
    if (user == null) return;

    try {
      final profile = await _userRepository.getUserProfile(user.uid);
      if (profile == null) return;

      final business = await _businessRepository.getBusiness(
        profile.businessId,
      );
      if (business == null) return;

      // Configure persistence: HIPAA = session, non-HIPAA = local (stay logged in)
      await _authRepository.configurePersistence(
        requiresHipaa: business.requiresHipaaCompliance,
      );
    } catch (e) {
      // Best-effort: persistence configuration should not fail login
      debugPrint('Failed to configure persistence: $e');
    }
  }

  /// Sign in anonymously for demo mode.
  Future<UserCredential> signInAsDemo() async {
    if (DemoConfig.isDemoMode) {
      throw FirebaseAuthException(
        code: 'demo-mode-disabled',
        message: 'Open the demo directly. Sign-in is not required.',
      );
    }
    return _authRepository.signInAsDemo();
  }

  Future<void> _enforceMfaIfRequired(UserCredential credential) async {
    final user = credential.user;
    if (user == null) return;

    final profile = await _userRepository.getUserProfile(user.uid);
    if (profile == null) return;

    // Only admin/owner roles can be required to have MFA
    if (!_isAdminOrOwner(profile.role)) return;

    // Check if business has MFA enabled
    final business = await _businessRepository.getBusiness(profile.businessId);
    if (business == null || !business.mfaEnabled) return;

    final enrolled = await user.multiFactor.getEnrolledFactors();
    final hasMfa = enrolled.isNotEmpty;
    if (hasMfa) return;

    // User needs MFA but hasn't enrolled - keep them signed in
    // so they can complete enrollment process
    unawaited(
      _logAuthenticationEvent(
        status: 'mfa_enrollment_required',
        userId: user.uid,
        failureReason: 'mfa-not-enrolled',
      ),
    );
    throw MfaEnrollmentRequiredException(
      userId: user.uid,
      userRole: profile.role,
    );
  }

  bool _isAdminOrOwner(UserRole role) {
    return role == UserRole.owner || role == UserRole.admin;
  }

  Future<void> _logAuthenticationEvent({
    required String status,
    String? userId,
    String? failureReason,
  }) async {
    if (DemoConfig.isDemoMode) return;
    try {
      final callable = _functions.httpsCallable('logAuthenticationEvent');
      final payload = <String, dynamic>{
        'status': status,
        if (userId != null && userId.isNotEmpty) 'userId': userId,
        if (failureReason != null && failureReason.isNotEmpty)
          'failureReason': failureReason,
      };

      final deviceInfo = _buildDeviceInfo();
      if (deviceInfo.isNotEmpty) {
        payload['deviceInfo'] = deviceInfo;
      }

      await callable.call(payload);
    } catch (_) {
      // Best-effort: audit logging failures must not block authentication.
    }
  }

  Map<String, dynamic> _buildDeviceInfo() {
    return <String, dynamic>{
      'platform': defaultTargetPlatform.name,
      'isWeb': kIsWeb,
    };
  }
}
