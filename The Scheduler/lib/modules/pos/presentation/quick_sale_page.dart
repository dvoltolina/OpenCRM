import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/services/pos_service.dart';
import '../../../core/ui/ui_exports.dart';
import '../../../data/models/client.dart';
import '../../../data/models/pos_transaction.dart';
import '../../../data/models/retail_product.dart';
import '../../../data/models/security_context.dart';
import 'transaction_history_page.dart';
import 'widgets/cart_panel.dart';
import 'widgets/payment_dialog.dart';
import 'widgets/product_grid.dart';
import 'widgets/quick_sale_dialogs.dart';

/// QuickSalePage is the main POS register interface.
///
/// Features:
/// - Split layout with product grid and cart panel
/// - Optional client selection for tracking purchases
/// - Support for cash, card, and gift card payments
/// - Responsive design for tablet and desktop
class QuickSalePage extends ConsumerStatefulWidget {
  const QuickSalePage({
    super.key,
    this.clientId,
    this.clientName,
    this.appointmentId,
  });

  /// Pre-selected client ID (e.g., from appointment).
  final String? clientId;

  /// Pre-selected client name.
  final String? clientName;

  /// Linked appointment ID (for add-on sales during appointments).
  final String? appointmentId;

  @override
  ConsumerState<QuickSalePage> createState() => _QuickSalePageState();
}

class _QuickSalePageState extends ConsumerState<QuickSalePage> {
  final List<CartItem> _cart = [];
  String? _selectedClientId;
  String? _selectedClientName;
  int _discountCents = 0;
  String? _discountReason;

  PosService get _posService => ref.read(posServiceProvider);

  // Default tax rate - could be fetched from business config
  static const double _taxRate = 0.0825;

  @override
  void initState() {
    super.initState();
    _selectedClientId = widget.clientId;
    _selectedClientName = widget.clientName;
  }

  void _addToCart(RetailProduct product) {
    setState(() {
      final existingIndex = _cart.indexWhere((item) => item.productId == product.id);
      if (existingIndex >= 0) {
        final existing = _cart[existingIndex];
        _cart[existingIndex] = existing.copyWith(quantity: existing.quantity + 1);
      } else {
        _cart.add(CartItem(
          productId: product.id,
          productName: product.name,
          sku: product.sku,
          unitPriceCents: product.priceCents,
          quantity: 1,
          taxable: product.taxable,
        ));
      }
    });
  }

