import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/utils/safe_error_handler.dart';
import '../../client_portal/presentation/client_home_shell.dart';
import 'client_register_page.dart';
import 'guest_booking_page.dart';
import 'widgets/client_social_login_buttons.dart';

/// Login page for clients accessing the Client Portal.
class ClientLoginPage extends ConsumerStatefulWidget {
  const ClientLoginPage({super.key, this.businessId});

  /// If provided, restricts login to this specific business
  final String? businessId;

  @override
  ConsumerState<ClientLoginPage> createState() => _ClientLoginPageState();
}

class _ClientLoginPageState extends ConsumerState<ClientLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;
    if (widget.businessId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final businessId = widget.businessId!;

      final customerAuthService = ref.read(customerAuthServiceProvider);
      await customerAuthService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        businessId: businessId,
      );

      if (!mounted) return;

      // Navigate to client home
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ClientHomeShell(businessId: businessId),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = SafeErrorHandler.handle(
          e,
          context: 'client_email_login',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSocialLogin(ClientSocialProvider provider) async {
    if (_isLoading || widget.businessId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final businessId = widget.businessId!;
      final socialAuthService = ref.read(socialAuthServiceProvider);
      final customerAuthService = ref.read(customerAuthServiceProvider);

      if (provider == ClientSocialProvider.google) {
        await customerAuthService.signInWithGoogle(
          businessId: businessId,
          socialAuthService: socialAuthService,
        );
      } else {
        await customerAuthService.signInWithApple(
          businessId: businessId,
          socialAuthService: socialAuthService,
        );
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ClientHomeShell(businessId: businessId),
        ),
      );
    } catch (e, stackTrace) {
      setState(() {
        _errorMessage = SafeErrorHandler.handle(
          e,
          context: 'client_social_login',
          stackTrace: stackTrace,
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final branding = config.branding;
    final theme = Theme.of(context);
    final enableSocialLogin = config.featureFlags.enableClientSocialLogin;

    // If no businessId was provided, show error state
    if (widget.businessId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Client Login'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                VSpace.md,
                Text(
                  'Business Not Selected',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                VSpace.xs,
                Text(
                  'Please go back and enter your healthcare provider\'s business code to access the client portal.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                VSpace.lg,
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Client Login'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo & branding with gradient container
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
                        borderRadius: BorderRadius.circular(16),
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
                        Icons.person_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    VSpace.md,
                    Text(
                      'Client Portal',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: branding.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    VSpace.xs,
                    Text(
                      'Sign in to manage your appointments',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    VSpace.xl,

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
                              color: theme.colorScheme.onErrorContainer,
                            ),
                            HSpace.xs,
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      VSpace.md,
                    ],

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    VSpace.md,

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleLogin(),
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
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    VSpace.xs,

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _showForgotPasswordDialog(),
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    VSpace.lg,

                    // Login button with gradient
                    GradientButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      isLoading: _isLoading,
                      width: double.infinity,
                      height: 48,
                      child: const Text('Sign In'),
                    ),
                    if (enableSocialLogin) ...[
                      VSpace.md,
                      ClientSocialLoginButtons(
                        isLoading: _isLoading,
                        onTap: _handleSocialLogin,
                      ),
                    ],
                    VSpace.lg,

                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    VSpace.lg,

                    // Register link
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ClientRegisterPage(
                              businessId: widget.businessId,
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Create Account'),
                    ),
                    VSpace.sm,

                    // Guest booking option
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => GuestBookingPage(
                              businessId: widget.businessId,
                            ),
                          ),
                        );
                      },
                      child: const Text('Book as Guest'),
                    ),
                    VSpace.md,

                    // Magic link info
                    Text(
                      'Received a booking link? Click it directly to access your appointment.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
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

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController(text: _emailController.text);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
              ),
              VSpace.md,
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty || !email.contains('@')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid email'),
                    ),
                  );
                  return;
                }

                try {
                  final customerAuthService = ref.read(customerAuthServiceProvider);
                  await customerAuthService.sendPasswordResetEmail(
                    email: email,
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password reset email sent'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to send reset email. Please try again.'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Send Reset Link'),
            ),
          ],
        );
      },
    );
  }
}
