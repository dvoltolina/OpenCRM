import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Dialog for adjusting a gift card's balance.
///
/// Allows admin to add or subtract an amount with a required reason.
class AdjustBalanceDialog extends StatefulWidget {
  const AdjustBalanceDialog({super.key});

  @override
  State<AdjustBalanceDialog> createState() => _AdjustBalanceDialogState();
}

class _AdjustBalanceDialogState extends State<AdjustBalanceDialog> {
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isAdd = true;

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adjust Balance'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Add'), icon: Icon(Icons.add)),
              ButtonSegment(value: false, label: Text('Subtract'), icon: Icon(Icons.remove)),
            ],
            selected: {_isAdd},
            onSelectionChanged: (selected) {
              setState(() => _isAdd = selected.first);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: '\$',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason (required)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final amount = double.tryParse(_amountController.text);
            final reason = _reasonController.text.trim();
            if (amount != null && amount > 0 && reason.isNotEmpty) {
              Navigator.pop(context, {
                'amount': amount,
                'isAdd': _isAdd,
                'reason': reason,
              });
            }
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

/// Dialog for extending a gift card's expiration date.
///
/// Allows admin to select a new expiration date with a required reason.
class ExtendExpirationDialog extends StatefulWidget {
  const ExtendExpirationDialog({
    required this.currentExpiry,
    super.key,
  });

  final DateTime? currentExpiry;

  @override
  State<ExtendExpirationDialog> createState() => _ExtendExpirationDialogState();
}

class _ExtendExpirationDialogState extends State<ExtendExpirationDialog> {
  final _reasonController = TextEditingController();
  late DateTime _newExpiry;

  @override
  void initState() {
    super.initState();
    _newExpiry = widget.currentExpiry?.add(const Duration(days: 365)) ??
        DateTime.now().add(const Duration(days: 365));
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Extend Expiration'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('New Expiration Date'),
            subtitle: Text(DateFormat.yMMMd().format(_newExpiry)),
            trailing: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _newExpiry,
                  firstDate: DateTime.now().add(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (picked != null) {
                  setState(() => _newExpiry = picked);
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason (required)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final reason = _reasonController.text.trim();
            if (reason.isNotEmpty) {
              Navigator.pop(context, {
                'newExpiry': _newExpiry,
                'reason': reason,
              });
            }
          },
          child: const Text('Extend'),
        ),
      ],
    );
  }
}

/// Dialog for voiding a gift card.
///
/// Displays a warning about the remaining balance and requires a reason.
class VoidGiftCardDialog extends StatefulWidget {
  const VoidGiftCardDialog({
    required this.remainingBalanceDollars,
    super.key,
  });

  final double remainingBalanceDollars;

  @override
  State<VoidGiftCardDialog> createState() => _VoidGiftCardDialogState();
}

class _VoidGiftCardDialogState extends State<VoidGiftCardDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Void Gift Card'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'This will permanently void the gift card and cannot be undone. '
            'Remaining balance: \$${widget.remainingBalanceDollars.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason (required)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final reason = _reasonController.text.trim();
            if (reason.isNotEmpty) {
              Navigator.pop(context, reason);
            }
          },
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Void Card'),
        ),
      ],
    );
  }
}
