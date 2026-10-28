import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/staff_user.dart';

/// Custom exception for authentication errors.
class StaffAuthException implements Exception {
  const StaffAuthException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'StaffAuthException: $message';

  /// Common error messages for display.
  static const String invalidCredentials = 'Invalid email or password';
  static const String userNotFound = 'No account found with this email';
  static const String wrongPassword = 'Incorrect password';
  static const String tooManyAttempts = 'Too many attempts. Please try again later';
  static const String networkError = 'Network error. Please check your connection';
  static const String notStaffRole = 'This account is not authorized for staff access';
  static const String accountDisabled = 'This account has been disabled';
}

/// Service for handling staff authentication with Firebase Auth.
///
/// Provides sign in/out functionality, verifies staff role,
/// and manages user profile data from Firestore.
class StaffAuthService {
  StaffAuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Cached staff user profile.
  StaffUser? _cachedUser;

  /// Gets the currently cached user.
  StaffUser? get currentUser => _cachedUser;

  /// Signs in a staff member with email and password.
  ///
  /// Authenticates with Firebase Auth, then verifies the user has
  /// a staff/provider/admin role in Firestore.
  ///
  /// Throws [StaffAuthException] if authentication fails or user
  /// doesn't have staff role.
  Future<StaffUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Authenticate with Firebase
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const StaffAuthException(
          StaffAuthException.invalidCredentials,
          code: 'auth-failed',
        );
      }

      // Verify user has staff role and load profile
      final staffUser = await _loadStaffProfile(user.uid);
      if (staffUser == null) {
        // Sign out if not a valid staff user
        await _auth.signOut();
        throw const StaffAuthException(
          StaffAuthException.notStaffRole,
          code: 'not-staff',
        );
      }

      _cachedUser = staffUser;
      return staffUser;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  /// Signs out the current user.
  ///
  /// If [clearLocalData] is true (default), any callback registered
  /// should clear local database. This is handled by the caller.
  Future<void> signOut({bool clearLocalData = true}) async {
    _cachedUser = null;
    await _auth.signOut();
  }

  /// Gets the current authenticated user.
  ///
  /// Returns cached user if available, otherwise loads from Firestore.
  /// Returns null if not authenticated.
  Future<StaffUser?> getCurrentUser() async {
    if (_cachedUser != null) {
      return _cachedUser;
    }

    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    final staffUser = await _loadStaffProfile(user.uid);
    _cachedUser = staffUser;
    return staffUser;
  }

  /// Watches authentication state changes.
  ///
  /// Emits [StaffUser] when signed in and profile is valid,
  /// null when signed out or user doesn't have staff role.
  Stream<StaffUser?> watchAuthState() {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) {
        _cachedUser = null;
        return null;
      }

      final staffUser = await _loadStaffProfile(user.uid);
      _cachedUser = staffUser;
      return staffUser;
    });
  }

  /// Refreshes the staff profile from Firestore.
  ///
  /// Updates the cached user with latest data.
  /// Returns null if not authenticated or profile not found.
  Future<StaffUser?> refreshProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      _cachedUser = null;
      return null;
    }

    final staffUser = await _loadStaffProfile(user.uid);
    _cachedUser = staffUser;
    return staffUser;
  }

  /// Sends a password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  /// Loads staff profile from Firestore.
  ///
  /// Returns null if document doesn't exist or user doesn't have
  /// staff/provider/admin role.
  Future<StaffUser?> _loadStaffProfile(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        return null;
      }

      final data = userDoc.data()!;

      // Verify staff role
      final role = data['role'] as String?;
      if (role != 'staff' && role != 'provider' && role != 'admin') {
        return null;
      }

      return StaffUser.fromFirestore(uid, data);
    } catch (e) {
      // Log error but return null - user may not be authorized
      return null;
    }
  }

  /// Maps Firebase Auth exceptions to user-friendly messages.
  StaffAuthException _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return const StaffAuthException(
          StaffAuthException.userNotFound,
          code: 'user-not-found',
        );
      case 'wrong-password':
        return const StaffAuthException(
          StaffAuthException.wrongPassword,
          code: 'wrong-password',
        );
      case 'invalid-email':
        return const StaffAuthException(
          'Please enter a valid email address',
          code: 'invalid-email',
        );
      case 'user-disabled':
        return const StaffAuthException(
          StaffAuthException.accountDisabled,
          code: 'user-disabled',
        );
      case 'too-many-requests':
        return const StaffAuthException(
          StaffAuthException.tooManyAttempts,
          code: 'too-many-requests',
        );
      case 'network-request-failed':
        return const StaffAuthException(
          StaffAuthException.networkError,
          code: 'network-error',
        );
      case 'invalid-credential':
        return const StaffAuthException(
          StaffAuthException.invalidCredentials,
          code: 'invalid-credential',
        );
      default:
        return StaffAuthException(
          e.message ?? 'Authentication failed',
          code: e.code,
        );
    }
  }
}
