// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'modification_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ModificationRequest {

 String get id; String get businessId; String get appointmentId; String get clientId; String get providerId; ModificationRequestType get type; ModificationRequestStatus get status;@NullableTimestampConverter() DateTime? get requestedStartTime; int? get requestedDurationMinutes; String? get reason; bool get policyWindowBreached; bool get feeRequired; double? get feeAmount; bool get feeCollected; String? get requestedByName; String? get requestedByEmail;@NullableTimestampConverter() DateTime? get decisionAt; String? get decidedBy; String? get decisionNotes;@TimestampConverter() DateTime get createdAt;@NullableTimestampConverter() DateTime? get updatedAt; Map<String, dynamic>? get metadata;
/// Create a copy of ModificationRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModificationRequestCopyWith<ModificationRequest> get copyWith => _$ModificationRequestCopyWithImpl<ModificationRequest>(this as ModificationRequest, _$identity);

  /// Serializes this ModificationRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModificationRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.requestedStartTime, requestedStartTime) || other.requestedStartTime == requestedStartTime)&&(identical(other.requestedDurationMinutes, requestedDurationMinutes) || other.requestedDurationMinutes == requestedDurationMinutes)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.policyWindowBreached, policyWindowBreached) || other.policyWindowBreached == policyWindowBreached)&&(identical(other.feeRequired, feeRequired) || other.feeRequired == feeRequired)&&(identical(other.feeAmount, feeAmount) || other.feeAmount == feeAmount)&&(identical(other.feeCollected, feeCollected) || other.feeCollected == feeCollected)&&(identical(other.requestedByName, requestedByName) || other.requestedByName == requestedByName)&&(identical(other.requestedByEmail, requestedByEmail) || other.requestedByEmail == requestedByEmail)&&(identical(other.decisionAt, decisionAt) || other.decisionAt == decisionAt)&&(identical(other.decidedBy, decidedBy) || other.decidedBy == decidedBy)&&(identical(other.decisionNotes, decisionNotes) || other.decisionNotes == decisionNotes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,businessId,appointmentId,clientId,providerId,type,status,requestedStartTime,requestedDurationMinutes,reason,policyWindowBreached,feeRequired,feeAmount,feeCollected,requestedByName,requestedByEmail,decisionAt,decidedBy,decisionNotes,createdAt,updatedAt,const DeepCollectionEquality().hash(metadata)]);

