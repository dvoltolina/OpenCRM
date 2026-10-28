import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/onboarding_state.dart';
import '../../data/models/self_booking_access.dart';
import '../../data/repositories/onboarding_repository.dart';

class OnboardingController {
  OnboardingController._(this._repository);

  static final OnboardingController instance = OnboardingController._(
    FirestoreOnboardingRepository(),
  );

  final OnboardingRepository _repository;

  final ValueNotifier<OnboardingState?> state = ValueNotifier(null);

  StreamSubscription<OnboardingState?>? _subscription;
  String? _businessId;

  Future<void> init(String businessId) async {
    if (_businessId == businessId && _subscription != null) {
      return;
    }

    _businessId = businessId;
    _subscription?.cancel();

    final existing = await _repository.fetch(businessId);
    state.value = existing;

    _subscription = _repository.watch(businessId).listen((event) {
      state.value = event;
    });
  }

  Future<void> save(OnboardingState newState) async {
    await _repository.save(newState);
    state.value = newState;
  }

  bool get requiresDeposit => state.value?.requireDeposit ?? false;

  bool get emailRemindersEnabled => state.value?.emailReminders ?? true;

  bool get smsRemindersEnabled => state.value?.smsReminders ?? false;

  SelfBookingAccess get selfBookingAccess =>
      state.value?.selfBookingAccess ?? SelfBookingAccess.allCustomers;

  /// Whether self-booking is enabled (for backwards compatibility).
  bool get allowClientPortal => selfBookingAccess.isEnabled;

  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}

