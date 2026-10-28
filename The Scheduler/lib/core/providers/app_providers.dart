import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/security_context.dart';
import '../config/app_config.dart';
import '../config/demo_config.dart';
import '../services/auth_state_service.dart';
import '../services/theme_mode_service.dart';

/// Provider for the global [AppConfig].
///
/// This bridges the existing [ConfigScope] InheritedWidget pattern with Riverpod.
/// During migration, widgets can consume config via either:
///   - `ConfigScope.of(context)` (legacy)
///   - `ref.watch(appConfigProvider)` (Riverpod)
///
/// The config is overridden at the [ProviderScope] level in [SchedulerApp].
/// Default value is a placeholder that should never be used in practice.
final appConfigProvider = Provider<AppConfig>((ref) {
  // This default is overridden at ProviderScope level.
  // If you see this in production, the override is missing.
  throw UnimplementedError(
    'appConfigProvider must be overridden at ProviderScope level. '
    'Ensure SchedulerApp wraps the app with a ProviderScope that overrides this provider.',
  );
});

/// Provider for the [AuthStateService] singleton.
///
/// This wraps the existing singleton pattern so repositories/services
/// that depend on auth can be provided via Riverpod.
final authStateServiceProvider = Provider<AuthStateService>((ref) {
  return AuthStateService.instance;
});

/// StreamProvider for the current [SecurityContext].
///
/// Emits:
/// - `AsyncData(SecurityContext)` when user is authenticated with a valid profile
/// - `AsyncData(null)` when user is not authenticated or profile is missing
/// - `AsyncLoading` while the stream is initializing
/// - `AsyncError` on stream errors
///
/// Widgets can watch this to reactively respond to auth state changes:
/// ```dart
/// final securityContextAsync = ref.watch(securityContextProvider);
/// securityContextAsync.when(
///   data: (context) => context != null ? AuthenticatedWidget() : LoginPage(),
///   loading: () => LoadingSpinner(),
///   error: (e, s) => ErrorWidget(e),
/// );
/// ```
final securityContextProvider = StreamProvider<SecurityContext?>((ref) {
  if (DemoConfig.isDemoMode) {
    return Stream.value(DemoConfig.buildDemoSecurityContext());
  }
  final authService = ref.watch(authStateServiceProvider);
  return authService.watchSecurityContext();
});

/// Provider for the current [SecurityContext] value (nullable).
///
/// This is a convenience provider that extracts the value from the stream.
/// Returns null if loading, errored, or no authenticated user.
///
/// Use this when you need synchronous access and can handle null:
/// ```dart
/// final context = ref.watch(currentSecurityContextProvider);
/// if (context != null) { /* authenticated */ }
/// ```
final currentSecurityContextProvider = Provider<SecurityContext?>((ref) {
  if (DemoConfig.isDemoMode) {
    return DemoConfig.buildDemoSecurityContext();
  }
  return ref.watch(securityContextProvider).valueOrNull;
});

/// Provider for the [ThemeModeService] singleton.
///
/// Manages light/dark theme mode across the application.
/// The service exposes a ValueNotifier that can be watched directly
/// or via [themeModeProvider] for reactive updates.
final themeModeServiceProvider = Provider<ThemeModeService>((ref) {
  return ThemeModeService.instance;
});

/// Provider that watches the current [ThemeMode] from ThemeModeService.
///
/// Use this to reactively rebuild UI when theme mode changes:
/// ```dart
/// final themeModeNotifier = ref.watch(themeModeProvider);
/// return ValueListenableBuilder<ThemeMode>(
///   valueListenable: themeModeNotifier,
///   builder: (context, mode, _) => /* widget that uses mode */,
/// );
/// ```
final themeModeProvider = Provider<ValueNotifier<ThemeMode>>((ref) {
  final service = ref.watch(themeModeServiceProvider);
  return service.themeMode;
});
