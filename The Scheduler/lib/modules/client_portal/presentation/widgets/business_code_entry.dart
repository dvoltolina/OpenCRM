import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/components/components.dart';
import '../../../../data/models/business_search_result.dart';
import '../../services/business_search_service.dart';
import '../../providers/client_portal_providers.dart';

/// Widget for entering a business code.
///
/// Business codes are 6-8 alphanumeric characters.
/// Used for direct access via QR codes, business cards, etc.
class BusinessCodeEntry extends ConsumerStatefulWidget {
  const BusinessCodeEntry({
    super.key,
    required this.onBusinessFound,
  });

  final void Function(BusinessSearchResult) onBusinessFound;

  @override
  ConsumerState<BusinessCodeEntry> createState() => _BusinessCodeEntryState();
}

class _BusinessCodeEntryState extends ConsumerState<BusinessCodeEntry> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(businessSearchServiceProvider);
      final business = await service.getBusinessByCode(
        _codeController.text.trim(),
      );

      if (!mounted) return;

      if (business == null) {
        setState(() {
          _errorMessage = 'Business code not found. Please check and try again.';
        });
      } else {
        widget.onBusinessFound(business);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to lookup business code. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Have a business code?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          VSpace.sm,
          Text(
            'Enter the code you received from your business',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          VSpace.md,

          // Code input field
          TextFormField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(8),
            ],
            decoration: InputDecoration(
              labelText: 'Business Code',
              hintText: 'ABC123',
              prefixIcon: const Icon(Icons.qr_code),
              border: const OutlineInputBorder(),
              helperText: '6-8 characters',
              errorText: _errorMessage,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a business code';
              }
              if (!BusinessSearchService.isValidCodeFormat(value)) {
                return 'Code must be 6-8 alphanumeric characters';
              }
              return null;
            },
            enabled: !_isLoading,
            onFieldSubmitted: (_) => _handleSubmit(),
          ),
          VSpace.md,

          // Submit button
          FilledButton(
            onPressed: _isLoading ? null : _handleSubmit,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Continue with Code'),
          ),
        ],
      ),
    );
  }
}
