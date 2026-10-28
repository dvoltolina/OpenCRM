// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'join_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JoinRequest {

 String get id; String get businessId;/// User ID of the person requesting to join
 String get requestorUserId;/// Email address of the requestor
 String get requestorEmail;/// Display name of the requestor
 String get requestorDisplayName;/// Role the requestor is asking for
 String get role;/// Current status of the request
 JoinRequestStatus get status;/// Device/client metadata (no PHI, for audit purposes)
 Map<String, dynamic> get metadata;/// When the request was created
@_TimestampConverter() DateTime get createdAt;/// When the request was reviewed (optional)
@_NullableTimestampConverter() DateTime? get reviewedAt;/// User ID of the admin/owner who reviewed the request (optional)
 String? get reviewedBy;/// Notes from the reviewer about approval/denial (optional)
 String? get reviewNotes;
/// Create a copy of JoinRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JoinRequestCopyWith<JoinRequest> get copyWith => _$JoinRequestCopyWithImpl<JoinRequest>(this as JoinRequest, _$identity);

  /// Serializes this JoinRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JoinRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.requestorUserId, requestorUserId) || other.requestorUserId == requestorUserId)&&(identical(other.requestorEmail, requestorEmail) || other.requestorEmail == requestorEmail)&&(identical(other.requestorDisplayName, requestorDisplayName) || other.requestorDisplayName == requestorDisplayName)&&(identical(other.role, role) || other.role == role)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.metadata, metadata)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt)&&(identical(other.reviewedBy, reviewedBy) || other.reviewedBy == reviewedBy)&&(identical(other.reviewNotes, reviewNotes) || other.reviewNotes == reviewNotes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,requestorUserId,requestorEmail,requestorDisplayName,role,status,const DeepCollectionEquality().hash(metadata),createdAt,reviewedAt,reviewedBy,reviewNotes);

@override
String toString() {
  return 'JoinRequest(id: $id, businessId: $businessId, requestorUserId: $requestorUserId, requestorEmail: $requestorEmail, requestorDisplayName: $requestorDisplayName, role: $role, status: $status, metadata: $metadata, createdAt: $createdAt, reviewedAt: $reviewedAt, reviewedBy: $reviewedBy, reviewNotes: $reviewNotes)';
}


}

