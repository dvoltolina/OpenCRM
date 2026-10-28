import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/routing/role_router.dart';
import '../../../core/ui/components/components.dart';
import 'email_verification_page.dart';
import 'widgets/mfa_code_entry_step.dart';
import 'widgets/mfa_phone_entry_step.dart';
import 'widgets/mfa_success_step.dart';

/// MFA enrollment page for admin/owner roles.
/// Implements phone-based two-factor authentication using Firebase Auth.
/// HIPAA Compliance: No PHI in logs or error messages.
class MfaEnrollmentPage extends ConsumerStatefulWidget {
  const MfaEnrollmentPage({super.key});

  @override
  ConsumerState<MfaEnrollmentPage> createState() => _MfaEnrollmentPageState();
}

class _MfaEnrollmentPageState extends ConsumerState<MfaEnrollmentPage> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _codeFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _verificationId;
  int? _resendToken;
  PhoneAuthCredential? _credential;

  @override
  void initState() {
    super.initState();
    _redirectIfUnverified();
  }

  // Enrollment flow state
  _EnrollmentStep _currentStep = _EnrollmentStep.phoneEntry;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendVerificationCode() async {
    if (!_phoneFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // On iOS in debug mode, warn about potential configuration issues
      // Phone auth requires APNs + reCAPTCHA URL scheme to be configured
      if (kDebugMode && Platform.isIOS) {
        debugPrint('[MFA] iOS debug mode - phone auth may fail without APNs/reCAPTCHA config');
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      await user.reload();
      if (!user.emailVerified) {
        setState(() {
          _errorMessage = 'Please verify your email before setting up MFA.';
          _isLoading = false;
        });
        return;
      }

      final phoneNumber = _formatPhoneNumber(_phoneController.text.trim());
      debugPrint('[MFA] sendCode -> ${_maskPhoneNumber(phoneNumber)}');

      // Get multi-factor session
      MultiFactorSession? session;
      try {
        session = await user.multiFactor.getSession();
      } catch (e) {
        debugPrint('[MFA] getSession failed: $e');
        throw Exception('mfa-session-failed');
      }

      // Note: appVerificationDisabledForTesting does NOT work for MFA enrollment.
      // It only works for basic phone sign-in. For MFA, we need real APNs/reCAPTCHA.
      // On physical devices, ensure:
      // 1. APNs is configured in Firebase Console
      // 2. REVERSED_CLIENT_ID URL scheme is in Info.plist
      // 3. GoogleService-Info.plist has REVERSED_CLIENT_ID

      // Send verification code - wrapped in try-catch for iOS APNs issues
      try {
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          multiFactorSession: session,
          timeout: const Duration(seconds: 60),
          verificationCompleted: (PhoneAuthCredential credential) {
            // Auto-verification (Android only)
            if (mounted) {
              debugPrint('[MFA] verificationCompleted (auto)');
              setState(() {
                _credential = credential;
                _currentStep = _EnrollmentStep.codeEntry;
                _isLoading = false;
              });
            }
          },
          verificationFailed: (FirebaseAuthException error) {
            debugPrint('[MFA] verificationFailed: ${error.code}');
            if (mounted) {
              setState(() {
                _errorMessage = _parseErrorMessage(error.code);
                _isLoading = false;
              });
            }
          },
          codeSent: (String verificationId, int? resendToken) {
            debugPrint('[MFA] codeSent received');
            if (mounted) {
              setState(() {
                _verificationId = verificationId;
                _resendToken = resendToken;
                _currentStep = _EnrollmentStep.codeEntry;
                _isLoading = false;
              });
            }
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            debugPrint('[MFA] codeAutoRetrievalTimeout');
            if (mounted) {
              setState(() {
                _verificationId = verificationId;
              });
            }
          },
        );
      } catch (e) {
        // iOS may crash if APNs/reCAPTCHA not configured - this won't catch native crashes
        debugPrint('[MFA] verifyPhoneNumber threw: $e');
        throw Exception('phone-auth-config-error');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _parseErrorMessage(e.toString());
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyCodeAndEnroll() async {
    if (!_codeFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create credential from verification code
      PhoneAuthCredential credential;
      if (_credential != null) {
        // Auto-verification (Android)
        credential = _credential!;
      } else {
        if (_verificationId == null) {
          throw Exception('Verification ID not found');
        }
        debugPrint('[MFA] verifying code with verificationId');
        credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: _codeController.text.trim(),
        );
      }

      // Enroll the credential
      final multiFactorAssertion =
          PhoneMultiFactorGenerator.getAssertion(credential);
      await user.multiFactor.enroll(
        multiFactorAssertion,
        displayName: 'Phone',
      );

      debugPrint('[MFA] enrollment success');
      setState(() {
        _currentStep = _EnrollmentStep.success;
        _isLoading = false;
      });
    } on FirebaseAuthException catch (e) {
      debugPrint('[MFA] enrollment FirebaseAuthException: ${e.code}');
      setState(() {
        _errorMessage = _parseErrorMessage(e.code);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[MFA] enrollment error: $e');
      setState(() {
        _errorMessage = _parseErrorMessage(e.toString());
        _isLoading = false;
      });
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final phoneNumber = _formatPhoneNumber(_phoneController.text.trim());
      debugPrint('[MFA] resendCode -> ${_maskPhoneNumber(phoneNumber)}');

      MultiFactorSession? session;
      try {
        session = await user.multiFactor.getSession();
      } catch (e) {
        debugPrint('[MFA] getSession failed (resend): $e');
        throw Exception('mfa-session-failed');
      }

      try {
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          multiFactorSession: session,
          forceResendingToken: _resendToken,
          timeout: const Duration(seconds: 60),
          verificationCompleted: (PhoneAuthCredential credential) {
            if (mounted) {
              debugPrint('[MFA] verificationCompleted (auto) on resend');
              setState(() {
                _credential = credential;
                _isLoading = false;
              });
            }
          },
          verificationFailed: (FirebaseAuthException error) {
            debugPrint('[MFA] verificationFailed on resend: ${error.code}');
            if (mounted) {
              setState(() {
                _errorMessage = _parseErrorMessage(error.code);
                _isLoading = false;
              });
            }
          },
          codeSent: (String verificationId, int? resendToken) {
            debugPrint('[MFA] codeSent on resend received');
            if (mounted) {
              setState(() {
                _verificationId = verificationId;
                _resendToken = resendToken;
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Verification code resent'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            debugPrint('[MFA] codeAutoRetrievalTimeout on resend');
            if (mounted) {
              setState(() {
                _verificationId = verificationId;
              });
            }
          },
        );
      } catch (e) {
        debugPrint('[MFA] verifyPhoneNumber threw on resend: $e');
        throw Exception('phone-auth-config-error');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _parseErrorMessage(e.toString());
          _isLoading = false;
        });
      }
    }
  }

  void _skipMfaForDevelopment() {
    // Only available in debug mode - allows bypassing MFA setup for testing
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip MFA Setup?'),
        content: const Text(
          'This will skip two-factor authentication setup. '
          'This should only be used during development.\n\n'
          'In production, MFA is required for admin accounts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToHome();
            },
            child: const Text('Skip for Now'),
          ),
        ],
      ),
    );
  }

  void _navigateToHome() {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleRouter()),
        (route) => false,
      );
  }

  Future<void> _redirectIfUnverified() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await user.reload();
    if (!user.emailVerified && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const EmailVerificationPage()),
      );
    }
  }

  String _formatPhoneNumber(String phone) {
    // Remove all non-numeric characters
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // Add country code if not present
    if (!cleaned.startsWith('+')) {
      // Default to US country code
      return '+1$cleaned';
    }

    return cleaned;
  }

  String _maskPhoneNumber(String phone) {
    if (phone.length <= 4) return '****';
    final suffix = phone.substring(phone.length - 4);
    return '***$suffix';
  }

  String _parseErrorMessage(String error) {
    // HIPAA Compliance: Generic error messages, no PHI
    if (error.contains('invalid-phone-number')) return 'Invalid phone number format.';
    if (error.contains('too-many-requests')) return 'Too many requests. Try again later.';
    if (error.contains('invalid-verification-code')) return 'Invalid verification code.';
    if (error.contains('session-expired')) return 'Session expired. Please restart.';
    if (error.contains('quota-exceeded')) return 'SMS quota exceeded. Try again later.';
    if (error.contains('User not authenticated')) return 'Session expired. Log in again.';
    if (error.contains('phone-auth-config-error')) {
      return 'Phone auth configuration error. Ensure APNs and reCAPTCHA URL scheme are configured.';
    }
    if (error.contains('mfa-session-failed')) return 'MFA session failed. Log in again.';
    if (error.contains('network')) return 'Network error. Check connection.';
    if (error.contains('app-not-authorized')) {
      return 'App not authorized. Check Firebase Phone Auth configuration.';
    }
    if (error.contains('missing-client-identifier')) {
      return 'Missing configuration. Check GoogleService-Info.plist.';
    }
    if (error.contains('unverified-email')) {
      return 'Please verify your email first, then retry MFA.';
    }
    return 'An error occurred. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final branding = config.branding;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Identity'),
        centerTitle: false,
        leading: _currentStep == _EnrollmentStep.success
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _isLoading
                    ? null
                    : () {
                        if (_currentStep == _EnrollmentStep.codeEntry) {
                          setState(() {
                            _currentStep = _EnrollmentStep.phoneEntry;
                            _verificationId = null;
                            _credential = null;
                            _errorMessage = null;
                          });
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
              ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Icon(
                  Icons.security_rounded,
                  size: 64,
                  color: branding.primaryColor,
                ),
                VSpace.md,
                Text(
                  'Secure Your Account',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                VSpace.xs,
                Text(
                  'Two-factor authentication is required for admin and owner accounts',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                VSpace.xxxl,

                // Step content
                if (_currentStep == _EnrollmentStep.phoneEntry)
                  MfaPhoneEntryStep(
                    formKey: _phoneFormKey,
                    phoneController: _phoneController,
                    isLoading: _isLoading,
                    errorMessage: _errorMessage,
                    onSendCode: _sendVerificationCode,
                    onSkipForDevelopment: _skipMfaForDevelopment,
                  ),
                if (_currentStep == _EnrollmentStep.codeEntry)
                  MfaCodeEntryStep(
                    formKey: _codeFormKey,
                    codeController: _codeController,
                    phoneNumber: _phoneController.text,
                    isLoading: _isLoading,
                    errorMessage: _errorMessage,
                    onVerifyCode: _verifyCodeAndEnroll,
                    onResendCode: _resendCode,
                  ),
                if (_currentStep == _EnrollmentStep.success)
                  MfaSuccessStep(
                    onContinue: _navigateToHome,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _EnrollmentStep {
  phoneEntry,
  codeEntry,
  success,
}
