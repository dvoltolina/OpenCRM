import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget for selecting gift card amount (preset or custom).
class GiftCardAmountSelector extends StatelessWidget {
  const GiftCardAmountSelector({
    required this.presetAmounts,
    required this.selectedAmountCents,
    required this.useCustomAmount,
    required this.customAmountController,
    required this.onPresetAmountSelected,
    required this.onCustomAmountToggled,
    required this.onCustomAmountChanged,
    required this.primaryColor,
    super.key,
  });

  final List<int> presetAmounts;
  final int? selectedAmountCents;
  final bool useCustomAmount;
  final TextEditingController customAmountController;
  final ValueChanged<int> onPresetAmountSelected;
  final ValueChanged<bool> onCustomAmountToggled;
  final ValueChanged<String> onCustomAmountChanged;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...presetAmounts.map((cents) => ChoiceChip(
                  label: Text('\$${(cents / 100).toStringAsFixed(0)}'),
                  selected: !useCustomAmount && selectedAmountCents == cents,
                  onSelected: (selected) {
                    if (selected) {
                      onPresetAmountSelected(cents);
                    }
                  },
                  selectedColor: primaryColor.withValues(alpha: 0.2),
                )),
            ChoiceChip(
              label: const Text('Custom'),
              selected: useCustomAmount,
              onSelected: onCustomAmountToggled,
              selectedColor: primaryColor.withValues(alpha: 0.2),
            ),
          ],
        ),
        if (useCustomAmount) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: customAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: const InputDecoration(
              labelText: 'Custom Amount',
              prefixText: '\$',
              hintText: '50.00',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (!useCustomAmount) return null;
              if (value == null || value.isEmpty) {
                return 'Please enter an amount';
              }
              final amount = double.tryParse(value);
              if (amount == null) {
                return 'Please enter a valid number';
              }
              if (amount < 10) {
                return 'Minimum amount is \$10.00';
              }
              if (amount > 1000) {
                return 'Maximum amount is \$1,000.00';
              }
              return null;
            },
            onChanged: onCustomAmountChanged,
          ),
        ],
      ],
    );
  }
}
