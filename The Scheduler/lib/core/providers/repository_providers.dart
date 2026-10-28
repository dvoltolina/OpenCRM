import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/appointments_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/business_repository.dart';
import '../../data/repositories/audit_log_repository.dart';
import '../../data/repositories/availability_repository.dart';
import '../../data/repositories/clients_repository.dart';
import '../../data/repositories/communication_repository.dart';
import '../../data/repositories/file_attachment_repository.dart';
import '../../data/repositories/gift_card_repository.dart';
import '../../data/repositories/gift_card_template_repository.dart';
import '../../data/repositories/group_attendees_repository.dart';
import '../../data/repositories/intake_form_repository.dart';
import '../../data/repositories/invite_repository.dart';
import '../../data/repositories/locations_repository.dart';
import '../../data/repositories/modification_requests_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/pos_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/providers_repository.dart';
import '../../data/repositories/messaging_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/time_entry_repository.dart';
import '../../data/repositories/accounting_connection_repository.dart';
import '../../data/repositories/resources_repository.dart';
import '../services/encryption_service.dart';
import '../../data/repositories/services_repository.dart';
import '../../data/repositories/session_notes_repository.dart';
import '../../data/repositories/staff_repository.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/waitlist_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/staff_onboarding_repository.dart';
import '../../data/repositories/workspace_repository.dart';
import 'app_providers.dart';

/// Repository providers used across the app.

/// Provider for Firestore instance.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Provider for AuditLogRepository.
final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return AuditLogRepository(firestore: firestore);
});

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

/// Provider for BusinessRepository.
final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return BusinessRepository(firestore: firestore);
});

final appointmentsRepositoryProvider = Provider<AppointmentsRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auditLog = ref.watch(auditLogRepositoryProvider);
  final groupAttendees = GroupAttendeesRepository(
    firestore: firestore,
    auditLogRepository: auditLog,
  );
  return AppointmentsRepository(
    firestore: firestore,
    groupAttendeesRepository: groupAttendees,
    auditLogRepository: auditLog,
  );
});

final servicesRepositoryProvider = Provider<ServicesRepository>(
  (ref) => ServicesRepository(),
);

final providersRepositoryProvider = Provider<ProvidersRepository>(
  (ref) => ProvidersRepository(),
);

final locationsRepositoryProvider = Provider<LocationsRepository>(
  (ref) => LocationsRepository(),
);

final clientsRepositoryProvider = Provider<ClientsRepository>(
  (ref) => ClientsRepository(),
);

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => PaymentRepository(),
);

final availabilityRepositoryProvider = Provider<AvailabilityRepository>(
  (ref) => FirestoreAvailabilityRepository(),
);

final waitlistRepositoryProvider = Provider<WaitlistRepository>(
  (ref) => WaitlistRepository(),
);

final communicationRepositoryProvider = Provider<CommunicationRepository>((
  ref,
) {
  final config = ref.watch(appConfigProvider);
  final securityContext = ref.watch(securityContextProvider).valueOrNull;

  if (securityContext != null) {
    final firestore = ref.watch(firestoreProvider);
    return FirestoreCommunicationRepository(
      context: securityContext,
      defaultConfig: config.communicationConfig,
      firestore: firestore,
    );
  }

  return InMemoryCommunicationRepository(config.communicationConfig);
});

final modificationRequestsRepositoryProvider =
    Provider<ModificationRequestsRepository>(
      (ref) => ModificationRequestsRepository(),
    );

final groupAttendeesRepositoryProvider = Provider<GroupAttendeesRepository>((
  ref,
) {
  final firestore = ref.watch(firestoreProvider);
  final auditLog = ref.watch(auditLogRepositoryProvider);
  return GroupAttendeesRepository(
    firestore: firestore,
    auditLogRepository: auditLog,
  );
});

final resourcesRepositoryProvider = Provider<ResourcesRepository>(
  (ref) => ResourcesRepository(),
);

final messagingRepositoryProvider = Provider<MessagingRepository>(
  (ref) => MessagingRepository(),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(),
);

final intakeFormRepositoryProvider = Provider<IntakeFormRepository>(
  (ref) => IntakeFormRepository(),
);

final fileAttachmentRepositoryProvider = Provider<FileAttachmentRepository>(
  (ref) => FileAttachmentRepository(),
);

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final sessionNotesRepositoryProvider = Provider<SessionNotesRepository>((ref) {
  final auditLog = ref.watch(auditLogRepositoryProvider);
  return SessionNotesRepository(auditLogRepository: auditLog);
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return FirestoreSubscriptionRepository();
});

// ============================================================
// Gift Card Providers (Agent FC-E)
// ============================================================

final giftCardRepositoryProvider = Provider<GiftCardRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auditLog = ref.watch(auditLogRepositoryProvider);
  return GiftCardRepository(firestore: firestore, auditLogRepository: auditLog);
});

