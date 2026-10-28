// Test Data Factories
//
// Provides factory methods to create test data for all models.
// Use these factories to ensure consistent, predictable test data.
//
// Usage:
// ```dart
// final appointment = TestData.appointment();
// final client = TestData.client(name: 'Custom Name');
// ```

import 'package:flutter/material.dart' hide FormField;

import 'package:the_scheduler/core/config/app_config.dart';
import 'package:the_scheduler/core/config/app_branding.dart';
import 'package:the_scheduler/core/config/communication_config.dart';
import 'package:the_scheduler/core/config/feature_flags.dart';
import 'package:the_scheduler/core/config/integration_config.dart';
import 'package:the_scheduler/core/config/payment_config.dart';
import 'package:the_scheduler/data/models/analytics_metrics.dart';
import 'package:the_scheduler/data/models/appointment.dart';
import 'package:the_scheduler/data/models/availability.dart';
import 'package:the_scheduler/data/models/business.dart';
import 'package:the_scheduler/data/models/client.dart';
import 'package:the_scheduler/data/models/file_attachment.dart';
import 'package:the_scheduler/data/models/gift_card.dart';
import 'package:the_scheduler/data/models/intake_form.dart';
import 'package:the_scheduler/data/models/location.dart';
import 'package:the_scheduler/data/models/magic_link_token.dart';
import 'package:the_scheduler/data/models/payment.dart';
import 'package:the_scheduler/data/models/provider.dart';
import 'package:the_scheduler/data/models/resource.dart';
import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/data/models/service.dart';
import 'package:the_scheduler/data/models/session_note.dart';
import 'package:the_scheduler/data/models/subscription.dart';
import 'package:the_scheduler/data/models/waitlist_entry.dart';
import 'package:the_scheduler/data/models/join_code.dart';
import 'package:the_scheduler/data/models/invite.dart';

/// Alias for backwards compatibility with test files that use TestDataFactories
typedef TestDataFactories = TestData;

/// Test data factory class with static methods for creating test data
class TestData {
  // Private constructor to prevent instantiation
  TestData._();

  /// Fixed test date for predictable tests
  static final testDate = DateTime(2025, 12, 1, 10, 0);

  /// Standard business ID for tests
  static const businessId = 'test-business-1';

  /// Standard user ID for tests
  static const userId = 'test-user-1';
  static const _unset = Object();
  static int _paymentCounter = 1;

  // ====================
  // Security & Auth
  // ====================

  static SecurityContext securityContext({
    String? userId,
    String? businessId,
    UserRole? role,
    String? providerId,
    String? clientId,
  }) {
    return SecurityContext(
      userId: userId ?? TestData.userId,
      businessId: businessId ?? TestData.businessId,
      role: role ?? UserRole.admin,
      providerId: providerId,
      clientId: clientId,
    );
  }

  // ====================
  // App Config
  // ====================

  /// Creates a test AppConfig suitable for widget tests
  static AppConfig createTestConfig({
    String? productName,
    bool? enableClientPortal,
    bool? enablePayments,
    bool? enableWaitlist,
  }) {
    return AppConfig(
      branding: AppBranding(
        productName: productName ?? 'Test Scheduler',
        tagline: 'Test Environment',
        primaryColor: const Color(0xFF265D8C),
        accentColor: const Color(0xFF1FC8E1),
        backgroundColor: const Color(0xFFF4F6F8),
        logoAsset: null,
        fontFamily: 'Roboto',
      ),
      featureFlags: FeatureFlags(
        enableClientPortal: enableClientPortal ?? true,
        enableAutomatedReminders: true,
        enablePayments: enablePayments ?? true,
        enableMultiLocation: true,
        enableReporting: true,
        enableWaitlist: enableWaitlist ?? true,
        enableSessionNotes: true,
      ),
      bookingPolicies: const BookingPolicies(
        defaultSlotLength: Duration(minutes: 60),
        bufferBetweenAppointments: Duration(minutes: 10),
        cancellationWindow: Duration(hours: 24),
        allowDeposits: true,
        depositAmount: 50,
        minimumBookingNotice: Duration(hours: 2),
        maximumAdvanceBooking: Duration(days: 90),
        allowWaitlist: true,
        requireManualApprovalInsideWindow: false,
      ),
      modules: const [],
      serviceCatalog: const ['Test Service 1', 'Test Service 2'],
      defaultTimeZone: 'America/New_York',
      communicationConfig: CommunicationConfig.defaultClinic(),
      paymentConfig: const PaymentConfig(
        paymentIntentFunctionUrl: 'https://test.local/createPaymentIntent',
        currency: 'usd',
      ),
      integrationConfig: IntegrationConfig.defaultClinic(),
    );
  }

