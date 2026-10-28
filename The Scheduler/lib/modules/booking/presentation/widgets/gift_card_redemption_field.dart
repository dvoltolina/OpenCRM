import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../../../data/models/security_context.dart';
import '../../../../data/repositories/gift_card_repository.dart';

/// Result of applying a gift card to a booking.
///
/// Used by the booking flow to calculate remaining payment amount.
class GiftCardApplicationResult {
  const GiftCardApplicationResult({
    required this.code,
    required this.amountCents,
    required this.remainingBalanceCents,
    required this.coversFullAmount,
    this.expiresAt,
  });

  /// The validated gift card code
  final String code;

  /// Amount in cents to be applied to the booking
  final int amountCents;

  /// Gift card balance remaining after this redemption
  final int remainingBalanceCents;

  /// Whether this covers the full booking amount
  final bool coversFullAmount;

  /// When the gift card expires (null = never)
  final DateTime? expiresAt;

  /// Amount in dollars
  double get amountDollars => amountCents / 100.0;

  /// Remaining balance in dollars
  double get remainingBalanceDollars => remainingBalanceCents / 100.0;
}

/// Reusable widget for applying gift cards during booking.
///
/// Features:
/// - Code input with format hint
/// - Apply button with loading state
/// - Applied state showing discount amount
/// - Error handling for invalid codes
/// - Clear/remove functionality
class GiftCardRedemptionField extends ConsumerStatefulWidget {
  const GiftCardRedemptionField({
    required this.securityContext,
    required this.appointmentTotalCents,
    required this.onRedemptionChanged,
    this.primaryColor,
    super.key,
  });

  /// Security context for API calls
  final SecurityContext securityContext;

  /// Total appointment cost in cents
  final int appointmentTotalCents;

  /// Called when a gift card is applied or cleared
  final ValueChanged<GiftCardApplicationResult?> onRedemptionChanged;

  /// Primary color for styling (optional)
  final Color? primaryColor;

  @override
  ConsumerState<GiftCardRedemptionField> createState() =>
      _GiftCardRedemptionFieldState();
}

class _GiftCardRedemptionFieldState
    extends ConsumerState<GiftCardRedemptionField> {
  final _codeController = TextEditingController();
  final _focusNode = FocusNode();

  bool _isLoading = false;
  String? _errorMessage;
  GiftCardApplicationResult? _appliedResult;

  Color get _primaryColor =>
      widget.primaryColor ?? Theme.of(context).primaryColor;

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 12),
            if (_appliedResult != null)
              _buildAppliedState(theme)
            else
              _buildInputState(),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              _buildErrorMessage(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.card_giftcard,
          color: _primaryColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'Gift Card',
          style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const Spacer(),
        if (_appliedResult != null)
          TextButton(
            onPressed: _clearAppliedCard,
            child: const Text('Remove'),
          ),
      ],
    );
  }

  Widget _buildInputState() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: _codeController,
            focusNode: _focusNode,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
              UpperCaseTextFormatter(),
            ],
            decoration: InputDecoration(
              hintText: 'GIFT-XXXX-XXXX',
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              isDense: true,
              errorText: null,
              suffixIcon: _codeController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _codeController.clear();
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (_) {
              if (_errorMessage != null) {
                setState(() => _errorMessage = null);
              }
            },
            onFieldSubmitted: (_) => _applyGiftCard(),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _applyGiftCard,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Apply'),
          ),
        ),
      ],
    );
  }

  Widget _buildAppliedState(ThemeData theme) {
    final result = _appliedResult!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                result.code,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade900,
                ),
              ),
              const Spacer(),
              Text(
                '-\$${result.amountDollars.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (result.coversFullAmount) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Covers full amount!',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Remaining to pay:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  '\$${((widget.appointmentTotalCents - result.amountCents) / 100.0).toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          if (result.remainingBalanceCents > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Gift card balance after: \$${result.remainingBalanceDollars.toStringAsFixed(2)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorMessage(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applyGiftCard() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a gift card code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final giftCardService = ref.read(giftCardServiceProvider);

      // Apply gift card to booking (calculates amount, doesn't deduct yet)
      final redemptionResult = await giftCardService.applyGiftCardToBooking(
        context: widget.securityContext,
        giftCardCode: code,
        appointmentTotalCents: widget.appointmentTotalCents,
      );

      // Convert to our local result type
      final result = GiftCardApplicationResult(
        code: redemptionResult.code,
        amountCents: redemptionResult.amountCents,
        remainingBalanceCents: redemptionResult.remainingBalanceCents,
        coversFullAmount: redemptionResult.coversFullAmount,
        expiresAt: redemptionResult.expiresAt,
      );

      setState(() {
        _appliedResult = result;
        _isLoading = false;
      });

      widget.onRedemptionChanged(result);
    } on GiftCardException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Unable to validate gift card. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _clearAppliedCard() {
    setState(() {
      _appliedResult = null;
      _codeController.clear();
      _errorMessage = null;
    });
    widget.onRedemptionChanged(null);
  }
}

/// Text input formatter that converts text to uppercase.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
