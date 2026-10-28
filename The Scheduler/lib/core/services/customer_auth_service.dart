import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/client.dart';
import '../../data/models/security_context.dart';
import '../../data/repositories/clients_repository.dart';
import 'encryption_service.dart';
import 'social_auth_service.dart';

/// Service for customer-specific authentication and account management.
///
/// This service handles:
/// - Customer account creation (email/password, social login)
/// - Linking Firebase Auth users to Client profiles
/// - Customer-specific security context creation
/// - Password reset and account recovery
/// - Magic link to account migration
///
/// **Integration with existing auth:**
/// - Uses Firebase Auth for authentication backend
/// - Links to Client records via userId field
/// - Creates SecurityContext with role = UserRole.client
/// - Separate from business user authentication
class CustomerAuthService {
  CustomerAuthService({
    FirebaseAuth? firebaseAuth,
    ClientsRepository? clientsRepository,
    FirebaseFunctions? firebaseFunctions,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _clientsRepository = clientsRepository ?? ClientsRepository(),
        _functions = firebaseFunctions ?? FirebaseFunctions.instance;

  final FirebaseAuth _firebaseAuth;
  final ClientsRepository _clientsRepository;
  final FirebaseFunctions _functions;

  /// Get current authenticated user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Watch authentication state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  // MARK: - Account Creation

  /// Create a new customer account with email and password.
  ///
  /// This will:
  /// 1. Create Firebase Auth user
  /// 2. Link to existing Client profile (if email matches)
  /// 3. Or create a new Client profile
  ///
  /// Returns the linked Client profile.
  Future<Client> createAccountWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String businessId,
    String? phone,
  }) async {
    try {
      // Create Firebase Auth user
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = credential.user!.uid;

      // Update display name
      await credential.user!.updateDisplayName('$firstName $lastName');

      // Create admin security context to create/update client
      final adminContext = SecurityContext(
        userId: userId,
        businessId: businessId,
        role: UserRole.admin, // Temporarily use admin to create client
      );

      // Check if client already exists with this email
      final existingClients = await _clientsRepository.getClients(adminContext);
      
      final existingClient = existingClients.cast<Client?>().firstWhere(
        (c) => c?.email?.toLowerCase() == email.toLowerCase(),
        orElse: () => null,
      );

      Client client;
      if (existingClient != null) {
        // Link existing client to user account
        client = existingClient.copyWith(
          userId: userId,
          updatedAt: DateTime.now(),
        );

        await _clientsRepository.updateClient(
          context: adminContext,
          client: client,
        );
      } else {
        // Create new client profile
        client = Client(
          id: userId, // Use Firebase UID as client ID for consistency
          businessId: businessId,
          firstName: firstName,
          lastName: lastName,
          email: email,
          phone: phone,
          userId: userId,
          createdAt: DateTime.now(),
        );

        await _clientsRepository.createClient(
          context: adminContext,
          client: client,
        );
      }

      unawaited(
        _logAuthenticationEvent(
          status: 'success',
          businessId: businessId,
          userId: userId,
        ),
      );

      return client;
    } on FirebaseAuthException catch (error) {
      unawaited(
        _logAuthenticationEvent(
          status: 'failure',
          businessId: businessId,
          failureReason: error.code,
        ),
      );
      rethrow;
    } catch (_) {
      unawaited(
        _logAuthenticationEvent(
          status: 'failure',
          businessId: businessId,
          failureReason: 'unknown',
        ),
      );
      rethrow;
    }
  }

  /// Sign in with email and password
  ///
  /// Returns the authenticated user's Client profile
  Future<Client> signInWithEmail({
    required String email,
    required String password,
    required String businessId,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = credential.user!.uid;

      // Get client profile by userId
      final client = await getClientForUserInBusiness(
        userId: userId,
        businessId: businessId,
      );

      if (client == null) {
        unawaited(
          _logAuthenticationEvent(
            status: 'failure',
            businessId: businessId,
            userId: userId,
            failureReason: 'client-profile-missing',
          ),
        );
        throw Exception(
          'Account found but customer profile is missing. '
          'Please contact support.',
        );
      }

      unawaited(
        _logAuthenticationEvent(
          status: 'success',
          businessId: businessId,
          userId: userId,
        ),
      );

      return client;
    } on FirebaseAuthException catch (error) {
      unawaited(
        _logAuthenticationEvent(
          status: 'failure',
          businessId: businessId,
          failureReason: error.code,
        ),
      );
      rethrow;
    } catch (_) {
      unawaited(
        _logAuthenticationEvent(
          status: 'failure',
          businessId: businessId,
          failureReason: 'unknown',
        ),
      );
      rethrow;
    }
  }

  /// Sign in with Google (placeholder for future implementation)
  Future<Client> signInWithGoogle({
    required String businessId,
    required SocialAuthService socialAuthService,
  }) async {
    final credential = await socialAuthService.signInWithGoogle();
    return _handleSocialSignIn(
      businessId: businessId,
      firebaseUser: credential.user,
    );
  }

  /// Sign in with Apple (placeholder for future implementation)
  Future<Client> signInWithApple({
    required String businessId,
    required SocialAuthService socialAuthService,
  }) async {
    final credential = await socialAuthService.signInWithApple();
    return _handleSocialSignIn(
      businessId: businessId,
      firebaseUser: credential.user,
    );
  }

  // MARK: - Password Management

