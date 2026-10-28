// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'route_optimization_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RouteWaypoint {

/// Unique identifier (usually appointment ID)
 String get id;/// Display name
 String get name;/// Latitude
 double get latitude;/// Longitude
 double get longitude;/// Earliest arrival time (window start)
 DateTime get windowStart;/// Latest arrival time (window end)
 DateTime get windowEnd;/// Service duration at this location (minutes)
 int get serviceDurationMinutes;/// Priority (higher = more important to visit on time)
 int get priority;/// Whether this waypoint is required (vs optional)
 bool get isRequired;/// Associated client ID
 String? get clientId;/// Associated appointment ID
 String? get appointmentId;
/// Create a copy of RouteWaypoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RouteWaypointCopyWith<RouteWaypoint> get copyWith => _$RouteWaypointCopyWithImpl<RouteWaypoint>(this as RouteWaypoint, _$identity);

  /// Serializes this RouteWaypoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RouteWaypoint&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.windowStart, windowStart) || other.windowStart == windowStart)&&(identical(other.windowEnd, windowEnd) || other.windowEnd == windowEnd)&&(identical(other.serviceDurationMinutes, serviceDurationMinutes) || other.serviceDurationMinutes == serviceDurationMinutes)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.isRequired, isRequired) || other.isRequired == isRequired)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,latitude,longitude,windowStart,windowEnd,serviceDurationMinutes,priority,isRequired,clientId,appointmentId);

@override
String toString() {
  return 'RouteWaypoint(id: $id, name: $name, latitude: $latitude, longitude: $longitude, windowStart: $windowStart, windowEnd: $windowEnd, serviceDurationMinutes: $serviceDurationMinutes, priority: $priority, isRequired: $isRequired, clientId: $clientId, appointmentId: $appointmentId)';
}


}

