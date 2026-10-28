import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/services/analytics_service.dart';
import '../../core/services/gift_card_service.dart';
import '../../core/services/pos_service.dart';
import '../../core/services/appointment_modification_service.dart';
import '../../core/services/availability_service.dart';
import '../../core/services/booking_payment_gateway.dart';
import '../../core/services/booking_rules_engine.dart';
import '../../core/services/customer_auth_service.dart';
import '../../core/services/email_service.dart';
import '../../core/services/encryption_service.dart';
import '../../core/services/export_service.dart';
import '../../core/services/file_storage_service.dart';
import '../../core/services/magic_link_appointment_loader.dart';
import '../../core/services/magic_link_service.dart';
import '../../core/services/social_auth_service.dart';
import '../../core/services/recurrence_service.dart';
import '../../core/services/reference_data_cache.dart';
import '../../core/services/service_factories.dart';
import '../../core/services/sms_service.dart';
import '../../core/services/stripe_service.dart';
import '../../core/services/time_slot_service.dart';
import '../../core/services/timesheet_service.dart';
import '../../core/services/waitlist_service.dart';
import '../../core/services/accounting_oauth_service.dart';
import '../../core/services/accounting_sync_service.dart';
import '../../core/offline/connectivity_service.dart';
import '../../core/offline/offline_write_queue.dart';
import '../../data/models/waitlist_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_providers.dart';
import 'repository_providers.dart';

/// Service-level providers shared across the app. These wrap existing singletons
/// or factory helpers so widgets can consume dependencies via Riverpod instead
/// of instantiating them inline.

final recurrenceServiceProvider =
    Provider<RecurrenceService>((ref) => RecurrenceService());

final automationServiceProvider = Provider<AutomationService>((ref) {
  final config = ref.watch(appConfigProvider);
  final communicationRepository = ref.watch(communicationRepositoryProvider);
  return buildAutomationService(
    config,
    communicationRepository: communicationRepository,
  );
});

final availabilityServiceProvider = Provider<AvailabilityService>((ref) {
  final config = ref.watch(appConfigProvider);
  return FirestoreAvailabilityService(
    availabilityRepository: ref.watch(availabilityRepositoryProvider),
    appointmentsRepository: ref.watch(appointmentsRepositoryProvider),
    bookingPolicies: config.bookingPolicies,
  );
});

final bookingPaymentGatewayProvider = Provider<BookingPaymentGateway?>((ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.featureFlags.enablePayments) return null;

  final functionUrl = config.paymentConfig.paymentIntentFunctionUrl;
  if (functionUrl.isEmpty) return null;

  return StripeBookingPaymentGateway(
    cloudFunctionUrl: functionUrl,
    currency: config.paymentConfig.currency,
  );
});

final bookingRulesEngineProvider = Provider<BookingRulesEngine>((ref) {
  final config = ref.watch(appConfigProvider);
  return BookingRulesEngine(
    bookingPolicies: config.bookingPolicies,
    featureFlags: config.featureFlags,
    appointmentsRepository: ref.watch(appointmentsRepositoryProvider),
    clientsRepository: ref.watch(clientsRepositoryProvider),
    providersRepository: ref.watch(providersRepositoryProvider),
    servicesRepository: ref.watch(servicesRepositoryProvider),
    locationsRepository: ref.watch(locationsRepositoryProvider),
    availabilityService: ref.watch(availabilityServiceProvider),
    automationService: ref.watch(automationServiceProvider),
    paymentRepository: ref.watch(paymentRepositoryProvider),
    paymentGateway: ref.watch(bookingPaymentGatewayProvider),
    recurrenceService: ref.watch(recurrenceServiceProvider),
  );
});

final waitlistServiceProvider = Provider<WaitlistService>((ref) {
  final config = ref.watch(appConfigProvider);
  return WaitlistService(
    waitlistRepository: ref.watch(waitlistRepositoryProvider),
    automationService: ref.watch(automationServiceProvider),
    availabilityService: ref.watch(availabilityServiceProvider),
    bookingPolicies: config.bookingPolicies,
    handleReleasedSlotUrl: config.communicationConfig.handleReleasedSlotUrl,
    notifyWaitlistEntryUrl: config.communicationConfig.notifyWaitlistEntryUrl,
  );
});

final socialAuthServiceProvider = Provider<SocialAuthService>((ref) {
  return SocialAuthService();
});

class WaitlistEntriesFilter {
  const WaitlistEntriesFilter({
    this.serviceId,
    this.providerId,
    this.status,
  });

  final String? serviceId;
  final String? providerId;
  final WaitlistStatus? status;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WaitlistEntriesFilter &&
        other.serviceId == serviceId &&
        other.providerId == providerId &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(serviceId, providerId, status, runtimeType);
}

