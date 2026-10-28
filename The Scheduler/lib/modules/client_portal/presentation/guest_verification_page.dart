import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../data/models/guest_session.dart';
import '../providers/guest_session_provider.dart';
import '../services/guest_verification_service.dart';

/// Page for entering and verifying the 6-digit code.
///
/// Features:
/// - 6-digit code entry with auto-advance
/// - Resend code with cooldown
/// - Max 3 attempts per code
/// - Error handling
/// - Change contact info option
///
/// Security: Code verification happens server-side with hashed comparison
class GuestVerificationPage extends ConsumerStatefulWidget {
  const GuestVerificationPage({
    super.key,
    required this.sessionId,
    required this.verificationMethod,
    required this.contactInfo,
    required this.businessId,
  });

  final String sessionId;
  final GuestVerificationMethod verificationMethod;
  final String contactInfo;
  final String businessId;

  @override
  ConsumerState<GuestVerificationPage> createState() =>
      _GuestVerificationPageState();
}

class _GuestVerificationPageState
    extends ConsumerState<GuestVerificationPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  String? _errorMessage;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Auto-focus first input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  String get _code => _controllers.map((c) => c.text).join();

  bool get _isCodeComplete => _code.length == 6;

  Future<void> _handleVerify() async {
    if (!_isCodeComplete || _isLoading) return;

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

      final session = await service.verifyCode(
        sessionId: widget.sessionId,
        code: _code,
      );

      if (!mounted) return;

      // Save guest session
      ref.read(guestSessionProvider.notifier).setSession(session);

      // Navigate to booking flow
      // TODO: Navigate to actual booking flow
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification successful! Booking flow coming soon.'),
          backgroundColor: Colors.green,
        ),
      );

      // For now, pop back to start
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on InvalidCodeException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
      _clearCode();
    } on CodeExpiredException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } on MaxAttemptsException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Verification failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleResend() async {
    if (_resendCooldown > 0 || _isLoading) return;

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

      await service.resendCode(sessionId: widget.sessionId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code sent!'),
        ),
      );

      _startCooldown();
      _clearCode();
    } on RateLimitException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to resend code. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startCooldown() {
    setState(() {
      _resendCooldown = 60; // 60 seconds cooldown
    });

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _resendCooldown--;
      });

      if (_resendCooldown <= 0) {
        timer.cancel();
      }
    });
  }

  void _clearCode() {
    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Identity'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VSpace.xl,
              Icon(
                widget.verificationMethod == GuestVerificationMethod.sms
                    ? Icons.sms_outlined
                    : Icons.email_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              VSpace.lg,

              Text(
                'We sent a code to:',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              VSpace.sm,
              Text(
                widget.contactInfo,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              VSpace.xl,

              Text(
                'Enter the 6-digit code:',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              VSpace.md,

              // 6-digit code input
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return _CodeInputBox(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      }
                      if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }

                      // Auto-verify when complete
                      if (_isCodeComplete) {
                        _handleVerify();
                      }
                    },
                    enabled: !_isLoading,
                  );
                }),
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

              // Resend button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Didn\'t receive a code?',
                    style: theme.textTheme.bodyMedium,
                  ),
                  HSpace.sm,
                  if (_resendCooldown > 0)
                    Text(
                      'Resend in ${_resendCooldown}s',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    TextButton(
                      onPressed: _isLoading ? null : _handleResend,
                      child: const Text('Resend Code'),
                    ),
                ],
              ),
              const Spacer(),

              // Verify button
              FilledButton(
                onPressed: _isCodeComplete && !_isLoading ? _handleVerify : null,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Verify & Continue'),
              ),
              VSpace.md,

              // Change contact info
              TextButton.icon(
                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Use different contact info'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single digit input box for verification code
class _CodeInputBox extends StatelessWidget {
  const _CodeInputBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.enabled,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String) onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 50,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
