// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SyncRecord {

/// Unique identifier.
 String get id;/// Business this sync belongs to.
 String get businessId;/// The accounting connection this sync is for.
 String get connectionId;/// Local entity ID (payment ID, client ID, etc.).
 String get localId;/// Type of local entity.
 SyncLocalType get localType;/// Remote entity ID (QuickBooks/Xero ID).
 String? get remoteId;/// Type of remote entity.
 SyncRemoteType get remoteType;/// When the sync was attempted.
@TimestampConverter() DateTime get syncedAt;/// Direction of sync.
 SyncDirection get syncDirection;/// Status of the sync operation.
 SyncStatus get status;/// Error message if sync failed.
 String? get errorMessage;/// Number of retry attempts.
 int get retryCount;/// Additional metadata (e.g., amounts, reference numbers).
 Map<String, dynamic>? get metadata;/// Record creation timestamp.
@NullableTimestampConverter() DateTime? get createdAt;/// Last update timestamp.
@NullableTimestampConverter() DateTime? get updatedAt;
/// Create a copy of SyncRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncRecordCopyWith<SyncRecord> get copyWith => _$SyncRecordCopyWithImpl<SyncRecord>(this as SyncRecord, _$identity);

  /// Serializes this SyncRecord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.connectionId, connectionId) || other.connectionId == connectionId)&&(identical(other.localId, localId) || other.localId == localId)&&(identical(other.localType, localType) || other.localType == localType)&&(identical(other.remoteId, remoteId) || other.remoteId == remoteId)&&(identical(other.remoteType, remoteType) || other.remoteType == remoteType)&&(identical(other.syncedAt, syncedAt) || other.syncedAt == syncedAt)&&(identical(other.syncDirection, syncDirection) || other.syncDirection == syncDirection)&&(identical(other.status, status) || other.status == status)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.retryCount, retryCount) || other.retryCount == retryCount)&&const DeepCollectionEquality().equals(other.metadata, metadata)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,connectionId,localId,localType,remoteId,remoteType,syncedAt,syncDirection,status,errorMessage,retryCount,const DeepCollectionEquality().hash(metadata),createdAt,updatedAt);