  // ====================
  // Core Entities
  // ====================

  static Business business({
    String? id,
    String? name,
    String? description,
    String? contactEmail,
    String? contactPhone,
  }) {
    return Business(
      id: id ?? businessId,
      name: name ?? 'Test Clinic',
      description: description,
      contactEmail: contactEmail ?? 'contact@example.com',
      contactPhone: contactPhone ?? '555-0100',
      createdAt: testDate,
    );
  }

  static Client client({
    String? id,
    String? businessId,
    String? firstName,
    String? lastName,
    Object? email = _unset,
    Object? phone = _unset,
    ClientLifecycle? lifecycle,
    List<String>? tags,
  }) {
    final resolvedEmail = email == _unset ? 'john.doe@example.com' : email as String?;
    final resolvedPhone = phone == _unset ? '555-123-4567' : phone as String?;
    return Client(
      id: id ?? 'client-1',
      businessId: businessId ?? TestData.businessId,
      firstName: firstName ?? 'John',
      lastName: lastName ?? 'Doe',
      email: resolvedEmail,
      phone: resolvedPhone,
      lifecycle: lifecycle ?? ClientLifecycle.active,
      tags: tags ?? ['test'],
      createdAt: testDate,
    );
  }

  static Provider provider({
    String? id,
    String? businessId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? bio,
    String? colorHex,
    List<String>? specializations,
    List<String>? locationIds,
    List<String>? serviceIds,
  }) {
    return Provider(
      id: id ?? 'provider-1',
      businessId: businessId ?? TestData.businessId,
      firstName: firstName ?? 'Dr. Jane',
      lastName: lastName ?? 'Smith',
      email: email ?? 'jane.smith@example.com',
      phone: phone,
      bio: bio,
      colorHex: colorHex ?? '4285F4',
      specializations: specializations ?? ['General Dentistry'],
      locationIds: locationIds ?? [],
      serviceIds: serviceIds ?? [],
      createdAt: testDate,
    );
  }

  static Service service({
    String? id,
    String? businessId,
    String? name,
    int? durationMinutes,
    double? price,
    String? category,
    List<String>? providerIds,
  }) {
    return Service(
      id: id ?? 'service-1',
      businessId: businessId ?? TestData.businessId,
      name: name ?? 'Dental Cleaning',
      durationMinutes: durationMinutes ?? 60,
      price: price ?? 100.0,
      category: category ?? 'Dental',
      providerIds: providerIds ?? [],
      createdAt: testDate,
    );
  }

  static Location location({
    String? id,
    String? businessId,
    String? name,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? phone,
  }) {
    return Location(
      id: id ?? 'location-1',
      businessId: businessId ?? TestData.businessId,
      name: name ?? 'Main Office',
      address: address ?? '123 Test St',
      city: city ?? 'Testville',
      state: state ?? 'TS',
      zipCode: zipCode ?? '12345',
      phone: phone,
      createdAt: testDate,
    );
  }

  static Appointment appointment({
    String? id,
    String? businessId,
    String? clientId,
    String? providerId,
    String? serviceId,
    String? locationId,
    DateTime? startTime,
    DateTime? endTime,
    AppointmentStatus? status,
    String? notes,
  }) {
    final start = startTime ?? testDate;
    final end = endTime ?? start.add(const Duration(hours: 1));

    return Appointment(
      id: id ?? 'appointment-1',
      businessId: businessId ?? TestData.businessId,
      clientId: clientId ?? 'client-1',
      providerId: providerId ?? 'provider-1',
      serviceId: serviceId ?? 'service-1',
      locationId: locationId ?? 'location-1',
      startTime: start,
      endTime: end,
      date: DateTime(start.year, start.month, start.day),
      status: status ?? AppointmentStatus.confirmed,
      notes: notes,
      createdAt: testDate,
    );
  }

