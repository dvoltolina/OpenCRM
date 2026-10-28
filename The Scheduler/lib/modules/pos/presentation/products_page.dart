import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/ui_exports.dart';
import '../../../data/models/retail_product.dart';
import '../../../data/models/security_context.dart';
import '../../../data/repositories/product_repository.dart';
import 'widgets/inventory_adjustment_dialog.dart';
import 'widgets/product_form_dialog.dart';
import 'widgets/product_list_item.dart';

/// ProductsPage displays and manages retail products for the POS system.
/// Admin-only access - allows viewing, creating, editing, and managing inventory.
class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  ProductRepository get _productRepository =>
      ref.read(productRepositoryProvider);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ProductCategory? _selectedCategory;
  StockFilter _stockFilter = StockFilter.all;
  ProductSortOption _sortOption = ProductSortOption.name;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  List<RetailProduct> _filterAndSortProducts(List<RetailProduct> products) {
    var filtered = products;

    // Text search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.name.toLowerCase().contains(_searchQuery) ||
            (product.description?.toLowerCase().contains(_searchQuery) ??
                false) ||
            (product.sku?.toLowerCase().contains(_searchQuery) ?? false) ||
            (product.barcode?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    // Category filter
    if (_selectedCategory != null) {
      filtered =
          filtered.where((p) => p.category == _selectedCategory).toList();
    }

    // Stock filter
    switch (_stockFilter) {
      case StockFilter.all:
        break;
      case StockFilter.inStock:
        filtered = filtered.where((p) => !p.isOutOfStock).toList();
      case StockFilter.lowStock:
        filtered = filtered.where((p) => p.isLowStock).toList();
      case StockFilter.outOfStock:
        filtered = filtered.where((p) => p.isOutOfStock).toList();
    }

    // Sort
    switch (_sortOption) {
      case ProductSortOption.name:
        filtered.sort((a, b) => a.name.compareTo(b.name));
      case ProductSortOption.priceAsc:
        filtered.sort((a, b) => a.priceCents.compareTo(b.priceCents));
      case ProductSortOption.priceDesc:
        filtered.sort((a, b) => b.priceCents.compareTo(a.priceCents));
      case ProductSortOption.dateAdded:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return filtered;
  }

  int _getLowStockCount(List<RetailProduct> products) {
    return products.where((p) => p.isLowStock).length;
  }

  Future<void> _showNewProductDialog(SecurityContext securityContext) async {
    if (!context.mounted) return;
    final result = await showDialog<RetailProduct>(
      context: context,
      builder: (context) => ProductFormDialog(
        securityContext: securityContext,
        productRepository: _productRepository,
      ),
    );
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product "${result.name}" created successfully')),
      );
    }
  }

  Future<void> _showEditProductDialog(
    RetailProduct product,
    SecurityContext securityContext,
  ) async {
    if (!mounted) return;
    final result = await showDialog<RetailProduct>(
      context: context,
      builder: (context) => ProductFormDialog(
        product: product,
        securityContext: securityContext,
        productRepository: _productRepository,
      ),
    );
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product "${result.name}" updated successfully')),
      );
    }
  }

  Future<void> _showInventoryAdjustmentDialog(
    RetailProduct product,
    SecurityContext securityContext,
  ) async {
    if (!mounted) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => InventoryAdjustmentDialog(
        product: product,
        securityContext: securityContext,
        productRepository: _productRepository,
      ),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Inventory for "${product.name}" updated')),
      );
    }
  }

  Future<void> _deleteProduct(
    RetailProduct product,
    SecurityContext securityContext,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete "${product.name}"? '
          'This will hide the product from the catalog.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _deleteProductSilent(product, securityContext);
  }

  Future<void> _deleteProductSilent(
    RetailProduct product,
    SecurityContext securityContext,
  ) async {
    try {
      await _productRepository.deleteProduct(
        context: securityContext,
        productId: product.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product "${product.name}" deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting product: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final securityContextAsync = ref.watch(securityContextProvider);

    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Search and sort controls
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search by name, SKU, or barcode...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  HSpace.xs,
                  PopupMenuButton<ProductSortOption>(
                    icon: const Icon(Icons.sort),
                    tooltip: 'Sort',
                    onSelected: (option) => setState(() => _sortOption = option),
                    itemBuilder: (context) => ProductSortOption.values
                        .map((option) => PopupMenuItem(
                              value: option,
                              child: Row(
                                children: [
                                  if (_sortOption == option)
                                    const Icon(Icons.check, size: 18)
                                  else
                                    const SizedBox(width: 18),
                                  HSpace.xs,
                                  Text(option.displayName),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: securityContextAsync.when(
                data: (securityContext) {
                  if (securityContext == null) {
                    return _buildLoadingSkeleton();
                  }

                  final filter = ProductFilter(securityContext: securityContext);
                  final productsAsync = ref.watch(productsStreamProvider(filter));

                  return _buildProductsBody(
                    theme: theme,
                    securityContext: securityContext,
                    productsAsync: productsAsync,
                  );
                },
                loading: _buildLoadingSkeleton,
                error: (error, stackTrace) => Center(
                  child: ErrorFeedback(message: 'Error loading products: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: securityContextAsync.maybeWhen(
        data: (securityContext) {
          if (securityContext == null) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => _showNewProductDialog(securityContext),
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildProductsBody({
    required ThemeData theme,
    required SecurityContext securityContext,
    required AsyncValue<List<RetailProduct>> productsAsync,
  }) {
    if (productsAsync.isLoading) {
      return _buildLoadingSkeleton();
    }
    if (productsAsync.hasError) {
      return Center(
        child: ErrorFeedback(
          message: 'Error loading products: ${productsAsync.error}',
        ),
      );
    }

    final allProducts = productsAsync.value ?? <RetailProduct>[];
    final lowStockCount = _getLowStockCount(allProducts);
    final products = _filterAndSortProducts(allProducts);

    if (allProducts.isEmpty) {
      return _buildEmptyState(theme, securityContext);
    }

    return Column(
      children: [
        // Low stock alert banner
        if (lowStockCount > 0) _buildLowStockBanner(theme, lowStockCount),

        // Filter chips
        _buildFilterChips(theme),
        const Divider(height: 1),

        // Products list
        Expanded(
          child: products.isEmpty
              ? _buildNoResultsState(theme)
              : _buildProductsList(products, securityContext, theme),
        ),
      ],
    );
  }

  Widget _buildLowStockBanner(ThemeData theme, int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: theme.colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: theme.colorScheme.onErrorContainer),
          HSpace.sm,
          Expanded(
            child: Text(
              '$count product${count == 1 ? '' : 's'} ${count == 1 ? 'is' : 'are'} low on stock',
              style: TextStyle(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _stockFilter = StockFilter.lowStock),
            child: Text('View', style: TextStyle(color: theme.colorScheme.onErrorContainer)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildCategoryChip(theme),
          HSpace.xs,
          ...StockFilter.values.map((filter) {
            final isSelected = _stockFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Text(filter.displayName),
                onSelected: (_) {
                  setState(() {
                    _stockFilter = isSelected ? StockFilter.all : filter;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(ThemeData theme) {
    return PopupMenuButton<ProductCategory?>(
      child: Chip(
        avatar: const Icon(Icons.category, size: 18),
        label: Text(_selectedCategory?.displayName ?? 'All Categories'),
        deleteIcon: _selectedCategory != null ? const Icon(Icons.clear, size: 18) : null,
        onDeleted: _selectedCategory != null ? () => setState(() => _selectedCategory = null) : null,
      ),
      itemBuilder: (context) => [
        const PopupMenuItem<ProductCategory?>(value: null, child: Text('All Categories')),
        const PopupMenuDivider(),
        ...ProductCategory.values.map((category) => PopupMenuItem(
              value: category,
              child: Text(category.displayName),
            )),
      ],
      onSelected: (category) => setState(() => _selectedCategory = category),
    );
  }

  Widget _buildProductsList(
    List<RetailProduct> products,
    SecurityContext securityContext,
    ThemeData theme,
  ) {
    return ListView.builder(
      padding: AppSpacing.cardPadding,
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Dismissible(
          key: Key(product.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Product'),
                content: Text('Are you sure you want to delete "${product.name}"?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) => _deleteProductSilent(product, securityContext),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(Icons.delete, color: theme.colorScheme.onErrorContainer),
          ),
          child: ProductListItem(
            product: product,
            onTap: () => _showEditProductDialog(product, securityContext),
            onAdjustInventory: product.trackInventory
                ? () => _showInventoryAdjustmentDialog(product, securityContext)
                : null,
            onDelete: () => _deleteProduct(product, securityContext),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme, SecurityContext securityContext) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          VSpace.lg,
          Text('No Products Yet', style: theme.textTheme.headlineSmall),
          VSpace.xs,
          Text(
            'Add your first product to start selling',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          VSpace.lg,
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _showNewProductDialog(securityContext),
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          VSpace.md,
          Text('No products match your filters', style: theme.textTheme.titleMedium),
          VSpace.xs,
          TextButton(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
                _selectedCategory = null;
                _stockFilter = StockFilter.all;
              });
            },
            child: const Text('Clear filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Center(child: buildSkeletonList(count: 5));
  }
}
