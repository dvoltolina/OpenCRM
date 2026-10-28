import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/security_context.dart';
import '../models/service.dart';
import 'business_collection_repository.dart';

/// Repository for managing services with multi-tenant isolation.
/// Only admins can manage services.
class ServicesRepository extends BusinessCollectionRepository<Service> {
  ServicesRepository({super.firestore});

  @override
  String get collectionName => 'services';

  @override
  String get defaultOrderBy => 'name';

  @override
  Service fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Missing service data for ${doc.id}');
    }
    return Service.fromJson({'id': doc.id, ...data});
  }

  @override
  Map<String, dynamic> toMap(Service model) => model.toJson();

  @override
  String getId(Service model) => model.id;

  @override
  void authorizeWrite(SecurityContext context, Service model) {
    context.verifyBusinessAccess(model.businessId);
    if (!context.role.canManageProviders) {
      throw SecurityException('Insufficient permissions to modify services');
    }
  }

  @override
  void authorizeDelete(SecurityContext context) {
    if (!context.role.canManageProviders) {
      throw SecurityException('Insufficient permissions to delete services');
    }
    super.authorizeDelete(context);
  }

  /// Backwards-compatible API
  Future<void> upsertService({
    required SecurityContext context,
    required Service service,
  }) =>
      upsert(context: context, model: service);

  Stream<List<Service>> watchServices(SecurityContext context) =>
      watchAll(context);

  Future<List<Service>> getServices({
    required SecurityContext context,
  }) =>
      getAll(context: context);

  Future<Service?> getService({
    required SecurityContext context,
    required String serviceId,
  }) =>
      getById(context: context, id: serviceId);

  Future<void> deleteService({
    required SecurityContext context,
    required String serviceId,
  }) =>
      delete(context: context, id: serviceId);
}
