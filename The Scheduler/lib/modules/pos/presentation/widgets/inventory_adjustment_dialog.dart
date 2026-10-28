import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/models/retail_product.dart';
import '../../../../data/models/security_context.dart';
import '../../../../data/repositories/product_repository.dart';

/// Adjustment type for inventory changes.
enum InventoryAdjustmentType {
  received('Received', Icons.add_shopping_cart),
  damaged('Damaged/Broken', Icons.broken_image),
  lost('Lost/Stolen', Icons.search_off),
  correction('Count Correction', Icons.edit_note),
  returned('Customer Return', Icons.assignment_return);

  const InventoryAdjustmentType(this.displayName, this.icon);

  final String displayName;
  final IconData icon;
}

/// Dialog for manually adjusting product inventory.
class InventoryAdjustmentDialog extends StatefulWidget {
  const InventoryAdjustmentDialog({
    super.key,
    required this.product,
    required this.securityContext,
    required this.productRepository,
  });

  final RetailProduct product;
  final SecurityContext securityContext;
  final ProductRepository productRepository;

  @override
  State<InventoryAdjustmentDialog> createState() =>
      _InventoryAdjustmentDialogState();
}

class _InventoryAdjustmentDialogState extends State<InventoryAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();

  InventoryAdjustmentType _adjustmentType = InventoryAdjustmentType.received;
  bool _isSubmitting = false;

  int get _currentQuantity => widget.product.stockQuantity ?? 0;

  int? get _newQuantity {
    final input = int.tryParse(_quantityController.text);
    if (input == null) return null;
    return input;
  }

  int? get _difference {
    final newQty = _newQuantity;
    if (newQty == null) return null;
    return newQty - _currentQuantity;
  }

  @override
  void initState() {
    super.initState();
    _quantityController.text = _currentQuantity.toString();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final newQty = _newQuantity;
    if (newQty == null || newQty == _currentQuantity) {
      Navigator.pop(context, false);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final reason = '${_adjustmentType.displayName}: ${_reasonController.text.trim()}';

      await widget.productRepository.setStockQuantity(
        context: widget.securityContext,
        productId: widget.product.id,
        quantity: newQty,
        reason: reason,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } on ProductException catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adjusting inventory: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diff = _difference;

    return AlertDialog(
      title: const Text('Adjust Inventory'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (widget.product.sku != null)
                            Text(
                              'SKU: ${widget.product.sku}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Current Stock',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          _currentQuantity.toString(),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Adjustment type
              Text('Adjustment Type', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              DropdownButtonFormField<InventoryAdjustmentType>(
                initialValue: _adjustmentType,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.swap_vert),
                ),
                items: InventoryAdjustmentType.values
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Row(
                            children: [
                              Icon(type.icon, size: 20),
                              const SizedBox(width: 8),
                              Text(type.displayName),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _adjustmentType = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // New quantity
              Text('New Quantity', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.numbers),
                  helperText: 'Enter the new stock count',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Quantity is required';
                  }
                  final qty = int.tryParse(value);
                  if (qty == null || qty < 0) {
                    return 'Enter a valid quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Show difference
              if (diff != null && diff != 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: diff > 0
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: diff > 0
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        diff > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        color: diff > 0 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        diff > 0 ? '+$diff units' : '$diff units',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: diff > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Reason
              Text('Reason *', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.notes),
                  hintText: 'Describe the reason for this adjustment',
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a reason';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