  /// Send password reset email
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  /// Update password for current user
  Future<void> updatePassword({required String newPassword}) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in');
    }

    await user.updatePassword(newPassword);
  }

  // MARK: - Account Management

  /// Get customer security context for current user
  ///
  /// Returns null if not authenticated or no client profile found
  Future<SecurityContext?> getCustomerSecurityContext({
    required String businessId,
  }) async {
    final user = currentUser;
    if (user == null) return null;

    final client = await getClientForUserInBusiness(
      userId: user.uid,
      businessId: businessId,
    );

    if (client == null) return null;

    return SecurityContext(
      userId: user.uid,
      businessId: client.businessId,
      role: UserRole.client,
      clientId: client.id,
    );
  }

  /// Get client profile for current authenticated user
  Future<Client?> getCurrentClientProfile({
    required String businessId,
  }) async {
    final user = currentUser;
    if (user == null) return null;

    return getClientForUserInBusiness(
      userId: user.uid,
      businessId: businessId,
    );
  }

  /// Link magic link account to permanent customer account
  ///
  /// Use case: Customer clicked magic link multiple times and wants
  /// to create a permanent account for easy access.
  ///
  /// Steps:
  /// 1. Create Firebase Auth account
  /// 2. Link existing Client profile to new account
  Future<Client> linkMagicLinkToAccount({
    required String clientId,
    required String businessId,
    required String email,
    required String password,
  }) async {
    // Create admin context to fetch client
    final adminContext = SecurityContext(
      userId: 'system',
      businessId: businessId,
      role: UserRole.admin,
    );

    // Get existing client
    final client = await _clientsRepository.getClient(
      context: adminContext,
      clientId: clientId,
    );

    if (client == null) {
      throw Exception('Client profile not found');
    }

    // Create Firebase Auth user
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final userId = credential.user!.uid;

    // Update client with userId link
    final updatedClient = client.copyWith(
      userId: userId,
      updatedAt: DateTime.now(),
    );

    await _clientsRepository.updateClient(
      context: adminContext,
      client: updatedClient,
    );

    return updatedClient;
  }

  /// Sign out current user
  Future<void> signOut() async {
    EncryptionKeyManager.clearCache();
    await _firebaseAuth.signOut();
  }

  /// Delete customer account
  ///
  /// This will:
  /// 1. Delete Firebase Auth user
  /// 2. NOT delete Client profile (for business records)
  /// 3. Unlink userId from Client profile
  Future<void> deleteAccount({required String businessId}) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in');
    }

    final userId = user.uid;

    // Get client to unlink
    final client = await getClientForUserInBusiness(
      userId: userId,
      businessId: businessId,
    );
    
    if (client != null) {
      // Unlink userId from client profile
      final updatedClient = client.copyWith(
        userId: null,
        updatedAt: DateTime.now(),
      );

      final adminContext = SecurityContext(
        userId: userId,
        businessId: client.businessId,
        role: UserRole.admin,
      );

      await _clientsRepository.updateClient(
        context: adminContext,
        client: updatedClient,
      );
    }

    // Delete Firebase Auth account
    await user.delete();
  }

  // MARK: - Private Helpers

  /// Get client for user within a specific business
  Future<Client?> getClientForUserInBusiness({
    required String userId,
    required String businessId,
  }) async {
    final context = SecurityContext(
      userId: userId,
      businessId: businessId,
      role: UserRole.admin, // Use admin role to query
    );

    return await _clientsRepository.getClientByUserId(
      context: context,
      userId: userId,
    );
  }

  Future<void> _logAuthenticationEvent({
    required String status,
    required String businessId,
    String? userId,
    String? failureReason,
  }) async {
    try {
      final callable = _functions.httpsCallable('logAuthenticationEvent');
      final payload = <String, dynamic>{
        'status': status,
        'businessId': businessId,
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
      // Best-effort only; failures should not affect auth flow.
    }
  }

  Map<String, dynamic> _buildDeviceInfo() => <String, dynamic>{
    'platform': defaultTargetPlatform.name,
    'isWeb': kIsWeb,
  };

  Future<Client> _handleSocialSignIn({
    required String businessId,
    required User? firebaseUser,
  }) async {
    if (firebaseUser == null) {
      throw Exception('Sign-in failed: No user returned');
    }

    // Try to find existing client linked to this userId
    final existingClient = await _clientsRepository.getClientByUserId(
      context: SecurityContext(
        userId: firebaseUser.uid,
        businessId: businessId,
        role: UserRole.client,
      ),
      userId: firebaseUser.uid,
    );

    if (existingClient != null) {
      return existingClient;
    }

    // Create a new client profile
    final now = DateTime.now();
    final client = Client(
      id: firebaseUser.uid,
      businessId: businessId,
      firstName: firebaseUser.displayName ?? 'Client',
      lastName: '',
      email: firebaseUser.email,
      phone: firebaseUser.phoneNumber,
      address: null,
      tags: const [],
      lifecycle: ClientLifecycle.newClient,
      lastContactDate: null,
      lastAppointmentDate: null,
      preferences: const {},
      customFields: const {},
      createdAt: now,
      updatedAt: now,
      userId: firebaseUser.uid,
      hasPaymentMethod: false,
      stripeCustomerId: null,
      serviceLatitude: null,
      serviceLongitude: null,
      serviceNotes: null,
    );

    await _clientsRepository.createClient(
      context: SecurityContext(
        userId: firebaseUser.uid,
        businessId: businessId,
        role: UserRole.client,
      ),
      client: client,
    );

    return client;
  }
}
