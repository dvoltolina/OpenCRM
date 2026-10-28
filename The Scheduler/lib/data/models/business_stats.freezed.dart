// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'business_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BusinessStats {

/// Number of appointments scheduled for today
 int get appointmentsToday;/// Change in appointments compared to same day last week
 int get appointmentsChange;/// Revenue earned today (in cents)
 int get revenueTodayCents;/// Percentage change in revenue compared to same day last week
 double get revenueChangePercent;/// Number of staff members currently on duty (clocked in)
 int get staffOnDuty;/// Total number of active staff members
 int get staffTotal;/// Number of completed appointments today
 int get appointmentsCompleted;/// Number of cancelled appointments today
 int get appointmentsCancelled;/// Number of no-show appointments today
 int get appointmentsNoShow;
/// Create a copy of BusinessStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BusinessStatsCopyWith<BusinessStats> get copyWith => _$BusinessStatsCopyWithImpl<BusinessStats>(this as BusinessStats, _$identity);

  /// Serializes this BusinessStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BusinessStats&&(identical(other.appointmentsToday, appointmentsToday) || other.appointmentsToday == appointmentsToday)&&(identical(other.appointmentsChange, appointmentsChange) || other.appointmentsChange == appointmentsChange)&&(identical(other.revenueTodayCents, revenueTodayCents) || other.revenueTodayCents == revenueTodayCents)&&(identical(other.revenueChangePercent, revenueChangePercent) || other.revenueChangePercent == revenueChangePercent)&&(identical(other.staffOnDuty, staffOnDuty) || other.staffOnDuty == staffOnDuty)&&(identical(other.staffTotal, staffTotal) || other.staffTotal == staffTotal)&&(identical(other.appointmentsCompleted, appointmentsCompleted) || other.appointmentsCompleted == appointmentsCompleted)&&(identical(other.appointmentsCancelled, appointmentsCancelled) || other.appointmentsCancelled == appointmentsCancelled)&&(identical(other.appointmentsNoShow, appointmentsNoShow) || other.appointmentsNoShow == appointmentsNoShow));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appointmentsToday,appointmentsChange,revenueTodayCents,revenueChangePercent,staffOnDuty,staffTotal,appointmentsCompleted,appointmentsCancelled,appointmentsNoShow);

@override
String toString() {
  return 'BusinessStats(appointmentsToday: $appointmentsToday, appointmentsChange: $appointmentsChange, revenueTodayCents: $revenueTodayCents, revenueChangePercent: $revenueChangePercent, staffOnDuty: $staffOnDuty, staffTotal: $staffTotal, appointmentsCompleted: $appointmentsCompleted, appointmentsCancelled: $appointmentsCancelled, appointmentsNoShow: $appointmentsNoShow)';
}


}

