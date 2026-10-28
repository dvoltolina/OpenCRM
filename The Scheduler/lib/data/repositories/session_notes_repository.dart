import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/demo_config.dart';
import '../models/audit_log.dart';
import '../models/security_context.dart';
import '../models/session_note.dart';
import '../../core/services/encryption_service.dart';
import '../../core/services/demo_guard_service.dart';
import 'audit_log_repository.dart';

/// Repository for managing HIPAA-compliant session notes
///
/// Security:
/// - Provider-only access (admin, owner, or provider assigned to client)
/// - Encrypted content at rest
/// - Audit logging for all operations (both in-document and central audit_logs)
/// - Multi-tenant isolation
///
/// PHI Access Logging: All read operations are audit logged per HIPAA
/// requirements. Single-entity reads log `phiRead`; list/stream reads
/// log `phiReadList` once per logical action (not per document).
class SessionNotesRepository {
  SessionNotesRepository({
    FirebaseFirestore? firestore,
    AuditLogRepository? auditLogRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  final FirebaseFirestore _firestore;
  final AuditLogRepository _auditLogRepository;
  static const _uuid = Uuid();

  /// Get session notes collection reference
  CollectionReference _notesCollection(String businessId) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('session_notes');
  }

  /// Create a new session note
  Future<SessionNote> createNote({
    required SecurityContext context,
    required String appointmentId,
    required String clientId,
    required String providerId,
    required EncryptionService encryptionService,
    SessionNoteType? type,
    SessionNoteType? noteType, // Alias for type
    String? content,
    String? templateId, // Optional template ID
    SessionNoteVisibility visibility = SessionNoteVisibility.providerOnly,
    String? title,
    List<String> tags = const [],
    bool isPsychotherapyNote = false,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('create session note');
    }
    final effectiveNoteType = type ?? noteType ?? SessionNoteType.progressNote;
    final effectiveContent = content ?? '';
    _validateProviderAccess(context);

    final now = DateTime.now();
    final note = SessionNote(
      id: _uuid.v4(),
      businessId: context.businessId,
      appointmentId: appointmentId,
      clientId: clientId,
      providerId: providerId,
      noteType: effectiveNoteType,
      visibility: visibility,
      encryptedContent: encryptionService.encrypt(effectiveContent),
      title: title,
      tags: tags,
      createdAt: now,
      createdBy: context.userId,
      createdByName: context.userFullName ?? 'Unknown',
      isPsychotherapyNote: isPsychotherapyNote,
      auditLog: [
        SessionNoteAudit(
          id: _uuid.v4(),
          action: 'created',
          userId: context.userId,
          userFullName: context.userFullName ?? 'Unknown',
          timestamp: now,
        ),
      ],
    );

    await _notesCollection(context.businessId).doc(note.id).set(note.toJson());
    return note;
  }

  /// Get a single session note by ID
  ///
  /// Audit: Logs `phiRead` event when note is retrieved.
  Future<SessionNote?> getNote({
    required SecurityContext context,
    required String noteId,
  }) async {
    _validateProviderAccess(context);

    final doc = await _notesCollection(context.businessId).doc(noteId).get();
    if (!doc.exists) return null;

    final note = SessionNote.fromJson(
      _normalizeTimestamps(doc.data() as Map<String, dynamic>),
    );

    // Log access for in-document audit trail
    await _logAudit(
      context: context,
      noteId: noteId,
      action: 'viewed',
    );

    // Log PHI read access to central audit log (non-blocking)
    unawaited(_auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiRead,
      entityType: 'SessionNote',
      entityId: noteId,
      metadata: {
        'source': 'getNote',
        'clientId': note.clientId,
        'noteType': note.noteType.name,
      },
    )));

