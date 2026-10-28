import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/routing/role_router.dart';
import '../../../core/ui/components/components.dart';
import 'email_verification_page.dart';
import 'mfa_enrollment_page.dart';

/// Page for handling invite link deep links.
/// Processes invite URLs in the format: app.example.com/invite/{inviteId}?token={token}
/// HIPAA Compliance: Generic error messages only, no PHI in logs.
class InviteLinkHandlerPage extends ConsumerStatefulWidget {
  const InviteLinkHandlerPage({
    super.key,
    required this.inviteId,
    required this.token,
  });

  final String inviteId;
  final String token;

  @override
  ConsumerState<InviteLinkHandlerPage> createState() =>
      _InviteLinkHandlerPageState();
}

class _InviteLinkHandlerPageState extends ConsumerState<InviteLinkHandlerPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isLoading = true;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _inviteEmail;
  bool _needsUserInput = false;
  bool _isNewUser = false;

  @override
  void initState() {
    super.initState();
    _validateInvite();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _passwordController.dispose();
    _displayNameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _validateInvite() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if user is already authenticated
      final currentUser = FirebaseAuth.instance.currentUser;
      _isNewUser = currentUser == null;

      // Call the backend to validate invite (without accepting yet)
      final callable = FirebaseFunctions.instance.httpsCallable(
        'validateInvite',
      );

      final result = await callable.call(<String, dynamic>{
        'inviteId': widget.inviteId,
        'token': widget.token,
      });

      if (!mounted) return;

      final data = result.data as Map<String, dynamic>;
      final valid = data['valid'] as bool? ?? false;

      if (valid) {
        _inviteEmail = data['email'] as String?;

        // Check if we need user input (new user needs password and display name)
        if (_isNewUser) {
          setState(() {
            _needsUserInput = true;
            _isLoading = false;
          });
        } else {
          // Existing user - proceed to accept invite
          await _acceptInvite();
        }
      } else {
        setState(() {
          _errorMessage = _parseErrorMessage(data['error'] as String? ?? 'invalid-invite');
          _isLoading = false;
        });
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[InviteLink] FirebaseFunctionsException: ${e.code}');
      if (mounted) {
        setState(() {
          _errorMessage = _parseErrorMessage(e.code);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[InviteLink] Error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _acceptInvite() async {
    if (_needsUserInput && !_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // If new user, create account first
      if (_isNewUser && _needsUserInput) {
        if (_inviteEmail == null || _inviteEmail!.isEmpty) {
          throw Exception('Invalid invite email');
        }

        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _inviteEmail!,
          password: _passwordController.text,
        );
      }

      // Call the acceptInvite callable
      final callable = FirebaseFunctions.instance.httpsCallable(
        'acceptInvite',
      );

      final result = await callable.call(<String, dynamic>{
        'inviteId': widget.inviteId,
        'token': widget.token,
        if (_needsUserInput) 'displayName': _displayNameController.text.trim(),
        if (_needsUserInput && _isNewUser) 'password': _passwordController.text,
      });

      if (!mounted) return;

      final data = result.data as Map<String, dynamic>;
      final success = data['success'] as bool? ?? false;

      if (success) {
        // Success - route through verification flow
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
      } else {
        setState(() {
          _errorMessage = _parseErrorMessage(data['error'] as String? ?? 'unknown');
          _isLoading = false;
        });
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[InviteLink] acceptInvite FirebaseFunctionsException: ${e.code}');
      if (mounted) {
        setState(() {
          _errorMessage = _parseErrorMessage(e.code);
          _isLoading = false;
        });
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('[InviteLink] acceptInvite FirebaseAuthException: ${e.code}');
      if (mounted) {
        setState(() {
          _errorMessage = _parseAuthErrorMessage(e.code);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[InviteLink] acceptInvite Error: $e');
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
    if (error.contains('invalid-invite') ||
        error.contains('expired') ||
        error.contains('not-found') ||
        error.contains('revoked')) {
      return 'Invalid or expired invite link. Please contact your administrator.';
    } else if (error.contains('already-used')) {
      return 'This invite has already been used.';
    } else if (error.contains('email-mismatch')) {
      return 'This invite is for a different email address.';
    } else if (error.contains('rate-limit') ||
               error.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    } else if (error.contains('network')) {
      return 'Network error. Please check your connection.';
    }
    return 'Invalid or expired invite link. Please contact your administrator.';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Invite'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: _isLoading && !_needsUserInput
                ? _buildLoadingState(theme, branding)
                : _needsUserInput
                    ? _buildInputForm(theme, branding)
                    : _buildErrorState(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme, dynamic branding) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.mail_outline,
          size: 64,
          color: branding.primaryColor,
        ),
        VSpace.lg,
        Text(
          'Processing Invite',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        VSpace.md,
        const CircularProgressIndicator(),
        VSpace.md,
        Text(
          'Please wait while we validate your invitation...',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInputForm(ThemeData theme, dynamic branding) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header icon
          Icon(
            Icons.mail_outline,
            size: 64,
            color: branding.primaryColor,
          ),
          VSpace.md,

          // Title
          Text(
            'Complete Your Profile',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          VSpace.xs,

          // Subtitle
          Text(
            _inviteEmail != null
                ? 'You\'ve been invited to join as $_inviteEmail'
                : 'Complete your profile to accept the invitation',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          VSpace.xl,

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
            onFieldSubmitted: (_) =>
                _isNewUser ? _passwordFocus.requestFocus() : _acceptInvite(),
          ),

          // Password field (only for new users)
          if (_isNewUser) ...[
            VSpace.md,
            TextFormField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outlined),
                border: const OutlineInputBorder(),
                helperText: 'Create a password for your account',
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
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
              enabled: !_isLoading,
              onFieldSubmitted: (_) => _acceptInvite(),
            ),
          ],
          VSpace.lg,

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

          // Accept button
          FilledButton(
            onPressed: _isLoading ? null : _acceptInvite,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Accept Invitation'),
          ),
          VSpace.md,

          // Cancel button
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    Navigator.of(context).pop();
                  },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: theme.colorScheme.error,
        ),
        VSpace.md,
        Text(
          'Invalid Invite',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        VSpace.md,
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        VSpace.lg,
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Back to Login'),
        ),
      ],
    );
  }
}
