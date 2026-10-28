import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/ui/components/components.dart';
import 'staff_join_page.dart';

/// Page for selecting user role when joining a business.
/// Admin/Staff must enter an invite code to join.
/// Note: Business owners create accounts via the Admin Portal (web).
class RoleSelectionPage extends ConsumerWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final branding = config.branding;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surfaceContainerLowest : colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colorScheme.onSurfaceVariant,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    padding: AppSpacing.cardPadding,
                    decoration: BoxDecoration(
                      color: branding.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.badge_outlined,
                      size: 40,
                      color: branding.primaryColor,
                    ),
                  ),
                  VSpace.lg,

                  // Title
                  Text(
                    'Join Your Team',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  VSpace.sm,

                  // Subtitle
                  Text(
                    'Select your role to join with your invite code',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  VSpace.xl,

                  // Admin option
                  _RoleCard(
                    icon: Icons.manage_accounts_rounded,
                    title: 'Administrator',
                    subtitle: 'I was invited as an admin',
                    description: 'Join an existing business with admin privileges',
                    color: colorScheme.secondary,
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const StaffJoinPage(isAdmin: true),
                        ),
                      );
                    },
                  ),
                  VSpace.md,

                  // Staff option
                  _RoleCard(
                    icon: Icons.person_rounded,
                    title: 'Staff Member',
                    subtitle: 'I was invited to join a team',
                    description: 'Join an existing business as a staff member',
                    color: colorScheme.tertiary,
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const StaffJoinPage(isAdmin: false),
                        ),
                      );
                    },
                  ),
                  VSpace.xl,

                  // Help text
                  Container(
                    padding: AppSpacing.cardPadding,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        HSpace.sm,
                        Expanded(
                          child: Text(
                            'You\'ll need an invite code from your business owner to join.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
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

/// A card for selecting a role
class _RoleCard extends StatefulWidget {
  const _RoleCard({
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
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Polished card styling with subtle color tint and layered shadows
    final cardTint = widget.color.withValues(alpha: 0.03);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: _isPressed ? 0.98 : 1.0,
        child: Container(
        decoration: BoxDecoration(
          // Clean surface with subtle color tint
          color: widget.isDark
              ? colorScheme.surfaceContainerHigh
              : Color.alphaBlend(cardTint, colorScheme.surface),
          borderRadius: BorderRadius.circular(AppRadius.md),
          // Refined border
          border: Border.all(
            color: _isPressed
                ? widget.color.withValues(alpha: 0.5)
                : colorScheme.outlineVariant,
            width: _isPressed ? 2.0 : 1.0,
          ),
          // Layered shadows for depth
          boxShadow: [
            // Primary shadow - subtle and soft
            BoxShadow(
              color: Colors.black.withValues(alpha: widget.isDark ? 0.3 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            // Secondary shadow - larger spread
            BoxShadow(
              color: Colors.black.withValues(alpha: widget.isDark ? 0.15 : 0.03),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            // Color glow when pressed
            if (_isPressed)
              BoxShadow(
                color: widget.color.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            children: [
              // Icon container with gradient background
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.color.withValues(alpha: 0.15),
                      widget.color.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  // Subtle inner shadow for depth
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  size: 26,
                  color: widget.color,
                ),
              ),
              HSpace.md,

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    VSpace.xxs,
                    Text(
                      widget.subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: widget.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    VSpace.xxs,
                    Text(
                      widget.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow indicator
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
