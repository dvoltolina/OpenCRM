import 'package:ulid/ulid.dart';

import '../../data/models/onboarding_state.dart';
import '../../data/models/security_context.dart';
import '../../data/models/service.dart';
import '../../data/models/location.dart';
import '../../data/repositories/services_repository.dart';
import '../../data/repositories/locations_repository.dart';

/// Service that syncs onboarding data to actual Firestore entities.
/// Creates services and locations based on what was entered during onboarding.
class OnboardingCompletionService {
  OnboardingCompletionService({
    required ServicesRepository servicesRepository,
    required LocationsRepository locationsRepository,
  })  : _servicesRepository = servicesRepository,
        _locationsRepository = locationsRepository;

  final ServicesRepository _servicesRepository;
  final LocationsRepository _locationsRepository;

  /// Syncs onboarding data to Firestore entities.
  /// Creates services and location if they don't already exist.
  Future<void> syncOnboardingData({
    required OnboardingState state,
    required SecurityContext securityContext,
  }) async {
    // Create services from onboarding
    await _createServicesFromOnboarding(state, securityContext);

    // Create location from onboarding
    await _createLocationFromOnboarding(state, securityContext);
  }

  Future<void> _createServicesFromOnboarding(
    OnboardingState state,
    SecurityContext securityContext,
  ) async {
    if (state.services.isEmpty) return;

    // Get existing services to avoid duplicates
    final existingServices = await _servicesRepository.getServices(
      context: securityContext,
    );

    final existingNames = existingServices
        .map((s) => s.name.toLowerCase())
        .toSet();

    for (final serviceName in state.services) {
      // Skip if service already exists
      if (existingNames.contains(serviceName.toLowerCase())) {
        continue;
      }

      final service = Service(
        id: Ulid().toString(),
        businessId: state.businessId,
        name: serviceName,
        description: '',
        durationMinutes: 60, // Default 1 hour
        price: 0, // Price to be set later
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _servicesRepository.upsert(
        context: securityContext,
        model: service,
      );
    }
  }

  Future<void> _createLocationFromOnboarding(
    OnboardingState state,
    SecurityContext securityContext,
  ) async {
    if (state.location.isEmpty) return;

    // Get existing locations to avoid duplicates
    final existingLocations = await _locationsRepository.getLocations(
      context: securityContext,
    );

    // Skip if any location already exists
    if (existingLocations.isNotEmpty) {
      return;
    }

    // Parse location string - could be address, city, or full address
    final locationText = state.location.trim();

    final location = Location(
      id: Ulid().toString(),
      businessId: state.businessId,
      name: state.businessName,
      address: locationText,
      city: '',
      state: '',
      zipCode: '',
      createdAt: DateTime.now(),
    );

    await _locationsRepository.upsert(
      context: securityContext,
      model: location,
    );
  }
}
