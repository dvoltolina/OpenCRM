import 'package:freezed_annotation/freezed_annotation.dart';

import '../converters/timestamp_converters.dart';

part 'location.freezed.dart';
part 'location.g.dart';

/// Location entity representing a physical business location.
/// Multi-tenant: each location belongs to exactly one business.
@freezed
abstract class Location with _$Location {
  const factory Location({
    required String id,
    required String businessId,
    String? name,
    required String address,
    required String city,
    required String state,
    required String zipCode,
    String? phone,
    @TimestampConverter() required DateTime createdAt,
  }) = _Location;

  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);
}
