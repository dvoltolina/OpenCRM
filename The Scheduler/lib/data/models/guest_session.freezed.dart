// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'guest_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GuestSession {

 String get id; String get businessId; String get fullName; String get email; String get phone; GuestVerificationMethod get verificationMethod; bool get isVerified;@_TimestampConverter() DateTime get expiresAt;@_TimestampConverter() DateTime? get verifiedAt;@_TimestampConverter() DateTime? get createdAt;
/// Create a copy of GuestSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuestSessionCopyWith<GuestSession> get copyWith => _$GuestSessionCopyWithImpl<GuestSession>(this as GuestSession, _$identity);

  /// Serializes this GuestSession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuestSession&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.verificationMethod, verificationMethod) || other.verificationMethod == verificationMethod)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.verifiedAt, verifiedAt) || other.verifiedAt == verifiedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,fullName,email,phone,verificationMethod,isVerified,expiresAt,verifiedAt,createdAt);

@override
String toString() {
  return 'GuestSession(id: $id, businessId: $businessId, fullName: $fullName, email: $email, phone: $phone, verificationMethod: $verificationMethod, isVerified: $isVerified, expiresAt: $expiresAt, verifiedAt: $verifiedAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $GuestSessionCopyWith<$Res>  {
  factory $GuestSessionCopyWith(GuestSession value, $Res Function(GuestSession) _then) = _$GuestSessionCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String fullName, String email, String phone, GuestVerificationMethod verificationMethod, bool isVerified,@_TimestampConverter() DateTime expiresAt,@_TimestampConverter() DateTime? verifiedAt,@_TimestampConverter() DateTime? createdAt
});




}
/// @nodoc
class _$GuestSessionCopyWithImpl<$Res>
    implements $GuestSessionCopyWith<$Res> {
  _$GuestSessionCopyWithImpl(this._self, this._then);

  final GuestSession _self;
  final $Res Function(GuestSession) _then;

/// Create a copy of GuestSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? fullName = null,Object? email = null,Object? phone = null,Object? verificationMethod = null,Object? isVerified = null,Object? expiresAt = null,Object? verifiedAt = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,verificationMethod: null == verificationMethod ? _self.verificationMethod : verificationMethod // ignore: cast_nullable_to_non_nullable
as GuestVerificationMethod,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,verifiedAt: freezed == verifiedAt ? _self.verifiedAt : verifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [GuestSession].
extension GuestSessionPatterns on GuestSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GuestSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GuestSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GuestSession value)  $default,){
final _that = this;
switch (_that) {
case _GuestSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GuestSession value)?  $default,){
final _that = this;
switch (_that) {
case _GuestSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String fullName,  String email,  String phone,  GuestVerificationMethod verificationMethod,  bool isVerified, @_TimestampConverter()  DateTime expiresAt, @_TimestampConverter()  DateTime? verifiedAt, @_TimestampConverter()  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GuestSession() when $default != null:
return $default(_that.id,_that.businessId,_that.fullName,_that.email,_that.phone,_that.verificationMethod,_that.isVerified,_that.expiresAt,_that.verifiedAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String fullName,  String email,  String phone,  GuestVerificationMethod verificationMethod,  bool isVerified, @_TimestampConverter()  DateTime expiresAt, @_TimestampConverter()  DateTime? verifiedAt, @_TimestampConverter()  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _GuestSession():
return $default(_that.id,_that.businessId,_that.fullName,_that.email,_that.phone,_that.verificationMethod,_that.isVerified,_that.expiresAt,_that.verifiedAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String fullName,  String email,  String phone,  GuestVerificationMethod verificationMethod,  bool isVerified, @_TimestampConverter()  DateTime expiresAt, @_TimestampConverter()  DateTime? verifiedAt, @_TimestampConverter()  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _GuestSession() when $default != null:
return $default(_that.id,_that.businessId,_that.fullName,_that.email,_that.phone,_that.verificationMethod,_that.isVerified,_that.expiresAt,_that.verifiedAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GuestSession extends GuestSession {
  const _GuestSession({required this.id, required this.businessId, required this.fullName, required this.email, required this.phone, required this.verificationMethod, required this.isVerified, @_TimestampConverter() required this.expiresAt, @_TimestampConverter() this.verifiedAt, @_TimestampConverter() this.createdAt}): super._();
  factory _GuestSession.fromJson(Map<String, dynamic> json) => _$GuestSessionFromJson(json);

@override final  String id;
@override final  String businessId;
@override final  String fullName;
@override final  String email;
@override final  String phone;
@override final  GuestVerificationMethod verificationMethod;
@override final  bool isVerified;
@override@_TimestampConverter() final  DateTime expiresAt;
@override@_TimestampConverter() final  DateTime? verifiedAt;
@override@_TimestampConverter() final  DateTime? createdAt;

/// Create a copy of GuestSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuestSessionCopyWith<_GuestSession> get copyWith => __$GuestSessionCopyWithImpl<_GuestSession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GuestSessionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuestSession&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.verificationMethod, verificationMethod) || other.verificationMethod == verificationMethod)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.verifiedAt, verifiedAt) || other.verifiedAt == verifiedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,fullName,email,phone,verificationMethod,isVerified,expiresAt,verifiedAt,createdAt);

@override
String toString() {
  return 'GuestSession(id: $id, businessId: $businessId, fullName: $fullName, email: $email, phone: $phone, verificationMethod: $verificationMethod, isVerified: $isVerified, expiresAt: $expiresAt, verifiedAt: $verifiedAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$GuestSessionCopyWith<$Res> implements $GuestSessionCopyWith<$Res> {
  factory _$GuestSessionCopyWith(_GuestSession value, $Res Function(_GuestSession) _then) = __$GuestSessionCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String fullName, String email, String phone, GuestVerificationMethod verificationMethod, bool isVerified,@_TimestampConverter() DateTime expiresAt,@_TimestampConverter() DateTime? verifiedAt,@_TimestampConverter() DateTime? createdAt
});




}
/// @nodoc
class __$GuestSessionCopyWithImpl<$Res>
    implements _$GuestSessionCopyWith<$Res> {
  __$GuestSessionCopyWithImpl(this._self, this._then);

  final _GuestSession _self;
  final $Res Function(_GuestSession) _then;

/// Create a copy of GuestSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? fullName = null,Object? email = null,Object? phone = null,Object? verificationMethod = null,Object? isVerified = null,Object? expiresAt = null,Object? verifiedAt = freezed,Object? createdAt = freezed,}) {
  return _then(_GuestSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,verificationMethod: null == verificationMethod ? _self.verificationMethod : verificationMethod // ignore: cast_nullable_to_non_nullable
as GuestVerificationMethod,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,verifiedAt: freezed == verifiedAt ? _self.verifiedAt : verifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$VerificationResult {

 String get sessionId;@_TimestampConverter() DateTime get expiresAt; int get attemptsRemaining;
/// Create a copy of VerificationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerificationResultCopyWith<VerificationResult> get copyWith => _$VerificationResultCopyWithImpl<VerificationResult>(this as VerificationResult, _$identity);

  /// Serializes this VerificationResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerificationResult&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.attemptsRemaining, attemptsRemaining) || other.attemptsRemaining == attemptsRemaining));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,expiresAt,attemptsRemaining);

@override
String toString() {
  return 'VerificationResult(sessionId: $sessionId, expiresAt: $expiresAt, attemptsRemaining: $attemptsRemaining)';
}


}

/// @nodoc
abstract mixin class $VerificationResultCopyWith<$Res>  {
  factory $VerificationResultCopyWith(VerificationResult value, $Res Function(VerificationResult) _then) = _$VerificationResultCopyWithImpl;
@useResult
$Res call({
 String sessionId,@_TimestampConverter() DateTime expiresAt, int attemptsRemaining
});




}
/// @nodoc
class _$VerificationResultCopyWithImpl<$Res>
    implements $VerificationResultCopyWith<$Res> {
  _$VerificationResultCopyWithImpl(this._self, this._then);

  final VerificationResult _self;
  final $Res Function(VerificationResult) _then;

/// Create a copy of VerificationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionId = null,Object? expiresAt = null,Object? attemptsRemaining = null,}) {
  return _then(_self.copyWith(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,attemptsRemaining: null == attemptsRemaining ? _self.attemptsRemaining : attemptsRemaining // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [VerificationResult].
extension VerificationResultPatterns on VerificationResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VerificationResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VerificationResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VerificationResult value)  $default,){
final _that = this;
switch (_that) {
case _VerificationResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VerificationResult value)?  $default,){
final _that = this;
switch (_that) {
case _VerificationResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sessionId, @_TimestampConverter()  DateTime expiresAt,  int attemptsRemaining)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VerificationResult() when $default != null:
return $default(_that.sessionId,_that.expiresAt,_that.attemptsRemaining);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sessionId, @_TimestampConverter()  DateTime expiresAt,  int attemptsRemaining)  $default,) {final _that = this;
switch (_that) {
case _VerificationResult():
return $default(_that.sessionId,_that.expiresAt,_that.attemptsRemaining);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sessionId, @_TimestampConverter()  DateTime expiresAt,  int attemptsRemaining)?  $default,) {final _that = this;
switch (_that) {
case _VerificationResult() when $default != null:
return $default(_that.sessionId,_that.expiresAt,_that.attemptsRemaining);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VerificationResult implements VerificationResult {
  const _VerificationResult({required this.sessionId, @_TimestampConverter() required this.expiresAt, required this.attemptsRemaining});
  factory _VerificationResult.fromJson(Map<String, dynamic> json) => _$VerificationResultFromJson(json);

@override final  String sessionId;
@override@_TimestampConverter() final  DateTime expiresAt;
@override final  int attemptsRemaining;

/// Create a copy of VerificationResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VerificationResultCopyWith<_VerificationResult> get copyWith => __$VerificationResultCopyWithImpl<_VerificationResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VerificationResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VerificationResult&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.attemptsRemaining, attemptsRemaining) || other.attemptsRemaining == attemptsRemaining));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,expiresAt,attemptsRemaining);

@override
String toString() {
  return 'VerificationResult(sessionId: $sessionId, expiresAt: $expiresAt, attemptsRemaining: $attemptsRemaining)';
}


}

/// @nodoc
abstract mixin class _$VerificationResultCopyWith<$Res> implements $VerificationResultCopyWith<$Res> {
  factory _$VerificationResultCopyWith(_VerificationResult value, $Res Function(_VerificationResult) _then) = __$VerificationResultCopyWithImpl;
@override @useResult
$Res call({
 String sessionId,@_TimestampConverter() DateTime expiresAt, int attemptsRemaining
});




}
/// @nodoc
class __$VerificationResultCopyWithImpl<$Res>
    implements _$VerificationResultCopyWith<$Res> {
  __$VerificationResultCopyWithImpl(this._self, this._then);

  final _VerificationResult _self;
  final $Res Function(_VerificationResult) _then;

/// Create a copy of VerificationResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionId = null,Object? expiresAt = null,Object? attemptsRemaining = null,}) {
  return _then(_VerificationResult(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,attemptsRemaining: null == attemptsRemaining ? _self.attemptsRemaining : attemptsRemaining // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
