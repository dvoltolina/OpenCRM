import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/config/config_scope.dart';
import 'core/config/demo_config.dart';
import 'core/providers/providers.dart';
import 'core/routing/app_router.dart';
import 'core/services/demo_guard_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/demo_banner.dart';

/// Main application widget.
///
/// Maintains [ConfigScope] for backward compatibility during migration.
/// Uses Riverpod [ConsumerWidget] to access theme mode provider.
///
/// Shows PortalSelectionPage as the initial screen, allowing users
/// to choose between Business Portal and Client Portal.
/// Supports dynamic light/dark theme switching via ThemeModeService.
///
/// ## Riverpod Migration Notes (Agent R1)
///
/// The app now supports both dependency injection patterns:
/// - **Legacy**: `ConfigScope.of(context)` - InheritedWidget pattern
/// - **Riverpod**: `ref.watch(appConfigProvider)` - Riverpod providers
///
/// During migration, both work side-by-side. Widgets being migrated should
/// switch to `ref.watch(...)`. Once all ConfigScope usages are removed,
/// the InheritedWidget layer can be deprecated.
///
/// The [ProviderScope] is set up in bootstrap.dart and overrides:
/// - [appConfigProvider] with the runtime [AppConfig]
///
/// This enables:
/// - `ref.watch(appConfigProvider)` anywhere in the widget tree
/// - `ref.watch(securityContextProvider)` for auth state
/// - Easy testing via ProviderContainer overrides
class SchedulerApp extends ConsumerWidget {
  const SchedulerApp({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch theme mode from Riverpod provider
    final themeModeNotifier = ref.watch(themeModeProvider);

    return ConfigScope(
      // ConfigScope is retained for backward compatibility.
      // Widgets not yet migrated can still use ConfigScope.of(context).
      config: config,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeModeNotifier,
        builder: (context, themeMode, _) {
          return MaterialApp(
            title: config.branding.productName,
            theme: buildAppTheme(config.branding, brightness: Brightness.light),
            darkTheme: buildAppTheme(config.branding, brightness: Brightness.dark),
            themeMode: themeMode,
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: DemoGuardService.scaffoldMessengerKey,
            onGenerateRoute: AppRouter.onGenerateRoute,
            builder: (context, child) {
              final appChild = child ?? const SizedBox.shrink();
              if (!DemoConfig.isDemoMode) {
                return appChild;
              }

              return Column(
                children: [
                  const DemoBanner(),
                  Expanded(child: appChild),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
