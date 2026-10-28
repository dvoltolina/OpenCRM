import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/ui/components/components.dart';
import 'mfa_enrollment_page.dart';

/// Email verification step shown before MFA enrollment.
/// Ensures the user has a verified email before continuing to phone-based MFA.
class EmailVerificationPage extends ConsumerStatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  ConsumerState<EmailVerificationPage> createState() =>
      _EmailVerificationPageState();
}

class _EmailVerificationPageState extends ConsumerState<EmailVerificationPage> {
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _ensureVerified();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _ensureVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await user.reload();
    if (user.emailVerified && mounted) {
      _goToMfa();
    }
  }

  Future<void> _sendVerificationEmail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');
      await user.sendEmailVerification();
      if (mounted) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent. Please check your inbox.'),
            duration: Duration(seconds: 4),
          ),
        );
        _startPoll();
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('[EmailVerify] sendEmailVerification FirebaseAuthException: ${e.code}');
      if (mounted) {
        setState(() {
          _errorMessage = _friendlyError(e.code);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[EmailVerify] sendEmailVerification error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _startPoll() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await user.reload();
      if (user.emailVerified && mounted) {
        _pollTimer?.cancel();
        _goToMfa();
      }
    });
  }

  Future<void> _handleContinue() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'Session expired. Please sign in again.';
        _isLoading = false;
      });
      return;
    }
    await user.reload();
    if (user.emailVerified) {
      _goToMfa();
    } else {
      setState(() {
        _errorMessage = 'Please verify your email, then tap Continue.';
        _isLoading = false;
      });
    }
  }

  void _goToMfa() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MfaEnrollmentPage()),
    );
  }

  String? _friendlyError(String code) {
    if (code.contains('too-many-requests')) {
      return 'Too many requests. Wait a bit, then try again.';
    }
    if (code.contains('network')) return 'Network error. Check your connection.';
    return 'An error occurred. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final theme = Theme.of(context);
    final branding = config.branding;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        centerTitle: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.mark_email_read_outlined,
                    size: 64, color: branding.primaryColor),
                VSpace.md,
                Text(
                  'Check your email',
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                VSpace.xs,
                Text(
                  'We need to verify your email before enabling two-factor authentication.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                VSpace.xl,
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: theme.colorScheme.error),
                        HSpace.sm,
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_errorMessage != null) VSpace.md,
                // Send/Resend verification email button - full width
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _sendVerificationEmail,
                    icon: const Icon(Icons.send_outlined),
                    label: Text(
                      _emailSent
                          ? 'Resend verification email'
                          : 'Send verification email',
                    ),
                  ),
                ),
                VSpace.sm,
                // Continue button - full width
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _handleContinue,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('I\'ve verified my email'),
                  ),
                ),
                VSpace.sm,
                // Refresh status - centered
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : _ensureVerified,
                    child: const Text('Refresh status'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
