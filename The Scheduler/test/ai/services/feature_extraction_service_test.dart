@Tags(['ai'])
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:the_scheduler/data/models/appointment.dart';
import 'package:the_scheduler/data/models/client.dart';
import 'package:the_scheduler/data/models/payment.dart';
import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/data/models/service.dart';
import 'package:the_scheduler/data/models/user_role.dart';
import 'package:the_scheduler/data/repositories/appointments_repository.dart';
import 'package:the_scheduler/data/repositories/clients_repository.dart';
import 'package:the_scheduler/data/repositories/payment_repository.dart';
import 'package:the_scheduler/data/repositories/services_repository.dart';
import 'package:the_scheduler/ai/models/prediction_features.dart';
import 'package:the_scheduler/ai/services/feature_extraction_service.dart';

@GenerateMocks([
  AppointmentsRepository,
  ClientsRepository,
  PaymentRepository,
  ServicesRepository,
])
import 'feature_extraction_service_test.mocks.dart';

void main() {
  late FeatureExtractionService service;
  late MockAppointmentsRepository mockAppointmentsRepo;
  late MockClientsRepository mockClientsRepo;
  late MockPaymentRepository mockPaymentRepo;
  late MockServicesRepository mockServicesRepo;
  late SecurityContext testContext;

  setUp(() {
    mockAppointmentsRepo = MockAppointmentsRepository();
    mockClientsRepo = MockClientsRepository();
    mockPaymentRepo = MockPaymentRepository();
    mockServicesRepo = MockServicesRepository();

    service = FeatureExtractionService(
      appointmentsRepository: mockAppointmentsRepo,
      clientsRepository: mockClientsRepo,
      servicesRepository: mockServicesRepo,
      paymentRepository: mockPaymentRepo,
    );

    testContext = SecurityContext(
      userId: 'test-user-id',
      businessId: 'test-business-id',
      role: UserRole.admin,
    );
  });

  tearDown(() {
    service.clearCaches();
  });

  group('FeatureExtractionService', () {
    final testAppointment = Appointment(
      id: 'apt-1',
      businessId: 'test-business-id',
      clientId: 'client-1',
      providerId: 'provider-1',
      serviceId: 'service-1',
      locationId: 'location-1',
      startTime: DateTime.now().add(const Duration(days: 7)),
      endTime: DateTime.now().add(const Duration(days: 7, hours: 1)),
      date: DateTime.now().add(const Duration(days: 7)),
      status: AppointmentStatus.confirmed,
      createdAt: DateTime.now(),
      requiresPayment: true,
      paymentStatus: PaymentStatus.completed,
      isRecurring: false,
      isGroupSession: false,
    );

    final testClient = Client(
      id: 'client-1',
      businessId: 'test-business-id',
      firstName: 'John',
      lastName: 'Doe',
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      lifecycle: ClientLifecycle.active,
      hasPaymentMethod: true,
    );

    final testService = Service(
      id: 'service-1',
      businessId: 'test-business-id',
      name: 'Consultation',
      durationMinutes: 60,
      price: 100.0,
      category: 'General',
      createdAt: DateTime.now(),
    );

    final pastCompletedAppointment = Appointment(
      id: 'apt-past-1',
      businessId: 'test-business-id',
      clientId: 'client-1',
      providerId: 'provider-1',
      serviceId: 'service-1',
      locationId: 'location-1',
      startTime: DateTime.now().subtract(const Duration(days: 30)),
      endTime: DateTime.now().subtract(const Duration(days: 30)).add(const Duration(hours: 1)),
      date: DateTime.now().subtract(const Duration(days: 30)),
      status: AppointmentStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    );

    final pastNoshowAppointment = Appointment(
      id: 'apt-past-2',
      businessId: 'test-business-id',
      clientId: 'client-1',
      providerId: 'provider-1',
      serviceId: 'service-1',
      locationId: 'location-1',
      startTime: DateTime.now().subtract(const Duration(days: 60)),
      endTime: DateTime.now().subtract(const Duration(days: 60)).add(const Duration(hours: 1)),
      date: DateTime.now().subtract(const Duration(days: 60)),
      status: AppointmentStatus.noShow,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    );

    void setupDefaultMocks() {
      when(mockClientsRepo.getClient(
        context: anyNamed('context'),
        clientId: anyNamed('clientId'),
      )).thenAnswer((_) async => testClient);

      when(mockAppointmentsRepo.getClientAppointments(
        context: anyNamed('context'),
        clientId: anyNamed('clientId'),
      )).thenAnswer((_) async => [pastCompletedAppointment, pastNoshowAppointment]);

      when(mockPaymentRepo.getClientPayments(
        context: anyNamed('context'),
        clientId: anyNamed('clientId'),
      )).thenAnswer((_) async => [
            Payment(
              id: 'pay-1',
              businessId: 'test-business-id',
              appointmentId: 'apt-past-1',
              clientId: 'client-1',
              amountCents: 10000,
              status: PaymentStatus.completed,
              type: PaymentType.full,
              createdAt: DateTime.now().subtract(const Duration(days: 30)),
            ),
          ]);

      when(mockServicesRepo.getService(
        context: anyNamed('context'),
        serviceId: anyNamed('serviceId'),
      )).thenAnswer((_) async => testService);

      when(mockAppointmentsRepo.loadAppointmentsInRange(
        context: anyNamed('context'),
        start: anyNamed('start'),
        end: anyNamed('end'),
        providerId: anyNamed('providerId'),
        clientId: anyNamed('clientId'),
        locationId: anyNamed('locationId'),
      )).thenAnswer((_) async => [pastCompletedAppointment, pastNoshowAppointment]);

      when(mockAppointmentsRepo.getAppointmentsForDate(
        context: anyNamed('context'),
        providerId: anyNamed('providerId'),
        date: anyNamed('date'),
      )).thenAnswer((_) async => [testAppointment]);
    }

    group('Feature extraction with complete data', () {
      test('extracts all features correctly', () async {
        setupDefaultMocks();

        final features = await service.extractFeatures(
          context: testContext,
          appointment: testAppointment,
        );

        expect(features.appointmentId, equals('apt-1'));
        expect(features.businessId, equals('test-business-id'));
        expect(features.featureSchemaVersion, equals(kFeatureSchemaVersion));
        expect(features.clientHasPaymentMethod, isTrue);
        expect(features.paymentCollected, isTrue);
        expect(features.requiresPayment, isTrue);
        expect(features.isRecurring, isFalse);
        expect(features.isGroupSession, isFalse);
        expect(features.serviceDurationMinutes, equals(60));
        expect(features.servicePriceCents, equals(10000)); // $100 = 10000 cents
        expect(features.dayOfWeek, greaterThanOrEqualTo(1));
        expect(features.dayOfWeek, lessThanOrEqualTo(7));
        expect(features.hourOfDay, greaterThanOrEqualTo(0));
        expect(features.hourOfDay, lessThanOrEqualTo(23));
      });

      test('calculates client noshow rate correctly', () async {
        setupDefaultMocks();

        final features = await service.extractFeatures(
          context: testContext,
          appointment: testAppointment,
        );

        // 1 noshow out of 2 past appointments = 0.5
        expect(features.clientHistoricalNoshowRate, equals(0.5));
      });

      test('calculates lifetime value correctly', () async {
        setupDefaultMocks();

        final features = await service.extractFeatures(
          context: testContext,
          appointment: testAppointment,
        );

        expect(features.clientLifetimeValueCents, equals(10000));
      });

      test('maps lifecycle stage correctly', () async {
        setupDefaultMocks();

        final features = await service.extractFeatures(
          context: testContext,
          appointment: testAppointment,
        );

        expect(features.clientLifecycleStage, equals('active'));
      });
    });

    group('Feature extraction with missing data', () {
      test('handles missing client gracefully', () async {
        when(mockClientsRepo.getClient(
          context: anyNamed('context'),
          clientId: anyNamed('clientId'),
        )).thenAnswer((_) async => null);

        when(mockAppointmentsRepo.getClientAppointments(
          context: anyNamed('context'),
          clientId: anyNamed('clientId'),
        )).thenAnswer((_) async => []);

        when(mockPaymentRepo.getClientPayments(
          context: anyNamed('context'),
          clientId: anyNamed('clientId'),
        )).thenAnswer((_) async => []);

        when(mockServicesRepo.getService(
          context: anyNamed('context'),
          serviceId: anyNamed('serviceId'),
        )).thenAnswer((_) async => testService);

        when(mockAppointmentsRepo.loadAppointmentsInRange(
          context: anyNamed('context'),
          start: anyNamed('start'),
          end: anyNamed('end'),
          providerId: anyNamed('providerId'),
          clientId: anyNamed('clientId'),
          locationId: anyNamed('locationId'),
        )).thenAnswer((_) async => []);

        when(mockAppointmentsRepo.getAppointmentsForDate(
          context: anyNamed('context'),
          providerId: anyNamed('providerId'),
          date: anyNamed('date'),
        )).thenAnswer((_) async => [testAppointment]);

        final features = await service.extractFeatures(
          context: testContext,
          appointment: testAppointment,
        );

        // Should use defaults
        expect(features.clientHasPaymentMethod, isFalse);
        expect(features.clientLifecycleStage, equals('newClient'));
        expect(features.clientHistoricalNoshowRate, equals(0.0));
        expect(features.clientTotalAppointments, equals(0));
      });

      test('handles new client with no history', () async {
        when(mockClientsRepo.getClient(
          context: anyNamed('context'),
          clientId: anyNamed('clientId'),
        )).thenAnswer((_) async => Client(
              id: 'client-new',
              businessId: 'test-business-id',
              firstName: 'New',
              lastName: 'Client',
              createdAt: DateTime.now(),
              lifecycle: ClientLifecycle.newClient,
            ));

        when(mockAppointmentsRepo.getClientAppointments(
          context: anyNamed('context'),
          clientId: anyNamed('clientId'),
        )).thenAnswer((_) async => []);

        when(mockPaymentRepo.getClientPayments(
          context: anyNamed('context'),
          clientId: anyNamed('clientId'),
        )).thenAnswer((_) async => []);

        when(mockServicesRepo.getService(
          context: anyNamed('context'),
          serviceId: anyNamed('serviceId'),
        )).thenAnswer((_) async => testService);

        when(mockAppointmentsRepo.loadAppointmentsInRange(
          context: anyNamed('context'),
          start: anyNamed('start'),
          end: anyNamed('end'),
          providerId: anyNamed('providerId'),
          clientId: anyNamed('clientId'),
          locationId: anyNamed('locationId'),
        )).thenAnswer((_) async => []);

        when(mockAppointmentsRepo.getAppointmentsForDate(
          context: anyNamed('context'),
          providerId: anyNamed('providerId'),
          date: anyNamed('date'),
        )).thenAnswer((_) async => [testAppointment]);

        final features = await service.extractFeatures(
          context: testContext,
          appointment: testAppointment,
        );

        expect(features.clientTotalAppointments, equals(0));
        expect(features.clientHistoricalNoshowRate, equals(0.0));
        expect(features.clientDaysSinceLastVisit, equals(9999)); // New client indicator
      });

      test('sets hasIntakeForm to false (simplified implementation)', () async {
        setupDefaultMocks();

        final features = await service.extractFeatures(
          context: testContext,
          appointment: testAppointment,
        );

        // Current implementation always returns false
        expect(features.hasIntakeForm, isFalse);
      });

      test('handles missing service gracefully', () async {
        setupDefaultMocks();
        when(mockServicesRepo.getService(
          context: anyNamed('context'),
          serviceId: anyNamed('serviceId'),
        )).thenAnswer((_) async => null);

        final features = await service.extractFeatures(
          context: testContext,
          appointment: testAppointment,
        );

        // Should use defaults
        expect(features.serviceDurationMinutes, equals(60)); // Default
        expect(features.servicePriceCents, equals(0)); // Default
      });
    });

    group('Caching behavior', () {
      test('caches client statistics', () async {
        setupDefaultMocks();

        // First call
        await service.extractFeatures(
          context: testContext,
          appointment: testAppointment,
        );

        // Second call - should use cache
        await service.extractFeatures(
          context: testContext,
          appointment: testAppointment,
        );

        // Client should only be fetched once due to caching
        verify(mockClientsRepo.getClient(
          context: anyNamed('context'),
          clientId: anyNamed('clientId'),
        )).called(1);
      });

      test('clearCaches clears all cached data', () async {
        setupDefaultMocks();

        // First call - populates cache
        await service.extractFeatures(
          context: testContext,
          appointment: testAppointment,
        );

        // Clear caches
        service.clearCaches();

        // Second call - should fetch again
        await service.extractFeatures(
          context: testContext,
          appointment: testAppointment,
        );

        // Client should be fetched twice (cache was cleared)
        verify(mockClientsRepo.getClient(
          context: anyNamed('context'),
          clientId: anyNamed('clientId'),
        )).called(2);
      });
    });

    group('Feature validation', () {
      test('features pass validation with correct data', () async {
        setupDefaultMocks();

        final features = await service.extractFeatures(
          context: testContext,
          appointment: testAppointment,
        );

        expect(features.isValid, isTrue);
        expect(features.validate(), isEmpty);
      });
    });

    group('Batch extraction', () {
      test('extracts features for multiple appointments', () async {
        setupDefaultMocks();

        final appointment2 = testAppointment.copyWith(id: 'apt-2');

        final featuresList = await service.extractFeaturesBatch(
          context: testContext,
          appointments: [testAppointment, appointment2],
        );

        expect(featuresList.length, equals(2));
        expect(featuresList[0].appointmentId, equals('apt-1'));
        expect(featuresList[1].appointmentId, equals('apt-2'));
      });

      test('returns empty list for empty input', () async {
        final featuresList = await service.extractFeaturesBatch(
          context: testContext,
          appointments: [],
        );

        expect(featuresList, isEmpty);
      });
    });

    group('Lifecycle stage mapping', () {
      test('maps newClient lifecycle correctly', () async {
        setupDefaultMocks();
        when(mockClientsRepo.getClient(
          context: anyNamed('context'),
          clientId: anyNamed('clientId'),
        )).thenAnswer((_) async => testClient.copyWith(
              lifecycle: ClientLifecycle.newClient,
            ));

        final features = await service.extractFeatures(
          context: testContext,
          appointment: testAppointment,
        );

        expect(features.clientLifecycleStage, equals('newClient'));
      });

      test('maps active lifecycle correctly', () async {
        setupDefaultMocks();

        final features = await service.extractFeatures(
          context: testContext,
          appointment: testAppointment,
        );

        expect(features.clientLifecycleStage, equals('active'));
      });

      test('maps inactive lifecycle correctly', () async {
        setupDefaultMocks();
        when(mockClientsRepo.getClient(
          context: anyNamed('context'),
          clientId: anyNamed('clientId'),
        )).thenAnswer((_) async => testClient.copyWith(
              lifecycle: ClientLifecycle.inactive,
            ));

        final features = await service.extractFeatures(
          context: testContext,
          appointment: testAppointment,
        );

        expect(features.clientLifecycleStage, equals('inactive'));
      });

      test('maps churned lifecycle correctly', () async {
        setupDefaultMocks();
        when(mockClientsRepo.getClient(
          context: anyNamed('context'),
          clientId: anyNamed('clientId'),
        )).thenAnswer((_) async => testClient.copyWith(
              lifecycle: ClientLifecycle.churned,
            ));

        final features = await service.extractFeatures(
          context: testContext,
          appointment: testAppointment,
        );

        expect(features.clientLifecycleStage, equals('churned'));
      });
    });

    group('Day position detection', () {
      test('detects first appointment of day', () async {
        setupDefaultMocks();
        // Make testAppointment the only one, so it's both first and last
        when(mockAppointmentsRepo.getAppointmentsForDate(
          context: anyNamed('context'),
          providerId: anyNamed('providerId'),
          date: anyNamed('date'),
        )).thenAnswer((_) async => [testAppointment]);

        final features = await service.extractFeatures(
          context: testContext,
          appointment: testAppointment,
        );

        expect(features.isFirstAppointmentOfDay, isTrue);
        expect(features.isLastAppointmentOfDay, isTrue);
      });

      test('detects middle appointment correctly', () async {
        setupDefaultMocks();
        final earlierAppointment = testAppointment.copyWith(
          id: 'apt-early',
          startTime: testAppointment.startTime.subtract(const Duration(hours: 2)),
        );
        final laterAppointment = testAppointment.copyWith(
          id: 'apt-late',
          startTime: testAppointment.startTime.add(const Duration(hours: 2)),
        );

        when(mockAppointmentsRepo.getAppointmentsForDate(
          context: anyNamed('context'),
          providerId: anyNamed('providerId'),
          date: anyNamed('date'),
        )).thenAnswer((_) async => [earlierAppointment, testAppointment, laterAppointment]);

        final features = await service.extractFeatures(
          context: testContext,
          appointment: testAppointment,
        );

        expect(features.isFirstAppointmentOfDay, isFalse);
        expect(features.isLastAppointmentOfDay, isFalse);
      });
    });
  });
}
