import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/widgets/role_guard.dart';
import '../../../data/models/user_role.dart';
import '../../../data/models/staff_member.dart';
import '../../../data/models/staff_invite.dart';
import '../providers/staff_management_providers.dart';
import 'widgets/edit_staff_dialog.dart';
import 'widgets/invite_staff_dialog.dart';
import 'widgets/pending_invite_card.dart';
import 'widgets/staff_card.dart';

class StaffManagementPage extends ConsumerStatefulWidget {
  const StaffManagementPage({super.key});

  @override
  ConsumerState<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends ConsumerState<StaffManagementPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(filteredStaffProvider);
    final invitesAsync = ref.watch(pendingInvitesProvider);

    return RoleGuard(
      allowedRoles: const [UserRole.owner, UserRole.admin],
      fallback: const Scaffold(
        body: Center(child: Text('Only administrators can manage staff.')),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Team Management'),
          actions: [
            TextButton.icon(
              onPressed: () => _showInviteDialog(context),
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: const Text('Invite Staff'),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildFilters(),
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildStaffList(staff),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _buildInvites(invitesAsync),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search by name or email',
          ),
          onChanged: (value) =>
              ref.read(staffSearchProvider.notifier).state = value,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _FilterChip(
              label: 'All',
              selected: ref.watch(staffFilterProvider) == StaffFilter.all,
              onSelected: () =>
                  ref.read(staffFilterProvider.notifier).state = StaffFilter.all,
            ),
            _FilterChip(
              label: 'Active',
              selected:
                  ref.watch(staffFilterProvider).status == StaffStatus.active,
              onSelected: () => ref
                  .read(staffFilterProvider.notifier)
                  .state = StaffFilter.active,
            ),
            _FilterChip(
              label: 'Pending',
              selected:
                  ref.watch(staffFilterProvider).status == StaffStatus.pending,
              onSelected: () => ref
                  .read(staffFilterProvider.notifier)
                  .state = StaffFilter.pending,
            ),
            _FilterChip(
              label: 'Deactivated',
              selected: ref.watch(staffFilterProvider).status ==
                  StaffStatus.deactivated,
              onSelected: () => ref
                  .read(staffFilterProvider.notifier)
                  .state = StaffFilter.deactivated,
            ),
            for (final role in const [
              UserRole.admin,
              UserRole.manager,
              UserRole.sales,
              UserRole.provider,
              UserRole.frontDesk,
            ])
              _FilterChip(
                label: _roleLabel(role),
                selected: ref.watch(staffFilterProvider).role == role,
                onSelected: () => ref
                    .read(staffFilterProvider.notifier)
                    .state = StaffFilter.forRole(role),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStaffList(List<StaffMember> staff) {
    if (staff.isEmpty) {
      return const Center(
        child: Text('No staff found. Invite your first team member.'),
      );
    }

    return ListView.builder(
      itemCount: staff.length,
      itemBuilder: (context, index) {
        final member = staff[index];
        return StaffCard(
          member: member,
          onEdit: () => _showEditDialog(member),
          onDeactivate:
              member.isDeactivated ? null : () => _handleDeactivate(member),
          onReactivate:
              member.isDeactivated ? () => _handleReactivate(member) : null,
          onViewActivity: () {
            // Placeholder: hook to audit log view
          },
        );
      },
    );
  }

  Widget _buildInvites(AsyncValue<List<StaffInvite>> invitesAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: invitesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => const Text('Unable to load invites'),
          data: (invites) {
            if (invites.isEmpty) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No pending invites'),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => _showInviteDialog(context),
                    icon: const Icon(Icons.person_add_alt),
                    label: const Text('Invite Staff'),
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pending Invites',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...invites.map(
                  (invite) => PendingInviteCard(
                    invite: invite,
                    onCopyCode: null, // Plaintext code only available at creation
                    onCopyLink: null,
                    onRevoke: () => _handleRevoke(invite),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showInviteDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => const InviteStaffDialog(),
    );
  }

  Future<void> _showEditDialog(StaffMember member) async {
    await showDialog(
      context: context,
      builder: (_) => EditStaffDialog(member: member),
    );
  }

  Future<void> _handleDeactivate(StaffMember member) async {
    final confirmed = await _confirm(
      'Deactivate ${member.displayName.isNotEmpty ? member.displayName : member.email}?',
    );
    if (!confirmed) return;
    final ctx = ref.read(securityContextProvider).valueOrNull;
    if (ctx == null) return;
    try {
      await ref.read(staffRepositoryProvider).deactivateStaff(ctx, member.id);
    } catch (_) {
      _showError('Failed to deactivate staff');
    }
  }

  Future<void> _handleReactivate(StaffMember member) async {
    final ctx = ref.read(securityContextProvider).valueOrNull;
    if (ctx == null) return;
    try {
      await ref.read(staffRepositoryProvider).reactivateStaff(ctx, member.id);
    } catch (_) {
      _showError('Failed to reactivate staff');
    }
  }

  Future<void> _handleRevoke(StaffInvite invite) async {
    final confirmed = await _confirm('Revoke this invite?');
    if (!confirmed) return;
    final ctx = ref.read(securityContextProvider).valueOrNull;
    if (ctx == null) return;
    try {
      await ref.read(inviteRepositoryProvider).revokeInvite(ctx, invite.id);
    } catch (_) {
      _showError('Failed to revoke invite');
    }
  }

  Future<bool> _confirm(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.admin:
        return 'Admin';
      case UserRole.manager:
        return 'Manager';
      case UserRole.sales:
        return 'Sales';
      case UserRole.provider:
      case UserRole.staff:
        return 'Provider';
      case UserRole.frontDesk:
        return 'Front Desk';
      case UserRole.client:
        return 'Client';
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}
