// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'timesheet_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TimesheetSummary {

 String get staffId; String get staffName; String? get staffEmail; String? get staffAvatarUrl;@TimestampConverter() DateTime get periodStart;@TimestampConverter() DateTime get periodEnd;/// Total minutes worked across all entries
 int get totalWorkedMinutes;/// Total break minutes across all entries
 int get totalBreakMinutes;/// Number of shifts (clock-in/clock-out cycles) in period
 int get totalShifts;/// Regular hours (up to 8 hrs/day or 40 hrs/week)
 int get regularMinutes;/// Overtime hours (beyond 8 hrs/day or 40 hrs/week)
 int get overtimeMinutes;/// Staff hourly rate in cents (if available)
 int? get hourlyRateCents;/// Estimated pay based on hourly rate (regular + overtime)
 double get estimatedPayAmount;/// All time entries in this period
 List<TimeEntry> get entries;/// Current approval status
 TimesheetStatus get status;
/// Create a copy of TimesheetSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimesheetSummaryCopyWith<TimesheetSummary> get copyWith => _$TimesheetSummaryCopyWithImpl<TimesheetSummary>(this as TimesheetSummary, _$identity);

  /// Serializes this TimesheetSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimesheetSummary&&(identical(other.staffId, staffId) || other.staffId == staffId)&&(identical(other.staffName, staffName) || other.staffName == staffName)&&(identical(other.staffEmail, staffEmail) || other.staffEmail == staffEmail)&&(identical(other.staffAvatarUrl, staffAvatarUrl) || other.staffAvatarUrl == staffAvatarUrl)&&(identical(other.periodStart, periodStart) || other.periodStart == periodStart)&&(identical(other.periodEnd, periodEnd) || other.periodEnd == periodEnd)&&(identical(other.totalWorkedMinutes, totalWorkedMinutes) || other.totalWorkedMinutes == totalWorkedMinutes)&&(identical(other.totalBreakMinutes, totalBreakMinutes) || other.totalBreakMinutes == totalBreakMinutes)&&(identical(other.totalShifts, totalShifts) || other.totalShifts == totalShifts)&&(identical(other.regularMinutes, regularMinutes) || other.regularMinutes == regularMinutes)&&(identical(other.overtimeMinutes, overtimeMinutes) || other.overtimeMinutes == overtimeMinutes)&&(identical(other.hourlyRateCents, hourlyRateCents) || other.hourlyRateCents == hourlyRateCents)&&(identical(other.estimatedPayAmount, estimatedPayAmount) || other.estimatedPayAmount == estimatedPayAmount)&&const DeepCollectionEquality().equals(other.entries, entries)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,staffId,staffName,staffEmail,staffAvatarUrl,periodStart,periodEnd,totalWorkedMinutes,totalBreakMinutes,totalShifts,regularMinutes,overtimeMinutes,hourlyRateCents,estimatedPayAmount,const DeepCollectionEquality().hash(entries),status);

@override
String toString() {
  return 'TimesheetSummary(staffId: $staffId, staffName: $staffName, staffEmail: $staffEmail, staffAvatarUrl: $staffAvatarUrl, periodStart: $periodStart, periodEnd: $periodEnd, totalWorkedMinutes: $totalWorkedMinutes, totalBreakMinutes: $totalBreakMinutes, totalShifts: $totalShifts, regularMinutes: $regularMinutes, overtimeMinutes: $overtimeMinutes, hourlyRateCents: $hourlyRateCents, estimatedPayAmount: $estimatedPayAmount, entries: $entries, status: $status)';
}


}

