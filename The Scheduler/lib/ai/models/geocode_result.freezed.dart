// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'geocode_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GeocodeBounds {

 double get northeastLat; double get northeastLng; double get southwestLat; double get southwestLng;
/// Create a copy of GeocodeBounds
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GeocodeBoundsCopyWith<GeocodeBounds> get copyWith => _$GeocodeBoundsCopyWithImpl<GeocodeBounds>(this as GeocodeBounds, _$identity);

  /// Serializes this GeocodeBounds to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GeocodeBounds&&(identical(other.northeastLat, northeastLat) || other.northeastLat == northeastLat)&&(identical(other.northeastLng, northeastLng) || other.northeastLng == northeastLng)&&(identical(other.southwestLat, southwestLat) || other.southwestLat == southwestLat)&&(identical(other.southwestLng, southwestLng) || other.southwestLng == southwestLng));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,northeastLat,northeastLng,southwestLat,southwestLng);

@override
String toString() {
  return 'GeocodeBounds(northeastLat: $northeastLat, northeastLng: $northeastLng, southwestLat: $southwestLat, southwestLng: $southwestLng)';
}


}

/// @nodoc
abstract mixin class $GeocodeBoundsCopyWith<$Res>  {
  factory $GeocodeBoundsCopyWith(GeocodeBounds value, $Res Function(GeocodeBounds) _then) = _$GeocodeBoundsCopyWithImpl;
@useResult
$Res call({
 double northeastLat, double northeastLng, double southwestLat, double southwestLng
});




}
/// @nodoc
class _$GeocodeBoundsCopyWithImpl<$Res>
    implements $GeocodeBoundsCopyWith<$Res> {
  _$GeocodeBoundsCopyWithImpl(this._self, this._then);

  final GeocodeBounds _self;
  final $Res Function(GeocodeBounds) _then;

/// Create a copy of GeocodeBounds
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? northeastLat = null,Object? northeastLng = null,Object? southwestLat = null,Object? southwestLng = null,}) {
  return _then(_self.copyWith(
northeastLat: null == northeastLat ? _self.northeastLat : northeastLat // ignore: cast_nullable_to_non_nullable
as double,northeastLng: null == northeastLng ? _self.northeastLng : northeastLng // ignore: cast_nullable_to_non_nullable
as double,southwestLat: null == southwestLat ? _self.southwestLat : southwestLat // ignore: cast_nullable_to_non_nullable
as double,southwestLng: null == southwestLng ? _self.southwestLng : southwestLng // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [GeocodeBounds].
extension GeocodeBoundsPatterns on GeocodeBounds {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GeocodeBounds value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GeocodeBounds() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GeocodeBounds value)  $default,){
final _that = this;
switch (_that) {
case _GeocodeBounds():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GeocodeBounds value)?  $default,){
final _that = this;
switch (_that) {
case _GeocodeBounds() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double northeastLat,  double northeastLng,  double southwestLat,  double southwestLng)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GeocodeBounds() when $default != null:
return $default(_that.northeastLat,_that.northeastLng,_that.southwestLat,_that.southwestLng);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double northeastLat,  double northeastLng,  double southwestLat,  double southwestLng)  $default,) {final _that = this;
switch (_that) {
case _GeocodeBounds():
return $default(_that.northeastLat,_that.northeastLng,_that.southwestLat,_that.southwestLng);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double northeastLat,  double northeastLng,  double southwestLat,  double southwestLng)?  $default,) {final _that = this;
switch (_that) {
case _GeocodeBounds() when $default != null:
return $default(_that.northeastLat,_that.northeastLng,_that.southwestLat,_that.southwestLng);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GeocodeBounds implements GeocodeBounds {
  const _GeocodeBounds({required this.northeastLat, required this.northeastLng, required this.southwestLat, required this.southwestLng});
  factory _GeocodeBounds.fromJson(Map<String, dynamic> json) => _$GeocodeBoundsFromJson(json);

@override final  double northeastLat;
@override final  double northeastLng;
@override final  double southwestLat;
@override final  double southwestLng;

/// Create a copy of GeocodeBounds
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GeocodeBoundsCopyWith<_GeocodeBounds> get copyWith => __$GeocodeBoundsCopyWithImpl<_GeocodeBounds>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GeocodeBoundsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GeocodeBounds&&(identical(other.northeastLat, northeastLat) || other.northeastLat == northeastLat)&&(identical(other.northeastLng, northeastLng) || other.northeastLng == northeastLng)&&(identical(other.southwestLat, southwestLat) || other.southwestLat == southwestLat)&&(identical(other.southwestLng, southwestLng) || other.southwestLng == southwestLng));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,northeastLat,northeastLng,southwestLat,southwestLng);

@override
String toString() {
  return 'GeocodeBounds(northeastLat: $northeastLat, northeastLng: $northeastLng, southwestLat: $southwestLat, southwestLng: $southwestLng)';
}


}

/// @nodoc
abstract mixin class _$GeocodeBoundsCopyWith<$Res> implements $GeocodeBoundsCopyWith<$Res> {
  factory _$GeocodeBoundsCopyWith(_GeocodeBounds value, $Res Function(_GeocodeBounds) _then) = __$GeocodeBoundsCopyWithImpl;
@override @useResult
$Res call({
 double northeastLat, double northeastLng, double southwestLat, double southwestLng
});




}
/// @nodoc
class __$GeocodeBoundsCopyWithImpl<$Res>
    implements _$GeocodeBoundsCopyWith<$Res> {
  __$GeocodeBoundsCopyWithImpl(this._self, this._then);

  final _GeocodeBounds _self;
  final $Res Function(_GeocodeBounds) _then;

/// Create a copy of GeocodeBounds
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? northeastLat = null,Object? northeastLng = null,Object? southwestLat = null,Object? southwestLng = null,}) {
  return _then(_GeocodeBounds(
northeastLat: null == northeastLat ? _self.northeastLat : northeastLat // ignore: cast_nullable_to_non_nullable
as double,northeastLng: null == northeastLng ? _self.northeastLng : northeastLng // ignore: cast_nullable_to_non_nullable
as double,southwestLat: null == southwestLat ? _self.southwestLat : southwestLat // ignore: cast_nullable_to_non_nullable
as double,southwestLng: null == southwestLng ? _self.southwestLng : southwestLng // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$GeocodeResult {

/// Unique identifier for this geocode result
 String get id;/// Original address that was geocoded
 String get originalAddress;/// Formatted/standardized address from geocoder
 String? get formattedAddress;/// Latitude coordinate
 double get latitude;/// Longitude coordinate
 double get longitude;/// Place ID (Google) or OSM ID for future reference
 String? get placeId;/// Geocoding provider used
 GeocodeProvider get provider;/// Accuracy level of the result
 GeocodeAccuracy get accuracy;/// Confidence score (0.0-1.0) if available
 double? get confidence;/// When this geocoding was performed
 DateTime get geocodedAt;/// When this cache entry expires
 DateTime get expiresAt;/// Address components (street, city, state, zip, country)
 Map<String, String>? get addressComponents;/// Timezone at this location (e.g., "America/New_York")
 String? get timezone;/// Viewport bounds for map display
 GeocodeBounds? get viewport;
/// Create a copy of GeocodeResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GeocodeResultCopyWith<GeocodeResult> get copyWith => _$GeocodeResultCopyWithImpl<GeocodeResult>(this as GeocodeResult, _$identity);

  /// Serializes this GeocodeResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GeocodeResult&&(identical(other.id, id) || other.id == id)&&(identical(other.originalAddress, originalAddress) || other.originalAddress == originalAddress)&&(identical(other.formattedAddress, formattedAddress) || other.formattedAddress == formattedAddress)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.placeId, placeId) || other.placeId == placeId)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.accuracy, accuracy) || other.accuracy == accuracy)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.geocodedAt, geocodedAt) || other.geocodedAt == geocodedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&const DeepCollectionEquality().equals(other.addressComponents, addressComponents)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&(identical(other.viewport, viewport) || other.viewport == viewport));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,originalAddress,formattedAddress,latitude,longitude,placeId,provider,accuracy,confidence,geocodedAt,expiresAt,const DeepCollectionEquality().hash(addressComponents),timezone,viewport);

@override
String toString() {
  return 'GeocodeResult(id: $id, originalAddress: $originalAddress, formattedAddress: $formattedAddress, latitude: $latitude, longitude: $longitude, placeId: $placeId, provider: $provider, accuracy: $accuracy, confidence: $confidence, geocodedAt: $geocodedAt, expiresAt: $expiresAt, addressComponents: $addressComponents, timezone: $timezone, viewport: $viewport)';
}


}

/// @nodoc
abstract mixin class $GeocodeResultCopyWith<$Res>  {
  factory $GeocodeResultCopyWith(GeocodeResult value, $Res Function(GeocodeResult) _then) = _$GeocodeResultCopyWithImpl;
@useResult
$Res call({
 String id, String originalAddress, String? formattedAddress, double latitude, double longitude, String? placeId, GeocodeProvider provider, GeocodeAccuracy accuracy, double? confidence, DateTime geocodedAt, DateTime expiresAt, Map<String, String>? addressComponents, String? timezone, GeocodeBounds? viewport
});


$GeocodeBoundsCopyWith<$Res>? get viewport;

}
/// @nodoc
class _$GeocodeResultCopyWithImpl<$Res>
    implements $GeocodeResultCopyWith<$Res> {
  _$GeocodeResultCopyWithImpl(this._self, this._then);

  final GeocodeResult _self;
  final $Res Function(GeocodeResult) _then;

/// Create a copy of GeocodeResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? originalAddress = null,Object? formattedAddress = freezed,Object? latitude = null,Object? longitude = null,Object? placeId = freezed,Object? provider = null,Object? accuracy = null,Object? confidence = freezed,Object? geocodedAt = null,Object? expiresAt = null,Object? addressComponents = freezed,Object? timezone = freezed,Object? viewport = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,originalAddress: null == originalAddress ? _self.originalAddress : originalAddress // ignore: cast_nullable_to_non_nullable
as String,formattedAddress: freezed == formattedAddress ? _self.formattedAddress : formattedAddress // ignore: cast_nullable_to_non_nullable
as String?,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,placeId: freezed == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String?,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as GeocodeProvider,accuracy: null == accuracy ? _self.accuracy : accuracy // ignore: cast_nullable_to_non_nullable
as GeocodeAccuracy,confidence: freezed == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double?,geocodedAt: null == geocodedAt ? _self.geocodedAt : geocodedAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,addressComponents: freezed == addressComponents ? _self.addressComponents : addressComponents // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,timezone: freezed == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String?,viewport: freezed == viewport ? _self.viewport : viewport // ignore: cast_nullable_to_non_nullable
as GeocodeBounds?,
  ));
}
/// Create a copy of GeocodeResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeocodeBoundsCopyWith<$Res>? get viewport {
    if (_self.viewport == null) {
    return null;
  }

  return $GeocodeBoundsCopyWith<$Res>(_self.viewport!, (value) {
    return _then(_self.copyWith(viewport: value));
  });
}
}


