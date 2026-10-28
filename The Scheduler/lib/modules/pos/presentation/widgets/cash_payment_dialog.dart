import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Cash payment dialog - simpler version for quick cash sales.
///
/// Shows total, cash tendered input, and change calculation.
class CashPaymentDialog extends StatefulWidget {
  const CashPaymentDialog({
    super.key,
    required this.totalCents,
  });

  final int totalCents;

  @override
  State<CashPaymentDialog> createState() => _CashPaymentDialogState();
}

class _CashPaymentDialogState extends State<CashPaymentDialog> {
  final _controller = TextEditingController();
  double get _totalDollars => widget.totalCents / 100;

  @override
  void initState() {
    super.initState();
    _controller.text = _totalDollars.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? get _cashTenderedCents {
    final text = _controller.text.trim();
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null) return null;
    return (parsed * 100).round();
  }

  int get _changeCents {
    final tendered = _cashTenderedCents ?? 0;
    return (tendered - widget.totalCents).clamp(0, tendered);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.payments),
          SizedBox(width: 12),
          Text('Cash Payment'),
        ],
      ),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Total: \$${_totalDollars.toStringAsFixed(2)}',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Cash Tendered',
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: (_) => setState(() {}),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            if (_cashTenderedCents != null && _cashTenderedCents! >= widget.totalCents)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Change:'),
                    Text(
                      '\$${(_changeCents / 100).toStringAsFixed(2)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _cashTenderedCents != null && _cashTenderedCents! >= widget.totalCents
              ? () => Navigator.pop(context, _cashTenderedCents)
              : null,
          child: const Text('Complete'),
        ),
      ],
    );
  }
}
