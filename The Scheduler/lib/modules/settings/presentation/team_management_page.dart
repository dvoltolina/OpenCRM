import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import 'widgets/approvals_tab.dart';
import 'widgets/create_join_code_dialog.dart';
import 'widgets/create_invite_dialog.dart';
import 'widgets/invites_tab.dart';
import 'widgets/join_codes_tab.dart';

// TODO(RW1): Uncomment when models are available
// import '../../../data/models/join_code.dart';
// import '../../../data/models/invite.dart';
// import '../../../data/models/join_request.dart';

// TODO(RW2): Uncomment when repository is available
// import '../../../data/repositories/staff_onboarding_repository.dart';
// import '../../../core/providers/repository_providers.dart';

// ============================================================
// Stream Providers for Staff Onboarding Data
// ============================================================

// TODO(RW2): Uncomment when repository is available
/*
final staffOnboardingRepositoryProvider = Provider<StaffOnboardingRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auditLog = ref.watch(auditLogRepositoryProvider);
  return StaffOnboardingRepository(
    firestore: firestore,
    auditLogRepository: auditLog,
  );
});

final joinCodesStreamProvider = StreamProvider.autoDispose<List<JoinCode>>((ref) {
  final context = ref.watch(currentSecurityContextProvider);
  if (context == null) {
    return Stream.value([]);
  }
  final repo = ref.watch(staffOnboardingRepositoryProvider);
  return repo.watchJoinCodes(context);
});

final invitesStreamProvider = StreamProvider.autoDispose<List<Invite>>((ref) {
  final context = ref.watch(currentSecurityContextProvider);
  if (context == null) {
    return Stream.value([]);
  }
  final repo = ref.watch(staffOnboardingRepositoryProvider);
  return repo.watchInvites(context);
});

final pendingRequestsStreamProvider = StreamProvider.autoDispose<List<JoinRequest>>((ref) {
  final context = ref.watch(currentSecurityContextProvider);
  if (context == null) {
    return Stream.value([]);
  }
  final repo = ref.watch(staffOnboardingRepositoryProvider);
  return repo.watchPendingRequests(context);
});
*/

/// Admin page for managing team onboarding (join codes, invites, approval requests).
///
/// Features:
/// - Tabbed interface for Join Codes, Invites, and Pending Approvals
/// - Create join codes with role/expiry/max uses configuration
/// - Create email-specific invites
/// - Approve/deny join requests
/// - Revoke codes/invites
/// - Copy join code/link to clipboard
class TeamManagementPage extends ConsumerStatefulWidget {
  const TeamManagementPage({super.key});

  @override
  ConsumerState<TeamManagementPage> createState() => _TeamManagementPageState();
}

class _TeamManagementPageState extends ConsumerState<TeamManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final securityContextAsync = ref.watch(securityContextProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Management'),
        centerTitle: false,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Join Codes', icon: Icon(Icons.qr_code_2)),
            Tab(text: 'Invites', icon: Icon(Icons.mail_outline)),
            Tab(text: 'Approvals', icon: Icon(Icons.pending_actions)),
          ],
        ),
      ),
      body: securityContextAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const Center(child: Text('Failed to load security context')),
        data: (securityContext) {
          if (securityContext == null) {
            return const Center(child: Text('Authentication required.'));
          }
          return TabBarView(
            controller: _tabController,
            children: [
              JoinCodesTab(
                securityContext: securityContext,
                onCreateCode: () => _showCreateJoinCodeDialog(context),
              ),
              InvitesTab(
                securityContext: securityContext,
                onSendInvite: () => _showCreateInviteDialog(context),
              ),
              ApprovalsTab(securityContext: securityContext),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showCreateJoinCodeDialog(context);
          } else if (_tabController.index == 1) {
            _showCreateInviteDialog(context);
          }
        },
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'Create Code' : 'Send Invite'),
      ),
    );
  }

  void _showCreateJoinCodeDialog(BuildContext context) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => const CreateJoinCodeDialog(),
    );

    // Refresh list if code was created successfully
    // TODO(RW2): Uncomment when repository is available
    // if (result == true && mounted) {
    //   ref.invalidate(joinCodesStreamProvider);
    // }
  }

  void _showCreateInviteDialog(BuildContext context) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => const CreateInviteDialog(),
    );

    // Refresh list if invite was created successfully
    // TODO(RW2): Uncomment when repository is available
    // if (result == true && mounted) {
    //   ref.invalidate(invitesStreamProvider);
    // }
  }

  // TODO(RW2): Uncomment when repository is available
  /*
  /// Copies the join code to clipboard.
  /// Note: Plaintext codes are only available at creation time.
  Future<void> _copyCodeToClipboard(BuildContext context, JoinCode code) async {
    // Join codes store only codeHash, not plaintext
    // The plaintext code is only shown once at creation time
    // For existing codes, we can only show a partial identifier
    final codeIdentifier = '••••${code.codeHash.substring(code.codeHash.length - 4)}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Code identifier: $codeIdentifier (full code shown at creation only)'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // These methods call repository when implemented
  Future<void> _revokeJoinCode(
    BuildContext context,
    SecurityContext securityContext,
    JoinCode code,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Join Code'),
        content: const Text('This code will no longer be usable. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final repo = ref.read(staffOnboardingRepositoryProvider);
      await repo.revokeJoinCode(
        context: securityContext,
        codeId: code.id,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Join code revoked')),
        );
      }
    } catch (e, stackTrace) {
      final userMessage = SafeErrorHandler.handle(
        e,
        context: 'Revoking join code',
        stackTrace: stackTrace,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userMessage)),
        );
      }
    }
  }

  Future<void> _revokeInvite(
    BuildContext context,
    SecurityContext securityContext,
    Invite invite,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Invite'),
        content: Text('Revoke invite for ${invite.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final repo = ref.read(staffOnboardingRepositoryProvider);
      await repo.revokeInvite(
        context: securityContext,
        inviteId: invite.id,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invite revoked')),
        );
      }
    } catch (e, stackTrace) {
      final userMessage = SafeErrorHandler.handle(
        e,
        context: 'Revoking invite',
        stackTrace: stackTrace,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userMessage)),
        );
      }
    }
  }

  Future<void> _approveJoinRequest(
    BuildContext context,
    SecurityContext securityContext,
    JoinRequest request,
  ) async {
    try {
      final repo = ref.read(staffOnboardingRepositoryProvider);
      await repo.reviewJoinRequest(
        context: securityContext,
        requestId: request.id,
        approve: true,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${request.requestorDisplayName ?? request.requestorEmail} approved'),
          ),
        );
      }
    } catch (e, stackTrace) {
      final userMessage = SafeErrorHandler.handle(
        e,
        context: 'Approving join request',
        stackTrace: stackTrace,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userMessage)),
        );
      }
    }
  }

  Future<void> _denyJoinRequest(
    BuildContext context,
    SecurityContext securityContext,
    JoinRequest request,
  ) async {
    final theme = Theme.of(context);
    // Optional: Ask for denial reason
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deny Join Request'),
        content: Text('Deny request from ${request.requestorDisplayName ?? request.requestorEmail}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: const Text('Deny'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final repo = ref.read(staffOnboardingRepositoryProvider);
      await repo.reviewJoinRequest(
        context: securityContext,
        requestId: request.id,
        approve: false,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Join request denied')),
        );
      }
    } catch (e, stackTrace) {
      final userMessage = SafeErrorHandler.handle(
        e,
        context: 'Denying join request',
        stackTrace: stackTrace,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userMessage)),
        );
      }
    }
  }
  */
}
