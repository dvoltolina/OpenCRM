import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/guest_session.dart';

/// Provider for guest session state management.
///
/// Guest sessions:
/// - Are created after successful verification
/// - Last for 24 hours
/// - Are persisted locally for app restarts
/// - Expire automatically
final guestSessionProvider =
    StateNotifierProvider<GuestSessionNotifier, GuestSession?>((ref) {
  return GuestSessionNotifier();
});

/// Notifier for managing guest session state.
///
/// Responsibilities:
/// - Store current guest session
/// - Persist session to local storage
/// - Load session on app start
/// - Clear expired sessions
/// - Clear session on logout
class GuestSessionNotifier extends StateNotifier<GuestSession?> {
  GuestSessionNotifier() : super(null) {
    _init();
  }

  static const String _storageKey = 'guest_session';
  SharedPreferences? _prefs;

  /// Initialize by loading persisted session
  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    await loadPersistedSession();
  }

  /// Set session after successful verification.
  ///
  /// Persists session to local storage for app restarts.
  void setSession(GuestSession session) {
    state = session;
    _persistSession(session);
  }

  /// Clear current session.
  ///
  /// Called on:
  /// - Manual logout
  /// - Session expiry
  /// - User creates account
  void clearSession() {
    state = null;
    _clearPersistedSession();
  }

  /// Check if current session is still valid.
  ///
  /// A session is valid if:
  /// - Session exists
  /// - Is verified
  /// - Expiry time is in the future
  bool get isValid {
    if (state == null) return false;
    return state!.isValid;
  }

  /// Check if session exists but is expired
  bool get isExpired {
    if (state == null) return false;
    return state!.isExpired;
  }

  /// Load persisted session from local storage.
  ///
  /// Called on app start. Automatically clears expired sessions.
  Future<void> loadPersistedSession() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final json = _prefs!.getString(_storageKey);

      if (json == null) {
        return;
      }

      final data = jsonDecode(json) as Map<String, dynamic>;
      final session = GuestSession.fromJson(data);

      // Only restore if still valid
      if (session.isValid) {
        state = session;
      } else {
        // Clear expired session
        await _clearPersistedSession();
      }
    } catch (e) {
      // If parsing fails, clear the corrupted data
      await _clearPersistedSession();
    }
  }

  /// Persist session to local storage.
  Future<void> _persistSession(GuestSession session) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final json = jsonEncode(session.toJson());
      await _prefs!.setString(_storageKey, json);
    } catch (e) {
      // Failed to persist - session will be lost on restart
      // Log error in production
    }
  }

  /// Clear persisted session from local storage.
  Future<void> _clearPersistedSession() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.remove(_storageKey);
    } catch (e) {
      // Failed to clear - not critical
    }
  }

  /// Get time remaining until session expires.
  ///
  /// Returns null if no session or already expired.
  Duration? get timeRemaining {
    if (state == null || state!.isExpired) {
      return null;
    }

    return state!.expiresAt.difference(DateTime.now());
  }
}
