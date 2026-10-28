// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'availability.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TimeBlock {

 int get startHour;// 0-23
 int get startMinute;// 0-59
 int get endHour;// 0-23
 int get endMinute;
/// Create a copy of TimeBlock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimeBlockCopyWith<TimeBlock> get copyWith => _$TimeBlockCopyWithImpl<TimeBlock>(this as TimeBlock, _$identity);

  /// Serializes this TimeBlock to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimeBlock&&(identical(other.startHour, startHour) || other.startHour == startHour)&&(identical(other.startMinute, startMinute) || other.startMinute == startMinute)&&(identical(other.endHour, endHour) || other.endHour == endHour)&&(identical(other.endMinute, endMinute) || other.endMinute == endMinute));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startHour,startMinute,endHour,endMinute);

@override
String toString() {
  return 'TimeBlock(startHour: $startHour, startMinute: $startMinute, endHour: $endHour, endMinute: $endMinute)';
}


}

/// @nodoc
abstract mixin class $TimeBlockCopyWith<$Res>  {
  factory $TimeBlockCopyWith(TimeBlock value, $Res Function(TimeBlock) _then) = _$TimeBlockCopyWithImpl;
@useResult
$Res call({
 int startHour, int startMinute, int endHour, int endMinute
});




}
/// @nodoc
class _$TimeBlockCopyWithImpl<$Res>
    implements $TimeBlockCopyWith<$Res> {
  _$TimeBlockCopyWithImpl(this._self, this._then);

  final TimeBlock _self;
  final $Res Function(TimeBlock) _then;

/// Create a copy of TimeBlock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startHour = null,Object? startMinute = null,Object? endHour = null,Object? endMinute = null,}) {
  return _then(_self.copyWith(
startHour: null == startHour ? _self.startHour : startHour // ignore: cast_nullable_to_non_nullable
as int,startMinute: null == startMinute ? _self.startMinute : startMinute // ignore: cast_nullable_to_non_nullable
as int,endHour: null == endHour ? _self.endHour : endHour // ignore: cast_nullable_to_non_nullable
as int,endMinute: null == endMinute ? _self.endMinute : endMinute // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TimeBlock].
extension TimeBlockPatterns on TimeBlock {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TimeBlock value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TimeBlock() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TimeBlock value)  $default,){
final _that = this;
switch (_that) {
case _TimeBlock():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TimeBlock value)?  $default,){
final _that = this;
switch (_that) {
case _TimeBlock() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int startHour,  int startMinute,  int endHour,  int endMinute)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TimeBlock() when $default != null:
return $default(_that.startHour,_that.startMinute,_that.endHour,_that.endMinute);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int startHour,  int startMinute,  int endHour,  int endMinute)  $default,) {final _that = this;
switch (_that) {
case _TimeBlock():
return $default(_that.startHour,_that.startMinute,_that.endHour,_that.endMinute);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int startHour,  int startMinute,  int endHour,  int endMinute)?  $default,) {final _that = this;
switch (_that) {
case _TimeBlock() when $default != null:
return $default(_that.startHour,_that.startMinute,_that.endHour,_that.endMinute);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TimeBlock extends TimeBlock {
  const _TimeBlock({required this.startHour, required this.startMinute, required this.endHour, required this.endMinute}): super._();
  factory _TimeBlock.fromJson(Map<String, dynamic> json) => _$TimeBlockFromJson(json);

@override final  int startHour;
// 0-23
@override final  int startMinute;
// 0-59
@override final  int endHour;
// 0-23
@override final  int endMinute;

/// Create a copy of TimeBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TimeBlockCopyWith<_TimeBlock> get copyWith => __$TimeBlockCopyWithImpl<_TimeBlock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TimeBlockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TimeBlock&&(identical(other.startHour, startHour) || other.startHour == startHour)&&(identical(other.startMinute, startMinute) || other.startMinute == startMinute)&&(identical(other.endHour, endHour) || other.endHour == endHour)&&(identical(other.endMinute, endMinute) || other.endMinute == endMinute));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startHour,startMinute,endHour,endMinute);

@override
String toString() {
  return 'TimeBlock(startHour: $startHour, startMinute: $startMinute, endHour: $endHour, endMinute: $endMinute)';
}


}

/// @nodoc
abstract mixin class _$TimeBlockCopyWith<$Res> implements $TimeBlockCopyWith<$Res> {
  factory _$TimeBlockCopyWith(_TimeBlock value, $Res Function(_TimeBlock) _then) = __$TimeBlockCopyWithImpl;
@override @useResult
$Res call({
 int startHour, int startMinute, int endHour, int endMinute
});




}
/// @nodoc
class __$TimeBlockCopyWithImpl<$Res>
    implements _$TimeBlockCopyWith<$Res> {
  __$TimeBlockCopyWithImpl(this._self, this._then);

  final _TimeBlock _self;
  final $Res Function(_TimeBlock) _then;

/// Create a copy of TimeBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startHour = null,Object? startMinute = null,Object? endHour = null,Object? endMinute = null,}) {
  return _then(_TimeBlock(
startHour: null == startHour ? _self.startHour : startHour // ignore: cast_nullable_to_non_nullable
as int,startMinute: null == startMinute ? _self.startMinute : startMinute // ignore: cast_nullable_to_non_nullable
as int,endHour: null == endHour ? _self.endHour : endHour // ignore: cast_nullable_to_non_nullable
as int,endMinute: null == endMinute ? _self.endMinute : endMinute // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$WeeklySchedule {

 String get id; String get providerId; String get locationId; DayOfWeek get dayOfWeek; List<TimeBlock> get timeBlocks; bool get isActive;@TimestampConverter() DateTime get createdAt;@NullableTimestampConverter() DateTime? get updatedAt;
/// Create a copy of WeeklySchedule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeeklyScheduleCopyWith<WeeklySchedule> get copyWith => _$WeeklyScheduleCopyWithImpl<WeeklySchedule>(this as WeeklySchedule, _$identity);

  /// Serializes this WeeklySchedule to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeeklySchedule&&(identical(other.id, id) || other.id == id)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.locationId, locationId) || other.locationId == locationId)&&(identical(other.dayOfWeek, dayOfWeek) || other.dayOfWeek == dayOfWeek)&&const DeepCollectionEquality().equals(other.timeBlocks, timeBlocks)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,providerId,locationId,dayOfWeek,const DeepCollectionEquality().hash(timeBlocks),isActive,createdAt,updatedAt);

@override
String toString() {
  return 'WeeklySchedule(id: $id, providerId: $providerId, locationId: $locationId, dayOfWeek: $dayOfWeek, timeBlocks: $timeBlocks, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $WeeklyScheduleCopyWith<$Res>  {
  factory $WeeklyScheduleCopyWith(WeeklySchedule value, $Res Function(WeeklySchedule) _then) = _$WeeklyScheduleCopyWithImpl;
@useResult
$Res call({
 String id, String providerId, String locationId, DayOfWeek dayOfWeek, List<TimeBlock> timeBlocks, bool isActive,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$WeeklyScheduleCopyWithImpl<$Res>
    implements $WeeklyScheduleCopyWith<$Res> {
  _$WeeklyScheduleCopyWithImpl(this._self, this._then);

  final WeeklySchedule _self;
  final $Res Function(WeeklySchedule) _then;

/// Create a copy of WeeklySchedule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? providerId = null,Object? locationId = null,Object? dayOfWeek = null,Object? timeBlocks = null,Object? isActive = null,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,locationId: null == locationId ? _self.locationId : locationId // ignore: cast_nullable_to_non_nullable
as String,dayOfWeek: null == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as DayOfWeek,timeBlocks: null == timeBlocks ? _self.timeBlocks : timeBlocks // ignore: cast_nullable_to_non_nullable
as List<TimeBlock>,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [WeeklySchedule].
extension WeeklySchedulePatterns on WeeklySchedule {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeeklySchedule value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeeklySchedule() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeeklySchedule value)  $default,){
final _that = this;
switch (_that) {
case _WeeklySchedule():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeeklySchedule value)?  $default,){
final _that = this;
switch (_that) {
case _WeeklySchedule() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String providerId,  String locationId,  DayOfWeek dayOfWeek,  List<TimeBlock> timeBlocks,  bool isActive, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeeklySchedule() when $default != null:
return $default(_that.id,_that.providerId,_that.locationId,_that.dayOfWeek,_that.timeBlocks,_that.isActive,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String providerId,  String locationId,  DayOfWeek dayOfWeek,  List<TimeBlock> timeBlocks,  bool isActive, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _WeeklySchedule():
return $default(_that.id,_that.providerId,_that.locationId,_that.dayOfWeek,_that.timeBlocks,_that.isActive,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String providerId,  String locationId,  DayOfWeek dayOfWeek,  List<TimeBlock> timeBlocks,  bool isActive, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _WeeklySchedule() when $default != null:
return $default(_that.id,_that.providerId,_that.locationId,_that.dayOfWeek,_that.timeBlocks,_that.isActive,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WeeklySchedule implements WeeklySchedule {
  const _WeeklySchedule({required this.id, required this.providerId, required this.locationId, required this.dayOfWeek, required final  List<TimeBlock> timeBlocks, this.isActive = true, @TimestampConverter() required this.createdAt, @NullableTimestampConverter() this.updatedAt}): _timeBlocks = timeBlocks;
  factory _WeeklySchedule.fromJson(Map<String, dynamic> json) => _$WeeklyScheduleFromJson(json);

@override final  String id;
@override final  String providerId;
@override final  String locationId;
@override final  DayOfWeek dayOfWeek;
 final  List<TimeBlock> _timeBlocks;
@override List<TimeBlock> get timeBlocks {
  if (_timeBlocks is EqualUnmodifiableListView) return _timeBlocks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_timeBlocks);
}

@override@JsonKey() final  bool isActive;
@override@TimestampConverter() final  DateTime createdAt;
@override@NullableTimestampConverter() final  DateTime? updatedAt;

/// Create a copy of WeeklySchedule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeeklyScheduleCopyWith<_WeeklySchedule> get copyWith => __$WeeklyScheduleCopyWithImpl<_WeeklySchedule>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WeeklyScheduleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeeklySchedule&&(identical(other.id, id) || other.id == id)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.locationId, locationId) || other.locationId == locationId)&&(identical(other.dayOfWeek, dayOfWeek) || other.dayOfWeek == dayOfWeek)&&const DeepCollectionEquality().equals(other._timeBlocks, _timeBlocks)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,providerId,locationId,dayOfWeek,const DeepCollectionEquality().hash(_timeBlocks),isActive,createdAt,updatedAt);

@override
String toString() {
  return 'WeeklySchedule(id: $id, providerId: $providerId, locationId: $locationId, dayOfWeek: $dayOfWeek, timeBlocks: $timeBlocks, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$WeeklyScheduleCopyWith<$Res> implements $WeeklyScheduleCopyWith<$Res> {
  factory _$WeeklyScheduleCopyWith(_WeeklySchedule value, $Res Function(_WeeklySchedule) _then) = __$WeeklyScheduleCopyWithImpl;
@override @useResult
$Res call({
 String id, String providerId, String locationId, DayOfWeek dayOfWeek, List<TimeBlock> timeBlocks, bool isActive,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$WeeklyScheduleCopyWithImpl<$Res>
    implements _$WeeklyScheduleCopyWith<$Res> {
  __$WeeklyScheduleCopyWithImpl(this._self, this._then);

  final _WeeklySchedule _self;
  final $Res Function(_WeeklySchedule) _then;

/// Create a copy of WeeklySchedule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? providerId = null,Object? locationId = null,Object? dayOfWeek = null,Object? timeBlocks = null,Object? isActive = null,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_WeeklySchedule(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,locationId: null == locationId ? _self.locationId : locationId // ignore: cast_nullable_to_non_nullable
as String,dayOfWeek: null == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as DayOfWeek,timeBlocks: null == timeBlocks ? _self._timeBlocks : timeBlocks // ignore: cast_nullable_to_non_nullable
as List<TimeBlock>,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$Availability {

 String get id; String get providerId; String get locationId;@TimestampConverter() DateTime get startTime;@TimestampConverter() DateTime get endTime; AvailabilityType get type; String? get reason;// Optional reason for blocked time
 bool? get isRecurring;// Deprecated - use WeeklySchedule instead
@NullableTimestampConverter() DateTime? get specificDate;// If set, only applies to this date (override)
@TimestampConverter() DateTime get createdAt;@NullableTimestampConverter() DateTime? get updatedAt;
/// Create a copy of Availability
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AvailabilityCopyWith<Availability> get copyWith => _$AvailabilityCopyWithImpl<Availability>(this as Availability, _$identity);

  /// Serializes this Availability to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Availability&&(identical(other.id, id) || other.id == id)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.locationId, locationId) || other.locationId == locationId)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.type, type) || other.type == type)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.isRecurring, isRecurring) || other.isRecurring == isRecurring)&&(identical(other.specificDate, specificDate) || other.specificDate == specificDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,providerId,locationId,startTime,endTime,type,reason,isRecurring,specificDate,createdAt,updatedAt);

@override
String toString() {
  return 'Availability(id: $id, providerId: $providerId, locationId: $locationId, startTime: $startTime, endTime: $endTime, type: $type, reason: $reason, isRecurring: $isRecurring, specificDate: $specificDate, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $AvailabilityCopyWith<$Res>  {
  factory $AvailabilityCopyWith(Availability value, $Res Function(Availability) _then) = _$AvailabilityCopyWithImpl;
@useResult
$Res call({
 String id, String providerId, String locationId,@TimestampConverter() DateTime startTime,@TimestampConverter() DateTime endTime, AvailabilityType type, String? reason, bool? isRecurring,@NullableTimestampConverter() DateTime? specificDate,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$AvailabilityCopyWithImpl<$Res>
    implements $AvailabilityCopyWith<$Res> {
  _$AvailabilityCopyWithImpl(this._self, this._then);

  final Availability _self;
  final $Res Function(Availability) _then;

/// Create a copy of Availability
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? providerId = null,Object? locationId = null,Object? startTime = null,Object? endTime = null,Object? type = null,Object? reason = freezed,Object? isRecurring = freezed,Object? specificDate = freezed,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,locationId: null == locationId ? _self.locationId : locationId // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AvailabilityType,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,isRecurring: freezed == isRecurring ? _self.isRecurring : isRecurring // ignore: cast_nullable_to_non_nullable
as bool?,specificDate: freezed == specificDate ? _self.specificDate : specificDate // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Availability].
extension AvailabilityPatterns on Availability {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Availability value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Availability() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Availability value)  $default,){
final _that = this;
switch (_that) {
case _Availability():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Availability value)?  $default,){
final _that = this;
switch (_that) {
case _Availability() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String providerId,  String locationId, @TimestampConverter()  DateTime startTime, @TimestampConverter()  DateTime endTime,  AvailabilityType type,  String? reason,  bool? isRecurring, @NullableTimestampConverter()  DateTime? specificDate, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Availability() when $default != null:
return $default(_that.id,_that.providerId,_that.locationId,_that.startTime,_that.endTime,_that.type,_that.reason,_that.isRecurring,_that.specificDate,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String providerId,  String locationId, @TimestampConverter()  DateTime startTime, @TimestampConverter()  DateTime endTime,  AvailabilityType type,  String? reason,  bool? isRecurring, @NullableTimestampConverter()  DateTime? specificDate, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Availability():
return $default(_that.id,_that.providerId,_that.locationId,_that.startTime,_that.endTime,_that.type,_that.reason,_that.isRecurring,_that.specificDate,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String providerId,  String locationId, @TimestampConverter()  DateTime startTime, @TimestampConverter()  DateTime endTime,  AvailabilityType type,  String? reason,  bool? isRecurring, @NullableTimestampConverter()  DateTime? specificDate, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Availability() when $default != null:
return $default(_that.id,_that.providerId,_that.locationId,_that.startTime,_that.endTime,_that.type,_that.reason,_that.isRecurring,_that.specificDate,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Availability extends Availability {
  const _Availability({required this.id, required this.providerId, required this.locationId, @TimestampConverter() required this.startTime, @TimestampConverter() required this.endTime, required this.type, this.reason, this.isRecurring, @NullableTimestampConverter() this.specificDate, @TimestampConverter() required this.createdAt, @NullableTimestampConverter() this.updatedAt}): super._();
  factory _Availability.fromJson(Map<String, dynamic> json) => _$AvailabilityFromJson(json);

@override final  String id;
@override final  String providerId;
@override final  String locationId;
@override@TimestampConverter() final  DateTime startTime;
@override@TimestampConverter() final  DateTime endTime;
@override final  AvailabilityType type;
@override final  String? reason;
// Optional reason for blocked time
@override final  bool? isRecurring;
// Deprecated - use WeeklySchedule instead
@override@NullableTimestampConverter() final  DateTime? specificDate;
// If set, only applies to this date (override)
@override@TimestampConverter() final  DateTime createdAt;
@override@NullableTimestampConverter() final  DateTime? updatedAt;

/// Create a copy of Availability
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AvailabilityCopyWith<_Availability> get copyWith => __$AvailabilityCopyWithImpl<_Availability>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AvailabilityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Availability&&(identical(other.id, id) || other.id == id)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.locationId, locationId) || other.locationId == locationId)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.type, type) || other.type == type)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.isRecurring, isRecurring) || other.isRecurring == isRecurring)&&(identical(other.specificDate, specificDate) || other.specificDate == specificDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,providerId,locationId,startTime,endTime,type,reason,isRecurring,specificDate,createdAt,updatedAt);

@override
String toString() {
  return 'Availability(id: $id, providerId: $providerId, locationId: $locationId, startTime: $startTime, endTime: $endTime, type: $type, reason: $reason, isRecurring: $isRecurring, specificDate: $specificDate, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$AvailabilityCopyWith<$Res> implements $AvailabilityCopyWith<$Res> {
  factory _$AvailabilityCopyWith(_Availability value, $Res Function(_Availability) _then) = __$AvailabilityCopyWithImpl;
@override @useResult
$Res call({
 String id, String providerId, String locationId,@TimestampConverter() DateTime startTime,@TimestampConverter() DateTime endTime, AvailabilityType type, String? reason, bool? isRecurring,@NullableTimestampConverter() DateTime? specificDate,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$AvailabilityCopyWithImpl<$Res>
    implements _$AvailabilityCopyWith<$Res> {
  __$AvailabilityCopyWithImpl(this._self, this._then);

  final _Availability _self;
  final $Res Function(_Availability) _then;

/// Create a copy of Availability
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? providerId = null,Object? locationId = null,Object? startTime = null,Object? endTime = null,Object? type = null,Object? reason = freezed,Object? isRecurring = freezed,Object? specificDate = freezed,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_Availability(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,locationId: null == locationId ? _self.locationId : locationId // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AvailabilityType,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,isRecurring: freezed == isRecurring ? _self.isRecurring : isRecurring // ignore: cast_nullable_to_non_nullable
as bool?,specificDate: freezed == specificDate ? _self.specificDate : specificDate // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
