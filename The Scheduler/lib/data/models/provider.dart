import 'package:freezed_annotation/freezed_annotation.dart';

import '../converters/timestamp_converters.dart';

part 'provider.freezed.dart';
part 'provider.g.dart';

/// Provider entity representing a service provider (staff member).
/// Multi-tenant: each provider belongs to exactly one business.
@freezed
abstract class Provider with _$Provider {
  const factory Provider({
    required String id,
    required String businessId,
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
    String? stripeAccountId,
    String? bio,
    @Default([]) List<String> specializations,
    @Default([]) List<String> serviceIds,
    @Default([]) List<String> locationIds,
    @Default('4285F4') String colorHex, // Blue default
    @TimestampConverter() required DateTime createdAt,
    @NullableTimestampConverter() DateTime? updatedAt,
  }) = _Provider;

  factory Provider.fromJson(Map<String, dynamic> json) =>
      _$ProviderFromJson(json);

  const Provider._();

  /// Full name helper
  String get fullName => '$firstName $lastName';

  /// Initials for avatar
  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    return '$first$last'.toUpperCase();
  }

  /// Primary location ID (first location in list, for backwards compatibility)
  String? get locationId => locationIds.isNotEmpty ? locationIds.first : null;
}
