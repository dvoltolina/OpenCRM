import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/location.dart';
import '../models/security_context.dart';
import 'business_collection_repository.dart';

/// Repository for managing business locations with multi-tenant isolation.
/// Only admins can manage locations.
class LocationsRepository extends BusinessCollectionRepository<Location> {
  LocationsRepository({super.firestore});

  @override
  String get collectionName => 'locations';

  @override
  String get defaultOrderBy => 'name';

  @override
  Location fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Missing location data for ${doc.id}');
    }
    return Location.fromJson({'id': doc.id, ...data});
  }

  @override
  Map<String, dynamic> toMap(Location model) => model.toJson();

  @override
  String getId(Location model) => model.id;

  @override
  void authorizeWrite(SecurityContext context, Location model) {
    context.verifyBusinessAccess(model.businessId);
    if (!context.role.canManageProviders) {
      throw SecurityException('Insufficient permissions to modify locations');
    }
  }

  @override
  void authorizeDelete(SecurityContext context) {
    if (!context.role.canManageProviders) {
      throw SecurityException('Insufficient permissions to delete locations');
    }
    super.authorizeDelete(context);
  }

  /// Backwards-compatible API
  Future<void> upsertLocation({
    required SecurityContext context,
    required Location location,
  }) =>
      upsert(context: context, model: location);

  Stream<List<Location>> watchLocations(SecurityContext context) =>
      watchAll(context);

  Future<List<Location>> getLocations({
    required SecurityContext context,
  }) =>
      getAll(context: context);

  Future<Location?> getLocation({
    required SecurityContext context,
    required String locationId,
  }) =>
      getById(context: context, id: locationId);

  Future<void> deleteLocation({
    required SecurityContext context,
    required String locationId,
  }) =>
      delete(context: context, id: locationId);
}
