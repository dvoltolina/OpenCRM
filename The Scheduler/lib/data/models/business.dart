import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'business_industry.dart';

part 'business.freezed.dart';
part 'business.g.dart';

/// Converter for Firestore Timestamp to DateTime.
class _TimestampConverter implements JsonConverter<DateTime, dynamic> {
  const _TimestampConverter();

  @override
  DateTime fromJson(dynamic json) {
    if (json is Timestamp) {
      return json.toDate();
    } else if (json is String) {
      return DateTime.parse(json);
    } else if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json);
    }
    throw ArgumentError('Cannot convert $json to DateTime');
  }

  @override
  dynamic toJson(DateTime object) => Timestamp.fromDate(object);
}

/// Business entity representing a multi-tenant organization.
/// Each business is isolated and owns its own data (locations, providers, etc.)
@freezed
abstract class Business with _$Business {
  const factory Business({
    required String id,
    required String name,
    String? description,
    String? contactEmail,
    String? contactPhone,
    @_TimestampConverter() required DateTime createdAt,

    /// Industry type - determines default HIPAA compliance settings
    @Default(BusinessIndustry.other) BusinessIndustry industry,

    /// Whether this business requires HIPAA compliance.
    /// Auto-set based on industry, but can be manually enabled.
    @Default(false) bool requiresHipaaCompliance,

    /// Whether MFA is enabled for admin/owner roles.
    /// Auto-enabled for HIPAA businesses, optional for others.
    @Default(false) bool mfaEnabled,
  }) = _Business;

  factory Business.fromJson(Map<String, dynamic> json) =>
      _$BusinessFromJson(json);
}

