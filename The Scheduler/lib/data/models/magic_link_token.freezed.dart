// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'magic_link_token.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MagicLinkToken {

/// Unique token ID
 String get id;/// Business this token belongs to (multi-tenant isolation)
 String get businessId;/// Associated appointment ID
 String get appointmentId;/// Associated client ID
 String get clientId;/// Client email (for verification)
 String get clientEmail;/// Token string (random secure string)
 String get token;/// Token creation timestamp
@TimestampConverter() DateTime get createdAt;/// Token expiration timestamp (typically 48 hours from creation)
@TimestampConverter() DateTime get expiresAt;/// Whether the token has been used/accessed
 bool get hasBeenUsed;/// Last accessed timestamp (null if never accessed)
@NullableTimestampConverter() DateTime? get lastAccessedAt;/// Number of times this token has been accessed
 int get accessCount;/// Token status
 MagicLinkTokenStatus get status;
/// Create a copy of MagicLinkToken
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MagicLinkTokenCopyWith<MagicLinkToken> get copyWith => _$MagicLinkTokenCopyWithImpl<MagicLinkToken>(this as MagicLinkToken, _$identity);

  /// Serializes this MagicLinkToken to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MagicLinkToken&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.clientEmail, clientEmail) || other.clientEmail == clientEmail)&&(identical(other.token, token) || other.token == token)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.hasBeenUsed, hasBeenUsed) || other.hasBeenUsed == hasBeenUsed)&&(identical(other.lastAccessedAt, lastAccessedAt) || other.lastAccessedAt == lastAccessedAt)&&(identical(other.accessCount, accessCount) || other.accessCount == accessCount)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,appointmentId,clientId,clientEmail,token,createdAt,expiresAt,hasBeenUsed,lastAccessedAt,accessCount,status);

@override
String toString() {
  return 'MagicLinkToken(id: $id, businessId: $businessId, appointmentId: $appointmentId, clientId: $clientId, clientEmail: $clientEmail, token: $token, createdAt: $createdAt, expiresAt: $expiresAt, hasBeenUsed: $hasBeenUsed, lastAccessedAt: $lastAccessedAt, accessCount: $accessCount, status: $status)';
}


}

