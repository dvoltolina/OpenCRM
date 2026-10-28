import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../data/models/staff_invite.dart';
import '../../../data/models/staff_member.dart';
import '../../../data/models/user_role.dart';

class StaffFilter {
  const StaffFilter({this.role, this.status});

  final UserRole? role;
  final StaffStatus? status;

  static const all = StaffFilter();
  static const active = StaffFilter(status: StaffStatus.active);
  static const pending = StaffFilter(status: StaffStatus.pending);
  static const deactivated = StaffFilter(status: StaffStatus.deactivated);

  static StaffFilter forRole(UserRole role) => StaffFilter(role: role);
}

/// All staff members for the current business.
final staffMembersProvider =
    StreamProvider.autoDispose<List<StaffMember>>((ref) {
  final context = ref.watch(securityContextProvider).valueOrNull;
  if (context == null) return const Stream.empty();

  final repo = ref.watch(staffRepositoryProvider);
  return repo.watchStaffMembers(context);
});

/// Pending invites for current business.
final pendingInvitesProvider =
    StreamProvider.autoDispose<List<StaffInvite>>((ref) {
  final context = ref.watch(securityContextProvider).valueOrNull;
  if (context == null) return const Stream.empty();

  final repo = ref.watch(inviteRepositoryProvider);
  return repo.watchPendingInvites(context);
});

/// Staff filter state (role/status).
final staffFilterProvider =
    StateProvider<StaffFilter>((ref) => StaffFilter.all);

/// Staff search query.
final staffSearchProvider = StateProvider<String>((ref) => '');

/// Filtered staff list.
final filteredStaffProvider = Provider<List<StaffMember>>((ref) {
  final staff =
      ref.watch(staffMembersProvider).valueOrNull ?? const <StaffMember>[];
  final filter = ref.watch(staffFilterProvider);
  final search = ref.watch(staffSearchProvider).toLowerCase();

  var filtered = staff;

  if (filter.role != null) {
    filtered = filtered.where((s) => s.role == filter.role).toList();
  }
  if (filter.status != null) {
    filtered = filtered.where((s) => s.status == filter.status).toList();
  }
  if (search.isNotEmpty) {
    filtered = filtered.where((s) {
      return s.displayName.toLowerCase().contains(search) ||
          s.email.toLowerCase().contains(search);
    }).toList();
  }

  filtered.sort((a, b) => a.displayName.compareTo(b.displayName));
  return filtered;
});
