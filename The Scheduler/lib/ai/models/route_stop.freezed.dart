// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'route_stop.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RouteStop {

/// Unique identifier for this stop
 String get id;/// Position in the route (0 = first stop after depot)
 int get sequenceOrder;/// Type of stop
 RouteStopType get stopType;/// Status of this stop
 RouteStopStatus get status;// ============ Location ============
/// Display name for this stop
 String get name;/// Full address
 String get address;/// Latitude
 double get latitude;/// Longitude
 double get longitude;/// Special instructions (gate code, parking, etc.)
 String? get arrivalNotes;// ============ Timing ============
/// Earliest allowed arrival time
 DateTime get windowStart;/// Latest allowed arrival time
 DateTime get windowEnd;/// Scheduled/suggested arrival time (from optimizer)
 DateTime get scheduledArrival;/// Actual arrival time (filled when provider arrives)
 DateTime? get actualArrival;/// Expected service duration in minutes
 int get serviceDurationMinutes;/// Buffer time after service before next stop (minutes)
 int get bufferMinutes;/// Actual departure time (filled when provider leaves)
 DateTime? get actualDeparture;// ============ References ============
/// Linked appointment ID (for appointment stops)
 String? get appointmentId;/// Linked client ID
 String? get clientId;/// Service being performed
 String? get serviceId;/// Service name for display
 String? get serviceName;// ============ Travel to Next Stop ============
/// Estimated travel time to next stop (minutes)
 int? get travelToNextMinutes;/// Estimated distance to next stop (meters)
 int? get distanceToNextMeters;// ============ Metadata ============
/// Provider notes about this stop
 String? get providerNotes;/// When this stop was last updated
 DateTime get updatedAt;
/// Create a copy of RouteStop
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RouteStopCopyWith<RouteStop> get copyWith => _$RouteStopCopyWithImpl<RouteStop>(this as RouteStop, _$identity);

  /// Serializes this RouteStop to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RouteStop&&(identical(other.id, id) || other.id == id)&&(identical(other.sequenceOrder, sequenceOrder) || other.sequenceOrder == sequenceOrder)&&(identical(other.stopType, stopType) || other.stopType == stopType)&&(identical(other.status, status) || other.status == status)&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.arrivalNotes, arrivalNotes) || other.arrivalNotes == arrivalNotes)&&(identical(other.windowStart, windowStart) || other.windowStart == windowStart)&&(identical(other.windowEnd, windowEnd) || other.windowEnd == windowEnd)&&(identical(other.scheduledArrival, scheduledArrival) || other.scheduledArrival == scheduledArrival)&&(identical(other.actualArrival, actualArrival) || other.actualArrival == actualArrival)&&(identical(other.serviceDurationMinutes, serviceDurationMinutes) || other.serviceDurationMinutes == serviceDurationMinutes)&&(identical(other.bufferMinutes, bufferMinutes) || other.bufferMinutes == bufferMinutes)&&(identical(other.actualDeparture, actualDeparture) || other.actualDeparture == actualDeparture)&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName)&&(identical(other.travelToNextMinutes, travelToNextMinutes) || other.travelToNextMinutes == travelToNextMinutes)&&(identical(other.distanceToNextMeters, distanceToNextMeters) || other.distanceToNextMeters == distanceToNextMeters)&&(identical(other.providerNotes, providerNotes) || other.providerNotes == providerNotes)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,sequenceOrder,stopType,status,name,address,latitude,longitude,arrivalNotes,windowStart,windowEnd,scheduledArrival,actualArrival,serviceDurationMinutes,bufferMinutes,actualDeparture,appointmentId,clientId,serviceId,serviceName,travelToNextMinutes,distanceToNextMeters,providerNotes,updatedAt]);

