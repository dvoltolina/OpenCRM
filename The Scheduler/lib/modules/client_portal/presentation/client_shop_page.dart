import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/utils/safe_error_handler.dart';
import '../../../data/models/pos_transaction.dart';
import '../../../data/models/retail_product.dart';
import '../../../data/models/security_context.dart';
import 'widgets/client_cart_sheet.dart';
import 'widgets/client_product_card.dart';
import 'widgets/client_product_details_sheet.dart';

/// Client-facing shop/storefront page.
///
/// Allows customers to browse products, add to cart, and checkout.
class ClientShopPage extends ConsumerStatefulWidget {
  const ClientShopPage({
    required this.securityContext,
    required this.config,
    super.key,
  });

  final SecurityContext securityContext;
  final AppConfig config;

  @override
  ConsumerState<ClientShopPage> createState() => _ClientShopPageState();
}

class _ClientShopPageState extends ConsumerState<ClientShopPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  ProductCategory? _selectedCategory;
  final Map<String, int> _cart = {}; // productId -> quantity

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _cartItemCount => _cart.values.fold(0, (sum, qty) => sum + qty);

  int _getCartTotalCents(List<RetailProduct> products) {
    int total = 0;
    for (final entry in _cart.entries) {
      final product = products.firstWhere(
        (p) => p.id == entry.key,
        orElse: () => products.first,
      );
      total += product.priceCents * entry.value;
    }
    return total;
  }

  void _addToCart(RetailProduct product) {
    setState(() {
      _cart[product.id] = (_cart[product.id] ?? 0) + 1;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${product.name} to cart'),
        duration: const Duration(seconds: 1),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () => _showCart(context),
        ),
      ),
    );
  }

  void _updateCartQuantity(String productId, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _cart.remove(productId);
      } else {
        _cart[productId] = quantity;
      }
    });
  }

  List<RetailProduct> _filterProducts(List<RetailProduct> products) {
    var filtered = products.where((p) => p.canBeSold).toList();

    if (_selectedCategory != null) {
      filtered = filtered.where((p) => p.category == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(query) ||
            (p.description?.toLowerCase().contains(query) ?? false) ||
            p.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final branding = widget.config.branding;
    final filter = ProductFilter(
      securityContext: widget.securityContext,
      availableForSale: true,
    );
    final productsAsync = ref.watch(productsStreamProvider(filter));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    branding.primaryColor,
                    branding.primaryColor.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Shop',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (_cartItemCount > 0)
                          Badge(
                            label: Text('$_cartItemCount'),
                            child: IconButton(
                              onPressed: () => _showCart(context),
                              icon: const Icon(Icons.shopping_cart),
                              color: Colors.white,
                              tooltip: 'View Cart',
                            ),
                          )
                        else
                          IconButton(
                            onPressed: () => _showCart(context),
                            icon: const Icon(Icons.shopping_cart_outlined),
                            color: Colors.white,
                            tooltip: 'View Cart',
                          ),
                      ],
                    ),
                    VSpace.md,
                    // Search bar
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey.shade600),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: AppSpacing.sm),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Category filter chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _CategoryChip(
                    label: 'All',
                    isSelected: _selectedCategory == null,
                    onTap: () => setState(() => _selectedCategory = null),
                    primaryColor: branding.primaryColor,
                  ),
                  ...ProductCategory.values.map((category) => _CategoryChip(
                        label: category.displayName,
                        isSelected: _selectedCategory == category,
                        onTap: () => setState(() => _selectedCategory = category),
                        primaryColor: branding.primaryColor,
                      )),
                ],
              ),
            ),
          ),

          // Products grid
          productsAsync.when(
            data: (products) {
              final filtered = _filterProducts(products);
              if (filtered.isEmpty) {
                return SliverFillRemaining(child: _buildEmptyState(theme));
              }
              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = filtered[index];
                      return ClientProductCard(
                        product: product,
                        onTap: () => _showProductDetails(product),
                        onAddToCart: () => _addToCart(product),
                        primaryColor: branding.primaryColor,
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => SliverFillRemaining(
              child: Center(child: Text(SafeErrorHandler.handle(error))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            VSpace.md,
            Text(
              _searchQuery.isNotEmpty || _selectedCategory != null
                  ? 'No products match your search'
                  : 'No products available',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty || _selectedCategory != null) ...[
              VSpace.md,
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _selectedCategory = null;
                  });
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showProductDetails(RetailProduct product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ClientProductDetailsSheet(
        product: product,
        onAddToCart: () {
          _addToCart(product);
          Navigator.pop(context);
        },
        primaryColor: widget.config.branding.primaryColor,
      ),
    );
  }

  void _showCart(BuildContext context) {
    final filter = ProductFilter(
      securityContext: widget.securityContext,
      availableForSale: true,
    );
    final productsAsync = ref.read(productsStreamProvider(filter));

    productsAsync.when(
      data: (products) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => ClientCartSheet(
            cart: _cart,
            products: products,
            onUpdateQuantity: _updateCartQuantity,
            onCheckout: () => _handleCheckout(products),
            primaryColor: widget.config.branding.primaryColor,
          ),
        );
      },
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loading products...'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(SafeErrorHandler.handle(error))),
        );
      },
    );
  }

  Future<void> _handleCheckout(List<RetailProduct> products) async {
    if (_cart.isEmpty) return;

    Navigator.pop(context); // Close cart sheet

    final totalCents = _getCartTotalCents(products);

    // Show checkout confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Purchase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total: \$${(totalCents / 100).toStringAsFixed(2)}'),
            VSpace.xs,
            Text(
              '$_cartItemCount item${_cartItemCount == 1 ? '' : 's'} in your cart',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Process payment via Stripe
    try {
      final posService = ref.read(posServiceProvider);
      final stripeService = ref.read(stripeServiceProvider);

      // Build cart items using model from pos_transaction.dart
      final cartItems = _cart.entries.map((entry) {
        final product = products.firstWhere((p) => p.id == entry.key);
        return CartItem(
          productId: product.id,
          productName: product.name,
          quantity: entry.value,
          unitPriceCents: product.priceCents,
          taxable: product.taxable,
        );
      }).toList();

      // Create the transaction first
      final transaction = await posService.createTransaction(
        context: widget.securityContext,
        items: cartItems,
        paymentMethod: PosPaymentMethod.card,
        clientId: widget.securityContext.userId,
      );

      // Get the client secret for Stripe payment
      final paymentResult = await posService.processCardPayment(
        context: widget.securityContext,
        transactionId: transaction.id,
      );

      // Present payment sheet
      final paymentSuccess = await stripeService.presentPaymentSheet(
        clientSecret: paymentResult.clientSecret,
      );

      if (!paymentSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment cancelled')),
          );
        }
        return;
      }

      // Complete the card payment
      await posService.completeCardPayment(
        context: widget.securityContext,
        transactionId: transaction.id,
        paymentIntentId: paymentResult.clientSecret.split('_secret_').first,
      );

      // Clear cart and show success
      setState(() => _cart.clear());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Purchase complete! Check your email for receipt.'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(SafeErrorHandler.handle(e))),
        );
      }
    }
  }
}

/// Category filter chip.
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.primaryColor,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: primaryColor.withValues(alpha: 0.2),
        checkmarkColor: primaryColor,
      ),
    );
  }
}
