import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../data/models/gift_card.dart';

/// Confirmation page shown after successful gift card purchase.
///
/// Uses design tokens and the unified page scaffold to keep branding consistent.
class GiftCardConfirmationPage extends ConsumerWidget {
  const GiftCardConfirmationPage({
    required this.giftCard,
    required this.config,
    super.key,
  });

  final GiftCard giftCard;
  final AppConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensure portal flows stay tied to the active security context.
    ref.watch(securityContextProvider);

    return AppPageScaffold(
      title: 'Purchase Complete',
      showBackButton: false,
      body: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Column(
          children: [
            VSpace.xl,
            _buildSuccessIcon(context),
            VSpace.lg,
            _buildTitle(context),
            VSpace.xl,
            _buildGiftCardDisplay(context),
            VSpace.lg,
            _buildEmailConfirmation(context),
            VSpace.xl,
            _buildDoneButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessIcon(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check_circle_rounded,
        size: 60,
        color: colorScheme.primary,
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          'Thank You!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        VSpace.xs,
        Text(
          'Your gift card purchase was successful.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGiftCardDisplay(BuildContext context) {
    final primary = config.branding.primaryColor;
    final onPrimary = ThemeData.estimateBrightnessForColor(primary) == Brightness.dark
        ? Colors.white
        : Colors.black87;

    return AppCard(
      elevation: AppElevation.md,
      child: Container(
        width: double.infinity,
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          gradient: LinearGradient(
            colors: [
              primary,
              primary.withValues(alpha: 0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GIFT CARD',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: onPrimary.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
                Icon(
                  Icons.card_giftcard,
                  color: onPrimary,
                  size: AppIconSize.md,
                ),
              ],
            ),
            VSpace.md,
            Text(
              '\$${giftCard.originalAmountDollars.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            VSpace.lg,
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: onPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    giftCard.code,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: onPrimary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  HSpace.sm,
                  IconButton(
                    icon: Icon(
                      Icons.copy_rounded,
                      color: onPrimary,
                    ),
                    onPressed: () => _copyCode(context),
                    tooltip: 'Copy code',
                  ),
                ],
              ),
            ),
            VSpace.md,
            Text(
              giftCard.expiresAt != null
                  ? 'Valid until ${_formatDate(giftCard.expiresAt!)}'
                  : 'Never expires',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: onPrimary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailConfirmation(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.email_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            HSpace.xs,
            Text(
              'A confirmation email has been sent.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        VSpace.xs,
        Text(
          'You can use the gift card immediately or share it with a recipient.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDoneButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Done'),
      ),
    );
  }

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: giftCard.code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gift card code copied')),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
