import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/user_messages.dart';
import '../../../../core/providers/providers.dart';
import '../../../../data/models/gift_card_template.dart';
import '../../../../data/models/security_context.dart';
import 'template_color_picker.dart';

/// Dialog for creating or editing a gift card template.
///
/// Features:
/// - Live preview of template design
/// - Name, description, and image URL fields
/// - Background and text color pickers
/// - Preset amounts configuration
/// - Min/max amount constraints
/// - Validity days configuration
class TemplateEditorDialog extends ConsumerStatefulWidget {
  const TemplateEditorDialog({
    required this.securityContext,
    this.template,
    super.key,
  });

  final SecurityContext securityContext;
  final GiftCardTemplate? template;

  @override
  ConsumerState<TemplateEditorDialog> createState() =>
      _TemplateEditorDialogState();
}

class _TemplateEditorDialogState extends ConsumerState<TemplateEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _minAmountController;
  late final TextEditingController _maxAmountController;
  late final TextEditingController _validityDaysController;

  late Color _backgroundColor;
  late Color _textColor;
  late List<int> _presetAmountsCents;

  bool _isSubmitting = false;
  final _presetAmountController = TextEditingController();

  bool get _isEditing => widget.template != null;

  @override
  void initState() {
    super.initState();
    final template = widget.template;

    _nameController = TextEditingController(text: template?.name ?? '');
    _descriptionController =
        TextEditingController(text: template?.description ?? '');
    _imageUrlController = TextEditingController(text: template?.imageUrl ?? '');
    _minAmountController = TextEditingController(
      text: template?.minAmountDollars?.toStringAsFixed(0) ?? '',
    );
    _maxAmountController = TextEditingController(
      text: template?.maxAmountDollars?.toStringAsFixed(0) ?? '',
    );
    _validityDaysController = TextEditingController(
      text: template?.validityDays?.toString() ?? '',
    );

    _backgroundColor = template != null
        ? _parseColor(template.backgroundColor)
        : Colors.indigo;
    _textColor =
        template != null ? _parseColor(template.textColor) : Colors.white;
    _presetAmountsCents =
        List<int>.from(template?.presetAmountsCents ?? [2500, 5000, 10000]);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _validityDaysController.dispose();
    _presetAmountController.dispose();
    super.dispose();
  }

  Color _parseColor(String hex) {
    try {
      final hexCode = hex.replaceAll('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  String _colorToHex(Color color) {
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();
    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Template' : 'New Template'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Preview Card
                _buildPreviewCard(),
                const SizedBox(height: 24),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Template Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Description is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Image URL
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL (optional)',
                    border: OutlineInputBorder(),
                    hintText: 'https://example.com/image.jpg',
                  ),
                ),
                const SizedBox(height: 16),

                // Colors
                Row(
                  children: [
                    Expanded(
                      child: ColorPickerField(
                        label: 'Background',
                        color: _backgroundColor,
                        onColorChanged: (color) {
                          setState(() => _backgroundColor = color);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ColorPickerField(
                        label: 'Text',
                        color: _textColor,
                        onColorChanged: (color) {
                          setState(() => _textColor = color);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Preset Amounts
                _buildPresetAmountsSection(),
                const SizedBox(height: 16),

                // Min/Max Amounts
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minAmountController,
                        decoration: const InputDecoration(
                          labelText: 'Min Amount',
                          prefixText: '\$',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _maxAmountController,
                        decoration: const InputDecoration(
                          labelText: 'Max Amount',
                          prefixText: '\$',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Validity Days
                TextFormField(
                  controller: _validityDaysController,
                  decoration: const InputDecoration(
                    labelText: 'Validity Days (blank = never expires)',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., 365',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEditing ? 'Save' : 'Create'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (_imageUrlController.text.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _imageUrlController.text,
                width: double.infinity,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => const SizedBox(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.card_giftcard, color: _textColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Gift Card',
                      style: TextStyle(
                        color: _textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  _nameController.text.isEmpty
                      ? 'Template Name'
                      : _nameController.text,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _textColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetAmountsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preset Amounts',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._presetAmountsCents.map((cents) {
              return Chip(
                label: Text('\$${(cents / 100).toStringAsFixed(0)}'),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() => _presetAmountsCents.remove(cents));
                },
              );
            }),
            SizedBox(
              width: 100,
              child: TextField(
                controller: _presetAmountController,
                decoration: const InputDecoration(
                  hintText: 'Add...',
                  prefixText: '\$',
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (value) {
                  final amount = double.tryParse(value);
                  if (amount != null && amount >= 1) {
                    setState(() {
                      _presetAmountsCents.add((amount * 100).round());
                      _presetAmountsCents.sort();
                    });
                    _presetAmountController.clear();
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final templateRepo = ref.read(giftCardTemplateRepositoryProvider);

      final minAmount = _minAmountController.text.isNotEmpty
          ? (double.parse(_minAmountController.text) * 100).round()
          : null;
      final maxAmount = _maxAmountController.text.isNotEmpty
          ? (double.parse(_maxAmountController.text) * 100).round()
          : null;
      final validityDays = _validityDaysController.text.isNotEmpty
          ? int.parse(_validityDaysController.text)
          : null;

      if (_isEditing) {
        await templateRepo.updateTemplate(
          context: widget.securityContext,
          templateId: widget.template!.id,
          updates: {
            'name': _nameController.text.trim(),
            'description': _descriptionController.text.trim(),
            'imageUrl': _imageUrlController.text.trim(),
            'backgroundColor': _colorToHex(_backgroundColor),
            'textColor': _colorToHex(_textColor),
            'presetAmountsCents':
                _presetAmountsCents.isNotEmpty ? _presetAmountsCents : null,
            'minAmountCents': minAmount,
            'maxAmountCents': maxAmount,
            'validityDays': validityDays,
          },
        );
      } else {
        await templateRepo.createTemplate(
          context: widget.securityContext,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          imageUrl: _imageUrlController.text.trim(),
          backgroundColor: _colorToHex(_backgroundColor),
          textColor: _colorToHex(_textColor),
          presetAmountsCents:
              _presetAmountsCents.isNotEmpty ? _presetAmountsCents : null,
          minAmountCents: minAmount,
          maxAmountCents: maxAmount,
          validityDays: validityDays,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Template updated' : 'Template created',
          ),
        ),
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserMessages.saveError)),
      );
    }
  }
}
