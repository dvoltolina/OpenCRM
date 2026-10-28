import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/providers/providers.dart';
import '../../../data/models/business_search_result.dart';
import '../../../data/models/guest_session.dart';
import '../services/business_search_service.dart';
import 'guest_session_provider.dart';

part 'client_portal_providers.freezed.dart';

/// Provider for BusinessSearchService
final businessSearchServiceProvider = Provider<BusinessSearchService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final config = ref.watch(appConfigProvider);

  return BusinessSearchService(
    firestore: firestore,
    searchFunctionUrl: config.cloudFunctionUrls['businessSearch'] ?? '',
  );
});

/// Selected business for booking flow
final selectedBusinessProvider = StateProvider<BusinessSearchResult?>((ref) {
  return null;
});

/// Business search query string
final businessSearchQueryProvider = StateProvider<String>((ref) {
  return '';
});

/// Debounced business search results
///
/// Only searches when query is 2+ characters.
/// Returns empty list for short queries.
final businessSearchResultsProvider =
    FutureProvider<List<BusinessSearchResult>>((ref) async {
  final query = ref.watch(businessSearchQueryProvider);

  if (query.trim().length < 2) {
    return [];
  }

  final service = ref.watch(businessSearchServiceProvider);
  return service.searchBusinesses(query);
});

/// Business details for a specific business ID
final businessDetailsProvider =
    FutureProvider.family<BusinessDetails?, String>((ref, businessId) async {
  if (businessId.isEmpty) {
    return null;
  }

  final service = ref.watch(businessSearchServiceProvider);
  return service.getBusinessDetails(businessId);
});

/// Current client authentication state
///
/// Can be one of:
/// - Unauthenticated: No user or guest session
/// - Guest: Valid guest session
/// - SignedIn: Authenticated user account
final clientAuthStateProvider = Provider<ClientAuthState>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  final guest = ref.watch(guestSessionProvider);

  if (user != null) {
    return ClientAuthState.signedIn(user);
  } else if (guest != null && guest.isValid) {
    return ClientAuthState.guest(guest);
  } else {
    return const ClientAuthState.unauthenticated();
  }
});

/// Check if client is authenticated (either account or guest)
final isClientAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(clientAuthStateProvider);
  return authState.maybeWhen(
    unauthenticated: () => false,
    orElse: () => true,
  );
});

/// Client authentication state
@freezed
class ClientAuthState with _$ClientAuthState {
  const factory ClientAuthState.unauthenticated() = _Unauthenticated;
  const factory ClientAuthState.guest(GuestSession session) = _Guest;
  const factory ClientAuthState.signedIn(User user) = _SignedIn;
}

/// Provider for current user (from Firebase Auth)
final currentUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});
