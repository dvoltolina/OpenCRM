import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/config/demo_config.dart';
import '../../core/services/demo_guard_service.dart';
import '../models/security_context.dart';
import '../models/subscription.dart';

/// Repository for managing subscription data
///
/// This repository handles subscription CRUD operations with proper
/// multi-tenant isolation and security checks.
abstract class SubscriptionRepository {
  /// Watch the subscription for a business
  ///
  /// Returns a stream that emits the current subscription whenever it changes.
  Stream<Subscription?> watchSubscription(SecurityContext context);

  /// Get the current subscription for a business
  Future<Subscription?> getSubscription(SecurityContext context);

  /// Create a new subscription (typically called after successful Stripe setup)
  Future<void> upsertSubscription(
    SecurityContext context,
    Subscription subscription,
  );

  /// Update subscription status (e.g., from webhook)
  Future<void> updateSubscriptionStatus(
    SecurityContext context,
    String subscriptionId,
    SubscriptionStatus status,
  );

  /// Cancel subscription at period end
  Future<void> cancelSubscription(
    SecurityContext context,
    String subscriptionId,
  );

  /// Reactivate a canceled subscription
  Future<void> reactivateSubscription(
    SecurityContext context,
    String subscriptionId,
  );

  /// Get usage statistics for current billing period
  Future<Map<String, int>> getUsageStats(SecurityContext context);
}

/// Firestore implementation of SubscriptionRepository
class FirestoreSubscriptionRepository implements SubscriptionRepository {
  final FirebaseFirestore _firestore;

  FirestoreSubscriptionRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection reference for subscriptions
  CollectionReference<Map<String, dynamic>> _subscriptionsCollection(
    String businessId,
  ) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('subscriptions');
  }

  @override
  Stream<Subscription?> watchSubscription(SecurityContext context) {
    context.verifyBusinessAccess(context.businessId);

    return _subscriptionsCollection(
      context.businessId,
    ).doc('current').snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      final data = snapshot.data()!;
      data['id'] = snapshot.id;
      return Subscription.fromJson(data);
    });
  }

  @override
  Future<Subscription?> getSubscription(SecurityContext context) async {
    context.verifyBusinessAccess(context.businessId);

    final doc = await _subscriptionsCollection(
      context.businessId,
    ).doc('current').get();

    if (!doc.exists) return null;

    final data = doc.data()!;
    data['id'] = doc.id;
    return Subscription.fromJson(data);
  }

  @override
  Future<void> upsertSubscription(
    SecurityContext context,
    Subscription subscription,
  ) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('save subscription');
    }
    // Only owner can manage subscriptions
    if (!context.role.canManageBusiness) {
      throw SecurityException('Only business owners can manage subscriptions');
    }

    context.verifyBusinessAccess(context.businessId);

    if (subscription.businessId != context.businessId) {
      throw SecurityException(
        'Cannot manage subscription for different business',
      );
    }

    final data = subscription.toJson();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _subscriptionsCollection(
      context.businessId,
    ).doc('current').set(data, SetOptions(merge: true));
  }

  @override
  Future<void> updateSubscriptionStatus(
    SecurityContext context,
    String subscriptionId,
    SubscriptionStatus status,
  ) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('update subscription');
    }
    context.verifyBusinessAccess(context.businessId);

    await _subscriptionsCollection(context.businessId).doc('current').update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> cancelSubscription(
    SecurityContext context,
    String subscriptionId,
  ) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('cancel subscription');
    }
    // Only owner can cancel subscriptions
    if (!context.role.canManageBusiness) {
      throw SecurityException('Only business owners can cancel subscriptions');
    }

    context.verifyBusinessAccess(context.businessId);

    await _subscriptionsCollection(context.businessId).doc('current').update({
      'cancelAtPeriodEnd': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> reactivateSubscription(
    SecurityContext context,
    String subscriptionId,
  ) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('reactivate subscription');
    }
    // Only owner can reactivate subscriptions
    if (!context.role.canManageBusiness) {
      throw SecurityException(
        'Only business owners can reactivate subscriptions',
      );
    }

    context.verifyBusinessAccess(context.businessId);

    await _subscriptionsCollection(context.businessId).doc('current').update({
      'cancelAtPeriodEnd': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<Map<String, int>> getUsageStats(SecurityContext context) async {
    context.verifyBusinessAccess(context.businessId);

    // Get current period start from subscription
    final subscription = await getSubscription(context);
    if (subscription == null) {
      return {
        'providers': 0,
        'locations': 0,
        'appointmentsThisMonth': 0,
        'clients': 0,
        'smsThisMonth': 0,
      };
    }

    final periodStart = subscription.currentPeriodStart;

    // Count providers
    final providersSnapshot = await _firestore
        .collection('businesses')
        .doc(context.businessId)
        .collection('providers')
        .count()
        .get();

    // Count locations
    final locationsSnapshot = await _firestore
        .collection('businesses')
        .doc(context.businessId)
        .collection('locations')
        .count()
        .get();

    // Count appointments this billing period
    final appointmentsSnapshot = await _firestore
        .collection('businesses')
        .doc(context.businessId)
        .collection('appointments')
        .where('createdAt', isGreaterThanOrEqualTo: periodStart)
        .count()
        .get();

    // Count total clients
    final clientsSnapshot = await _firestore
        .collection('businesses')
        .doc(context.businessId)
        .collection('clients')
        .count()
        .get();

    // Count SMS sent this billing period
    // Note: This would come from a messages collection tracking sent SMS
    final smsSnapshot = await _firestore
        .collection('businesses')
        .doc(context.businessId)
        .collection('messages')
        .where('channel', isEqualTo: 'sms')
        .where('sentAt', isGreaterThanOrEqualTo: periodStart)
        .count()
        .get();

    return {
      'providers': providersSnapshot.count ?? 0,
      'locations': locationsSnapshot.count ?? 0,
      'appointmentsThisMonth': appointmentsSnapshot.count ?? 0,
      'clients': clientsSnapshot.count ?? 0,
      'smsThisMonth': smsSnapshot.count ?? 0,
    };
  }
}

/// Mock implementation for testing
class MockSubscriptionRepository implements SubscriptionRepository {
  Subscription? _currentSubscription;
  final Map<String, int> _usageStats = {
    'providers': 1,
    'locations': 1,
    'appointmentsThisMonth': 15,
    'clients': 25,
    'smsThisMonth': 10,
  };

  @override
  Stream<Subscription?> watchSubscription(SecurityContext context) {
    return Stream.value(_currentSubscription);
  }

  @override
  Future<Subscription?> getSubscription(SecurityContext context) async {
    return _currentSubscription;
  }

  @override
  Future<void> upsertSubscription(
    SecurityContext context,
    Subscription subscription,
  ) async {
    _currentSubscription = subscription;
  }

  @override
  Future<void> updateSubscriptionStatus(
    SecurityContext context,
    String subscriptionId,
    SubscriptionStatus status,
  ) async {
    if (_currentSubscription != null) {
      _currentSubscription = _currentSubscription!.copyWith(status: status);
    }
  }

  @override
  Future<void> cancelSubscription(
    SecurityContext context,
    String subscriptionId,
  ) async {
    if (_currentSubscription != null) {
      _currentSubscription = _currentSubscription!.copyWith(
        cancelAtPeriodEnd: true,
      );
    }
  }

  @override
  Future<void> reactivateSubscription(
    SecurityContext context,
    String subscriptionId,
  ) async {
    if (_currentSubscription != null) {
      _currentSubscription = _currentSubscription!.copyWith(
        cancelAtPeriodEnd: false,
      );
    }
  }

  @override
  Future<Map<String, int>> getUsageStats(SecurityContext context) async {
    return Map.from(_usageStats);
  }

  /// Helper method for testing
  void setMockSubscription(Subscription subscription) {
    _currentSubscription = subscription;
  }

  /// Helper method for testing
  void setMockUsageStats(Map<String, int> stats) {
    _usageStats.addAll(stats);
  }
}
