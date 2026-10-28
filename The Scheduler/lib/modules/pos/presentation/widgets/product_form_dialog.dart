import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/models/retail_product.dart';
import '../../../../data/models/security_context.dart';
import '../../../../data/repositories/product_repository.dart';
import 'product_image_picker.dart';

/// Dialog for creating or editing a retail product.
class ProductFormDialog extends StatefulWidget {
  const ProductFormDialog({
    super.key,
    this.product,
    required this.securityContext,
    required this.productRepository,
  });

  final RetailProduct? product;
  final SecurityContext securityContext;
  final ProductRepository productRepository;

  bool get isEditing => product != null;

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _stockQuantityController = TextEditingController();
  final _lowStockThresholdController = TextEditingController();
  final _tagsController = TextEditingController();

  ProductCategory _selectedCategory = ProductCategory.other;
  bool _trackInventory = false;
  bool _taxable = true;
  bool _isSubmitting = false;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _populateForm(widget.product!);
    }
  }

  void _populateForm(RetailProduct product) {
    _nameController.text = product.name;
    _descriptionController.text = product.description ?? '';
    _priceController.text = product.priceDollars.toStringAsFixed(2);
    if (product.costCents != null) {
      _costController.text = product.costDollars!.toStringAsFixed(2);
    }
    _skuController.text = product.sku ?? '';
    _barcodeController.text = product.barcode ?? '';
    _selectedCategory = product.category;
    _trackInventory = product.trackInventory;
    if (product.stockQuantity != null) {
      _stockQuantityController.text = product.stockQuantity.toString();
    }
    if (product.lowStockThreshold != null) {
      _lowStockThresholdController.text = product.lowStockThreshold.toString();
    }
    _tagsController.text = product.tags.join(', ');
    _taxable = product.taxable;
    _imageUrl = product.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _stockQuantityController.dispose();
    _lowStockThresholdController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  int _parsePriceToCents(String value) {
    final parsed = double.tryParse(value) ?? 0.0;
    return (parsed * 100).round();
  }

  List<String> _parseTags(String value) {
    if (value.trim().isEmpty) return [];
    return value.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final priceCents = _parsePriceToCents(_priceController.text);
      final costCents = _costController.text.trim().isEmpty ? null : _parsePriceToCents(_costController.text);
      final tags = _parseTags(_tagsController.text);
      final stockQuantity = _trackInventory && _stockQuantityController.text.isNotEmpty
          ? int.tryParse(_stockQuantityController.text)
          : null;
      final lowStockThreshold = _trackInventory && _lowStockThresholdController.text.isNotEmpty
          ? int.tryParse(_lowStockThresholdController.text)
          : null;

      RetailProduct result;

      if (widget.isEditing) {
        result = await widget.productRepository.updateProduct(
          context: widget.securityContext,
          productId: widget.product!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          priceCents: priceCents,
          costCents: costCents,
          sku: _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
          barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
          category: _selectedCategory,
          tags: tags,
          trackInventory: _trackInventory,
          stockQuantity: stockQuantity,
          lowStockThreshold: lowStockThreshold,
          taxable: _taxable,
          imageUrl: _imageUrl,
        );
      } else {
        result = await widget.productRepository.createProduct(
          context: widget.securityContext,
          name: _nameController.text.trim(),
          priceCents: priceCents,
          category: _selectedCategory,
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          costCents: costCents,
          sku: _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
          barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
          tags: tags,
          trackInventory: _trackInventory,
          stockQuantity: stockQuantity,
          lowStockThreshold: lowStockThreshold,
          taxable: _taxable,
          imageUrl: _imageUrl,
        );
      }

      if (mounted) {
        Navigator.pop(context, result);
      }
    } on ProductException catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error ${widget.isEditing ? 'updating' : 'creating'} product: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.isEditing ? 'Edit Product' : 'Add Product'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              TextButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(widget.isEditing ? 'Save' : 'Create'),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildBasicInfoSection(theme),
                const SizedBox(height: 24),
                _buildImageSection(theme),
                const SizedBox(height: 24),
                _buildPricingSection(theme),
                const SizedBox(height: 24),
                _buildIdentificationSection(theme),
                const SizedBox(height: 24),
                _buildInventorySection(theme),
                const SizedBox(height: 24),
                _buildTagsSection(theme),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Basic Information', style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Product Name *', prefixIcon: Icon(Icons.inventory_2)),
          textCapitalization: TextCapitalization.words,
          validator: (value) => (value == null || value.trim().isEmpty) ? 'Product name is required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description)),
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<ProductCategory>(
          initialValue: _selectedCategory,
          decoration: const InputDecoration(labelText: 'Category *', prefixIcon: Icon(Icons.category)),
          items: ProductCategory.values
              .map((cat) => DropdownMenuItem(value: cat, child: Text(cat.displayName)))
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _selectedCategory = value);
          },
        ),
      ],
    );
  }

  Widget _buildImageSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Product Image', style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        ProductImagePicker(
          securityContext: widget.securityContext,
          imageUrl: _imageUrl,
          onImageChanged: (url) => setState(() => _imageUrl = url),
        ),
      ],
    );
  }

  Widget _buildPricingSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pricing', style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price *', prefixIcon: Icon(Icons.attach_money), prefixText: '\$ '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Price is required';
                  final price = double.tryParse(value);
                  if (price == null || price < 0) return 'Enter a valid price';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _costController,
                decoration: const InputDecoration(
                  labelText: 'Cost (optional)',
                  prefixIcon: Icon(Icons.money_off),
                  prefixText: '\$ ',
                  helperText: 'For profit tracking',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Taxable'),
          subtitle: const Text('Apply sales tax to this product'),
          value: _taxable,
          onChanged: (value) => setState(() => _taxable = value),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildIdentificationSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Identification', style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(labelText: 'SKU', prefixIcon: Icon(Icons.qr_code), helperText: 'Stock Keeping Unit'),
                textCapitalization: TextCapitalization.characters,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _barcodeController,
                decoration: InputDecoration(
                  labelText: 'Barcode',
                  prefixIcon: const Icon(Icons.barcode_reader),
                  helperText: 'UPC/EAN code',
                  suffixIcon: IconButton(icon: const Icon(Icons.camera_alt), onPressed: _scanBarcode, tooltip: 'Scan barcode'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInventorySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Inventory', style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Track Inventory'),
          subtitle: const Text('Monitor stock levels for this product'),
          value: _trackInventory,
          onChanged: (value) => setState(() => _trackInventory = value),
          contentPadding: EdgeInsets.zero,
        ),
        if (_trackInventory) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _stockQuantityController,
                  decoration: const InputDecoration(labelText: 'Current Stock', prefixIcon: Icon(Icons.inventory)),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (_trackInventory && (value == null || value.isEmpty)) return 'Stock quantity required';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _lowStockThresholdController,
                  decoration: const InputDecoration(
                    labelText: 'Low Stock Alert',
                    prefixIcon: Icon(Icons.warning_amber),
                    helperText: 'Alert when below',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTagsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tags', style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        TextFormField(
          controller: _tagsController,
          decoration: const InputDecoration(
            labelText: 'Tags',
            prefixIcon: Icon(Icons.label),
            helperText: 'Separate tags with commas',
            hintText: 'e.g., bestseller, new, organic',
          ),
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }

  void _scanBarcode() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Barcode scanning requires mobile_scanner package'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
