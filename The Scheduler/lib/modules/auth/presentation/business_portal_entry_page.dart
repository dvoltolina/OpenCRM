import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/demo_config.dart';
import '../../../core/providers/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../home/presentation/home_shell.dart';
import 'login_page.dart';
import 'role_selection_page.dart';

/// Entry page for Business Portal that offers Log In or Create Account options.
/// This is the first page shown when clicking "Business Portal" from portal selection.
class BusinessPortalEntryPage extends ConsumerWidget {
  const BusinessPortalEntryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (DemoConfig.isDemoMode) {
      return const HomeShell();
    }

    final config = ref.watch(appConfigProvider);
    final branding = config.branding;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? colorScheme.surfaceContainerLowest
          : colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Back button row
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  VSpace.lg,

                  // Logo with gradient background and layered shadows
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [branding.primaryColor, branding.accentColor],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        // Primary colored glow
                        BoxShadow(
                          color: branding.primaryColor.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                        // Secondary spread for depth
                        BoxShadow(
                          color: branding.accentColor.withValues(alpha: 0.2),
                          blurRadius: 40,
                          offset: const Offset(0, 16),
                        ),
                        // Subtle ambient shadow
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.business_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  VSpace.xl,

                  // Title
                  Text(
                    'Business Portal',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  VSpace.sm,

                  // Subtitle
                  Text(
                    'Manage your practice and staff',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  VSpace.xxxl,

                  // Log In button - primary action with ember glow
                  GradientButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    width: double.infinity,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login_rounded),
                        HSpace.xs,
                        Text('Log In'),
                      ],
                    ),
                  ),
                  VSpace.md,

                  // Team join button - owner onboarding lives in the web admin.
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RoleSelectionPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_add_outlined),
                      label: const Text('Join Team'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  VSpace.sm,
                  Text(
                    'Business owners create new workspaces in the Admin Portal.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  VSpace.xxxl,

                  // Footer text
                  Text(
                    'Secure & HIPAA Compliant',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
