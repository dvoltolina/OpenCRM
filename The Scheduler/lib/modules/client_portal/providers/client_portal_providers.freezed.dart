// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'client_portal_providers.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ClientAuthState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClientAuthState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ClientAuthState()';
}


}

/// @nodoc
class $ClientAuthStateCopyWith<$Res>  {
$ClientAuthStateCopyWith(ClientAuthState _, $Res Function(ClientAuthState) __);
}


/// Adds pattern-matching-related methods to [ClientAuthState].
extension ClientAuthStatePatterns on ClientAuthState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Unauthenticated value)?  unauthenticated,TResult Function( _Guest value)?  guest,TResult Function( _SignedIn value)?  signedIn,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Unauthenticated() when unauthenticated != null:
return unauthenticated(_that);case _Guest() when guest != null:
return guest(_that);case _SignedIn() when signedIn != null:
return signedIn(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Unauthenticated value)  unauthenticated,required TResult Function( _Guest value)  guest,required TResult Function( _SignedIn value)  signedIn,}){
final _that = this;
switch (_that) {
case _Unauthenticated():
return unauthenticated(_that);case _Guest():
return guest(_that);case _SignedIn():
return signedIn(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Unauthenticated value)?  unauthenticated,TResult? Function( _Guest value)?  guest,TResult? Function( _SignedIn value)?  signedIn,}){
final _that = this;
switch (_that) {
case _Unauthenticated() when unauthenticated != null:
return unauthenticated(_that);case _Guest() when guest != null:
return guest(_that);case _SignedIn() when signedIn != null:
return signedIn(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  unauthenticated,TResult Function( GuestSession session)?  guest,TResult Function( User user)?  signedIn,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Unauthenticated() when unauthenticated != null:
return unauthenticated();case _Guest() when guest != null:
return guest(_that.session);case _SignedIn() when signedIn != null:
return signedIn(_that.user);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  unauthenticated,required TResult Function( GuestSession session)  guest,required TResult Function( User user)  signedIn,}) {final _that = this;
switch (_that) {
case _Unauthenticated():
return unauthenticated();case _Guest():
return guest(_that.session);case _SignedIn():
return signedIn(_that.user);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  unauthenticated,TResult? Function( GuestSession session)?  guest,TResult? Function( User user)?  signedIn,}) {final _that = this;
switch (_that) {
case _Unauthenticated() when unauthenticated != null:
return unauthenticated();case _Guest() when guest != null:
return guest(_that.session);case _SignedIn() when signedIn != null:
return signedIn(_that.user);case _:
  return null;

}
}

}

/// @nodoc


class _Unauthenticated implements ClientAuthState {
  const _Unauthenticated();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Unauthenticated);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ClientAuthState.unauthenticated()';
}


}




/// @nodoc


class _Guest implements ClientAuthState {
  const _Guest(this.session);
  

 final  GuestSession session;

/// Create a copy of ClientAuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuestCopyWith<_Guest> get copyWith => __$GuestCopyWithImpl<_Guest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Guest&&(identical(other.session, session) || other.session == session));
}


@override
int get hashCode => Object.hash(runtimeType,session);

@override
String toString() {
  return 'ClientAuthState.guest(session: $session)';
}


}

/// @nodoc
abstract mixin class _$GuestCopyWith<$Res> implements $ClientAuthStateCopyWith<$Res> {
  factory _$GuestCopyWith(_Guest value, $Res Function(_Guest) _then) = __$GuestCopyWithImpl;
@useResult
$Res call({
 GuestSession session
});


$GuestSessionCopyWith<$Res> get session;

}
/// @nodoc
class __$GuestCopyWithImpl<$Res>
    implements _$GuestCopyWith<$Res> {
  __$GuestCopyWithImpl(this._self, this._then);

  final _Guest _self;
  final $Res Function(_Guest) _then;

/// Create a copy of ClientAuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? session = null,}) {
  return _then(_Guest(
null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as GuestSession,
  ));
}

/// Create a copy of ClientAuthState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GuestSessionCopyWith<$Res> get session {
  
  return $GuestSessionCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}

/// @nodoc


class _SignedIn implements ClientAuthState {
  const _SignedIn(this.user);
  

 final  User user;

/// Create a copy of ClientAuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SignedInCopyWith<_SignedIn> get copyWith => __$SignedInCopyWithImpl<_SignedIn>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SignedIn&&(identical(other.user, user) || other.user == user));
}


@override
int get hashCode => Object.hash(runtimeType,user);

@override
String toString() {
  return 'ClientAuthState.signedIn(user: $user)';
}


}

/// @nodoc
abstract mixin class _$SignedInCopyWith<$Res> implements $ClientAuthStateCopyWith<$Res> {
  factory _$SignedInCopyWith(_SignedIn value, $Res Function(_SignedIn) _then) = __$SignedInCopyWithImpl;
@useResult
$Res call({
 User user
});




}
/// @nodoc
class __$SignedInCopyWithImpl<$Res>
    implements _$SignedInCopyWith<$Res> {
  __$SignedInCopyWithImpl(this._self, this._then);

  final _SignedIn _self;
  final $Res Function(_SignedIn) _then;

/// Create a copy of ClientAuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? user = null,}) {
  return _then(_SignedIn(
null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as User,
  ));
}


}

// dart format on
