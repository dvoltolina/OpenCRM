import 'package:flutter/material.dart';

import '../../../../core/ui/components/components.dart';

class StaffInviteCodeForm extends StatelessWidget {
  const StaffInviteCodeForm({
    super.key,
    required this.formKey,
    required this.codeController,
    required this.isLoading,
    required this.errorMessage,
    required this.onSubmit,
    required this.onBack,
    required this.primaryColor,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController codeController;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onSubmit;
  final VoidCallback onBack;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.vpn_key_rounded,
            size: 64,
            color: primaryColor,
          ),
          VSpace.lg,
          Text(
            'Enter Invite Code',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          VSpace.sm,
          Text(
            'Enter the invite code provided by your business owner or administrator',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          VSpace.xl,
          TextFormField(
            controller: codeController,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 4,
            ),
            decoration: const InputDecoration(
              labelText: 'Invite Code',
              hintText: 'XXXXXXXX',
              prefixIcon: Icon(Icons.key_rounded),
              border: OutlineInputBorder(),
              helperText: '8-character code from your business',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your invite code';
              }
              if (value.trim().length < 6) {
                return 'Code must be at least 6 characters';
              }
              return null;
            },
            enabled: !isLoading,
            onFieldSubmitted: (_) => onSubmit(),
          ),
          VSpace.lg,
          if (errorMessage != null) ...[
            _ErrorBanner(message: errorMessage!),
            VSpace.lg,
          ],
          FilledButton(
            onPressed: isLoading ? null : onSubmit,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Continue'),
          ),
          VSpace.md,
          TextButton(
            onPressed: isLoading ? null : onBack,
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }
}

class StaffAccountForm extends StatefulWidget {
  const StaffAccountForm({
    super.key,
    required this.formKey,
    required this.displayNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.businessName,
    required this.showHipaaNotice,
    required this.isAdmin,
    required this.isLoading,
    required this.errorMessage,
    required this.onSubmit,
    required this.onCancel,
    required this.onChangeCode,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController displayNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final String? businessName;
  final bool showHipaaNotice;
  final bool isAdmin;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  final VoidCallback onChangeCode;

  @override
  State<StaffAccountForm> createState() => _StaffAccountFormState();
}

class _StaffAccountFormState extends State<StaffAccountForm> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: theme.colorScheme.primary,
                ),
                HSpace.sm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Joining',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        widget.businessName ?? 'Business',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: widget.isLoading ? null : widget.onChangeCode,
                  child: const Text('Change'),
                ),
              ],
            ),
          ),
          if (widget.showHipaaNotice) ...[
            VSpace.md,
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    color: theme.colorScheme.tertiary,
                    size: 20,
                  ),
                  HSpace.sm,
                  Expanded(
                    child: Text(
                      widget.isAdmin
                          ? 'This business requires HIPAA compliance. Admin accounts must enroll in two-factor authentication.'
                          : 'This business requires HIPAA compliance. Admin accounts on this business must enroll in two-factor authentication.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          VSpace.xl,
          Text(
            'Create Your Account',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          VSpace.lg,
          TextFormField(
            controller: widget.displayNameController,
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
            enabled: !widget.isLoading,
          ),
          VSpace.md,
          TextFormField(
            controller: widget.emailController,
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
            enabled: !widget.isLoading,
          ),
          VSpace.md,
          TextFormField(
            controller: widget.passwordController,
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
            enabled: !widget.isLoading,
          ),
          VSpace.md,
          TextFormField(
            controller: widget.confirmPasswordController,
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
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != widget.passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            enabled: !widget.isLoading,
          ),
          VSpace.lg,
          if (widget.errorMessage != null) ...[
            _ErrorBanner(message: widget.errorMessage!),
            VSpace.lg,
          ],
          FilledButton(
            onPressed: widget.isLoading ? null : widget.onSubmit,
            child: widget.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create Account'),
          ),
          VSpace.md,
          TextButton(
            onPressed: widget.isLoading ? null : widget.onCancel,
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
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
              message,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