  // ====================
  // Availability
  // ====================

  static WeeklySchedule weeklySchedule({
    String? id,
    String? providerId,
    String? locationId,
    DayOfWeek? dayOfWeek,
    List<TimeBlock>? timeBlocks,
  }) {
    return WeeklySchedule(
      id: id ?? 'schedule-1',
      providerId: providerId ?? 'provider-1',
      locationId: locationId ?? 'location-1',
      dayOfWeek: dayOfWeek ?? DayOfWeek.monday,
      timeBlocks: timeBlocks ?? [TimeBlock.fromStrings('09:00', '17:00')],
      isActive: true,
      createdAt: testDate,
    );
  }

  static Availability availability({
    String? id,
    String? providerId,
    String? locationId,
    DateTime? startTime,
    DateTime? endTime,
    AvailabilityType? type,
  }) {
    final start = startTime ?? testDate;
    final end = endTime ?? start.add(const Duration(hours: 1));

    return Availability(
      id: id ?? 'availability-1',
      providerId: providerId ?? 'provider-1',
      locationId: locationId ?? 'location-1',
      startTime: start,
      endTime: end,
      type: type ?? AvailabilityType.available,
      createdAt: testDate,
    );
  }

  static TimeBlock timeBlock({
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
  }) {
    return TimeBlock(
      startHour: startHour ?? 9,
      startMinute: startMinute ?? 0,
      endHour: endHour ?? 17,
      endMinute: endMinute ?? 0,
    );
  }

  // ====================
  // Payments & Subscriptions
  // ====================

  static Payment payment({
    String? id,
    String? businessId,
    String? appointmentId,
    String? clientId,
    int? amountCents,
    PaymentStatus? status,
    PaymentType? type,
    String? cardLast4,
    String? cardBrand,
    String? paymentMethodDescription,
    int? refundAmountCents,
    DateTime? completedAt,
    DateTime? refundedAt,
    String? stripeRefundId,
    String? reason,
    String? errorMessage,
  }) {
    final resolvedId = id ?? 'payment-${_paymentCounter++}';
    return Payment(
      id: resolvedId,
      businessId: businessId ?? TestData.businessId,
      appointmentId: appointmentId ?? 'appointment-1',
      clientId: clientId ?? 'client-1',
      amountCents: amountCents ?? 5000,
      status: status ?? PaymentStatus.completed,
      type: type ?? PaymentType.full,
      cardLast4: cardLast4,
      cardBrand: cardBrand,
      paymentMethodDescription: paymentMethodDescription,
      refundAmountCents: refundAmountCents,
      completedAt: completedAt,
      refundedAt: refundedAt,
      stripeRefundId: stripeRefundId,
      reason: reason,
      errorMessage: errorMessage,
      createdAt: testDate,
    );
  }

  static Subscription subscription({
    String? id,
    String? businessId,
    SubscriptionTier? tier,
    SubscriptionStatus? status,
    DateTime? currentPeriodStart,
    DateTime? currentPeriodEnd,
    DateTime? canceledAt,
    bool? cancelAtPeriodEnd,
  }) {
    final now = DateTime.now();
    return Subscription(
      id: id ?? 'subscription-1',
      businessId: businessId ?? TestData.businessId,
      tier: tier ?? SubscriptionTier.professional,
      status: status ?? SubscriptionStatus.active,
      stripeCustomerId: 'cus_test123',
      currentPeriodStart: currentPeriodStart ?? now,
      currentPeriodEnd: currentPeriodEnd ?? now.add(const Duration(days: 30)),
      cancelAtPeriodEnd: cancelAtPeriodEnd ?? false,
      canceledAt: canceledAt,
      createdAt: testDate,
      updatedAt: testDate,
    );
  }

  // ====================
  // Resources
  // ====================

  static Resource resource({
    String? id,
    String? businessId,
    String? name,
    ResourceType? type,
    String? locationId,
    int? capacity,
    bool? isActive,
  }) {
    return Resource(
      id: id ?? 'resource-1',
      businessId: businessId ?? TestData.businessId,
      name: name ?? 'Room 1',
      type: type ?? ResourceType.room,
      locationId: locationId ?? 'location-1',
      capacity: capacity ?? 1,
      isActive: isActive ?? true,
      createdAt: testDate,
    );
  }

