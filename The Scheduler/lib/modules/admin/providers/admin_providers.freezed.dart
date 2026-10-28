// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'admin_providers.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TeamMemberStatus {

 StaffMember get member; ClockStatus get clockStatus;
/// Create a copy of TeamMemberStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TeamMemberStatusCopyWith<TeamMemberStatus> get copyWith => _$TeamMemberStatusCopyWithImpl<TeamMemberStatus>(this as TeamMemberStatus, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TeamMemberStatus&&(identical(other.member, member) || other.member == member)&&(identical(other.clockStatus, clockStatus) || other.clockStatus == clockStatus));
}


@override
int get hashCode => Object.hash(runtimeType,member,clockStatus);

@override
String toString() {
  return 'TeamMemberStatus(member: $member, clockStatus: $clockStatus)';
}


}

/// @nodoc
abstract mixin class $TeamMemberStatusCopyWith<$Res>  {
  factory $TeamMemberStatusCopyWith(TeamMemberStatus value, $Res Function(TeamMemberStatus) _then) = _$TeamMemberStatusCopyWithImpl;
@useResult
$Res call({
 StaffMember member, ClockStatus clockStatus
});




}
/// @nodoc
class _$TeamMemberStatusCopyWithImpl<$Res>
    implements $TeamMemberStatusCopyWith<$Res> {
  _$TeamMemberStatusCopyWithImpl(this._self, this._then);

  final TeamMemberStatus _self;
  final $Res Function(TeamMemberStatus) _then;

/// Create a copy of TeamMemberStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? member = null,Object? clockStatus = null,}) {
  return _then(_self.copyWith(
member: null == member ? _self.member : member // ignore: cast_nullable_to_non_nullable
as StaffMember,clockStatus: null == clockStatus ? _self.clockStatus : clockStatus // ignore: cast_nullable_to_non_nullable
as ClockStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [TeamMemberStatus].
extension TeamMemberStatusPatterns on TeamMemberStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TeamMemberStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TeamMemberStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TeamMemberStatus value)  $default,){
final _that = this;
switch (_that) {
case _TeamMemberStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TeamMemberStatus value)?  $default,){
final _that = this;
switch (_that) {
case _TeamMemberStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( StaffMember member,  ClockStatus clockStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TeamMemberStatus() when $default != null:
return $default(_that.member,_that.clockStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( StaffMember member,  ClockStatus clockStatus)  $default,) {final _that = this;
switch (_that) {
case _TeamMemberStatus():
return $default(_that.member,_that.clockStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( StaffMember member,  ClockStatus clockStatus)?  $default,) {final _that = this;
switch (_that) {
case _TeamMemberStatus() when $default != null:
return $default(_that.member,_that.clockStatus);case _:
  return null;

}
}

}

/// @nodoc


class _TeamMemberStatus implements TeamMemberStatus {
  const _TeamMemberStatus({required this.member, required this.clockStatus});
  

@override final  StaffMember member;
@override final  ClockStatus clockStatus;

/// Create a copy of TeamMemberStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TeamMemberStatusCopyWith<_TeamMemberStatus> get copyWith => __$TeamMemberStatusCopyWithImpl<_TeamMemberStatus>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TeamMemberStatus&&(identical(other.member, member) || other.member == member)&&(identical(other.clockStatus, clockStatus) || other.clockStatus == clockStatus));
}


@override
int get hashCode => Object.hash(runtimeType,member,clockStatus);

@override
String toString() {
  return 'TeamMemberStatus(member: $member, clockStatus: $clockStatus)';
}


}

/// @nodoc
abstract mixin class _$TeamMemberStatusCopyWith<$Res> implements $TeamMemberStatusCopyWith<$Res> {
  factory _$TeamMemberStatusCopyWith(_TeamMemberStatus value, $Res Function(_TeamMemberStatus) _then) = __$TeamMemberStatusCopyWithImpl;
@override @useResult
$Res call({
 StaffMember member, ClockStatus clockStatus
});




}
/// @nodoc
class __$TeamMemberStatusCopyWithImpl<$Res>
    implements _$TeamMemberStatusCopyWith<$Res> {
  __$TeamMemberStatusCopyWithImpl(this._self, this._then);

  final _TeamMemberStatus _self;
  final $Res Function(_TeamMemberStatus) _then;

/// Create a copy of TeamMemberStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? member = null,Object? clockStatus = null,}) {
  return _then(_TeamMemberStatus(
member: null == member ? _self.member : member // ignore: cast_nullable_to_non_nullable
as StaffMember,clockStatus: null == clockStatus ? _self.clockStatus : clockStatus // ignore: cast_nullable_to_non_nullable
as ClockStatus,
  ));
}


}

// dart format on