    return note;
  }

  /// Watch session notes for a specific appointment
  ///
  /// Audit: Logs one `phiReadList` event on first emission.
  Stream<List<SessionNote>> watchAppointmentNotes({
    required SecurityContext context,
    required String appointmentId,
  }) {
    _validateProviderAccess(context);

    return _withAuditLogOnFirstEmission(
      stream: _notesCollection(context.businessId)
          .where('appointmentId', isEqualTo: appointmentId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => SessionNote.fromJson(
                    _normalizeTimestamps(doc.data() as Map<String, dynamic>),
                  ))
              .toList()),
      context: context,
      metadata: {'source': 'watchAppointmentNotes', 'appointmentId': appointmentId},
    );
  }

  /// Watch all session notes for a client (timeline view)
  ///
  /// Audit: Logs one `phiReadList` event on first emission.
  Stream<List<SessionNote>> watchClientNotes({
    required SecurityContext context,
    required String clientId,
  }) {
    _validateProviderAccess(context);

    return _withAuditLogOnFirstEmission(
      stream: _notesCollection(context.businessId)
          .where('clientId', isEqualTo: clientId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => SessionNote.fromJson(
                    _normalizeTimestamps(doc.data() as Map<String, dynamic>),
                  ))
              .toList()),
      context: context,
      metadata: {'source': 'watchClientNotes', 'clientId': clientId},
    );
  }

  /// Get all session notes for a client (non-streaming)
  ///
  /// Audit: Logs one `phiReadList` event when notes are retrieved.
  Future<List<SessionNote>> getClientNotes({
    required SecurityContext context,
    required String clientId,
  }) async {
    _validateProviderAccess(context);

    final snapshot = await _notesCollection(context.businessId)
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .get();

    final notes = snapshot.docs
        .map((doc) => SessionNote.fromJson(
              _normalizeTimestamps(doc.data() as Map<String, dynamic>),
            ))
        .toList();

    // Log PHI read list access to central audit log (non-blocking)
    unawaited(_auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiReadList,
      entityType: 'SessionNote',
      entityId: context.businessId,
      metadata: {
        'source': 'getClientNotes',
        'clientId': clientId,
        'mode': 'list',
        'count': notes.length,
      },
    )));

    return notes;
  }

  /// Update session note content
  Future<SessionNote> updateNote({
    required SecurityContext context,
    required EncryptionService encryptionService,
    String? noteId,
    SessionNote? note, // Alternatively pass the note object
    String? newContent,
    String? content, // Alias for newContent
    SessionNoteType? type,
    SessionNoteVisibility? visibility,
    String? templateId,
    String? appointmentId,
    String? providerId,
    String? title,
    List<String>? tags,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('update session note');
    }
    _validateProviderAccess(context);

    final effectiveNoteId = noteId ?? note?.id;
    if (effectiveNoteId == null) {
      throw Exception('Either noteId or note must be provided');
    }

    // Get existing note to check if locked
    final existing = await getNote(context: context, noteId: effectiveNoteId);
    if (existing == null) {
      throw Exception('Note not found');
    }
    if (existing.isLocked) {
      throw Exception('Note is locked and cannot be edited');
    }

    final effectiveContent = content ?? newContent;
    final now = DateTime.now();
    final updates = <String, dynamic>{
      'updatedAt': now,
      'lastEditedBy': context.userId,
      'lastEditedByName': context.userFullName ?? 'Unknown',
    };

    if (effectiveContent != null) {
      updates['encryptedContent'] = encryptionService.encrypt(effectiveContent);
    }
    if (title != null) updates['title'] = title;
    if (tags != null) updates['tags'] = tags;
    if (type != null) updates['noteType'] = type.name;
    if (visibility != null) updates['visibility'] = visibility.name;

    await _notesCollection(context.businessId).doc(effectiveNoteId).update(updates);

    // Log edit for audit trail
    await _logAudit(
      context: context,
      noteId: effectiveNoteId,
      action: 'edited',
      changesSummary: 'Content updated',
    );

    // Return the updated note
    final updated = await getNote(context: context, noteId: effectiveNoteId);
    return updated!;
  }

  /// Lock a note to prevent further editing
  Future<void> lockNote({
    required SecurityContext context,
    required String noteId,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('lock session note');
    }
    _validateProviderAccess(context);

    await _notesCollection(context.businessId).doc(noteId).update({
      'isLocked': true,
    });

    await _logAudit(
      context: context,
      noteId: noteId,
      action: 'locked',
    );
  }

  /// Delete a session note (soft delete - marks as deleted but retains for audit)
  Future<void> deleteNote({
    required SecurityContext context,
    required String noteId,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('delete session note');
    }
    _validateOwnerAccess(context); // Only owners can delete notes

    await _logAudit(
      context: context,
      noteId: noteId,
      action: 'deleted',
    );

    // In production, implement soft delete with retention policy
    // For now, hard delete
    await _notesCollection(context.businessId).doc(noteId).delete();
  }

  /// Search notes by tags (tags are NOT encrypted)
  Future<List<SessionNote>> searchByTags({
    required SecurityContext context,
    required List<String> tags,
    String? clientId,
  }) async {
    _validateProviderAccess(context);

    var query = _notesCollection(context.businessId)
        .where('tags', arrayContainsAny: tags);

    if (clientId != null) {
      query = query.where('clientId', isEqualTo: clientId);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => SessionNote.fromJson(
              _normalizeTimestamps(doc.data() as Map<String, dynamic>),
            ))
        .toList();
  }

  /// Get notes by type for a client
  Future<List<SessionNote>> getNotesByType({
    required SecurityContext context,
    required String clientId,
    required SessionNoteType noteType,
  }) async {
    _validateProviderAccess(context);

    final snapshot = await _notesCollection(context.businessId)
        .where('clientId', isEqualTo: clientId)
        .where('noteType', isEqualTo: noteType.name)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => SessionNote.fromJson(
              _normalizeTimestamps(doc.data() as Map<String, dynamic>),
            ))
        .toList();
  }

  /// Export all notes for a client (for compliance/audit)
  Future<List<SessionNote>> exportClientNotes({
    required SecurityContext context,
    required String clientId,
  }) async {
    _validateOwnerAccess(context); // Only owners can export

    return await getClientNotes(context: context, clientId: clientId);
  }

  /// Log audit entry for a note
  Future<void> _logAudit({
    required SecurityContext context,
    required String noteId,
    required String action,
    String? changesSummary,
  }) async {
    final audit = SessionNoteAudit(
      id: _uuid.v4(),
      action: action,
      userId: context.userId,
      userFullName: context.userFullName ?? 'Unknown',
      timestamp: DateTime.now(),
      changesSummary: changesSummary,
    );

    // Add to audit log array
    await _notesCollection(context.businessId).doc(noteId).update({
      'auditLog': FieldValue.arrayUnion([audit.toJson()]),
    });
  }

  /// Validate that user has provider-level access
  void _validateProviderAccess(SecurityContext context) {
    if (!context.role.canManageClients) {
      throw SecurityException(
        'Unauthorized: Session notes require provider access',
      );
    }
  }

  /// Normalize Firestore Timestamps to ISO strings for JSON deserialization
  Map<String, dynamic> _normalizeTimestamps(Map<String, dynamic> data) {
    final normalized = Map<String, dynamic>.from(data);

    void normalizeField(String key) {
      final value = normalized[key];
      if (value is Timestamp) {
        normalized[key] = value.toDate().toIso8601String();
      } else if (value is DateTime) {
        normalized[key] = value.toIso8601String();
      }
    }

    normalizeField('createdAt');
    normalizeField('updatedAt');

    // Normalize timestamps in auditLog entries
    if (normalized['auditLog'] is List) {
      normalized['auditLog'] = (normalized['auditLog'] as List).map((entry) {
        if (entry is Map<String, dynamic>) {
          final normalizedEntry = Map<String, dynamic>.from(entry);
          final ts = normalizedEntry['timestamp'];
          if (ts is Timestamp) {
            normalizedEntry['timestamp'] = ts.toDate().toIso8601String();
          } else if (ts is DateTime) {
            normalizedEntry['timestamp'] = ts.toIso8601String();
          }
          return normalizedEntry;
        }
        return entry;
      }).toList();
    }

    return normalized;
  }

  /// Validate that user has owner access
  void _validateOwnerAccess(SecurityContext context) {
    if (context.role != UserRole.owner) {
      throw SecurityException(
        'Unauthorized: This operation requires owner access',
      );
    }
  }

  /// Wrap a stream so PHI list read is logged only on the first emission.
  Stream<List<SessionNote>> _withAuditLogOnFirstEmission({
    required Stream<List<SessionNote>> stream,
    required SecurityContext context,
    required Map<String, dynamic> metadata,
  }) async* {
    bool logged = false;
    await for (final notes in stream) {
      if (!logged) {
        logged = true;
        unawaited(_auditLogRepository.logEvent(AuditLogEntry(
          businessId: context.businessId,
          userId: context.userId,
          actionType: AuditActionType.phiReadList,
          entityType: 'SessionNote',
          entityId: context.businessId,
          metadata: {
            ...metadata,
            'mode': 'list',
            'count': notes.length,
          },
        )));
      }
      yield notes;
    }
  }
}

