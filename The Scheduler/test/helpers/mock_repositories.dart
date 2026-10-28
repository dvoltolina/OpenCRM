// Mock Repository Implementations
//
// Provides in-memory mock implementations of repositories for testing.
// These mocks allow testing business logic without Firebase dependencies.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:the_scheduler/core/services/recurrence_service.dart';
import 'package:the_scheduler/data/models/appointment.dart';
import 'package:the_scheduler/data/models/availability.dart';
import 'package:the_scheduler/data/models/client.dart';
import 'package:the_scheduler/data/models/location.dart';
import 'package:the_scheduler/data/models/payment.dart';
import 'package:the_scheduler/data/models/provider.dart';
import 'package:the_scheduler/data/models/resource.dart';
import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/data/models/service.dart';
import 'package:the_scheduler/data/models/subscription.dart';
import 'package:the_scheduler/data/models/audit_log.dart';
import 'package:the_scheduler/data/repositories/appointments_repository.dart';
import 'package:the_scheduler/data/repositories/audit_log_repository.dart';
import 'package:the_scheduler/data/repositories/availability_repository.dart';
import 'package:the_scheduler/data/repositories/clients_repository.dart';
import 'package:the_scheduler/data/repositories/group_attendees_repository.dart';
import 'package:the_scheduler/data/repositories/locations_repository.dart';
import 'package:the_scheduler/data/repositories/providers_repository.dart';
import 'package:the_scheduler/data/repositories/resources_repository.dart';
import 'package:the_scheduler/data/repositories/services_repository.dart';
import 'package:the_scheduler/data/repositories/subscription_repository.dart';

// ====================
// Audit Log Repository Mock
// ====================

/// Mock audit log repository for testing (no-op implementation).
class MockAuditLogRepository extends AuditLogRepository {
  MockAuditLogRepository() : super(firestore: FakeFirebaseFirestore());

  final List<AuditLogEntry> loggedEvents = [];

  @override
  Future<void> logEvent(AuditLogEntry entry) async {
    loggedEvents.add(entry);
  }
}

// ====================
// Appointments Repository Mock
// ====================

class MockAppointmentsRepository extends AppointmentsRepository {
  factory MockAppointmentsRepository() {
    final firestore = FakeFirebaseFirestore();
    return MockAppointmentsRepository._(firestore);
  }

  MockAppointmentsRepository._(FakeFirebaseFirestore firestore)
      : super(
          firestore: firestore,
          recurrenceService: RecurrenceService(firestore: firestore),
          groupAttendeesRepository: GroupAttendeesRepository(
            firestore: firestore,
            auditLogRepository: AuditLogRepository(firestore: firestore),
          ),
          auditLogRepository: MockAuditLogRepository(),
        );

  final List<Appointment> _appointments = [];

  @override
  Future<void> upsertAppointment({
    required SecurityContext context,
    required Appointment appointment,
  }) async {
    // Validate security
    if (appointment.businessId != context.businessId) {
      throw SecurityException('Business ID mismatch');
    }

    // Remove existing if updating
    _appointments.removeWhere((a) => a.id == appointment.id);

    // Add new/updated appointment
    _appointments.add(appointment);
  }

