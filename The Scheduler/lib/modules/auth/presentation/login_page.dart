import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/demo_config.dart';
import '../../../core/providers/providers.dart';
import '../../../core/routing/role_router.dart';
import '../../../core/services/auth_state_service.dart';
import '../../../core/ui/components/components.dart';
import '../../home/presentation/home_shell.dart';
import 'forgot_password_page.dart';
import 'widgets/auth_form_widgets.dart';
import 'widgets/auth_guard.dart';
import 'email_verification_page.dart';
import 'join_with_code_page.dart';

/// Login page with email/password authentication.
/// Displays branding from AppConfig and handles Firebase Auth.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authStateServiceProvider);
      await authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      // Navigate to business dashboard with auth guard
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const AuthGuard(child: RoleRouter()),
        ),
      );
    } on MfaEnrollmentRequiredException catch (_) {
      // User needs to enroll in MFA - verify email first, then MFA
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const EmailVerificationPage()),
      );
    } on FirebaseAuthException catch (e) {
      // Temporary debug log to surface exact auth failure reason during testing.
      debugPrint('Login failed [${e.code}]: ${e.message}');
      setState(() {
        _errorMessage = _parseErrorMessage(e.code);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Login failed [unknown]: $e');
      setState(() {
        _errorMessage = _parseErrorMessage(e.toString());
        _isLoading = false;
      });
    }
  }

  Future<void> _handleDemoLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authStateServiceProvider);
      await authService.signInAsDemo();
      if (!mounted) return;
      // Navigate to business dashboard with auth guard
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const AuthGuard(child: RoleRouter()),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Demo login failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  String _parseErrorMessage(String error) {
    // HIPAA Compliance: Generic error messages to prevent user enumeration
    if (error.contains('invalid-email')) {
      return 'Invalid email address.';
    } else if (error.contains('too-many-requests')) {
      return 'Too many failed attempts. Please try again later.';
    } else {
      // Generic message for user-not-found, wrong-password, user-disabled
      // to prevent user enumeration attacks
      return 'Invalid credentials. Please check your email and password.';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (DemoConfig.isDemoMode) {
      return const HomeShell();
    }

    final config = ref.watch(appConfigProvider);
    final branding = config.branding;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    // Animation duration for consistent feel
    const animDuration = Duration(milliseconds: 350);
    const animCurve = Curves.easeOutCubic;

    return GestureDetector(
      // Dismiss keyboard when tapping outside text fields
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: isDark ? colorScheme.surfaceContainerLowest : colorScheme.surface,
        body: SafeArea(
          child: LayoutBuilder(
              builder: (context, constraints) {
                return AnimatedPadding(
                duration: animDuration,
                curve: animCurve,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: keyboardVisible ? AppSpacing.md : AppSpacing.lg,
                ),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: AnimatedContainer(
                    duration: animDuration,
                    curve: animCurve,
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - (keyboardVisible ? AppSpacing.xl : AppSpacing.xxxl),
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          // Back button row
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: isDark ? Colors.white70 : Colors.black45,
                                  size: 20,
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),

                          // Animated spacer for smooth centering
                          AnimatedContainer(
                            duration: animDuration,
                            curve: animCurve,
                            height: keyboardVisible ? AppSpacing.xs : 0,
                          ),

                          // Branding with smooth slide and fade
                          AnimatedSlide(
                            duration: animDuration,
                            curve: animCurve,
                            offset: keyboardVisible ? const Offset(0, -0.5) : Offset.zero,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                              opacity: keyboardVisible ? 0.0 : 1.0,
                              child: AnimatedContainer(
                                duration: animDuration,
                                curve: animCurve,
                                height: keyboardVisible ? 0 : null,
                                child: keyboardVisible
                                    ? const SizedBox.shrink()
                                    : Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: AppSpacing.cardPadding,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  branding.primaryColor,
                                                  branding.accentColor,
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(20),
                                              boxShadow: [
                                                // Primary navy shadow
                                                BoxShadow(
                                                  color: branding.primaryColor
                                                      .withValues(alpha: 0.4),
                                                  blurRadius: 16,
                                                  offset: const Offset(0, 8),
                                                ),
                                                // Vibrant blue glow
                                                BoxShadow(
                                                  color: branding.accentColor
                                                      .withValues(alpha: 0.3),
                                                  blurRadius: 24,
                                                  offset: const Offset(0, 12),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.calendar_month_rounded,
                                              size: 40,
                                              color: Colors.white,
                                            ),
                                          ),
                                          VSpace.lg,
                                          Text(
                                            branding.productName,
                                            style:
                                                theme.textTheme.headlineSmall?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  isDark ? Colors.white : Colors.black87,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          VSpace.xl,
                                        ],
                                      ),
                              ),
                            ),
                          ),

                          // Form with slide animation (no card container)
                          AnimatedSlide(
                            duration: animDuration,
                            curve: animCurve,
                            offset: keyboardVisible ? const Offset(0, -0.02) : Offset.zero,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 400),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Welcome back',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    VSpace.xxs,
                                    Text(
                                      'Sign in to continue',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: isDark ? Colors.white60 : Colors.black45,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    VSpace.lg,

                                    // Email field
                                    AuthTextField(
                                      controller: _emailController,
                                      focusNode: _emailFocus,
                                      label: 'Email',
                                      hint: 'you@example.com',
                                      icon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      autofillHints: const [AutofillHints.email],
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        if (!value.contains('@')) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                      onSubmitted: (_) =>
                                          _passwordFocus.requestFocus(),
                                      isDark: isDark,
                                      primaryColor: branding.primaryColor,
                                      enabled: !_isLoading,
                                    ),
                                    VSpace.md,

                                    // Password field
                                    AuthTextField(
                                      controller: _passwordController,
                                      focusNode: _passwordFocus,
                                      label: 'Password',
                                      hint: '••••••••',
                                      icon: Icons.lock_outlined,
                                      obscureText: _obscurePassword,
                                      autofillHints: const [AutofillHints.password],
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color:
                                              isDark ? Colors.white38 : Colors.black38,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your password';
                                        }
                                        if (value.length < 6) {
                                          return 'Password must be at least 6 characters';
                                        }
                                        return null;
                                      },
                                      onSubmitted: (_) => _handleLogin(),
                                      isDark: isDark,
                                      primaryColor: branding.primaryColor,
                                      enabled: !_isLoading,
                                    ),

                                    // Forgot password
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _isLoading
                                            ? null
                                            : () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const ForgotPasswordPage(),
                                                  ),
                                                );
                                              },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.xs,
                                            vertical: AppSpacing.xxs,
                                          ),
                                        ),
                                        child: Text(
                                          'Forgot password?',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: branding.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    VSpace.xs,

                                    // Error message
                                    if (_errorMessage != null) ...[
                                      Container(
                                        padding: const EdgeInsets.all(AppSpacing.sm),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.errorContainer
                                              .withValues(alpha: 0.3),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: theme.colorScheme.error
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.error_outline_rounded,
                                              color: theme.colorScheme.error,
                                              size: 20,
                                            ),
                                            HSpace.sm,
                                            Expanded(
                                              child: Text(
                                                _errorMessage!,
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  color: theme.colorScheme.error,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      VSpace.md,
                                    ],

                                    // Login button - full width with gradient
                                    GradientButton(
                                      onPressed: _handleLogin,
                                      isLoading: _isLoading,
                                      width: double.infinity,
                                      child: const Text('Sign In'),
                                    ),
                                    VSpace.md,

                                    // Join with code button - for staff with invite
                                    Center(
                                      child: TextButton.icon(
                                        onPressed: _isLoading
                                            ? null
                                            : () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const JoinWithCodePage(),
                                                  ),
                                                );
                                              },
                                        icon: Icon(
                                          Icons.group_add_rounded,
                                          size: 18,
                                          color: branding.primaryColor,
                                        ),
                                        label: Text(
                                          'Have a join code?',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: branding.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Animated bottom spacer
                        AnimatedContainer(
                          duration: animDuration,
                          curve: animCurve,
                          height: keyboardVisible ? AppSpacing.xs : 0,
                        ),

                        // Demo mode link with smooth slide and fade
                        AnimatedSlide(
                          duration: animDuration,
                          curve: animCurve,
                          offset: keyboardVisible ? const Offset(0, 0.5) : Offset.zero,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            opacity: keyboardVisible ? 0.0 : 1.0,
                            child: AnimatedContainer(
                              duration: animDuration,
                              curve: animCurve,
                              height: keyboardVisible ? 0 : null,
                              child: keyboardVisible
                                  ? const SizedBox.shrink()
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        VSpace.lg,
                                        TextButton.icon(
                                          onPressed:
                                              _isLoading ? null : _handleDemoLogin,
                                          icon: Icon(
                                            Icons.play_circle_outline_rounded,
                                            size: 18,
                                            color: isDark
                                                ? Colors.white38
                                                : Colors.black38,
                                          ),
                                          label: Text(
                                            'Try Demo Mode',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: isDark
                                                  ? Colors.white38
                                                  : Colors.black38,
                                            ),
                                          ),
                                        ),
                                        VSpace.xs,
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              );
            },
          ),
        ),
      ),
    );
  }
}