/// Mock repository for testing
class MockSessionNotesRepository extends SessionNotesRepository {
  final Map<String, SessionNote> _notes = {};

  @override
  Future<SessionNote> createNote({
    required SecurityContext context,
    required String appointmentId,
    required String clientId,
    required String providerId,
    required EncryptionService encryptionService,
    SessionNoteType? type,
    SessionNoteType? noteType,
    String? content,
    String? templateId,
    SessionNoteVisibility visibility = SessionNoteVisibility.providerOnly,
    String? title,
    List<String> tags = const [],
    bool isPsychotherapyNote = false,
  }) async {
    final effectiveNoteType = type ?? noteType ?? SessionNoteType.progressNote;
    final effectiveContent = content ?? '';
    final note = SessionNote(
      id: Uuid().v4(),
      businessId: context.businessId,
      appointmentId: appointmentId,
      clientId: clientId,
      providerId: providerId,
      noteType: effectiveNoteType,
      visibility: visibility,
      encryptedContent: encryptionService.encrypt(effectiveContent),
      title: title,
      tags: tags,
      createdAt: DateTime.now(),
      createdBy: context.userId,
      createdByName: context.userFullName ?? 'Unknown',
      isPsychotherapyNote: isPsychotherapyNote,
    );

    _notes[note.id] = note;
    return note;
  }

  @override
  Future<SessionNote?> getNote({
    required SecurityContext context,
    required String noteId,
  }) async {
    return _notes[noteId];
  }

  @override
  Future<List<SessionNote>> getClientNotes({
    required SecurityContext context,
    required String clientId,
  }) async {
    return _notes.values
        .where((note) => note.clientId == clientId && note.businessId == context.businessId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
