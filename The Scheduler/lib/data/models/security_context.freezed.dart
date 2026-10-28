// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'security_context.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SecurityContext {

 String get userId;// Firebase Auth UID
 String get businessId;// Current business context
 UserRole get role; List<String> get roles; String? get providerId;// Set if user is a staff member
 String? get clientId;// Set if user is a client
 String? get userFullName;// Optional cached user display name
 String? get authToken;
/// Create a copy of SecurityContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SecurityContextCopyWith<SecurityContext> get copyWith => _$SecurityContextCopyWithImpl<SecurityContext>(this as SecurityContext, _$identity);

  /// Serializes this SecurityContext to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SecurityContext&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.role, role) || other.role == role)&&const DeepCollectionEquality().equals(other.roles, roles)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.userFullName, userFullName) || other.userFullName == userFullName)&&(identical(other.authToken, authToken) || other.authToken == authToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,businessId,role,const DeepCollectionEquality().hash(roles),providerId,clientId,userFullName,authToken);

@override
String toString() {
  return 'SecurityContext(userId: $userId, businessId: $businessId, role: $role, roles: $roles, providerId: $providerId, clientId: $clientId, userFullName: $userFullName, authToken: $authToken)';
}


}

/// @nodoc
abstract mixin class $SecurityContextCopyWith<$Res>  {
  factory $SecurityContextCopyWith(SecurityContext value, $Res Function(SecurityContext) _then) = _$SecurityContextCopyWithImpl;
@useResult
$Res call({
 String userId, String businessId, UserRole role, List<String> roles, String? providerId, String? clientId, String? userFullName, String? authToken
});




}
/// @nodoc
class _$SecurityContextCopyWithImpl<$Res>
    implements $SecurityContextCopyWith<$Res> {
  _$SecurityContextCopyWithImpl(this._self, this._then);

  final SecurityContext _self;
  final $Res Function(SecurityContext) _then;

/// Create a copy of SecurityContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? businessId = null,Object? role = null,Object? roles = null,Object? providerId = freezed,Object? clientId = freezed,Object? userFullName = freezed,Object? authToken = freezed,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,roles: null == roles ? _self.roles : roles // ignore: cast_nullable_to_non_nullable
as List<String>,providerId: freezed == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String?,clientId: freezed == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String?,userFullName: freezed == userFullName ? _self.userFullName : userFullName // ignore: cast_nullable_to_non_nullable
as String?,authToken: freezed == authToken ? _self.authToken : authToken // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SecurityContext].
extension SecurityContextPatterns on SecurityContext {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SecurityContext value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SecurityContext() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SecurityContext value)  $default,){
final _that = this;
switch (_that) {
case _SecurityContext():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SecurityContext value)?  $default,){
final _that = this;
switch (_that) {
case _SecurityContext() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String businessId,  UserRole role,  List<String> roles,  String? providerId,  String? clientId,  String? userFullName,  String? authToken)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SecurityContext() when $default != null:
return $default(_that.userId,_that.businessId,_that.role,_that.roles,_that.providerId,_that.clientId,_that.userFullName,_that.authToken);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String businessId,  UserRole role,  List<String> roles,  String? providerId,  String? clientId,  String? userFullName,  String? authToken)  $default,) {final _that = this;
switch (_that) {
case _SecurityContext():
return $default(_that.userId,_that.businessId,_that.role,_that.roles,_that.providerId,_that.clientId,_that.userFullName,_that.authToken);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String businessId,  UserRole role,  List<String> roles,  String? providerId,  String? clientId,  String? userFullName,  String? authToken)?  $default,) {final _that = this;
switch (_that) {
case _SecurityContext() when $default != null:
return $default(_that.userId,_that.businessId,_that.role,_that.roles,_that.providerId,_that.clientId,_that.userFullName,_that.authToken);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SecurityContext extends SecurityContext {
  const _SecurityContext({required this.userId, required this.businessId, this.role = UserRole.client, final  List<String> roles = const <String>[], this.providerId, this.clientId, this.userFullName, this.authToken}): _roles = roles,super._();
  factory _SecurityContext.fromJson(Map<String, dynamic> json) => _$SecurityContextFromJson(json);

@override final  String userId;
// Firebase Auth UID
@override final  String businessId;
// Current business context
@override@JsonKey() final  UserRole role;
 final  List<String> _roles;
@override@JsonKey() List<String> get roles {
  if (_roles is EqualUnmodifiableListView) return _roles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_roles);
}

@override final  String? providerId;
// Set if user is a staff member
@override final  String? clientId;
// Set if user is a client
@override final  String? userFullName;
// Optional cached user display name
@override final  String? authToken;

/// Create a copy of SecurityContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SecurityContextCopyWith<_SecurityContext> get copyWith => __$SecurityContextCopyWithImpl<_SecurityContext>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SecurityContextToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SecurityContext&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.role, role) || other.role == role)&&const DeepCollectionEquality().equals(other._roles, _roles)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.userFullName, userFullName) || other.userFullName == userFullName)&&(identical(other.authToken, authToken) || other.authToken == authToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,businessId,role,const DeepCollectionEquality().hash(_roles),providerId,clientId,userFullName,authToken);

@override
String toString() {
  return 'SecurityContext(userId: $userId, businessId: $businessId, role: $role, roles: $roles, providerId: $providerId, clientId: $clientId, userFullName: $userFullName, authToken: $authToken)';
}


}

/// @nodoc
abstract mixin class _$SecurityContextCopyWith<$Res> implements $SecurityContextCopyWith<$Res> {
  factory _$SecurityContextCopyWith(_SecurityContext value, $Res Function(_SecurityContext) _then) = __$SecurityContextCopyWithImpl;
@override @useResult
$Res call({
 String userId, String businessId, UserRole role, List<String> roles, String? providerId, String? clientId, String? userFullName, String? authToken
});




}
/// @nodoc
class __$SecurityContextCopyWithImpl<$Res>
    implements _$SecurityContextCopyWith<$Res> {
  __$SecurityContextCopyWithImpl(this._self, this._then);

  final _SecurityContext _self;
  final $Res Function(_SecurityContext) _then;

/// Create a copy of SecurityContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? businessId = null,Object? role = null,Object? roles = null,Object? providerId = freezed,Object? clientId = freezed,Object? userFullName = freezed,Object? authToken = freezed,}) {
  return _then(_SecurityContext(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,roles: null == roles ? _self._roles : roles // ignore: cast_nullable_to_non_nullable
as List<String>,providerId: freezed == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String?,clientId: freezed == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String?,userFullName: freezed == userFullName ? _self.userFullName : userFullName // ignore: cast_nullable_to_non_nullable
as String?,authToken: freezed == authToken ? _self.authToken : authToken // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