/// @nodoc
abstract mixin class $RouteWaypointCopyWith<$Res>  {
  factory $RouteWaypointCopyWith(RouteWaypoint value, $Res Function(RouteWaypoint) _then) = _$RouteWaypointCopyWithImpl;
@useResult
$Res call({
 String id, String name, double latitude, double longitude, DateTime windowStart, DateTime windowEnd, int serviceDurationMinutes, int priority, bool isRequired, String? clientId, String? appointmentId
});




}
/// @nodoc
class _$RouteWaypointCopyWithImpl<$Res>
    implements $RouteWaypointCopyWith<$Res> {
  _$RouteWaypointCopyWithImpl(this._self, this._then);

  final RouteWaypoint _self;
  final $Res Function(RouteWaypoint) _then;

/// Create a copy of RouteWaypoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? latitude = null,Object? longitude = null,Object? windowStart = null,Object? windowEnd = null,Object? serviceDurationMinutes = null,Object? priority = null,Object? isRequired = null,Object? clientId = freezed,Object? appointmentId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,windowStart: null == windowStart ? _self.windowStart : windowStart // ignore: cast_nullable_to_non_nullable
as DateTime,windowEnd: null == windowEnd ? _self.windowEnd : windowEnd // ignore: cast_nullable_to_non_nullable
as DateTime,serviceDurationMinutes: null == serviceDurationMinutes ? _self.serviceDurationMinutes : serviceDurationMinutes // ignore: cast_nullable_to_non_nullable
as int,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,isRequired: null == isRequired ? _self.isRequired : isRequired // ignore: cast_nullable_to_non_nullable
as bool,clientId: freezed == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String?,appointmentId: freezed == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RouteWaypoint].
extension RouteWaypointPatterns on RouteWaypoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RouteWaypoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RouteWaypoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RouteWaypoint value)  $default,){
final _that = this;
switch (_that) {
case _RouteWaypoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RouteWaypoint value)?  $default,){
final _that = this;
switch (_that) {
case _RouteWaypoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  double latitude,  double longitude,  DateTime windowStart,  DateTime windowEnd,  int serviceDurationMinutes,  int priority,  bool isRequired,  String? clientId,  String? appointmentId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RouteWaypoint() when $default != null:
return $default(_that.id,_that.name,_that.latitude,_that.longitude,_that.windowStart,_that.windowEnd,_that.serviceDurationMinutes,_that.priority,_that.isRequired,_that.clientId,_that.appointmentId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  double latitude,  double longitude,  DateTime windowStart,  DateTime windowEnd,  int serviceDurationMinutes,  int priority,  bool isRequired,  String? clientId,  String? appointmentId)  $default,) {final _that = this;
switch (_that) {
case _RouteWaypoint():
return $default(_that.id,_that.name,_that.latitude,_that.longitude,_that.windowStart,_that.windowEnd,_that.serviceDurationMinutes,_that.priority,_that.isRequired,_that.clientId,_that.appointmentId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  double latitude,  double longitude,  DateTime windowStart,  DateTime windowEnd,  int serviceDurationMinutes,  int priority,  bool isRequired,  String? clientId,  String? appointmentId)?  $default,) {final _that = this;
switch (_that) {
case _RouteWaypoint() when $default != null:
return $default(_that.id,_that.name,_that.latitude,_that.longitude,_that.windowStart,_that.windowEnd,_that.serviceDurationMinutes,_that.priority,_that.isRequired,_that.clientId,_that.appointmentId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RouteWaypoint implements RouteWaypoint {
  const _RouteWaypoint({required this.id, required this.name, required this.latitude, required this.longitude, required this.windowStart, required this.windowEnd, required this.serviceDurationMinutes, this.priority = 1, this.isRequired = true, this.clientId, this.appointmentId});
  factory _RouteWaypoint.fromJson(Map<String, dynamic> json) => _$RouteWaypointFromJson(json);

/// Unique identifier (usually appointment ID)
@override final  String id;
/// Display name
@override final  String name;
/// Latitude
@override final  double latitude;
/// Longitude
@override final  double longitude;
/// Earliest arrival time (window start)
@override final  DateTime windowStart;
/// Latest arrival time (window end)
@override final  DateTime windowEnd;
/// Service duration at this location (minutes)
@override final  int serviceDurationMinutes;
/// Priority (higher = more important to visit on time)
@override@JsonKey() final  int priority;
/// Whether this waypoint is required (vs optional)
@override@JsonKey() final  bool isRequired;
/// Associated client ID
@override final  String? clientId;
/// Associated appointment ID
@override final  String? appointmentId;

/// Create a copy of RouteWaypoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RouteWaypointCopyWith<_RouteWaypoint> get copyWith => __$RouteWaypointCopyWithImpl<_RouteWaypoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RouteWaypointToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RouteWaypoint&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.windowStart, windowStart) || other.windowStart == windowStart)&&(identical(other.windowEnd, windowEnd) || other.windowEnd == windowEnd)&&(identical(other.serviceDurationMinutes, serviceDurationMinutes) || other.serviceDurationMinutes == serviceDurationMinutes)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.isRequired, isRequired) || other.isRequired == isRequired)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,latitude,longitude,windowStart,windowEnd,serviceDurationMinutes,priority,isRequired,clientId,appointmentId);

@override
String toString() {
  return 'RouteWaypoint(id: $id, name: $name, latitude: $latitude, longitude: $longitude, windowStart: $windowStart, windowEnd: $windowEnd, serviceDurationMinutes: $serviceDurationMinutes, priority: $priority, isRequired: $isRequired, clientId: $clientId, appointmentId: $appointmentId)';
}


}

/// @nodoc
abstract mixin class _$RouteWaypointCopyWith<$Res> implements $RouteWaypointCopyWith<$Res> {
  factory _$RouteWaypointCopyWith(_RouteWaypoint value, $Res Function(_RouteWaypoint) _then) = __$RouteWaypointCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, double latitude, double longitude, DateTime windowStart, DateTime windowEnd, int serviceDurationMinutes, int priority, bool isRequired, String? clientId, String? appointmentId
});




}
/// @nodoc
class __$RouteWaypointCopyWithImpl<$Res>
    implements _$RouteWaypointCopyWith<$Res> {
  __$RouteWaypointCopyWithImpl(this._self, this._then);

  final _RouteWaypoint _self;
  final $Res Function(_RouteWaypoint) _then;

/// Create a copy of RouteWaypoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? latitude = null,Object? longitude = null,Object? windowStart = null,Object? windowEnd = null,Object? serviceDurationMinutes = null,Object? priority = null,Object? isRequired = null,Object? clientId = freezed,Object? appointmentId = freezed,}) {
  return _then(_RouteWaypoint(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,windowStart: null == windowStart ? _self.windowStart : windowStart // ignore: cast_nullable_to_non_nullable
as DateTime,windowEnd: null == windowEnd ? _self.windowEnd : windowEnd // ignore: cast_nullable_to_non_nullable
as DateTime,serviceDurationMinutes: null == serviceDurationMinutes ? _self.serviceDurationMinutes : serviceDurationMinutes // ignore: cast_nullable_to_non_nullable
as int,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,isRequired: null == isRequired ? _self.isRequired : isRequired // ignore: cast_nullable_to_non_nullable
as bool,clientId: freezed == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String?,appointmentId: freezed == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$RouteOptimizationRequest {

/// Business ID
 String get businessId;/// Provider ID
 String get providerId;/// Date for this route
 DateTime get routeDate;// ============ Start/End Locations ============
/// Starting location (depot) latitude
 double get depotLatitude;/// Starting location (depot) longitude
 double get depotLongitude;/// Depot address for display
 String get depotAddress;/// Whether to return to depot at end
 bool get returnToDepot;/// End location if different from depot
 double? get endLatitude; double? get endLongitude; String? get endAddress;// ============ Waypoints ============
/// Locations to visit
 List<RouteWaypoint> get waypoints;// ============ Time Constraints ============
/// Earliest departure time from depot
 DateTime get earliestDeparture;/// Latest return time to depot
 DateTime get latestReturn;/// Maximum driving time per day (minutes)
 int? get maxDrivingMinutes;// ============ Preferences ============
/// What to optimize for
 OptimizationObjective get objective;/// Include breaks (lunch, etc.)
 bool get includeBreaks;/// Break duration in minutes (if includeBreaks)
 int get breakDurationMinutes;/// Preferred break time window start
 DateTime? get breakWindowStart;/// Preferred break time window end
 DateTime? get breakWindowEnd;// ============ Vehicle Constraints ============
/// Average speed in km/h (for time estimates without routing API)
 int get averageSpeedKmh;/// Buffer time between appointments (minutes)
 int get bufferBetweenStopsMinutes;
/// Create a copy of RouteOptimizationRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RouteOptimizationRequestCopyWith<RouteOptimizationRequest> get copyWith => _$RouteOptimizationRequestCopyWithImpl<RouteOptimizationRequest>(this as RouteOptimizationRequest, _$identity);

  /// Serializes this RouteOptimizationRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RouteOptimizationRequest&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.routeDate, routeDate) || other.routeDate == routeDate)&&(identical(other.depotLatitude, depotLatitude) || other.depotLatitude == depotLatitude)&&(identical(other.depotLongitude, depotLongitude) || other.depotLongitude == depotLongitude)&&(identical(other.depotAddress, depotAddress) || other.depotAddress == depotAddress)&&(identical(other.returnToDepot, returnToDepot) || other.returnToDepot == returnToDepot)&&(identical(other.endLatitude, endLatitude) || other.endLatitude == endLatitude)&&(identical(other.endLongitude, endLongitude) || other.endLongitude == endLongitude)&&(identical(other.endAddress, endAddress) || other.endAddress == endAddress)&&const DeepCollectionEquality().equals(other.waypoints, waypoints)&&(identical(other.earliestDeparture, earliestDeparture) || other.earliestDeparture == earliestDeparture)&&(identical(other.latestReturn, latestReturn) || other.latestReturn == latestReturn)&&(identical(other.maxDrivingMinutes, maxDrivingMinutes) || other.maxDrivingMinutes == maxDrivingMinutes)&&(identical(other.objective, objective) || other.objective == objective)&&(identical(other.includeBreaks, includeBreaks) || other.includeBreaks == includeBreaks)&&(identical(other.breakDurationMinutes, breakDurationMinutes) || other.breakDurationMinutes == breakDurationMinutes)&&(identical(other.breakWindowStart, breakWindowStart) || other.breakWindowStart == breakWindowStart)&&(identical(other.breakWindowEnd, breakWindowEnd) || other.breakWindowEnd == breakWindowEnd)&&(identical(other.averageSpeedKmh, averageSpeedKmh) || other.averageSpeedKmh == averageSpeedKmh)&&(identical(other.bufferBetweenStopsMinutes, bufferBetweenStopsMinutes) || other.bufferBetweenStopsMinutes == bufferBetweenStopsMinutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,businessId,providerId,routeDate,depotLatitude,depotLongitude,depotAddress,returnToDepot,endLatitude,endLongitude,endAddress,const DeepCollectionEquality().hash(waypoints),earliestDeparture,latestReturn,maxDrivingMinutes,objective,includeBreaks,breakDurationMinutes,breakWindowStart,breakWindowEnd,averageSpeedKmh,bufferBetweenStopsMinutes]);

@override
String toString() {
  return 'RouteOptimizationRequest(businessId: $businessId, providerId: $providerId, routeDate: $routeDate, depotLatitude: $depotLatitude, depotLongitude: $depotLongitude, depotAddress: $depotAddress, returnToDepot: $returnToDepot, endLatitude: $endLatitude, endLongitude: $endLongitude, endAddress: $endAddress, waypoints: $waypoints, earliestDeparture: $earliestDeparture, latestReturn: $latestReturn, maxDrivingMinutes: $maxDrivingMinutes, objective: $objective, includeBreaks: $includeBreaks, breakDurationMinutes: $breakDurationMinutes, breakWindowStart: $breakWindowStart, breakWindowEnd: $breakWindowEnd, averageSpeedKmh: $averageSpeedKmh, bufferBetweenStopsMinutes: $bufferBetweenStopsMinutes)';
}


}

/// @nodoc
abstract mixin class $RouteOptimizationRequestCopyWith<$Res>  {
  factory $RouteOptimizationRequestCopyWith(RouteOptimizationRequest value, $Res Function(RouteOptimizationRequest) _then) = _$RouteOptimizationRequestCopyWithImpl;
@useResult
$Res call({
 String businessId, String providerId, DateTime routeDate, double depotLatitude, double depotLongitude, String depotAddress, bool returnToDepot, double? endLatitude, double? endLongitude, String? endAddress, List<RouteWaypoint> waypoints, DateTime earliestDeparture, DateTime latestReturn, int? maxDrivingMinutes, OptimizationObjective objective, bool includeBreaks, int breakDurationMinutes, DateTime? breakWindowStart, DateTime? breakWindowEnd, int averageSpeedKmh, int bufferBetweenStopsMinutes
});




}
/// @nodoc
class _$RouteOptimizationRequestCopyWithImpl<$Res>
    implements $RouteOptimizationRequestCopyWith<$Res> {
  _$RouteOptimizationRequestCopyWithImpl(this._self, this._then);

  final RouteOptimizationRequest _self;
  final $Res Function(RouteOptimizationRequest) _then;

/// Create a copy of RouteOptimizationRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? businessId = null,Object? providerId = null,Object? routeDate = null,Object? depotLatitude = null,Object? depotLongitude = null,Object? depotAddress = null,Object? returnToDepot = null,Object? endLatitude = freezed,Object? endLongitude = freezed,Object? endAddress = freezed,Object? waypoints = null,Object? earliestDeparture = null,Object? latestReturn = null,Object? maxDrivingMinutes = freezed,Object? objective = null,Object? includeBreaks = null,Object? breakDurationMinutes = null,Object? breakWindowStart = freezed,Object? breakWindowEnd = freezed,Object? averageSpeedKmh = null,Object? bufferBetweenStopsMinutes = null,}) {
  return _then(_self.copyWith(
businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,routeDate: null == routeDate ? _self.routeDate : routeDate // ignore: cast_nullable_to_non_nullable
as DateTime,depotLatitude: null == depotLatitude ? _self.depotLatitude : depotLatitude // ignore: cast_nullable_to_non_nullable
as double,depotLongitude: null == depotLongitude ? _self.depotLongitude : depotLongitude // ignore: cast_nullable_to_non_nullable
as double,depotAddress: null == depotAddress ? _self.depotAddress : depotAddress // ignore: cast_nullable_to_non_nullable
as String,returnToDepot: null == returnToDepot ? _self.returnToDepot : returnToDepot // ignore: cast_nullable_to_non_nullable
as bool,endLatitude: freezed == endLatitude ? _self.endLatitude : endLatitude // ignore: cast_nullable_to_non_nullable
as double?,endLongitude: freezed == endLongitude ? _self.endLongitude : endLongitude // ignore: cast_nullable_to_non_nullable
as double?,endAddress: freezed == endAddress ? _self.endAddress : endAddress // ignore: cast_nullable_to_non_nullable
as String?,waypoints: null == waypoints ? _self.waypoints : waypoints // ignore: cast_nullable_to_non_nullable
as List<RouteWaypoint>,earliestDeparture: null == earliestDeparture ? _self.earliestDeparture : earliestDeparture // ignore: cast_nullable_to_non_nullable
as DateTime,latestReturn: null == latestReturn ? _self.latestReturn : latestReturn // ignore: cast_nullable_to_non_nullable
as DateTime,maxDrivingMinutes: freezed == maxDrivingMinutes ? _self.maxDrivingMinutes : maxDrivingMinutes // ignore: cast_nullable_to_non_nullable
as int?,objective: null == objective ? _self.objective : objective // ignore: cast_nullable_to_non_nullable
as OptimizationObjective,includeBreaks: null == includeBreaks ? _self.includeBreaks : includeBreaks // ignore: cast_nullable_to_non_nullable
as bool,breakDurationMinutes: null == breakDurationMinutes ? _self.breakDurationMinutes : breakDurationMinutes // ignore: cast_nullable_to_non_nullable
as int,breakWindowStart: freezed == breakWindowStart ? _self.breakWindowStart : breakWindowStart // ignore: cast_nullable_to_non_nullable
as DateTime?,breakWindowEnd: freezed == breakWindowEnd ? _self.breakWindowEnd : breakWindowEnd // ignore: cast_nullable_to_non_nullable
as DateTime?,averageSpeedKmh: null == averageSpeedKmh ? _self.averageSpeedKmh : averageSpeedKmh // ignore: cast_nullable_to_non_nullable
as int,bufferBetweenStopsMinutes: null == bufferBetweenStopsMinutes ? _self.bufferBetweenStopsMinutes : bufferBetweenStopsMinutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RouteOptimizationRequest].
extension RouteOptimizationRequestPatterns on RouteOptimizationRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RouteOptimizationRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RouteOptimizationRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RouteOptimizationRequest value)  $default,){
final _that = this;
switch (_that) {
case _RouteOptimizationRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RouteOptimizationRequest value)?  $default,){
final _that = this;
switch (_that) {
case _RouteOptimizationRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String businessId,  String providerId,  DateTime routeDate,  double depotLatitude,  double depotLongitude,  String depotAddress,  bool returnToDepot,  double? endLatitude,  double? endLongitude,  String? endAddress,  List<RouteWaypoint> waypoints,  DateTime earliestDeparture,  DateTime latestReturn,  int? maxDrivingMinutes,  OptimizationObjective objective,  bool includeBreaks,  int breakDurationMinutes,  DateTime? breakWindowStart,  DateTime? breakWindowEnd,  int averageSpeedKmh,  int bufferBetweenStopsMinutes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RouteOptimizationRequest() when $default != null:
return $default(_that.businessId,_that.providerId,_that.routeDate,_that.depotLatitude,_that.depotLongitude,_that.depotAddress,_that.returnToDepot,_that.endLatitude,_that.endLongitude,_that.endAddress,_that.waypoints,_that.earliestDeparture,_that.latestReturn,_that.maxDrivingMinutes,_that.objective,_that.includeBreaks,_that.breakDurationMinutes,_that.breakWindowStart,_that.breakWindowEnd,_that.averageSpeedKmh,_that.bufferBetweenStopsMinutes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String businessId,  String providerId,  DateTime routeDate,  double depotLatitude,  double depotLongitude,  String depotAddress,  bool returnToDepot,  double? endLatitude,  double? endLongitude,  String? endAddress,  List<RouteWaypoint> waypoints,  DateTime earliestDeparture,  DateTime latestReturn,  int? maxDrivingMinutes,  OptimizationObjective objective,  bool includeBreaks,  int breakDurationMinutes,  DateTime? breakWindowStart,  DateTime? breakWindowEnd,  int averageSpeedKmh,  int bufferBetweenStopsMinutes)  $default,) {final _that = this;
switch (_that) {
case _RouteOptimizationRequest():
return $default(_that.businessId,_that.providerId,_that.routeDate,_that.depotLatitude,_that.depotLongitude,_that.depotAddress,_that.returnToDepot,_that.endLatitude,_that.endLongitude,_that.endAddress,_that.waypoints,_that.earliestDeparture,_that.latestReturn,_that.maxDrivingMinutes,_that.objective,_that.includeBreaks,_that.breakDurationMinutes,_that.breakWindowStart,_that.breakWindowEnd,_that.averageSpeedKmh,_that.bufferBetweenStopsMinutes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String businessId,  String providerId,  DateTime routeDate,  double depotLatitude,  double depotLongitude,  String depotAddress,  bool returnToDepot,  double? endLatitude,  double? endLongitude,  String? endAddress,  List<RouteWaypoint> waypoints,  DateTime earliestDeparture,  DateTime latestReturn,  int? maxDrivingMinutes,  OptimizationObjective objective,  bool includeBreaks,  int breakDurationMinutes,  DateTime? breakWindowStart,  DateTime? breakWindowEnd,  int averageSpeedKmh,  int bufferBetweenStopsMinutes)?  $default,) {final _that = this;
switch (_that) {
case _RouteOptimizationRequest() when $default != null:
return $default(_that.businessId,_that.providerId,_that.routeDate,_that.depotLatitude,_that.depotLongitude,_that.depotAddress,_that.returnToDepot,_that.endLatitude,_that.endLongitude,_that.endAddress,_that.waypoints,_that.earliestDeparture,_that.latestReturn,_that.maxDrivingMinutes,_that.objective,_that.includeBreaks,_that.breakDurationMinutes,_that.breakWindowStart,_that.breakWindowEnd,_that.averageSpeedKmh,_that.bufferBetweenStopsMinutes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RouteOptimizationRequest implements RouteOptimizationRequest {
  const _RouteOptimizationRequest({required this.businessId, required this.providerId, required this.routeDate, required this.depotLatitude, required this.depotLongitude, required this.depotAddress, this.returnToDepot = true, this.endLatitude, this.endLongitude, this.endAddress, required final  List<RouteWaypoint> waypoints, required this.earliestDeparture, required this.latestReturn, this.maxDrivingMinutes, this.objective = OptimizationObjective.minimizeTime, this.includeBreaks = false, this.breakDurationMinutes = 30, this.breakWindowStart, this.breakWindowEnd, this.averageSpeedKmh = 40, this.bufferBetweenStopsMinutes = 5}): _waypoints = waypoints;
  factory _RouteOptimizationRequest.fromJson(Map<String, dynamic> json) => _$RouteOptimizationRequestFromJson(json);

/// Business ID
@override final  String businessId;
/// Provider ID
@override final  String providerId;
/// Date for this route
@override final  DateTime routeDate;
// ============ Start/End Locations ============
/// Starting location (depot) latitude
@override final  double depotLatitude;
/// Starting location (depot) longitude
@override final  double depotLongitude;
/// Depot address for display
@override final  String depotAddress;
/// Whether to return to depot at end
@override@JsonKey() final  bool returnToDepot;
/// End location if different from depot
@override final  double? endLatitude;
@override final  double? endLongitude;
@override final  String? endAddress;
// ============ Waypoints ============
/// Locations to visit
 final  List<RouteWaypoint> _waypoints;
// ============ Waypoints ============
/// Locations to visit
@override List<RouteWaypoint> get waypoints {
  if (_waypoints is EqualUnmodifiableListView) return _waypoints;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_waypoints);
}

// ============ Time Constraints ============
/// Earliest departure time from depot
@override final  DateTime earliestDeparture;
/// Latest return time to depot
@override final  DateTime latestReturn;
/// Maximum driving time per day (minutes)
@override final  int? maxDrivingMinutes;
// ============ Preferences ============
/// What to optimize for
@override@JsonKey() final  OptimizationObjective objective;
/// Include breaks (lunch, etc.)
@override@JsonKey() final  bool includeBreaks;
/// Break duration in minutes (if includeBreaks)
@override@JsonKey() final  int breakDurationMinutes;
/// Preferred break time window start
@override final  DateTime? breakWindowStart;
/// Preferred break time window end
@override final  DateTime? breakWindowEnd;
// ============ Vehicle Constraints ============
/// Average speed in km/h (for time estimates without routing API)
@override@JsonKey() final  int averageSpeedKmh;
/// Buffer time between appointments (minutes)
@override@JsonKey() final  int bufferBetweenStopsMinutes;

/// Create a copy of RouteOptimizationRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RouteOptimizationRequestCopyWith<_RouteOptimizationRequest> get copyWith => __$RouteOptimizationRequestCopyWithImpl<_RouteOptimizationRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RouteOptimizationRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RouteOptimizationRequest&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.routeDate, routeDate) || other.routeDate == routeDate)&&(identical(other.depotLatitude, depotLatitude) || other.depotLatitude == depotLatitude)&&(identical(other.depotLongitude, depotLongitude) || other.depotLongitude == depotLongitude)&&(identical(other.depotAddress, depotAddress) || other.depotAddress == depotAddress)&&(identical(other.returnToDepot, returnToDepot) || other.returnToDepot == returnToDepot)&&(identical(other.endLatitude, endLatitude) || other.endLatitude == endLatitude)&&(identical(other.endLongitude, endLongitude) || other.endLongitude == endLongitude)&&(identical(other.endAddress, endAddress) || other.endAddress == endAddress)&&const DeepCollectionEquality().equals(other._waypoints, _waypoints)&&(identical(other.earliestDeparture, earliestDeparture) || other.earliestDeparture == earliestDeparture)&&(identical(other.latestReturn, latestReturn) || other.latestReturn == latestReturn)&&(identical(other.maxDrivingMinutes, maxDrivingMinutes) || other.maxDrivingMinutes == maxDrivingMinutes)&&(identical(other.objective, objective) || other.objective == objective)&&(identical(other.includeBreaks, includeBreaks) || other.includeBreaks == includeBreaks)&&(identical(other.breakDurationMinutes, breakDurationMinutes) || other.breakDurationMinutes == breakDurationMinutes)&&(identical(other.breakWindowStart, breakWindowStart) || other.breakWindowStart == breakWindowStart)&&(identical(other.breakWindowEnd, breakWindowEnd) || other.breakWindowEnd == breakWindowEnd)&&(identical(other.averageSpeedKmh, averageSpeedKmh) || other.averageSpeedKmh == averageSpeedKmh)&&(identical(other.bufferBetweenStopsMinutes, bufferBetweenStopsMinutes) || other.bufferBetweenStopsMinutes == bufferBetweenStopsMinutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,businessId,providerId,routeDate,depotLatitude,depotLongitude,depotAddress,returnToDepot,endLatitude,endLongitude,endAddress,const DeepCollectionEquality().hash(_waypoints),earliestDeparture,latestReturn,maxDrivingMinutes,objective,includeBreaks,breakDurationMinutes,breakWindowStart,breakWindowEnd,averageSpeedKmh,bufferBetweenStopsMinutes]);

@override
String toString() {
  return 'RouteOptimizationRequest(businessId: $businessId, providerId: $providerId, routeDate: $routeDate, depotLatitude: $depotLatitude, depotLongitude: $depotLongitude, depotAddress: $depotAddress, returnToDepot: $returnToDepot, endLatitude: $endLatitude, endLongitude: $endLongitude, endAddress: $endAddress, waypoints: $waypoints, earliestDeparture: $earliestDeparture, latestReturn: $latestReturn, maxDrivingMinutes: $maxDrivingMinutes, objective: $objective, includeBreaks: $includeBreaks, breakDurationMinutes: $breakDurationMinutes, breakWindowStart: $breakWindowStart, breakWindowEnd: $breakWindowEnd, averageSpeedKmh: $averageSpeedKmh, bufferBetweenStopsMinutes: $bufferBetweenStopsMinutes)';
}


}

/// @nodoc
abstract mixin class _$RouteOptimizationRequestCopyWith<$Res> implements $RouteOptimizationRequestCopyWith<$Res> {
  factory _$RouteOptimizationRequestCopyWith(_RouteOptimizationRequest value, $Res Function(_RouteOptimizationRequest) _then) = __$RouteOptimizationRequestCopyWithImpl;
@override @useResult
$Res call({
 String businessId, String providerId, DateTime routeDate, double depotLatitude, double depotLongitude, String depotAddress, bool returnToDepot, double? endLatitude, double? endLongitude, String? endAddress, List<RouteWaypoint> waypoints, DateTime earliestDeparture, DateTime latestReturn, int? maxDrivingMinutes, OptimizationObjective objective, bool includeBreaks, int breakDurationMinutes, DateTime? breakWindowStart, DateTime? breakWindowEnd, int averageSpeedKmh, int bufferBetweenStopsMinutes
});




}
/// @nodoc
class __$RouteOptimizationRequestCopyWithImpl<$Res>
    implements _$RouteOptimizationRequestCopyWith<$Res> {
  __$RouteOptimizationRequestCopyWithImpl(this._self, this._then);

  final _RouteOptimizationRequest _self;
  final $Res Function(_RouteOptimizationRequest) _then;

/// Create a copy of RouteOptimizationRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? businessId = null,Object? providerId = null,Object? routeDate = null,Object? depotLatitude = null,Object? depotLongitude = null,Object? depotAddress = null,Object? returnToDepot = null,Object? endLatitude = freezed,Object? endLongitude = freezed,Object? endAddress = freezed,Object? waypoints = null,Object? earliestDeparture = null,Object? latestReturn = null,Object? maxDrivingMinutes = freezed,Object? objective = null,Object? includeBreaks = null,Object? breakDurationMinutes = null,Object? breakWindowStart = freezed,Object? breakWindowEnd = freezed,Object? averageSpeedKmh = null,Object? bufferBetweenStopsMinutes = null,}) {
  return _then(_RouteOptimizationRequest(
businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,routeDate: null == routeDate ? _self.routeDate : routeDate // ignore: cast_nullable_to_non_nullable
as DateTime,depotLatitude: null == depotLatitude ? _self.depotLatitude : depotLatitude // ignore: cast_nullable_to_non_nullable
as double,depotLongitude: null == depotLongitude ? _self.depotLongitude : depotLongitude // ignore: cast_nullable_to_non_nullable
as double,depotAddress: null == depotAddress ? _self.depotAddress : depotAddress // ignore: cast_nullable_to_non_nullable
as String,returnToDepot: null == returnToDepot ? _self.returnToDepot : returnToDepot // ignore: cast_nullable_to_non_nullable
as bool,endLatitude: freezed == endLatitude ? _self.endLatitude : endLatitude // ignore: cast_nullable_to_non_nullable
as double?,endLongitude: freezed == endLongitude ? _self.endLongitude : endLongitude // ignore: cast_nullable_to_non_nullable
as double?,endAddress: freezed == endAddress ? _self.endAddress : endAddress // ignore: cast_nullable_to_non_nullable
as String?,waypoints: null == waypoints ? _self._waypoints : waypoints // ignore: cast_nullable_to_non_nullable
as List<RouteWaypoint>,earliestDeparture: null == earliestDeparture ? _self.earliestDeparture : earliestDeparture // ignore: cast_nullable_to_non_nullable
as DateTime,latestReturn: null == latestReturn ? _self.latestReturn : latestReturn // ignore: cast_nullable_to_non_nullable
as DateTime,maxDrivingMinutes: freezed == maxDrivingMinutes ? _self.maxDrivingMinutes : maxDrivingMinutes // ignore: cast_nullable_to_non_nullable
as int?,objective: null == objective ? _self.objective : objective // ignore: cast_nullable_to_non_nullable
as OptimizationObjective,includeBreaks: null == includeBreaks ? _self.includeBreaks : includeBreaks // ignore: cast_nullable_to_non_nullable
as bool,breakDurationMinutes: null == breakDurationMinutes ? _self.breakDurationMinutes : breakDurationMinutes // ignore: cast_nullable_to_non_nullable
as int,breakWindowStart: freezed == breakWindowStart ? _self.breakWindowStart : breakWindowStart // ignore: cast_nullable_to_non_nullable
as DateTime?,breakWindowEnd: freezed == breakWindowEnd ? _self.breakWindowEnd : breakWindowEnd // ignore: cast_nullable_to_non_nullable
as DateTime?,averageSpeedKmh: null == averageSpeedKmh ? _self.averageSpeedKmh : averageSpeedKmh // ignore: cast_nullable_to_non_nullable
as int,bufferBetweenStopsMinutes: null == bufferBetweenStopsMinutes ? _self.bufferBetweenStopsMinutes : bufferBetweenStopsMinutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
