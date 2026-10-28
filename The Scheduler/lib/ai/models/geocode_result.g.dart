// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geocode_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GeocodeBounds _$GeocodeBoundsFromJson(Map<String, dynamic> json) =>
    _GeocodeBounds(
      northeastLat: (json['northeastLat'] as num).toDouble(),
      northeastLng: (json['northeastLng'] as num).toDouble(),
      southwestLat: (json['southwestLat'] as num).toDouble(),
      southwestLng: (json['southwestLng'] as num).toDouble(),
    );

Map<String, dynamic> _$GeocodeBoundsToJson(_GeocodeBounds instance) =>
    <String, dynamic>{
      'northeastLat': instance.northeastLat,
      'northeastLng': instance.northeastLng,
      'southwestLat': instance.southwestLat,
      'southwestLng': instance.southwestLng,
    };

_GeocodeResult _$GeocodeResultFromJson(Map<String, dynamic> json) =>
    _GeocodeResult(
      id: json['id'] as String,
      originalAddress: json['originalAddress'] as String,
      formattedAddress: json['formattedAddress'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      placeId: json['placeId'] as String?,
      provider: $enumDecode(_$GeocodeProviderEnumMap, json['provider']),
      accuracy: $enumDecode(_$GeocodeAccuracyEnumMap, json['accuracy']),
      confidence: (json['confidence'] as num?)?.toDouble(),
      geocodedAt: DateTime.parse(json['geocodedAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      addressComponents: (json['addressComponents'] as Map<String, dynamic>?)
          ?.map((k, e) => MapEntry(k, e as String)),
      timezone: json['timezone'] as String?,
      viewport: json['viewport'] == null
          ? null
          : GeocodeBounds.fromJson(json['viewport'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GeocodeResultToJson(_GeocodeResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'originalAddress': instance.originalAddress,
      'formattedAddress': instance.formattedAddress,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'placeId': instance.placeId,
      'provider': _$GeocodeProviderEnumMap[instance.provider]!,
      'accuracy': _$GeocodeAccuracyEnumMap[instance.accuracy]!,
      'confidence': instance.confidence,
      'geocodedAt': instance.geocodedAt.toIso8601String(),
      'expiresAt': instance.expiresAt.toIso8601String(),
      'addressComponents': instance.addressComponents,
      'timezone': instance.timezone,
      'viewport': instance.viewport?.toJson(),
    };

const _$GeocodeProviderEnumMap = {
  GeocodeProvider.google: 'google',
  GeocodeProvider.openStreetMap: 'openStreetMap',
  GeocodeProvider.manual: 'manual',
  GeocodeProvider.imported: 'imported',
};

const _$GeocodeAccuracyEnumMap = {
  GeocodeAccuracy.rooftop: 'rooftop',
  GeocodeAccuracy.rangeInterpolated: 'rangeInterpolated',
  GeocodeAccuracy.geometricCenter: 'geometricCenter',
  GeocodeAccuracy.approximate: 'approximate',
  GeocodeAccuracy.unknown: 'unknown',
};
