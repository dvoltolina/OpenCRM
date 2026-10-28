import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../../../core/ui/components/components.dart';
import '../../../../data/models/subscription.dart';
import '../../../settings/presentation/billing_page.dart';

class SubscriptionGate extends ConsumerWidget {
  const SubscriptionGate({
    super.key,
    required this.enabled,
    required this.child,
  });

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!enabled) return child;

    final securityContextAsync = ref.watch(securityContextProvider);
    return securityContextAsync.when(
      loading: () => const _GateScaffold(),
      error: (error, stackTrace) => const _GateScaffold(),
      data: (securityContext) {
        if (securityContext == null) {
          return const _GateScaffold();
        }

        final subscriptionRepo = ref.watch(subscriptionRepositoryProvider);
        return StreamBuilder<Subscription?>(
          stream: subscriptionRepo.watchSubscription(securityContext),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _GateScaffold();
            }

            final subscription = snapshot.data;
            if (_hasAccess(subscription)) {
              return child;
            }

            return _Paywall(
              businessId: securityContext.businessId,
              subscription: subscription,
            );
          },
        );
      },
    );
  }

  bool _hasAccess(Subscription? subscription) {
    if (subscription == null) return false;
    return subscription.status == SubscriptionStatus.active ||
        subscription.status == SubscriptionStatus.trialing;
  }
}

class _GateScaffold extends StatelessWidget {
  const _GateScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _Paywall extends StatelessWidget {
  const _Paywall({
    required this.businessId,
    required this.subscription,
  });

  final String businessId;
  final Subscription? subscription;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusText = subscription == null
        ? 'No active subscription found.'
        : 'Status: ${subscription!.status.name}';

    return Scaffold(
      body: Center(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.lock_outline,
                    size: 56, color: theme.colorScheme.primary),
                VSpace.md,
                Text(
                  'Subscription Required',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                VSpace.xs,
                Text(
                  '$statusText Activate your plan to continue.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                VSpace.lg,
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BillingPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.credit_card),
                  label: const Text('Go to Billing'),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).popUntil(
                    (route) => route.isFirst,
                  ),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