@override
String toString() {
  return 'RouteStop(id: $id, sequenceOrder: $sequenceOrder, stopType: $stopType, status: $status, name: $name, address: $address, latitude: $latitude, longitude: $longitude, arrivalNotes: $arrivalNotes, windowStart: $windowStart, windowEnd: $windowEnd, scheduledArrival: $scheduledArrival, actualArrival: $actualArrival, serviceDurationMinutes: $serviceDurationMinutes, bufferMinutes: $bufferMinutes, actualDeparture: $actualDeparture, appointmentId: $appointmentId, clientId: $clientId, serviceId: $serviceId, serviceName: $serviceName, travelToNextMinutes: $travelToNextMinutes, distanceToNextMeters: $distanceToNextMeters, providerNotes: $providerNotes, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $RouteStopCopyWith<$Res>  {
  factory $RouteStopCopyWith(RouteStop value, $Res Function(RouteStop) _then) = _$RouteStopCopyWithImpl;
@useResult
$Res call({
 String id, int sequenceOrder, RouteStopType stopType, RouteStopStatus status, String name, String address, double latitude, double longitude, String? arrivalNotes, DateTime windowStart, DateTime windowEnd, DateTime scheduledArrival, DateTime? actualArrival, int serviceDurationMinutes, int bufferMinutes, DateTime? actualDeparture, String? appointmentId, String? clientId, String? serviceId, String? serviceName, int? travelToNextMinutes, int? distanceToNextMeters, String? providerNotes, DateTime updatedAt
});




}
/// @nodoc
class _$RouteStopCopyWithImpl<$Res>
    implements $RouteStopCopyWith<$Res> {
  _$RouteStopCopyWithImpl(this._self, this._then);

  final RouteStop _self;
  final $Res Function(RouteStop) _then;

/// Create a copy of RouteStop
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sequenceOrder = null,Object? stopType = null,Object? status = null,Object? name = null,Object? address = null,Object? latitude = null,Object? longitude = null,Object? arrivalNotes = freezed,Object? windowStart = null,Object? windowEnd = null,Object? scheduledArrival = null,Object? actualArrival = freezed,Object? serviceDurationMinutes = null,Object? bufferMinutes = null,Object? actualDeparture = freezed,Object? appointmentId = freezed,Object? clientId = freezed,Object? serviceId = freezed,Object? serviceName = freezed,Object? travelToNextMinutes = freezed,Object? distanceToNextMeters = freezed,Object? providerNotes = freezed,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sequenceOrder: null == sequenceOrder ? _self.sequenceOrder : sequenceOrder // ignore: cast_nullable_to_non_nullable
as int,stopType: null == stopType ? _self.stopType : stopType // ignore: cast_nullable_to_non_nullable
as RouteStopType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RouteStopStatus,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,arrivalNotes: freezed == arrivalNotes ? _self.arrivalNotes : arrivalNotes // ignore: cast_nullable_to_non_nullable
as String?,windowStart: null == windowStart ? _self.windowStart : windowStart // ignore: cast_nullable_to_non_nullable
as DateTime,windowEnd: null == windowEnd ? _self.windowEnd : windowEnd // ignore: cast_nullable_to_non_nullable
as DateTime,scheduledArrival: null == scheduledArrival ? _self.scheduledArrival : scheduledArrival // ignore: cast_nullable_to_non_nullable
as DateTime,actualArrival: freezed == actualArrival ? _self.actualArrival : actualArrival // ignore: cast_nullable_to_non_nullable
as DateTime?,serviceDurationMinutes: null == serviceDurationMinutes ? _self.serviceDurationMinutes : serviceDurationMinutes // ignore: cast_nullable_to_non_nullable
as int,bufferMinutes: null == bufferMinutes ? _self.bufferMinutes : bufferMinutes // ignore: cast_nullable_to_non_nullable
as int,actualDeparture: freezed == actualDeparture ? _self.actualDeparture : actualDeparture // ignore: cast_nullable_to_non_nullable
as DateTime?,appointmentId: freezed == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String?,clientId: freezed == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String?,serviceId: freezed == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String?,serviceName: freezed == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as String?,travelToNextMinutes: freezed == travelToNextMinutes ? _self.travelToNextMinutes : travelToNextMinutes // ignore: cast_nullable_to_non_nullable
as int?,distanceToNextMeters: freezed == distanceToNextMeters ? _self.distanceToNextMeters : distanceToNextMeters // ignore: cast_nullable_to_non_nullable
as int?,providerNotes: freezed == providerNotes ? _self.providerNotes : providerNotes // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [RouteStop].
extension RouteStopPatterns on RouteStop {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RouteStop value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RouteStop() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RouteStop value)  $default,){
final _that = this;
switch (_that) {
case _RouteStop():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RouteStop value)?  $default,){
final _that = this;
switch (_that) {
case _RouteStop() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int sequenceOrder,  RouteStopType stopType,  RouteStopStatus status,  String name,  String address,  double latitude,  double longitude,  String? arrivalNotes,  DateTime windowStart,  DateTime windowEnd,  DateTime scheduledArrival,  DateTime? actualArrival,  int serviceDurationMinutes,  int bufferMinutes,  DateTime? actualDeparture,  String? appointmentId,  String? clientId,  String? serviceId,  String? serviceName,  int? travelToNextMinutes,  int? distanceToNextMeters,  String? providerNotes,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RouteStop() when $default != null:
return $default(_that.id,_that.sequenceOrder,_that.stopType,_that.status,_that.name,_that.address,_that.latitude,_that.longitude,_that.arrivalNotes,_that.windowStart,_that.windowEnd,_that.scheduledArrival,_that.actualArrival,_that.serviceDurationMinutes,_that.bufferMinutes,_that.actualDeparture,_that.appointmentId,_that.clientId,_that.serviceId,_that.serviceName,_that.travelToNextMinutes,_that.distanceToNextMeters,_that.providerNotes,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int sequenceOrder,  RouteStopType stopType,  RouteStopStatus status,  String name,  String address,  double latitude,  double longitude,  String? arrivalNotes,  DateTime windowStart,  DateTime windowEnd,  DateTime scheduledArrival,  DateTime? actualArrival,  int serviceDurationMinutes,  int bufferMinutes,  DateTime? actualDeparture,  String? appointmentId,  String? clientId,  String? serviceId,  String? serviceName,  int? travelToNextMinutes,  int? distanceToNextMeters,  String? providerNotes,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _RouteStop():
return $default(_that.id,_that.sequenceOrder,_that.stopType,_that.status,_that.name,_that.address,_that.latitude,_that.longitude,_that.arrivalNotes,_that.windowStart,_that.windowEnd,_that.scheduledArrival,_that.actualArrival,_that.serviceDurationMinutes,_that.bufferMinutes,_that.actualDeparture,_that.appointmentId,_that.clientId,_that.serviceId,_that.serviceName,_that.travelToNextMinutes,_that.distanceToNextMeters,_that.providerNotes,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int sequenceOrder,  RouteStopType stopType,  RouteStopStatus status,  String name,  String address,  double latitude,  double longitude,  String? arrivalNotes,  DateTime windowStart,  DateTime windowEnd,  DateTime scheduledArrival,  DateTime? actualArrival,  int serviceDurationMinutes,  int bufferMinutes,  DateTime? actualDeparture,  String? appointmentId,  String? clientId,  String? serviceId,  String? serviceName,  int? travelToNextMinutes,  int? distanceToNextMeters,  String? providerNotes,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _RouteStop() when $default != null:
return $default(_that.id,_that.sequenceOrder,_that.stopType,_that.status,_that.name,_that.address,_that.latitude,_that.longitude,_that.arrivalNotes,_that.windowStart,_that.windowEnd,_that.scheduledArrival,_that.actualArrival,_that.serviceDurationMinutes,_that.bufferMinutes,_that.actualDeparture,_that.appointmentId,_that.clientId,_that.serviceId,_that.serviceName,_that.travelToNextMinutes,_that.distanceToNextMeters,_that.providerNotes,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RouteStop implements RouteStop {
  const _RouteStop({required this.id, required this.sequenceOrder, required this.stopType, this.status = RouteStopStatus.pending, required this.name, required this.address, required this.latitude, required this.longitude, this.arrivalNotes, required this.windowStart, required this.windowEnd, required this.scheduledArrival, this.actualArrival, required this.serviceDurationMinutes, this.bufferMinutes = 0, this.actualDeparture, this.appointmentId, this.clientId, this.serviceId, this.serviceName, this.travelToNextMinutes, this.distanceToNextMeters, this.providerNotes, required this.updatedAt});
  factory _RouteStop.fromJson(Map<String, dynamic> json) => _$RouteStopFromJson(json);

/// Unique identifier for this stop
@override final  String id;
/// Position in the route (0 = first stop after depot)
@override final  int sequenceOrder;
/// Type of stop
@override final  RouteStopType stopType;
/// Status of this stop
@override@JsonKey() final  RouteStopStatus status;
// ============ Location ============
/// Display name for this stop
@override final  String name;
/// Full address
@override final  String address;
/// Latitude
@override final  double latitude;
/// Longitude
@override final  double longitude;
/// Special instructions (gate code, parking, etc.)
@override final  String? arrivalNotes;
// ============ Timing ============
/// Earliest allowed arrival time
@override final  DateTime windowStart;
/// Latest allowed arrival time
@override final  DateTime windowEnd;
/// Scheduled/suggested arrival time (from optimizer)
@override final  DateTime scheduledArrival;
/// Actual arrival time (filled when provider arrives)
@override final  DateTime? actualArrival;
/// Expected service duration in minutes
@override final  int serviceDurationMinutes;
/// Buffer time after service before next stop (minutes)
@override@JsonKey() final  int bufferMinutes;
/// Actual departure time (filled when provider leaves)
@override final  DateTime? actualDeparture;
// ============ References ============
/// Linked appointment ID (for appointment stops)
@override final  String? appointmentId;
/// Linked client ID
@override final  String? clientId;
/// Service being performed
@override final  String? serviceId;
/// Service name for display
@override final  String? serviceName;
// ============ Travel to Next Stop ============
/// Estimated travel time to next stop (minutes)
@override final  int? travelToNextMinutes;
/// Estimated distance to next stop (meters)
@override final  int? distanceToNextMeters;
// ============ Metadata ============
/// Provider notes about this stop
@override final  String? providerNotes;
/// When this stop was last updated
@override final  DateTime updatedAt;

/// Create a copy of RouteStop
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RouteStopCopyWith<_RouteStop> get copyWith => __$RouteStopCopyWithImpl<_RouteStop>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RouteStopToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RouteStop&&(identical(other.id, id) || other.id == id)&&(identical(other.sequenceOrder, sequenceOrder) || other.sequenceOrder == sequenceOrder)&&(identical(other.stopType, stopType) || other.stopType == stopType)&&(identical(other.status, status) || other.status == status)&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.arrivalNotes, arrivalNotes) || other.arrivalNotes == arrivalNotes)&&(identical(other.windowStart, windowStart) || other.windowStart == windowStart)&&(identical(other.windowEnd, windowEnd) || other.windowEnd == windowEnd)&&(identical(other.scheduledArrival, scheduledArrival) || other.scheduledArrival == scheduledArrival)&&(identical(other.actualArrival, actualArrival) || other.actualArrival == actualArrival)&&(identical(other.serviceDurationMinutes, serviceDurationMinutes) || other.serviceDurationMinutes == serviceDurationMinutes)&&(identical(other.bufferMinutes, bufferMinutes) || other.bufferMinutes == bufferMinutes)&&(identical(other.actualDeparture, actualDeparture) || other.actualDeparture == actualDeparture)&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName)&&(identical(other.travelToNextMinutes, travelToNextMinutes) || other.travelToNextMinutes == travelToNextMinutes)&&(identical(other.distanceToNextMeters, distanceToNextMeters) || other.distanceToNextMeters == distanceToNextMeters)&&(identical(other.providerNotes, providerNotes) || other.providerNotes == providerNotes)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,sequenceOrder,stopType,status,name,address,latitude,longitude,arrivalNotes,windowStart,windowEnd,scheduledArrival,actualArrival,serviceDurationMinutes,bufferMinutes,actualDeparture,appointmentId,clientId,serviceId,serviceName,travelToNextMinutes,distanceToNextMeters,providerNotes,updatedAt]);

@override
String toString() {
  return 'RouteStop(id: $id, sequenceOrder: $sequenceOrder, stopType: $stopType, status: $status, name: $name, address: $address, latitude: $latitude, longitude: $longitude, arrivalNotes: $arrivalNotes, windowStart: $windowStart, windowEnd: $windowEnd, scheduledArrival: $scheduledArrival, actualArrival: $actualArrival, serviceDurationMinutes: $serviceDurationMinutes, bufferMinutes: $bufferMinutes, actualDeparture: $actualDeparture, appointmentId: $appointmentId, clientId: $clientId, serviceId: $serviceId, serviceName: $serviceName, travelToNextMinutes: $travelToNextMinutes, distanceToNextMeters: $distanceToNextMeters, providerNotes: $providerNotes, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$RouteStopCopyWith<$Res> implements $RouteStopCopyWith<$Res> {
  factory _$RouteStopCopyWith(_RouteStop value, $Res Function(_RouteStop) _then) = __$RouteStopCopyWithImpl;
@override @useResult
$Res call({
 String id, int sequenceOrder, RouteStopType stopType, RouteStopStatus status, String name, String address, double latitude, double longitude, String? arrivalNotes, DateTime windowStart, DateTime windowEnd, DateTime scheduledArrival, DateTime? actualArrival, int serviceDurationMinutes, int bufferMinutes, DateTime? actualDeparture, String? appointmentId, String? clientId, String? serviceId, String? serviceName, int? travelToNextMinutes, int? distanceToNextMeters, String? providerNotes, DateTime updatedAt
});




}
/// @nodoc
class __$RouteStopCopyWithImpl<$Res>
    implements _$RouteStopCopyWith<$Res> {
  __$RouteStopCopyWithImpl(this._self, this._then);

  final _RouteStop _self;
  final $Res Function(_RouteStop) _then;

/// Create a copy of RouteStop
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sequenceOrder = null,Object? stopType = null,Object? status = null,Object? name = null,Object? address = null,Object? latitude = null,Object? longitude = null,Object? arrivalNotes = freezed,Object? windowStart = null,Object? windowEnd = null,Object? scheduledArrival = null,Object? actualArrival = freezed,Object? serviceDurationMinutes = null,Object? bufferMinutes = null,Object? actualDeparture = freezed,Object? appointmentId = freezed,Object? clientId = freezed,Object? serviceId = freezed,Object? serviceName = freezed,Object? travelToNextMinutes = freezed,Object? distanceToNextMeters = freezed,Object? providerNotes = freezed,Object? updatedAt = null,}) {
  return _then(_RouteStop(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sequenceOrder: null == sequenceOrder ? _self.sequenceOrder : sequenceOrder // ignore: cast_nullable_to_non_nullable
as int,stopType: null == stopType ? _self.stopType : stopType // ignore: cast_nullable_to_non_nullable
as RouteStopType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RouteStopStatus,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,arrivalNotes: freezed == arrivalNotes ? _self.arrivalNotes : arrivalNotes // ignore: cast_nullable_to_non_nullable
as String?,windowStart: null == windowStart ? _self.windowStart : windowStart // ignore: cast_nullable_to_non_nullable
as DateTime,windowEnd: null == windowEnd ? _self.windowEnd : windowEnd // ignore: cast_nullable_to_non_nullable
as DateTime,scheduledArrival: null == scheduledArrival ? _self.scheduledArrival : scheduledArrival // ignore: cast_nullable_to_non_nullable
as DateTime,actualArrival: freezed == actualArrival ? _self.actualArrival : actualArrival // ignore: cast_nullable_to_non_nullable
as DateTime?,serviceDurationMinutes: null == serviceDurationMinutes ? _self.serviceDurationMinutes : serviceDurationMinutes // ignore: cast_nullable_to_non_nullable
as int,bufferMinutes: null == bufferMinutes ? _self.bufferMinutes : bufferMinutes // ignore: cast_nullable_to_non_nullable
as int,actualDeparture: freezed == actualDeparture ? _self.actualDeparture : actualDeparture // ignore: cast_nullable_to_non_nullable
as DateTime?,appointmentId: freezed == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String?,clientId: freezed == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String?,serviceId: freezed == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String?,serviceName: freezed == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as String?,travelToNextMinutes: freezed == travelToNextMinutes ? _self.travelToNextMinutes : travelToNextMinutes // ignore: cast_nullable_to_non_nullable
as int?,distanceToNextMeters: freezed == distanceToNextMeters ? _self.distanceToNextMeters : distanceToNextMeters // ignore: cast_nullable_to_non_nullable
as int?,providerNotes: freezed == providerNotes ? _self.providerNotes : providerNotes // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
