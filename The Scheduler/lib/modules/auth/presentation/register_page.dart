import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/routing/role_router.dart';
import '../../../core/services/auth_state_service.dart';
import '../../../core/ui/components/components.dart';
import '../../../data/models/business_industry.dart';
import '../../../data/models/user_role.dart';
import 'mfa_enrollment_page.dart';
import 'utils/auth_flow_utils.dart';
import 'widgets/auth_form_widgets.dart';
import 'widgets/auth_guard.dart';
import 'email_verification_page.dart';
import 'join_with_code_page.dart';

/// Registration page for new users.
/// Collects email, password, display name, industry, and assigns a role.
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key, this.initialIndustry});

  final BusinessIndustry? initialIndustry;

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _businessNameController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  UserRole _selectedRole = UserRole.owner;
  final bool _isCreatingNewBusiness = true;

  // Industry and MFA settings
  late BusinessIndustry _selectedIndustry;
  bool _enableMfaOptional = false; // For non-HIPAA industries

  @override
  void initState() {
    super.initState();
    _selectedIndustry = widget.initialIndustry ?? BusinessIndustry.other;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }

  bool get _requiresHipaa => _selectedIndustry.defaultRequiresHipaa;
  bool get _mfaEnabled => _requiresHipaa || _enableMfaOptional;

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create user account first (without businessId - will be set by createWorkspace)
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.registerWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        businessId: 'pending', // Temporary - will be updated by createWorkspace
        role: UserRole.owner, // Always owner for new workspace creators
        displayName: _displayNameController.text.trim(),
      );

      // Create workspace via Cloud Function (generates ULID, invite code, public booking URL)
      if (_isCreatingNewBusiness) {
        final workspaceRepo = ref.read(workspaceRepositoryProvider);
        final workspaceResponse = await workspaceRepo.createWorkspace(
          businessName: _businessNameController.text.trim(),
          ownerEmail: _emailController.text.trim(),
          ownerDisplayName: _displayNameController.text.trim(),
          industry: _selectedIndustry.value,
          requiresHipaaCompliance: _requiresHipaa,
          mfaEnabled: _mfaEnabled,
        );

        // The workspace callable issues auth claims. Refresh them before routing
        // so startup guards don't see a stale "pending" business membership.
        await authRepository.refreshCurrentUserToken();

        // Configure persistence immediately based on HIPAA setting for the new business
        await applyBusinessPersistence(
          authRepository: ref.read(authRepositoryProvider),
          requiresHipaa: workspaceResponse.requiresHipaaCompliance,
        );

        // Store invite code and booking URL for display
        // User will be redirected to show these details
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Workspace created! Invite code: ${workspaceResponse.inviteCode}',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // If MFA is enabled and user is admin/owner, redirect to email verification first
        if (_mfaEnabled &&
            (_selectedRole == UserRole.owner ||
                _selectedRole == UserRole.admin)) {
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
    } on MfaEnrollmentRequiredException {
      // Redirect to MFA enrollment
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MfaEnrollmentPage()),
          (route) => false,
        );
      }
    } catch (e) {
      // HIPAA: Log error code only, not full message which may contain PII
      final errorCode = e.toString().contains('[')
          ? e.toString().split('[').last.split(']').first
          : 'unknown';
      debugPrint('Registration failed: $errorCode');
      if (mounted) {
        setState(() {
          _errorMessage = _parseErrorMessage(e.toString());
          _isLoading = false;
        });
      }
    }
  }

  String _parseErrorMessage(String error) {
    // HIPAA Compliance: Generic error messages to prevent user enumeration
    if (error.contains('invalid-email')) {
      return 'Invalid email address.';
    } else if (error.contains('weak-password')) {
      return 'Password is too weak. Use at least 6 characters.';
    } else if (error.contains('network-request-failed')) {
      return 'Network error. Please check your connection.';
    } else if (error.contains('email-already-in-use')) {
      // Generic message to prevent user enumeration
      return 'Registration failed. Please check your information or contact support.';
    } else {
      return 'Registration failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final branding = config.branding;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      // Dismiss keyboard when tapping outside text fields
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Create Account')),
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
                    // Header
                    Text(
                      'Join ${branding.productName}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    VSpace.xs,
                    Text(
                      'Create your account to get started',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    VSpace.xl,

                    // Display name
                    TextFormField(
                      controller: _displayNameController,
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
                    ),
                    VSpace.md,

                    // Email
                    TextFormField(
                      controller: _emailController,
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
                    ),
                    VSpace.md,

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        border: const OutlineInputBorder(),
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
                    ),
                    VSpace.md,

                    // Confirm password
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                      enabled: !_isLoading,
                    ),
                    VSpace.lg,

                    // Business setup section
                    Card(
                      child: Padding(
                        padding: AppSpacing.cardPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Business Setup',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            VSpace.md,

                            // Business name (only for new business)
                            if (_isCreatingNewBusiness) ...[
                              TextFormField(
                                controller: _businessNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Business Name',
                                  prefixIcon: Icon(Icons.business_outlined),
                                  border: OutlineInputBorder(),
                                  helperText:
                                      'Name of your clinic, practice, or organization',
                                ),
                                validator: (value) {
                                  if (_isCreatingNewBusiness &&
                                      (value == null || value.trim().isEmpty)) {
                                    return 'Please enter your business name';
                                  }
                                  return null;
                                },
                                enabled: !_isLoading,
                              ),
                              VSpace.md,

                              // Industry selection
                              AuthDropdown<BusinessIndustry>(
                                value: _selectedIndustry,
                                labelText: 'Industry',
                                icon: Icons.category_outlined,
                                isDark: isDark,
                                primaryColor: branding.primaryColor,
                                enabled: !_isLoading,
                                items: BusinessIndustry.values.map((industry) {
                                  return AuthDropdownItem(
                                    value: industry,
                                    label: industry.displayName,
                                    subtitle: industry.defaultRequiresHipaa
                                        ? 'HIPAA compliant • MFA required'
                                        : null,
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedIndustry = value;
                                      // Reset optional MFA when switching industries
                                      if (value.defaultRequiresHipaa) {
                                        _enableMfaOptional = false;
                                      }
                                    });
                                  }
                                },
                              ),
                              VSpace.md,
                            ],

                            // Role selection
                            AuthDropdown<UserRole>(
                              value: _selectedRole,
                              labelText: 'Your Role',
                              icon: Icons.badge_outlined,
                              isDark: isDark,
                              primaryColor: branding.primaryColor,
                              enabled: !_isLoading,
                              items: const [
                                AuthDropdownItem(
                                  value: UserRole.owner,
                                  label: 'Owner',
                                  subtitle: 'Full access to all features',
                                ),
                                AuthDropdownItem(
                                  value: UserRole.admin,
                                  label: 'Administrator',
                                  subtitle: 'Manage staff and settings',
                                ),
                                AuthDropdownItem(
                                  value: UserRole.staff,
                                  label: 'Staff Member',
                                  subtitle: 'Day-to-day operations',
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedRole = value;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Security settings section (only for non-HIPAA industries)
                    if (!_requiresHipaa && _isCreatingNewBusiness) ...[
                      VSpace.md,
                      Card(
                        child: Padding(
                          padding: AppSpacing.cardPadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.security_outlined,
                                    color: theme.colorScheme.primary,
                                  ),
                                  HSpace.xs,
                                  Text(
                                    'Security',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              VSpace.sm,
                              SwitchListTile(
                                title: const Text(
                                  'Enable Two-Factor Authentication',
                                ),
                                subtitle: const Text(
                                  'Require phone verification for admin logins',
                                ),
                                value: _enableMfaOptional,
                                onChanged: _isLoading
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _enableMfaOptional = value;
                                        });
                                      },
                                contentPadding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // HIPAA notice for healthcare industries
                    if (_requiresHipaa && _isCreatingNewBusiness) ...[
                      VSpace.md,
                      Card(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        child: Padding(
                          padding: AppSpacing.cardPadding,
                          child: Row(
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              HSpace.sm,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'HIPAA Compliance Enabled',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    VSpace.xxs,
                                    Text(
                                      'Two-factor authentication will be required for admin accounts to protect sensitive data.',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    VSpace.lg,

                    // Error message
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
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

                    // Register button - full width with gradient
                    GradientButton(
                      onPressed: _handleRegister,
                      isLoading: _isLoading,
                      width: double.infinity,
                      child: const Text('Create Account'),
                    ),
                    VSpace.md,

                    // Back to login - full width
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.of(context).pop();
                              },
                        child: const Text('Already have an account? Sign In'),
                      ),
                    ),
                    VSpace.xs,

                    // Join with code link - centered
                    Center(
                      child: TextButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const JoinWithCodePage(),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.group_add_rounded, size: 18),
                        label: const Text('Join with an invite code'),
                      ),
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
