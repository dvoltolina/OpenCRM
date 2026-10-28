import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/core/services/encryption_service.dart';
import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/data/models/session_note.dart';
import 'package:the_scheduler/data/repositories/audit_log_repository.dart';
import 'package:the_scheduler/data/repositories/session_notes_repository.dart';

void main() {
  group('SessionNotesRepository', () {
    late FakeFirebaseFirestore firestore;
    late SessionNotesRepository repository;
    late SecurityContext providerContext;
    late MockEncryptionService encryptionService;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = SessionNotesRepository(
        firestore: firestore,
        auditLogRepository: AuditLogRepository(firestore: firestore),
      );
      providerContext = SecurityContext(
        userId: 'provider-1',
        businessId: 'biz-1',
        role: UserRole.admin,
        userFullName: 'Dr. Admin',
      );
      encryptionService = MockEncryptionService()..initialize();
    });

    test('createNote encrypts content and logs audit trail', () async {
      final note = await repository.createNote(
        context: providerContext,
        appointmentId: 'appt-1',
        clientId: 'client-1',
        providerId: 'provider-1',
        encryptionService: encryptionService,
        content: 'Sensitive session summary',
        noteType: SessionNoteType.progressNote,
        title: 'Week 1',
      );

      final stored = await firestore
          .collection('businesses')
          .doc(providerContext.businessId)
          .collection('session_notes')
          .doc(note.id)
          .get();

      final data = stored.data();
      expect(stored.exists, isTrue);
      expect(data?['encryptedContent'], startsWith('MOCK_ENCRYPTED:'));
      expect((data?['auditLog'] as List).length, 1);
    });

    test('updateNote re-encrypts content and records editor', () async {
      final original = await repository.createNote(
        context: providerContext,
        appointmentId: 'appt-2',
        clientId: 'client-2',
        providerId: 'provider-1',
        encryptionService: encryptionService,
        content: 'Initial note',
      );

      final updated = await repository.updateNote(
        context: providerContext,
        encryptionService: encryptionService,
        noteId: original.id,
        newContent: 'Updated content',
        title: 'Updated title',
      );

      expect(updated.title, 'Updated title');
      expect(updated.lastEditedBy, providerContext.userId);
      final stored = await firestore
          .collection('businesses')
          .doc(providerContext.businessId)
          .collection('session_notes')
          .doc(original.id)
          .get();
      expect(
        stored.data()?['encryptedContent'],
        startsWith('MOCK_ENCRYPTED:Updated content'),
      );
    });

    test('lockNote prevents subsequent edits', () async {
      final note = await repository.createNote(
        context: providerContext,
        appointmentId: 'appt-3',
        clientId: 'client-3',
        providerId: 'provider-1',
        encryptionService: encryptionService,
        content: 'Lock me',
      );

      await repository.lockNote(
        context: providerContext,
        noteId: note.id,
      );

      expect(
        () => repository.updateNote(
          context: providerContext,
          encryptionService: encryptionService,
          noteId: note.id,
          newContent: 'attempted edit',
        ),
        throwsException,
      );
    });
  });
}

