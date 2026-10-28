import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/routing/role_router.dart';
import '../../../core/ui/components/components.dart';
import 'email_verification_page.dart';
import 'mfa_enrollment_page.dart';

/// Page for staff to join a business using a join code.
/// Implements the staff onboarding flow as specified in 11_staff_onboarding.md.
/// HIPAA Compliance: Generic error messages only, no PHI in logs.
class JoinWithCodePage extends ConsumerStatefulWidget {
  const JoinWithCodePage({super.key});

  @override
  ConsumerState<JoinWithCodePage> createState() => _JoinWithCodePageState();
}

class _JoinWithCodePageState extends ConsumerState<JoinWithCodePage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _displayNameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;
  bool _requiresApproval = false;

  @override
  void dispose() {
    _codeController.dispose();
    _emailController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    _codeFocus.dispose();
    _emailFocus.dispose();
    _displayNameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleJoinWithCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
      _requiresApproval = false;
    });

    try {
      // Check if user is already authenticated
      final currentUser = FirebaseAuth.instance.currentUser;
      final isNewUser = currentUser == null;

      // If new user, create account first
      if (isNewUser) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      // Call the requestJoinWithCode callable
      final callable = FirebaseFunctions.instance.httpsCallable(
        'requestJoinWithCode',
      );

      final result = await callable.call(<String, dynamic>{
        'code': _codeController.text.trim().toUpperCase(),
        'email': _emailController.text.trim(),
        'displayName': _displayNameController.text.trim(),
        'deviceInfo': {
          'platform': defaultTargetPlatform.name,
          'timestamp': DateTime.now().toIso8601String(),
        },
      });

      if (!mounted) return;

      final data = result.data as Map<String, dynamic>;
      final success = data['success'] as bool? ?? true;

      if (success) {
        // Check if requires approval
        _requiresApproval = data['requiresApproval'] as bool? ?? false;

        if (_requiresApproval) {
          // Show pending approval state
          setState(() {
            _successMessage =
                'Your join request has been submitted and is pending approval. '
                'You will be notified when an admin approves your request.';
            _isLoading = false;
          });
        } else {
          // Success - attach business and route through verification flow
          final emailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
          final requiresMfa = data['requiresMfa'] as bool? ?? false;

          if (!emailVerified) {
            // Route to email verification
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const EmailVerificationPage()),
            );
          } else if (requiresMfa) {
            // Route to MFA enrollment
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MfaEnrollmentPage()),
            );
          } else {
            // Route to home
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const RoleRouter()),
            );
          }
        }
      } else {
        setState(() {
          _errorMessage = _parseErrorMessage(data['error'] as String? ?? 'unknown');
          _isLoading = false;
        });
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[JoinCode] FirebaseFunctionsException: ${e.code}');
      if (mounted) {
        setState(() {
          _errorMessage = _parseErrorMessage(e.code);
          _isLoading = false;
        });
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('[JoinCode] FirebaseAuthException: ${e.code}');
      if (mounted) {
        setState(() {
          _errorMessage = _parseAuthErrorMessage(e.code);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[JoinCode] Error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  String _parseErrorMessage(String error) {
    // HIPAA Compliance: Generic error messages to prevent enumeration
    if (error.contains('invalid-code') ||
        error.contains('expired') ||
        error.contains('not-found') ||
        error.contains('revoked')) {
      return 'Invalid code or expired. Please try again.';
    } else if (error.contains('rate-limit') ||
               error.contains('too-many-requests') ||
               error.contains('quota-exceeded')) {
      return 'Too many attempts. Please try again later.';
    } else if (error.contains('already-attached') ||
               error.contains('already-member')) {
      return 'This account is already associated with a business.';
    } else if (error.contains('network')) {
      return 'Network error. Please check your connection.';
    }
    return 'Invalid code or expired. Please try again.';
  }

  String _parseAuthErrorMessage(String error) {
    // HIPAA Compliance: Generic error messages
    if (error.contains('invalid-email')) {
      return 'Invalid email address.';
    } else if (error.contains('weak-password')) {
      return 'Password is too weak. Use at least 6 characters.';
    } else if (error.contains('email-already-in-use')) {
      return 'Email already in use. Please sign in instead.';
    } else if (error.contains('network-request-failed')) {
      return 'Network error. Please check your connection.';
    }
    return 'An error occurred. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final branding = config.branding;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Join with Code'),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header icon with gradient container
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            branding.primaryColor,
                            branding.accentColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        boxShadow: [
                          // Primary navy shadow
                          BoxShadow(
                            color: branding.primaryColor
                                .withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                          // Vibrant blue glow
                          BoxShadow(
                            color: branding.accentColor
                                .withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.group_add_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    VSpace.md,

                    // Title
                    Text(
                      'Join a Business',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    VSpace.xs,

                    // Subtitle
                    Text(
                      'Enter the join code provided by your business owner or administrator',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    VSpace.xl,

                    // Join code field
                    TextFormField(
                      controller: _codeController,
                      focusNode: _codeFocus,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Join Code',
                        prefixIcon: Icon(Icons.vpn_key_outlined),
                        border: OutlineInputBorder(),
                        helperText: '6-8 character code',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your join code';
                        }
                        if (value.trim().length < 6 || value.trim().length > 8) {
                          return 'Code must be 6-8 characters';
                        }
                        return null;
                      },
                      enabled: !_isLoading,
                      onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                    ),
                    VSpace.md,

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      focusNode: _emailFocus,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                      enabled: !_isLoading,
                      onFieldSubmitted: (_) => _displayNameFocus.requestFocus(),
                    ),
                    VSpace.md,

                    // Display name field
                    TextFormField(
                      controller: _displayNameController,
                      focusNode: _displayNameFocus,
                      autofillHints: const [AutofillHints.name],
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                      enabled: !_isLoading,
                      onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                    ),
                    VSpace.md,

                    // Password field (for new users)
                    TextFormField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        border: const OutlineInputBorder(),
                        helperText: 'Required if creating a new account',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        // Password is required for new users
                        if (FirebaseAuth.instance.currentUser == null) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                        }
                        return null;
                      },
                      enabled: !_isLoading,
                      onFieldSubmitted: (_) => _handleJoinWithCode(),
                    ),
                    VSpace.lg,

                    // Info card
                    Card(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      child: Padding(
                        padding: AppSpacing.cardPadding,
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.primary,
                            ),
                            HSpace.sm,
                            Expanded(
                              child: Text(
                                'Your join code was provided by your business. '
                                'If you don\'t have one, contact your administrator.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    VSpace.md,

                    // Error message
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: theme.colorScheme.error,
                            ),
                            HSpace.sm,
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      VSpace.md,
                    ],

                    // Success message (pending approval)
                    if (_successMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: theme.colorScheme.primary,
                            ),
                            HSpace.sm,
                            Expanded(
                              child: Text(
                                _successMessage!,
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      VSpace.md,
                    ],

                    // Join button with gradient
                    GradientButton(
                      onPressed: _requiresApproval ? null : _handleJoinWithCode,
                      isLoading: _isLoading,
                      width: double.infinity,
                      child: const Text('Join Business'),
                    ),
                    VSpace.md,

                    // Back button
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.of(context).pop();
                            },
                      child: const Text('Back to Login'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
