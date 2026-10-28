import 'package:freezed_annotation/freezed_annotation.dart';

part 'business_search_result.freezed.dart';
part 'business_search_result.g.dart';

/// Limited business information returned from search.
/// Only includes public, non-sensitive data.
@freezed
abstract class BusinessSearchResult with _$BusinessSearchResult {
  const factory BusinessSearchResult({
    required String id,
    required String name,
    required String businessCode,
    String? logoUrl,
    String? city,
    String? state,
    @Default([]) List<String> serviceCategories,
    double? rating,
    int? reviewCount,
  }) = _BusinessSearchResult;

  factory BusinessSearchResult.fromJson(Map<String, dynamic> json) =>
      _$BusinessSearchResultFromJson(json);
}

/// Detailed business information for booking.
/// Includes hours, services, locations, etc.
@freezed
abstract class BusinessDetails with _$BusinessDetails {
  const factory BusinessDetails({
    required String id,
    required String name,
    required String businessCode,
    String? description,
    String? logoUrl,
    @Default([]) List<BusinessLocation> locations,
    @Default([]) List<String> serviceCategories,
    BusinessHours? hours,
    String? phone,
    String? email,
    String? website,
    double? rating,
    int? reviewCount,
  }) = _BusinessDetails;

  factory BusinessDetails.fromJson(Map<String, dynamic> json) =>
      _$BusinessDetailsFromJson(json);
}

/// Business location information
@freezed
abstract class BusinessLocation with _$BusinessLocation {
  const factory BusinessLocation({
    required String id,
    required String name,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? phone,
  }) = _BusinessLocation;

  factory BusinessLocation.fromJson(Map<String, dynamic> json) =>
      _$BusinessLocationFromJson(json);
}

/// Business hours information
@freezed
abstract class BusinessHours with _$BusinessHours {
  const factory BusinessHours({
    DayHours? monday,
    DayHours? tuesday,
    DayHours? wednesday,
    DayHours? thursday,
    DayHours? friday,
    DayHours? saturday,
    DayHours? sunday,
  }) = _BusinessHours;

  factory BusinessHours.fromJson(Map<String, dynamic> json) =>
      _$BusinessHoursFromJson(json);
}

/// Hours for a specific day
@freezed
abstract class DayHours with _$DayHours {
  const factory DayHours({
    required bool isOpen,
    String? openTime,
    String? closeTime,
  }) = _DayHours;

  factory DayHours.fromJson(Map<String, dynamic> json) =>
      _$DayHoursFromJson(json);
}
