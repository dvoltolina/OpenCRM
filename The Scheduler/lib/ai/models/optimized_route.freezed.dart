// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'optimized_route.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OptimizedRoute {

/// Unique identifier
 String get id;/// Business ID (multi-tenant)
 String get businessId;/// Provider this route is for
 String get providerId;/// Provider name for display
 String get providerName;/// Date this route is for
 DateTime get routeDate;/// Current status
 RouteStatus get status;// ============ Stops ============
/// All stops in optimized order (including depot)
 List<RouteStop> get stops;/// Travel segments between stops
 List<TravelSegment> get segments;// ============ Timing ============
/// When the route starts (departure from depot)
 DateTime get startTime;/// Expected end time (arrival back at depot or last stop)
 DateTime get expectedEndTime;/// Actual end time (filled when route completes)
 DateTime? get actualEndTime;// ============ Metrics ============
/// Total distance in meters
 int get totalDistanceMeters;/// Total estimated travel time in seconds
 int get totalTravelTimeSeconds;/// Total service time in seconds
 int get totalServiceTimeSeconds;// ============ Optimization Results ============
/// Distance of original (unoptimized) route in meters
 int? get originalDistanceMeters;/// Travel time of original route in seconds
 int? get originalTravelTimeSeconds;/// Distance saved by optimization (meters)
 int? get distanceSavedMeters;/// Time saved by optimization (seconds)
 int? get timeSavedSeconds;/// Percentage improvement in travel time
 double? get optimizationImprovementPercent;/// Optimization objective used
 OptimizationObjective? get objective;// ============ Metadata ============
/// Algorithm version used for optimization
 String get optimizerVersion;/// When this route was optimized
 DateTime get optimizedAt;/// When this route was last updated
 DateTime get updatedAt;/// Notes about this route
 String? get notes;
/// Create a copy of OptimizedRoute
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OptimizedRouteCopyWith<OptimizedRoute> get copyWith => _$OptimizedRouteCopyWithImpl<OptimizedRoute>(this as OptimizedRoute, _$identity);

  /// Serializes this OptimizedRoute to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OptimizedRoute&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.providerName, providerName) || other.providerName == providerName)&&(identical(other.routeDate, routeDate) || other.routeDate == routeDate)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.stops, stops)&&const DeepCollectionEquality().equals(other.segments, segments)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.expectedEndTime, expectedEndTime) || other.expectedEndTime == expectedEndTime)&&(identical(other.actualEndTime, actualEndTime) || other.actualEndTime == actualEndTime)&&(identical(other.totalDistanceMeters, totalDistanceMeters) || other.totalDistanceMeters == totalDistanceMeters)&&(identical(other.totalTravelTimeSeconds, totalTravelTimeSeconds) || other.totalTravelTimeSeconds == totalTravelTimeSeconds)&&(identical(other.totalServiceTimeSeconds, totalServiceTimeSeconds) || other.totalServiceTimeSeconds == totalServiceTimeSeconds)&&(identical(other.originalDistanceMeters, originalDistanceMeters) || other.originalDistanceMeters == originalDistanceMeters)&&(identical(other.originalTravelTimeSeconds, originalTravelTimeSeconds) || other.originalTravelTimeSeconds == originalTravelTimeSeconds)&&(identical(other.distanceSavedMeters, distanceSavedMeters) || other.distanceSavedMeters == distanceSavedMeters)&&(identical(other.timeSavedSeconds, timeSavedSeconds) || other.timeSavedSeconds == timeSavedSeconds)&&(identical(other.optimizationImprovementPercent, optimizationImprovementPercent) || other.optimizationImprovementPercent == optimizationImprovementPercent)&&(identical(other.objective, objective) || other.objective == objective)&&(identical(other.optimizerVersion, optimizerVersion) || other.optimizerVersion == optimizerVersion)&&(identical(other.optimizedAt, optimizedAt) || other.optimizedAt == optimizedAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,businessId,providerId,providerName,routeDate,status,const DeepCollectionEquality().hash(stops),const DeepCollectionEquality().hash(segments),startTime,expectedEndTime,actualEndTime,totalDistanceMeters,totalTravelTimeSeconds,totalServiceTimeSeconds,originalDistanceMeters,originalTravelTimeSeconds,distanceSavedMeters,timeSavedSeconds,optimizationImprovementPercent,objective,optimizerVersion,optimizedAt,updatedAt,notes]);

