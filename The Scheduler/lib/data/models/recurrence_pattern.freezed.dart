// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recurrence_pattern.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecurrencePattern {

/// Unique identifier for this recurrence pattern
 String get id;/// How often the appointment recurs
 RecurrenceFrequency get frequency;/// For weekly/biweekly: which days of the week
/// For monthly: which day of month (stored as int in customInterval)
 List<DayOfWeek> get daysOfWeek;/// Custom interval (e.g., every 3 days, every 2 weeks)
/// Only used when frequency is 'custom'
 int? get customInterval;/// Custom interval unit (days, weeks, months) for custom frequency
 String? get customIntervalUnit;/// How the recurrence ends
 RecurrenceEndType get endType;/// Number of occurrences before stopping (used if endType is afterOccurrences)
 int? get numberOfOccurrences;/// End date for recurrence (used if endType is onDate)
@NullableTimestampConverter() DateTime? get endDate;/// Dates to exclude from recurrence (holidays, provider time off)
@TimestampListConverter() List<DateTime> get exclusionDates;/// Whether this pattern is currently active
 bool get isActive;/// When this pattern was created
@TimestampConverter() DateTime get createdAt;/// When this pattern was last modified
@NullableTimestampConverter() DateTime? get updatedAt;
/// Create a copy of RecurrencePattern
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecurrencePatternCopyWith<RecurrencePattern> get copyWith => _$RecurrencePatternCopyWithImpl<RecurrencePattern>(this as RecurrencePattern, _$identity);

  /// Serializes this RecurrencePattern to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecurrencePattern&&(identical(other.id, id) || other.id == id)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&const DeepCollectionEquality().equals(other.daysOfWeek, daysOfWeek)&&(identical(other.customInterval, customInterval) || other.customInterval == customInterval)&&(identical(other.customIntervalUnit, customIntervalUnit) || other.customIntervalUnit == customIntervalUnit)&&(identical(other.endType, endType) || other.endType == endType)&&(identical(other.numberOfOccurrences, numberOfOccurrences) || other.numberOfOccurrences == numberOfOccurrences)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&const DeepCollectionEquality().equals(other.exclusionDates, exclusionDates)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,frequency,const DeepCollectionEquality().hash(daysOfWeek),customInterval,customIntervalUnit,endType,numberOfOccurrences,endDate,const DeepCollectionEquality().hash(exclusionDates),isActive,createdAt,updatedAt);