  // ====================
  // Intake Forms
  // ====================

  static IntakeFormTemplate intakeFormTemplate({
    String? id,
    String? businessId,
    String? name,
    List<FormField>? fields,
    bool? isActive,
  }) {
    return IntakeFormTemplate(
      id: id ?? 'template-1',
      businessId: businessId ?? TestData.businessId,
      name: name ?? 'Medical Intake',
      description: 'Standard medical intake form',
      fields:
          fields ??
          [
            const FormField(
              id: 'field-1',
              label: 'Medical History',
              type: FormFieldType.multiline,
              required: true,
            ),
          ],
      isActive: isActive ?? true,
      version: 1,
      createdAt: testDate,
    );
  }

  static IntakeFormSubmission intakeFormSubmission({
    String? id,
    String? businessId,
    String? clientId,
    String? templateId,
    Map<String, dynamic>? responses,
    Object? submittedBy = _unset,
  }) {
    final resolvedSubmittedBy =
        submittedBy == _unset ? 'client-1' : submittedBy as String?;

    return IntakeFormSubmission(
      id: id ?? 'submission-1',
      businessId: businessId ?? TestData.businessId,
      clientId: clientId ?? 'client-1',
      templateId: templateId ?? 'template-1',
      responses: responses ?? {'field-1': 'No major health issues'},
      submittedAt: testDate,
      submittedBy: resolvedSubmittedBy,
    );
  }

  // ====================
  // Analytics
  // ====================

