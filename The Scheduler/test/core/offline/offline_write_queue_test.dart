import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:the_scheduler/core/offline/offline_write_queue.dart';
import 'package:the_scheduler/core/offline/pending_write.dart';
import 'package:the_scheduler/core/services/recurrence_service.dart';
import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/data/repositories/appointments_repository.dart';
import 'package:the_scheduler/data/repositories/audit_log_repository.dart';
import 'package:the_scheduler/data/repositories/group_attendees_repository.dart';
import 'package:the_scheduler/data/repositories/session_notes_repository.dart';
import 'package:the_scheduler/data/repositories/task_repository.dart';

void main() {
  group('OfflineWriteQueue', () {
    late FakeFirebaseFirestore firestore;
    late SharedPreferences prefs;
    late AppointmentsRepository appointmentsRepo;
    late SessionNotesRepository sessionNotesRepo;
    late TaskRepository taskRepo;
    late OfflineWriteQueue queue;
    late SecurityContext testContext;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      firestore = FakeFirebaseFirestore();

      final auditLog = AuditLogRepository(firestore: firestore);
      final groupAttendees = GroupAttendeesRepository(
        firestore: firestore,
        auditLogRepository: auditLog,
      );
      final recurrenceService = RecurrenceService(firestore: firestore);

      appointmentsRepo = AppointmentsRepository(
        firestore: firestore,
        recurrenceService: recurrenceService,
        groupAttendeesRepository: groupAttendees,
        auditLogRepository: auditLog,
      );

      sessionNotesRepo = SessionNotesRepository(
        firestore: firestore,
        auditLogRepository: auditLog,
      );

      taskRepo = TaskRepository(
        firestore: firestore,
        auditLogRepository: auditLog,
      );

      queue = OfflineWriteQueue(
        prefs: prefs,
        appointmentsRepo: appointmentsRepo,
        notesRepo: sessionNotesRepo,
        tasksRepo: taskRepo,
      );

      testContext = SecurityContext(
        userId: 'test-user',
        businessId: 'test-business',
        role: UserRole.staff,
        providerId: 'test-provider',
      );
    });

    test('enqueues pending write', () async {
      final write = PendingWrite(
        id: 'write-1',
        type: PendingWriteType.appointmentStatus,
        payload: {
          'appointmentId': 'appt-1',
          'status': 'completed',
          'userId': testContext.userId,
          'businessId': testContext.businessId,
          'role': testContext.role.name,
          'providerId': testContext.providerId,
        },
        createdAt: DateTime.now(),
      );

      await queue.enqueue(write);

      final size = await queue.getQueueSize();
      expect(size, 1);

      final writes = await queue.getQueue();
      expect(writes.length, 1);
      expect(writes.first.type, PendingWriteType.appointmentStatus);
      expect(writes.first.retryCount, 0);
    });

    test('updates existing write with same ID', () async {
      final write1 = PendingWrite(
        id: 'write-1',
        type: PendingWriteType.appointmentStatus,
        payload: {'appointmentId': 'appt-1', 'status': 'pending'},
        createdAt: DateTime.now(),
      );

      final write2 = PendingWrite(
        id: 'write-1', // Same ID
        type: PendingWriteType.appointmentStatus,
        payload: {'appointmentId': 'appt-1', 'status': 'completed'},
        createdAt: DateTime.now(),
      );

      await queue.enqueue(write1);
      await queue.enqueue(write2);

      // Should only have 1 write (updated)
      final size = await queue.getQueueSize();
      expect(size, 1);

      final writes = await queue.getQueue();
      expect(writes.first.payload['status'], 'completed');
    });

    test('persists queue to SharedPreferences', () async {
      final write = PendingWrite(
        id: 'write-1',
        type: PendingWriteType.taskCreate,
        payload: {'title': 'Test Task'},
        createdAt: DateTime.now(),
      );

      await queue.enqueue(write);

      // Create new queue instance with same prefs
      final queue2 = OfflineWriteQueue(
        prefs: prefs,
        appointmentsRepo: appointmentsRepo,
        notesRepo: sessionNotesRepo,
        tasksRepo: taskRepo,
      );

      // Should load persisted writes
      final size = await queue2.getQueueSize();
      expect(size, 1);
    });

    test('clears entire queue', () async {
      await queue.enqueue(PendingWrite(
        id: 'write-1',
        type: PendingWriteType.taskCreate,
        payload: {'title': 'Task 1'},
        createdAt: DateTime.now(),
      ));

      await queue.enqueue(PendingWrite(
        id: 'write-2',
        type: PendingWriteType.taskCreate,
        payload: {'title': 'Task 2'},
        createdAt: DateTime.now(),
      ));

      var size = await queue.getQueueSize();
      expect(size, 2);

      await queue.clear();

      size = await queue.getQueueSize();
      expect(size, 0);
    });

    test('handles corrupt SharedPreferences data gracefully', () async {
      // Write invalid JSON to SharedPreferences
      await prefs.setString('offline_write_queue', 'invalid-json');

      // Should initialize with empty queue instead of throwing
      final queue2 = OfflineWriteQueue(
        prefs: prefs,
        appointmentsRepo: appointmentsRepo,
        notesRepo: sessionNotesRepo,
        tasksRepo: taskRepo,
      );

      final size = await queue2.getQueueSize();
      expect(size, 0);
    });

    test('emits queue changes via stream', () async {
      final emissions = <List<PendingWrite>>[];
      queue.queueStream.listen(emissions.add);

      await Future.delayed(const Duration(milliseconds: 10));

      await queue.enqueue(PendingWrite(
        id: 'write-1',
        type: PendingWriteType.taskCreate,
        payload: {'title': 'Task 1'},
        createdAt: DateTime.now(),
      ));

      await Future.delayed(const Duration(milliseconds: 10));

      await queue.enqueue(PendingWrite(
        id: 'write-2',
        type: PendingWriteType.taskCreate,
        payload: {'title': 'Task 2'},
        createdAt: DateTime.now(),
      ));

      await Future.delayed(const Duration(milliseconds: 10));

      // Should have emissions with increasing queue size
      expect(emissions.length, greaterThanOrEqualTo(2));
    });

    test('processes writes in FIFO order', () async {
      await queue.enqueue(PendingWrite(
        id: 'write-1',
        type: PendingWriteType.appointmentStatus,
        payload: {'appointmentId': 'appt-1'},
        createdAt: DateTime.now(),
      ));

      await queue.enqueue(PendingWrite(
        id: 'write-2',
        type: PendingWriteType.appointmentStatus,
        payload: {'appointmentId': 'appt-2'},
        createdAt: DateTime.now(),
      ));

      await queue.enqueue(PendingWrite(
        id: 'write-3',
        type: PendingWriteType.appointmentStatus,
        payload: {'appointmentId': 'appt-3'},
        createdAt: DateTime.now(),
      ));

      final writes = await queue.getQueue();

      // Should be in order of creation
      expect(writes[0].payload['appointmentId'], 'appt-1');
      expect(writes[1].payload['appointmentId'], 'appt-2');
      expect(writes[2].payload['appointmentId'], 'appt-3');
    });

    test('PendingWrite serializes and deserializes correctly', () {
      final original = PendingWrite(
        id: 'test-id',
        type: PendingWriteType.noteCreate,
        payload: {'key': 'value', 'nested': {'a': 1}},
        createdAt: DateTime(2024, 1, 15, 10, 30),
        retryCount: 2,
        isProcessing: false,
        lastAttemptAt: DateTime(2024, 1, 15, 10, 31),
        lastError: 'Some error',
      );

      final json = original.toJson();
      final restored = PendingWrite.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.type, original.type);
      expect(restored.payload, original.payload);
      expect(restored.retryCount, original.retryCount);
      expect(restored.isProcessing, original.isProcessing);
      expect(restored.lastError, original.lastError);
    });

    test('PendingWrite copyWith works correctly', () {
      final original = PendingWrite(
        id: 'test-id',
        type: PendingWriteType.taskUpdate,
        payload: {'taskId': 'task-1'},
        createdAt: DateTime.now(),
      );

      final modified = original.copyWith(
        retryCount: 3,
        isProcessing: true,
        lastError: 'Network error',
      );

      expect(modified.id, original.id);
      expect(modified.type, original.type);
      expect(modified.retryCount, 3);
      expect(modified.isProcessing, true);
      expect(modified.lastError, 'Network error');
    });
  });
}
