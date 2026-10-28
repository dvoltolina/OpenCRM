import 'package:freezed_annotation/freezed_annotation.dart';

import '../converters/timestamp_converters.dart';

part 'resource.freezed.dart';
part 'resource.g.dart';

/// ResourceType enum for categorizing resources
enum ResourceType {
  room,
  equipment,
  vehicle,
  other;

  String get displayName {
    switch (this) {
      case ResourceType.room:
        return 'Room';
      case ResourceType.equipment:
        return 'Equipment';
      case ResourceType.vehicle:
        return 'Vehicle';
      case ResourceType.other:
        return 'Other';
    }
  }
}

/// Resource entity representing rooms, equipment, or other bookable resources.
/// Multi-tenant: each resource belongs to exactly one business.
@freezed
abstract class Resource with _$Resource {
  const factory Resource({
    required String id,
    required String businessId,
    required String name,
    required ResourceType type,
    String? description,
    required String locationId,
    @Default(1) int capacity,
    @Default(true) bool isActive,
    @Default([]) List<String> maintenanceSchedule,
    @TimestampConverter() required DateTime createdAt,
    @NullableTimestampConverter() DateTime? updatedAt,
  }) = _Resource;

  factory Resource.fromJson(Map<String, dynamic> json) =>
      _$ResourceFromJson(json);

  const Resource._();

  /// Display capacity as a string
  String get capacityDisplay => capacity == 1 ? '1 person' : '$capacity people';
}