  static AnalyticsMetrics analyticsMetrics({
    String? businessId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final start = startDate ?? testDate;
    final end = endDate ?? testDate.add(const Duration(days: 30));

    return AnalyticsMetrics(
      businessId: businessId ?? TestData.businessId,
      startDate: start,
      endDate: end,
      totalAppointments: 100,
      confirmedAppointments: 80,
      canceledAppointments: 15,
      completedAppointments: 70,
      pendingAppointments: 10,
      noShowAppointments: 5,
      totalRevenueCents: 10000000,
      paidRevenueCents: 9500000,
      pendingRevenueCents: 500000,
      refundedRevenueCents: 0,
      totalClients: 50,
      newClients: 10,
      returningClients: 40,
      activeClients: 45,
      inactiveClients: 5,
      appointmentsByProvider: {'provider-1': 100},
      revenueByProvider: {'provider-1': 10000000},
      appointmentsByService: {'service-1': 100},
      revenueByService: {'service-1': 10000000},
      appointmentsByDayOfWeek: {
        'Monday': 20,
        'Tuesday': 20,
        'Wednesday': 20,
        'Thursday': 20,
        'Friday': 20,
      },
      appointmentsByHourOfDay: {9: 10, 10: 15, 11: 20, 14: 15, 15: 20, 16: 20},
      appointmentsByDate: {'2025-12-01': 5, '2025-12-02': 5, '2025-12-03': 5},
      averageBookingLeadDays: 7.5,
      cancellationRate: 0.15,
      noShowRate: 0.05,
      utilizationRate: 0.75,
    );
  }

  // ====================
  // Session Notes & Files
  // ====================

  static SessionNote sessionNote({
    String? id,
    String? businessId,
    String? appointmentId,
    String? clientId,
    String? providerId,
    SessionNoteType? noteType,
    String? encryptedContent,
    String? title,
    List<String>? tags,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final created = createdAt ?? testDate;
    return SessionNote(
      id: id ?? 'note-1',
      businessId: businessId ?? TestData.businessId,
      appointmentId: appointmentId ?? 'appointment-1',
      clientId: clientId ?? 'client-1',
      providerId: providerId ?? 'provider-1',
      noteType: noteType ?? SessionNoteType.progressNote,
      encryptedContent: encryptedContent ?? 'encrypted-content-base64',
      title: title ?? 'Progress Note',
      tags: tags ?? const ['test'],
      createdAt: created,
      updatedAt: updatedAt ?? created,
      createdBy: createdBy ?? 'user-1',
      createdByName: createdByName ?? 'Test Provider',
    );
  }

  static FileAttachment fileAttachment({
    String? id,
    String? businessId,
    String? clientId,
    String? uploaderId,
    String? name,
    String? storagePath,
    int? sizeBytes,
    String? mimeType,
    FileAccessLevel? accessLevel,
    FileCategory? category,
    DateTime? uploadedAt,
  }) {
    return FileAttachment(
      id: id ?? 'file-1',
      businessId: businessId ?? TestData.businessId,
      clientId: clientId ?? 'client-1',
      uploaderId: uploaderId ?? 'user-1',
      name: name ?? 'test-file.pdf',
      storagePath: storagePath ?? 'businesses/test-business-1/clients/client-1/files/file-1.pdf',
      sizeBytes: sizeBytes ?? 1024,
      contentType: mimeType ?? 'application/pdf',
      accessLevel: accessLevel ?? FileAccessLevel.clientOnly,
      category: category ?? FileCategory.general,
      uploadedAt: uploadedAt ?? testDate,
    );
  }

  // ====================
  // Magic Links
  // ====================

  static MagicLinkToken magicLinkToken({
    String? id,
    String? businessId,
    String? appointmentId,
    String? clientId,
    String? clientEmail,
    String? token,
    DateTime? expiresAt,
    MagicLinkTokenStatus? status,
    int? accessCount,
    bool? hasBeenUsed,
    DateTime? lastAccessedAt,
    DateTime? createdAt,
  }) {
    final created = createdAt ?? testDate;
    return MagicLinkToken(
      id: id ?? 'token-1',
      businessId: businessId ?? TestData.businessId,
      appointmentId: appointmentId ?? 'appointment-1',
      clientId: clientId ?? 'client-1',
      clientEmail: clientEmail ?? 'client@example.com',
      token: token ?? 'test-token-${DateTime.now().millisecondsSinceEpoch}',
      expiresAt: expiresAt ?? created.add(const Duration(hours: 48)),
      status: status ?? MagicLinkTokenStatus.active,
      accessCount: accessCount ?? 0,
      hasBeenUsed: hasBeenUsed ?? false,
      lastAccessedAt: lastAccessedAt,
      createdAt: created,
    );
  }

  // ====================
  // Waitlist
  // ====================

  static WaitlistEntry waitlistEntry({
    String? id,
    String? businessId,
    String? clientId,
    String? clientName,
    String? clientEmail,
    String? clientPhone,
    String? serviceId,
    String? providerId,
    DateTime? earliestDate,
    DateTime? latestDate,
    List<int>? preferredDaysOfWeek,
    List<TimeOfDayPreference>? preferredTimesOfDay,
    NotificationPreference? notificationPreference,
    WaitlistStatus? status,
    double? priorityScore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final created = createdAt ?? testDate;
    return WaitlistEntry(
      id: id ?? 'waitlist-1',
      businessId: businessId ?? TestData.businessId,
      clientId: clientId ?? 'client-1',
      clientName: clientName ?? 'John Doe',
      clientEmail: clientEmail ?? 'john.doe@example.com',
      clientPhone: clientPhone ?? '555-123-4567',
      serviceId: serviceId ?? 'service-1',
      providerId: providerId,
      earliestDate: earliestDate ?? testDate,
      latestDate: latestDate ?? testDate.add(const Duration(days: 30)),
      preferredDaysOfWeek: preferredDaysOfWeek ?? const [1, 3, 5],
      timeOfDayPreferences: preferredTimesOfDay ?? const [TimeOfDayPreference.anytime],
      notificationPreference: notificationPreference ?? NotificationPreference.email,
      status: status ?? WaitlistStatus.active,
      priorityScore: priorityScore ?? 0.5,
      createdAt: created,
      updatedAt: updatedAt ?? created,
    );
  }

  // ====================
  // Gift Cards
  // ====================

  static GiftCard giftCard({
    String? id,
    String? businessId,
    String? code,
    int? originalAmountCents,
    int? remainingBalanceCents,
    GiftCardStatus? status,
    String? recipientName,
    String? recipientEmail,
    String? senderName,
    String? message,
    String? purchaserEmail,
    String? purchaserName,
    String? paymentId,
    DateTime? expiresAt,
    DateTime? activatedAt,
    DateTime? createdAt,
  }) {
    final purchasedAt = createdAt ?? testDate;
    return GiftCard(
      id: id ?? 'giftcard-1',
      businessId: businessId ?? TestData.businessId,
      code: code ?? 'GC-TEST-1234',
      originalAmountCents: originalAmountCents ?? 10000,
      remainingBalanceCents: remainingBalanceCents ?? 10000,
      status: status ?? GiftCardStatus.active,
      purchaserEmail: purchaserEmail ?? 'john.doe@example.com',
      purchaserName: purchaserName ?? 'John Doe',
      purchasedAt: purchasedAt,
      createdAt: purchasedAt,
      paymentId: paymentId,
      recipientName: recipientName ?? 'Jane Doe',
      recipientEmail: recipientEmail ?? 'jane.doe@example.com',
      personalMessage: message,
      expiresAt: expiresAt,
      activatedAt: activatedAt ?? purchasedAt,
    );
  }

  // ====================
  // Staff Onboarding
  // ====================

  static JoinCode joinCode({
    String? id,
    String? businessId,
    String? codeHash,
    String? createdBy,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? maxUses,
    int? uses,
    String? role,
    JoinCodeStatus? status,
    DateTime? lastUsedAt,
    String? lastUsedBy,
    String? notes,
  }) {
    final created = createdAt ?? testDate;
    return JoinCode(
      id: id ?? 'joincode-1',
      businessId: businessId ?? TestData.businessId,
      codeHash: codeHash ?? 'sha256-hash-abc123',
      createdBy: createdBy ?? 'admin-1',
      createdAt: created,
      expiresAt: expiresAt ?? created.add(const Duration(days: 7)),
      maxUses: maxUses ?? 5,
      uses: uses ?? 0,
      role: role ?? 'staff',
      status: status ?? JoinCodeStatus.active,
      lastUsedAt: lastUsedAt,
      lastUsedBy: lastUsedBy,
      notes: notes,
    );
  }

  static Invite invite({
    String? id,
    String? businessId,
    String? email,
    String? role,
    String? tokenHash,
    String? createdBy,
    DateTime? createdAt,
    DateTime? expiresAt,
    InviteStatus? status,
    DateTime? acceptedAt,
    String? acceptedBy,
    String? notes,
  }) {
    final created = createdAt ?? testDate;
    return Invite(
      id: id ?? 'invite-1',
      businessId: businessId ?? TestData.businessId,
      email: email ?? 'newstaff@example.com',
      role: role ?? 'staff',
      tokenHash: tokenHash ?? 'sha256-token-hash-xyz789',
      createdBy: createdBy ?? 'admin-1',
      createdAt: created,
      expiresAt: expiresAt ?? created.add(const Duration(days: 7)),
      status: status ?? InviteStatus.pending,
      acceptedAt: acceptedAt,
      acceptedBy: acceptedBy,
      notes: notes,
    );
  }

  // ====================
  // Lists of Test Data
  // ====================

  /// Creates a list of test clients
  static List<Client> clients({int count = 5, String? businessId}) {
    return List.generate(
      count,
      (index) => client(
        id: 'client-${index + 1}',
        businessId: businessId,
        firstName: 'Client',
        lastName: '${index + 1}',
        email: 'client${index + 1}@example.com',
      ),
    );
  }

  /// Creates a list of test providers
  static List<Provider> providers({int count = 3, String? businessId}) {
    return List.generate(
      count,
      (index) => provider(
        id: 'provider-${index + 1}',
        businessId: businessId,
        firstName: 'Provider',
        lastName: '${index + 1}',
        email: 'provider${index + 1}@example.com',
      ),
    );
  }

  /// Creates a list of test appointments
  static List<Appointment> appointments({
    int count = 10,
    String? businessId,
    String? providerId,
    String? clientId,
  }) {
    return List.generate(
      count,
      (index) => appointment(
        id: 'appointment-${index + 1}',
        businessId: businessId,
        providerId: providerId,
        clientId: clientId,
        startTime: testDate.add(Duration(days: index)),
        endTime: testDate.add(Duration(days: index, hours: 1)),
      ),
    );
  }
}