final waitlistEntriesStreamProviderFamily =
    StreamProvider.family<List<WaitlistEntry>, WaitlistEntriesFilter>(
  (ref, filter) {
    final context = ref.watch(currentSecurityContextProvider);
    if (context == null) return const Stream.empty();
    return ref.watch(waitlistRepositoryProvider).watchEntries(
          context: context,
          serviceId: filter.serviceId,
          providerId: filter.providerId,
          status: filter.status,
        );
  },
);

final customerAuthServiceProvider =
    Provider<CustomerAuthService>((ref) => CustomerAuthService());

final magicLinkServiceProvider =
    Provider<MagicLinkService>((ref) => MagicLinkService());

final magicLinkAppointmentLoaderProvider =
    Provider<MagicLinkAppointmentLoader>((ref) {
  return MagicLinkAppointmentLoader(
    magicLinkService: ref.watch(magicLinkServiceProvider),
    appointmentsRepository: ref.watch(appointmentsRepositoryProvider),
    clientsRepository: ref.watch(clientsRepositoryProvider),
    providersRepository: ref.watch(providersRepositoryProvider),
    servicesRepository: ref.watch(servicesRepositoryProvider),
    locationsRepository: ref.watch(locationsRepositoryProvider),
  );
});

/// Provider for ReferenceDataCache.
/// Singleton cache for frequently-accessed reference data (Services, Providers, Locations).
final referenceDataCacheProvider = Provider((ref) {
  return ReferenceDataCache.instance;
});

// Additional service providers for Agent R2 completion

/// Provider for TimeSlotService.
final timeSlotServiceProvider = Provider<TimeSlotService>((ref) {
  final config = ref.watch(appConfigProvider);
  return TimeSlotService(
    availabilityRepository: ref.watch(availabilityRepositoryProvider),
    appointmentsRepository: ref.watch(appointmentsRepositoryProvider),
    bookingPolicies: config.bookingPolicies,
  );
});

/// Provider for EmailService (mock by default).
final emailServiceProvider = Provider<EmailService>((ref) {
  return MockEmailService();
});

/// Provider for SmsService (mock by default).
final smsServiceProvider = Provider<SmsService>((ref) {
  return MockSmsService();
});

/// Provider for HTTP client.
final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

/// Provider for AppointmentModificationService.
final appointmentModificationServiceProvider = Provider<AppointmentModificationService>((ref) {
  final config = ref.watch(appConfigProvider);
  return AppointmentModificationService(
    bookingPolicies: config.bookingPolicies,
    featureFlags: config.featureFlags,
    appointmentsRepository: ref.watch(appointmentsRepositoryProvider),
    clientsRepository: ref.watch(clientsRepositoryProvider),
    providersRepository: ref.watch(providersRepositoryProvider),
    servicesRepository: ref.watch(servicesRepositoryProvider),
    locationsRepository: ref.watch(locationsRepositoryProvider),
    availabilityService: ref.watch(availabilityServiceProvider),
    automationService: ref.watch(automationServiceProvider),
    modificationRequestsRepository: ref.watch(modificationRequestsRepositoryProvider),
    paymentGateway: ref.watch(bookingPaymentGatewayProvider),
    paymentRepository: ref.watch(paymentRepositoryProvider),
  );
});

/// Provider for FirebaseStorage instance.
final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

/// Provider for FileStorageService.
final fileStorageServiceProvider = Provider<FileStorageService>((ref) {
  final storage = ref.watch(firebaseStorageProvider);
  return FileStorageService(storage: storage);
});

/// Provider for StripeService singleton.
final stripeServiceProvider = Provider<StripeService>((ref) {
  return StripeService.instance;
});

/// Provider for AnalyticsService.
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(
    appointmentsRepository: ref.watch(appointmentsRepositoryProvider),
    clientsRepository: ref.watch(clientsRepositoryProvider),
    paymentRepository: ref.watch(paymentRepositoryProvider),
    subscriptionRepository: ref.watch(subscriptionRepositoryProvider),
  );
});

/// Provider for ExportService.
final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService(
    auditLogRepository: ref.watch(auditLogRepositoryProvider),
  );
});

// ============================================================
// Gift Card Providers (Agent FC-E)
// ============================================================

/// Provider for GiftCardService.
final giftCardServiceProvider = Provider<GiftCardService>((ref) {
  final config = ref.watch(appConfigProvider);
  return GiftCardService(
    repository: ref.watch(giftCardRepositoryProvider),
    templateRepository: ref.watch(giftCardTemplateRepositoryProvider),
    stripeService: ref.watch(stripeServiceProvider),
    emailService: ref.watch(emailServiceProvider),
    auditLogRepository: ref.watch(auditLogRepositoryProvider),
    appConfig: config,
  );
});

