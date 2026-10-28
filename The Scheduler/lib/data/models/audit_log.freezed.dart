// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audit_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuditLogEntry {

/// Optional document ID for round-tripping Firestore entries.
 String? get id;/// Tenant isolation scope.
 String get businessId;/// Acting user.
 String get userId;/// Action category captured for compliance reporting.
 AuditActionType get actionType;/// Entity type (e.g., 'Client', 'Appointment').
 String get entityType;/// Entity identifier (use a high-level identifier for list reads).
 String get entityId;/// Server-assigned timestamp of the event.
@NullableTimestampConverter() DateTime? get timestamp;/// Server-captured IP address (never client-provided).
 String? get ipAddress;/// Optional device descriptor (OS, app version, platform).
 Map<String, dynamic>? get deviceInfo;/// Optional correlation ID to stitch related actions.
 String? get correlationId;/// Additional structured context; never include PHI or free text.
 Map<String, dynamic> get metadata;
/// Create a copy of AuditLogEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuditLogEntryCopyWith<AuditLogEntry> get copyWith => _$AuditLogEntryCopyWithImpl<AuditLogEntry>(this as AuditLogEntry, _$identity);

  /// Serializes this AuditLogEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuditLogEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.actionType, actionType) || other.actionType == actionType)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.ipAddress, ipAddress) || other.ipAddress == ipAddress)&&const DeepCollectionEquality().equals(other.deviceInfo, deviceInfo)&&(identical(other.correlationId, correlationId) || other.correlationId == correlationId)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,userId,actionType,entityType,entityId,timestamp,ipAddress,const DeepCollectionEquality().hash(deviceInfo),correlationId,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'AuditLogEntry(id: $id, businessId: $businessId, userId: $userId, actionType: $actionType, entityType: $entityType, entityId: $entityId, timestamp: $timestamp, ipAddress: $ipAddress, deviceInfo: $deviceInfo, correlationId: $correlationId, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $AuditLogEntryCopyWith<$Res>  {
  factory $AuditLogEntryCopyWith(AuditLogEntry value, $Res Function(AuditLogEntry) _then) = _$AuditLogEntryCopyWithImpl;
