import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/config/demo_config.dart';
import '../../core/services/demo_guard_service.dart';
import '../models/business.dart';
import '../models/security_context.dart';

/// Repository for managing business entities.
/// Only owners can modify business settings.
class BusinessRepository {
  BusinessRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Get a business by ID
  Future<Business?> getBusiness(String businessId) async {
    final doc = await _firestore.collection('businesses').doc(businessId).get();
    if (!doc.exists) {
      if (DemoConfig.isDemoMode && businessId == DemoConfig.demoBusinessId) {
        return DemoConfig.buildDemoBusiness();
      }
      return null;
    }

    return Business.fromJson({'id': doc.id, ...doc.data()!});
  }

  /// Update business information (owner only)
  Future<void> updateBusiness({
    required SecurityContext context,
    required Business business,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('update business');
    }
    if (!context.isOwner) {
      throw SecurityException('Only owners can modify business settings');
    }

    context.verifyBusinessAccess(business.id);

    await _firestore
        .collection('businesses')
        .doc(business.id)
        .set(business.toJson(), SetOptions(merge: true));
  }

  /// Create a new business (used during onboarding/registration)
  Future<void> createBusiness({
    required Business business,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('create business');
    }
    await _firestore
        .collection('businesses')
        .doc(business.id)
        .set(business.toJson());
  }

  /// Watch business updates
  Stream<Business?> watchBusiness(String businessId) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return Business.fromJson({'id': doc.id, ...doc.data()!});
    });
  }
}
