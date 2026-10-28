import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/ui/components/components.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/safe_error_handler.dart';
import '../../../data/models/client.dart';
import '../../../data/models/security_context.dart';
import '../../../data/models/file_attachment.dart';
import '../../../core/services/file_storage_service.dart';
import 'widgets/document_upload_card.dart';

/// Customer Profile Page - Customer portal profile and preferences management
///
/// Features:
/// - View and edit contact information (email, phone)
/// - Manage notification preferences (email/SMS toggles)
/// - Set preferred providers and services
/// - Set time preferences for bookings
/// - Upload profile photo (placeholder)
/// - View uploaded documents (placeholder - integrate with file storage)
/// - Change password
/// - Delete account
///
/// Requires authenticated customer with SecurityContext
class CustomerProfilePage extends ConsumerStatefulWidget {
  const CustomerProfilePage({
    required this.securityContext,
    required this.client,
    super.key,
  });

  final SecurityContext securityContext;
  final Client client;

  @override
  ConsumerState<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends ConsumerState<CustomerProfilePage> {

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  bool _isEditing = false;
  bool _isSaving = false;
  bool _uploadingPhoto = false;
  String? _photoUrl;
  
  // Notification preferences (stored in client.preferences)
  late bool _emailNotifications;
  late bool _smsNotifications;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final client = widget.client;
    _firstNameController = TextEditingController(text: client.firstName);
    _lastNameController = TextEditingController(text: client.lastName);
    _emailController = TextEditingController(text: client.email ?? '');
    _phoneController = TextEditingController(text: client.phone ?? '');
    _addressController = TextEditingController(text: client.address ?? '');
    _photoUrl = client.preferences['profilePhotoUrl'] as String?;

    // Load preferences
    _emailNotifications =
        client.preferences['emailNotifications'] as bool? ?? true;
    _smsNotifications = client.preferences['smsNotifications'] as bool? ?? false;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Profile',
            )
          else ...[
            TextButton(
              onPressed: _cancelEditing,
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ],
      ),
      body: ListView(
        padding: AppSpacing.pagePadding,
        children: [
          // Profile Photo Section
          _buildProfilePhotoSection(),
          VSpace.lg,

          // Contact Information
          _buildSectionCard(
            title: 'Contact Information',
            children: [
              _buildTextField(
                controller: _firstNameController,
                label: 'First Name',
                icon: Icons.person_outline,
                enabled: _isEditing,
              ),
              VSpace.md,
              _buildTextField(
                controller: _lastNameController,
                label: 'Last Name',
                icon: Icons.person_outline,
                enabled: _isEditing,
              ),
              VSpace.md,
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                enabled: _isEditing,
                keyboardType: TextInputType.emailAddress,
              ),
              VSpace.md,
              _buildTextField(
                controller: _phoneController,
                label: 'Phone',
                icon: Icons.phone_outlined,
                enabled: _isEditing,
                keyboardType: TextInputType.phone,
              ),
              VSpace.md,
              _buildTextField(
                controller: _addressController,
                label: 'Address',
                icon: Icons.location_on_outlined,
                enabled: _isEditing,
                maxLines: 2,
              ),
            ],
          ),
          VSpace.md,

          // Notification Preferences
          _buildSectionCard(
            title: 'Notification Preferences',
            children: [
              SwitchListTile(
                value: _emailNotifications,
                onChanged: _isEditing
                    ? (value) => setState(() => _emailNotifications = value)
                    : null,
                title: const Text('Email Notifications'),
                subtitle: const Text('Receive appointment reminders via email'),
                secondary: const Icon(Icons.email_outlined),
              ),
              SwitchListTile(
                value: _smsNotifications,
                onChanged: _isEditing
                    ? (value) => setState(() => _smsNotifications = value)
                    : null,
                title: const Text('SMS Notifications'),
                subtitle: const Text('Receive appointment reminders via text'),
                secondary: const Icon(Icons.sms_outlined),
              ),
            ],
          ),
          VSpace.md,

          // Documents
          DocumentUploadCard(
            securityContext: widget.securityContext,
            client: widget.client,
          ),
          VSpace.md,

          // Account Actions
          _buildSectionCard(
            title: 'Account',
            children: [
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Change Password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _changePassword,
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                title: Text(
                  'Delete Account',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _deleteAccount,
              ),
            ],
          ),
          VSpace.md,

          // Sign Out Button
          FilledButton.tonalIcon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout_outlined),
            label: const Text('Sign Out'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          VSpace.xl,
        ],
      ),
    );
  }

  Widget _buildProfilePhotoSection() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage:
                _photoUrl != null ? NetworkImage(_photoUrl!) : null,
            child: _photoUrl == null
                ? Text(
                    widget.client.initials,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          if (_isEditing) ...[
            VSpace.sm,
            TextButton.icon(
              onPressed: _uploadingPhoto ? null : _uploadProfilePhoto,
              icon: const Icon(Icons.camera_alt_outlined),
              label: _uploadingPhoto
                  ? const Text('Uploading...')
                  : const Text('Change Photo'),
            ),
            if (_photoUrl != null)
              TextButton(
                onPressed: _uploadingPhoto ? null : _removeProfilePhoto,
                child: const Text('Remove Photo'),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          VSpace.md,
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: !enabled,
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      final updatedClient = widget.client.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        preferences: {
          ...widget.client.preferences,
          'emailNotifications': _emailNotifications,
          'smsNotifications': _smsNotifications,
        },
        updatedAt: DateTime.now(),
      );

      await ref.read(clientsRepositoryProvider).updateClient(
        context: widget.securityContext,
        client: updatedClient,
      );

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(SafeErrorHandler.handle(e))),
        );
      }
    }
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _initializeControllers();
    });
  }

  void _uploadProfilePhoto() {
    unawaited(_pickAndUploadProfilePhoto());
  }

  Future<void> _pickAndUploadProfilePhoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
        allowedExtensions: FileStorageService.allowedExtensions,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;

      setState(() => _uploadingPhoto = true);

      final storage = ref.read(fileStorageServiceProvider);
      final attachment = await storage.uploadClientFile(
        context: widget.securityContext,
        file: file,
        clientId: widget.client.id,
        category: FileCategory.identification,
        accessLevel: FileAccessLevel.clientOnly,
      );

      final updatedClient = widget.client.copyWith(
        preferences: {
          ...widget.client.preferences,
          'profilePhotoUrl': attachment.downloadUrl,
        },
        updatedAt: DateTime.now(),
      );

      await ref.read(clientsRepositoryProvider).updateClient(
        context: widget.securityContext,
        client: updatedClient,
      );

      if (!mounted) return;
      setState(() {
        _photoUrl = attachment.downloadUrl;
        _uploadingPhoto = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(SafeErrorHandler.handle(e))),
      );
    }
  }

  Future<void> _removeProfilePhoto() async {
    try {
      setState(() => _uploadingPhoto = true);

      final updatedPrefs = Map<String, dynamic>.from(widget.client.preferences)
        ..remove('profilePhotoUrl');

      final updatedClient = widget.client.copyWith(
        preferences: updatedPrefs,
        updatedAt: DateTime.now(),
      );

      await ref.read(clientsRepositoryProvider).updateClient(
        context: widget.securityContext,
        client: updatedClient,
      );

      if (!mounted) return;
      setState(() {
        _photoUrl = null;
        _uploadingPhoto = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo removed')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(SafeErrorHandler.handle(e))),
      );
    }
  }

  Future<void> _changePassword() async {
    final newPassword = await showDialog<String>(
      context: context,
      builder: (context) => _ChangePasswordDialog(),
    );

    if (newPassword != null && mounted) {
      try {
        await ref.read(customerAuthServiceProvider).updatePassword(newPassword: newPassword);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(SafeErrorHandler.handle(e))),
          );
        }
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This will permanently delete your account and all associated data. '
          'This action cannot be undone.\n\n'
          'Your appointment history will be retained for business records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(customerAuthServiceProvider).deleteAccount(
          businessId: widget.securityContext.businessId,
        );

        if (mounted) {
          // Navigate to login/home
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(SafeErrorHandler.handle(e))),
          );
        }
      }
    }
  }

  Future<void> _signOut() async {
    await ref.read(customerAuthServiceProvider).signOut();
    if (mounted) {
      // Navigate to login/home
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}

/// Change password dialog
class _ChangePasswordDialog extends StatefulWidget {
  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Password'),
      content: FormFieldGroup(
        children: [
          TextField(
            controller: _newPasswordController,
            obscureText: _obscureNew,
            decoration: InputDecoration(
              labelText: 'New Password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
          ),
          TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _savePassword,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _savePassword() {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a password')),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    Navigator.pop(context, newPassword);
  }
}
