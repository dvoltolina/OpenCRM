import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/resource.dart';
import '../models/security_context.dart';
import 'business_collection_repository.dart';

/// Repository for managing resources with multi-tenant isolation.
/// Only admins can manage resources.
class ResourcesRepository extends BusinessCollectionRepository<Resource> {
  ResourcesRepository({super.firestore});

  @override
  String get collectionName => 'resources';

  @override
  String get defaultOrderBy => 'name';

  @override
  Resource fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Missing resource data for ${doc.id}');
    }
    return Resource.fromJson({'id': doc.id, ...data});
  }

  @override
  Map<String, dynamic> toMap(Resource model) => model.toJson();

  @override
  String getId(Resource model) => model.id;

  @override
  void authorizeWrite(SecurityContext context, Resource model) {
    context.verifyBusinessAccess(model.businessId);
    if (!context.role.canManageProviders) {
      throw SecurityException('Insufficient permissions to modify resources');
    }
  }

  @override
  void authorizeDelete(SecurityContext context) {
    if (!context.role.canManageProviders) {
      throw SecurityException('Insufficient permissions to delete resources');
    }
    super.authorizeDelete(context);
  }

  /// Backwards-compatible API
  Future<void> upsertResource({
    required SecurityContext context,
    required Resource resource,
  }) =>
      upsert(context: context, model: resource);

  Stream<List<Resource>> watchResources(SecurityContext context) =>
      watchAll(context);

  Stream<List<Resource>> watchResourcesByLocation({
    required SecurityContext context,
    required String locationId,
  }) {
    authorizeRead(context);
    return collectionRef(context)
        .where('locationId', isEqualTo: locationId)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => fromDoc(doc))
              .toList(),
        );
  }

  Future<Resource?> getResource({
    required SecurityContext context,
    required String resourceId,
  }) =>
      getById(context: context, id: resourceId);

  Future<void> deleteResource({
    required SecurityContext context,
    required String resourceId,
  }) =>
      delete(context: context, id: resourceId);
}