/// @nodoc
abstract mixin class $MagicLinkTokenCopyWith<$Res>  {
  factory $MagicLinkTokenCopyWith(MagicLinkToken value, $Res Function(MagicLinkToken) _then) = _$MagicLinkTokenCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String appointmentId, String clientId, String clientEmail, String token,@TimestampConverter() DateTime createdAt,@TimestampConverter() DateTime expiresAt, bool hasBeenUsed,@NullableTimestampConverter() DateTime? lastAccessedAt, int accessCount, MagicLinkTokenStatus status
});




}
/// @nodoc
class _$MagicLinkTokenCopyWithImpl<$Res>
    implements $MagicLinkTokenCopyWith<$Res> {
  _$MagicLinkTokenCopyWithImpl(this._self, this._then);

  final MagicLinkToken _self;
  final $Res Function(MagicLinkToken) _then;

/// Create a copy of MagicLinkToken
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? appointmentId = null,Object? clientId = null,Object? clientEmail = null,Object? token = null,Object? createdAt = null,Object? expiresAt = null,Object? hasBeenUsed = null,Object? lastAccessedAt = freezed,Object? accessCount = null,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,appointmentId: null == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String,clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,clientEmail: null == clientEmail ? _self.clientEmail : clientEmail // ignore: cast_nullable_to_non_nullable
as String,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,hasBeenUsed: null == hasBeenUsed ? _self.hasBeenUsed : hasBeenUsed // ignore: cast_nullable_to_non_nullable
as bool,lastAccessedAt: freezed == lastAccessedAt ? _self.lastAccessedAt : lastAccessedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,accessCount: null == accessCount ? _self.accessCount : accessCount // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MagicLinkTokenStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [MagicLinkToken].
extension MagicLinkTokenPatterns on MagicLinkToken {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MagicLinkToken value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MagicLinkToken() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MagicLinkToken value)  $default,){
final _that = this;
switch (_that) {
case _MagicLinkToken():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MagicLinkToken value)?  $default,){
final _that = this;
switch (_that) {
case _MagicLinkToken() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String appointmentId,  String clientId,  String clientEmail,  String token, @TimestampConverter()  DateTime createdAt, @TimestampConverter()  DateTime expiresAt,  bool hasBeenUsed, @NullableTimestampConverter()  DateTime? lastAccessedAt,  int accessCount,  MagicLinkTokenStatus status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MagicLinkToken() when $default != null:
return $default(_that.id,_that.businessId,_that.appointmentId,_that.clientId,_that.clientEmail,_that.token,_that.createdAt,_that.expiresAt,_that.hasBeenUsed,_that.lastAccessedAt,_that.accessCount,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String appointmentId,  String clientId,  String clientEmail,  String token, @TimestampConverter()  DateTime createdAt, @TimestampConverter()  DateTime expiresAt,  bool hasBeenUsed, @NullableTimestampConverter()  DateTime? lastAccessedAt,  int accessCount,  MagicLinkTokenStatus status)  $default,) {final _that = this;
switch (_that) {
case _MagicLinkToken():
return $default(_that.id,_that.businessId,_that.appointmentId,_that.clientId,_that.clientEmail,_that.token,_that.createdAt,_that.expiresAt,_that.hasBeenUsed,_that.lastAccessedAt,_that.accessCount,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String appointmentId,  String clientId,  String clientEmail,  String token, @TimestampConverter()  DateTime createdAt, @TimestampConverter()  DateTime expiresAt,  bool hasBeenUsed, @NullableTimestampConverter()  DateTime? lastAccessedAt,  int accessCount,  MagicLinkTokenStatus status)?  $default,) {final _that = this;
switch (_that) {
case _MagicLinkToken() when $default != null:
return $default(_that.id,_that.businessId,_that.appointmentId,_that.clientId,_that.clientEmail,_that.token,_that.createdAt,_that.expiresAt,_that.hasBeenUsed,_that.lastAccessedAt,_that.accessCount,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MagicLinkToken implements MagicLinkToken {
  const _MagicLinkToken({required this.id, required this.businessId, required this.appointmentId, required this.clientId, required this.clientEmail, required this.token, @TimestampConverter() required this.createdAt, @TimestampConverter() required this.expiresAt, this.hasBeenUsed = false, @NullableTimestampConverter() this.lastAccessedAt, this.accessCount = 0, this.status = MagicLinkTokenStatus.active});
  factory _MagicLinkToken.fromJson(Map<String, dynamic> json) => _$MagicLinkTokenFromJson(json);

/// Unique token ID
@override final  String id;
/// Business this token belongs to (multi-tenant isolation)
@override final  String businessId;
/// Associated appointment ID
@override final  String appointmentId;
/// Associated client ID
@override final  String clientId;
/// Client email (for verification)
@override final  String clientEmail;
/// Token string (random secure string)
@override final  String token;
/// Token creation timestamp
@override@TimestampConverter() final  DateTime createdAt;
/// Token expiration timestamp (typically 48 hours from creation)
@override@TimestampConverter() final  DateTime expiresAt;
/// Whether the token has been used/accessed
@override@JsonKey() final  bool hasBeenUsed;
/// Last accessed timestamp (null if never accessed)
@override@NullableTimestampConverter() final  DateTime? lastAccessedAt;
/// Number of times this token has been accessed
@override@JsonKey() final  int accessCount;
/// Token status
@override@JsonKey() final  MagicLinkTokenStatus status;

/// Create a copy of MagicLinkToken
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MagicLinkTokenCopyWith<_MagicLinkToken> get copyWith => __$MagicLinkTokenCopyWithImpl<_MagicLinkToken>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MagicLinkTokenToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MagicLinkToken&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.clientEmail, clientEmail) || other.clientEmail == clientEmail)&&(identical(other.token, token) || other.token == token)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.hasBeenUsed, hasBeenUsed) || other.hasBeenUsed == hasBeenUsed)&&(identical(other.lastAccessedAt, lastAccessedAt) || other.lastAccessedAt == lastAccessedAt)&&(identical(other.accessCount, accessCount) || other.accessCount == accessCount)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,appointmentId,clientId,clientEmail,token,createdAt,expiresAt,hasBeenUsed,lastAccessedAt,accessCount,status);

@override
String toString() {
  return 'MagicLinkToken(id: $id, businessId: $businessId, appointmentId: $appointmentId, clientId: $clientId, clientEmail: $clientEmail, token: $token, createdAt: $createdAt, expiresAt: $expiresAt, hasBeenUsed: $hasBeenUsed, lastAccessedAt: $lastAccessedAt, accessCount: $accessCount, status: $status)';
}


}

/// @nodoc
abstract mixin class _$MagicLinkTokenCopyWith<$Res> implements $MagicLinkTokenCopyWith<$Res> {
  factory _$MagicLinkTokenCopyWith(_MagicLinkToken value, $Res Function(_MagicLinkToken) _then) = __$MagicLinkTokenCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String appointmentId, String clientId, String clientEmail, String token,@TimestampConverter() DateTime createdAt,@TimestampConverter() DateTime expiresAt, bool hasBeenUsed,@NullableTimestampConverter() DateTime? lastAccessedAt, int accessCount, MagicLinkTokenStatus status
});




}
/// @nodoc
class __$MagicLinkTokenCopyWithImpl<$Res>
    implements _$MagicLinkTokenCopyWith<$Res> {
  __$MagicLinkTokenCopyWithImpl(this._self, this._then);

  final _MagicLinkToken _self;
  final $Res Function(_MagicLinkToken) _then;

/// Create a copy of MagicLinkToken
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? appointmentId = null,Object? clientId = null,Object? clientEmail = null,Object? token = null,Object? createdAt = null,Object? expiresAt = null,Object? hasBeenUsed = null,Object? lastAccessedAt = freezed,Object? accessCount = null,Object? status = null,}) {
  return _then(_MagicLinkToken(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,appointmentId: null == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String,clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,clientEmail: null == clientEmail ? _self.clientEmail : clientEmail // ignore: cast_nullable_to_non_nullable
as String,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,hasBeenUsed: null == hasBeenUsed ? _self.hasBeenUsed : hasBeenUsed // ignore: cast_nullable_to_non_nullable
as bool,lastAccessedAt: freezed == lastAccessedAt ? _self.lastAccessedAt : lastAccessedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,accessCount: null == accessCount ? _self.accessCount : accessCount // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MagicLinkTokenStatus,
  ));
}


}

// dart format on
