import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../../../data/models/pos_transaction.dart';
import '../../../../data/models/security_context.dart';
import 'payment_types.dart';

export 'cash_payment_dialog.dart';
export 'payment_types.dart';

/// Dialog for processing POS payments.
///
/// Supports cash, card, and gift card payments with appropriate
/// inputs for each method.
class PaymentDialog extends ConsumerStatefulWidget {
  const PaymentDialog({
    super.key,
    required this.securityContext,
    required this.totalCents,
    required this.paymentMethod,
    required this.onProcessPayment,
  });

  final SecurityContext securityContext;
  final int totalCents;
  final PosPaymentMethod paymentMethod;
  final Future<PaymentDialogResult> Function({
    required PosPaymentMethod method,
    int? cashTenderedCents,
    String? giftCardCode,
  }) onProcessPayment;

  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cashController = TextEditingController();
  final _giftCardController = TextEditingController();

  bool _isProcessing = false;
  String? _error;
  PaymentDialogResult? _result;

  // Gift card validation state
  bool _isValidatingGiftCard = false;
  int? _giftCardBalanceCents;
  String? _giftCardError;

  double get _totalDollars => widget.totalCents / 100;

  @override
  void initState() {
    super.initState();
    if (widget.paymentMethod == PosPaymentMethod.cash) {
      _cashController.text = _totalDollars.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _cashController.dispose();
    _giftCardController.dispose();
    super.dispose();
  }

  int? get _cashTenderedCents {
    final text = _cashController.text.trim();
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null) return null;
    return (parsed * 100).round();
  }

  int get _changeCents {
    final tendered = _cashTenderedCents ?? 0;
    return (tendered - widget.totalCents).clamp(0, tendered);
  }

