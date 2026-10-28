import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';

import '../../core/config/demo_config.dart';
import '../../core/services/demo_guard_service.dart';
import '../models/security_context.dart';

/// Shared Firestore CRUD helper for business-scoped collections.
/// Subclasses provide serialization + auth rules to avoid copy/paste.
///
/// Default limit of 200 protects against unbounded reads while allowing
/// reasonable collection sizes for Services, Locations, Providers, Resources.
abstract class BusinessCollectionRepository<T> {
  BusinessCollectionRepository({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore firestore;

  /// Default limit for list queries to control Firebase costs.
  /// Can be overridden by subclasses for smaller/larger collections.
  int get defaultLimit => 200;

  /// Collection name under `businesses/{businessId}`.
  String get collectionName;

  /// Optional default ordering field.
  String? get defaultOrderBy => null;

  /// Whether the default ordering should be descending.
  bool get orderDescending => false;

  /// Map Firestore doc to domain model.
  T fromDoc(DocumentSnapshot<Map<String, dynamic>> doc);

  /// Map domain model to Firestore payload (without id).
  Map<String, dynamic> toMap(T model);

  /// Extract id from domain model.
  String getId(T model);

  /// Authorization hook for reads.
  void authorizeRead(SecurityContext context) {
    context.verifyBusinessAccess();
  }

  /// Authorization hook for writes.
  void authorizeWrite(SecurityContext context, T model) {
    authorizeRead(context);
  }

  /// Authorization hook for deletes.
  void authorizeDelete(SecurityContext context) {
    authorizeRead(context);
  }

  /// Expose raw collection for specialized queries in subclasses.
  @protected
  CollectionReference<Map<String, dynamic>> collectionRef(
    SecurityContext context,
  ) {
    return firestore
        .collection('businesses')
        .doc(context.businessId)
        .collection(collectionName);
  }

  Query<Map<String, dynamic>> _withDefaultOrdering(
    Query<Map<String, dynamic>> query,
  ) {
    if (defaultOrderBy == null) return query;
    return query.orderBy(defaultOrderBy!, descending: orderDescending);
  }

  /// Watch all documents in the collection with a limit.
  ///
  /// [limit] controls max documents returned (default: [defaultLimit]).
  Stream<List<T>> watchAll(SecurityContext context, {int? limit}) {
    authorizeRead(context);
    final effectiveLimit = limit ?? defaultLimit;
    final query = _withDefaultOrdering(collectionRef(context)).limit(effectiveLimit);
    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => fromDoc(doc))
              .toList(),
        );
  }

  /// Get all documents in the collection with a limit.
  ///
  /// [limit] controls max documents returned (default: [defaultLimit]).
  Future<List<T>> getAll({required SecurityContext context, int? limit}) async {
    authorizeRead(context);
    final effectiveLimit = limit ?? defaultLimit;
    final snapshot = await _withDefaultOrdering(collectionRef(context))
        .limit(effectiveLimit)
        .get();
    return snapshot.docs.map((doc) => fromDoc(doc)).toList();
  }

  Future<T?> getById({
    required SecurityContext context,
    required String id,
  }) async {
    authorizeRead(context);
    final doc = await collectionRef(context).doc(id).get();
    if (!doc.exists) return null;
    return fromDoc(doc);
  }

  Future<void> upsert({
    required SecurityContext context,
    required T model,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('update $collectionName');
    }
    authorizeWrite(context, model);
    await collectionRef(context)
        .doc(getId(model))
        .set(toMap(model), SetOptions(merge: true));
  }

  Future<void> delete({
    required SecurityContext context,
    required String id,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('delete $collectionName');
    }
    authorizeDelete(context);
    await collectionRef(context).doc(id).delete();
  }
}