  void _updateQuantity(int index, int quantity) {
    if (index < 0 || index >= _cart.length) return;
    setState(() {
      if (quantity <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index] = _cart[index].copyWith(quantity: quantity);
      }
    });
  }

  void _removeItem(int index) {
    if (index < 0 || index >= _cart.length) return;
    setState(() {
      _cart.removeAt(index);
    });
  }

  void _clearCart() {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to clear all items from the cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        setState(() {
          _cart.clear();
          _discountCents = 0;
          _discountReason = null;
        });
      }
    });
  }

  Future<void> _selectClient(SecurityContext securityContext) async {
    final result = await showDialog<Client>(
      context: context,
      builder: (context) => ClientSearchDialog(securityContext: securityContext),
    );

    if (result != null) {
      setState(() {
        _selectedClientId = result.id;
        _selectedClientName = result.fullName;
      });
    }
  }

  void _clearClient() {
    setState(() {
      _selectedClientId = null;
      _selectedClientName = null;
    });
  }

  Future<void> _editDiscount() async {
    final result = await showDialog<DiscountResult>(
      context: context,
      builder: (context) => DiscountDialog(
        currentDiscountCents: _discountCents,
        currentReason: _discountReason,
        maxDiscountCents: _calculateSubtotal(),
      ),
    );

    if (result != null) {
      setState(() {
        _discountCents = result.amountCents;
        _discountReason = result.reason;
      });
    }
  }

  int _calculateSubtotal() {
    return _cart.fold(0, (sum, item) => sum + item.totalCents);
  }

  Future<void> _checkout(
    PosPaymentMethod method,
    SecurityContext securityContext,
  ) async {
    if (_cart.isEmpty) return;

    final summary = _posService.calculateCartSummary(
      items: _cart,
      taxRate: _taxRate,
      discountCents: _discountCents,
    );

    final result = await showDialog<PaymentDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentDialog(
        securityContext: securityContext,
        totalCents: summary.totalCents,
        paymentMethod: method,
        onProcessPayment: ({
          required PosPaymentMethod method,
          int? cashTenderedCents,
          String? giftCardCode,
        }) async {
          return _processPayment(
            securityContext: securityContext,
            method: method,
            cashTenderedCents: cashTenderedCents,
            giftCardCode: giftCardCode,
          );
        },
      ),
    );

    if (result != null && result.success && mounted) {
      // Clear cart after successful payment
      setState(() {
        _cart.clear();
        _discountCents = 0;
        _discountReason = null;
        // Keep client selected for convenience
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sale completed! Receipt #${result.receiptNumber ?? result.transaction?.receiptDisplay ?? 'N/A'}',
          ),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              // Navigate to transaction detail if needed
            },
          ),
        ),
      );
    }
  }

  Future<PaymentDialogResult> _processPayment({
    required SecurityContext securityContext,
    required PosPaymentMethod method,
    int? cashTenderedCents,
    String? giftCardCode,
  }) async {
    try {
      // Create the transaction
      final transaction = await _posService.createTransaction(
        context: securityContext,
        items: _cart,
        paymentMethod: method,
        clientId: _selectedClientId,
        clientName: _selectedClientName,
        appointmentId: widget.appointmentId,
        discountCents: _discountCents,
        discountReason: _discountReason,
        taxRate: _taxRate,
      );

      // Process payment based on method
      SaleCompletionResult completionResult;

      switch (method) {
        case PosPaymentMethod.cash:
          completionResult = await _posService.processCashPayment(
            context: securityContext,
            transactionId: transaction.id,
            cashTenderedCents: cashTenderedCents!,
          );
          break;

        case PosPaymentMethod.card:
          // Get payment intent
          final cardResult = await _posService.processCardPayment(
            context: securityContext,
            transactionId: transaction.id,
          );

          // Present Stripe payment sheet
          final stripeService = ref.read(stripeServiceProvider);
          final paymentSuccess = await stripeService.presentPaymentSheet(
            clientSecret: cardResult.clientSecret,
          );

          if (!paymentSuccess) {
            return const PaymentDialogResult(
              success: false,
              error: 'Card payment was cancelled or failed',
            );
          }

          // Complete the payment
          completionResult = await _posService.completeCardPayment(
            context: securityContext,
            transactionId: transaction.id,
            paymentIntentId: cardResult.paymentIntentId ?? '',
          );
          break;

        case PosPaymentMethod.giftCard:
          completionResult = await _posService.processGiftCardPayment(
            context: securityContext,
            transactionId: transaction.id,
            giftCardCode: giftCardCode!,
          );
          break;

        default:
          return PaymentDialogResult(
            success: false,
            error: '${method.displayName} payments are not yet supported',
          );
      }

      if (completionResult.success) {
        return PaymentDialogResult(
          success: true,
          transaction: completionResult.transaction,
          receiptNumber: completionResult.transaction.receiptNumber,
        );
      } else {
        return PaymentDialogResult(
          success: false,
          error: completionResult.error ?? 'Payment failed',
        );
      }
    } on PosServiceException catch (e) {
      return PaymentDialogResult(
        success: false,
        error: e.message,
      );
    } catch (e) {
      return PaymentDialogResult(
        success: false,
        error: 'Payment failed: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final securityContextAsync = ref.watch(securityContextProvider);

    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Controls row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Client selector
                  Expanded(
                    child: securityContextAsync.maybeWhen(
                      data: (securityContext) {
                        if (securityContext == null) return const SizedBox.shrink();
                        return _buildClientSelector(securityContext);
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ),
                  // History button
                  IconButton(
                    icon: const Icon(Icons.history),
                    tooltip: 'Transaction History',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TransactionHistoryPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: securityContextAsync.when(
                data: (securityContext) {
                  if (securityContext == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return _buildBody(securityContext);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: ErrorFeedback(message: 'Error: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientSelector(SecurityContext securityContext) {
    if (_selectedClientId != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Chip(
          avatar: const Icon(Icons.person, size: 18),
          label: Text(_selectedClientName ?? 'Client'),
          onDeleted: _clearClient,
          deleteIcon: const Icon(Icons.close, size: 18),
        ),
      );
    }

    return TextButton.icon(
      onPressed: () => _selectClient(securityContext),
      icon: const Icon(Icons.person_add),
      label: const Text('Add Client'),
    );
  }

  Widget _buildBody(SecurityContext securityContext) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use side-by-side layout for tablets and wider screens
        final isWideScreen = constraints.maxWidth >= 800;

        if (isWideScreen) {
          return Row(
            children: [
              // Product grid (left side - 60%)
              Expanded(
                flex: 6,
                child: ProductGrid(
                  securityContext: securityContext,
                  onProductSelected: _addToCart,
                ),
              ),

              // Divider
              const VerticalDivider(width: 1),

              // Cart panel (right side - 40%)
              SizedBox(
                width: 380,
                child: CartPanel(
                  items: _cart,
                  taxRate: _taxRate,
                  discountCents: _discountCents,
                  onUpdateQuantity: _updateQuantity,
                  onRemoveItem: _removeItem,
                  onClearCart: _clearCart,
                  onCheckout: (method) => _checkout(method, securityContext),
                  onEditDiscount: _cart.isNotEmpty ? _editDiscount : null,
                  selectedClientName: _selectedClientName,
                ),
              ),
            ],
          );
        }

        // Stacked layout for narrow screens - use tabs
        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'Products', icon: Icon(Icons.grid_view)),
                  Tab(text: 'Cart', icon: Icon(Icons.shopping_cart)),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    ProductGrid(
                      securityContext: securityContext,
                      onProductSelected: _addToCart,
                    ),
                    CartPanel(
                      items: _cart,
                      taxRate: _taxRate,
                      discountCents: _discountCents,
                      onUpdateQuantity: _updateQuantity,
                      onRemoveItem: _removeItem,
                      onClearCart: _clearCart,
                      onCheckout: (method) => _checkout(method, securityContext),
                      onEditDiscount: _cart.isNotEmpty ? _editDiscount : null,
                      selectedClientName: _selectedClientName,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