@override
String toString() {
  return 'SyncRecord(id: $id, businessId: $businessId, connectionId: $connectionId, localId: $localId, localType: $localType, remoteId: $remoteId, remoteType: $remoteType, syncedAt: $syncedAt, syncDirection: $syncDirection, status: $status, errorMessage: $errorMessage, retryCount: $retryCount, metadata: $metadata, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $SyncRecordCopyWith<$Res>  {
  factory $SyncRecordCopyWith(SyncRecord value, $Res Function(SyncRecord) _then) = _$SyncRecordCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String connectionId, String localId, SyncLocalType localType, String? remoteId, SyncRemoteType remoteType,@TimestampConverter() DateTime syncedAt, SyncDirection syncDirection, SyncStatus status, String? errorMessage, int retryCount, Map<String, dynamic>? metadata,@NullableTimestampConverter() DateTime? createdAt,@NullableTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$SyncRecordCopyWithImpl<$Res>
    implements $SyncRecordCopyWith<$Res> {
  _$SyncRecordCopyWithImpl(this._self, this._then);

  final SyncRecord _self;
  final $Res Function(SyncRecord) _then;

/// Create a copy of SyncRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? connectionId = null,Object? localId = null,Object? localType = null,Object? remoteId = freezed,Object? remoteType = null,Object? syncedAt = null,Object? syncDirection = null,Object? status = null,Object? errorMessage = freezed,Object? retryCount = null,Object? metadata = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,connectionId: null == connectionId ? _self.connectionId : connectionId // ignore: cast_nullable_to_non_nullable
as String,localId: null == localId ? _self.localId : localId // ignore: cast_nullable_to_non_nullable
as String,localType: null == localType ? _self.localType : localType // ignore: cast_nullable_to_non_nullable
as SyncLocalType,remoteId: freezed == remoteId ? _self.remoteId : remoteId // ignore: cast_nullable_to_non_nullable
as String?,remoteType: null == remoteType ? _self.remoteType : remoteType // ignore: cast_nullable_to_non_nullable
as SyncRemoteType,syncedAt: null == syncedAt ? _self.syncedAt : syncedAt // ignore: cast_nullable_to_non_nullable
as DateTime,syncDirection: null == syncDirection ? _self.syncDirection : syncDirection // ignore: cast_nullable_to_non_nullable
as SyncDirection,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SyncStatus,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,retryCount: null == retryCount ? _self.retryCount : retryCount // ignore: cast_nullable_to_non_nullable
as int,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncRecord].
extension SyncRecordPatterns on SyncRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncRecord value)  $default,){
final _that = this;
switch (_that) {
case _SyncRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncRecord value)?  $default,){
final _that = this;
switch (_that) {
case _SyncRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String connectionId,  String localId,  SyncLocalType localType,  String? remoteId,  SyncRemoteType remoteType, @TimestampConverter()  DateTime syncedAt,  SyncDirection syncDirection,  SyncStatus status,  String? errorMessage,  int retryCount,  Map<String, dynamic>? metadata, @NullableTimestampConverter()  DateTime? createdAt, @NullableTimestampConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncRecord() when $default != null:
return $default(_that.id,_that.businessId,_that.connectionId,_that.localId,_that.localType,_that.remoteId,_that.remoteType,_that.syncedAt,_that.syncDirection,_that.status,_that.errorMessage,_that.retryCount,_that.metadata,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String connectionId,  String localId,  SyncLocalType localType,  String? remoteId,  SyncRemoteType remoteType, @TimestampConverter()  DateTime syncedAt,  SyncDirection syncDirection,  SyncStatus status,  String? errorMessage,  int retryCount,  Map<String, dynamic>? metadata, @NullableTimestampConverter()  DateTime? createdAt, @NullableTimestampConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _SyncRecord():
return $default(_that.id,_that.businessId,_that.connectionId,_that.localId,_that.localType,_that.remoteId,_that.remoteType,_that.syncedAt,_that.syncDirection,_that.status,_that.errorMessage,_that.retryCount,_that.metadata,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String connectionId,  String localId,  SyncLocalType localType,  String? remoteId,  SyncRemoteType remoteType, @TimestampConverter()  DateTime syncedAt,  SyncDirection syncDirection,  SyncStatus status,  String? errorMessage,  int retryCount,  Map<String, dynamic>? metadata, @NullableTimestampConverter()  DateTime? createdAt, @NullableTimestampConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _SyncRecord() when $default != null:
return $default(_that.id,_that.businessId,_that.connectionId,_that.localId,_that.localType,_that.remoteId,_that.remoteType,_that.syncedAt,_that.syncDirection,_that.status,_that.errorMessage,_that.retryCount,_that.metadata,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SyncRecord extends SyncRecord {
  const _SyncRecord({required this.id, required this.businessId, required this.connectionId, required this.localId, required this.localType, this.remoteId, required this.remoteType, @TimestampConverter() required this.syncedAt, required this.syncDirection, this.status = SyncStatus.pending, this.errorMessage, this.retryCount = 0, final  Map<String, dynamic>? metadata, @NullableTimestampConverter() this.createdAt, @NullableTimestampConverter() this.updatedAt}): _metadata = metadata,super._();
  factory _SyncRecord.fromJson(Map<String, dynamic> json) => _$SyncRecordFromJson(json);

/// Unique identifier.
@override final  String id;
/// Business this sync belongs to.
@override final  String businessId;
/// The accounting connection this sync is for.
@override final  String connectionId;
/// Local entity ID (payment ID, client ID, etc.).
@override final  String localId;
/// Type of local entity.
@override final  SyncLocalType localType;
/// Remote entity ID (QuickBooks/Xero ID).
@override final  String? remoteId;
/// Type of remote entity.
@override final  SyncRemoteType remoteType;
/// When the sync was attempted.
@override@TimestampConverter() final  DateTime syncedAt;
/// Direction of sync.
@override final  SyncDirection syncDirection;
/// Status of the sync operation.
@override@JsonKey() final  SyncStatus status;
/// Error message if sync failed.
@override final  String? errorMessage;
/// Number of retry attempts.
@override@JsonKey() final  int retryCount;
/// Additional metadata (e.g., amounts, reference numbers).
 final  Map<String, dynamic>? _metadata;
/// Additional metadata (e.g., amounts, reference numbers).
@override Map<String, dynamic>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// Record creation timestamp.
@override@NullableTimestampConverter() final  DateTime? createdAt;
/// Last update timestamp.
@override@NullableTimestampConverter() final  DateTime? updatedAt;

/// Create a copy of SyncRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncRecordCopyWith<_SyncRecord> get copyWith => __$SyncRecordCopyWithImpl<_SyncRecord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SyncRecordToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.connectionId, connectionId) || other.connectionId == connectionId)&&(identical(other.localId, localId) || other.localId == localId)&&(identical(other.localType, localType) || other.localType == localType)&&(identical(other.remoteId, remoteId) || other.remoteId == remoteId)&&(identical(other.remoteType, remoteType) || other.remoteType == remoteType)&&(identical(other.syncedAt, syncedAt) || other.syncedAt == syncedAt)&&(identical(other.syncDirection, syncDirection) || other.syncDirection == syncDirection)&&(identical(other.status, status) || other.status == status)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.retryCount, retryCount) || other.retryCount == retryCount)&&const DeepCollectionEquality().equals(other._metadata, _metadata)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,connectionId,localId,localType,remoteId,remoteType,syncedAt,syncDirection,status,errorMessage,retryCount,const DeepCollectionEquality().hash(_metadata),createdAt,updatedAt);

@override
String toString() {
  return 'SyncRecord(id: $id, businessId: $businessId, connectionId: $connectionId, localId: $localId, localType: $localType, remoteId: $remoteId, remoteType: $remoteType, syncedAt: $syncedAt, syncDirection: $syncDirection, status: $status, errorMessage: $errorMessage, retryCount: $retryCount, metadata: $metadata, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$SyncRecordCopyWith<$Res> implements $SyncRecordCopyWith<$Res> {
  factory _$SyncRecordCopyWith(_SyncRecord value, $Res Function(_SyncRecord) _then) = __$SyncRecordCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String connectionId, String localId, SyncLocalType localType, String? remoteId, SyncRemoteType remoteType,@TimestampConverter() DateTime syncedAt, SyncDirection syncDirection, SyncStatus status, String? errorMessage, int retryCount, Map<String, dynamic>? metadata,@NullableTimestampConverter() DateTime? createdAt,@NullableTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$SyncRecordCopyWithImpl<$Res>
    implements _$SyncRecordCopyWith<$Res> {
  __$SyncRecordCopyWithImpl(this._self, this._then);

  final _SyncRecord _self;
  final $Res Function(_SyncRecord) _then;

/// Create a copy of SyncRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? connectionId = null,Object? localId = null,Object? localType = null,Object? remoteId = freezed,Object? remoteType = null,Object? syncedAt = null,Object? syncDirection = null,Object? status = null,Object? errorMessage = freezed,Object? retryCount = null,Object? metadata = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_SyncRecord(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,connectionId: null == connectionId ? _self.connectionId : connectionId // ignore: cast_nullable_to_non_nullable
as String,localId: null == localId ? _self.localId : localId // ignore: cast_nullable_to_non_nullable
as String,localType: null == localType ? _self.localType : localType // ignore: cast_nullable_to_non_nullable
as SyncLocalType,remoteId: freezed == remoteId ? _self.remoteId : remoteId // ignore: cast_nullable_to_non_nullable
as String?,remoteType: null == remoteType ? _self.remoteType : remoteType // ignore: cast_nullable_to_non_nullable
as SyncRemoteType,syncedAt: null == syncedAt ? _self.syncedAt : syncedAt // ignore: cast_nullable_to_non_nullable
as DateTime,syncDirection: null == syncDirection ? _self.syncDirection : syncDirection // ignore: cast_nullable_to_non_nullable
as SyncDirection,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SyncStatus,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,retryCount: null == retryCount ? _self.retryCount : retryCount // ignore: cast_nullable_to_non_nullable
as int,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
