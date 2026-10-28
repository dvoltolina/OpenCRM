import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/demo_config.dart';
import '../../../core/providers/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../home/presentation/home_shell.dart';
import 'business_portal_entry_page.dart';
import 'client_login_page.dart';

/// Initial screen that lets users choose between Business Portal and Client Portal.
class PortalSelectionPage extends ConsumerWidget {
  const PortalSelectionPage({super.key});

  /// Show dialog to enter business code for client portal access
  void _showBusinessCodeDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final theme = Theme.of(context);
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Enter Business Code'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter your healthcare provider\'s business code to access your client portal.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  VSpace.md,
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Business Code',
                      hintText: 'e.g., my-therapy-practice',
                      prefixIcon: const Icon(Icons.business_outlined),
                      border: const OutlineInputBorder(),
                      errorText: errorMessage,
                    ),
                    textInputAction: TextInputAction.done,
                    enabled: !isLoading,
                    onSubmitted: (_) => _handleLookup(
                      context,
                      ref,
                      controller.text,
                      setState,
                      () => isLoading = true,
                      (msg) => errorMessage = msg,
                    ),
                  ),
                  VSpace.xs,
                  Text(
                    'The business code is usually found in your appointment email or on your provider\'s website.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isLoading
                      ? null
                      : () => _handleLookup(
                            context,
                            ref,
                            controller.text,
                            setState,
                            () => isLoading = true,
                            (msg) => errorMessage = msg,
                          ),
                  child: isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleLookup(
    BuildContext context,
    WidgetRef ref,
    String code,
    StateSetter setState,
    VoidCallback setLoading,
    void Function(String?) setError,
  ) async {
    final trimmedCode = code.trim().toLowerCase();
    if (trimmedCode.isEmpty) {
      setState(() => setError('Please enter a business code'));
      return;
    }

    setState(() {
      setLoading();
      setError(null);
    });

    try {
      final workspaceRepo = ref.read(workspaceRepositoryProvider);
      final result = await workspaceRepo.lookupBusinessBySlug(slug: trimmedCode);

      if (!context.mounted) return;

      if (result.found && result.businessId != null) {
        Navigator.of(context).pop(); // Close dialog
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ClientLoginPage(businessId: result.businessId),
          ),
        );
      } else {
        setState(() => setError('Business not found. Please check the code and try again.'));
      }
    } catch (e) {
      if (!context.mounted) return;
      setState(() => setError('Unable to verify business code. Please try again.'));
    }
  }

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
      backgroundColor: isDark ? colorScheme.surfaceContainerLowest : colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with gradient background and layered shadows
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          branding.primaryColor,
                          branding.accentColor,
                        ],
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
                      Icons.calendar_month_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Product name
                  Text(
                    branding.productName,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  VSpace.xs,

                  // Tagline
                  Text(
                    branding.tagline,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isDark ? Colors.white60 : Colors.black45,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 56),

                  // Selection prompt
                  Text(
                    'Choose your portal',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Business Portal Card
                  _PortalCard(
                    icon: Icons.business_rounded,
                    title: 'Business Portal',
                    subtitle: 'Manage your practice',
                    description: 'For staff, providers, and administrators',
                    color: branding.primaryColor,
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BusinessPortalEntryPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  // Client Portal Card
                  _PortalCard(
                    icon: Icons.person_rounded,
                    title: 'Client Portal',
                    subtitle: 'Access your account',
                    description: 'View appointments, forms, and billing',
                    color: colorScheme.secondary,
                    isDark: isDark,
                    onTap: () => _showBusinessCodeDialog(context, ref),
                  ),

                  const SizedBox(height: 48),

                  // Footer text
                  Text(
                    'Secure & HIPAA Compliant',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white30 : Colors.black26,
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

class _PortalCard extends StatefulWidget {
  const _PortalCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  State<_PortalCard> createState() => _PortalCardState();
}

class _PortalCardState extends State<_PortalCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _shadowAnimation = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Darken the color for a more striking appearance
    final darkerColor = HSLColor.fromColor(widget.color)
        .withLightness((HSLColor.fromColor(widget.color).lightness * 0.85).clamp(0.0, 1.0))
        .toColor();

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    darkerColor,
                    widget.color,
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: darkerColor.withValues(alpha: 0.4 * _shadowAnimation.value),
                    blurRadius: 20 * _shadowAnimation.value,
                    offset: Offset(0, 8 * _shadowAnimation.value),
                  ),
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.2 * _shadowAnimation.value),
                    blurRadius: 8 * _shadowAnimation.value,
                    offset: Offset(0, 2 * _shadowAnimation.value),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Icon container - white background for contrast
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                    HSpace.md,

                    // Text content - white text for contrast
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          VSpace.xxs,
                          Text(
                            widget.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Arrow - white for visibility
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