@override
String toString() {
  return 'RecurrencePattern(id: $id, frequency: $frequency, daysOfWeek: $daysOfWeek, customInterval: $customInterval, customIntervalUnit: $customIntervalUnit, endType: $endType, numberOfOccurrences: $numberOfOccurrences, endDate: $endDate, exclusionDates: $exclusionDates, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $RecurrencePatternCopyWith<$Res>  {
  factory $RecurrencePatternCopyWith(RecurrencePattern value, $Res Function(RecurrencePattern) _then) = _$RecurrencePatternCopyWithImpl;
@useResult
$Res call({
 String id, RecurrenceFrequency frequency, List<DayOfWeek> daysOfWeek, int? customInterval, String? customIntervalUnit, RecurrenceEndType endType, int? numberOfOccurrences,@NullableTimestampConverter() DateTime? endDate,@TimestampListConverter() List<DateTime> exclusionDates, bool isActive,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$RecurrencePatternCopyWithImpl<$Res>
    implements $RecurrencePatternCopyWith<$Res> {
  _$RecurrencePatternCopyWithImpl(this._self, this._then);

  final RecurrencePattern _self;
  final $Res Function(RecurrencePattern) _then;

/// Create a copy of RecurrencePattern
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? frequency = null,Object? daysOfWeek = null,Object? customInterval = freezed,Object? customIntervalUnit = freezed,Object? endType = null,Object? numberOfOccurrences = freezed,Object? endDate = freezed,Object? exclusionDates = null,Object? isActive = null,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as RecurrenceFrequency,daysOfWeek: null == daysOfWeek ? _self.daysOfWeek : daysOfWeek // ignore: cast_nullable_to_non_nullable
as List<DayOfWeek>,customInterval: freezed == customInterval ? _self.customInterval : customInterval // ignore: cast_nullable_to_non_nullable
as int?,customIntervalUnit: freezed == customIntervalUnit ? _self.customIntervalUnit : customIntervalUnit // ignore: cast_nullable_to_non_nullable
as String?,endType: null == endType ? _self.endType : endType // ignore: cast_nullable_to_non_nullable
as RecurrenceEndType,numberOfOccurrences: freezed == numberOfOccurrences ? _self.numberOfOccurrences : numberOfOccurrences // ignore: cast_nullable_to_non_nullable
as int?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,exclusionDates: null == exclusionDates ? _self.exclusionDates : exclusionDates // ignore: cast_nullable_to_non_nullable
as List<DateTime>,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [RecurrencePattern].
extension RecurrencePatternPatterns on RecurrencePattern {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecurrencePattern value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecurrencePattern() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecurrencePattern value)  $default,){
final _that = this;
switch (_that) {
case _RecurrencePattern():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecurrencePattern value)?  $default,){
final _that = this;
switch (_that) {
case _RecurrencePattern() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  RecurrenceFrequency frequency,  List<DayOfWeek> daysOfWeek,  int? customInterval,  String? customIntervalUnit,  RecurrenceEndType endType,  int? numberOfOccurrences, @NullableTimestampConverter()  DateTime? endDate, @TimestampListConverter()  List<DateTime> exclusionDates,  bool isActive, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecurrencePattern() when $default != null:
return $default(_that.id,_that.frequency,_that.daysOfWeek,_that.customInterval,_that.customIntervalUnit,_that.endType,_that.numberOfOccurrences,_that.endDate,_that.exclusionDates,_that.isActive,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  RecurrenceFrequency frequency,  List<DayOfWeek> daysOfWeek,  int? customInterval,  String? customIntervalUnit,  RecurrenceEndType endType,  int? numberOfOccurrences, @NullableTimestampConverter()  DateTime? endDate, @TimestampListConverter()  List<DateTime> exclusionDates,  bool isActive, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _RecurrencePattern():
return $default(_that.id,_that.frequency,_that.daysOfWeek,_that.customInterval,_that.customIntervalUnit,_that.endType,_that.numberOfOccurrences,_that.endDate,_that.exclusionDates,_that.isActive,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  RecurrenceFrequency frequency,  List<DayOfWeek> daysOfWeek,  int? customInterval,  String? customIntervalUnit,  RecurrenceEndType endType,  int? numberOfOccurrences, @NullableTimestampConverter()  DateTime? endDate, @TimestampListConverter()  List<DateTime> exclusionDates,  bool isActive, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _RecurrencePattern() when $default != null:
return $default(_that.id,_that.frequency,_that.daysOfWeek,_that.customInterval,_that.customIntervalUnit,_that.endType,_that.numberOfOccurrences,_that.endDate,_that.exclusionDates,_that.isActive,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecurrencePattern implements RecurrencePattern {
  const _RecurrencePattern({required this.id, required this.frequency, final  List<DayOfWeek> daysOfWeek = const [], this.customInterval, this.customIntervalUnit, required this.endType, this.numberOfOccurrences, @NullableTimestampConverter() this.endDate, @TimestampListConverter() final  List<DateTime> exclusionDates = const [], this.isActive = true, @TimestampConverter() required this.createdAt, @NullableTimestampConverter() this.updatedAt}): _daysOfWeek = daysOfWeek,_exclusionDates = exclusionDates;
  factory _RecurrencePattern.fromJson(Map<String, dynamic> json) => _$RecurrencePatternFromJson(json);

/// Unique identifier for this recurrence pattern
@override final  String id;
/// How often the appointment recurs
@override final  RecurrenceFrequency frequency;
/// For weekly/biweekly: which days of the week
/// For monthly: which day of month (stored as int in customInterval)
 final  List<DayOfWeek> _daysOfWeek;
/// For weekly/biweekly: which days of the week
/// For monthly: which day of month (stored as int in customInterval)
@override@JsonKey() List<DayOfWeek> get daysOfWeek {
  if (_daysOfWeek is EqualUnmodifiableListView) return _daysOfWeek;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_daysOfWeek);
}

/// Custom interval (e.g., every 3 days, every 2 weeks)
/// Only used when frequency is 'custom'
@override final  int? customInterval;
/// Custom interval unit (days, weeks, months) for custom frequency
@override final  String? customIntervalUnit;
/// How the recurrence ends
@override final  RecurrenceEndType endType;
/// Number of occurrences before stopping (used if endType is afterOccurrences)
@override final  int? numberOfOccurrences;
/// End date for recurrence (used if endType is onDate)
@override@NullableTimestampConverter() final  DateTime? endDate;
/// Dates to exclude from recurrence (holidays, provider time off)
 final  List<DateTime> _exclusionDates;
/// Dates to exclude from recurrence (holidays, provider time off)
@override@JsonKey()@TimestampListConverter() List<DateTime> get exclusionDates {
  if (_exclusionDates is EqualUnmodifiableListView) return _exclusionDates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_exclusionDates);
}

/// Whether this pattern is currently active
@override@JsonKey() final  bool isActive;
/// When this pattern was created
@override@TimestampConverter() final  DateTime createdAt;
/// When this pattern was last modified
@override@NullableTimestampConverter() final  DateTime? updatedAt;

/// Create a copy of RecurrencePattern
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecurrencePatternCopyWith<_RecurrencePattern> get copyWith => __$RecurrencePatternCopyWithImpl<_RecurrencePattern>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecurrencePatternToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecurrencePattern&&(identical(other.id, id) || other.id == id)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&const DeepCollectionEquality().equals(other._daysOfWeek, _daysOfWeek)&&(identical(other.customInterval, customInterval) || other.customInterval == customInterval)&&(identical(other.customIntervalUnit, customIntervalUnit) || other.customIntervalUnit == customIntervalUnit)&&(identical(other.endType, endType) || other.endType == endType)&&(identical(other.numberOfOccurrences, numberOfOccurrences) || other.numberOfOccurrences == numberOfOccurrences)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&const DeepCollectionEquality().equals(other._exclusionDates, _exclusionDates)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,frequency,const DeepCollectionEquality().hash(_daysOfWeek),customInterval,customIntervalUnit,endType,numberOfOccurrences,endDate,const DeepCollectionEquality().hash(_exclusionDates),isActive,createdAt,updatedAt);

@override
String toString() {
  return 'RecurrencePattern(id: $id, frequency: $frequency, daysOfWeek: $daysOfWeek, customInterval: $customInterval, customIntervalUnit: $customIntervalUnit, endType: $endType, numberOfOccurrences: $numberOfOccurrences, endDate: $endDate, exclusionDates: $exclusionDates, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$RecurrencePatternCopyWith<$Res> implements $RecurrencePatternCopyWith<$Res> {
  factory _$RecurrencePatternCopyWith(_RecurrencePattern value, $Res Function(_RecurrencePattern) _then) = __$RecurrencePatternCopyWithImpl;
@override @useResult
$Res call({
 String id, RecurrenceFrequency frequency, List<DayOfWeek> daysOfWeek, int? customInterval, String? customIntervalUnit, RecurrenceEndType endType, int? numberOfOccurrences,@NullableTimestampConverter() DateTime? endDate,@TimestampListConverter() List<DateTime> exclusionDates, bool isActive,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$RecurrencePatternCopyWithImpl<$Res>
    implements _$RecurrencePatternCopyWith<$Res> {
  __$RecurrencePatternCopyWithImpl(this._self, this._then);

  final _RecurrencePattern _self;
  final $Res Function(_RecurrencePattern) _then;

/// Create a copy of RecurrencePattern
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? frequency = null,Object? daysOfWeek = null,Object? customInterval = freezed,Object? customIntervalUnit = freezed,Object? endType = null,Object? numberOfOccurrences = freezed,Object? endDate = freezed,Object? exclusionDates = null,Object? isActive = null,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_RecurrencePattern(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as RecurrenceFrequency,daysOfWeek: null == daysOfWeek ? _self._daysOfWeek : daysOfWeek // ignore: cast_nullable_to_non_nullable
as List<DayOfWeek>,customInterval: freezed == customInterval ? _self.customInterval : customInterval // ignore: cast_nullable_to_non_nullable
as int?,customIntervalUnit: freezed == customIntervalUnit ? _self.customIntervalUnit : customIntervalUnit // ignore: cast_nullable_to_non_nullable
as String?,endType: null == endType ? _self.endType : endType // ignore: cast_nullable_to_non_nullable
as RecurrenceEndType,numberOfOccurrences: freezed == numberOfOccurrences ? _self.numberOfOccurrences : numberOfOccurrences // ignore: cast_nullable_to_non_nullable
as int?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,exclusionDates: null == exclusionDates ? _self._exclusionDates : exclusionDates // ignore: cast_nullable_to_non_nullable
as List<DateTime>,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
