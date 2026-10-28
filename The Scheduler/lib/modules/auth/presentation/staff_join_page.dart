import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/routing/role_router.dart';
import '../../../core/ui/components/components.dart';
import 'email_verification_page.dart';
import 'widgets/auth_guard.dart';
import 'widgets/staff_join_forms.dart';
import 'utils/auth_flow_utils.dart';

/// Page for Admin/Staff to join a business using an invite code.
/// Shows code entry first, then account creation form after validation.
/// Enforces MFA if the business requires HIPAA compliance.
class StaffJoinPage extends ConsumerStatefulWidget {
  const StaffJoinPage({
    super.key,
    required this.isAdmin,
    this.validateInviteCodeOverride,
    this.requestJoinOverride,
    this.firebaseAuthOverride,
  });

  /// Whether the user selected Admin (true) or Staff (false)
  final bool isAdmin;
  final Future<Map<String, dynamic>> Function(String inviteCode)?
  validateInviteCodeOverride;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> payload)?
  requestJoinOverride;
  final FirebaseAuth? firebaseAuthOverride;

  @override
  ConsumerState<StaffJoinPage> createState() => _StaffJoinPageState();
}

class _StaffJoinPageState extends ConsumerState<StaffJoinPage> {
  late final FirebaseAuth _auth;
  // Form keys and controllers
  final _codeFormKey = GlobalKey<FormState>();
  final _accountFormKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // State
  bool _isLoading = false;
  String? _errorMessage;

  // After code validation
  bool _codeValidated = false;
  String? _businessName;
  bool _requiresHipaaCompliance = false;
  bool _mfaEnabled = false;

  @override
  void initState() {
    super.initState();
    _auth = widget.firebaseAuthOverride ?? FirebaseAuth.instance;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _emailController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _resetCodeValidation() {
    setState(() {
      _codeValidated = false;
      _errorMessage = null;
    });
  }

  Future<void> _validateCode() async {
    if (!_codeFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic> data;
      if (widget.validateInviteCodeOverride != null) {
        data = await widget.validateInviteCodeOverride!(
          _codeController.text.trim().toUpperCase(),
        );
      } else {
        final callable = FirebaseFunctions.instance.httpsCallable(
          'validateInviteCode',
        );
        final result = await callable.call(<String, dynamic>{
          'inviteCode': _codeController.text.trim().toUpperCase(),
        });
        if (!mounted) return;
        data = result.data as Map<String, dynamic>;
      }

      final valid = data['valid'] as bool? ?? false;

      if (valid) {
        setState(() {
          _codeValidated = true;
          _businessName = data['businessName'] as String?;
          _requiresHipaaCompliance =
              data['requiresHipaaCompliance'] as bool? ?? false;
          _mfaEnabled = data['mfaEnabled'] as bool? ?? false;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Invalid code. Please check and try again.';
          _isLoading = false;
        });
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[StaffJoin] FirebaseFunctionsException: ${e.code}');
      if (mounted) {
        setState(() {
          _errorMessage = 'Invalid code. Please check and try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[StaffJoin] Error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createAccount() async {
    if (!_accountFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Update display name
      await credential.user?.updateDisplayName(
        _displayNameController.text.trim(),
      );

      // Call requestJoinWithCode to attach user to business
      Map<String, dynamic> data;
      final payload = <String, dynamic>{
        'code': _codeController.text.trim().toUpperCase(),
        'email': _emailController.text.trim(),
        'displayName': _displayNameController.text.trim(),
        'deviceInfo': {
          'platform': defaultTargetPlatform.name,
          'timestamp': DateTime.now().toIso8601String(),
        },
      };

      if (widget.requestJoinOverride != null) {
        data = await widget.requestJoinOverride!(payload);
      } else {
        final callable = FirebaseFunctions.instance.httpsCallable(
          'requestJoinWithCode',
        );
        final result = await callable.call(payload);

        if (!mounted) return;
        data = result.data as Map<String, dynamic>;
      }

      final success = data['success'] as bool? ?? false;
      final requiresApproval = data['requiresApproval'] as bool? ?? false;

      if (success) {
        try {
          await _auth.currentUser?.getIdToken(true);
        } catch (_) {
          // Best-effort: claim refresh should not block the join flow.
        }

        // Apply HIPAA-aware persistence so web sessions respect business policy
        await applyBusinessPersistence(
          authRepository: ref.read(authRepositoryProvider),
          requiresHipaa: _requiresHipaaCompliance,
        );

        if (requiresApproval) {
          // Show pending approval message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Your request has been submitted for approval. You will be notified when approved.',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 5),
              ),
            );
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        } else if (mounted) {
          // Navigate based on requirements
          // If HIPAA/MFA is required for admin roles, go through email verification then MFA enrollment
          if (shouldRouteToMfa(
            mfaEnabled: _mfaEnabled,
            isAdmin: widget.isAdmin,
          )) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const EmailVerificationPage()),
              (route) => false,
            );
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const AuthGuard(child: RoleRouter()),
              ),
              (route) => false,
            );
          }
        }
      } else {
        setState(() {
          _errorMessage = _parseErrorMessage(
            data['error'] as String? ?? 'unknown',
          );
          _isLoading = false;
        });
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('[StaffJoin] FirebaseAuthException: ${e.code}');
      if (mounted) {
        setState(() {
          _errorMessage = _parseAuthErrorMessage(e.code);
          _isLoading = false;
        });
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[StaffJoin] FirebaseFunctionsException: ${e.code}');
      if (mounted) {
        setState(() {
          _errorMessage = _parseErrorMessage(e.code);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[StaffJoin] Error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  String _parseErrorMessage(String error) {
    // HIPAA Compliance: Generic error messages
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
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final roleText = widget.isAdmin ? 'Administrator' : 'Staff Member';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: isDark
            ? colorScheme.surfaceContainerLowest
            : colorScheme.surface,
        appBar: AppBar(
          title: Text('Join as $roleText'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: AppSpacing.pagePadding,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: _codeValidated
                    ? StaffAccountForm(
                        formKey: _accountFormKey,
                        displayNameController: _displayNameController,
                        emailController: _emailController,
                        passwordController: _passwordController,
                        confirmPasswordController: _confirmPasswordController,
                        businessName: _businessName,
                        showHipaaNotice: _requiresHipaaCompliance,
                        isAdmin: widget.isAdmin,
                        isLoading: _isLoading,
                        errorMessage: _errorMessage,
                        onSubmit: _createAccount,
                        onCancel: () => Navigator.of(context).pop(),
                        onChangeCode: _resetCodeValidation,
                      )
                    : StaffInviteCodeForm(
                        formKey: _codeFormKey,
                        codeController: _codeController,
                        isLoading: _isLoading,
                        errorMessage: _errorMessage,
                        onSubmit: _validateCode,
                        onBack: () => Navigator.of(context).pop(),
                        primaryColor: branding.primaryColor,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
