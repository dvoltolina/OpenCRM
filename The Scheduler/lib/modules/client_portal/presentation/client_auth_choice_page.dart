import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/components/components.dart';
import 'guest_booking_form.dart';

/// Page where user chooses how to proceed with booking.
///
/// Options:
/// 1. Sign In - Use existing account
/// 2. Create Account - Register new account
/// 3. Continue as Guest - Quick booking without account
///
/// HIPAA Note: No PHI on this page
class ClientAuthChoicePage extends ConsumerWidget {
  const ClientAuthChoicePage({
    super.key,
    required this.businessId,
  });

  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VSpace.xl,
              Text(
                'How would you like to continue?',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              VSpace.md,
              Text(
                'Choose the option that works best for you',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),

              // Sign In option
              _AuthChoiceCard(
                icon: Icons.login,
                title: 'Sign In',
                subtitle: 'Use your existing account',
                onTap: () => _handleSignIn(context),
              ),
              VSpace.md,

              // Create Account option
              _AuthChoiceCard(
                icon: Icons.person_add,
                title: 'Create Account',
                subtitle: 'Save your info for faster booking',
                onTap: () => _handleCreateAccount(context),
              ),
              VSpace.md,

              // Guest booking option
              _AuthChoiceCard(
                icon: Icons.person_outline,
                title: 'Continue as Guest',
                subtitle: 'Quick booking, no account needed',
                isPrimary: true,
                onTap: () => _handleGuestBooking(context),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSignIn(BuildContext context) {
    // Navigate to sign in page
    // TODO: Implement navigation to sign in page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sign in flow not yet implemented'),
      ),
    );
  }

  void _handleCreateAccount(BuildContext context) {
    // Navigate to registration page
    // TODO: Implement navigation to registration page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account creation flow not yet implemented'),
      ),
    );
  }

  void _handleGuestBooking(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GuestBookingForm(businessId: businessId),
      ),
    );
  }
}

/// Card for an authentication choice option
class _AuthChoiceCard extends StatelessWidget {
  const _AuthChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isPrimary = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: isPrimary ? 4 : 1,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isPrimary
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: isPrimary
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              HSpace.md,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isPrimary ? theme.colorScheme.primary : null,
                      ),
                    ),
                    VSpace.xs,
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
