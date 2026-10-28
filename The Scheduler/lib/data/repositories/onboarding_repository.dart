import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/config/demo_config.dart';
import '../../core/services/demo_guard_service.dart';
import '../models/onboarding_state.dart';

abstract class OnboardingRepository {
  Future<OnboardingState?> fetch(String businessId);

  Stream<OnboardingState?> watch(String businessId);

  Future<void> save(OnboardingState state);
}

/// Firestore-backed repository that persists onboarding state
/// under businesses/{businessId}/settings/onboarding
class FirestoreOnboardingRepository implements OnboardingRepository {
  FirestoreOnboardingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _docRef(String businessId) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('settings')
        .doc('onboarding');
  }

  @override
  Future<OnboardingState?> fetch(String businessId) async {
    final doc = await _docRef(businessId).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return OnboardingState.fromJson(doc.data()!);
  }

  @override
  Stream<OnboardingState?> watch(String businessId) {
    return _docRef(businessId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return OnboardingState.fromJson(snapshot.data()!);
    });
  }

  @override
  Future<void> save(OnboardingState state) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('save onboarding');
    }
    await _docRef(state.businessId).set(
      state.toJson(),
      SetOptions(merge: true),
    );
  }
}

/// In-memory repository for testing only.
class InMemoryOnboardingRepository implements OnboardingRepository {
  final Map<String, OnboardingState> _store = {};
  final Map<String, StreamController<OnboardingState?>> _controllers = {};

  @override
  Future<OnboardingState?> fetch(String businessId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _store[businessId];
  }

  @override
  Stream<OnboardingState?> watch(String businessId) {
    return _controllerFor(businessId).stream;
  }

  @override
  Future<void> save(OnboardingState state) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _store[state.businessId] = state;
    _controllerFor(state.businessId).add(state);
  }

  StreamController<OnboardingState?> _controllerFor(String businessId) {
    return _controllers.putIfAbsent(
      businessId,
      () => StreamController<OnboardingState?>.broadcast()
        ..add(_store[businessId]),
    );
  }

  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
  }
}
