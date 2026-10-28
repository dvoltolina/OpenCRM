/// Barrel file for Riverpod providers.
///
/// Import this file to access all shared providers:
/// ```dart
/// import 'package:the_scheduler/core/providers/providers.dart';
/// ```
///
/// ## Migration Bridge Pattern
///
/// During the Riverpod migration, both ConfigScope (legacy) and Riverpod providers
/// work side-by-side:
///
/// - **Legacy**: `ConfigScope.of(context)` returns AppConfig
/// - **Riverpod**: `ref.watch(appConfigProvider)` returns AppConfig
///
/// Widgets being migrated should switch to `ref.watch(...)`. Once all usages
/// of ConfigScope.of() are removed, the InheritedWidget can be deprecated.
///
/// ## Available Providers
///
/// See individual files for comprehensive documentation on each provider.
///
/// ## Testing
///
/// Override providers in tests using ProviderContainer:
/// ```dart
/// final container = ProviderContainer(
///   overrides: [
///     appConfigProvider.overrideWithValue(testConfig),
///     firestoreProvider.overrideWithValue(fakeFirestore),
///   ],
/// );
/// ```
library;

export 'app_providers.dart';
export 'data_stream_providers.dart';
export 'repository_providers.dart';
export 'service_providers.dart';
export 'role_providers.dart';
