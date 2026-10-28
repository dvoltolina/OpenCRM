// DI Test Helpers
// Provides factory functions for creating properly-wired repository instances
// using FakeFirebaseFirestore, avoiding any calls to FirebaseFirestore.instance.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:the_scheduler/core/services/recurrence_service.dart';
import 'package:the_scheduler/data/repositories/appointments_repository.dart';
import 'package:the_scheduler/data/repositories/audit_log_repository.dart';
import 'package:the_scheduler/data/repositories/availability_repository.dart';
import 'package:the_scheduler/data/repositories/clients_repository.dart';
import 'package:the_scheduler/data/repositories/file_attachment_repository.dart';
import 'package:the_scheduler/data/repositories/group_attendees_repository.dart';
import 'package:the_scheduler/data/repositories/locations_repository.dart';
import 'package:the_scheduler/data/repositories/payment_repository.dart';
import 'package:the_scheduler/data/repositories/providers_repository.dart';
import 'package:the_scheduler/data/repositories/services_repository.dart';
import 'package:the_scheduler/data/repositories/waitlist_repository.dart';

/// Container for all test repositories using fake Firestore.
///
/// Usage:
/// ```dart
/// final fakeFirestore = FakeFirebaseFirestore();
/// final repos = TestRepositories(fakeFirestore);
/// // Use repos.appointments, repos.clients, etc.
/// ```
class TestRepositories {
  TestRepositories(this.firestore)
      : auditLog = AuditLogRepository(firestore: firestore),
        recurrenceService = RecurrenceService(firestore: firestore) {
    groupAttendees = GroupAttendeesRepository(
      firestore: firestore,
      auditLogRepository: auditLog,
    );
  }

  final FakeFirebaseFirestore firestore;
  final AuditLogRepository auditLog;
  late final GroupAttendeesRepository groupAttendees;
  final RecurrenceService recurrenceService;

  late final AppointmentsRepository appointments = AppointmentsRepository(
    firestore: firestore,
    recurrenceService: recurrenceService,
    groupAttendeesRepository: groupAttendees,
    auditLogRepository: auditLog,
  );

  late final ClientsRepository clients = ClientsRepository(
    firestore: firestore,
    auditLogRepository: auditLog,
  );

  late final ProvidersRepository providers = ProvidersRepository(
    firestore: firestore,
    auditLogRepository: auditLog,
  );

  late final ServicesRepository services = ServicesRepository(
    firestore: firestore,
  );

  late final LocationsRepository locations = LocationsRepository(
    firestore: firestore,
  );

  late final FirestoreAvailabilityRepository availability =
      FirestoreAvailabilityRepository(firestore: firestore);

  late final PaymentRepository payments = PaymentRepository(
    firestore: firestore,
    auditLogRepository: auditLog,
  );

  late final WaitlistRepository waitlist = WaitlistRepository(
    firestore: firestore,
  );

  late final FileAttachmentRepository fileAttachments = FileAttachmentRepository(
    firestore: firestore,
    auditLogRepository: auditLog,
  );
}