  @override
  Future<List<Appointment>> loadAppointmentsInRange({
    required SecurityContext context,
    required DateTime start,
    required DateTime end,
    String? providerId,
    String? clientId,
    String? locationId,
  }) async {
    return _appointments.where((appointment) {
      // Business ID filter
      if (appointment.businessId != context.businessId) return false;

      // Date range filter
      if (appointment.startTime.isBefore(start) ||
          appointment.startTime.isAfter(end)) {
        return false;
      }

      // Optional filters
      if (providerId != null && appointment.providerId != providerId) {
        return false;
      }
      if (clientId != null && appointment.clientId != clientId) {
        return false;
      }
      if (locationId != null && appointment.locationId != locationId) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Future<List<Appointment>> getAppointmentsForDate({
    required SecurityContext context,
    required String providerId,
    required DateTime date,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return loadAppointmentsInRange(
      context: context,
      start: startOfDay,
      end: endOfDay,
      providerId: providerId,
    );
  }

  @override
  Stream<List<Appointment>> watchAppointmentsInRange({
    required SecurityContext context,
    required DateTime start,
    required DateTime end,
    String? providerId,
    String? clientId,
    String? locationId,
  }) async* {
    yield await loadAppointmentsInRange(
      context: context,
      start: start,
      end: end,
      providerId: providerId,
      clientId: clientId,
      locationId: locationId,
    );
  }

  // Helper methods for testing
  void addAppointment(Appointment appointment) {
    _appointments.add(appointment);
  }

  void clear() {
    _appointments.clear();
  }

  int get count => _appointments.length;
}

// ====================
// Clients Repository Mock
// ====================

class MockClientsRepository extends ClientsRepository {
  MockClientsRepository()
      : super(
          firestore: FakeFirebaseFirestore(),
          auditLogRepository: MockAuditLogRepository(),
        );

  final Map<String, Client> _clients = {};

  @override
  Future<Client?> getClient({
    required SecurityContext context,
    required String clientId,
    bool allowSalesRead = false,
  }) async {
    final client = _clients[clientId];
    if (client != null && client.businessId != context.businessId) {
      throw SecurityException('Business ID mismatch');
    }
    return client;
  }

  @override
  Future<List<Client>> getClients(
    SecurityContext context, {
    int limit = 100,
    String? startAfterId,
    bool allowSalesRead = false,
  }) async {
    return _clients.values
        .where((c) => c.businessId == context.businessId)
        .take(limit)
        .toList();
  }

  @override
  Future<void> upsertClient({
    required SecurityContext context,
    required Client client,
  }) async {
    if (client.businessId != context.businessId) {
      throw SecurityException('Business ID mismatch');
    }
    _clients[client.id] = client;
  }

  @override
  Future<void> deleteClient({
    required SecurityContext context,
    required String clientId,
  }) async {
    final client = _clients[clientId];
    if (client != null && client.businessId != context.businessId) {
      throw SecurityException('Business ID mismatch');
    }
    _clients.remove(clientId);
  }

  // Helper methods for testing
  void addClient(Client client) {
    _clients[client.id] = client;
  }

  void clear() {
    _clients.clear();
  }

  int get count => _clients.length;
}

// ====================
// Providers Repository Mock
// ====================

class MockProvidersRepository extends ProvidersRepository {
  MockProvidersRepository()
      : super(
          firestore: FakeFirebaseFirestore(),
          auditLogRepository: MockAuditLogRepository(),
        );

  final Map<String, Provider> _providers = {};

  @override
  Future<Provider?> getProvider({
    required SecurityContext context,
    required String providerId,
  }) async {
    final provider = _providers[providerId];
    if (provider != null && provider.businessId != context.businessId) {
      throw SecurityException('Business ID mismatch');
    }
    return provider;
  }

  @override
  Stream<List<Provider>> watchProviders(
    SecurityContext context, {
    String? locationId,
  }) async* {
    var providers = _providers.values
        .where((p) => p.businessId == context.businessId)
        .toList();

    if (locationId != null) {
      providers = providers
          .where((p) => p.locationIds.contains(locationId))
          .toList();
    }

    yield providers;
  }

  @override
  Future<void> upsertProvider({
    required SecurityContext context,
    required Provider provider,
  }) async {
    if (provider.businessId != context.businessId) {
      throw SecurityException('Business ID mismatch');
    }
    if (context.role == UserRole.staff) {
      if (context.providerId != provider.id) {
        throw SecurityException('Staff cannot create providers');
      }
      if (!_providers.containsKey(provider.id)) {
        throw SecurityException('Staff cannot create providers');
      }
    }
    _providers[provider.id] = provider;
  }

  @override
  Future<void> deleteProvider({
    required SecurityContext context,
    required String providerId,
  }) async {
    final provider = _providers[providerId];
    if (provider != null && provider.businessId != context.businessId) {
      throw SecurityException('Business ID mismatch');
    }
    if (context.role == UserRole.staff) {
      throw SecurityException('Staff cannot delete providers');
    }
    _providers.remove(providerId);
  }

  // Helper methods for testing
  void addProvider(Provider provider) {
    _providers[provider.id] = provider;
  }

  void clear() {
    _providers.clear();
  }

  int get count => _providers.length;
}

// ====================
// Services Repository Mock
// ====================

class MockServicesRepository extends ServicesRepository {
  MockServicesRepository() : super(firestore: FakeFirebaseFirestore());

  final Map<String, Service> _services = {};

  @override
  Future<Service?> getService({
    required SecurityContext context,
    required String serviceId,
  }) async {
    final service = _services[serviceId];
    if (service != null && service.businessId != context.businessId) {
      throw SecurityException('Business ID mismatch');
    }
    return service;
  }

  @override
  Stream<List<Service>> watchServices(
    SecurityContext context, {
    String? category,
    String? providerId,
  }) async* {
    var services = _services.values
        .where((s) => s.businessId == context.businessId)
        .toList();

    if (category != null) {
      services = services.where((s) => s.category == category).toList();
    }

    if (providerId != null) {
      services = services
          .where((s) => s.providerIds.contains(providerId))
          .toList();
    }

    yield services;
  }

  @override
  Future<void> upsertService({
    required SecurityContext context,
    required Service service,
  }) async {
    if (service.businessId != context.businessId) {
      throw SecurityException('Business ID mismatch');
    }
    if (context.role == UserRole.staff) {
      throw SecurityException('Staff cannot create services');
    }
    _services[service.id] = service;
  }

  @override
  Future<void> deleteService({
    required SecurityContext context,
    required String serviceId,
  }) async {
    final service = _services[serviceId];
    if (service != null && service.businessId != context.businessId) {
      throw SecurityException('Business ID mismatch');
    }
    if (context.role == UserRole.staff) {
      throw SecurityException('Staff cannot delete services');
    }
    _services.remove(serviceId);
  }

  // Helper methods for testing
  void addService(Service service) {
    _services[service.id] = service;
  }

  void clear() {
    _services.clear();
  }

  int get count => _services.length;
}

// ====================
// Locations Repository Mock
// ====================

class MockLocationsRepository extends LocationsRepository {
  MockLocationsRepository() : super(firestore: FakeFirebaseFirestore());

  final Map<String, Location> _locations = {};

  @override
  Future<Location?> getLocation({
    required SecurityContext context,
    required String locationId,
  }) async {
    final location = _locations[locationId];
    if (location != null && location.businessId != context.businessId) {
      throw SecurityException('Business ID mismatch');
    }
    return location;
  }

  @override
  Stream<List<Location>> watchLocations(SecurityContext context) async* {
    yield _locations.values
        .where((l) => l.businessId == context.businessId)
        .toList();
  }

  @override
  Future<void> upsertLocation({
    required SecurityContext context,
    required Location location,
  }) async {
    if (location.businessId != context.businessId) {
      throw SecurityException('Business ID mismatch');
    }
    if (context.role == UserRole.staff) {
      throw SecurityException('Staff cannot create locations');
    }
    _locations[location.id] = location;
  }

  @override
  Future<void> deleteLocation({
    required SecurityContext context,
    required String locationId,
  }) async {
    final location = _locations[locationId];
    if (location != null && location.businessId != context.businessId) {
      throw SecurityException('Business ID mismatch');
    }
    if (context.role == UserRole.staff) {
      throw SecurityException('Staff cannot delete locations');
    }
    _locations.remove(locationId);
  }

  // Helper methods for testing
  void addLocation(Location location) {
    _locations[location.id] = location;
  }

  void clear() {
    _locations.clear();
  }

  int get count => _locations.length;
}

// ====================
// Availability Repository Mock
// ====================

class MockAvailabilityRepository implements AvailabilityRepository {
  final Map<String, WeeklySchedule> _weeklySchedules = {};
  final List<Availability> _availabilities = [];

  @override
  Stream<List<WeeklySchedule>> watchWeeklySchedules(
    SecurityContext context,
    String providerId, {
    String? locationId,
  }) async* {
    yield _weeklySchedules.values
        .where(
          (s) =>
              s.providerId == providerId &&
              (locationId == null || s.locationId == locationId),
        )
        .toList();
  }

  @override
  Stream<List<Availability>> watchAvailability(
    SecurityContext context,
    String providerId,
    DateTime startDate,
    DateTime endDate, {
    String? locationId,
  }) async* {
    yield _availabilities
        .where((a) =>
            a.providerId == providerId &&
            (locationId == null || a.locationId == locationId) &&
            a.startTime.isAfter(startDate) &&
            a.startTime.isBefore(endDate))
        .toList();
  }

  @override
  Future<WeeklySchedule?> getWeeklySchedule(
    SecurityContext context,
    String providerId,
    DayOfWeek dayOfWeek, {
    String? locationId,
  }) async {
    for (final schedule in _weeklySchedules.values) {
      final matchesProvider = schedule.providerId == providerId;
      final matchesDay = schedule.dayOfWeek == dayOfWeek;
      final matchesLocation =
          locationId == null || schedule.locationId == locationId;
      if (matchesProvider && matchesDay && matchesLocation) {
        return schedule;
      }
    }
    return null;
  }

  @override
  Future<List<Availability>> getAvailabilityForDate(
    SecurityContext context,
    String providerId,
    DateTime date, {
    String? locationId,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _availabilities
        .where((a) =>
            a.providerId == providerId &&
            (locationId == null || a.locationId == locationId) &&
            a.startTime.isAfter(startOfDay) &&
            a.startTime.isBefore(endOfDay))
        .toList();
  }

  @override
  Future<void> upsertWeeklySchedule(
    SecurityContext context,
    WeeklySchedule schedule,
  ) async {
    // No businessId check needed - isolation handled at provider level
    _weeklySchedules[schedule.id] = schedule;
  }

  @override
  Future<void> upsertAvailability(
    SecurityContext context,
    Availability availability,
  ) async {
    // No businessId check needed - isolation handled at provider level
    _availabilities
        .removeWhere((a) => a.id == availability.id);
    _availabilities.add(availability);
  }

  @override
  Future<void> deleteWeeklySchedule(
    SecurityContext context,
    String scheduleId,
  ) async {
    // No businessId check needed - isolation handled at provider level
    _weeklySchedules.remove(scheduleId);
  }

  @override
  Future<void> deleteAvailability(
    SecurityContext context,
    String availabilityId,
  ) async {
    // No businessId check needed - isolation handled at provider level
    _availabilities.removeWhere((a) => a.id == availabilityId);
  }

  @override
  Future<void> batchCreateWeeklySchedules(
    SecurityContext context,
    List<WeeklySchedule> schedules,
  ) async {
    for (final schedule in schedules) {
      await upsertWeeklySchedule(context, schedule);
    }
  }

  // Helper methods for testing
  void addWeeklySchedule(WeeklySchedule schedule) {
    _weeklySchedules[schedule.id] = schedule;
  }

  void addAvailability(Availability availability) {
    _availabilities.add(availability);
  }

  void clear() {
    _weeklySchedules.clear();
    _availabilities.clear();
  }

  int get weeklyScheduleCount => _weeklySchedules.length;
  int get availabilityCount => _availabilities.length;
}

// ====================
// Subscription Repository Mock
// ====================

class MockSubscriptionRepository implements SubscriptionRepository {
  final Map<String, Subscription> _subscriptions = {};

  @override
  Stream<Subscription?> watchSubscription(SecurityContext context) async* {
    yield _subscriptions.values
        .where((s) => s.businessId == context.businessId)
        .firstOrNull;
  }

  @override
  Future<Subscription?> getSubscription(SecurityContext context) async {
    return _subscriptions.values
        .where((s) => s.businessId == context.businessId)
        .firstOrNull;
  }

  Future<Subscription?> getSubscriptionById(
    SecurityContext context,
    String subscriptionId,
  ) async {
    final subscription = _subscriptions[subscriptionId];
    if (subscription != null &&
        subscription.businessId != context.businessId) {
      throw SecurityException('Business ID mismatch');
    }
    return subscription;
  }

  @override
  Future<void> upsertSubscription(
    SecurityContext context,
    Subscription subscription,
  ) async {
    if (subscription.businessId != context.businessId) {
      throw SecurityException('Business ID mismatch');
    }
    // Only owner can modify subscriptions
    if (!context.role.canManageBusiness) {
      throw SecurityException('Only owners can modify subscriptions');
    }
    _subscriptions[subscription.id] = subscription;
  }

  @override
  Future<void> updateSubscriptionStatus(
    SecurityContext context,
    String subscriptionId,
    SubscriptionStatus status,
  ) async {
    final subscription = _subscriptions[subscriptionId];
    if (subscription != null) {
      _subscriptions[subscriptionId] = subscription.copyWith(status: status);
    }
  }

  @override
  Future<void> cancelSubscription(
    SecurityContext context,
    String subscriptionId,
  ) async {
    if (!context.role.canManageBusiness) {
      throw SecurityException('Only owners can cancel subscriptions');
    }
    final subscription = _subscriptions[subscriptionId];
    if (subscription != null) {
      _subscriptions[subscriptionId] =
          subscription.copyWith(cancelAtPeriodEnd: true);
    }
  }

  @override
  Future<void> reactivateSubscription(
    SecurityContext context,
    String subscriptionId,
  ) async {
    final subscription = _subscriptions[subscriptionId];
    if (subscription != null) {
      _subscriptions[subscriptionId] =
          subscription.copyWith(cancelAtPeriodEnd: false);
    }
  }

  @override
  Future<Map<String, int>> getUsageStats(SecurityContext context) async {
    return {
      'providers': 0,
      'locations': 0,
      'appointments': 0,
      'sms': 0,
    };
  }

  Future<void> deleteSubscription(
    SecurityContext context,
    String subscriptionId,
  ) async {
    if (!context.role.canManageBusiness) {
      throw SecurityException('Only owners can delete subscriptions');
    }
    _subscriptions.remove(subscriptionId);
  }

  // Helper methods for testing
  void addSubscription(Subscription subscription) {
    _subscriptions[subscription.id] = subscription;
  }

  void clear() {
    _subscriptions.clear();
  }

  int get count => _subscriptions.length;
}

// ====================
// Resources Repository Mock
// ====================

class MockResourcesRepository extends ResourcesRepository {
  MockResourcesRepository() : super(firestore: FakeFirebaseFirestore());

  final Map<String, Resource> _resources = {};

  @override
  Stream<List<Resource>> watchResources(SecurityContext context) async* {
    yield _resources.values
        .where((r) => r.businessId == context.businessId)
        .toList();
  }

  @override
  Stream<List<Resource>> watchResourcesByLocation({
    required SecurityContext context,
    required String locationId,
  }) async* {
    yield _resources.values
        .where((r) =>
            r.businessId == context.businessId && r.locationId == locationId)
        .toList();
  }

  @override
  Future<Resource?> getResource({
    required SecurityContext context,
    required String resourceId,
  }) async {
    final resource = _resources[resourceId];
    if (resource != null && resource.businessId != context.businessId) {
      throw SecurityException('Business ID mismatch');
    }
    return resource;
  }

  @override
  Future<void> upsertResource({
    required SecurityContext context,
    required Resource resource,
  }) async {
    if (resource.businessId != context.businessId) {
      throw SecurityException('Business ID mismatch');
    }
    if (!context.role.canManageProviders) {
      throw SecurityException('Insufficient permissions to modify resources');
    }
    _resources[resource.id] = resource;
  }

  @override
  Future<void> deleteResource({
    required SecurityContext context,
    required String resourceId,
  }) async {
    if (!context.role.canManageProviders) {
      throw SecurityException('Insufficient permissions to delete resources');
    }
    final resource = _resources[resourceId];
    if (resource != null && resource.businessId != context.businessId) {
      throw SecurityException('Business ID mismatch');
    }
    _resources.remove(resourceId);
  }

  // Helper methods for testing
  void addResource(Resource resource) {
    _resources[resource.id] = resource;
  }

  void clear() {
    _resources.clear();
  }

  int get count => _resources.length;
}

// ====================
// Payment Repository Mock
// ====================

class MockPaymentRepository {
  final Map<String, Payment> _payments = {};
  int _autoId = 0;

  Future<void> upsertPayment(
    SecurityContext context,
    Payment payment,
  ) async {
    if (payment.businessId != context.businessId) {
      throw SecurityException('Business ID mismatch');
    }
    if (context.role == UserRole.client) {
      throw SecurityException('Clients cannot create payments');
    }
    _payments[payment.id] = payment;
  }

  Future<Payment?> getPayment(
    SecurityContext context,
    String paymentId,
  ) async {
    final payment = _payments[paymentId];
    if (payment != null && payment.businessId != context.businessId) {
      throw SecurityException('Business ID mismatch');
    }
    return payment;
  }

  Stream<List<Payment>> watchPaymentsForClient(
    SecurityContext context,
    String clientId,
  ) async* {
    yield _payments.values
        .where((p) =>
            p.businessId == context.businessId && p.clientId == clientId)
        .toList();
  }

  Stream<List<Payment>> watchPaymentsForAppointment(
    SecurityContext context,
    String appointmentId,
  ) async* {
    yield _payments.values
        .where((p) =>
            p.businessId == context.businessId &&
            p.appointmentId == appointmentId)
        .toList();
  }

  Future<void> deletePayment(
    SecurityContext context,
    String paymentId,
  ) async {
    final payment = _payments[paymentId];
    if (payment != null && payment.businessId != context.businessId) {
      throw SecurityException('Business ID mismatch');
    }
    _payments.remove(paymentId);
  }

  // Helper methods for testing
  void addPayment(Payment payment) {
    final id = payment.id.isEmpty ? 'payment-${++_autoId}' : payment.id;
    _payments[id] = payment.copyWith(id: id);
  }

  void clear() {
    _payments.clear();
  }

  int get count => _payments.length;
}

// NOTE: SecurityException is imported from security_context.dart
// Do not redefine it here to avoid ambiguous imports