final giftCardTemplateRepositoryProvider = Provider<GiftCardTemplateRepository>(
  (ref) {
    final firestore = ref.watch(firestoreProvider);
    final auditLog = ref.watch(auditLogRepositoryProvider);
    return GiftCardTemplateRepository(
      firestore: firestore,
      auditLogRepository: auditLog,
    );
  },
);

// ============================================================
// POS Providers (Agent FC-J)
// ============================================================

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auditLog = ref.watch(auditLogRepositoryProvider);
  return ProductRepository(firestore: firestore, auditLogRepository: auditLog);
});

final posRepositoryProvider = Provider<PosRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auditLog = ref.watch(auditLogRepositoryProvider);
  return PosRepository(firestore: firestore, auditLogRepository: auditLog);
});

// ============================================================
// Time Entry Providers (Agent S12)
// ============================================================

final timeEntryRepositoryProvider = Provider<TimeEntryRepository>((ref) {
  final auditLog = ref.watch(auditLogRepositoryProvider);
  return TimeEntryRepository(auditLogRepository: auditLog);
});

// ============================================================
// Accounting Integration Providers (Agent FC-T)
// ============================================================

/// Provider for EncryptionService.
///
/// HIPAA: Provides AES-256-GCM encryption for sensitive data.
/// In production, master keys should come from Cloud KMS.
final encryptionServiceProvider =
    FutureProvider.family<EncryptionService, String>((ref, businessId) async {
      return EncryptionKeyManager.getForBusiness(businessId);
    });

/// Provider for AccountingConnectionRepository.
///
/// Manages connections to accounting software (QuickBooks, Xero)
/// including OAuth tokens, sync settings, and sync history.
///
/// HIPAA: OAuth tokens are encrypted at rest using the business's
/// encryption key via EncryptionService.
final accountingConnectionRepositoryProvider =
    Provider.family<AccountingConnectionRepository, EncryptionService?>((
      ref,
      encryptionService,
    ) {
      final firestore = ref.watch(firestoreProvider);
      final auditLog = ref.watch(auditLogRepositoryProvider);
      return AccountingConnectionRepository(
        firestore: firestore,
        auditLogRepository: auditLog,
        encryptionService: encryptionService,
      );
    });

/// Convenience provider for AccountingConnectionRepository without encryption.
/// WARNING: Only use for development/testing. Production must use encrypted version.
final accountingConnectionRepositoryUnencryptedProvider =
    Provider<AccountingConnectionRepository>((ref) {
      final firestore = ref.watch(firestoreProvider);
      final auditLog = ref.watch(auditLogRepositoryProvider);
      return AccountingConnectionRepository(
        firestore: firestore,
        auditLogRepository: auditLog,
        // No encryption service - will log warnings in debug mode
      );
    });

// ============================================================
// Task Providers (Agent FP2)
// ============================================================

/// Provider for TaskRepository.
///
/// Manages provider tasks with RBAC enforcement:
/// - Staff can only manage their own tasks
/// - Admins can manage all business tasks
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auditLog = ref.watch(auditLogRepositoryProvider);
  return TaskRepository(firestore: firestore, auditLogRepository: auditLog);
});

// ============================================================
// Staff Onboarding Providers (Agent RW2)
// ============================================================

/// Provider for StaffOnboardingRepository.
///
/// Manages staff onboarding via join codes, invites, and join requests.
/// All mutation operations call Cloud Functions for security and audit logging.
///
/// RBAC enforcement:
/// - Only owners and admins can create/revoke codes and invites
/// - Only owners and admins can review join requests
///
/// HIPAA compliance:
/// - All operations are audit logged
/// - No PHI in join codes, invites, or requests
/// - Generic error messages to prevent user enumeration
final staffOnboardingRepositoryProvider = Provider<StaffOnboardingRepository>((
  ref,
) {
  final firestore = ref.watch(firestoreProvider);
  final auditLog = ref.watch(auditLogRepositoryProvider);
  return StaffOnboardingRepository(firestore: firestore, auditLog: auditLog);
});

// Staff management (ROLE-B)
final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final functions = FirebaseFunctions.instance;
  return StaffRepository(
    firestore: firestore,
    functions: functions,
  );
});

final inviteRepositoryProvider = Provider<InviteRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final functions = FirebaseFunctions.instance;
  return InviteRepository(
    firestore: firestore,
    functions: functions,
  );
});

// ============================================================
// Workspace Providers (Agent WS1)
// ============================================================

/// Provider for WorkspaceRepository.
///
/// Manages workspace/business creation with ULID-based IDs.
/// Calls createWorkspace Cloud Function for secure workspace setup.
///
/// HIPAA compliance:
/// - All operations are audit logged by Cloud Functions
/// - Business isolation enforced at creation time
final workspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  return WorkspaceRepository();
});