@override
String toString() {
  return 'OptimizedRoute(id: $id, businessId: $businessId, providerId: $providerId, providerName: $providerName, routeDate: $routeDate, status: $status, stops: $stops, segments: $segments, startTime: $startTime, expectedEndTime: $expectedEndTime, actualEndTime: $actualEndTime, totalDistanceMeters: $totalDistanceMeters, totalTravelTimeSeconds: $totalTravelTimeSeconds, totalServiceTimeSeconds: $totalServiceTimeSeconds, originalDistanceMeters: $originalDistanceMeters, originalTravelTimeSeconds: $originalTravelTimeSeconds, distanceSavedMeters: $distanceSavedMeters, timeSavedSeconds: $timeSavedSeconds, optimizationImprovementPercent: $optimizationImprovementPercent, objective: $objective, optimizerVersion: $optimizerVersion, optimizedAt: $optimizedAt, updatedAt: $updatedAt, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $OptimizedRouteCopyWith<$Res>  {
  factory $OptimizedRouteCopyWith(OptimizedRoute value, $Res Function(OptimizedRoute) _then) = _$OptimizedRouteCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String providerId, String providerName, DateTime routeDate, RouteStatus status, List<RouteStop> stops, List<TravelSegment> segments, DateTime startTime, DateTime expectedEndTime, DateTime? actualEndTime, int totalDistanceMeters, int totalTravelTimeSeconds, int totalServiceTimeSeconds, int? originalDistanceMeters, int? originalTravelTimeSeconds, int? distanceSavedMeters, int? timeSavedSeconds, double? optimizationImprovementPercent, OptimizationObjective? objective, String optimizerVersion, DateTime optimizedAt, DateTime updatedAt, String? notes
});




}
/// @nodoc
class _$OptimizedRouteCopyWithImpl<$Res>
    implements $OptimizedRouteCopyWith<$Res> {
  _$OptimizedRouteCopyWithImpl(this._self, this._then);

  final OptimizedRoute _self;
  final $Res Function(OptimizedRoute) _then;

/// Create a copy of OptimizedRoute
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? providerId = null,Object? providerName = null,Object? routeDate = null,Object? status = null,Object? stops = null,Object? segments = null,Object? startTime = null,Object? expectedEndTime = null,Object? actualEndTime = freezed,Object? totalDistanceMeters = null,Object? totalTravelTimeSeconds = null,Object? totalServiceTimeSeconds = null,Object? originalDistanceMeters = freezed,Object? originalTravelTimeSeconds = freezed,Object? distanceSavedMeters = freezed,Object? timeSavedSeconds = freezed,Object? optimizationImprovementPercent = freezed,Object? objective = freezed,Object? optimizerVersion = null,Object? optimizedAt = null,Object? updatedAt = null,Object? notes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,providerName: null == providerName ? _self.providerName : providerName // ignore: cast_nullable_to_non_nullable
as String,routeDate: null == routeDate ? _self.routeDate : routeDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RouteStatus,stops: null == stops ? _self.stops : stops // ignore: cast_nullable_to_non_nullable
as List<RouteStop>,segments: null == segments ? _self.segments : segments // ignore: cast_nullable_to_non_nullable
as List<TravelSegment>,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,expectedEndTime: null == expectedEndTime ? _self.expectedEndTime : expectedEndTime // ignore: cast_nullable_to_non_nullable
as DateTime,actualEndTime: freezed == actualEndTime ? _self.actualEndTime : actualEndTime // ignore: cast_nullable_to_non_nullable
as DateTime?,totalDistanceMeters: null == totalDistanceMeters ? _self.totalDistanceMeters : totalDistanceMeters // ignore: cast_nullable_to_non_nullable
as int,totalTravelTimeSeconds: null == totalTravelTimeSeconds ? _self.totalTravelTimeSeconds : totalTravelTimeSeconds // ignore: cast_nullable_to_non_nullable
as int,totalServiceTimeSeconds: null == totalServiceTimeSeconds ? _self.totalServiceTimeSeconds : totalServiceTimeSeconds // ignore: cast_nullable_to_non_nullable
as int,originalDistanceMeters: freezed == originalDistanceMeters ? _self.originalDistanceMeters : originalDistanceMeters // ignore: cast_nullable_to_non_nullable
as int?,originalTravelTimeSeconds: freezed == originalTravelTimeSeconds ? _self.originalTravelTimeSeconds : originalTravelTimeSeconds // ignore: cast_nullable_to_non_nullable
as int?,distanceSavedMeters: freezed == distanceSavedMeters ? _self.distanceSavedMeters : distanceSavedMeters // ignore: cast_nullable_to_non_nullable
as int?,timeSavedSeconds: freezed == timeSavedSeconds ? _self.timeSavedSeconds : timeSavedSeconds // ignore: cast_nullable_to_non_nullable
as int?,optimizationImprovementPercent: freezed == optimizationImprovementPercent ? _self.optimizationImprovementPercent : optimizationImprovementPercent // ignore: cast_nullable_to_non_nullable
as double?,objective: freezed == objective ? _self.objective : objective // ignore: cast_nullable_to_non_nullable
as OptimizationObjective?,optimizerVersion: null == optimizerVersion ? _self.optimizerVersion : optimizerVersion // ignore: cast_nullable_to_non_nullable
as String,optimizedAt: null == optimizedAt ? _self.optimizedAt : optimizedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [OptimizedRoute].
extension OptimizedRoutePatterns on OptimizedRoute {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OptimizedRoute value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OptimizedRoute() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OptimizedRoute value)  $default,){
final _that = this;
switch (_that) {
case _OptimizedRoute():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OptimizedRoute value)?  $default,){
final _that = this;
switch (_that) {
case _OptimizedRoute() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String providerId,  String providerName,  DateTime routeDate,  RouteStatus status,  List<RouteStop> stops,  List<TravelSegment> segments,  DateTime startTime,  DateTime expectedEndTime,  DateTime? actualEndTime,  int totalDistanceMeters,  int totalTravelTimeSeconds,  int totalServiceTimeSeconds,  int? originalDistanceMeters,  int? originalTravelTimeSeconds,  int? distanceSavedMeters,  int? timeSavedSeconds,  double? optimizationImprovementPercent,  OptimizationObjective? objective,  String optimizerVersion,  DateTime optimizedAt,  DateTime updatedAt,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OptimizedRoute() when $default != null:
return $default(_that.id,_that.businessId,_that.providerId,_that.providerName,_that.routeDate,_that.status,_that.stops,_that.segments,_that.startTime,_that.expectedEndTime,_that.actualEndTime,_that.totalDistanceMeters,_that.totalTravelTimeSeconds,_that.totalServiceTimeSeconds,_that.originalDistanceMeters,_that.originalTravelTimeSeconds,_that.distanceSavedMeters,_that.timeSavedSeconds,_that.optimizationImprovementPercent,_that.objective,_that.optimizerVersion,_that.optimizedAt,_that.updatedAt,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String providerId,  String providerName,  DateTime routeDate,  RouteStatus status,  List<RouteStop> stops,  List<TravelSegment> segments,  DateTime startTime,  DateTime expectedEndTime,  DateTime? actualEndTime,  int totalDistanceMeters,  int totalTravelTimeSeconds,  int totalServiceTimeSeconds,  int? originalDistanceMeters,  int? originalTravelTimeSeconds,  int? distanceSavedMeters,  int? timeSavedSeconds,  double? optimizationImprovementPercent,  OptimizationObjective? objective,  String optimizerVersion,  DateTime optimizedAt,  DateTime updatedAt,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _OptimizedRoute():
return $default(_that.id,_that.businessId,_that.providerId,_that.providerName,_that.routeDate,_that.status,_that.stops,_that.segments,_that.startTime,_that.expectedEndTime,_that.actualEndTime,_that.totalDistanceMeters,_that.totalTravelTimeSeconds,_that.totalServiceTimeSeconds,_that.originalDistanceMeters,_that.originalTravelTimeSeconds,_that.distanceSavedMeters,_that.timeSavedSeconds,_that.optimizationImprovementPercent,_that.objective,_that.optimizerVersion,_that.optimizedAt,_that.updatedAt,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String providerId,  String providerName,  DateTime routeDate,  RouteStatus status,  List<RouteStop> stops,  List<TravelSegment> segments,  DateTime startTime,  DateTime expectedEndTime,  DateTime? actualEndTime,  int totalDistanceMeters,  int totalTravelTimeSeconds,  int totalServiceTimeSeconds,  int? originalDistanceMeters,  int? originalTravelTimeSeconds,  int? distanceSavedMeters,  int? timeSavedSeconds,  double? optimizationImprovementPercent,  OptimizationObjective? objective,  String optimizerVersion,  DateTime optimizedAt,  DateTime updatedAt,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _OptimizedRoute() when $default != null:
return $default(_that.id,_that.businessId,_that.providerId,_that.providerName,_that.routeDate,_that.status,_that.stops,_that.segments,_that.startTime,_that.expectedEndTime,_that.actualEndTime,_that.totalDistanceMeters,_that.totalTravelTimeSeconds,_that.totalServiceTimeSeconds,_that.originalDistanceMeters,_that.originalTravelTimeSeconds,_that.distanceSavedMeters,_that.timeSavedSeconds,_that.optimizationImprovementPercent,_that.objective,_that.optimizerVersion,_that.optimizedAt,_that.updatedAt,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OptimizedRoute implements OptimizedRoute {
  const _OptimizedRoute({required this.id, required this.businessId, required this.providerId, required this.providerName, required this.routeDate, this.status = RouteStatus.planned, required final  List<RouteStop> stops, required final  List<TravelSegment> segments, required this.startTime, required this.expectedEndTime, this.actualEndTime, required this.totalDistanceMeters, required this.totalTravelTimeSeconds, required this.totalServiceTimeSeconds, this.originalDistanceMeters, this.originalTravelTimeSeconds, this.distanceSavedMeters, this.timeSavedSeconds, this.optimizationImprovementPercent, this.objective, required this.optimizerVersion, required this.optimizedAt, required this.updatedAt, this.notes}): _stops = stops,_segments = segments;
  factory _OptimizedRoute.fromJson(Map<String, dynamic> json) => _$OptimizedRouteFromJson(json);

/// Unique identifier
@override final  String id;
/// Business ID (multi-tenant)
@override final  String businessId;
/// Provider this route is for
@override final  String providerId;
/// Provider name for display
@override final  String providerName;
/// Date this route is for
@override final  DateTime routeDate;
/// Current status
@override@JsonKey() final  RouteStatus status;
// ============ Stops ============
/// All stops in optimized order (including depot)
 final  List<RouteStop> _stops;
// ============ Stops ============
/// All stops in optimized order (including depot)
@override List<RouteStop> get stops {
  if (_stops is EqualUnmodifiableListView) return _stops;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_stops);
}

/// Travel segments between stops
 final  List<TravelSegment> _segments;
/// Travel segments between stops
@override List<TravelSegment> get segments {
  if (_segments is EqualUnmodifiableListView) return _segments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_segments);
}

// ============ Timing ============
/// When the route starts (departure from depot)
@override final  DateTime startTime;
/// Expected end time (arrival back at depot or last stop)
@override final  DateTime expectedEndTime;
/// Actual end time (filled when route completes)
@override final  DateTime? actualEndTime;
// ============ Metrics ============
/// Total distance in meters
@override final  int totalDistanceMeters;
/// Total estimated travel time in seconds
@override final  int totalTravelTimeSeconds;
/// Total service time in seconds
@override final  int totalServiceTimeSeconds;
// ============ Optimization Results ============
/// Distance of original (unoptimized) route in meters
@override final  int? originalDistanceMeters;
/// Travel time of original route in seconds
@override final  int? originalTravelTimeSeconds;
/// Distance saved by optimization (meters)
@override final  int? distanceSavedMeters;
/// Time saved by optimization (seconds)
@override final  int? timeSavedSeconds;
/// Percentage improvement in travel time
@override final  double? optimizationImprovementPercent;
/// Optimization objective used
@override final  OptimizationObjective? objective;
// ============ Metadata ============
/// Algorithm version used for optimization
@override final  String optimizerVersion;
/// When this route was optimized
@override final  DateTime optimizedAt;
/// When this route was last updated
@override final  DateTime updatedAt;
/// Notes about this route
@override final  String? notes;

/// Create a copy of OptimizedRoute
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OptimizedRouteCopyWith<_OptimizedRoute> get copyWith => __$OptimizedRouteCopyWithImpl<_OptimizedRoute>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OptimizedRouteToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OptimizedRoute&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.providerName, providerName) || other.providerName == providerName)&&(identical(other.routeDate, routeDate) || other.routeDate == routeDate)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._stops, _stops)&&const DeepCollectionEquality().equals(other._segments, _segments)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.expectedEndTime, expectedEndTime) || other.expectedEndTime == expectedEndTime)&&(identical(other.actualEndTime, actualEndTime) || other.actualEndTime == actualEndTime)&&(identical(other.totalDistanceMeters, totalDistanceMeters) || other.totalDistanceMeters == totalDistanceMeters)&&(identical(other.totalTravelTimeSeconds, totalTravelTimeSeconds) || other.totalTravelTimeSeconds == totalTravelTimeSeconds)&&(identical(other.totalServiceTimeSeconds, totalServiceTimeSeconds) || other.totalServiceTimeSeconds == totalServiceTimeSeconds)&&(identical(other.originalDistanceMeters, originalDistanceMeters) || other.originalDistanceMeters == originalDistanceMeters)&&(identical(other.originalTravelTimeSeconds, originalTravelTimeSeconds) || other.originalTravelTimeSeconds == originalTravelTimeSeconds)&&(identical(other.distanceSavedMeters, distanceSavedMeters) || other.distanceSavedMeters == distanceSavedMeters)&&(identical(other.timeSavedSeconds, timeSavedSeconds) || other.timeSavedSeconds == timeSavedSeconds)&&(identical(other.optimizationImprovementPercent, optimizationImprovementPercent) || other.optimizationImprovementPercent == optimizationImprovementPercent)&&(identical(other.objective, objective) || other.objective == objective)&&(identical(other.optimizerVersion, optimizerVersion) || other.optimizerVersion == optimizerVersion)&&(identical(other.optimizedAt, optimizedAt) || other.optimizedAt == optimizedAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,businessId,providerId,providerName,routeDate,status,const DeepCollectionEquality().hash(_stops),const DeepCollectionEquality().hash(_segments),startTime,expectedEndTime,actualEndTime,totalDistanceMeters,totalTravelTimeSeconds,totalServiceTimeSeconds,originalDistanceMeters,originalTravelTimeSeconds,distanceSavedMeters,timeSavedSeconds,optimizationImprovementPercent,objective,optimizerVersion,optimizedAt,updatedAt,notes]);

