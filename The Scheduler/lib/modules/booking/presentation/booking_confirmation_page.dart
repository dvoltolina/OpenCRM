import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../data/models/appointment.dart';
import '../../../data/models/magic_link_token.dart';
import '../../../data/models/client.dart';
import '../../../data/models/provider.dart' as provider_model;
import '../../../data/models/service.dart';
import '../../../data/models/location.dart';

/// Booking confirmation page shown after successful appointment creation
/// Updated by Agent U4 (2025-11-29) - Uses design tokens
///
/// Displays:
/// - Confirmation message and success icon
/// - Booking details (date, time, provider, service, location)
/// - Confirmation code
/// - Magic link for future access
/// - Instructions for managing the appointment
///
/// This is a critical customer-facing touchpoint that provides reassurance
/// and easy access to appointment management.
class BookingConfirmationPage extends ConsumerWidget {
  const BookingConfirmationPage({
    required this.appointment,
    required this.magicLinkToken,
    required this.client,
    required this.provider,
    required this.service,
    required this.location,
    super.key,
  });

  final Appointment appointment;
  final MagicLinkToken magicLinkToken;
  final Client client;
  final provider_model.Provider provider;
  final Service service;
  final Location location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Touch security context to align with RBAC expectations, even though data is injected.
    ref.watch(securityContextProvider);

    final dateFormat = DateFormat('EEEE, MMMM d, y');
    final timeFormat = DateFormat('h:mm a');

    return ScrollablePageScaffold(
      title: 'Booking Confirmed',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success icon and message
          _buildSuccessHeader(context),
          VSpace.xl,

          // Confirmation code card
          _buildConfirmationCodeCard(context),
          VSpace.lg,

          // Booking details card
          _buildBookingDetailsCard(
            context,
            dateFormat,
            timeFormat,
          ),
          VSpace.lg,

          // Magic link card
          _buildMagicLinkCard(context),
          VSpace.lg,

          // Instructions
          _buildInstructions(context),
          VSpace.xl,

          // Action buttons
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildSuccessHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: AppIconSize.xl * 2,
          height: AppIconSize.xl * 2,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            size: AppIconSize.xl,
            color: theme.colorScheme.primary,
          ),
        ),
        VSpace.md,
        Text(
          'Booking Confirmed!',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        VSpace.xs,
        Text(
          'We\'ve sent a confirmation email to ${client.email}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationCodeCard(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.confirmation_number_outlined,
                  color: theme.colorScheme.primary,
                ),
                HSpace.xs,
                Text(
                  'Confirmation Code',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            VSpace.md,
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  Text(
                    appointment.id.substring(0, 8).toUpperCase(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  HSpace.sm,
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () => _copyToClipboard(
                      context,
                      appointment.id.substring(0, 8).toUpperCase(),
                      'Confirmation code copied',
                    ),
                    tooltip: 'Copy code',
                  ),
                ],
              ),
            ),
            VSpace.xs,
            Text(
              'Save this code for your records',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingDetailsCard(
      BuildContext context,
      DateFormat dateFormat,
      DateFormat timeFormat,
      ) {
    final theme = Theme.of(context);

    return AppCard(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appointment Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            VSpace.md,
            _buildDetailRow(
              context,
              icon: Icons.event_outlined,
              label: 'Date',
              value: dateFormat.format(appointment.startTime),
            ),
            const Divider(height: AppSpacing.lg),
            _buildDetailRow(
              context,
              icon: Icons.access_time_outlined,
              label: 'Time',
              value: '${timeFormat.format(appointment.startTime)} - '
                  '${timeFormat.format(appointment.endTime)}',
            ),
            const Divider(height: AppSpacing.lg),
            _buildDetailRow(
              context,
              icon: Icons.design_services_outlined,
              label: 'Service',
              value: service.name,
            ),
            const Divider(height: AppSpacing.lg),
            _buildDetailRow(
              context,
              icon: Icons.person_outline,
              label: 'Provider',
              value: provider.fullName,
            ),
            const Divider(height: AppSpacing.lg),
            _buildDetailRow(
              context,
              icon: Icons.location_on_outlined,
              label: 'Location',
              value: location.name ?? location.address,
            ),
            if (appointment.notes != null) ...[
              const Divider(height: AppSpacing.lg),
              _buildDetailRow(
                context,
                icon: Icons.notes_outlined,
                label: 'Notes',
                value: appointment.notes!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String value,
      }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: AppIconSize.sm,
          color: theme.colorScheme.primary,
        ),
        HSpace.sm,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              VSpace.xxs,
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMagicLinkCard(BuildContext context) {
    final theme = Theme.of(context);
    final magicLinkUrl = 'https://book.example.com/appointment/${magicLinkToken.token}';

    return AppCard(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.link_outlined,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                HSpace.xs,
                Text(
                  'Manage Your Appointment',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            VSpace.sm,
            Text(
              'Use this secure link to view, reschedule, or cancel your appointment. '
                  'No login required!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            VSpace.md,
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      magicLinkUrl,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  HSpace.xs,
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () => _copyToClipboard(
                      context,
                      magicLinkUrl,
                      'Link copied to clipboard',
                    ),
                    tooltip: 'Copy link',
                  ),
                ],
              ),
            ),
            VSpace.sm,
            Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: AppIconSize.xs,
                  color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                ),
                HSpace.xxs,
                Text(
                  magicLinkToken.expirationDisplay,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What\'s Next?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            VSpace.md,
            _buildInstructionItem(
              context,
              number: '1',
              text: 'Check your email for a confirmation message with all the details',
            ),
            VSpace.sm,
            _buildInstructionItem(
              context,
              number: '2',
              text: 'Save the magic link above to manage your appointment anytime',
            ),
            VSpace.sm,
            _buildInstructionItem(
              context,
              number: '3',
              text: 'Need to reschedule or cancel? Just click the link - no login needed',
            ),
            VSpace.sm,
            _buildInstructionItem(
              context,
              number: '4',
              text: 'We\'ll send you reminders before your appointment',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(
      BuildContext context, {
        required String number,
        required String text,
      }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: AppIconSize.md + AppSpacing.xs,
          height: AppIconSize.md + AppSpacing.xs,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        HSpace.sm,
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxs),
            child: Text(
              text,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FullWidthButton(
          onPressed: () {
            // Navigate to home or close
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          label: 'Back to Home',
          icon: Icons.home_outlined,
        ),
        VSpace.sm,
        FullWidthButton(
          onPressed: () {
            final magicLinkUrl =
                'https://book.example.com/appointment/${magicLinkToken.token}';
            _copyToClipboard(context, magicLinkUrl, 'Link copied to clipboard');
          },
          label: 'Share Link',
          icon: Icons.share_outlined,
          buttonType: FullWidthButtonType.outlined,
        ),
      ],
    );
  }

  void _copyToClipboard(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
