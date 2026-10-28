// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/user_messages.dart';
import '../../../../core/providers/providers.dart';
import '../../../../data/models/gift_card.dart';
import '../../../../data/models/security_context.dart';
import 'gift_card_admin_dialogs.dart';

/// Bottom sheet showing full gift card details and admin actions.
///
/// Features:
/// - Gift card info (code, amounts, dates)
/// - Purchaser and recipient info
/// - Redemption history
/// - Admin actions (void, adjust, extend, resend)
class GiftCardDetailSheet extends ConsumerStatefulWidget {
  const GiftCardDetailSheet({
    required this.giftCard,
    required this.securityContext,
    super.key,
  });

  final GiftCard giftCard;
  final SecurityContext securityContext;

  @override
  ConsumerState<GiftCardDetailSheet> createState() => _GiftCardDetailSheetState();
}

class _GiftCardDetailSheetState extends ConsumerState<GiftCardDetailSheet> {
  late GiftCard _giftCard;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _giftCard = widget.giftCard;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd();
    final dateTimeFormat = DateFormat.yMMMd().add_jm();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _giftCard.code,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 20),
                                onPressed: () => _copyCode(context),
                                tooltip: 'Copy code',
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          _StatusChip(status: _giftCard.status),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${_giftCard.remainingBalanceDollars.toStringAsFixed(2)}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _giftCard.remainingBalanceCents > 0
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                          ),
                        ),
                        Text(
                          'of \$${_giftCard.originalAmountDollars.toStringAsFixed(2)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Dates Section
                    _SectionHeader(title: 'Dates'),
                    _InfoRow(
                      label: 'Purchased',
                      value: dateTimeFormat.format(_giftCard.purchasedAt),
                    ),
                    if (_giftCard.activatedAt != null)
                      _InfoRow(
                        label: 'Activated',
                        value: dateTimeFormat.format(_giftCard.activatedAt!),
                      ),
                    _InfoRow(
                      label: 'Expires',
                      value: _giftCard.expiresAt != null
                          ? dateFormat.format(_giftCard.expiresAt!)
                          : 'Never',
                      valueColor: _giftCard.expiresAt != null &&
                              _giftCard.expiresAt!.isBefore(DateTime.now())
                          ? theme.colorScheme.error
                          : null,
                    ),
                    if (_giftCard.lastRedeemedAt != null)
                      _InfoRow(
                        label: 'Last Redeemed',
                        value: dateTimeFormat.format(_giftCard.lastRedeemedAt!),
                      ),
                    const SizedBox(height: 24),

                    // Purchaser Section
                    _SectionHeader(title: 'Purchaser'),
                    _InfoRow(
                      label: 'Email',
                      value: _giftCard.purchaserEmail,
                      copyable: true,
                    ),
                    if (_giftCard.purchaserName != null)
                      _InfoRow(
                        label: 'Name',
                        value: _giftCard.purchaserName!,
                      ),
                    const SizedBox(height: 24),

                    // Recipient Section
                    if (_giftCard.recipientEmail != null) ...[
                      _SectionHeader(title: 'Recipient'),
                      _InfoRow(
                        label: 'Email',
                        value: _giftCard.recipientEmail!,
                        copyable: true,
                      ),
                      if (_giftCard.recipientName != null)
                        _InfoRow(
                          label: 'Name',
                          value: _giftCard.recipientName!,
                        ),
                      if (_giftCard.personalMessage != null)
                        _InfoRow(
                          label: 'Message',
                          value: '"${_giftCard.personalMessage!}"',
                        ),
                      _InfoRow(
                        label: 'Delivered',
                        value: _giftCard.delivered ? 'Yes' : 'No',
                        valueColor: _giftCard.delivered ? Colors.green : theme.colorScheme.tertiary,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Payment Section
                    _SectionHeader(title: 'Payment'),
                    _InfoRow(
                      label: 'Payment ID',
                      value: _giftCard.paymentId ?? 'N/A',
                      copyable: _giftCard.paymentId != null,
                    ),
                    const SizedBox(height: 24),

                    // Redemptions Section
                    _SectionHeader(title: 'Redemption History'),
                    if (_giftCard.redemptions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'No redemptions yet',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      )
                    else
                      ...(_giftCard.redemptions.map((redemption) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.redeem),
                            ),
                            title: Text(
                              '\$${(redemption.amountCents / 100).toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              dateTimeFormat.format(redemption.redeemedAt),
                            ),
                            trailing: Text(
                              'Appt: ${redemption.appointmentId.substring(0, 8)}...',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        );
                      })),
                    const SizedBox(height: 24),

                    // Admin Actions
                    if (_giftCard.status != GiftCardStatus.voided) ...[
                      _SectionHeader(title: 'Admin Actions'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (_giftCard.status == GiftCardStatus.active) ...[
                            OutlinedButton.icon(
                              onPressed: _isLoading ? null : () => _showAdjustBalanceDialog(context),
                              icon: const Icon(Icons.account_balance_wallet),
                              label: const Text('Adjust Balance'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _isLoading ? null : () => _showExtendExpirationDialog(context),
                              icon: const Icon(Icons.event),
                              label: const Text('Extend Expiration'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _isLoading ? null : _resendEmail,
                              icon: const Icon(Icons.email),
                              label: const Text('Resend Email'),
                            ),
                          ],
                          if (_giftCard.status == GiftCardStatus.expired)
                            OutlinedButton.icon(
                              onPressed: _isLoading ? null : () => _showExtendExpirationDialog(context),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reactivate'),
                            ),
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : () => _showVoidDialog(context),
                            icon: Icon(Icons.cancel, color: theme.colorScheme.error),
                            label: Text(
                              'Void Card',
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: theme.colorScheme.error),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _giftCard.code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code copied'), duration: Duration(seconds: 1)),
    );
  }

  Future<void> _resendEmail() async {
    setState(() => _isLoading = true);
    try {
      final giftCardService = ref.read(giftCardServiceProvider);
      await giftCardService.resendGiftCardEmail(
        context: widget.securityContext,
        giftCardId: _giftCard.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email sent successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserMessages.saveError)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAdjustBalanceDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AdjustBalanceDialog(),
    );

    if (result == null) return;

    final amount = result['amount'] as double;
    final isAdd = result['isAdd'] as bool;
    final reason = result['reason'] as String;

    setState(() => _isLoading = true);
    try {
      final giftCardService = ref.read(giftCardServiceProvider);
      final adjustmentCents = (amount * 100).round() * (isAdd ? 1 : -1);
      final updated = await giftCardService.adjustGiftCardBalance(
        context: widget.securityContext,
        giftCardId: _giftCard.id,
        adjustmentCents: adjustmentCents,
        reason: reason,
      );
      setState(() => _giftCard = updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Balance adjusted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserMessages.saveError)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showExtendExpirationDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ExtendExpirationDialog(
        currentExpiry: _giftCard.expiresAt,
      ),
    );

    if (result == null) return;

    final newExpiry = result['newExpiry'] as DateTime;
    final reason = result['reason'] as String;

    setState(() => _isLoading = true);
    try {
      final giftCardService = ref.read(giftCardServiceProvider);
      final updated = await giftCardService.extendExpiration(
        context: widget.securityContext,
        giftCardId: _giftCard.id,
        newExpiresAt: newExpiry,
        reason: reason,
      );
      setState(() => _giftCard = updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expiration extended successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserMessages.saveError)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showVoidDialog(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => VoidGiftCardDialog(
        remainingBalanceDollars: _giftCard.remainingBalanceDollars,
      ),
    );

    if (reason == null) return;

    setState(() => _isLoading = true);
    try {
      final giftCardService = ref.read(giftCardServiceProvider);
      await giftCardService.voidGiftCard(
        context: widget.securityContext,
        giftCardId: _giftCard.id,
        reason: reason,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gift card voided')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserMessages.saveError)),
      );
      setState(() => _isLoading = false);
    }
  }
}

// ============================================================
// Helper Widgets
// ============================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.outline,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.copyable = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(color: valueColor),
                  ),
                ),
                if (copyable)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 14),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.only(left: 8),
                    iconSize: 14,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final GiftCardStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _statusLabel,
        style: theme.textTheme.bodySmall?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String get _statusLabel {
    switch (status) {
      case GiftCardStatus.pending:
        return 'Pending';
      case GiftCardStatus.active:
        return 'Active';
      case GiftCardStatus.depleted:
        return 'Depleted';
      case GiftCardStatus.expired:
        return 'Expired';
      case GiftCardStatus.voided:
        return 'Voided';
    }
  }

  Color _statusColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (status) {
      case GiftCardStatus.pending:
        return theme.colorScheme.tertiary;
      case GiftCardStatus.active:
        return Colors.green;
      case GiftCardStatus.depleted:
        return theme.colorScheme.outline;
      case GiftCardStatus.expired:
        return theme.colorScheme.error;
      case GiftCardStatus.voided:
        return theme.colorScheme.error;
    }
  }
}
