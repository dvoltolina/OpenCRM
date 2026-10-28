import 'package:freezed_annotation/freezed_annotation.dart';

import '../converters/timestamp_converters.dart';

part 'client.freezed.dart';
part 'client.g.dart';

/// Client lifecycle status for tracking engagement
enum ClientLifecycle {
  /// New client (first appointment not yet completed)
  newClient,

  /// Active client (regular appointments)
  active,

  /// Inactive client (no appointments in 90+ days)
  inactive,

  /// Churned client (explicitly marked as no longer returning)
  churned,
}

/// Client entity representing a customer/patient.
/// Multi-tenant: each client belongs to exactly one business.
/// Clients cannot be shared across businesses for privacy/security.
@freezed
abstract class Client with _$Client {
  const factory Client({
    required String id,
    required String businessId,
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
    String? address,
    @NullableTimestampConverter() DateTime? birthDate,
    String? notes,
    @Default([]) List<String> tags,
    @Default(ClientLifecycle.newClient) ClientLifecycle lifecycle,
    @NullableTimestampConverter() DateTime? lastContactDate,
    @NullableTimestampConverter() DateTime? lastAppointmentDate,
    @Default({}) Map<String, dynamic> preferences,
    @Default({}) Map<String, dynamic> customFields,
    @TimestampConverter() required DateTime createdAt,
    @NullableTimestampConverter() DateTime? updatedAt,
    /// Optional Firebase Auth user ID if client has a login account
    /// This links the client profile to a Firebase Auth user for customer portal access
    String? userId,

    // ========== AI Prediction Fields ==========
    /// Whether client has a payment method on file (card, bank account, etc.)
    /// Used by no-show prediction model as a trust indicator.
    @Default(false) bool hasPaymentMethod,

    /// Stripe customer ID for payment processing (optional)
    String? stripeCustomerId,

    // ========== Route Optimization Fields (for mobile providers) ==========
    /// Service address latitude (for mobile providers)
    /// Used by route optimization in Phase 3.
    double? serviceLatitude,

    /// Service address longitude (for mobile providers)
    /// Used by route optimization in Phase 3.
    double? serviceLongitude,

    /// Service location notes (e.g., "Gate code: 1234", "Park in back")
    String? serviceNotes,
  }) = _Client;

  factory Client.fromJson(Map<String, dynamic> json) =>
      _$ClientFromJson(json);

  const Client._();

  /// Full name helper
  String get fullName => '$firstName $lastName';

  /// Initials helper for avatars
  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    return '$first$last'.toUpperCase();
  }

  /// Check if client has email
  bool get hasEmail => email != null && email!.isNotEmpty;

  /// Check if client has phone
  bool get hasPhone => phone != null && phone!.isNotEmpty;

  /// Check if client has a linked user account
  bool get hasUserAccount => userId != null && userId!.isNotEmpty;

  /// Get lifecycle display name
  String get lifecycleDisplay {
    switch (lifecycle) {
      case ClientLifecycle.newClient:
        return 'New';
      case ClientLifecycle.active:
        return 'Active';
      case ClientLifecycle.inactive:
        return 'Inactive';
      case ClientLifecycle.churned:
        return 'Churned';
    }
  }

  /// Get lifecycle color for UI
  int get lifecycleColorValue {
    switch (lifecycle) {
      case ClientLifecycle.newClient:
        return 0xFF2196F3; // Blue
      case ClientLifecycle.active:
        return 0xFF4CAF50; // Green
      case ClientLifecycle.inactive:
        return 0xFFFFC107; // Amber
      case ClientLifecycle.churned:
        return 0xFF9E9E9E; // Grey
    }
  }

  /// Check if client has service location coordinates (for mobile providers)
  bool get hasServiceLocation =>
      serviceLatitude != null && serviceLongitude != null;

  /// Check if client has Stripe integration
  bool get hasStripeCustomer =>
      stripeCustomerId != null && stripeCustomerId!.isNotEmpty;
}
