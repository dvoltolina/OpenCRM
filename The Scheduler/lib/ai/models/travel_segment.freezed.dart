// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'travel_segment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TravelSegment {

/// Unique identifier
 String get id;/// Route this segment belongs to
 String get routeId;/// Origin stop ID
 String get fromStopId;/// Destination stop ID
 String get toStopId;/// Sequence in route (matches destination stop sequence)
 int get sequenceOrder;// ============ Distance & Time ============
/// Distance in meters
 int get distanceMeters;/// Estimated duration in seconds (from OSRM)
 int get estimatedDurationSeconds;/// Actual duration in seconds (filled after travel)
 int? get actualDurationSeconds;/// Traffic condition at time of estimation
 TrafficCondition get trafficCondition;// ============ Geometry ============
/// Encoded polyline for map display (Google format)
 String? get encodedPolyline;/// Turn-by-turn instructions (optional)
 List<String>? get turnInstructions;// ============ Waypoints ============
/// Origin coordinates
 double get fromLatitude; double get fromLongitude;/// Destination coordinates
 double get toLatitude; double get toLongitude;// ============ Metadata ============
/// When this segment was calculated
 DateTime get calculatedAt;/// Source of routing data (osrm, google, etc.)
 String get routingSource;
/// Create a copy of TravelSegment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TravelSegmentCopyWith<TravelSegment> get copyWith => _$TravelSegmentCopyWithImpl<TravelSegment>(this as TravelSegment, _$identity);

  /// Serializes this TravelSegment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TravelSegment&&(identical(other.id, id) || other.id == id)&&(identical(other.routeId, routeId) || other.routeId == routeId)&&(identical(other.fromStopId, fromStopId) || other.fromStopId == fromStopId)&&(identical(other.toStopId, toStopId) || other.toStopId == toStopId)&&(identical(other.sequenceOrder, sequenceOrder) || other.sequenceOrder == sequenceOrder)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&(identical(other.estimatedDurationSeconds, estimatedDurationSeconds) || other.estimatedDurationSeconds == estimatedDurationSeconds)&&(identical(other.actualDurationSeconds, actualDurationSeconds) || other.actualDurationSeconds == actualDurationSeconds)&&(identical(other.trafficCondition, trafficCondition) || other.trafficCondition == trafficCondition)&&(identical(other.encodedPolyline, encodedPolyline) || other.encodedPolyline == encodedPolyline)&&const DeepCollectionEquality().equals(other.turnInstructions, turnInstructions)&&(identical(other.fromLatitude, fromLatitude) || other.fromLatitude == fromLatitude)&&(identical(other.fromLongitude, fromLongitude) || other.fromLongitude == fromLongitude)&&(identical(other.toLatitude, toLatitude) || other.toLatitude == toLatitude)&&(identical(other.toLongitude, toLongitude) || other.toLongitude == toLongitude)&&(identical(other.calculatedAt, calculatedAt) || other.calculatedAt == calculatedAt)&&(identical(other.routingSource, routingSource) || other.routingSource == routingSource));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,routeId,fromStopId,toStopId,sequenceOrder,distanceMeters,estimatedDurationSeconds,actualDurationSeconds,trafficCondition,encodedPolyline,const DeepCollectionEquality().hash(turnInstructions),fromLatitude,fromLongitude,toLatitude,toLongitude,calculatedAt,routingSource);

@override
String toString() {
  return 'TravelSegment(id: $id, routeId: $routeId, fromStopId: $fromStopId, toStopId: $toStopId, sequenceOrder: $sequenceOrder, distanceMeters: $distanceMeters, estimatedDurationSeconds: $estimatedDurationSeconds, actualDurationSeconds: $actualDurationSeconds, trafficCondition: $trafficCondition, encodedPolyline: $encodedPolyline, turnInstructions: $turnInstructions, fromLatitude: $fromLatitude, fromLongitude: $fromLongitude, toLatitude: $toLatitude, toLongitude: $toLongitude, calculatedAt: $calculatedAt, routingSource: $routingSource)';
}


}

