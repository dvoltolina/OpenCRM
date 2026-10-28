import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/demo_config.dart';
import '../models/user_role.dart';
import '../models/security_context.dart';
import 'user_repository.dart';

/// Repository for Firebase Authentication operations.
/// Works in conjunction with UserRepository for RBAC.
/// Implements persistence handling based on HIPAA requirements.
class AuthRepository {
  AuthRepository({FirebaseAuth? firebaseAuth, UserRepository? userRepository})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _userRepository = userRepository ?? UserRepository();

  final FirebaseAuth _firebaseAuth;
  final UserRepository _userRepository;

  /// Configure session persistence based on HIPAA requirements.
  /// HIPAA businesses use session-based persistence (logged out when browser closes).
  /// Non-HIPAA businesses use local persistence (stay logged in).
  Future<void> configurePersistence({required bool requiresHipaa}) async {
    // Persistence only applies to web platform
    if (kIsWeb) {
      try {
        if (requiresHipaa) {
          // HIPAA compliant: session-based persistence (logged out when browser closes)
          await _firebaseAuth.setPersistence(Persistence.SESSION);
        } else {
          // Non-HIPAA: local persistence (stay logged in across sessions)
          await _firebaseAuth.setPersistence(Persistence.LOCAL);
        }
      } catch (e) {
        // Persistence configuration is best-effort, don't fail login
        debugPrint('Failed to configure persistence: $e');
      }
    }
    // For mobile platforms, Firebase handles persistence automatically
    // and uses secure storage by default
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Update last login (non-blocking - don't fail login if this fails)
    if (credential.user != null) {
      try {
        await _userRepository.updateLastLogin(credential.user!.uid);
      } catch (_) {
        // Best effort - login should succeed even if lastLogin update fails
      }
    }

    return credential;
  }

  /// Sign in anonymously for demo purposes
  Future<UserCredential> signInAsDemo() {
    return _firebaseAuth.signInAnonymously();
  }

  /// Sign out
  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }

  /// Watch authentication state changes
  Stream<User?> watchUser() => _firebaseAuth.authStateChanges();

  /// Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Get user profile with security context
  Future<UserProfile?> getCurrentUserProfile() async {
    if (DemoConfig.isDemoMode) {
      return DemoConfig.buildDemoUserProfile();
    }
    final user = currentUser;
    if (user == null) return null;
    final profile = await _userRepository.getUserProfile(user.uid);
    if (_hasResolvedBusiness(profile)) {
      return profile;
    }

    final claimsProfile = await _buildProfileFromClaims(user);
    if (claimsProfile != null) {
      return claimsProfile;
    }

    return profile;
  }

  /// Get current security context (combines auth + user profile)
  Future<SecurityContext?> getCurrentSecurityContext() async {
    if (DemoConfig.isDemoMode) {
      return DemoConfig.buildDemoSecurityContext();
    }
    final profile = await getCurrentUserProfile();
    if (profile == null) return null;
    return SecurityContext.fromUserProfile(profile);
  }

  /// Refreshes the current user's ID token so newly issued claims are visible.
  Future<void> refreshCurrentUserToken() async {
    final user = currentUser;
    if (user == null) return;
    await user.getIdToken(true);
  }

  /// Register a new user with role assignment
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String businessId,
    required UserRole role,
    required String displayName,
    String? providerId,
    String? clientId,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user != null) {
      // Update display name
      await credential.user!.updateDisplayName(displayName);

      // Create user profile with RBAC
      final profile = UserProfile(
        id: credential.user!.uid,
        businessId: businessId,
        role: role,
        providerId: providerId,
        clientId: clientId,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
      );

      // Note: This bypasses security context since we're creating the initial user
      // In production, this should only be callable by admins or during onboarding
      await _userRepository.upsertUserProfile(
        context: SecurityContext(
          userId: credential.user!.uid,
          businessId: businessId,
          role: UserRole.owner, // Temporary context for creation
        ),
        profile: profile,
      );
    }

    return credential;
  }

  bool _hasResolvedBusiness(UserProfile? profile) {
    return profile != null &&
        profile.businessId.isNotEmpty &&
        profile.businessId != 'pending';
  }

  Future<UserProfile?> _buildProfileFromClaims(User user) async {
    try {
      final tokenResult = await user.getIdTokenResult();
      final claims = tokenResult.claims;
      if (claims == null) return null;

      final businessId = claims['businessId'] as String?;
      final roleName = claims['role'] as String?;
      if (businessId == null || businessId.isEmpty) {
        return null;
      }

      final role = parseUserRole(roleName);

      return UserProfile(
        id: user.uid,
        businessId: businessId,
        role: role,
        providerId: claims['providerId'] as String?,
        clientId: claims['clientId'] as String?,
        email: user.email,
        displayName: user.displayName,
        createdAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}
