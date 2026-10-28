import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../../data/models/appointment.dart';
import '../../data/models/client.dart';
import '../../data/models/intake_form.dart';
import '../../data/models/location.dart';
import '../../data/models/provider.dart' as provider_model;
import '../../data/models/resource.dart';
import '../../data/models/retail_product.dart';
import '../../data/models/security_context.dart';
import '../../data/models/service.dart';
import '../../data/models/waitlist_entry.dart';
import 'repository_providers.dart';
import 'service_providers.dart';

/// Stream providers for shared reference data used across admin modules.

final servicesStreamProvider =
    riverpod.StreamProvider.autoDispose.family<List<Service>, SecurityContext>(
  (ref, securityContext) {
    final cache = ref.watch(referenceDataCacheProvider);
    return cache.watchServices(securityContext);
  },
);

final providersStreamProvider = riverpod.StreamProvider.autoDispose
    .family<List<provider_model.Provider>, SecurityContext>(
  (ref, securityContext) {
    final cache = ref.watch(referenceDataCacheProvider);
    return cache.watchProviders(securityContext);
  },
);

final locationsStreamProvider =
    riverpod.StreamProvider.autoDispose.family<List<Location>, SecurityContext>(
  (ref, securityContext) {
    final cache = ref.watch(referenceDataCacheProvider);
    return cache.watchLocations(securityContext);
  },
);

final clientsStreamProvider =
    riverpod.StreamProvider.autoDispose.family<List<Client>, SecurityContext>(
  (ref, securityContext) {
    final repository = ref.watch(clientsRepositoryProvider);
    return repository.watchClients(securityContext);
  },
);

final resourcesStreamProvider =
    riverpod.StreamProvider.autoDispose.family<List<Resource>, SecurityContext>(
  (ref, securityContext) {
    final repository = ref.watch(resourcesRepositoryProvider);
    return repository.watchResources(securityContext);
  },
);

final intakeFormsStreamProvider = riverpod.StreamProvider.autoDispose
    .family<List<IntakeFormTemplate>, SecurityContext>(
  (ref, securityContext) {
    final repository = ref.watch(intakeFormRepositoryProvider);
    return repository.watchTemplates(securityContext);
  },
);

/// Filter parameters for waitlist stream queries.
class WaitlistFilter {
  const WaitlistFilter({
    required this.securityContext,
    this.serviceId,
    this.providerId,
    this.status,
  });

  final SecurityContext securityContext;
  final String? serviceId;
  final String? providerId;
  final WaitlistStatus? status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WaitlistFilter &&
          runtimeType == other.runtimeType &&
          securityContext == other.securityContext &&
          serviceId == other.serviceId &&
          providerId == other.providerId &&
          status == other.status;

  @override
  int get hashCode => Object.hash(securityContext, serviceId, providerId, status);
}

/// Stream provider for waitlist entries with optional filters.
///
/// Usage:
/// ```dart
/// final filter = WaitlistFilter(
///   securityContext: ctx,
///   serviceId: selectedService?.id,
///   status: WaitlistStatus.active,
/// );
/// final entriesAsync = ref.watch(waitlistEntriesStreamProvider(filter));
/// ```
final waitlistEntriesStreamProvider = riverpod.StreamProvider.autoDispose
    .family<List<WaitlistEntry>, WaitlistFilter>(
  (ref, filter) {
    final repository = ref.watch(waitlistRepositoryProvider);
    return repository.watchEntries(
      context: filter.securityContext,
      serviceId: filter.serviceId,
      providerId: filter.providerId,
      status: filter.status,
    );
  },
);

/// Filter parameters for appointment range queries (calendar view).
class AppointmentRangeFilter {
  const AppointmentRangeFilter({
    required this.securityContext,
    required this.start,
    required this.end,
    this.providerId,
    this.clientId,
    this.locationId,
  });

  final SecurityContext securityContext;
  final DateTime start;
  final DateTime end;
  final String? providerId;
  final String? clientId;
  final String? locationId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentRangeFilter &&
          runtimeType == other.runtimeType &&
          securityContext == other.securityContext &&
          start == other.start &&
          end == other.end &&
          providerId == other.providerId &&
          clientId == other.clientId &&
          locationId == other.locationId;

  @override
  int get hashCode => Object.hash(securityContext, start, end, providerId, clientId, locationId);
}

/// Stream provider for appointments within a date range.
///
/// Usage:
/// ```dart
/// final filter = AppointmentRangeFilter(
///   securityContext: ctx,
///   start: DateTime(2025, 1, 1),
///   end: DateTime(2025, 1, 31),
///   providerId: selectedProviderId,
/// );
/// final appointmentsAsync = ref.watch(appointmentsInRangeProvider(filter));
/// ```
final appointmentsInRangeProvider = riverpod.StreamProvider.autoDispose
    .family<List<Appointment>, AppointmentRangeFilter>(
  (ref, filter) {
    final repository = ref.watch(appointmentsRepositoryProvider);
    return repository.watchAppointmentsInRange(
      context: filter.securityContext,
      start: filter.start,
      end: filter.end,
      providerId: filter.providerId,
      clientId: filter.clientId,
      locationId: filter.locationId,
    );
  },
);

// ============================================================
// POS Product Providers (Agent FC-J)
// ============================================================

/// Filter for products list with optional category filter.
class ProductFilter {
  const ProductFilter({
    required this.securityContext,
    this.category,
    this.availableForSale,
  });

  final SecurityContext securityContext;
  final ProductCategory? category;
  final bool? availableForSale;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductFilter &&
          runtimeType == other.runtimeType &&
          securityContext == other.securityContext &&
          category == other.category &&
          availableForSale == other.availableForSale;

  @override
  int get hashCode => Object.hash(securityContext, category, availableForSale);
}

/// Stream provider for retail products.
///
/// Usage:
/// ```dart
/// final filter = ProductFilter(
///   securityContext: ctx,
///   category: ProductCategory.skincare,
/// );
/// final productsAsync = ref.watch(productsStreamProvider(filter));
/// ```
final productsStreamProvider = riverpod.StreamProvider.autoDispose
    .family<List<RetailProduct>, ProductFilter>(
  (ref, filter) {
    final repository = ref.watch(productRepositoryProvider);
    return repository.watchProducts(
      filter.securityContext,
      category: filter.category,
      availableForSale: filter.availableForSale,
    );
  },
);