/// @nodoc
abstract mixin class $TravelSegmentCopyWith<$Res>  {
  factory $TravelSegmentCopyWith(TravelSegment value, $Res Function(TravelSegment) _then) = _$TravelSegmentCopyWithImpl;
@useResult
$Res call({
 String id, String routeId, String fromStopId, String toStopId, int sequenceOrder, int distanceMeters, int estimatedDurationSeconds, int? actualDurationSeconds, TrafficCondition trafficCondition, String? encodedPolyline, List<String>? turnInstructions, double fromLatitude, double fromLongitude, double toLatitude, double toLongitude, DateTime calculatedAt, String routingSource
});




}
/// @nodoc
class _$TravelSegmentCopyWithImpl<$Res>
    implements $TravelSegmentCopyWith<$Res> {
  _$TravelSegmentCopyWithImpl(this._self, this._then);

  final TravelSegment _self;
  final $Res Function(TravelSegment) _then;

/// Create a copy of TravelSegment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? routeId = null,Object? fromStopId = null,Object? toStopId = null,Object? sequenceOrder = null,Object? distanceMeters = null,Object? estimatedDurationSeconds = null,Object? actualDurationSeconds = freezed,Object? trafficCondition = null,Object? encodedPolyline = freezed,Object? turnInstructions = freezed,Object? fromLatitude = null,Object? fromLongitude = null,Object? toLatitude = null,Object? toLongitude = null,Object? calculatedAt = null,Object? routingSource = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,routeId: null == routeId ? _self.routeId : routeId // ignore: cast_nullable_to_non_nullable
as String,fromStopId: null == fromStopId ? _self.fromStopId : fromStopId // ignore: cast_nullable_to_non_nullable
as String,toStopId: null == toStopId ? _self.toStopId : toStopId // ignore: cast_nullable_to_non_nullable
as String,sequenceOrder: null == sequenceOrder ? _self.sequenceOrder : sequenceOrder // ignore: cast_nullable_to_non_nullable
as int,distanceMeters: null == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as int,estimatedDurationSeconds: null == estimatedDurationSeconds ? _self.estimatedDurationSeconds : estimatedDurationSeconds // ignore: cast_nullable_to_non_nullable
as int,actualDurationSeconds: freezed == actualDurationSeconds ? _self.actualDurationSeconds : actualDurationSeconds // ignore: cast_nullable_to_non_nullable
as int?,trafficCondition: null == trafficCondition ? _self.trafficCondition : trafficCondition // ignore: cast_nullable_to_non_nullable
as TrafficCondition,encodedPolyline: freezed == encodedPolyline ? _self.encodedPolyline : encodedPolyline // ignore: cast_nullable_to_non_nullable
as String?,turnInstructions: freezed == turnInstructions ? _self.turnInstructions : turnInstructions // ignore: cast_nullable_to_non_nullable
as List<String>?,fromLatitude: null == fromLatitude ? _self.fromLatitude : fromLatitude // ignore: cast_nullable_to_non_nullable
as double,fromLongitude: null == fromLongitude ? _self.fromLongitude : fromLongitude // ignore: cast_nullable_to_non_nullable
as double,toLatitude: null == toLatitude ? _self.toLatitude : toLatitude // ignore: cast_nullable_to_non_nullable
as double,toLongitude: null == toLongitude ? _self.toLongitude : toLongitude // ignore: cast_nullable_to_non_nullable
as double,calculatedAt: null == calculatedAt ? _self.calculatedAt : calculatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,routingSource: null == routingSource ? _self.routingSource : routingSource // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TravelSegment].
extension TravelSegmentPatterns on TravelSegment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TravelSegment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TravelSegment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TravelSegment value)  $default,){
final _that = this;
switch (_that) {
case _TravelSegment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TravelSegment value)?  $default,){
final _that = this;
switch (_that) {
case _TravelSegment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String routeId,  String fromStopId,  String toStopId,  int sequenceOrder,  int distanceMeters,  int estimatedDurationSeconds,  int? actualDurationSeconds,  TrafficCondition trafficCondition,  String? encodedPolyline,  List<String>? turnInstructions,  double fromLatitude,  double fromLongitude,  double toLatitude,  double toLongitude,  DateTime calculatedAt,  String routingSource)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TravelSegment() when $default != null:
return $default(_that.id,_that.routeId,_that.fromStopId,_that.toStopId,_that.sequenceOrder,_that.distanceMeters,_that.estimatedDurationSeconds,_that.actualDurationSeconds,_that.trafficCondition,_that.encodedPolyline,_that.turnInstructions,_that.fromLatitude,_that.fromLongitude,_that.toLatitude,_that.toLongitude,_that.calculatedAt,_that.routingSource);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String routeId,  String fromStopId,  String toStopId,  int sequenceOrder,  int distanceMeters,  int estimatedDurationSeconds,  int? actualDurationSeconds,  TrafficCondition trafficCondition,  String? encodedPolyline,  List<String>? turnInstructions,  double fromLatitude,  double fromLongitude,  double toLatitude,  double toLongitude,  DateTime calculatedAt,  String routingSource)  $default,) {final _that = this;
switch (_that) {
case _TravelSegment():
return $default(_that.id,_that.routeId,_that.fromStopId,_that.toStopId,_that.sequenceOrder,_that.distanceMeters,_that.estimatedDurationSeconds,_that.actualDurationSeconds,_that.trafficCondition,_that.encodedPolyline,_that.turnInstructions,_that.fromLatitude,_that.fromLongitude,_that.toLatitude,_that.toLongitude,_that.calculatedAt,_that.routingSource);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String routeId,  String fromStopId,  String toStopId,  int sequenceOrder,  int distanceMeters,  int estimatedDurationSeconds,  int? actualDurationSeconds,  TrafficCondition trafficCondition,  String? encodedPolyline,  List<String>? turnInstructions,  double fromLatitude,  double fromLongitude,  double toLatitude,  double toLongitude,  DateTime calculatedAt,  String routingSource)?  $default,) {final _that = this;
switch (_that) {
case _TravelSegment() when $default != null:
return $default(_that.id,_that.routeId,_that.fromStopId,_that.toStopId,_that.sequenceOrder,_that.distanceMeters,_that.estimatedDurationSeconds,_that.actualDurationSeconds,_that.trafficCondition,_that.encodedPolyline,_that.turnInstructions,_that.fromLatitude,_that.fromLongitude,_that.toLatitude,_that.toLongitude,_that.calculatedAt,_that.routingSource);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TravelSegment implements TravelSegment {
  const _TravelSegment({required this.id, required this.routeId, required this.fromStopId, required this.toStopId, required this.sequenceOrder, required this.distanceMeters, required this.estimatedDurationSeconds, this.actualDurationSeconds, this.trafficCondition = TrafficCondition.unknown, this.encodedPolyline, final  List<String>? turnInstructions, required this.fromLatitude, required this.fromLongitude, required this.toLatitude, required this.toLongitude, required this.calculatedAt, required this.routingSource}): _turnInstructions = turnInstructions;
  factory _TravelSegment.fromJson(Map<String, dynamic> json) => _$TravelSegmentFromJson(json);

/// Unique identifier
@override final  String id;
/// Route this segment belongs to
@override final  String routeId;
/// Origin stop ID
@override final  String fromStopId;
/// Destination stop ID
@override final  String toStopId;
/// Sequence in route (matches destination stop sequence)
@override final  int sequenceOrder;
// ============ Distance & Time ============
/// Distance in meters
@override final  int distanceMeters;
/// Estimated duration in seconds (from OSRM)
@override final  int estimatedDurationSeconds;
/// Actual duration in seconds (filled after travel)
@override final  int? actualDurationSeconds;
/// Traffic condition at time of estimation
@override@JsonKey() final  TrafficCondition trafficCondition;
// ============ Geometry ============
/// Encoded polyline for map display (Google format)
@override final  String? encodedPolyline;
/// Turn-by-turn instructions (optional)
 final  List<String>? _turnInstructions;
/// Turn-by-turn instructions (optional)
@override List<String>? get turnInstructions {
  final value = _turnInstructions;
  if (value == null) return null;
  if (_turnInstructions is EqualUnmodifiableListView) return _turnInstructions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

// ============ Waypoints ============
/// Origin coordinates
@override final  double fromLatitude;
@override final  double fromLongitude;
/// Destination coordinates
@override final  double toLatitude;
@override final  double toLongitude;
// ============ Metadata ============
/// When this segment was calculated
@override final  DateTime calculatedAt;
/// Source of routing data (osrm, google, etc.)
@override final  String routingSource;

/// Create a copy of TravelSegment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TravelSegmentCopyWith<_TravelSegment> get copyWith => __$TravelSegmentCopyWithImpl<_TravelSegment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TravelSegmentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TravelSegment&&(identical(other.id, id) || other.id == id)&&(identical(other.routeId, routeId) || other.routeId == routeId)&&(identical(other.fromStopId, fromStopId) || other.fromStopId == fromStopId)&&(identical(other.toStopId, toStopId) || other.toStopId == toStopId)&&(identical(other.sequenceOrder, sequenceOrder) || other.sequenceOrder == sequenceOrder)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&(identical(other.estimatedDurationSeconds, estimatedDurationSeconds) || other.estimatedDurationSeconds == estimatedDurationSeconds)&&(identical(other.actualDurationSeconds, actualDurationSeconds) || other.actualDurationSeconds == actualDurationSeconds)&&(identical(other.trafficCondition, trafficCondition) || other.trafficCondition == trafficCondition)&&(identical(other.encodedPolyline, encodedPolyline) || other.encodedPolyline == encodedPolyline)&&const DeepCollectionEquality().equals(other._turnInstructions, _turnInstructions)&&(identical(other.fromLatitude, fromLatitude) || other.fromLatitude == fromLatitude)&&(identical(other.fromLongitude, fromLongitude) || other.fromLongitude == fromLongitude)&&(identical(other.toLatitude, toLatitude) || other.toLatitude == toLatitude)&&(identical(other.toLongitude, toLongitude) || other.toLongitude == toLongitude)&&(identical(other.calculatedAt, calculatedAt) || other.calculatedAt == calculatedAt)&&(identical(other.routingSource, routingSource) || other.routingSource == routingSource));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,routeId,fromStopId,toStopId,sequenceOrder,distanceMeters,estimatedDurationSeconds,actualDurationSeconds,trafficCondition,encodedPolyline,const DeepCollectionEquality().hash(_turnInstructions),fromLatitude,fromLongitude,toLatitude,toLongitude,calculatedAt,routingSource);

@override
String toString() {
  return 'TravelSegment(id: $id, routeId: $routeId, fromStopId: $fromStopId, toStopId: $toStopId, sequenceOrder: $sequenceOrder, distanceMeters: $distanceMeters, estimatedDurationSeconds: $estimatedDurationSeconds, actualDurationSeconds: $actualDurationSeconds, trafficCondition: $trafficCondition, encodedPolyline: $encodedPolyline, turnInstructions: $turnInstructions, fromLatitude: $fromLatitude, fromLongitude: $fromLongitude, toLatitude: $toLatitude, toLongitude: $toLongitude, calculatedAt: $calculatedAt, routingSource: $routingSource)';
}


}

/// @nodoc
abstract mixin class _$TravelSegmentCopyWith<$Res> implements $TravelSegmentCopyWith<$Res> {
  factory _$TravelSegmentCopyWith(_TravelSegment value, $Res Function(_TravelSegment) _then) = __$TravelSegmentCopyWithImpl;
@override @useResult
$Res call({
 String id, String routeId, String fromStopId, String toStopId, int sequenceOrder, int distanceMeters, int estimatedDurationSeconds, int? actualDurationSeconds, TrafficCondition trafficCondition, String? encodedPolyline, List<String>? turnInstructions, double fromLatitude, double fromLongitude, double toLatitude, double toLongitude, DateTime calculatedAt, String routingSource
});




}
/// @nodoc
class __$TravelSegmentCopyWithImpl<$Res>
    implements _$TravelSegmentCopyWith<$Res> {
  __$TravelSegmentCopyWithImpl(this._self, this._then);

  final _TravelSegment _self;
  final $Res Function(_TravelSegment) _then;

/// Create a copy of TravelSegment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? routeId = null,Object? fromStopId = null,Object? toStopId = null,Object? sequenceOrder = null,Object? distanceMeters = null,Object? estimatedDurationSeconds = null,Object? actualDurationSeconds = freezed,Object? trafficCondition = null,Object? encodedPolyline = freezed,Object? turnInstructions = freezed,Object? fromLatitude = null,Object? fromLongitude = null,Object? toLatitude = null,Object? toLongitude = null,Object? calculatedAt = null,Object? routingSource = null,}) {
  return _then(_TravelSegment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,routeId: null == routeId ? _self.routeId : routeId // ignore: cast_nullable_to_non_nullable
as String,fromStopId: null == fromStopId ? _self.fromStopId : fromStopId // ignore: cast_nullable_to_non_nullable
as String,toStopId: null == toStopId ? _self.toStopId : toStopId // ignore: cast_nullable_to_non_nullable
as String,sequenceOrder: null == sequenceOrder ? _self.sequenceOrder : sequenceOrder // ignore: cast_nullable_to_non_nullable
as int,distanceMeters: null == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as int,estimatedDurationSeconds: null == estimatedDurationSeconds ? _self.estimatedDurationSeconds : estimatedDurationSeconds // ignore: cast_nullable_to_non_nullable
as int,actualDurationSeconds: freezed == actualDurationSeconds ? _self.actualDurationSeconds : actualDurationSeconds // ignore: cast_nullable_to_non_nullable
as int?,trafficCondition: null == trafficCondition ? _self.trafficCondition : trafficCondition // ignore: cast_nullable_to_non_nullable
as TrafficCondition,encodedPolyline: freezed == encodedPolyline ? _self.encodedPolyline : encodedPolyline // ignore: cast_nullable_to_non_nullable
as String?,turnInstructions: freezed == turnInstructions ? _self._turnInstructions : turnInstructions // ignore: cast_nullable_to_non_nullable
as List<String>?,fromLatitude: null == fromLatitude ? _self.fromLatitude : fromLatitude // ignore: cast_nullable_to_non_nullable
as double,fromLongitude: null == fromLongitude ? _self.fromLongitude : fromLongitude // ignore: cast_nullable_to_non_nullable
as double,toLatitude: null == toLatitude ? _self.toLatitude : toLatitude // ignore: cast_nullable_to_non_nullable
as double,toLongitude: null == toLongitude ? _self.toLongitude : toLongitude // ignore: cast_nullable_to_non_nullable
as double,calculatedAt: null == calculatedAt ? _self.calculatedAt : calculatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,routingSource: null == routingSource ? _self.routingSource : routingSource // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
