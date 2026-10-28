import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../data/models/guest_session.dart';
import '../services/guest_verification_service.dart';
import 'guest_verification_page.dart';

/// Form for guest booking contact information.
///
/// Collects:
/// - Full name
/// - Email
/// - Phone number
/// - Verification method (SMS or email)
///
/// HIPAA Note: This data becomes PHI when linked to appointments.
/// Do not log this information.
class GuestBookingForm extends ConsumerStatefulWidget {
  const GuestBookingForm({
    super.key,
    required this.businessId,
  });

  final String businessId;

  @override
  ConsumerState<GuestBookingForm> createState() => _GuestBookingFormState();
}

class _GuestBookingFormState extends ConsumerState<GuestBookingForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  GuestVerificationMethod _verificationMethod = GuestVerificationMethod.sms;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
      final config = ref.read(appConfigProvider);
      final service = GuestVerificationService(
        sendVerificationUrl:
            config.cloudFunctionUrls['sendGuestVerification'] ?? '',
        verifyCodeUrl: config.cloudFunctionUrls['verifyGuestCode'] ?? '',
        resendCodeUrl: config.cloudFunctionUrls['resendGuestCode'] ?? '',
      );

      VerificationResult result;

      if (_verificationMethod == GuestVerificationMethod.sms) {
        result = await service.sendSmsCode(
          businessId: widget.businessId,
          phone: _phoneController.text.trim(),
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
        );
      } else {
        result = await service.sendEmailCode(
          businessId: widget.businessId,
          email: _emailController.text.trim(),
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
        );
      }

      if (!mounted) return;

      // Navigate to verification page
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GuestVerificationPage(
            sessionId: result.sessionId,
            verificationMethod: _verificationMethod,
            contactInfo: _verificationMethod == GuestVerificationMethod.sms
                ? _phoneController.text.trim()
                : _emailController.text.trim(),
            businessId: widget.businessId,
          ),
        ),
      );
    } on RateLimitException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send verification code. Please try again.';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guest Booking'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Enter Your Information',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                VSpace.sm,
                Text(
                  'We\'ll verify your identity to complete the booking',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                VSpace.xl,

                // Full name
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Jane Doe',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),
                VSpace.md,

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'jane@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!GuestVerificationService.isValidEmail(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),
                VSpace.md,

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9\-\(\) ]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '(555) 123-4567',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (!GuestVerificationService.isValidPhone(value)) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),
                VSpace.xl,

                // Verification method selection
                Text(
                  'Verify your identity via:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                VSpace.md,

                RadioGroup<GuestVerificationMethod>(
                  groupValue: _verificationMethod,
                  onChanged: (value) {
                    if (_isLoading || value == null) return;
                    setState(() {
                      _verificationMethod = value;
                    });
                  },
                  child: Column(
                    children: [
                      _VerificationMethodOption(
                        icon: Icons.sms_outlined,
                        label: 'Text Message (SMS)',
                        value: GuestVerificationMethod.sms,
                        groupValue: _verificationMethod,
                        enabled: !_isLoading,
                        onSelected: (value) {
                          setState(() {
                            _verificationMethod = value;
                          });
                        },
                      ),
                      VSpace.sm,
                      _VerificationMethodOption(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: GuestVerificationMethod.email,
                        groupValue: _verificationMethod,
                        enabled: !_isLoading,
                        onSelected: (value) {
                          setState(() {
                            _verificationMethod = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                VSpace.xl,

                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        HSpace.md,
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  VSpace.md,
                ],

                // Terms notice
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'By continuing, you agree to our Terms of Service and Privacy Policy.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                VSpace.lg,

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
                      : const Text('Send Verification Code'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Radio option for verification method
class _VerificationMethodOption extends StatelessWidget {
  const _VerificationMethodOption({
    required this.icon,
    required this.label,
    required this.value,
    required this.groupValue,
    required this.enabled,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final GuestVerificationMethod value;
  final GuestVerificationMethod groupValue;
  final bool enabled;
  final ValueChanged<GuestVerificationMethod> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = value == groupValue;

    return InkWell(
      onTap: enabled ? () => onSelected(value) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            HSpace.md,
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isSelected ? theme.colorScheme.primary : null,
                  fontWeight: isSelected ? FontWeight.bold : null,
                ),
              ),
            ),
            Radio<GuestVerificationMethod>(
              value: value,
            ),
          ],
        ),
      ),
    );
  }
}