/// Adds pattern-matching-related methods to [GeocodeResult].
extension GeocodeResultPatterns on GeocodeResult {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GeocodeResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GeocodeResult() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GeocodeResult value)  $default,){
final _that = this;
switch (_that) {
case _GeocodeResult():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GeocodeResult value)?  $default,){
final _that = this;
switch (_that) {
case _GeocodeResult() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String originalAddress,  String? formattedAddress,  double latitude,  double longitude,  String? placeId,  GeocodeProvider provider,  GeocodeAccuracy accuracy,  double? confidence,  DateTime geocodedAt,  DateTime expiresAt,  Map<String, String>? addressComponents,  String? timezone,  GeocodeBounds? viewport)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GeocodeResult() when $default != null:
return $default(_that.id,_that.originalAddress,_that.formattedAddress,_that.latitude,_that.longitude,_that.placeId,_that.provider,_that.accuracy,_that.confidence,_that.geocodedAt,_that.expiresAt,_that.addressComponents,_that.timezone,_that.viewport);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String originalAddress,  String? formattedAddress,  double latitude,  double longitude,  String? placeId,  GeocodeProvider provider,  GeocodeAccuracy accuracy,  double? confidence,  DateTime geocodedAt,  DateTime expiresAt,  Map<String, String>? addressComponents,  String? timezone,  GeocodeBounds? viewport)  $default,) {final _that = this;
switch (_that) {
case _GeocodeResult():
return $default(_that.id,_that.originalAddress,_that.formattedAddress,_that.latitude,_that.longitude,_that.placeId,_that.provider,_that.accuracy,_that.confidence,_that.geocodedAt,_that.expiresAt,_that.addressComponents,_that.timezone,_that.viewport);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String originalAddress,  String? formattedAddress,  double latitude,  double longitude,  String? placeId,  GeocodeProvider provider,  GeocodeAccuracy accuracy,  double? confidence,  DateTime geocodedAt,  DateTime expiresAt,  Map<String, String>? addressComponents,  String? timezone,  GeocodeBounds? viewport)?  $default,) {final _that = this;
switch (_that) {
case _GeocodeResult() when $default != null:
return $default(_that.id,_that.originalAddress,_that.formattedAddress,_that.latitude,_that.longitude,_that.placeId,_that.provider,_that.accuracy,_that.confidence,_that.geocodedAt,_that.expiresAt,_that.addressComponents,_that.timezone,_that.viewport);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GeocodeResult implements GeocodeResult {
  const _GeocodeResult({required this.id, required this.originalAddress, this.formattedAddress, required this.latitude, required this.longitude, this.placeId, required this.provider, required this.accuracy, this.confidence, required this.geocodedAt, required this.expiresAt, final  Map<String, String>? addressComponents, this.timezone, this.viewport}): _addressComponents = addressComponents;
  factory _GeocodeResult.fromJson(Map<String, dynamic> json) => _$GeocodeResultFromJson(json);

/// Unique identifier for this geocode result
@override final  String id;
/// Original address that was geocoded
@override final  String originalAddress;
/// Formatted/standardized address from geocoder
@override final  String? formattedAddress;
/// Latitude coordinate
@override final  double latitude;
/// Longitude coordinate
@override final  double longitude;
/// Place ID (Google) or OSM ID for future reference
@override final  String? placeId;
/// Geocoding provider used
@override final  GeocodeProvider provider;
/// Accuracy level of the result
@override final  GeocodeAccuracy accuracy;
/// Confidence score (0.0-1.0) if available
@override final  double? confidence;
/// When this geocoding was performed
@override final  DateTime geocodedAt;
/// When this cache entry expires
@override final  DateTime expiresAt;
/// Address components (street, city, state, zip, country)
 final  Map<String, String>? _addressComponents;
/// Address components (street, city, state, zip, country)
@override Map<String, String>? get addressComponents {
  final value = _addressComponents;
  if (value == null) return null;
  if (_addressComponents is EqualUnmodifiableMapView) return _addressComponents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// Timezone at this location (e.g., "America/New_York")
@override final  String? timezone;
/// Viewport bounds for map display
@override final  GeocodeBounds? viewport;

/// Create a copy of GeocodeResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GeocodeResultCopyWith<_GeocodeResult> get copyWith => __$GeocodeResultCopyWithImpl<_GeocodeResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GeocodeResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GeocodeResult&&(identical(other.id, id) || other.id == id)&&(identical(other.originalAddress, originalAddress) || other.originalAddress == originalAddress)&&(identical(other.formattedAddress, formattedAddress) || other.formattedAddress == formattedAddress)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.placeId, placeId) || other.placeId == placeId)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.accuracy, accuracy) || other.accuracy == accuracy)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.geocodedAt, geocodedAt) || other.geocodedAt == geocodedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&const DeepCollectionEquality().equals(other._addressComponents, _addressComponents)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&(identical(other.viewport, viewport) || other.viewport == viewport));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,originalAddress,formattedAddress,latitude,longitude,placeId,provider,accuracy,confidence,geocodedAt,expiresAt,const DeepCollectionEquality().hash(_addressComponents),timezone,viewport);

@override
String toString() {
  return 'GeocodeResult(id: $id, originalAddress: $originalAddress, formattedAddress: $formattedAddress, latitude: $latitude, longitude: $longitude, placeId: $placeId, provider: $provider, accuracy: $accuracy, confidence: $confidence, geocodedAt: $geocodedAt, expiresAt: $expiresAt, addressComponents: $addressComponents, timezone: $timezone, viewport: $viewport)';
}


}

/// @nodoc
abstract mixin class _$GeocodeResultCopyWith<$Res> implements $GeocodeResultCopyWith<$Res> {
  factory _$GeocodeResultCopyWith(_GeocodeResult value, $Res Function(_GeocodeResult) _then) = __$GeocodeResultCopyWithImpl;
@override @useResult
$Res call({
 String id, String originalAddress, String? formattedAddress, double latitude, double longitude, String? placeId, GeocodeProvider provider, GeocodeAccuracy accuracy, double? confidence, DateTime geocodedAt, DateTime expiresAt, Map<String, String>? addressComponents, String? timezone, GeocodeBounds? viewport
});


@override $GeocodeBoundsCopyWith<$Res>? get viewport;

}
/// @nodoc
class __$GeocodeResultCopyWithImpl<$Res>
    implements _$GeocodeResultCopyWith<$Res> {
  __$GeocodeResultCopyWithImpl(this._self, this._then);

  final _GeocodeResult _self;
  final $Res Function(_GeocodeResult) _then;

/// Create a copy of GeocodeResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? originalAddress = null,Object? formattedAddress = freezed,Object? latitude = null,Object? longitude = null,Object? placeId = freezed,Object? provider = null,Object? accuracy = null,Object? confidence = freezed,Object? geocodedAt = null,Object? expiresAt = null,Object? addressComponents = freezed,Object? timezone = freezed,Object? viewport = freezed,}) {
  return _then(_GeocodeResult(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,originalAddress: null == originalAddress ? _self.originalAddress : originalAddress // ignore: cast_nullable_to_non_nullable
as String,formattedAddress: freezed == formattedAddress ? _self.formattedAddress : formattedAddress // ignore: cast_nullable_to_non_nullable
as String?,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,placeId: freezed == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String?,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as GeocodeProvider,accuracy: null == accuracy ? _self.accuracy : accuracy // ignore: cast_nullable_to_non_nullable
as GeocodeAccuracy,confidence: freezed == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double?,geocodedAt: null == geocodedAt ? _self.geocodedAt : geocodedAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,addressComponents: freezed == addressComponents ? _self._addressComponents : addressComponents // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,timezone: freezed == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String?,viewport: freezed == viewport ? _self.viewport : viewport // ignore: cast_nullable_to_non_nullable
as GeocodeBounds?,
  ));
}

/// Create a copy of GeocodeResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeocodeBoundsCopyWith<$Res>? get viewport {
    if (_self.viewport == null) {
    return null;
  }

  return $GeocodeBoundsCopyWith<$Res>(_self.viewport!, (value) {
    return _then(_self.copyWith(viewport: value));
  });
}
}

// dart format on
