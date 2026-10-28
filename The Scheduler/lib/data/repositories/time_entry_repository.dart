import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/demo_guard_service.dart';
import '../models/audit_log.dart';
import '../models/security_context.dart';
import '../models/time_entry.dart';
import 'audit_log_repository.dart';

/// Repository for managing time entries with multi-tenant isolation and RBAC.
///
/// Staff can view/manage their own time entries.
/// Managers/admins can view/manage all time entries in their business.
///
/// Time entries are stored at:
/// `businesses/{businessId}/timeEntries/{timeEntryId}`
///
/// PHI Access Logging: All read operations are audit logged per HIPAA
/// requirements for labor/payroll data access.
class TimeEntryRepository {
  TimeEntryRepository({
    FirebaseFirestore? firestore,
    AuditLogRepository? auditLogRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  final FirebaseFirestore _firestore;
  final AuditLogRepository _auditLogRepository;

  // ---------------------------------------------------------------------------
  // CRUD Operations
  // ---------------------------------------------------------------------------

  /// Watch time entries with optional filters.
  ///
  /// Audit: Logs one `phiReadList` event on first emission.
  Stream<List<TimeEntry>> watchTimeEntries({
    required SecurityContext context,
    String? staffId,
    DateTime? startDate,
    DateTime? endDate,
    TimeEntryStatus? status,
    List<TimeEntryStatus>? statuses,
    int limit = 100,
  }) {
    if (status != null && statuses != null) {
      throw ArgumentError('Provide either status or statuses, not both.');
    }

    Query<Map<String, dynamic>> query = _timeEntriesCollection(
      context.businessId,
    );

    // Filter by staff ID
    if (staffId != null) {
      _verifyStaffAccess(context, staffId);
      query = query.where('staffId', isEqualTo: staffId);
    } else if (context.providerId != null &&
        !context.role.canManageAllAppointments) {
      // Staff can only see their own entries
      query = query.where('staffId', isEqualTo: context.providerId);
    }

    // Filter by date range
    if (startDate != null) {
      query = query.where(
        'clockInTime',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }
    if (endDate != null) {
      query = query.where(
        'clockInTime',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }

    // Filter by status
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    } else if (statuses != null && statuses.isNotEmpty) {
      query = query.where(
        'status',
        whereIn: statuses.map((s) => s.name).toList(),
      );
    }

    query = query.orderBy('clockInTime', descending: true).limit(limit);

    return _withAuditLogOnFirstEmission(
      stream: query.snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => _mapTimeEntryDoc(doc, context.businessId))
            .toList(),
      ),
      context: context,
      entityType: 'TimeEntry',
      metadata: {
        'source': 'watchTimeEntries',
        'mode': 'list',
        'staffId': staffId,
      },
    );
  }

  /// Get a single time entry by ID.
  ///
  /// Audit: Logs one `phiRead` event when entry is retrieved.
  Future<TimeEntry?> getTimeEntry({
    required SecurityContext context,
    required String timeEntryId,
  }) async {
    final doc = await _timeEntriesCollection(
      context.businessId,
    ).doc(timeEntryId).get();

    if (!doc.exists) return null;

    final entry = _mapTimeEntryDoc(doc, context.businessId);

    // Verify access
    _verifyStaffAccess(context, entry.staffId);

    // Log PHI read access
    unawaited(
      _auditLogRepository.logEvent(
        AuditLogEntry(
          businessId: context.businessId,
          userId: context.userId,
          actionType: AuditActionType.phiRead,
          entityType: 'TimeEntry',
          entityId: timeEntryId,
          metadata: {'source': 'getTimeEntry'},
        ),
      ),
    );

    return entry;
  }

  /// Get the active (currently clocked in) entry for a staff member.
  Future<TimeEntry?> getActiveEntry({
    required SecurityContext context,
    required String staffId,
  }) async {
    _verifyStaffAccess(context, staffId);

    final snapshot = await _timeEntriesCollection(context.businessId)
        .where('staffId', isEqualTo: staffId)
        .where('status', isEqualTo: TimeEntryStatus.active.name)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return _mapTimeEntryDoc(snapshot.docs.first, context.businessId);
  }

  /// Create a new time entry.
  Future<void> createTimeEntry({
    required SecurityContext context,
    required TimeEntry entry,
  }) async {
    DemoGuardService.assertReadOnly('create time entry');
    // Staff can only create entries for themselves
    if (context.providerId != null &&
        !context.role.canManageAllAppointments &&
        context.providerId != entry.staffId) {
      throw SecurityException('Staff can only create entries for themselves');
    }

    await _timeEntriesCollection(
      context.businessId,
    ).doc(entry.id).set(entry.toJson());
  }

  /// Update an existing time entry.
  Future<void> updateTimeEntry({
    required SecurityContext context,
    required TimeEntry entry,
  }) async {
    DemoGuardService.assertReadOnly('update time entry');
    // Verify the entry exists and user has access
    final existing = await getTimeEntry(
      context: context,
      timeEntryId: entry.id,
    );

    if (existing == null) {
      throw SecurityException('Time entry not found');
    }

    // Staff can only update their own non-approved entries
    if (context.providerId != null && !context.role.canManageAllAppointments) {
      if (context.providerId != entry.staffId) {
        throw SecurityException('Staff can only update their own entries');
      }
      if (existing.status == TimeEntryStatus.approved) {
        throw SecurityException('Cannot modify approved entries');
      }
    }

    await _timeEntriesCollection(
      context.businessId,
    ).doc(entry.id).update(entry.toJson());
  }

  /// Delete a time entry.
  /// Only admins can delete entries.
  Future<void> deleteTimeEntry({
    required SecurityContext context,
    required String timeEntryId,
  }) async {
    DemoGuardService.assertReadOnly('delete time entry');
    if (!context.role.canManageAllAppointments) {
      throw SecurityException('Only administrators can delete time entries');
    }

    await _timeEntriesCollection(context.businessId).doc(timeEntryId).delete();
  }

  // ---------------------------------------------------------------------------
  // Query Methods
  // ---------------------------------------------------------------------------

  /// Get entries for a staff member within a date range.
  ///
  /// Audit: Logs one `phiReadList` event when entries are retrieved.
  Future<List<TimeEntry>> getEntriesByStaff({
    required SecurityContext context,
    required String staffId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _verifyStaffAccess(context, staffId);

    final snapshot = await _timeEntriesCollection(context.businessId)
        .where('staffId', isEqualTo: staffId)
        .where(
          'clockInTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where('clockInTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('clockInTime', descending: true)
        .get();

    final entries = snapshot.docs
        .map((doc) => _mapTimeEntryDoc(doc, context.businessId))
        .toList();

    // Log PHI read list access
    unawaited(
      _auditLogRepository.logEvent(
        AuditLogEntry(
          businessId: context.businessId,
          userId: context.userId,
          actionType: AuditActionType.phiReadList,
          entityType: 'TimeEntry',
          entityId: context.businessId,
          metadata: {
            'source': 'getEntriesByStaff',
            'staffId': staffId,
            'count': entries.length,
          },
        ),
      ),
    );

    return entries;
  }

  /// Get all entries pending approval.
  ///
  /// Only admins/managers can access this.
  ///
  /// Audit: Logs one `phiReadList` event when entries are retrieved.
  Future<List<TimeEntry>> getEntriesPendingApproval({
    required SecurityContext context,
    int limit = 100,
  }) async {
    if (!context.role.canManageAllAppointments) {
      throw SecurityException('Only administrators can view pending approvals');
    }

    final snapshot = await _timeEntriesCollection(context.businessId)
        .where('status', isEqualTo: TimeEntryStatus.pending.name)
        .orderBy('clockInTime', descending: true)
        .limit(limit)
        .get();

    final entries = snapshot.docs
        .map((doc) => _mapTimeEntryDoc(doc, context.businessId))
        .toList();

    // Log PHI read list access
    unawaited(
      _auditLogRepository.logEvent(
        AuditLogEntry(
          businessId: context.businessId,
          userId: context.userId,
          actionType: AuditActionType.phiReadList,
          entityType: 'TimeEntry',
          entityId: context.businessId,
          metadata: {
            'source': 'getEntriesPendingApproval',
            'count': entries.length,
          },
        ),
      ),
    );

    return entries;
  }

  /// Get all entries for a specific date (any staff member).
  /// Only admins/managers can access this.
  Future<List<TimeEntry>> getEntriesForDate({
    required SecurityContext context,
    required DateTime date,
  }) async {
    if (!context.role.canManageAllAppointments) {
      throw SecurityException('Only administrators can view all entries');
    }

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    final snapshot = await _timeEntriesCollection(context.businessId)
        .where(
          'clockInTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('clockInTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('clockInTime')
        .get();

    return snapshot.docs
        .map((doc) => _mapTimeEntryDoc(doc, context.businessId))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Approval Methods
  // ---------------------------------------------------------------------------

  /// Approve a time entry.
  /// Only admins/managers can approve entries.
  Future<void> approveTimeEntry({
    required SecurityContext context,
    required String timeEntryId,
    String? managerNotes,
  }) async {
    DemoGuardService.assertReadOnly('approve time entry');
    if (!context.role.canManageAllAppointments) {
      throw SecurityException('Only administrators can approve time entries');
    }

    final entry = await getTimeEntry(
      context: context,
      timeEntryId: timeEntryId,
    );
    if (entry == null) {
      throw SecurityException('Time entry not found');
    }

    if (entry.status != TimeEntryStatus.pending) {
      throw SecurityException('Only pending entries can be approved');
    }

    await _timeEntriesCollection(context.businessId).doc(timeEntryId).update({
      'status': TimeEntryStatus.approved.name,
      'approvedByUserId': context.userId,
      'approvedAt': FieldValue.serverTimestamp(),
      if (managerNotes != null) 'managerNotes': managerNotes,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Log approval action
    unawaited(
      _auditLogRepository.logEvent(
        AuditLogEntry(
          businessId: context.businessId,
          userId: context.userId,
          actionType: AuditActionType.phiWrite,
          entityType: 'TimeEntry',
          entityId: timeEntryId,
          metadata: {'action': 'approve', 'staffId': entry.staffId},
        ),
      ),
    );
  }

  /// Reject a time entry with a reason.
  /// Only admins/managers can reject entries.
  Future<void> rejectTimeEntry({
    required SecurityContext context,
    required String timeEntryId,
    required String reason,
    String? managerNotes,
  }) async {
    DemoGuardService.assertReadOnly('reject time entry');
    if (!context.role.canManageAllAppointments) {
      throw SecurityException('Only administrators can reject time entries');
    }

    if (reason.isEmpty) {
      throw ArgumentError('Rejection reason is required');
    }

    final entry = await getTimeEntry(
      context: context,
      timeEntryId: timeEntryId,
    );
    if (entry == null) {
      throw SecurityException('Time entry not found');
    }

    if (entry.status != TimeEntryStatus.pending) {
      throw SecurityException('Only pending entries can be rejected');
    }

    await _timeEntriesCollection(context.businessId).doc(timeEntryId).update({
      'status': TimeEntryStatus.rejected.name,
      'approvedByUserId': context.userId,
      'approvedAt': FieldValue.serverTimestamp(),
      'rejectionReason': reason,
      if (managerNotes != null) 'managerNotes': managerNotes,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Log rejection action
    unawaited(
      _auditLogRepository.logEvent(
        AuditLogEntry(
          businessId: context.businessId,
          userId: context.userId,
          actionType: AuditActionType.phiWrite,
          entityType: 'TimeEntry',
          entityId: timeEntryId,
          metadata: {
            'action': 'reject',
            'staffId': entry.staffId,
            'reason': reason,
          },
        ),
      ),
    );
  }

  /// Bulk approve multiple time entries.
  Future<int> bulkApproveTimeEntries({
    required SecurityContext context,
    required List<String> timeEntryIds,
    String? managerNotes,
  }) async {
    DemoGuardService.assertReadOnly('approve time entries');
    if (!context.role.canManageAllAppointments) {
      throw SecurityException('Only administrators can approve time entries');
    }

    int approvedCount = 0;
    final batch = _firestore.batch();

    for (final id in timeEntryIds) {
      final ref = _timeEntriesCollection(context.businessId).doc(id);
      batch.update(ref, {
        'status': TimeEntryStatus.approved.name,
        'approvedByUserId': context.userId,
        'approvedAt': FieldValue.serverTimestamp(),
        if (managerNotes != null) 'managerNotes': managerNotes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      approvedCount++;
    }

    await batch.commit();

    // Log bulk approval
    unawaited(
      _auditLogRepository.logEvent(
        AuditLogEntry(
          businessId: context.businessId,
          userId: context.userId,
          actionType: AuditActionType.phiWrite,
          entityType: 'TimeEntry',
          entityId: context.businessId,
          metadata: {'action': 'bulkApprove', 'count': approvedCount},
        ),
      ),
    );

    return approvedCount;
  }

  // ---------------------------------------------------------------------------
  // Private Helpers
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _timeEntriesCollection(
    String businessId,
  ) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('timeEntries');
  }

  TimeEntry _mapTimeEntryDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String businessId,
  ) {
    final data = doc.data() ?? {};
    return TimeEntry.fromJson({
      'id': doc.id,
      'businessId': businessId,
      ...data,
    });
  }

  void _verifyStaffAccess(SecurityContext context, String staffId) {
    if (!context.role.canManageAllAppointments) {
      if (context.providerId != null && context.providerId != staffId) {
        throw SecurityException('Cannot access other staff\'s time entries');
      }
    }
  }

  /// Wraps a stream to log one audit event on first emission.
  Stream<List<T>> _withAuditLogOnFirstEmission<T>({
    required Stream<List<T>> stream,
    required SecurityContext context,
    required String entityType,
    required Map<String, dynamic> metadata,
  }) {
    var hasLogged = false;
    return stream.map((data) {
      if (!hasLogged) {
        hasLogged = true;
        unawaited(
          _auditLogRepository.logEvent(
            AuditLogEntry(
              businessId: context.businessId,
              userId: context.userId,
              actionType: AuditActionType.phiReadList,
              entityType: entityType,
              entityId: context.businessId,
              metadata: {...metadata, 'count': data.length},
            ),
          ),
        );
      }
      return data;
    });
  }
}