@override
String toString() {
  return 'ModificationRequest(id: $id, businessId: $businessId, appointmentId: $appointmentId, clientId: $clientId, providerId: $providerId, type: $type, status: $status, requestedStartTime: $requestedStartTime, requestedDurationMinutes: $requestedDurationMinutes, reason: $reason, policyWindowBreached: $policyWindowBreached, feeRequired: $feeRequired, feeAmount: $feeAmount, feeCollected: $feeCollected, requestedByName: $requestedByName, requestedByEmail: $requestedByEmail, decisionAt: $decisionAt, decidedBy: $decidedBy, decisionNotes: $decisionNotes, createdAt: $createdAt, updatedAt: $updatedAt, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $ModificationRequestCopyWith<$Res>  {
  factory $ModificationRequestCopyWith(ModificationRequest value, $Res Function(ModificationRequest) _then) = _$ModificationRequestCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String appointmentId, String clientId, String providerId, ModificationRequestType type, ModificationRequestStatus status,@NullableTimestampConverter() DateTime? requestedStartTime, int? requestedDurationMinutes, String? reason, bool policyWindowBreached, bool feeRequired, double? feeAmount, bool feeCollected, String? requestedByName, String? requestedByEmail,@NullableTimestampConverter() DateTime? decisionAt, String? decidedBy, String? decisionNotes,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? updatedAt, Map<String, dynamic>? metadata
});




}
/// @nodoc
class _$ModificationRequestCopyWithImpl<$Res>
    implements $ModificationRequestCopyWith<$Res> {
  _$ModificationRequestCopyWithImpl(this._self, this._then);

  final ModificationRequest _self;
  final $Res Function(ModificationRequest) _then;

/// Create a copy of ModificationRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? appointmentId = null,Object? clientId = null,Object? providerId = null,Object? type = null,Object? status = null,Object? requestedStartTime = freezed,Object? requestedDurationMinutes = freezed,Object? reason = freezed,Object? policyWindowBreached = null,Object? feeRequired = null,Object? feeAmount = freezed,Object? feeCollected = null,Object? requestedByName = freezed,Object? requestedByEmail = freezed,Object? decisionAt = freezed,Object? decidedBy = freezed,Object? decisionNotes = freezed,Object? createdAt = null,Object? updatedAt = freezed,Object? metadata = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,appointmentId: null == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String,clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ModificationRequestType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ModificationRequestStatus,requestedStartTime: freezed == requestedStartTime ? _self.requestedStartTime : requestedStartTime // ignore: cast_nullable_to_non_nullable
as DateTime?,requestedDurationMinutes: freezed == requestedDurationMinutes ? _self.requestedDurationMinutes : requestedDurationMinutes // ignore: cast_nullable_to_non_nullable
as int?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,policyWindowBreached: null == policyWindowBreached ? _self.policyWindowBreached : policyWindowBreached // ignore: cast_nullable_to_non_nullable
as bool,feeRequired: null == feeRequired ? _self.feeRequired : feeRequired // ignore: cast_nullable_to_non_nullable
as bool,feeAmount: freezed == feeAmount ? _self.feeAmount : feeAmount // ignore: cast_nullable_to_non_nullable
as double?,feeCollected: null == feeCollected ? _self.feeCollected : feeCollected // ignore: cast_nullable_to_non_nullable
as bool,requestedByName: freezed == requestedByName ? _self.requestedByName : requestedByName // ignore: cast_nullable_to_non_nullable
as String?,requestedByEmail: freezed == requestedByEmail ? _self.requestedByEmail : requestedByEmail // ignore: cast_nullable_to_non_nullable
as String?,decisionAt: freezed == decisionAt ? _self.decisionAt : decisionAt // ignore: cast_nullable_to_non_nullable
as DateTime?,decidedBy: freezed == decidedBy ? _self.decidedBy : decidedBy // ignore: cast_nullable_to_non_nullable
as String?,decisionNotes: freezed == decisionNotes ? _self.decisionNotes : decisionNotes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [ModificationRequest].
extension ModificationRequestPatterns on ModificationRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModificationRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModificationRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModificationRequest value)  $default,){
final _that = this;
switch (_that) {
case _ModificationRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModificationRequest value)?  $default,){
final _that = this;
switch (_that) {
case _ModificationRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String appointmentId,  String clientId,  String providerId,  ModificationRequestType type,  ModificationRequestStatus status, @NullableTimestampConverter()  DateTime? requestedStartTime,  int? requestedDurationMinutes,  String? reason,  bool policyWindowBreached,  bool feeRequired,  double? feeAmount,  bool feeCollected,  String? requestedByName,  String? requestedByEmail, @NullableTimestampConverter()  DateTime? decisionAt,  String? decidedBy,  String? decisionNotes, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt,  Map<String, dynamic>? metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModificationRequest() when $default != null:
return $default(_that.id,_that.businessId,_that.appointmentId,_that.clientId,_that.providerId,_that.type,_that.status,_that.requestedStartTime,_that.requestedDurationMinutes,_that.reason,_that.policyWindowBreached,_that.feeRequired,_that.feeAmount,_that.feeCollected,_that.requestedByName,_that.requestedByEmail,_that.decisionAt,_that.decidedBy,_that.decisionNotes,_that.createdAt,_that.updatedAt,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String appointmentId,  String clientId,  String providerId,  ModificationRequestType type,  ModificationRequestStatus status, @NullableTimestampConverter()  DateTime? requestedStartTime,  int? requestedDurationMinutes,  String? reason,  bool policyWindowBreached,  bool feeRequired,  double? feeAmount,  bool feeCollected,  String? requestedByName,  String? requestedByEmail, @NullableTimestampConverter()  DateTime? decisionAt,  String? decidedBy,  String? decisionNotes, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt,  Map<String, dynamic>? metadata)  $default,) {final _that = this;
switch (_that) {
case _ModificationRequest():
return $default(_that.id,_that.businessId,_that.appointmentId,_that.clientId,_that.providerId,_that.type,_that.status,_that.requestedStartTime,_that.requestedDurationMinutes,_that.reason,_that.policyWindowBreached,_that.feeRequired,_that.feeAmount,_that.feeCollected,_that.requestedByName,_that.requestedByEmail,_that.decisionAt,_that.decidedBy,_that.decisionNotes,_that.createdAt,_that.updatedAt,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String appointmentId,  String clientId,  String providerId,  ModificationRequestType type,  ModificationRequestStatus status, @NullableTimestampConverter()  DateTime? requestedStartTime,  int? requestedDurationMinutes,  String? reason,  bool policyWindowBreached,  bool feeRequired,  double? feeAmount,  bool feeCollected,  String? requestedByName,  String? requestedByEmail, @NullableTimestampConverter()  DateTime? decisionAt,  String? decidedBy,  String? decisionNotes, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt,  Map<String, dynamic>? metadata)?  $default,) {final _that = this;
switch (_that) {
case _ModificationRequest() when $default != null:
return $default(_that.id,_that.businessId,_that.appointmentId,_that.clientId,_that.providerId,_that.type,_that.status,_that.requestedStartTime,_that.requestedDurationMinutes,_that.reason,_that.policyWindowBreached,_that.feeRequired,_that.feeAmount,_that.feeCollected,_that.requestedByName,_that.requestedByEmail,_that.decisionAt,_that.decidedBy,_that.decisionNotes,_that.createdAt,_that.updatedAt,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModificationRequest implements ModificationRequest {
  const _ModificationRequest({required this.id, required this.businessId, required this.appointmentId, required this.clientId, required this.providerId, required this.type, this.status = ModificationRequestStatus.pending, @NullableTimestampConverter() this.requestedStartTime, this.requestedDurationMinutes, this.reason, this.policyWindowBreached = false, this.feeRequired = false, this.feeAmount, this.feeCollected = false, this.requestedByName, this.requestedByEmail, @NullableTimestampConverter() this.decisionAt, this.decidedBy, this.decisionNotes, @TimestampConverter() required this.createdAt, @NullableTimestampConverter() this.updatedAt, final  Map<String, dynamic>? metadata}): _metadata = metadata;
  factory _ModificationRequest.fromJson(Map<String, dynamic> json) => _$ModificationRequestFromJson(json);

@override final  String id;
@override final  String businessId;
@override final  String appointmentId;
@override final  String clientId;
@override final  String providerId;
@override final  ModificationRequestType type;
@override@JsonKey() final  ModificationRequestStatus status;
@override@NullableTimestampConverter() final  DateTime? requestedStartTime;
@override final  int? requestedDurationMinutes;
@override final  String? reason;
@override@JsonKey() final  bool policyWindowBreached;
@override@JsonKey() final  bool feeRequired;
@override final  double? feeAmount;
@override@JsonKey() final  bool feeCollected;
@override final  String? requestedByName;
@override final  String? requestedByEmail;
@override@NullableTimestampConverter() final  DateTime? decisionAt;
@override final  String? decidedBy;
@override final  String? decisionNotes;
@override@TimestampConverter() final  DateTime createdAt;
@override@NullableTimestampConverter() final  DateTime? updatedAt;
 final  Map<String, dynamic>? _metadata;
@override Map<String, dynamic>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of ModificationRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModificationRequestCopyWith<_ModificationRequest> get copyWith => __$ModificationRequestCopyWithImpl<_ModificationRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModificationRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModificationRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.requestedStartTime, requestedStartTime) || other.requestedStartTime == requestedStartTime)&&(identical(other.requestedDurationMinutes, requestedDurationMinutes) || other.requestedDurationMinutes == requestedDurationMinutes)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.policyWindowBreached, policyWindowBreached) || other.policyWindowBreached == policyWindowBreached)&&(identical(other.feeRequired, feeRequired) || other.feeRequired == feeRequired)&&(identical(other.feeAmount, feeAmount) || other.feeAmount == feeAmount)&&(identical(other.feeCollected, feeCollected) || other.feeCollected == feeCollected)&&(identical(other.requestedByName, requestedByName) || other.requestedByName == requestedByName)&&(identical(other.requestedByEmail, requestedByEmail) || other.requestedByEmail == requestedByEmail)&&(identical(other.decisionAt, decisionAt) || other.decisionAt == decisionAt)&&(identical(other.decidedBy, decidedBy) || other.decidedBy == decidedBy)&&(identical(other.decisionNotes, decisionNotes) || other.decisionNotes == decisionNotes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,businessId,appointmentId,clientId,providerId,type,status,requestedStartTime,requestedDurationMinutes,reason,policyWindowBreached,feeRequired,feeAmount,feeCollected,requestedByName,requestedByEmail,decisionAt,decidedBy,decisionNotes,createdAt,updatedAt,const DeepCollectionEquality().hash(_metadata)]);

@override
String toString() {
  return 'ModificationRequest(id: $id, businessId: $businessId, appointmentId: $appointmentId, clientId: $clientId, providerId: $providerId, type: $type, status: $status, requestedStartTime: $requestedStartTime, requestedDurationMinutes: $requestedDurationMinutes, reason: $reason, policyWindowBreached: $policyWindowBreached, feeRequired: $feeRequired, feeAmount: $feeAmount, feeCollected: $feeCollected, requestedByName: $requestedByName, requestedByEmail: $requestedByEmail, decisionAt: $decisionAt, decidedBy: $decidedBy, decisionNotes: $decisionNotes, createdAt: $createdAt, updatedAt: $updatedAt, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$ModificationRequestCopyWith<$Res> implements $ModificationRequestCopyWith<$Res> {
  factory _$ModificationRequestCopyWith(_ModificationRequest value, $Res Function(_ModificationRequest) _then) = __$ModificationRequestCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String appointmentId, String clientId, String providerId, ModificationRequestType type, ModificationRequestStatus status,@NullableTimestampConverter() DateTime? requestedStartTime, int? requestedDurationMinutes, String? reason, bool policyWindowBreached, bool feeRequired, double? feeAmount, bool feeCollected, String? requestedByName, String? requestedByEmail,@NullableTimestampConverter() DateTime? decisionAt, String? decidedBy, String? decisionNotes,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? updatedAt, Map<String, dynamic>? metadata
});




}
/// @nodoc
class __$ModificationRequestCopyWithImpl<$Res>
    implements _$ModificationRequestCopyWith<$Res> {
  __$ModificationRequestCopyWithImpl(this._self, this._then);

  final _ModificationRequest _self;
  final $Res Function(_ModificationRequest) _then;

/// Create a copy of ModificationRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? appointmentId = null,Object? clientId = null,Object? providerId = null,Object? type = null,Object? status = null,Object? requestedStartTime = freezed,Object? requestedDurationMinutes = freezed,Object? reason = freezed,Object? policyWindowBreached = null,Object? feeRequired = null,Object? feeAmount = freezed,Object? feeCollected = null,Object? requestedByName = freezed,Object? requestedByEmail = freezed,Object? decisionAt = freezed,Object? decidedBy = freezed,Object? decisionNotes = freezed,Object? createdAt = null,Object? updatedAt = freezed,Object? metadata = freezed,}) {
  return _then(_ModificationRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,appointmentId: null == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String,clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ModificationRequestType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ModificationRequestStatus,requestedStartTime: freezed == requestedStartTime ? _self.requestedStartTime : requestedStartTime // ignore: cast_nullable_to_non_nullable
as DateTime?,requestedDurationMinutes: freezed == requestedDurationMinutes ? _self.requestedDurationMinutes : requestedDurationMinutes // ignore: cast_nullable_to_non_nullable
as int?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,policyWindowBreached: null == policyWindowBreached ? _self.policyWindowBreached : policyWindowBreached // ignore: cast_nullable_to_non_nullable
as bool,feeRequired: null == feeRequired ? _self.feeRequired : feeRequired // ignore: cast_nullable_to_non_nullable
as bool,feeAmount: freezed == feeAmount ? _self.feeAmount : feeAmount // ignore: cast_nullable_to_non_nullable
as double?,feeCollected: null == feeCollected ? _self.feeCollected : feeCollected // ignore: cast_nullable_to_non_nullable
as bool,requestedByName: freezed == requestedByName ? _self.requestedByName : requestedByName // ignore: cast_nullable_to_non_nullable
as String?,requestedByEmail: freezed == requestedByEmail ? _self.requestedByEmail : requestedByEmail // ignore: cast_nullable_to_non_nullable
as String?,decisionAt: freezed == decisionAt ? _self.decisionAt : decisionAt // ignore: cast_nullable_to_non_nullable
as DateTime?,decidedBy: freezed == decidedBy ? _self.decidedBy : decidedBy // ignore: cast_nullable_to_non_nullable
as String?,decisionNotes: freezed == decisionNotes ? _self.decisionNotes : decisionNotes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
