import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../auth/presentation/portal_selection_page.dart';
import '../services/emergency_actions_service.dart';
import '../utils/web_links.dart';
import 'widgets/emergency_dialogs.dart';

/// Admin settings page - account, business settings, and emergency actions.
///
/// Provides access to limited mobile settings. For full configuration,
/// links to web dashboard.
///
/// HIPAA: Emergency actions are audit logged.
class AdminSettingsPage extends ConsumerStatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  ConsumerState<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends ConsumerState<AdminSettingsPage> {
  bool _dangerZoneExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final securityContext = ref.watch(securityContextProvider).valueOrNull;

    if (securityContext == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Account section
          _SectionHeader(title: 'Account'),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            subtitle: Text(securityContext.userFullName ?? 'No name'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to profile page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile - coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change Password'),
            subtitle: const Text('Manage on web dashboard'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => AdminWebLinks.openSettings(securityContext.businessId),
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Two-Factor Authentication'),
            subtitle: const Text('Manage on web dashboard'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => AdminWebLinks.openSettings(securityContext.businessId),
          ),

          const Divider(),

          // Business section
          _SectionHeader(title: 'Business Settings'),
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text('Business Information'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => AdminWebLinks.openSettings(securityContext.businessId),
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Business Hours'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to business hours editor
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Business hours - coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.event_busy),
            title: const Text('Holiday Closures'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to holiday closures
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Holiday closures - coming soon')),
              );
            },
          ),

          const Divider(),

          // Mobile settings
          _SectionHeader(title: 'Mobile Settings'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive important updates'),
            value: true, // TODO: Connect to actual setting
            onChanged: (value) {
              // TODO: Update notification setting
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification settings - coming soon')),
              );
            },
          ),

          const Divider(),

          // Links
          _SectionHeader(title: 'More'),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Full Settings (Web)'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => AdminWebLinks.openSettings(securityContext.businessId),
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Open support page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Support - coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms & Privacy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Open terms page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Terms & Privacy - coming soon')),
              );
            },
          ),

          const Divider(),

          // Sign out
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () => _handleSignOut(context),
          ),

          const Divider(),

          // Danger zone (collapsible)
          ExpansionTile(
            leading: Icon(Icons.warning, color: theme.colorScheme.error),
            title: Text(
              'Emergency Actions',
              style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold),
            ),
            initiallyExpanded: _dangerZoneExpanded,
            onExpansionChanged: (expanded) {
              setState(() => _dangerZoneExpanded = expanded);
            },
            children: [
              Container(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.block, color: theme.colorScheme.error),
                      title: Text(
                        'Disable Online Booking',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                      subtitle: const Text('Prevent new bookings (emergency)'),
                      onTap: () => _handleDisableBooking(context, securityContext),
                    ),
                    ListTile(
                      leading: Icon(Icons.lock_person, color: theme.colorScheme.error),
                      title: Text(
                        'Force Sign Out All Staff',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                      subtitle: const Text('Revoke all active sessions (emergency)'),
                      onTap: () => _handleForceSignOut(context, securityContext),
                    ),
                    ListTile(
                      leading: Icon(Icons.campaign, color: theme.colorScheme.error),
                      title: Text(
                        'Send Emergency Announcement',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                      subtitle: const Text('Notify all staff immediately'),
                      onTap: () => _handleEmergencyAnnouncement(context, securityContext),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    await ref.read(authStateServiceProvider).signOut();

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PortalSelectionPage()),
        (route) => false,
      );
    }
  }

  Future<void> _handleDisableBooking(BuildContext context, securityContext) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const DisableBookingDialog(),
    );

    if (result == null) return;
    if (!context.mounted) return;

    try {
      final service = EmergencyActionsService(
        firestore: ref.read(firestoreProvider),
        auditLogRepository: ref.read(auditLogRepositoryProvider),
      );

      await service.disableBooking(
        securityContext,
        reason: result['reason'] as String,
        until: result['until'] as DateTime?,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Online booking disabled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      // HIPAA: Generic error message - no exception details exposed
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Operation failed. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleForceSignOut(BuildContext context, securityContext) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => const EmergencyReasonDialog(
        title: 'Force Sign Out All Staff',
        description: 'This will revoke all active staff sessions. '
            'They will need to sign in again. Please provide a reason:',
      ),
    );

    if (reason == null || reason.isEmpty) return;
    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Emergency Action'),
        content: const Text(
          'This will force sign out ALL staff members. '
          'Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      final service = EmergencyActionsService(
        firestore: ref.read(firestoreProvider),
        auditLogRepository: ref.read(auditLogRepositoryProvider),
      );

      await service.forceSignOutAllStaff(securityContext, reason: reason);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All staff signed out'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      // HIPAA: Generic error message - no exception details exposed
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Operation failed. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleEmergencyAnnouncement(BuildContext context, securityContext) async {
    final message = await showDialog<String>(
      context: context,
      builder: (context) => const EmergencyAnnouncementDialog(),
    );

    if (message == null || message.isEmpty) return;
    if (!context.mounted) return;

    try {
      final service = EmergencyActionsService(
        firestore: ref.read(firestoreProvider),
        auditLogRepository: ref.read(auditLogRepositoryProvider),
      );

      await service.sendEmergencyAnnouncement(securityContext, message: message);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency announcement sent to all staff'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      // HIPAA: Generic error message - no exception details exposed
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Operation failed. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
