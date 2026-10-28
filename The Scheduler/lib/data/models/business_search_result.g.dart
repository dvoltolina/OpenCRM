// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_search_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BusinessSearchResult _$BusinessSearchResultFromJson(
  Map<String, dynamic> json,
) => _BusinessSearchResult(
  id: json['id'] as String,
  name: json['name'] as String,
  businessCode: json['businessCode'] as String,
  logoUrl: json['logoUrl'] as String?,
  city: json['city'] as String?,
  state: json['state'] as String?,
  serviceCategories:
      (json['serviceCategories'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  rating: (json['rating'] as num?)?.toDouble(),
  reviewCount: (json['reviewCount'] as num?)?.toInt(),
);

Map<String, dynamic> _$BusinessSearchResultToJson(
  _BusinessSearchResult instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'businessCode': instance.businessCode,
  'logoUrl': instance.logoUrl,
  'city': instance.city,
  'state': instance.state,
  'serviceCategories': instance.serviceCategories,
  'rating': instance.rating,
  'reviewCount': instance.reviewCount,
};

_BusinessDetails _$BusinessDetailsFromJson(Map<String, dynamic> json) =>
    _BusinessDetails(
      id: json['id'] as String,
      name: json['name'] as String,
      businessCode: json['businessCode'] as String,
      description: json['description'] as String?,
      logoUrl: json['logoUrl'] as String?,
      locations:
          (json['locations'] as List<dynamic>?)
              ?.map((e) => BusinessLocation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      serviceCategories:
          (json['serviceCategories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      hours: json['hours'] == null
          ? null
          : BusinessHours.fromJson(json['hours'] as Map<String, dynamic>),
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: (json['reviewCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BusinessDetailsToJson(_BusinessDetails instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'businessCode': instance.businessCode,
      'description': instance.description,
      'logoUrl': instance.logoUrl,
      'locations': instance.locations.map((e) => e.toJson()).toList(),
      'serviceCategories': instance.serviceCategories,
      'hours': instance.hours?.toJson(),
      'phone': instance.phone,
      'email': instance.email,
      'website': instance.website,
      'rating': instance.rating,
      'reviewCount': instance.reviewCount,
    };

_BusinessLocation _$BusinessLocationFromJson(Map<String, dynamic> json) =>
    _BusinessLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipCode: json['zipCode'] as String?,
      phone: json['phone'] as String?,
    );

Map<String, dynamic> _$BusinessLocationToJson(_BusinessLocation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'city': instance.city,
      'state': instance.state,
      'zipCode': instance.zipCode,
      'phone': instance.phone,
    };

_BusinessHours _$BusinessHoursFromJson(Map<String, dynamic> json) =>
    _BusinessHours(
      monday: json['monday'] == null
          ? null
          : DayHours.fromJson(json['monday'] as Map<String, dynamic>),
      tuesday: json['tuesday'] == null
          ? null
          : DayHours.fromJson(json['tuesday'] as Map<String, dynamic>),
      wednesday: json['wednesday'] == null
          ? null
          : DayHours.fromJson(json['wednesday'] as Map<String, dynamic>),
      thursday: json['thursday'] == null
          ? null
          : DayHours.fromJson(json['thursday'] as Map<String, dynamic>),
      friday: json['friday'] == null
          ? null
          : DayHours.fromJson(json['friday'] as Map<String, dynamic>),
      saturday: json['saturday'] == null
          ? null
          : DayHours.fromJson(json['saturday'] as Map<String, dynamic>),
      sunday: json['sunday'] == null
          ? null
          : DayHours.fromJson(json['sunday'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BusinessHoursToJson(_BusinessHours instance) =>
    <String, dynamic>{
      'monday': instance.monday?.toJson(),
      'tuesday': instance.tuesday?.toJson(),
      'wednesday': instance.wednesday?.toJson(),
      'thursday': instance.thursday?.toJson(),
      'friday': instance.friday?.toJson(),
      'saturday': instance.saturday?.toJson(),
      'sunday': instance.sunday?.toJson(),
    };

_DayHours _$DayHoursFromJson(Map<String, dynamic> json) => _DayHours(
  isOpen: json['isOpen'] as bool,
  openTime: json['openTime'] as String?,
  closeTime: json['closeTime'] as String?,
);

Map<String, dynamic> _$DayHoursToJson(_DayHours instance) => <String, dynamic>{
  'isOpen': instance.isOpen,
  'openTime': instance.openTime,
  'closeTime': instance.closeTime,
};
