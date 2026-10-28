import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../security/secure_storage_service.dart';
import '../security/session_manager.dart';
import '../security/biometric_service.dart';
import '../security/remote_wipe_service.dart';

// Service Providers

/// Provider for the secure storage service singleton.
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService.instance;
});

/// Provider for the session manager singleton.
final sessionManagerProvider = Provider<SessionManager>((ref) {
  return SessionManager.instance;
});

/// Provider for the biometric service singleton.
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService.instance;
});

/// Provider for the remote wipe service singleton.
final remoteWipeServiceProvider = Provider<RemoteWipeService>((ref) {
  return RemoteWipeService.instance;
});

// State Providers

/// Provider for the current session state.
final sessionStateProvider = StateProvider<SessionState>((ref) {
  return SessionManager.instance.state;
});

/// Provider for checking if the session is valid.
final isSessionValidProvider = Provider<bool>((ref) {
  final state = ref.watch(sessionStateProvider);
  return state == SessionState.active || state == SessionState.expiring;
});

/// Provider for checking if biometric authentication is available.
final isBiometricAvailableProvider = FutureProvider<bool>((ref) async {
  return BiometricService.instance.isBiometricAvailable();
});

/// Provider for checking if biometric authentication is enabled by user.
final isBiometricEnabledProvider = FutureProvider<bool>((ref) async {
  return BiometricService.instance.isEnabled();
});

/// Provider for getting available biometric types description.
final biometricDescriptionProvider = FutureProvider<String>((ref) async {
  return BiometricService.instance.getBiometricDescription();
});

/// Provider for the session timeout duration.
final sessionTimeoutProvider = StateProvider<Duration>((ref) {
  return SessionManager.instance.inactivityTimeout;
});

/// Provider for the remaining session time.
final sessionRemainingTimeProvider = Provider<Duration>((ref) {
  // Watch session state to trigger refresh
  ref.watch(sessionStateProvider);
  return SessionManager.instance.remainingTime;
});

/// Provider for remote wipe status.
final remoteWipeStatusProvider = StateProvider<RemoteWipeStatus>((ref) {
  return RemoteWipeService.instance.status;
});

// Action Providers

/// Provider for updating biometric enabled preference.
final updateBiometricEnabledProvider =
    Provider.family<Future<bool> Function(bool), void>((ref, _) {
  return (bool enabled) async {
    final success = await BiometricService.instance.setEnabled(enabled);
    if (success) {
      ref.invalidate(isBiometricEnabledProvider);
    }
    return success;
  };
});

/// Provider for updating session timeout.
final updateSessionTimeoutProvider =
    Provider.family<Future<void> Function(Duration), void>((ref, _) {
  return (Duration timeout) async {
    await SessionManager.instance.setInactivityTimeout(timeout);
    ref.read(sessionTimeoutProvider.notifier).state = timeout;
  };
});

/// Provider for recording user activity.
final recordActivityProvider = Provider<void Function()>((ref) {
  return () {
    SessionManager.instance.recordActivity();
    // Update session state if needed
    ref.read(sessionStateProvider.notifier).state =
        SessionManager.instance.state;
  };
});

/// Provider for locking the session.
final lockSessionProvider = Provider<void Function()>((ref) {
  return () {
    SessionManager.instance.lockSession();
    ref.read(sessionStateProvider.notifier).state =
        SessionManager.instance.state;
  };
});

/// Provider for unlocking the session.
final unlockSessionProvider = Provider<void Function()>((ref) {
  return () {
    SessionManager.instance.unlockSession();
    ref.read(sessionStateProvider.notifier).state =
        SessionManager.instance.state;
  };
});

/// Provider for biometric unlock authentication.
final biometricUnlockProvider = FutureProvider.family<bool, void>((ref, _) async {
  final result = await BiometricService.instance.authenticateForUnlock();
  if (result == BiometricResult.success) {
    ref.read(unlockSessionProvider)();
    return true;
  }
  return false;
});

// Initialization

/// Provider that initializes all security services.
///
/// Call this during app startup after authentication.
final initializeSecurityProvider =
    FutureProvider.family<void, String>((ref, businessId) async {
  // Initialize session manager
  await SessionManager.instance.initialize();

  // Set up session callbacks to update providers
  SessionManager.instance.onSessionExpired = () {
    ref.read(sessionStateProvider.notifier).state = SessionState.expired;
  };
  SessionManager.instance.onSessionWarning = () {
    ref.read(sessionStateProvider.notifier).state = SessionState.expiring;
  };
  SessionManager.instance.onSessionLocked = () {
    ref.read(sessionStateProvider.notifier).state = SessionState.locked;
  };
  SessionManager.instance.onSessionRestored = () {
    ref.read(sessionStateProvider.notifier).state = SessionState.active;
  };

  // Initialize remote wipe service
  await RemoteWipeService.instance.initialize(businessId);

  // Set up remote wipe callbacks
  RemoteWipeService.instance.onWipeComplete = () {
    ref.read(remoteWipeStatusProvider.notifier).state =
        RemoteWipeStatus.completed;
  };

  // Start session
  SessionManager.instance.startSession();
  ref.read(sessionStateProvider.notifier).state = SessionState.active;
});