/// @nodoc
abstract mixin class $TimesheetSummaryCopyWith<$Res>  {
  factory $TimesheetSummaryCopyWith(TimesheetSummary value, $Res Function(TimesheetSummary) _then) = _$TimesheetSummaryCopyWithImpl;
@useResult
$Res call({
 String staffId, String staffName, String? staffEmail, String? staffAvatarUrl,@TimestampConverter() DateTime periodStart,@TimestampConverter() DateTime periodEnd, int totalWorkedMinutes, int totalBreakMinutes, int totalShifts, int regularMinutes, int overtimeMinutes, int? hourlyRateCents, double estimatedPayAmount, List<TimeEntry> entries, TimesheetStatus status
});




}
/// @nodoc
class _$TimesheetSummaryCopyWithImpl<$Res>
    implements $TimesheetSummaryCopyWith<$Res> {
  _$TimesheetSummaryCopyWithImpl(this._self, this._then);

  final TimesheetSummary _self;
  final $Res Function(TimesheetSummary) _then;

/// Create a copy of TimesheetSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? staffId = null,Object? staffName = null,Object? staffEmail = freezed,Object? staffAvatarUrl = freezed,Object? periodStart = null,Object? periodEnd = null,Object? totalWorkedMinutes = null,Object? totalBreakMinutes = null,Object? totalShifts = null,Object? regularMinutes = null,Object? overtimeMinutes = null,Object? hourlyRateCents = freezed,Object? estimatedPayAmount = null,Object? entries = null,Object? status = null,}) {
  return _then(_self.copyWith(
staffId: null == staffId ? _self.staffId : staffId // ignore: cast_nullable_to_non_nullable
as String,staffName: null == staffName ? _self.staffName : staffName // ignore: cast_nullable_to_non_nullable
as String,staffEmail: freezed == staffEmail ? _self.staffEmail : staffEmail // ignore: cast_nullable_to_non_nullable
as String?,staffAvatarUrl: freezed == staffAvatarUrl ? _self.staffAvatarUrl : staffAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,periodStart: null == periodStart ? _self.periodStart : periodStart // ignore: cast_nullable_to_non_nullable
as DateTime,periodEnd: null == periodEnd ? _self.periodEnd : periodEnd // ignore: cast_nullable_to_non_nullable
as DateTime,totalWorkedMinutes: null == totalWorkedMinutes ? _self.totalWorkedMinutes : totalWorkedMinutes // ignore: cast_nullable_to_non_nullable
as int,totalBreakMinutes: null == totalBreakMinutes ? _self.totalBreakMinutes : totalBreakMinutes // ignore: cast_nullable_to_non_nullable
as int,totalShifts: null == totalShifts ? _self.totalShifts : totalShifts // ignore: cast_nullable_to_non_nullable
as int,regularMinutes: null == regularMinutes ? _self.regularMinutes : regularMinutes // ignore: cast_nullable_to_non_nullable
as int,overtimeMinutes: null == overtimeMinutes ? _self.overtimeMinutes : overtimeMinutes // ignore: cast_nullable_to_non_nullable
as int,hourlyRateCents: freezed == hourlyRateCents ? _self.hourlyRateCents : hourlyRateCents // ignore: cast_nullable_to_non_nullable
as int?,estimatedPayAmount: null == estimatedPayAmount ? _self.estimatedPayAmount : estimatedPayAmount // ignore: cast_nullable_to_non_nullable
as double,entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<TimeEntry>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TimesheetStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [TimesheetSummary].
extension TimesheetSummaryPatterns on TimesheetSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TimesheetSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TimesheetSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TimesheetSummary value)  $default,){
final _that = this;
switch (_that) {
case _TimesheetSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TimesheetSummary value)?  $default,){
final _that = this;
switch (_that) {
case _TimesheetSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String staffId,  String staffName,  String? staffEmail,  String? staffAvatarUrl, @TimestampConverter()  DateTime periodStart, @TimestampConverter()  DateTime periodEnd,  int totalWorkedMinutes,  int totalBreakMinutes,  int totalShifts,  int regularMinutes,  int overtimeMinutes,  int? hourlyRateCents,  double estimatedPayAmount,  List<TimeEntry> entries,  TimesheetStatus status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TimesheetSummary() when $default != null:
return $default(_that.staffId,_that.staffName,_that.staffEmail,_that.staffAvatarUrl,_that.periodStart,_that.periodEnd,_that.totalWorkedMinutes,_that.totalBreakMinutes,_that.totalShifts,_that.regularMinutes,_that.overtimeMinutes,_that.hourlyRateCents,_that.estimatedPayAmount,_that.entries,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String staffId,  String staffName,  String? staffEmail,  String? staffAvatarUrl, @TimestampConverter()  DateTime periodStart, @TimestampConverter()  DateTime periodEnd,  int totalWorkedMinutes,  int totalBreakMinutes,  int totalShifts,  int regularMinutes,  int overtimeMinutes,  int? hourlyRateCents,  double estimatedPayAmount,  List<TimeEntry> entries,  TimesheetStatus status)  $default,) {final _that = this;
switch (_that) {
case _TimesheetSummary():
return $default(_that.staffId,_that.staffName,_that.staffEmail,_that.staffAvatarUrl,_that.periodStart,_that.periodEnd,_that.totalWorkedMinutes,_that.totalBreakMinutes,_that.totalShifts,_that.regularMinutes,_that.overtimeMinutes,_that.hourlyRateCents,_that.estimatedPayAmount,_that.entries,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String staffId,  String staffName,  String? staffEmail,  String? staffAvatarUrl, @TimestampConverter()  DateTime periodStart, @TimestampConverter()  DateTime periodEnd,  int totalWorkedMinutes,  int totalBreakMinutes,  int totalShifts,  int regularMinutes,  int overtimeMinutes,  int? hourlyRateCents,  double estimatedPayAmount,  List<TimeEntry> entries,  TimesheetStatus status)?  $default,) {final _that = this;
switch (_that) {
case _TimesheetSummary() when $default != null:
return $default(_that.staffId,_that.staffName,_that.staffEmail,_that.staffAvatarUrl,_that.periodStart,_that.periodEnd,_that.totalWorkedMinutes,_that.totalBreakMinutes,_that.totalShifts,_that.regularMinutes,_that.overtimeMinutes,_that.hourlyRateCents,_that.estimatedPayAmount,_that.entries,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TimesheetSummary extends TimesheetSummary {
  const _TimesheetSummary({required this.staffId, required this.staffName, this.staffEmail, this.staffAvatarUrl, @TimestampConverter() required this.periodStart, @TimestampConverter() required this.periodEnd, required this.totalWorkedMinutes, required this.totalBreakMinutes, required this.totalShifts, required this.regularMinutes, required this.overtimeMinutes, this.hourlyRateCents, required this.estimatedPayAmount, required final  List<TimeEntry> entries, required this.status}): _entries = entries,super._();
  factory _TimesheetSummary.fromJson(Map<String, dynamic> json) => _$TimesheetSummaryFromJson(json);

@override final  String staffId;
@override final  String staffName;
@override final  String? staffEmail;
@override final  String? staffAvatarUrl;
@override@TimestampConverter() final  DateTime periodStart;
@override@TimestampConverter() final  DateTime periodEnd;
/// Total minutes worked across all entries
@override final  int totalWorkedMinutes;
/// Total break minutes across all entries
@override final  int totalBreakMinutes;
/// Number of shifts (clock-in/clock-out cycles) in period
@override final  int totalShifts;
/// Regular hours (up to 8 hrs/day or 40 hrs/week)
@override final  int regularMinutes;
/// Overtime hours (beyond 8 hrs/day or 40 hrs/week)
@override final  int overtimeMinutes;
/// Staff hourly rate in cents (if available)
@override final  int? hourlyRateCents;
/// Estimated pay based on hourly rate (regular + overtime)
@override final  double estimatedPayAmount;
/// All time entries in this period
 final  List<TimeEntry> _entries;
/// All time entries in this period
@override List<TimeEntry> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}

/// Current approval status
@override final  TimesheetStatus status;

/// Create a copy of TimesheetSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TimesheetSummaryCopyWith<_TimesheetSummary> get copyWith => __$TimesheetSummaryCopyWithImpl<_TimesheetSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TimesheetSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TimesheetSummary&&(identical(other.staffId, staffId) || other.staffId == staffId)&&(identical(other.staffName, staffName) || other.staffName == staffName)&&(identical(other.staffEmail, staffEmail) || other.staffEmail == staffEmail)&&(identical(other.staffAvatarUrl, staffAvatarUrl) || other.staffAvatarUrl == staffAvatarUrl)&&(identical(other.periodStart, periodStart) || other.periodStart == periodStart)&&(identical(other.periodEnd, periodEnd) || other.periodEnd == periodEnd)&&(identical(other.totalWorkedMinutes, totalWorkedMinutes) || other.totalWorkedMinutes == totalWorkedMinutes)&&(identical(other.totalBreakMinutes, totalBreakMinutes) || other.totalBreakMinutes == totalBreakMinutes)&&(identical(other.totalShifts, totalShifts) || other.totalShifts == totalShifts)&&(identical(other.regularMinutes, regularMinutes) || other.regularMinutes == regularMinutes)&&(identical(other.overtimeMinutes, overtimeMinutes) || other.overtimeMinutes == overtimeMinutes)&&(identical(other.hourlyRateCents, hourlyRateCents) || other.hourlyRateCents == hourlyRateCents)&&(identical(other.estimatedPayAmount, estimatedPayAmount) || other.estimatedPayAmount == estimatedPayAmount)&&const DeepCollectionEquality().equals(other._entries, _entries)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,staffId,staffName,staffEmail,staffAvatarUrl,periodStart,periodEnd,totalWorkedMinutes,totalBreakMinutes,totalShifts,regularMinutes,overtimeMinutes,hourlyRateCents,estimatedPayAmount,const DeepCollectionEquality().hash(_entries),status);

@override
String toString() {
  return 'TimesheetSummary(staffId: $staffId, staffName: $staffName, staffEmail: $staffEmail, staffAvatarUrl: $staffAvatarUrl, periodStart: $periodStart, periodEnd: $periodEnd, totalWorkedMinutes: $totalWorkedMinutes, totalBreakMinutes: $totalBreakMinutes, totalShifts: $totalShifts, regularMinutes: $regularMinutes, overtimeMinutes: $overtimeMinutes, hourlyRateCents: $hourlyRateCents, estimatedPayAmount: $estimatedPayAmount, entries: $entries, status: $status)';
}


}

/// @nodoc
abstract mixin class _$TimesheetSummaryCopyWith<$Res> implements $TimesheetSummaryCopyWith<$Res> {
  factory _$TimesheetSummaryCopyWith(_TimesheetSummary value, $Res Function(_TimesheetSummary) _then) = __$TimesheetSummaryCopyWithImpl;
@override @useResult
$Res call({
 String staffId, String staffName, String? staffEmail, String? staffAvatarUrl,@TimestampConverter() DateTime periodStart,@TimestampConverter() DateTime periodEnd, int totalWorkedMinutes, int totalBreakMinutes, int totalShifts, int regularMinutes, int overtimeMinutes, int? hourlyRateCents, double estimatedPayAmount, List<TimeEntry> entries, TimesheetStatus status
});




}
/// @nodoc
class __$TimesheetSummaryCopyWithImpl<$Res>
    implements _$TimesheetSummaryCopyWith<$Res> {
  __$TimesheetSummaryCopyWithImpl(this._self, this._then);

  final _TimesheetSummary _self;
  final $Res Function(_TimesheetSummary) _then;

/// Create a copy of TimesheetSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? staffId = null,Object? staffName = null,Object? staffEmail = freezed,Object? staffAvatarUrl = freezed,Object? periodStart = null,Object? periodEnd = null,Object? totalWorkedMinutes = null,Object? totalBreakMinutes = null,Object? totalShifts = null,Object? regularMinutes = null,Object? overtimeMinutes = null,Object? hourlyRateCents = freezed,Object? estimatedPayAmount = null,Object? entries = null,Object? status = null,}) {
  return _then(_TimesheetSummary(
staffId: null == staffId ? _self.staffId : staffId // ignore: cast_nullable_to_non_nullable
as String,staffName: null == staffName ? _self.staffName : staffName // ignore: cast_nullable_to_non_nullable
as String,staffEmail: freezed == staffEmail ? _self.staffEmail : staffEmail // ignore: cast_nullable_to_non_nullable
as String?,staffAvatarUrl: freezed == staffAvatarUrl ? _self.staffAvatarUrl : staffAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,periodStart: null == periodStart ? _self.periodStart : periodStart // ignore: cast_nullable_to_non_nullable
as DateTime,periodEnd: null == periodEnd ? _self.periodEnd : periodEnd // ignore: cast_nullable_to_non_nullable
as DateTime,totalWorkedMinutes: null == totalWorkedMinutes ? _self.totalWorkedMinutes : totalWorkedMinutes // ignore: cast_nullable_to_non_nullable
as int,totalBreakMinutes: null == totalBreakMinutes ? _self.totalBreakMinutes : totalBreakMinutes // ignore: cast_nullable_to_non_nullable
as int,totalShifts: null == totalShifts ? _self.totalShifts : totalShifts // ignore: cast_nullable_to_non_nullable
as int,regularMinutes: null == regularMinutes ? _self.regularMinutes : regularMinutes // ignore: cast_nullable_to_non_nullable
as int,overtimeMinutes: null == overtimeMinutes ? _self.overtimeMinutes : overtimeMinutes // ignore: cast_nullable_to_non_nullable
as int,hourlyRateCents: freezed == hourlyRateCents ? _self.hourlyRateCents : hourlyRateCents // ignore: cast_nullable_to_non_nullable
as int?,estimatedPayAmount: null == estimatedPayAmount ? _self.estimatedPayAmount : estimatedPayAmount // ignore: cast_nullable_to_non_nullable
as double,entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<TimeEntry>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TimesheetStatus,
  ));
}


}

// dart format on
