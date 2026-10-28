import 'package:flutter/material.dart';

import '../../../../data/models/pos_transaction.dart';

/// Cart panel widget for displaying and managing cart items.
///
/// Shows line items with quantity controls, totals, and payment buttons.
class CartPanel extends StatelessWidget {
  const CartPanel({
    super.key,
    required this.items,
    required this.taxRate,
    required this.onUpdateQuantity,
    required this.onRemoveItem,
    required this.onClearCart,
    required this.onCheckout,
    this.discountCents = 0,
    this.onEditDiscount,
    this.selectedClientName,
  });

  final List<CartItem> items;
  final double taxRate;
  final int discountCents;
  final void Function(int index, int quantity) onUpdateQuantity;
  final void Function(int index) onRemoveItem;
  final VoidCallback onClearCart;
  final void Function(PosPaymentMethod method) onCheckout;
  final VoidCallback? onEditDiscount;
  final String? selectedClientName;

  int get _subtotalCents {
    return items.fold(0, (sum, item) => sum + item.totalCents);
  }

  int get _taxCents {
    final taxableSubtotal = items
        .where((i) => i.taxable)
        .fold(0, (sum, item) => sum + item.totalCents);
    final taxableAfterDiscount =
        (taxableSubtotal - discountCents).clamp(0, taxableSubtotal);
    return (taxableAfterDiscount * taxRate).round();
  }

  int get _totalCents {
    return (_subtotalCents - discountCents + _taxCents).clamp(0, _subtotalCents + _taxCents);
  }

  int get _itemCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          // Cart header
          _buildHeader(theme),

          // Client info (if selected)
          if (selectedClientName != null) _buildClientInfo(theme),

          const Divider(height: 1),

          // Cart items
          Expanded(
            child: items.isEmpty
                ? _buildEmptyCart(theme)
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _CartItemTile(
                        item: item,
                        onIncrement: () =>
                            onUpdateQuantity(index, item.quantity + 1),
                        onDecrement: () {
                          if (item.quantity > 1) {
                            onUpdateQuantity(index, item.quantity - 1);
                          } else {
                            onRemoveItem(index);
                          }
                        },
                        onRemove: () => onRemoveItem(index),
                      );
                    },
                  ),
          ),

          // Totals section
          _buildTotals(theme),

          // Payment buttons
          _buildPaymentButtons(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.shopping_cart,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Cart',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_itemCount > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_itemCount item${_itemCount == 1 ? '' : 's'}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear cart',
              onPressed: onClearCart,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClientInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Row(
        children: [
          Icon(
            Icons.person,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              selectedClientName!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Cart is empty',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap products to add them',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotals(ThemeData theme) {
    final taxRatePercent = (taxRate * 100).toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        children: [
          // Subtotal
          _TotalRow(
            label: 'Subtotal',
            amount: _subtotalCents,
          ),

          // Discount
          if (discountCents > 0 || onEditDiscount != null)
            _TotalRow(
              label: 'Discount',
              amount: -discountCents,
              isDiscount: true,
              onTap: onEditDiscount,
            ),

          // Tax
          _TotalRow(
            label: 'Tax ($taxRatePercent%)',
            amount: _taxCents,
          ),

          const Divider(height: 16),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\$${(_totalCents / 100).toStringAsFixed(2)}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButtons(ThemeData theme) {
    final isDisabled = items.isEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isDisabled
                      ? null
                      : () => onCheckout(PosPaymentMethod.cash),
                  icon: const Icon(Icons.payments),
                  label: const Text('Cash'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isDisabled
                      ? null
                      : () => onCheckout(PosPaymentMethod.card),
                  icon: const Icon(Icons.credit_card),
                  label: const Text('Card'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isDisabled
                  ? null
                  : () => onCheckout(PosPaymentMethod.giftCard),
              icon: const Icon(Icons.card_giftcard),
              label: const Text('Gift Card'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cart item tile with quantity controls.
class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey('${item.productId}_${item.quantity}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: theme.colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(
          Icons.delete,
          color: theme.colorScheme.onError,
        ),
      ),
      onDismissed: (_) => onRemove(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Row(
          children: [
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${item.unitPriceDollars.toStringAsFixed(2)} each',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Quantity controls
            Row(
              children: [
                _QuantityButton(
                  icon: Icons.remove,
                  onTap: onDecrement,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '${item.quantity}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _QuantityButton(
                  icon: Icons.add,
                  onTap: onIncrement,
                ),
              ],
            ),

            const SizedBox(width: 16),

            // Line total
            SizedBox(
              width: 70,
              child: Text(
                '\$${item.totalDollars.toStringAsFixed(2)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quantity adjustment button.
class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}

/// Total row in the summary section.
class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.amount,
    this.isDiscount = false,
    this.onTap,
  });

  final String label;
  final int amount;
  final bool isDiscount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayAmount = amount.abs();
    final prefix = isDiscount ? '-' : '';

    Widget row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.edit,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
              ],
            ],
          ),
          Text(
            '$prefix\$${(displayAmount / 100).toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDiscount
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      row = InkWell(
        onTap: onTap,
        child: row,
      );
    }

    return row;
  }
}