@override
String toString() {
  return 'OptimizedRoute(id: $id, businessId: $businessId, providerId: $providerId, providerName: $providerName, routeDate: $routeDate, status: $status, stops: $stops, segments: $segments, startTime: $startTime, expectedEndTime: $expectedEndTime, actualEndTime: $actualEndTime, totalDistanceMeters: $totalDistanceMeters, totalTravelTimeSeconds: $totalTravelTimeSeconds, totalServiceTimeSeconds: $totalServiceTimeSeconds, originalDistanceMeters: $originalDistanceMeters, originalTravelTimeSeconds: $originalTravelTimeSeconds, distanceSavedMeters: $distanceSavedMeters, timeSavedSeconds: $timeSavedSeconds, optimizationImprovementPercent: $optimizationImprovementPercent, objective: $objective, optimizerVersion: $optimizerVersion, optimizedAt: $optimizedAt, updatedAt: $updatedAt, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$OptimizedRouteCopyWith<$Res> implements $OptimizedRouteCopyWith<$Res> {
  factory _$OptimizedRouteCopyWith(_OptimizedRoute value, $Res Function(_OptimizedRoute) _then) = __$OptimizedRouteCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String providerId, String providerName, DateTime routeDate, RouteStatus status, List<RouteStop> stops, List<TravelSegment> segments, DateTime startTime, DateTime expectedEndTime, DateTime? actualEndTime, int totalDistanceMeters, int totalTravelTimeSeconds, int totalServiceTimeSeconds, int? originalDistanceMeters, int? originalTravelTimeSeconds, int? distanceSavedMeters, int? timeSavedSeconds, double? optimizationImprovementPercent, OptimizationObjective? objective, String optimizerVersion, DateTime optimizedAt, DateTime updatedAt, String? notes
});




}
/// @nodoc
class __$OptimizedRouteCopyWithImpl<$Res>
    implements _$OptimizedRouteCopyWith<$Res> {
  __$OptimizedRouteCopyWithImpl(this._self, this._then);

  final _OptimizedRoute _self;
  final $Res Function(_OptimizedRoute) _then;

/// Create a copy of OptimizedRoute
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? providerId = null,Object? providerName = null,Object? routeDate = null,Object? status = null,Object? stops = null,Object? segments = null,Object? startTime = null,Object? expectedEndTime = null,Object? actualEndTime = freezed,Object? totalDistanceMeters = null,Object? totalTravelTimeSeconds = null,Object? totalServiceTimeSeconds = null,Object? originalDistanceMeters = freezed,Object? originalTravelTimeSeconds = freezed,Object? distanceSavedMeters = freezed,Object? timeSavedSeconds = freezed,Object? optimizationImprovementPercent = freezed,Object? objective = freezed,Object? optimizerVersion = null,Object? optimizedAt = null,Object? updatedAt = null,Object? notes = freezed,}) {
  return _then(_OptimizedRoute(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,providerName: null == providerName ? _self.providerName : providerName // ignore: cast_nullable_to_non_nullable
as String,routeDate: null == routeDate ? _self.routeDate : routeDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RouteStatus,stops: null == stops ? _self._stops : stops // ignore: cast_nullable_to_non_nullable
as List<RouteStop>,segments: null == segments ? _self._segments : segments // ignore: cast_nullable_to_non_nullable
as List<TravelSegment>,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,expectedEndTime: null == expectedEndTime ? _self.expectedEndTime : expectedEndTime // ignore: cast_nullable_to_non_nullable
as DateTime,actualEndTime: freezed == actualEndTime ? _self.actualEndTime : actualEndTime // ignore: cast_nullable_to_non_nullable
as DateTime?,totalDistanceMeters: null == totalDistanceMeters ? _self.totalDistanceMeters : totalDistanceMeters // ignore: cast_nullable_to_non_nullable
as int,totalTravelTimeSeconds: null == totalTravelTimeSeconds ? _self.totalTravelTimeSeconds : totalTravelTimeSeconds // ignore: cast_nullable_to_non_nullable
as int,totalServiceTimeSeconds: null == totalServiceTimeSeconds ? _self.totalServiceTimeSeconds : totalServiceTimeSeconds // ignore: cast_nullable_to_non_nullable
as int,originalDistanceMeters: freezed == originalDistanceMeters ? _self.originalDistanceMeters : originalDistanceMeters // ignore: cast_nullable_to_non_nullable
as int?,originalTravelTimeSeconds: freezed == originalTravelTimeSeconds ? _self.originalTravelTimeSeconds : originalTravelTimeSeconds // ignore: cast_nullable_to_non_nullable
as int?,distanceSavedMeters: freezed == distanceSavedMeters ? _self.distanceSavedMeters : distanceSavedMeters // ignore: cast_nullable_to_non_nullable
as int?,timeSavedSeconds: freezed == timeSavedSeconds ? _self.timeSavedSeconds : timeSavedSeconds // ignore: cast_nullable_to_non_nullable
as int?,optimizationImprovementPercent: freezed == optimizationImprovementPercent ? _self.optimizationImprovementPercent : optimizationImprovementPercent // ignore: cast_nullable_to_non_nullable
as double?,objective: freezed == objective ? _self.objective : objective // ignore: cast_nullable_to_non_nullable
as OptimizationObjective?,optimizerVersion: null == optimizerVersion ? _self.optimizerVersion : optimizerVersion // ignore: cast_nullable_to_non_nullable
as String,optimizedAt: null == optimizedAt ? _self.optimizedAt : optimizedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
