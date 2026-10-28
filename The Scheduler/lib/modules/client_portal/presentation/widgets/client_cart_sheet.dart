import 'package:flutter/material.dart';

import '../../../../data/models/retail_product.dart';

/// Shopping cart bottom sheet for client shop.
///
/// Displays cart items with quantity controls and checkout button.
class ClientCartSheet extends StatelessWidget {
  const ClientCartSheet({
    super.key,
    required this.cart,
    required this.products,
    required this.onUpdateQuantity,
    required this.onCheckout,
    required this.primaryColor,
  });

  final Map<String, int> cart;
  final List<RetailProduct> products;
  final void Function(String productId, int quantity) onUpdateQuantity;
  final VoidCallback onCheckout;
  final Color primaryColor;

  int get _totalCents {
    int total = 0;
    for (final entry in cart.entries) {
      final product = products.firstWhere(
        (p) => p.id == entry.key,
        orElse: () => products.first,
      );
      total += product.priceCents * entry.value;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(Icons.shopping_cart, color: primaryColor),
                const SizedBox(width: 12),
                Text(
                  'Your Cart',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Cart items
          Expanded(
            child: cart.isEmpty
                ? _buildEmptyCart(theme)
                : ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: cart.length,
                    separatorBuilder: (_, idx) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final entry = cart.entries.elementAt(index);
                      final product = products.firstWhere(
                        (p) => p.id == entry.key,
                        orElse: () => products.first,
                      );
                      return _CartItemTile(
                        product: product,
                        quantity: entry.value,
                        onUpdateQuantity: (qty) => onUpdateQuantity(product.id, qty),
                        primaryColor: primaryColor,
                      );
                    },
                  ),
          ),

          // Checkout section
          if (cart.isNotEmpty)
            Container(
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                16 + MediaQuery.paddingOf(context).bottom,
              ),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: theme.textTheme.titleMedium),
                      Text(
                        '\$${(_totalCents / 100).toStringAsFixed(2)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: onCheckout,
                      icon: const Icon(Icons.payment),
                      label: const Text('Checkout'),
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
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
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some products to get started',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
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
    required this.product,
    required this.quantity,
    required this.onUpdateQuantity,
    required this.primaryColor,
  });

  final RetailProduct product;
  final int quantity;
  final ValueChanged<int> onUpdateQuantity;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtotal = product.priceCents * quantity;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Product image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: product.imageUrl != null
                ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                : Icon(
                    Icons.inventory_2,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
          ),
          const SizedBox(width: 12),

          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.priceDisplay} each',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Quantity controls
          Row(
            children: [
              IconButton(
                onPressed: () => onUpdateQuantity(quantity - 1),
                icon: Icon(
                  quantity == 1 ? Icons.delete_outline : Icons.remove,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  foregroundColor: quantity == 1 ? Colors.red : null,
                ),
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '$quantity',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => onUpdateQuantity(quantity + 1),
                icon: const Icon(Icons.add, size: 20),
              ),
            ],
          ),
          const SizedBox(width: 8),

          // Subtotal
          SizedBox(
            width: 60,
            child: Text(
              '\$${(subtotal / 100).toStringAsFixed(2)}',
              textAlign: TextAlign.end,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
