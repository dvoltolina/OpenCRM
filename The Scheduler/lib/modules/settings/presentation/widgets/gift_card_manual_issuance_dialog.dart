import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/user_messages.dart';
import '../../../../core/providers/providers.dart';

/// Dialog for manually issuing a gift card.
/// Modern design with rounded corners and sophisticated blue styling.
class GiftCardManualIssuanceDialog extends ConsumerStatefulWidget {
  const GiftCardManualIssuanceDialog({super.key});

  @override
  ConsumerState<GiftCardManualIssuanceDialog> createState() =>
      _GiftCardManualIssuanceDialogState();
}

class _GiftCardManualIssuanceDialogState
    extends ConsumerState<GiftCardManualIssuanceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _recipientEmailController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final _reasonController = TextEditingController();

  bool _isSubmitting = false;
  DateTime? _expiresAt;

  @override
  void dispose() {
    _amountController.dispose();
    _recipientEmailController.dispose();
    _recipientNameController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final branding = ref.watch(appConfigProvider).branding;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      title: Row(
        children: [
          Icon(Icons.card_giftcard, color: branding.primaryColor),
          const SizedBox(width: 12),
          const Text('Issue Gift Card'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Issue a gift card without payment (promotional, goodwill, etc.)',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: '\$',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.attach_money, color: branding.accentColor),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    final amount = double.tryParse(value);
                    if (amount == null || amount < 1) return 'Invalid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _recipientEmailController,
                  decoration: InputDecoration(
                    labelText: 'Recipient Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.email, color: branding.accentColor),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (!value.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _recipientNameController,
                  decoration: InputDecoration(
                    labelText: 'Recipient Name (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.person, color: branding.accentColor),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    labelText: 'Reason (required for audit)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.note, color: branding.accentColor),
                    hintText: 'e.g., Customer appreciation, promotional campaign',
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Reason is required for audit trail';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Expiration Date'),
                  subtitle: Text(
                    _expiresAt != null
                        ? DateFormat.yMMMd().format(_expiresAt!)
                        : 'Never expires',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_expiresAt != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _expiresAt = null),
                        ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: _pickExpirationDate,
                      ),
                    ],
                  ),
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
                  style: FilledButton.styleFrom(
                    backgroundColor: branding.effectiveCtaColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Issue Gift Card'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickExpirationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _expiresAt = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final securityContext = ref.read(securityContextProvider).value;
      if (securityContext == null) throw Exception('Not authenticated');

      final giftCardService = ref.read(giftCardServiceProvider);
      final amountCents = (double.parse(_amountController.text) * 100).round();

      await giftCardService.issueManualGiftCard(
        context: securityContext,
        amountCents: amountCents,
        recipientEmail: _recipientEmailController.text.trim(),
        reason: _reasonController.text.trim(),
        recipientName: _recipientNameController.text.trim().isEmpty
            ? null
            : _recipientNameController.text.trim(),
        expiresAt: _expiresAt,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gift card issued successfully')),
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserMessages.saveError)),
      );
    }
  }
}
