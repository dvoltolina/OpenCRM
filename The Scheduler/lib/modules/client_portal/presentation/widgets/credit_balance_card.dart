import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/client_credit_service.dart';

/// Widget to display client credit balance and available credits.
class CreditBalanceCard extends StatelessWidget {
  const CreditBalanceCard({
    super.key,
    required this.credits,
    required this.totalBalanceCents,
    this.currency = 'USD',
    this.onCreditTap,
  });

  final List<ClientCredit> credits;
  final int totalBalanceCents;
  final String currency;
  final ValueChanged<ClientCredit>? onCreditTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(
      symbol: currency == 'USD' ? '\$' : currency,
    );

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with total balance
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Credit',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(totalBalanceCents / 100),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Credits list
          if (credits.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 48,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No available credits',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Credits can be applied to future bookings',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: credits.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: theme.colorScheme.outlineVariant,
              ),
              itemBuilder: (context, index) {
                final credit = credits[index];
                return _CreditListTile(
                  credit: credit,
                  currency: currency,
                  onTap: onCreditTap != null
                      ? () => onCreditTap!(credit)
                      : null,
                );
              },
            ),
        ],
      ),
    );
  }
}

class _CreditListTile extends StatelessWidget {
  const _CreditListTile({
    required this.credit,
    required this.currency,
    this.onTap,
  });

  final ClientCredit credit;
  final String currency;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd();
    final currencyFormat = NumberFormat.currency(
      symbol: currency == 'USD' ? '\$' : currency,
    );

    final isExpiringSoon = credit.expiresAt != null &&
        credit.expiresAt!.difference(DateTime.now()).inDays <= 30;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Icon(
          Icons.card_giftcard,
          color: theme.colorScheme.onSecondaryContainer,
          size: 20,
        ),
      ),
      title: Text(
        currencyFormat.format(credit.amountDollars),
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (credit.reason != null)
            Text(
              credit.reason!,
              style: theme.textTheme.bodySmall,
            ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                'Issued: ${dateFormat.format(credit.createdAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (credit.expiresAt != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isExpiringSoon
                        ? theme.colorScheme.errorContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Expires: ${dateFormat.format(credit.expiresAt!)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isExpiringSoon
                          ? theme.colorScheme.onErrorContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: onTap != null
          ? Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            )
          : null,
    );
  }
}