/// @nodoc
abstract mixin class $JoinRequestCopyWith<$Res>  {
  factory $JoinRequestCopyWith(JoinRequest value, $Res Function(JoinRequest) _then) = _$JoinRequestCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String requestorUserId, String requestorEmail, String requestorDisplayName, String role, JoinRequestStatus status, Map<String, dynamic> metadata,@_TimestampConverter() DateTime createdAt,@_NullableTimestampConverter() DateTime? reviewedAt, String? reviewedBy, String? reviewNotes
});




}
/// @nodoc
class _$JoinRequestCopyWithImpl<$Res>
    implements $JoinRequestCopyWith<$Res> {
  _$JoinRequestCopyWithImpl(this._self, this._then);

  final JoinRequest _self;
  final $Res Function(JoinRequest) _then;

/// Create a copy of JoinRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? requestorUserId = null,Object? requestorEmail = null,Object? requestorDisplayName = null,Object? role = null,Object? status = null,Object? metadata = null,Object? createdAt = null,Object? reviewedAt = freezed,Object? reviewedBy = freezed,Object? reviewNotes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,requestorUserId: null == requestorUserId ? _self.requestorUserId : requestorUserId // ignore: cast_nullable_to_non_nullable
as String,requestorEmail: null == requestorEmail ? _self.requestorEmail : requestorEmail // ignore: cast_nullable_to_non_nullable
as String,requestorDisplayName: null == requestorDisplayName ? _self.requestorDisplayName : requestorDisplayName // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JoinRequestStatus,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reviewedBy: freezed == reviewedBy ? _self.reviewedBy : reviewedBy // ignore: cast_nullable_to_non_nullable
as String?,reviewNotes: freezed == reviewNotes ? _self.reviewNotes : reviewNotes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [JoinRequest].
extension JoinRequestPatterns on JoinRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JoinRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JoinRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JoinRequest value)  $default,){
final _that = this;
switch (_that) {
case _JoinRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JoinRequest value)?  $default,){
final _that = this;
switch (_that) {
case _JoinRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String requestorUserId,  String requestorEmail,  String requestorDisplayName,  String role,  JoinRequestStatus status,  Map<String, dynamic> metadata, @_TimestampConverter()  DateTime createdAt, @_NullableTimestampConverter()  DateTime? reviewedAt,  String? reviewedBy,  String? reviewNotes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JoinRequest() when $default != null:
return $default(_that.id,_that.businessId,_that.requestorUserId,_that.requestorEmail,_that.requestorDisplayName,_that.role,_that.status,_that.metadata,_that.createdAt,_that.reviewedAt,_that.reviewedBy,_that.reviewNotes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String requestorUserId,  String requestorEmail,  String requestorDisplayName,  String role,  JoinRequestStatus status,  Map<String, dynamic> metadata, @_TimestampConverter()  DateTime createdAt, @_NullableTimestampConverter()  DateTime? reviewedAt,  String? reviewedBy,  String? reviewNotes)  $default,) {final _that = this;
switch (_that) {
case _JoinRequest():
return $default(_that.id,_that.businessId,_that.requestorUserId,_that.requestorEmail,_that.requestorDisplayName,_that.role,_that.status,_that.metadata,_that.createdAt,_that.reviewedAt,_that.reviewedBy,_that.reviewNotes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String requestorUserId,  String requestorEmail,  String requestorDisplayName,  String role,  JoinRequestStatus status,  Map<String, dynamic> metadata, @_TimestampConverter()  DateTime createdAt, @_NullableTimestampConverter()  DateTime? reviewedAt,  String? reviewedBy,  String? reviewNotes)?  $default,) {final _that = this;
switch (_that) {
case _JoinRequest() when $default != null:
return $default(_that.id,_that.businessId,_that.requestorUserId,_that.requestorEmail,_that.requestorDisplayName,_that.role,_that.status,_that.metadata,_that.createdAt,_that.reviewedAt,_that.reviewedBy,_that.reviewNotes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JoinRequest extends JoinRequest {
  const _JoinRequest({required this.id, required this.businessId, required this.requestorUserId, required this.requestorEmail, required this.requestorDisplayName, required this.role, required this.status, final  Map<String, dynamic> metadata = const <String, dynamic>{}, @_TimestampConverter() required this.createdAt, @_NullableTimestampConverter() this.reviewedAt, this.reviewedBy, this.reviewNotes}): _metadata = metadata,super._();
  factory _JoinRequest.fromJson(Map<String, dynamic> json) => _$JoinRequestFromJson(json);

@override final  String id;
@override final  String businessId;
/// User ID of the person requesting to join
@override final  String requestorUserId;
/// Email address of the requestor
@override final  String requestorEmail;
/// Display name of the requestor
@override final  String requestorDisplayName;
/// Role the requestor is asking for
@override final  String role;
/// Current status of the request
@override final  JoinRequestStatus status;
/// Device/client metadata (no PHI, for audit purposes)
 final  Map<String, dynamic> _metadata;
/// Device/client metadata (no PHI, for audit purposes)
@override@JsonKey() Map<String, dynamic> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}

/// When the request was created
@override@_TimestampConverter() final  DateTime createdAt;
/// When the request was reviewed (optional)
@override@_NullableTimestampConverter() final  DateTime? reviewedAt;
/// User ID of the admin/owner who reviewed the request (optional)
@override final  String? reviewedBy;
/// Notes from the reviewer about approval/denial (optional)
@override final  String? reviewNotes;

/// Create a copy of JoinRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JoinRequestCopyWith<_JoinRequest> get copyWith => __$JoinRequestCopyWithImpl<_JoinRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JoinRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JoinRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.requestorUserId, requestorUserId) || other.requestorUserId == requestorUserId)&&(identical(other.requestorEmail, requestorEmail) || other.requestorEmail == requestorEmail)&&(identical(other.requestorDisplayName, requestorDisplayName) || other.requestorDisplayName == requestorDisplayName)&&(identical(other.role, role) || other.role == role)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._metadata, _metadata)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt)&&(identical(other.reviewedBy, reviewedBy) || other.reviewedBy == reviewedBy)&&(identical(other.reviewNotes, reviewNotes) || other.reviewNotes == reviewNotes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,requestorUserId,requestorEmail,requestorDisplayName,role,status,const DeepCollectionEquality().hash(_metadata),createdAt,reviewedAt,reviewedBy,reviewNotes);

@override
String toString() {
  return 'JoinRequest(id: $id, businessId: $businessId, requestorUserId: $requestorUserId, requestorEmail: $requestorEmail, requestorDisplayName: $requestorDisplayName, role: $role, status: $status, metadata: $metadata, createdAt: $createdAt, reviewedAt: $reviewedAt, reviewedBy: $reviewedBy, reviewNotes: $reviewNotes)';
}


}

/// @nodoc
abstract mixin class _$JoinRequestCopyWith<$Res> implements $JoinRequestCopyWith<$Res> {
  factory _$JoinRequestCopyWith(_JoinRequest value, $Res Function(_JoinRequest) _then) = __$JoinRequestCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String requestorUserId, String requestorEmail, String requestorDisplayName, String role, JoinRequestStatus status, Map<String, dynamic> metadata,@_TimestampConverter() DateTime createdAt,@_NullableTimestampConverter() DateTime? reviewedAt, String? reviewedBy, String? reviewNotes
});




}
/// @nodoc
class __$JoinRequestCopyWithImpl<$Res>
    implements _$JoinRequestCopyWith<$Res> {
  __$JoinRequestCopyWithImpl(this._self, this._then);

  final _JoinRequest _self;
  final $Res Function(_JoinRequest) _then;

/// Create a copy of JoinRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? requestorUserId = null,Object? requestorEmail = null,Object? requestorDisplayName = null,Object? role = null,Object? status = null,Object? metadata = null,Object? createdAt = null,Object? reviewedAt = freezed,Object? reviewedBy = freezed,Object? reviewNotes = freezed,}) {
  return _then(_JoinRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,requestorUserId: null == requestorUserId ? _self.requestorUserId : requestorUserId // ignore: cast_nullable_to_non_nullable
as String,requestorEmail: null == requestorEmail ? _self.requestorEmail : requestorEmail // ignore: cast_nullable_to_non_nullable
as String,requestorDisplayName: null == requestorDisplayName ? _self.requestorDisplayName : requestorDisplayName // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JoinRequestStatus,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reviewedBy: freezed == reviewedBy ? _self.reviewedBy : reviewedBy // ignore: cast_nullable_to_non_nullable
as String?,reviewNotes: freezed == reviewNotes ? _self.reviewNotes : reviewNotes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