  Future<void> _validateGiftCard() async {
    final code = _giftCardController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _isValidatingGiftCard = true;
      _giftCardError = null;
      _giftCardBalanceCents = null;
    });

    try {
      final giftCardRepo = ref.read(giftCardRepositoryProvider);
      final balance = await giftCardRepo.checkBalance(
        businessId: widget.securityContext.businessId,
        code: code,
      );

      if (!mounted) return;

      if (balance.valid) {
        setState(() {
          _giftCardBalanceCents = balance.balanceCents;
          _isValidatingGiftCard = false;
        });
      } else {
        setState(() {
          _giftCardError = 'Invalid or expired gift card';
          _isValidatingGiftCard = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _giftCardError = 'Failed to validate gift card';
        _isValidatingGiftCard = false;
      });
    }
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.paymentMethod == PosPaymentMethod.giftCard) {
      if (_giftCardBalanceCents == null) {
        setState(() => _error = 'Please validate the gift card first');
        return;
      }
      if (_giftCardBalanceCents! < widget.totalCents) {
        setState(() => _error = 'Insufficient gift card balance');
        return;
      }
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final result = await widget.onProcessPayment(
        method: widget.paymentMethod,
        cashTenderedCents: widget.paymentMethod == PosPaymentMethod.cash
            ? _cashTenderedCents
            : null,
        giftCardCode: widget.paymentMethod == PosPaymentMethod.giftCard
            ? _giftCardController.text.trim().toUpperCase()
            : null,
      );

      if (!mounted) return;

      if (result.success) {
        setState(() => _result = result);
      } else {
        setState(() {
          _error = result.error ?? 'Payment failed';
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_result != null && _result!.success) {
      return _buildSuccessDialog(theme);
    }

    return AlertDialog(
      title: Row(
        children: [
          Icon(_getPaymentMethodIcon(), color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(widget.paymentMethod.dialogTitle)),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTotalDisplay(theme),
              const SizedBox(height: 24),
              ..._buildPaymentInputs(theme),
              if (_error != null) _buildErrorBanner(theme),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isProcessing ? null : _processPayment,
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.paymentMethod.buttonLabel),
        ),
      ],
    );
  }

  Widget _buildTotalDisplay(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Total Due',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\$${_totalDollars.toStringAsFixed(2)}',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_error!, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessDialog(ThemeData theme) {
    return AlertDialog(
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, size: 48, color: Colors.green.shade700),
            ),
            const SizedBox(height: 24),
            Text(
              'Payment Successful!',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_result?.receiptNumber != null)
              Text(
                'Receipt #${_result!.receiptNumber}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              '\$${_totalDollars.toStringAsFixed(2)}',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            if (widget.paymentMethod == PosPaymentMethod.cash && _changeCents > 0)
              _buildChangeDisplay(theme),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context, _result),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _buildChangeDisplay(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payments, color: theme.colorScheme.onTertiaryContainer),
            const SizedBox(width: 8),
            Text(
              'Change: \$${(_changeCents / 100).toStringAsFixed(2)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPaymentInputs(ThemeData theme) {
    switch (widget.paymentMethod) {
      case PosPaymentMethod.cash:
        return _buildCashInputs(theme);
      case PosPaymentMethod.card:
        return _buildCardInputs(theme);
      case PosPaymentMethod.giftCard:
        return _buildGiftCardInputs(theme);
      default:
        return [];
    }
  }

  List<Widget> _buildCashInputs(ThemeData theme) {
    return [
      TextFormField(
        controller: _cashController,
        decoration: const InputDecoration(labelText: 'Cash Tendered', prefixText: '\$ '),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
        validator: (value) {
          if (value == null || value.isEmpty) return 'Enter cash amount';
          final parsed = double.tryParse(value);
          if (parsed == null) return 'Invalid amount';
          if ((parsed * 100).round() < widget.totalCents) return 'Insufficient amount';
          return null;
        },
        onChanged: (_) => setState(() {}),
        autofocus: true,
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: getQuickAmounts(_totalDollars).map((amount) {
          return OutlinedButton(
            onPressed: () {
              _cashController.text = amount.toStringAsFixed(2);
              setState(() {});
            },
            child: Text('\$$amount'),
          );
        }).toList(),
      ),
      const SizedBox(height: 16),
      if (_cashTenderedCents != null && _cashTenderedCents! >= widget.totalCents)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Change Due:', style: theme.textTheme.titleMedium),
              Text(
                '\$${(_changeCents / 100).toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
    ];
  }

  List<Widget> _buildCardInputs(ThemeData theme) {
    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(Icons.credit_card, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Tap "Pay" to open the payment terminal',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildGiftCardInputs(ThemeData theme) {
    return [
      TextFormField(
        controller: _giftCardController,
        decoration: InputDecoration(
          labelText: 'Gift Card Code',
          hintText: 'GIFT-XXXX-XXXX',
          errorText: _giftCardError,
          suffixIcon: _isValidatingGiftCard
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  onPressed: _validateGiftCard,
                  tooltip: 'Validate',
                ),
        ),
        textCapitalization: TextCapitalization.characters,
        validator: (value) => (value == null || value.isEmpty) ? 'Enter gift card code' : null,
        onFieldSubmitted: (_) => _validateGiftCard(),
        autofocus: true,
      ),
      if (_giftCardBalanceCents != null) _buildGiftCardBalanceDisplay(theme),
    ];
  }

  Widget _buildGiftCardBalanceDisplay(ThemeData theme) {
    final hasEnough = _giftCardBalanceCents! >= widget.totalCents;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasEnough ? Colors.green.shade50 : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: hasEnough ? Colors.green : Colors.orange),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Gift Card Balance:'),
                Text(
                  '\$${(_giftCardBalanceCents! / 100).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (hasEnough)
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
                  const SizedBox(width: 4),
                  Text('Covers full amount!', style: TextStyle(color: Colors.green.shade700)),
                ],
              )
            else ...[
              Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700, size: 18),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Insufficient - \$${((widget.totalCents - _giftCardBalanceCents!) / 100).toStringAsFixed(2)} short',
                      style: TextStyle(color: Colors.orange.shade700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      PaymentDialogResult(
                        success: false,
                        error: 'SPLIT_PAYMENT_REQUESTED',
                        receiptNumber: _giftCardController.text.trim().toUpperCase(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.credit_card),
                  label: Text(
                    'Pay \$${((widget.totalCents - _giftCardBalanceCents!) / 100).toStringAsFixed(2)} with Card',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getPaymentMethodIcon() {
    switch (widget.paymentMethod) {
      case PosPaymentMethod.cash:
        return Icons.payments;
      case PosPaymentMethod.card:
        return Icons.credit_card;
      case PosPaymentMethod.giftCard:
        return Icons.card_giftcard;
      default:
        return Icons.payment;
    }
  }
}