/// @nodoc
abstract mixin class $BusinessStatsCopyWith<$Res>  {
  factory $BusinessStatsCopyWith(BusinessStats value, $Res Function(BusinessStats) _then) = _$BusinessStatsCopyWithImpl;
@useResult
$Res call({
 int appointmentsToday, int appointmentsChange, int revenueTodayCents, double revenueChangePercent, int staffOnDuty, int staffTotal, int appointmentsCompleted, int appointmentsCancelled, int appointmentsNoShow
});




}
/// @nodoc
class _$BusinessStatsCopyWithImpl<$Res>
    implements $BusinessStatsCopyWith<$Res> {
  _$BusinessStatsCopyWithImpl(this._self, this._then);

  final BusinessStats _self;
  final $Res Function(BusinessStats) _then;

/// Create a copy of BusinessStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? appointmentsToday = null,Object? appointmentsChange = null,Object? revenueTodayCents = null,Object? revenueChangePercent = null,Object? staffOnDuty = null,Object? staffTotal = null,Object? appointmentsCompleted = null,Object? appointmentsCancelled = null,Object? appointmentsNoShow = null,}) {
  return _then(_self.copyWith(
appointmentsToday: null == appointmentsToday ? _self.appointmentsToday : appointmentsToday // ignore: cast_nullable_to_non_nullable
as int,appointmentsChange: null == appointmentsChange ? _self.appointmentsChange : appointmentsChange // ignore: cast_nullable_to_non_nullable
as int,revenueTodayCents: null == revenueTodayCents ? _self.revenueTodayCents : revenueTodayCents // ignore: cast_nullable_to_non_nullable
as int,revenueChangePercent: null == revenueChangePercent ? _self.revenueChangePercent : revenueChangePercent // ignore: cast_nullable_to_non_nullable
as double,staffOnDuty: null == staffOnDuty ? _self.staffOnDuty : staffOnDuty // ignore: cast_nullable_to_non_nullable
as int,staffTotal: null == staffTotal ? _self.staffTotal : staffTotal // ignore: cast_nullable_to_non_nullable
as int,appointmentsCompleted: null == appointmentsCompleted ? _self.appointmentsCompleted : appointmentsCompleted // ignore: cast_nullable_to_non_nullable
as int,appointmentsCancelled: null == appointmentsCancelled ? _self.appointmentsCancelled : appointmentsCancelled // ignore: cast_nullable_to_non_nullable
as int,appointmentsNoShow: null == appointmentsNoShow ? _self.appointmentsNoShow : appointmentsNoShow // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BusinessStats].
extension BusinessStatsPatterns on BusinessStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BusinessStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BusinessStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BusinessStats value)  $default,){
final _that = this;
switch (_that) {
case _BusinessStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BusinessStats value)?  $default,){
final _that = this;
switch (_that) {
case _BusinessStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int appointmentsToday,  int appointmentsChange,  int revenueTodayCents,  double revenueChangePercent,  int staffOnDuty,  int staffTotal,  int appointmentsCompleted,  int appointmentsCancelled,  int appointmentsNoShow)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BusinessStats() when $default != null:
return $default(_that.appointmentsToday,_that.appointmentsChange,_that.revenueTodayCents,_that.revenueChangePercent,_that.staffOnDuty,_that.staffTotal,_that.appointmentsCompleted,_that.appointmentsCancelled,_that.appointmentsNoShow);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int appointmentsToday,  int appointmentsChange,  int revenueTodayCents,  double revenueChangePercent,  int staffOnDuty,  int staffTotal,  int appointmentsCompleted,  int appointmentsCancelled,  int appointmentsNoShow)  $default,) {final _that = this;
switch (_that) {
case _BusinessStats():
return $default(_that.appointmentsToday,_that.appointmentsChange,_that.revenueTodayCents,_that.revenueChangePercent,_that.staffOnDuty,_that.staffTotal,_that.appointmentsCompleted,_that.appointmentsCancelled,_that.appointmentsNoShow);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int appointmentsToday,  int appointmentsChange,  int revenueTodayCents,  double revenueChangePercent,  int staffOnDuty,  int staffTotal,  int appointmentsCompleted,  int appointmentsCancelled,  int appointmentsNoShow)?  $default,) {final _that = this;
switch (_that) {
case _BusinessStats() when $default != null:
return $default(_that.appointmentsToday,_that.appointmentsChange,_that.revenueTodayCents,_that.revenueChangePercent,_that.staffOnDuty,_that.staffTotal,_that.appointmentsCompleted,_that.appointmentsCancelled,_that.appointmentsNoShow);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BusinessStats extends BusinessStats {
  const _BusinessStats({required this.appointmentsToday, required this.appointmentsChange, required this.revenueTodayCents, required this.revenueChangePercent, required this.staffOnDuty, required this.staffTotal, this.appointmentsCompleted = 0, this.appointmentsCancelled = 0, this.appointmentsNoShow = 0}): super._();
  factory _BusinessStats.fromJson(Map<String, dynamic> json) => _$BusinessStatsFromJson(json);

/// Number of appointments scheduled for today
@override final  int appointmentsToday;
/// Change in appointments compared to same day last week
@override final  int appointmentsChange;
/// Revenue earned today (in cents)
@override final  int revenueTodayCents;
/// Percentage change in revenue compared to same day last week
@override final  double revenueChangePercent;
/// Number of staff members currently on duty (clocked in)
@override final  int staffOnDuty;
/// Total number of active staff members
@override final  int staffTotal;
/// Number of completed appointments today
@override@JsonKey() final  int appointmentsCompleted;
/// Number of cancelled appointments today
@override@JsonKey() final  int appointmentsCancelled;
/// Number of no-show appointments today
@override@JsonKey() final  int appointmentsNoShow;

/// Create a copy of BusinessStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BusinessStatsCopyWith<_BusinessStats> get copyWith => __$BusinessStatsCopyWithImpl<_BusinessStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BusinessStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BusinessStats&&(identical(other.appointmentsToday, appointmentsToday) || other.appointmentsToday == appointmentsToday)&&(identical(other.appointmentsChange, appointmentsChange) || other.appointmentsChange == appointmentsChange)&&(identical(other.revenueTodayCents, revenueTodayCents) || other.revenueTodayCents == revenueTodayCents)&&(identical(other.revenueChangePercent, revenueChangePercent) || other.revenueChangePercent == revenueChangePercent)&&(identical(other.staffOnDuty, staffOnDuty) || other.staffOnDuty == staffOnDuty)&&(identical(other.staffTotal, staffTotal) || other.staffTotal == staffTotal)&&(identical(other.appointmentsCompleted, appointmentsCompleted) || other.appointmentsCompleted == appointmentsCompleted)&&(identical(other.appointmentsCancelled, appointmentsCancelled) || other.appointmentsCancelled == appointmentsCancelled)&&(identical(other.appointmentsNoShow, appointmentsNoShow) || other.appointmentsNoShow == appointmentsNoShow));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appointmentsToday,appointmentsChange,revenueTodayCents,revenueChangePercent,staffOnDuty,staffTotal,appointmentsCompleted,appointmentsCancelled,appointmentsNoShow);

@override
String toString() {
  return 'BusinessStats(appointmentsToday: $appointmentsToday, appointmentsChange: $appointmentsChange, revenueTodayCents: $revenueTodayCents, revenueChangePercent: $revenueChangePercent, staffOnDuty: $staffOnDuty, staffTotal: $staffTotal, appointmentsCompleted: $appointmentsCompleted, appointmentsCancelled: $appointmentsCancelled, appointmentsNoShow: $appointmentsNoShow)';
}


}

/// @nodoc
abstract mixin class _$BusinessStatsCopyWith<$Res> implements $BusinessStatsCopyWith<$Res> {
  factory _$BusinessStatsCopyWith(_BusinessStats value, $Res Function(_BusinessStats) _then) = __$BusinessStatsCopyWithImpl;
@override @useResult
$Res call({
 int appointmentsToday, int appointmentsChange, int revenueTodayCents, double revenueChangePercent, int staffOnDuty, int staffTotal, int appointmentsCompleted, int appointmentsCancelled, int appointmentsNoShow
});




}
/// @nodoc
class __$BusinessStatsCopyWithImpl<$Res>
    implements _$BusinessStatsCopyWith<$Res> {
  __$BusinessStatsCopyWithImpl(this._self, this._then);

  final _BusinessStats _self;
  final $Res Function(_BusinessStats) _then;

/// Create a copy of BusinessStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? appointmentsToday = null,Object? appointmentsChange = null,Object? revenueTodayCents = null,Object? revenueChangePercent = null,Object? staffOnDuty = null,Object? staffTotal = null,Object? appointmentsCompleted = null,Object? appointmentsCancelled = null,Object? appointmentsNoShow = null,}) {
  return _then(_BusinessStats(
appointmentsToday: null == appointmentsToday ? _self.appointmentsToday : appointmentsToday // ignore: cast_nullable_to_non_nullable
as int,appointmentsChange: null == appointmentsChange ? _self.appointmentsChange : appointmentsChange // ignore: cast_nullable_to_non_nullable
as int,revenueTodayCents: null == revenueTodayCents ? _self.revenueTodayCents : revenueTodayCents // ignore: cast_nullable_to_non_nullable
as int,revenueChangePercent: null == revenueChangePercent ? _self.revenueChangePercent : revenueChangePercent // ignore: cast_nullable_to_non_nullable
as double,staffOnDuty: null == staffOnDuty ? _self.staffOnDuty : staffOnDuty // ignore: cast_nullable_to_non_nullable
as int,staffTotal: null == staffTotal ? _self.staffTotal : staffTotal // ignore: cast_nullable_to_non_nullable
as int,appointmentsCompleted: null == appointmentsCompleted ? _self.appointmentsCompleted : appointmentsCompleted // ignore: cast_nullable_to_non_nullable
as int,appointmentsCancelled: null == appointmentsCancelled ? _self.appointmentsCancelled : appointmentsCancelled // ignore: cast_nullable_to_non_nullable
as int,appointmentsNoShow: null == appointmentsNoShow ? _self.appointmentsNoShow : appointmentsNoShow // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
