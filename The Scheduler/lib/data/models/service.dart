import 'package:freezed_annotation/freezed_annotation.dart';

import '../converters/timestamp_converters.dart';

part 'service.freezed.dart';
part 'service.g.dart';

/// Service entity representing a bookable service offering.
/// Multi-tenant: each service belongs to exactly one business.
@freezed
abstract class Service with _$Service {
  const factory Service({
    required String id,
    required String businessId,
    required String name,
    required int durationMinutes,
    required double price,
    String? description,
    String? category,
    @Default([]) List<String> providerIds,
    @Default([]) List<String> requiredResources,
    String? intakeFormTemplateId,
    int? bufferMinutes,
    @TimestampConverter() required DateTime createdAt,
    @NullableTimestampConverter() DateTime? updatedAt,
  }) = _Service;

  factory Service.fromJson(Map<String, dynamic> json) =>
      _$ServiceFromJson(json);

  const Service._();

  /// Duration as a human-readable string
  String get durationDisplay {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  /// Price formatted as currency
  String get priceDisplay => '\$${price.toStringAsFixed(2)}';
}
