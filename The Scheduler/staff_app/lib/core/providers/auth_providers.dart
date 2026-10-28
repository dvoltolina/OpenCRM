import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/staff_user.dart';
import '../services/staff_auth_service.dart';
import 'database_provider.dart';

/// Provider for Firebase Auth instance.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provider for Firestore instance.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Provider for the staff authentication service.
///
/// Provides sign in/out functionality and user profile management.
final staffAuthServiceProvider = Provider<StaffAuthService>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  return StaffAuthService(auth: auth, firestore: firestore);
});

/// Stream provider for authentication state changes.
///
/// Returns the current [User] or null if not authenticated.
/// Used by the app to determine initial routing.
final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

/// Provider for the current user ID.
///
/// Returns null if not authenticated.
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull?.uid;
});

/// Provider for checking if user is authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return userId != null;
});

/// Provider for the current staff user profile.
///
/// Fetches user data from Firestore and returns a [StaffUser] object.
/// Returns null if not authenticated or user document doesn't exist.
final currentStaffUserProvider = FutureProvider<StaffUser?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;

  if (user == null) {
    return null;
  }

  final firestore = ref.read(firestoreProvider);

  // Fetch user document from Firestore
  final userDoc = await firestore
      .collection('users')
      .doc(user.uid)
      .get();

  if (!userDoc.exists) {
    return null;
  }

  final userData = userDoc.data()!;

  // Verify this is a staff/provider role
  final role = userData['role'] as String?;
  if (role != 'staff' && role != 'provider' && role != 'admin') {
    return null;
  }

  return StaffUser.fromFirestore(user.uid, userData);
});

/// Provider for the current staff user's business ID.
///
/// Convenience provider for quick access to business ID.
final staffBusinessIdProvider = Provider<String?>((ref) {
  final staffUser = ref.watch(currentStaffUserProvider);
  return staffUser.valueOrNull?.businessId;
});

/// Provider for the current staff user's provider ID.
///
/// Convenience provider for quick access to provider ID (staff ID).
final staffProviderIdProvider = Provider<String?>((ref) {
  final staffUser = ref.watch(currentStaffUserProvider);
  return staffUser.valueOrNull?.providerId;
});

/// Provider for checking if current user has a specific permission.
final hasPermissionProvider = Provider.family<bool, String>((ref, permission) {
  final staffUser = ref.watch(currentStaffUserProvider);
  return staffUser.valueOrNull?.hasPermission(permission) ?? false;
});

/// Provider for signing out the current user.
///
/// Uses [StaffAuthService] to handle sign out and cleanup.
final signOutProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final authService = ref.read(staffAuthServiceProvider);
    final db = ref.read(databaseProvider);

    // Clear local cached data to avoid cross-user leakage on shared devices.
    await db.clearAllData();
    await authService.signOut();
  };
});

/// Provider for the current staff user's business name.
///
/// Fetches the business document from Firestore to get the display name.
/// Returns null if not authenticated or business document doesn't exist.
final businessNameProvider = FutureProvider<String?>((ref) async {
  final businessId = ref.watch(staffBusinessIdProvider);
  if (businessId == null || businessId.isEmpty) {
    return null;
  }

  final firestore = ref.read(firestoreProvider);

  try {
    // Try to get business document - businesses collection at root level
    final businessDoc = await firestore
        .collection('businesses')
        .doc(businessId)
        .get();

    if (businessDoc.exists) {
      final data = businessDoc.data();
      // Try common field names for business name
      return data?['name'] as String? ??
          data?['businessName'] as String? ??
          data?['displayName'] as String? ??
          businessId; // Fallback to ID if no name field
    }

    // Fallback to businessId as display name
    return businessId;
  } catch (e) {
    // On error, just return the businessId
    return businessId;
  }
});