// ============================================================
// POS Providers (Agent FC-K)
// ============================================================

/// Provider for PosService.
final posServiceProvider = Provider<PosService>((ref) {
  final config = ref.watch(appConfigProvider);
  return PosService(
    posRepository: ref.watch(posRepositoryProvider),
    productRepository: ref.watch(productRepositoryProvider),
    giftCardRepository: ref.watch(giftCardRepositoryProvider),
    stripeService: ref.watch(stripeServiceProvider),
    auditLogRepository: ref.watch(auditLogRepositoryProvider),
    appConfig: config,
  );
});

// ============================================================
// Timesheet Providers (Agent S12)
// ============================================================

/// Provider for TimesheetService.
final timesheetServiceProvider = Provider<TimesheetService>((ref) {
  return TimesheetService(
    timeEntryRepository: ref.watch(timeEntryRepositoryProvider),
    providersRepository: ref.watch(providersRepositoryProvider),
  );
});

// ============================================================
// Accounting Integration Providers (Agent FC-T)
// ============================================================

/// Provider for AccountingOAuthService.
///
/// Handles OAuth 2.0 flows for QuickBooks and Xero connections.
/// Manages authorization URLs, token exchange, and token refresh.
///
/// HIPAA NOTE: For production use, use [accountingOAuthServiceEncryptedProvider]
/// which encrypts OAuth tokens at rest.
final accountingOAuthServiceProvider = Provider<AccountingOAuthService>((ref) {
  return AccountingOAuthService(
    repository: ref.watch(accountingConnectionRepositoryUnencryptedProvider),
  );
});

/// Provider for AccountingOAuthService with encryption.
///
/// HIPAA: Use this provider in production to ensure OAuth tokens are
/// encrypted at rest. Requires passing the EncryptionService for the business.
final accountingOAuthServiceEncryptedProvider =
    Provider.family<AccountingOAuthService, EncryptionService?>((ref, encryptionService) {
  return AccountingOAuthService(
    repository: ref.watch(accountingConnectionRepositoryProvider(encryptionService)),
  );
});

/// Provider for AccountingSyncService.
///
/// Syncs data (clients, payments, invoices) to accounting software.
/// All API calls go through Cloud Functions to protect OAuth secrets.
///
/// HIPAA NOTE: For production use, use [accountingSyncServiceEncryptedProvider]
/// which encrypts OAuth tokens at rest.
final accountingSyncServiceProvider = Provider<AccountingSyncService>((ref) {
  return AccountingSyncService(
    connectionRepository: ref.watch(accountingConnectionRepositoryUnencryptedProvider),
    oauthService: ref.watch(accountingOAuthServiceProvider),
    clientsRepository: ref.watch(clientsRepositoryProvider),
    paymentRepository: ref.watch(paymentRepositoryProvider),
  );
});

/// Provider for AccountingSyncService with encryption.
///
/// HIPAA: Use this provider in production to ensure OAuth tokens are
/// encrypted at rest. Requires passing the EncryptionService for the business.
final accountingSyncServiceEncryptedProvider =
    Provider.family<AccountingSyncService, EncryptionService?>((ref, encryptionService) {
  return AccountingSyncService(
    connectionRepository: ref.watch(accountingConnectionRepositoryProvider(encryptionService)),
    oauthService: ref.watch(accountingOAuthServiceEncryptedProvider(encryptionService)),
    clientsRepository: ref.watch(clientsRepositoryProvider),
    paymentRepository: ref.watch(paymentRepositoryProvider),
  );
});

// Offline & Connectivity Providers (Agent FP4)

/// Connectivity service for monitoring network status.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Stream provider for current connectivity status.
final connectivityProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.connectivityStream.asBroadcastStream();
});

/// SharedPreferences instance for offline queue persistence.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden at bootstrap');
});

/// Offline write queue service.
final offlineWriteQueueProvider = Provider<OfflineWriteQueue>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final appointmentsRepo = ref.watch(appointmentsRepositoryProvider);
  final tasksRepo = ref.watch(taskRepositoryProvider);
  final notesRepo = ref.watch(sessionNotesRepositoryProvider);

  final queue = OfflineWriteQueue(
    prefs: prefs,
    appointmentsRepo: appointmentsRepo,
    tasksRepo: tasksRepo,
    notesRepo: notesRepo,
  );

  ref.onDispose(() => queue.dispose());
  return queue;
});

/// Stream provider for offline queue size (for monitoring).
final offlineQueueSizeProvider = StreamProvider<int>((ref) async* {
  final queue = ref.watch(offlineWriteQueueProvider);

  // Emit initial size
  yield await queue.getQueueSize();

  // Listen to queue changes and emit size
  await for (final writes in queue.queueStream) {
    yield writes.length;
  }
});
