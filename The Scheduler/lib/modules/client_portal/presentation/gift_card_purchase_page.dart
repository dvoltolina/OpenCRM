import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/components/components.dart';
import '../../../core/config/app_config.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/safe_error_handler.dart';
import '../../../data/models/gift_card_template.dart';
import '../../../data/models/security_context.dart';
import '../../../data/repositories/gift_card_repository.dart';
import 'gift_card_confirmation_page.dart';
import 'widgets/gift_card_template_selector.dart';
import 'widgets/gift_card_amount_selector.dart';
import 'widgets/gift_card_recipient_form.dart';

/// Client-facing gift card purchase page.
///
/// Allows customers to:
/// - Select a design template
/// - Choose an amount (preset or custom)
/// - Send to themselves or as a gift
/// - Complete payment via Stripe
class GiftCardPurchasePage extends ConsumerStatefulWidget {
  const GiftCardPurchasePage({
    required this.config,
    super.key,
  });

  final AppConfig config;

  @override
  ConsumerState<GiftCardPurchasePage> createState() => _GiftCardPurchasePageState();
}

class _GiftCardPurchasePageState extends ConsumerState<GiftCardPurchasePage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _recipientEmailController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final _messageController = TextEditingController();
  final _customAmountController = TextEditingController();

  GiftCardTemplate? _selectedTemplate;
  int? _selectedAmountCents;
  bool _sendToSelf = true;
  bool _useCustomAmount = false;
  bool _isLoading = false;
  String? _errorMessage;

  static const _presetAmounts = [2500, 5000, 7500, 10000, 15000, 20000];

  @override
  void dispose() {
    _emailController.dispose();
    _recipientEmailController.dispose();
    _recipientNameController.dispose();
    _messageController.dispose();
    _customAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final securityContextAsync = ref.watch(securityContextProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Gift Card'),
        backgroundColor: widget.config.branding.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: securityContextAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(SafeErrorHandler.handle(error))),
        data: (securityContext) {
          if (securityContext == null) {
            return const Center(
              child: Text('Please sign in to purchase gift cards.'),
            );
          }
          return _buildContent(context, securityContext);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, SecurityContext securityContext) {
    final templatesStream = ref.watch(
      giftCardServiceProvider,
    ).watchTemplates(securityContext);

    return StreamBuilder<List<GiftCardTemplate>>(
      stream: templatesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final templates = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null) ...[
                  _buildErrorBanner(),
                  VSpace.md,
                ],
                _buildSectionTitle('Choose a Design'),
                VSpace.sm,
                _buildTemplateSelector(templates),
                VSpace.lg,
                _buildSectionTitle('Select Amount'),
                VSpace.sm,
                _buildAmountSelector(),
                VSpace.lg,
                _buildSectionTitle('Recipient'),
                VSpace.sm,
                _buildRecipientToggle(),
                VSpace.md,
                if (!_sendToSelf) _buildRecipientForm(),
                _buildPurchaserEmailField(),
                VSpace.xl,
                _buildSummary(),
                VSpace.md,
                _buildPurchaseButton(securityContext),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          HSpace.sm,
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => _errorMessage = null),
            color: Colors.red.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildTemplateSelector(List<GiftCardTemplate> templates) {
    return GiftCardTemplateSelector(
      templates: templates,
      selectedTemplate: _selectedTemplate,
      onTemplateSelected: (template) {
        setState(() => _selectedTemplate = template);
      },
      primaryColor: widget.config.branding.primaryColor,
    );
  }

  Widget _buildAmountSelector() {
    return GiftCardAmountSelector(
      presetAmounts: _presetAmounts,
      selectedAmountCents: _selectedAmountCents,
      useCustomAmount: _useCustomAmount,
      customAmountController: _customAmountController,
      onPresetAmountSelected: (cents) {
        setState(() {
          _selectedAmountCents = cents;
          _useCustomAmount = false;
          _customAmountController.clear();
        });
      },
      onCustomAmountToggled: (selected) {
        setState(() {
          _useCustomAmount = selected;
          if (selected) {
            _selectedAmountCents = null;
          }
        });
      },
      onCustomAmountChanged: (value) {
        final amount = double.tryParse(value);
        if (amount != null) {
          setState(() {
            _selectedAmountCents = (amount * 100).round();
          });
        }
      },
      primaryColor: widget.config.branding.primaryColor,
    );
  }

  Widget _buildRecipientToggle() {
    return AppCard(
      padding: EdgeInsets.zero,
      child: SwitchListTile(
        title: const Text('Send to myself'),
        subtitle: Text(
          _sendToSelf
              ? 'Gift card will be sent to your email'
              : 'Gift card will be sent to someone else',
        ),
        value: _sendToSelf,
        onChanged: (value) => setState(() => _sendToSelf = value),
        activeTrackColor: widget.config.branding.primaryColor.withValues(alpha: 0.5),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return widget.config.branding.primaryColor;
          }
          return null;
        }),
      ),
    );
  }

  Widget _buildRecipientForm() {
    return GiftCardRecipientForm(
      recipientNameController: _recipientNameController,
      recipientEmailController: _recipientEmailController,
      messageController: _messageController,
    );
  }

  Widget _buildPurchaserEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: const InputDecoration(
        labelText: 'Your Email',
        hintText: 'your@example.com',
        prefixIcon: Icon(Icons.email_outlined),
        border: OutlineInputBorder(),
        helperText: 'Confirmation will be sent to this address',
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your email';
        }
        if (!_isValidEmail(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildSummary() {
    final amountCents = _selectedAmountCents;
    if (amountCents == null) {
      return const SizedBox.shrink();
    }

    final amountDollars = amountCents / 100.0;

    return AppCard(
      color: widget.config.branding.primaryColor.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gift Card Amount',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                '\$${amountDollars.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (!_sendToSelf && _recipientNameController.text.isNotEmpty) ...[
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.card_giftcard, size: 16),
                HSpace.xs,
                Text('To: ${_recipientNameController.text}'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPurchaseButton(SecurityContext securityContext) {
    final hasAmount = _selectedAmountCents != null && _selectedAmountCents! >= 1000;

    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: hasAmount && !_isLoading
            ? () => _handlePurchase(securityContext)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.config.branding.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline),
                  HSpace.xs,
                  Text(
                    'Purchase Gift Card - \$${(_selectedAmountCents ?? 0) / 100}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _handlePurchase(SecurityContext securityContext) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final giftCardService = ref.read(giftCardServiceProvider);
      final stripeService = ref.read(stripeServiceProvider);

      // Initiate purchase
      final result = await giftCardService.purchaseGiftCard(
        context: securityContext,
        amountCents: _selectedAmountCents!,
        purchaserEmail: _emailController.text.trim(),
        recipientEmail: _sendToSelf ? null : _recipientEmailController.text.trim(),
        recipientName: _sendToSelf ? null : _recipientNameController.text.trim(),
        personalMessage: _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
        templateId: _selectedTemplate?.id,
      );

      // Present Stripe payment sheet
      final paymentSuccess = await stripeService.presentPaymentSheet(
        clientSecret: result.clientSecret,
      );

      if (!paymentSuccess) {
        setState(() {
          _errorMessage = 'Payment was cancelled or failed. Please try again.';
          _isLoading = false;
        });
        return;
      }

      // Confirm the purchase
      final confirmedCard = await giftCardService.confirmGiftCardPurchase(
        context: securityContext,
        giftCardId: result.giftCard.id,
        paymentIntentId: result.clientSecret.split('_secret_').first,
      );

      if (!mounted) return;

      // Navigate to confirmation page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GiftCardConfirmationPage(
            giftCard: confirmedCard,
            config: widget.config,
          ),
        ),
      );
    } on GiftCardException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }
}