@useResult
$Res call({
 String? id, String businessId, String userId, AuditActionType actionType, String entityType, String entityId,@NullableTimestampConverter() DateTime? timestamp, String? ipAddress, Map<String, dynamic>? deviceInfo, String? correlationId, Map<String, dynamic> metadata
});




}
/// @nodoc
class _$AuditLogEntryCopyWithImpl<$Res>
    implements $AuditLogEntryCopyWith<$Res> {
  _$AuditLogEntryCopyWithImpl(this._self, this._then);

  final AuditLogEntry _self;
  final $Res Function(AuditLogEntry) _then;

/// Create a copy of AuditLogEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? businessId = null,Object? userId = null,Object? actionType = null,Object? entityType = null,Object? entityId = null,Object? timestamp = freezed,Object? ipAddress = freezed,Object? deviceInfo = freezed,Object? correlationId = freezed,Object? metadata = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,actionType: null == actionType ? _self.actionType : actionType // ignore: cast_nullable_to_non_nullable
as AuditActionType,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as String,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime?,ipAddress: freezed == ipAddress ? _self.ipAddress : ipAddress // ignore: cast_nullable_to_non_nullable
as String?,deviceInfo: freezed == deviceInfo ? _self.deviceInfo : deviceInfo // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,correlationId: freezed == correlationId ? _self.correlationId : correlationId // ignore: cast_nullable_to_non_nullable
as String?,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [AuditLogEntry].
extension AuditLogEntryPatterns on AuditLogEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuditLogEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuditLogEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuditLogEntry value)  $default,){
final _that = this;
switch (_that) {
case _AuditLogEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuditLogEntry value)?  $default,){
final _that = this;
switch (_that) {
case _AuditLogEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id,  String businessId,  String userId,  AuditActionType actionType,  String entityType,  String entityId, @NullableTimestampConverter()  DateTime? timestamp,  String? ipAddress,  Map<String, dynamic>? deviceInfo,  String? correlationId,  Map<String, dynamic> metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuditLogEntry() when $default != null:
return $default(_that.id,_that.businessId,_that.userId,_that.actionType,_that.entityType,_that.entityId,_that.timestamp,_that.ipAddress,_that.deviceInfo,_that.correlationId,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id,  String businessId,  String userId,  AuditActionType actionType,  String entityType,  String entityId, @NullableTimestampConverter()  DateTime? timestamp,  String? ipAddress,  Map<String, dynamic>? deviceInfo,  String? correlationId,  Map<String, dynamic> metadata)  $default,) {final _that = this;
switch (_that) {
case _AuditLogEntry():
return $default(_that.id,_that.businessId,_that.userId,_that.actionType,_that.entityType,_that.entityId,_that.timestamp,_that.ipAddress,_that.deviceInfo,_that.correlationId,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id,  String businessId,  String userId,  AuditActionType actionType,  String entityType,  String entityId, @NullableTimestampConverter()  DateTime? timestamp,  String? ipAddress,  Map<String, dynamic>? deviceInfo,  String? correlationId,  Map<String, dynamic> metadata)?  $default,) {final _that = this;
switch (_that) {
case _AuditLogEntry() when $default != null:
return $default(_that.id,_that.businessId,_that.userId,_that.actionType,_that.entityType,_that.entityId,_that.timestamp,_that.ipAddress,_that.deviceInfo,_that.correlationId,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuditLogEntry implements AuditLogEntry {
  const _AuditLogEntry({this.id, required this.businessId, required this.userId, required this.actionType, required this.entityType, required this.entityId, @NullableTimestampConverter() this.timestamp, this.ipAddress, final  Map<String, dynamic>? deviceInfo, this.correlationId, final  Map<String, dynamic> metadata = const <String, dynamic>{}}): _deviceInfo = deviceInfo,_metadata = metadata;
  factory _AuditLogEntry.fromJson(Map<String, dynamic> json) => _$AuditLogEntryFromJson(json);

/// Optional document ID for round-tripping Firestore entries.
@override final  String? id;
/// Tenant isolation scope.
@override final  String businessId;
/// Acting user.
@override final  String userId;
/// Action category captured for compliance reporting.
@override final  AuditActionType actionType;
/// Entity type (e.g., 'Client', 'Appointment').
@override final  String entityType;
/// Entity identifier (use a high-level identifier for list reads).
@override final  String entityId;
/// Server-assigned timestamp of the event.
@override@NullableTimestampConverter() final  DateTime? timestamp;
/// Server-captured IP address (never client-provided).
@override final  String? ipAddress;
/// Optional device descriptor (OS, app version, platform).
 final  Map<String, dynamic>? _deviceInfo;
/// Optional device descriptor (OS, app version, platform).
@override Map<String, dynamic>? get deviceInfo {
  final value = _deviceInfo;
  if (value == null) return null;
  if (_deviceInfo is EqualUnmodifiableMapView) return _deviceInfo;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// Optional correlation ID to stitch related actions.
@override final  String? correlationId;
/// Additional structured context; never include PHI or free text.
 final  Map<String, dynamic> _metadata;
/// Additional structured context; never include PHI or free text.
@override@JsonKey() Map<String, dynamic> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}


/// Create a copy of AuditLogEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuditLogEntryCopyWith<_AuditLogEntry> get copyWith => __$AuditLogEntryCopyWithImpl<_AuditLogEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuditLogEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuditLogEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.actionType, actionType) || other.actionType == actionType)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.ipAddress, ipAddress) || other.ipAddress == ipAddress)&&const DeepCollectionEquality().equals(other._deviceInfo, _deviceInfo)&&(identical(other.correlationId, correlationId) || other.correlationId == correlationId)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,userId,actionType,entityType,entityId,timestamp,ipAddress,const DeepCollectionEquality().hash(_deviceInfo),correlationId,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'AuditLogEntry(id: $id, businessId: $businessId, userId: $userId, actionType: $actionType, entityType: $entityType, entityId: $entityId, timestamp: $timestamp, ipAddress: $ipAddress, deviceInfo: $deviceInfo, correlationId: $correlationId, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$AuditLogEntryCopyWith<$Res> implements $AuditLogEntryCopyWith<$Res> {
  factory _$AuditLogEntryCopyWith(_AuditLogEntry value, $Res Function(_AuditLogEntry) _then) = __$AuditLogEntryCopyWithImpl;
@override @useResult
$Res call({
 String? id, String businessId, String userId, AuditActionType actionType, String entityType, String entityId,@NullableTimestampConverter() DateTime? timestamp, String? ipAddress, Map<String, dynamic>? deviceInfo, String? correlationId, Map<String, dynamic> metadata
});




}
/// @nodoc
class __$AuditLogEntryCopyWithImpl<$Res>
    implements _$AuditLogEntryCopyWith<$Res> {
  __$AuditLogEntryCopyWithImpl(this._self, this._then);

  final _AuditLogEntry _self;
  final $Res Function(_AuditLogEntry) _then;

/// Create a copy of AuditLogEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? businessId = null,Object? userId = null,Object? actionType = null,Object? entityType = null,Object? entityId = null,Object? timestamp = freezed,Object? ipAddress = freezed,Object? deviceInfo = freezed,Object? correlationId = freezed,Object? metadata = null,}) {
  return _then(_AuditLogEntry(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,actionType: null == actionType ? _self.actionType : actionType // ignore: cast_nullable_to_non_nullable
as AuditActionType,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as String,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime?,ipAddress: freezed == ipAddress ? _self.ipAddress : ipAddress // ignore: cast_nullable_to_non_nullable
as String?,deviceInfo: freezed == deviceInfo ? _self._deviceInfo : deviceInfo // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,correlationId: freezed == correlationId ? _self.correlationId : correlationId // ignore: cast_nullable_to_non_nullable
as String?,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
