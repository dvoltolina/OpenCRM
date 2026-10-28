// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'demand_forecast.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DemandForecast {

/// Date of the forecast.
 DateTime get date;/// Predicted booking count.
 double get predictedCount;/// Lower bound of confidence interval.
 double get lowerBound;/// Upper bound of confidence interval.
 double get upperBound;/// Demand level classification.
 DemandLevel get demandLevel;/// Confidence score (0-1).
 double get confidence;/// Day of week (1=Monday, 7=Sunday).
 int get dayOfWeek;/// Whether this is a holiday.
 bool get isHoliday;/// Holiday name if applicable.
 String? get holidayName;/// Year-over-year change percentage.
 double? get yearOverYearChange;/// Week-over-week change percentage.
 double? get weekOverWeekChange;/// Breakdown by service type.
 Map<String, double> get serviceBreakdown;/// Breakdown by time of day.
 Map<String, double> get hourlyBreakdown;
/// Create a copy of DemandForecast
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DemandForecastCopyWith<DemandForecast> get copyWith => _$DemandForecastCopyWithImpl<DemandForecast>(this as DemandForecast, _$identity);

  /// Serializes this DemandForecast to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DemandForecast&&(identical(other.date, date) || other.date == date)&&(identical(other.predictedCount, predictedCount) || other.predictedCount == predictedCount)&&(identical(other.lowerBound, lowerBound) || other.lowerBound == lowerBound)&&(identical(other.upperBound, upperBound) || other.upperBound == upperBound)&&(identical(other.demandLevel, demandLevel) || other.demandLevel == demandLevel)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.dayOfWeek, dayOfWeek) || other.dayOfWeek == dayOfWeek)&&(identical(other.isHoliday, isHoliday) || other.isHoliday == isHoliday)&&(identical(other.holidayName, holidayName) || other.holidayName == holidayName)&&(identical(other.yearOverYearChange, yearOverYearChange) || other.yearOverYearChange == yearOverYearChange)&&(identical(other.weekOverWeekChange, weekOverWeekChange) || other.weekOverWeekChange == weekOverWeekChange)&&const DeepCollectionEquality().equals(other.serviceBreakdown, serviceBreakdown)&&const DeepCollectionEquality().equals(other.hourlyBreakdown, hourlyBreakdown));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,predictedCount,lowerBound,upperBound,demandLevel,confidence,dayOfWeek,isHoliday,holidayName,yearOverYearChange,weekOverWeekChange,const DeepCollectionEquality().hash(serviceBreakdown),const DeepCollectionEquality().hash(hourlyBreakdown));

@override
String toString() {
  return 'DemandForecast(date: $date, predictedCount: $predictedCount, lowerBound: $lowerBound, upperBound: $upperBound, demandLevel: $demandLevel, confidence: $confidence, dayOfWeek: $dayOfWeek, isHoliday: $isHoliday, holidayName: $holidayName, yearOverYearChange: $yearOverYearChange, weekOverWeekChange: $weekOverWeekChange, serviceBreakdown: $serviceBreakdown, hourlyBreakdown: $hourlyBreakdown)';
}


}

/// @nodoc
abstract mixin class $DemandForecastCopyWith<$Res>  {
  factory $DemandForecastCopyWith(DemandForecast value, $Res Function(DemandForecast) _then) = _$DemandForecastCopyWithImpl;
@useResult
$Res call({
 DateTime date, double predictedCount, double lowerBound, double upperBound, DemandLevel demandLevel, double confidence, int dayOfWeek, bool isHoliday, String? holidayName, double? yearOverYearChange, double? weekOverWeekChange, Map<String, double> serviceBreakdown, Map<String, double> hourlyBreakdown
});




}
/// @nodoc
class _$DemandForecastCopyWithImpl<$Res>
    implements $DemandForecastCopyWith<$Res> {
  _$DemandForecastCopyWithImpl(this._self, this._then);

  final DemandForecast _self;
  final $Res Function(DemandForecast) _then;

/// Create a copy of DemandForecast
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? predictedCount = null,Object? lowerBound = null,Object? upperBound = null,Object? demandLevel = null,Object? confidence = null,Object? dayOfWeek = null,Object? isHoliday = null,Object? holidayName = freezed,Object? yearOverYearChange = freezed,Object? weekOverWeekChange = freezed,Object? serviceBreakdown = null,Object? hourlyBreakdown = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,predictedCount: null == predictedCount ? _self.predictedCount : predictedCount // ignore: cast_nullable_to_non_nullable
as double,lowerBound: null == lowerBound ? _self.lowerBound : lowerBound // ignore: cast_nullable_to_non_nullable
as double,upperBound: null == upperBound ? _self.upperBound : upperBound // ignore: cast_nullable_to_non_nullable
as double,demandLevel: null == demandLevel ? _self.demandLevel : demandLevel // ignore: cast_nullable_to_non_nullable
as DemandLevel,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,dayOfWeek: null == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as int,isHoliday: null == isHoliday ? _self.isHoliday : isHoliday // ignore: cast_nullable_to_non_nullable
as bool,holidayName: freezed == holidayName ? _self.holidayName : holidayName // ignore: cast_nullable_to_non_nullable
as String?,yearOverYearChange: freezed == yearOverYearChange ? _self.yearOverYearChange : yearOverYearChange // ignore: cast_nullable_to_non_nullable
as double?,weekOverWeekChange: freezed == weekOverWeekChange ? _self.weekOverWeekChange : weekOverWeekChange // ignore: cast_nullable_to_non_nullable
as double?,serviceBreakdown: null == serviceBreakdown ? _self.serviceBreakdown : serviceBreakdown // ignore: cast_nullable_to_non_nullable
as Map<String, double>,hourlyBreakdown: null == hourlyBreakdown ? _self.hourlyBreakdown : hourlyBreakdown // ignore: cast_nullable_to_non_nullable
as Map<String, double>,
  ));
}

}


/// Adds pattern-matching-related methods to [DemandForecast].
extension DemandForecastPatterns on DemandForecast {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DemandForecast value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DemandForecast() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DemandForecast value)  $default,){
final _that = this;
switch (_that) {
case _DemandForecast():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DemandForecast value)?  $default,){
final _that = this;
switch (_that) {
case _DemandForecast() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime date,  double predictedCount,  double lowerBound,  double upperBound,  DemandLevel demandLevel,  double confidence,  int dayOfWeek,  bool isHoliday,  String? holidayName,  double? yearOverYearChange,  double? weekOverWeekChange,  Map<String, double> serviceBreakdown,  Map<String, double> hourlyBreakdown)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DemandForecast() when $default != null:
return $default(_that.date,_that.predictedCount,_that.lowerBound,_that.upperBound,_that.demandLevel,_that.confidence,_that.dayOfWeek,_that.isHoliday,_that.holidayName,_that.yearOverYearChange,_that.weekOverWeekChange,_that.serviceBreakdown,_that.hourlyBreakdown);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime date,  double predictedCount,  double lowerBound,  double upperBound,  DemandLevel demandLevel,  double confidence,  int dayOfWeek,  bool isHoliday,  String? holidayName,  double? yearOverYearChange,  double? weekOverWeekChange,  Map<String, double> serviceBreakdown,  Map<String, double> hourlyBreakdown)  $default,) {final _that = this;
switch (_that) {
case _DemandForecast():
return $default(_that.date,_that.predictedCount,_that.lowerBound,_that.upperBound,_that.demandLevel,_that.confidence,_that.dayOfWeek,_that.isHoliday,_that.holidayName,_that.yearOverYearChange,_that.weekOverWeekChange,_that.serviceBreakdown,_that.hourlyBreakdown);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime date,  double predictedCount,  double lowerBound,  double upperBound,  DemandLevel demandLevel,  double confidence,  int dayOfWeek,  bool isHoliday,  String? holidayName,  double? yearOverYearChange,  double? weekOverWeekChange,  Map<String, double> serviceBreakdown,  Map<String, double> hourlyBreakdown)?  $default,) {final _that = this;
switch (_that) {
case _DemandForecast() when $default != null:
return $default(_that.date,_that.predictedCount,_that.lowerBound,_that.upperBound,_that.demandLevel,_that.confidence,_that.dayOfWeek,_that.isHoliday,_that.holidayName,_that.yearOverYearChange,_that.weekOverWeekChange,_that.serviceBreakdown,_that.hourlyBreakdown);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DemandForecast extends DemandForecast {
  const _DemandForecast({required this.date, required this.predictedCount, required this.lowerBound, required this.upperBound, required this.demandLevel, required this.confidence, required this.dayOfWeek, this.isHoliday = false, this.holidayName, this.yearOverYearChange, this.weekOverWeekChange, final  Map<String, double> serviceBreakdown = const {}, final  Map<String, double> hourlyBreakdown = const {}}): _serviceBreakdown = serviceBreakdown,_hourlyBreakdown = hourlyBreakdown,super._();
  factory _DemandForecast.fromJson(Map<String, dynamic> json) => _$DemandForecastFromJson(json);

/// Date of the forecast.
@override final  DateTime date;
/// Predicted booking count.
@override final  double predictedCount;
/// Lower bound of confidence interval.
@override final  double lowerBound;
/// Upper bound of confidence interval.
@override final  double upperBound;
/// Demand level classification.
@override final  DemandLevel demandLevel;
/// Confidence score (0-1).
@override final  double confidence;
/// Day of week (1=Monday, 7=Sunday).
@override final  int dayOfWeek;
/// Whether this is a holiday.
@override@JsonKey() final  bool isHoliday;
/// Holiday name if applicable.
@override final  String? holidayName;
/// Year-over-year change percentage.
@override final  double? yearOverYearChange;
/// Week-over-week change percentage.
@override final  double? weekOverWeekChange;
/// Breakdown by service type.
 final  Map<String, double> _serviceBreakdown;
/// Breakdown by service type.
@override@JsonKey() Map<String, double> get serviceBreakdown {
  if (_serviceBreakdown is EqualUnmodifiableMapView) return _serviceBreakdown;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_serviceBreakdown);
}

/// Breakdown by time of day.
 final  Map<String, double> _hourlyBreakdown;
/// Breakdown by time of day.
@override@JsonKey() Map<String, double> get hourlyBreakdown {
  if (_hourlyBreakdown is EqualUnmodifiableMapView) return _hourlyBreakdown;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_hourlyBreakdown);
}


/// Create a copy of DemandForecast
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DemandForecastCopyWith<_DemandForecast> get copyWith => __$DemandForecastCopyWithImpl<_DemandForecast>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DemandForecastToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DemandForecast&&(identical(other.date, date) || other.date == date)&&(identical(other.predictedCount, predictedCount) || other.predictedCount == predictedCount)&&(identical(other.lowerBound, lowerBound) || other.lowerBound == lowerBound)&&(identical(other.upperBound, upperBound) || other.upperBound == upperBound)&&(identical(other.demandLevel, demandLevel) || other.demandLevel == demandLevel)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.dayOfWeek, dayOfWeek) || other.dayOfWeek == dayOfWeek)&&(identical(other.isHoliday, isHoliday) || other.isHoliday == isHoliday)&&(identical(other.holidayName, holidayName) || other.holidayName == holidayName)&&(identical(other.yearOverYearChange, yearOverYearChange) || other.yearOverYearChange == yearOverYearChange)&&(identical(other.weekOverWeekChange, weekOverWeekChange) || other.weekOverWeekChange == weekOverWeekChange)&&const DeepCollectionEquality().equals(other._serviceBreakdown, _serviceBreakdown)&&const DeepCollectionEquality().equals(other._hourlyBreakdown, _hourlyBreakdown));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,predictedCount,lowerBound,upperBound,demandLevel,confidence,dayOfWeek,isHoliday,holidayName,yearOverYearChange,weekOverWeekChange,const DeepCollectionEquality().hash(_serviceBreakdown),const DeepCollectionEquality().hash(_hourlyBreakdown));

@override
String toString() {
  return 'DemandForecast(date: $date, predictedCount: $predictedCount, lowerBound: $lowerBound, upperBound: $upperBound, demandLevel: $demandLevel, confidence: $confidence, dayOfWeek: $dayOfWeek, isHoliday: $isHoliday, holidayName: $holidayName, yearOverYearChange: $yearOverYearChange, weekOverWeekChange: $weekOverWeekChange, serviceBreakdown: $serviceBreakdown, hourlyBreakdown: $hourlyBreakdown)';
}


}

/// @nodoc
abstract mixin class _$DemandForecastCopyWith<$Res> implements $DemandForecastCopyWith<$Res> {
  factory _$DemandForecastCopyWith(_DemandForecast value, $Res Function(_DemandForecast) _then) = __$DemandForecastCopyWithImpl;
@override @useResult
$Res call({
 DateTime date, double predictedCount, double lowerBound, double upperBound, DemandLevel demandLevel, double confidence, int dayOfWeek, bool isHoliday, String? holidayName, double? yearOverYearChange, double? weekOverWeekChange, Map<String, double> serviceBreakdown, Map<String, double> hourlyBreakdown
});




}
/// @nodoc
class __$DemandForecastCopyWithImpl<$Res>
    implements _$DemandForecastCopyWith<$Res> {
  __$DemandForecastCopyWithImpl(this._self, this._then);

  final _DemandForecast _self;
  final $Res Function(_DemandForecast) _then;

/// Create a copy of DemandForecast
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? predictedCount = null,Object? lowerBound = null,Object? upperBound = null,Object? demandLevel = null,Object? confidence = null,Object? dayOfWeek = null,Object? isHoliday = null,Object? holidayName = freezed,Object? yearOverYearChange = freezed,Object? weekOverWeekChange = freezed,Object? serviceBreakdown = null,Object? hourlyBreakdown = null,}) {
  return _then(_DemandForecast(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,predictedCount: null == predictedCount ? _self.predictedCount : predictedCount // ignore: cast_nullable_to_non_nullable
as double,lowerBound: null == lowerBound ? _self.lowerBound : lowerBound // ignore: cast_nullable_to_non_nullable
as double,upperBound: null == upperBound ? _self.upperBound : upperBound // ignore: cast_nullable_to_non_nullable
as double,demandLevel: null == demandLevel ? _self.demandLevel : demandLevel // ignore: cast_nullable_to_non_nullable
as DemandLevel,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,dayOfWeek: null == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as int,isHoliday: null == isHoliday ? _self.isHoliday : isHoliday // ignore: cast_nullable_to_non_nullable
as bool,holidayName: freezed == holidayName ? _self.holidayName : holidayName // ignore: cast_nullable_to_non_nullable
as String?,yearOverYearChange: freezed == yearOverYearChange ? _self.yearOverYearChange : yearOverYearChange // ignore: cast_nullable_to_non_nullable
as double?,weekOverWeekChange: freezed == weekOverWeekChange ? _self.weekOverWeekChange : weekOverWeekChange // ignore: cast_nullable_to_non_nullable
as double?,serviceBreakdown: null == serviceBreakdown ? _self._serviceBreakdown : serviceBreakdown // ignore: cast_nullable_to_non_nullable
as Map<String, double>,hourlyBreakdown: null == hourlyBreakdown ? _self._hourlyBreakdown : hourlyBreakdown // ignore: cast_nullable_to_non_nullable
as Map<String, double>,
  ));
}


}


/// @nodoc
mixin _$StaffingRecommendation {

/// Date of recommendation.
 DateTime get date;/// The demand forecast this is based on.
 DemandForecast get forecast;/// Current staff capacity (appointments per day).
 int get currentCapacity;/// Recommended capacity.
 int get recommendedCapacity;/// Recommendation type.
 StaffingAction get action;/// Urgency level (1-5, 5 = most urgent).
 int get urgency;/// Explanation of the recommendation.
 String get reasoning;/// Specific suggestions.
 List<StaffingSuggestion> get suggestions;/// Expected revenue impact.
 double? get revenueImpact;/// Confidence in recommendation (0-1).
 double get confidence;
/// Create a copy of StaffingRecommendation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaffingRecommendationCopyWith<StaffingRecommendation> get copyWith => _$StaffingRecommendationCopyWithImpl<StaffingRecommendation>(this as StaffingRecommendation, _$identity);

  /// Serializes this StaffingRecommendation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaffingRecommendation&&(identical(other.date, date) || other.date == date)&&(identical(other.forecast, forecast) || other.forecast == forecast)&&(identical(other.currentCapacity, currentCapacity) || other.currentCapacity == currentCapacity)&&(identical(other.recommendedCapacity, recommendedCapacity) || other.recommendedCapacity == recommendedCapacity)&&(identical(other.action, action) || other.action == action)&&(identical(other.urgency, urgency) || other.urgency == urgency)&&(identical(other.reasoning, reasoning) || other.reasoning == reasoning)&&const DeepCollectionEquality().equals(other.suggestions, suggestions)&&(identical(other.revenueImpact, revenueImpact) || other.revenueImpact == revenueImpact)&&(identical(other.confidence, confidence) || other.confidence == confidence));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,forecast,currentCapacity,recommendedCapacity,action,urgency,reasoning,const DeepCollectionEquality().hash(suggestions),revenueImpact,confidence);

@override
String toString() {
  return 'StaffingRecommendation(date: $date, forecast: $forecast, currentCapacity: $currentCapacity, recommendedCapacity: $recommendedCapacity, action: $action, urgency: $urgency, reasoning: $reasoning, suggestions: $suggestions, revenueImpact: $revenueImpact, confidence: $confidence)';
}


}

/// @nodoc
abstract mixin class $StaffingRecommendationCopyWith<$Res>  {
  factory $StaffingRecommendationCopyWith(StaffingRecommendation value, $Res Function(StaffingRecommendation) _then) = _$StaffingRecommendationCopyWithImpl;
@useResult
$Res call({
 DateTime date, DemandForecast forecast, int currentCapacity, int recommendedCapacity, StaffingAction action, int urgency, String reasoning, List<StaffingSuggestion> suggestions, double? revenueImpact, double confidence
});


$DemandForecastCopyWith<$Res> get forecast;

}
/// @nodoc
class _$StaffingRecommendationCopyWithImpl<$Res>
    implements $StaffingRecommendationCopyWith<$Res> {
  _$StaffingRecommendationCopyWithImpl(this._self, this._then);

  final StaffingRecommendation _self;
  final $Res Function(StaffingRecommendation) _then;

/// Create a copy of StaffingRecommendation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? forecast = null,Object? currentCapacity = null,Object? recommendedCapacity = null,Object? action = null,Object? urgency = null,Object? reasoning = null,Object? suggestions = null,Object? revenueImpact = freezed,Object? confidence = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,forecast: null == forecast ? _self.forecast : forecast // ignore: cast_nullable_to_non_nullable
as DemandForecast,currentCapacity: null == currentCapacity ? _self.currentCapacity : currentCapacity // ignore: cast_nullable_to_non_nullable
as int,recommendedCapacity: null == recommendedCapacity ? _self.recommendedCapacity : recommendedCapacity // ignore: cast_nullable_to_non_nullable
as int,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as StaffingAction,urgency: null == urgency ? _self.urgency : urgency // ignore: cast_nullable_to_non_nullable
as int,reasoning: null == reasoning ? _self.reasoning : reasoning // ignore: cast_nullable_to_non_nullable
as String,suggestions: null == suggestions ? _self.suggestions : suggestions // ignore: cast_nullable_to_non_nullable
as List<StaffingSuggestion>,revenueImpact: freezed == revenueImpact ? _self.revenueImpact : revenueImpact // ignore: cast_nullable_to_non_nullable
as double?,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,
  ));
}
/// Create a copy of StaffingRecommendation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DemandForecastCopyWith<$Res> get forecast {
  
  return $DemandForecastCopyWith<$Res>(_self.forecast, (value) {
    return _then(_self.copyWith(forecast: value));
  });
}
}


/// Adds pattern-matching-related methods to [StaffingRecommendation].
extension StaffingRecommendationPatterns on StaffingRecommendation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StaffingRecommendation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StaffingRecommendation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StaffingRecommendation value)  $default,){
final _that = this;
switch (_that) {
case _StaffingRecommendation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StaffingRecommendation value)?  $default,){
final _that = this;
switch (_that) {
case _StaffingRecommendation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime date,  DemandForecast forecast,  int currentCapacity,  int recommendedCapacity,  StaffingAction action,  int urgency,  String reasoning,  List<StaffingSuggestion> suggestions,  double? revenueImpact,  double confidence)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StaffingRecommendation() when $default != null:
return $default(_that.date,_that.forecast,_that.currentCapacity,_that.recommendedCapacity,_that.action,_that.urgency,_that.reasoning,_that.suggestions,_that.revenueImpact,_that.confidence);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime date,  DemandForecast forecast,  int currentCapacity,  int recommendedCapacity,  StaffingAction action,  int urgency,  String reasoning,  List<StaffingSuggestion> suggestions,  double? revenueImpact,  double confidence)  $default,) {final _that = this;
switch (_that) {
case _StaffingRecommendation():
return $default(_that.date,_that.forecast,_that.currentCapacity,_that.recommendedCapacity,_that.action,_that.urgency,_that.reasoning,_that.suggestions,_that.revenueImpact,_that.confidence);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime date,  DemandForecast forecast,  int currentCapacity,  int recommendedCapacity,  StaffingAction action,  int urgency,  String reasoning,  List<StaffingSuggestion> suggestions,  double? revenueImpact,  double confidence)?  $default,) {final _that = this;
switch (_that) {
case _StaffingRecommendation() when $default != null:
return $default(_that.date,_that.forecast,_that.currentCapacity,_that.recommendedCapacity,_that.action,_that.urgency,_that.reasoning,_that.suggestions,_that.revenueImpact,_that.confidence);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StaffingRecommendation extends StaffingRecommendation {
  const _StaffingRecommendation({required this.date, required this.forecast, required this.currentCapacity, required this.recommendedCapacity, required this.action, required this.urgency, required this.reasoning, final  List<StaffingSuggestion> suggestions = const [], this.revenueImpact, required this.confidence}): _suggestions = suggestions,super._();
  factory _StaffingRecommendation.fromJson(Map<String, dynamic> json) => _$StaffingRecommendationFromJson(json);

/// Date of recommendation.
@override final  DateTime date;
/// The demand forecast this is based on.
@override final  DemandForecast forecast;
/// Current staff capacity (appointments per day).
@override final  int currentCapacity;
/// Recommended capacity.
@override final  int recommendedCapacity;
/// Recommendation type.
@override final  StaffingAction action;
/// Urgency level (1-5, 5 = most urgent).
@override final  int urgency;
/// Explanation of the recommendation.
@override final  String reasoning;
/// Specific suggestions.
 final  List<StaffingSuggestion> _suggestions;
/// Specific suggestions.
@override@JsonKey() List<StaffingSuggestion> get suggestions {
  if (_suggestions is EqualUnmodifiableListView) return _suggestions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_suggestions);
}

/// Expected revenue impact.
@override final  double? revenueImpact;
/// Confidence in recommendation (0-1).
@override final  double confidence;

/// Create a copy of StaffingRecommendation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaffingRecommendationCopyWith<_StaffingRecommendation> get copyWith => __$StaffingRecommendationCopyWithImpl<_StaffingRecommendation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StaffingRecommendationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StaffingRecommendation&&(identical(other.date, date) || other.date == date)&&(identical(other.forecast, forecast) || other.forecast == forecast)&&(identical(other.currentCapacity, currentCapacity) || other.currentCapacity == currentCapacity)&&(identical(other.recommendedCapacity, recommendedCapacity) || other.recommendedCapacity == recommendedCapacity)&&(identical(other.action, action) || other.action == action)&&(identical(other.urgency, urgency) || other.urgency == urgency)&&(identical(other.reasoning, reasoning) || other.reasoning == reasoning)&&const DeepCollectionEquality().equals(other._suggestions, _suggestions)&&(identical(other.revenueImpact, revenueImpact) || other.revenueImpact == revenueImpact)&&(identical(other.confidence, confidence) || other.confidence == confidence));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,forecast,currentCapacity,recommendedCapacity,action,urgency,reasoning,const DeepCollectionEquality().hash(_suggestions),revenueImpact,confidence);

@override
String toString() {
  return 'StaffingRecommendation(date: $date, forecast: $forecast, currentCapacity: $currentCapacity, recommendedCapacity: $recommendedCapacity, action: $action, urgency: $urgency, reasoning: $reasoning, suggestions: $suggestions, revenueImpact: $revenueImpact, confidence: $confidence)';
}


}

/// @nodoc
abstract mixin class _$StaffingRecommendationCopyWith<$Res> implements $StaffingRecommendationCopyWith<$Res> {
  factory _$StaffingRecommendationCopyWith(_StaffingRecommendation value, $Res Function(_StaffingRecommendation) _then) = __$StaffingRecommendationCopyWithImpl;
@override @useResult
$Res call({
 DateTime date, DemandForecast forecast, int currentCapacity, int recommendedCapacity, StaffingAction action, int urgency, String reasoning, List<StaffingSuggestion> suggestions, double? revenueImpact, double confidence
});


@override $DemandForecastCopyWith<$Res> get forecast;

}
/// @nodoc
class __$StaffingRecommendationCopyWithImpl<$Res>
    implements _$StaffingRecommendationCopyWith<$Res> {
  __$StaffingRecommendationCopyWithImpl(this._self, this._then);

  final _StaffingRecommendation _self;
  final $Res Function(_StaffingRecommendation) _then;

/// Create a copy of StaffingRecommendation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? forecast = null,Object? currentCapacity = null,Object? recommendedCapacity = null,Object? action = null,Object? urgency = null,Object? reasoning = null,Object? suggestions = null,Object? revenueImpact = freezed,Object? confidence = null,}) {
  return _then(_StaffingRecommendation(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,forecast: null == forecast ? _self.forecast : forecast // ignore: cast_nullable_to_non_nullable
as DemandForecast,currentCapacity: null == currentCapacity ? _self.currentCapacity : currentCapacity // ignore: cast_nullable_to_non_nullable
as int,recommendedCapacity: null == recommendedCapacity ? _self.recommendedCapacity : recommendedCapacity // ignore: cast_nullable_to_non_nullable
as int,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as StaffingAction,urgency: null == urgency ? _self.urgency : urgency // ignore: cast_nullable_to_non_nullable
as int,reasoning: null == reasoning ? _self.reasoning : reasoning // ignore: cast_nullable_to_non_nullable
as String,suggestions: null == suggestions ? _self._suggestions : suggestions // ignore: cast_nullable_to_non_nullable
as List<StaffingSuggestion>,revenueImpact: freezed == revenueImpact ? _self.revenueImpact : revenueImpact // ignore: cast_nullable_to_non_nullable
as double?,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

/// Create a copy of StaffingRecommendation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DemandForecastCopyWith<$Res> get forecast {
  
  return $DemandForecastCopyWith<$Res>(_self.forecast, (value) {
    return _then(_self.copyWith(forecast: value));
  });
}
}


/// @nodoc
mixin _$StaffingSuggestion {

/// Suggestion type.
 String get type;/// Description.
 String get description;/// Priority (1-5).
 int get priority;/// Estimated impact.
 String? get impact;/// Action to take.
 String? get actionUrl;
/// Create a copy of StaffingSuggestion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaffingSuggestionCopyWith<StaffingSuggestion> get copyWith => _$StaffingSuggestionCopyWithImpl<StaffingSuggestion>(this as StaffingSuggestion, _$identity);

  /// Serializes this StaffingSuggestion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaffingSuggestion&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.impact, impact) || other.impact == impact)&&(identical(other.actionUrl, actionUrl) || other.actionUrl == actionUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,description,priority,impact,actionUrl);

@override
String toString() {
  return 'StaffingSuggestion(type: $type, description: $description, priority: $priority, impact: $impact, actionUrl: $actionUrl)';
}


}

/// @nodoc
abstract mixin class $StaffingSuggestionCopyWith<$Res>  {
  factory $StaffingSuggestionCopyWith(StaffingSuggestion value, $Res Function(StaffingSuggestion) _then) = _$StaffingSuggestionCopyWithImpl;
@useResult
$Res call({
 String type, String description, int priority, String? impact, String? actionUrl
});




}
/// @nodoc
class _$StaffingSuggestionCopyWithImpl<$Res>
    implements $StaffingSuggestionCopyWith<$Res> {
  _$StaffingSuggestionCopyWithImpl(this._self, this._then);

  final StaffingSuggestion _self;
  final $Res Function(StaffingSuggestion) _then;

/// Create a copy of StaffingSuggestion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? description = null,Object? priority = null,Object? impact = freezed,Object? actionUrl = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,impact: freezed == impact ? _self.impact : impact // ignore: cast_nullable_to_non_nullable
as String?,actionUrl: freezed == actionUrl ? _self.actionUrl : actionUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [StaffingSuggestion].
extension StaffingSuggestionPatterns on StaffingSuggestion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StaffingSuggestion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StaffingSuggestion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StaffingSuggestion value)  $default,){
final _that = this;
switch (_that) {
case _StaffingSuggestion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StaffingSuggestion value)?  $default,){
final _that = this;
switch (_that) {
case _StaffingSuggestion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  String description,  int priority,  String? impact,  String? actionUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StaffingSuggestion() when $default != null:
return $default(_that.type,_that.description,_that.priority,_that.impact,_that.actionUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  String description,  int priority,  String? impact,  String? actionUrl)  $default,) {final _that = this;
switch (_that) {
case _StaffingSuggestion():
return $default(_that.type,_that.description,_that.priority,_that.impact,_that.actionUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  String description,  int priority,  String? impact,  String? actionUrl)?  $default,) {final _that = this;
switch (_that) {
case _StaffingSuggestion() when $default != null:
return $default(_that.type,_that.description,_that.priority,_that.impact,_that.actionUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StaffingSuggestion implements StaffingSuggestion {
  const _StaffingSuggestion({required this.type, required this.description, required this.priority, this.impact, this.actionUrl});
  factory _StaffingSuggestion.fromJson(Map<String, dynamic> json) => _$StaffingSuggestionFromJson(json);

/// Suggestion type.
@override final  String type;
/// Description.
@override final  String description;
/// Priority (1-5).
@override final  int priority;
/// Estimated impact.
@override final  String? impact;
/// Action to take.
@override final  String? actionUrl;

/// Create a copy of StaffingSuggestion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaffingSuggestionCopyWith<_StaffingSuggestion> get copyWith => __$StaffingSuggestionCopyWithImpl<_StaffingSuggestion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StaffingSuggestionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StaffingSuggestion&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.impact, impact) || other.impact == impact)&&(identical(other.actionUrl, actionUrl) || other.actionUrl == actionUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,description,priority,impact,actionUrl);

@override
String toString() {
  return 'StaffingSuggestion(type: $type, description: $description, priority: $priority, impact: $impact, actionUrl: $actionUrl)';
}


}

/// @nodoc
abstract mixin class _$StaffingSuggestionCopyWith<$Res> implements $StaffingSuggestionCopyWith<$Res> {
  factory _$StaffingSuggestionCopyWith(_StaffingSuggestion value, $Res Function(_StaffingSuggestion) _then) = __$StaffingSuggestionCopyWithImpl;
@override @useResult
$Res call({
 String type, String description, int priority, String? impact, String? actionUrl
});




}
/// @nodoc
class __$StaffingSuggestionCopyWithImpl<$Res>
    implements _$StaffingSuggestionCopyWith<$Res> {
  __$StaffingSuggestionCopyWithImpl(this._self, this._then);

  final _StaffingSuggestion _self;
  final $Res Function(_StaffingSuggestion) _then;

/// Create a copy of StaffingSuggestion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? description = null,Object? priority = null,Object? impact = freezed,Object? actionUrl = freezed,}) {
  return _then(_StaffingSuggestion(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,impact: freezed == impact ? _self.impact : impact // ignore: cast_nullable_to_non_nullable
as String?,actionUrl: freezed == actionUrl ? _self.actionUrl : actionUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$DemandForecastResult {

/// Business ID.
 String get businessId;/// Location ID (if specific).
 String? get locationId;/// Service ID (if specific).
 String? get serviceId;/// Start date of forecast.
 DateTime get startDate;/// End date of forecast.
 DateTime get endDate;/// Daily forecasts.
 List<DemandForecast> get forecasts;/// Staffing recommendations.
 List<StaffingRecommendation> get staffingRecommendations;/// When this forecast was generated.
 DateTime get generatedAt;/// Model version used.
 String? get modelVersion;/// Average daily demand in forecast period.
 double get averageDemand;/// Peak demand day.
 DemandForecast? get peakDay;/// Lowest demand day.
 DemandForecast? get valleyDay;/// Days with high/very high demand.
 List<DemandForecast> get highDemandDays;/// Days needing attention (urgent staffing).
 List<StaffingRecommendation> get urgentDays;
/// Create a copy of DemandForecastResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DemandForecastResultCopyWith<DemandForecastResult> get copyWith => _$DemandForecastResultCopyWithImpl<DemandForecastResult>(this as DemandForecastResult, _$identity);

  /// Serializes this DemandForecastResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DemandForecastResult&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.locationId, locationId) || other.locationId == locationId)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&const DeepCollectionEquality().equals(other.forecasts, forecasts)&&const DeepCollectionEquality().equals(other.staffingRecommendations, staffingRecommendations)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.modelVersion, modelVersion) || other.modelVersion == modelVersion)&&(identical(other.averageDemand, averageDemand) || other.averageDemand == averageDemand)&&(identical(other.peakDay, peakDay) || other.peakDay == peakDay)&&(identical(other.valleyDay, valleyDay) || other.valleyDay == valleyDay)&&const DeepCollectionEquality().equals(other.highDemandDays, highDemandDays)&&const DeepCollectionEquality().equals(other.urgentDays, urgentDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,businessId,locationId,serviceId,startDate,endDate,const DeepCollectionEquality().hash(forecasts),const DeepCollectionEquality().hash(staffingRecommendations),generatedAt,modelVersion,averageDemand,peakDay,valleyDay,const DeepCollectionEquality().hash(highDemandDays),const DeepCollectionEquality().hash(urgentDays));

@override
String toString() {
  return 'DemandForecastResult(businessId: $businessId, locationId: $locationId, serviceId: $serviceId, startDate: $startDate, endDate: $endDate, forecasts: $forecasts, staffingRecommendations: $staffingRecommendations, generatedAt: $generatedAt, modelVersion: $modelVersion, averageDemand: $averageDemand, peakDay: $peakDay, valleyDay: $valleyDay, highDemandDays: $highDemandDays, urgentDays: $urgentDays)';
}


}

/// @nodoc
abstract mixin class $DemandForecastResultCopyWith<$Res>  {
  factory $DemandForecastResultCopyWith(DemandForecastResult value, $Res Function(DemandForecastResult) _then) = _$DemandForecastResultCopyWithImpl;
@useResult
$Res call({
 String businessId, String? locationId, String? serviceId, DateTime startDate, DateTime endDate, List<DemandForecast> forecasts, List<StaffingRecommendation> staffingRecommendations, DateTime generatedAt, String? modelVersion, double averageDemand, DemandForecast? peakDay, DemandForecast? valleyDay, List<DemandForecast> highDemandDays, List<StaffingRecommendation> urgentDays
});


$DemandForecastCopyWith<$Res>? get peakDay;$DemandForecastCopyWith<$Res>? get valleyDay;

}
/// @nodoc
class _$DemandForecastResultCopyWithImpl<$Res>
    implements $DemandForecastResultCopyWith<$Res> {
  _$DemandForecastResultCopyWithImpl(this._self, this._then);

  final DemandForecastResult _self;
  final $Res Function(DemandForecastResult) _then;

/// Create a copy of DemandForecastResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? businessId = null,Object? locationId = freezed,Object? serviceId = freezed,Object? startDate = null,Object? endDate = null,Object? forecasts = null,Object? staffingRecommendations = null,Object? generatedAt = null,Object? modelVersion = freezed,Object? averageDemand = null,Object? peakDay = freezed,Object? valleyDay = freezed,Object? highDemandDays = null,Object? urgentDays = null,}) {
  return _then(_self.copyWith(
businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,locationId: freezed == locationId ? _self.locationId : locationId // ignore: cast_nullable_to_non_nullable
as String?,serviceId: freezed == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String?,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,forecasts: null == forecasts ? _self.forecasts : forecasts // ignore: cast_nullable_to_non_nullable
as List<DemandForecast>,staffingRecommendations: null == staffingRecommendations ? _self.staffingRecommendations : staffingRecommendations // ignore: cast_nullable_to_non_nullable
as List<StaffingRecommendation>,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,modelVersion: freezed == modelVersion ? _self.modelVersion : modelVersion // ignore: cast_nullable_to_non_nullable
as String?,averageDemand: null == averageDemand ? _self.averageDemand : averageDemand // ignore: cast_nullable_to_non_nullable
as double,peakDay: freezed == peakDay ? _self.peakDay : peakDay // ignore: cast_nullable_to_non_nullable
as DemandForecast?,valleyDay: freezed == valleyDay ? _self.valleyDay : valleyDay // ignore: cast_nullable_to_non_nullable
as DemandForecast?,highDemandDays: null == highDemandDays ? _self.highDemandDays : highDemandDays // ignore: cast_nullable_to_non_nullable
as List<DemandForecast>,urgentDays: null == urgentDays ? _self.urgentDays : urgentDays // ignore: cast_nullable_to_non_nullable
as List<StaffingRecommendation>,
  ));
}
/// Create a copy of DemandForecastResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DemandForecastCopyWith<$Res>? get peakDay {
    if (_self.peakDay == null) {
    return null;
  }

  return $DemandForecastCopyWith<$Res>(_self.peakDay!, (value) {
    return _then(_self.copyWith(peakDay: value));
  });
}/// Create a copy of DemandForecastResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DemandForecastCopyWith<$Res>? get valleyDay {
    if (_self.valleyDay == null) {
    return null;
  }

  return $DemandForecastCopyWith<$Res>(_self.valleyDay!, (value) {
    return _then(_self.copyWith(valleyDay: value));
  });
}
}


/// Adds pattern-matching-related methods to [DemandForecastResult].
extension DemandForecastResultPatterns on DemandForecastResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DemandForecastResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DemandForecastResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DemandForecastResult value)  $default,){
final _that = this;
switch (_that) {
case _DemandForecastResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DemandForecastResult value)?  $default,){
final _that = this;
switch (_that) {
case _DemandForecastResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String businessId,  String? locationId,  String? serviceId,  DateTime startDate,  DateTime endDate,  List<DemandForecast> forecasts,  List<StaffingRecommendation> staffingRecommendations,  DateTime generatedAt,  String? modelVersion,  double averageDemand,  DemandForecast? peakDay,  DemandForecast? valleyDay,  List<DemandForecast> highDemandDays,  List<StaffingRecommendation> urgentDays)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DemandForecastResult() when $default != null:
return $default(_that.businessId,_that.locationId,_that.serviceId,_that.startDate,_that.endDate,_that.forecasts,_that.staffingRecommendations,_that.generatedAt,_that.modelVersion,_that.averageDemand,_that.peakDay,_that.valleyDay,_that.highDemandDays,_that.urgentDays);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String businessId,  String? locationId,  String? serviceId,  DateTime startDate,  DateTime endDate,  List<DemandForecast> forecasts,  List<StaffingRecommendation> staffingRecommendations,  DateTime generatedAt,  String? modelVersion,  double averageDemand,  DemandForecast? peakDay,  DemandForecast? valleyDay,  List<DemandForecast> highDemandDays,  List<StaffingRecommendation> urgentDays)  $default,) {final _that = this;
switch (_that) {
case _DemandForecastResult():
return $default(_that.businessId,_that.locationId,_that.serviceId,_that.startDate,_that.endDate,_that.forecasts,_that.staffingRecommendations,_that.generatedAt,_that.modelVersion,_that.averageDemand,_that.peakDay,_that.valleyDay,_that.highDemandDays,_that.urgentDays);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String businessId,  String? locationId,  String? serviceId,  DateTime startDate,  DateTime endDate,  List<DemandForecast> forecasts,  List<StaffingRecommendation> staffingRecommendations,  DateTime generatedAt,  String? modelVersion,  double averageDemand,  DemandForecast? peakDay,  DemandForecast? valleyDay,  List<DemandForecast> highDemandDays,  List<StaffingRecommendation> urgentDays)?  $default,) {final _that = this;
switch (_that) {
case _DemandForecastResult() when $default != null:
return $default(_that.businessId,_that.locationId,_that.serviceId,_that.startDate,_that.endDate,_that.forecasts,_that.staffingRecommendations,_that.generatedAt,_that.modelVersion,_that.averageDemand,_that.peakDay,_that.valleyDay,_that.highDemandDays,_that.urgentDays);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DemandForecastResult extends DemandForecastResult {
  const _DemandForecastResult({required this.businessId, this.locationId, this.serviceId, required this.startDate, required this.endDate, required final  List<DemandForecast> forecasts, final  List<StaffingRecommendation> staffingRecommendations = const [], required this.generatedAt, this.modelVersion, required this.averageDemand, this.peakDay, this.valleyDay, final  List<DemandForecast> highDemandDays = const [], final  List<StaffingRecommendation> urgentDays = const []}): _forecasts = forecasts,_staffingRecommendations = staffingRecommendations,_highDemandDays = highDemandDays,_urgentDays = urgentDays,super._();
  factory _DemandForecastResult.fromJson(Map<String, dynamic> json) => _$DemandForecastResultFromJson(json);

/// Business ID.
@override final  String businessId;
/// Location ID (if specific).
@override final  String? locationId;
/// Service ID (if specific).
@override final  String? serviceId;
/// Start date of forecast.
@override final  DateTime startDate;
/// End date of forecast.
@override final  DateTime endDate;
/// Daily forecasts.
 final  List<DemandForecast> _forecasts;
/// Daily forecasts.
@override List<DemandForecast> get forecasts {
  if (_forecasts is EqualUnmodifiableListView) return _forecasts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_forecasts);
}

/// Staffing recommendations.
 final  List<StaffingRecommendation> _staffingRecommendations;
/// Staffing recommendations.
@override@JsonKey() List<StaffingRecommendation> get staffingRecommendations {
  if (_staffingRecommendations is EqualUnmodifiableListView) return _staffingRecommendations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_staffingRecommendations);
}

/// When this forecast was generated.
@override final  DateTime generatedAt;
/// Model version used.
@override final  String? modelVersion;
/// Average daily demand in forecast period.
@override final  double averageDemand;
/// Peak demand day.
@override final  DemandForecast? peakDay;
/// Lowest demand day.
@override final  DemandForecast? valleyDay;
/// Days with high/very high demand.
 final  List<DemandForecast> _highDemandDays;
/// Days with high/very high demand.
@override@JsonKey() List<DemandForecast> get highDemandDays {
  if (_highDemandDays is EqualUnmodifiableListView) return _highDemandDays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_highDemandDays);
}

/// Days needing attention (urgent staffing).
 final  List<StaffingRecommendation> _urgentDays;
/// Days needing attention (urgent staffing).
@override@JsonKey() List<StaffingRecommendation> get urgentDays {
  if (_urgentDays is EqualUnmodifiableListView) return _urgentDays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_urgentDays);
}


/// Create a copy of DemandForecastResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DemandForecastResultCopyWith<_DemandForecastResult> get copyWith => __$DemandForecastResultCopyWithImpl<_DemandForecastResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DemandForecastResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DemandForecastResult&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.locationId, locationId) || other.locationId == locationId)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&const DeepCollectionEquality().equals(other._forecasts, _forecasts)&&const DeepCollectionEquality().equals(other._staffingRecommendations, _staffingRecommendations)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.modelVersion, modelVersion) || other.modelVersion == modelVersion)&&(identical(other.averageDemand, averageDemand) || other.averageDemand == averageDemand)&&(identical(other.peakDay, peakDay) || other.peakDay == peakDay)&&(identical(other.valleyDay, valleyDay) || other.valleyDay == valleyDay)&&const DeepCollectionEquality().equals(other._highDemandDays, _highDemandDays)&&const DeepCollectionEquality().equals(other._urgentDays, _urgentDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,businessId,locationId,serviceId,startDate,endDate,const DeepCollectionEquality().hash(_forecasts),const DeepCollectionEquality().hash(_staffingRecommendations),generatedAt,modelVersion,averageDemand,peakDay,valleyDay,const DeepCollectionEquality().hash(_highDemandDays),const DeepCollectionEquality().hash(_urgentDays));

@override
String toString() {
  return 'DemandForecastResult(businessId: $businessId, locationId: $locationId, serviceId: $serviceId, startDate: $startDate, endDate: $endDate, forecasts: $forecasts, staffingRecommendations: $staffingRecommendations, generatedAt: $generatedAt, modelVersion: $modelVersion, averageDemand: $averageDemand, peakDay: $peakDay, valleyDay: $valleyDay, highDemandDays: $highDemandDays, urgentDays: $urgentDays)';
}


}

/// @nodoc
abstract mixin class _$DemandForecastResultCopyWith<$Res> implements $DemandForecastResultCopyWith<$Res> {
  factory _$DemandForecastResultCopyWith(_DemandForecastResult value, $Res Function(_DemandForecastResult) _then) = __$DemandForecastResultCopyWithImpl;
@override @useResult
$Res call({
 String businessId, String? locationId, String? serviceId, DateTime startDate, DateTime endDate, List<DemandForecast> forecasts, List<StaffingRecommendation> staffingRecommendations, DateTime generatedAt, String? modelVersion, double averageDemand, DemandForecast? peakDay, DemandForecast? valleyDay, List<DemandForecast> highDemandDays, List<StaffingRecommendation> urgentDays
});


@override $DemandForecastCopyWith<$Res>? get peakDay;@override $DemandForecastCopyWith<$Res>? get valleyDay;

}
/// @nodoc
class __$DemandForecastResultCopyWithImpl<$Res>
    implements _$DemandForecastResultCopyWith<$Res> {
  __$DemandForecastResultCopyWithImpl(this._self, this._then);

  final _DemandForecastResult _self;
  final $Res Function(_DemandForecastResult) _then;

/// Create a copy of DemandForecastResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? businessId = null,Object? locationId = freezed,Object? serviceId = freezed,Object? startDate = null,Object? endDate = null,Object? forecasts = null,Object? staffingRecommendations = null,Object? generatedAt = null,Object? modelVersion = freezed,Object? averageDemand = null,Object? peakDay = freezed,Object? valleyDay = freezed,Object? highDemandDays = null,Object? urgentDays = null,}) {
  return _then(_DemandForecastResult(
businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,locationId: freezed == locationId ? _self.locationId : locationId // ignore: cast_nullable_to_non_nullable
as String?,serviceId: freezed == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String?,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,forecasts: null == forecasts ? _self._forecasts : forecasts // ignore: cast_nullable_to_non_nullable
as List<DemandForecast>,staffingRecommendations: null == staffingRecommendations ? _self._staffingRecommendations : staffingRecommendations // ignore: cast_nullable_to_non_nullable
as List<StaffingRecommendation>,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,modelVersion: freezed == modelVersion ? _self.modelVersion : modelVersion // ignore: cast_nullable_to_non_nullable
as String?,averageDemand: null == averageDemand ? _self.averageDemand : averageDemand // ignore: cast_nullable_to_non_nullable
as double,peakDay: freezed == peakDay ? _self.peakDay : peakDay // ignore: cast_nullable_to_non_nullable
as DemandForecast?,valleyDay: freezed == valleyDay ? _self.valleyDay : valleyDay // ignore: cast_nullable_to_non_nullable
as DemandForecast?,highDemandDays: null == highDemandDays ? _self._highDemandDays : highDemandDays // ignore: cast_nullable_to_non_nullable
as List<DemandForecast>,urgentDays: null == urgentDays ? _self._urgentDays : urgentDays // ignore: cast_nullable_to_non_nullable
as List<StaffingRecommendation>,
  ));
}

/// Create a copy of DemandForecastResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DemandForecastCopyWith<$Res>? get peakDay {
    if (_self.peakDay == null) {
    return null;
  }

  return $DemandForecastCopyWith<$Res>(_self.peakDay!, (value) {
    return _then(_self.copyWith(peakDay: value));
  });
}/// Create a copy of DemandForecastResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DemandForecastCopyWith<$Res>? get valleyDay {
    if (_self.valleyDay == null) {
    return null;
  }

  return $DemandForecastCopyWith<$Res>(_self.valleyDay!, (value) {
    return _then(_self.copyWith(valleyDay: value));
  });
}
}


/// @nodoc
mixin _$DemandForecastRequest {

/// Business ID.
 String get businessId;/// Location ID (optional, for specific location).
 String? get locationId;/// Service ID (optional, for specific service).
 String? get serviceId;/// Start date for forecast.
 DateTime get startDate;/// Number of days to forecast.
 int get forecastDays;/// Include staffing recommendations.
 bool get includeStaffing;/// Current staff capacity per day.
 int? get currentCapacity;/// Include hourly breakdown.
 bool get includeHourly;/// Include service breakdown.
 bool get includeServiceBreakdown;
/// Create a copy of DemandForecastRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DemandForecastRequestCopyWith<DemandForecastRequest> get copyWith => _$DemandForecastRequestCopyWithImpl<DemandForecastRequest>(this as DemandForecastRequest, _$identity);

  /// Serializes this DemandForecastRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DemandForecastRequest&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.locationId, locationId) || other.locationId == locationId)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.forecastDays, forecastDays) || other.forecastDays == forecastDays)&&(identical(other.includeStaffing, includeStaffing) || other.includeStaffing == includeStaffing)&&(identical(other.currentCapacity, currentCapacity) || other.currentCapacity == currentCapacity)&&(identical(other.includeHourly, includeHourly) || other.includeHourly == includeHourly)&&(identical(other.includeServiceBreakdown, includeServiceBreakdown) || other.includeServiceBreakdown == includeServiceBreakdown));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,businessId,locationId,serviceId,startDate,forecastDays,includeStaffing,currentCapacity,includeHourly,includeServiceBreakdown);

@override
String toString() {
  return 'DemandForecastRequest(businessId: $businessId, locationId: $locationId, serviceId: $serviceId, startDate: $startDate, forecastDays: $forecastDays, includeStaffing: $includeStaffing, currentCapacity: $currentCapacity, includeHourly: $includeHourly, includeServiceBreakdown: $includeServiceBreakdown)';
}


}

/// @nodoc
abstract mixin class $DemandForecastRequestCopyWith<$Res>  {
  factory $DemandForecastRequestCopyWith(DemandForecastRequest value, $Res Function(DemandForecastRequest) _then) = _$DemandForecastRequestCopyWithImpl;
@useResult
$Res call({
 String businessId, String? locationId, String? serviceId, DateTime startDate, int forecastDays, bool includeStaffing, int? currentCapacity, bool includeHourly, bool includeServiceBreakdown
});




}
/// @nodoc
class _$DemandForecastRequestCopyWithImpl<$Res>
    implements $DemandForecastRequestCopyWith<$Res> {
  _$DemandForecastRequestCopyWithImpl(this._self, this._then);

  final DemandForecastRequest _self;
  final $Res Function(DemandForecastRequest) _then;

/// Create a copy of DemandForecastRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? businessId = null,Object? locationId = freezed,Object? serviceId = freezed,Object? startDate = null,Object? forecastDays = null,Object? includeStaffing = null,Object? currentCapacity = freezed,Object? includeHourly = null,Object? includeServiceBreakdown = null,}) {
  return _then(_self.copyWith(
businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,locationId: freezed == locationId ? _self.locationId : locationId // ignore: cast_nullable_to_non_nullable
as String?,serviceId: freezed == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String?,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,forecastDays: null == forecastDays ? _self.forecastDays : forecastDays // ignore: cast_nullable_to_non_nullable
as int,includeStaffing: null == includeStaffing ? _self.includeStaffing : includeStaffing // ignore: cast_nullable_to_non_nullable
as bool,currentCapacity: freezed == currentCapacity ? _self.currentCapacity : currentCapacity // ignore: cast_nullable_to_non_nullable
as int?,includeHourly: null == includeHourly ? _self.includeHourly : includeHourly // ignore: cast_nullable_to_non_nullable
as bool,includeServiceBreakdown: null == includeServiceBreakdown ? _self.includeServiceBreakdown : includeServiceBreakdown // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DemandForecastRequest].
extension DemandForecastRequestPatterns on DemandForecastRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DemandForecastRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DemandForecastRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DemandForecastRequest value)  $default,){
final _that = this;
switch (_that) {
case _DemandForecastRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DemandForecastRequest value)?  $default,){
final _that = this;
switch (_that) {
case _DemandForecastRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String businessId,  String? locationId,  String? serviceId,  DateTime startDate,  int forecastDays,  bool includeStaffing,  int? currentCapacity,  bool includeHourly,  bool includeServiceBreakdown)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DemandForecastRequest() when $default != null:
return $default(_that.businessId,_that.locationId,_that.serviceId,_that.startDate,_that.forecastDays,_that.includeStaffing,_that.currentCapacity,_that.includeHourly,_that.includeServiceBreakdown);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String businessId,  String? locationId,  String? serviceId,  DateTime startDate,  int forecastDays,  bool includeStaffing,  int? currentCapacity,  bool includeHourly,  bool includeServiceBreakdown)  $default,) {final _that = this;
switch (_that) {
case _DemandForecastRequest():
return $default(_that.businessId,_that.locationId,_that.serviceId,_that.startDate,_that.forecastDays,_that.includeStaffing,_that.currentCapacity,_that.includeHourly,_that.includeServiceBreakdown);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String businessId,  String? locationId,  String? serviceId,  DateTime startDate,  int forecastDays,  bool includeStaffing,  int? currentCapacity,  bool includeHourly,  bool includeServiceBreakdown)?  $default,) {final _that = this;
switch (_that) {
case _DemandForecastRequest() when $default != null:
return $default(_that.businessId,_that.locationId,_that.serviceId,_that.startDate,_that.forecastDays,_that.includeStaffing,_that.currentCapacity,_that.includeHourly,_that.includeServiceBreakdown);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DemandForecastRequest implements DemandForecastRequest {
  const _DemandForecastRequest({required this.businessId, this.locationId, this.serviceId, required this.startDate, this.forecastDays = 30, this.includeStaffing = true, this.currentCapacity, this.includeHourly = false, this.includeServiceBreakdown = false});
  factory _DemandForecastRequest.fromJson(Map<String, dynamic> json) => _$DemandForecastRequestFromJson(json);

/// Business ID.
@override final  String businessId;
/// Location ID (optional, for specific location).
@override final  String? locationId;
/// Service ID (optional, for specific service).
@override final  String? serviceId;
/// Start date for forecast.
@override final  DateTime startDate;
/// Number of days to forecast.
@override@JsonKey() final  int forecastDays;
/// Include staffing recommendations.
@override@JsonKey() final  bool includeStaffing;
/// Current staff capacity per day.
@override final  int? currentCapacity;
/// Include hourly breakdown.
@override@JsonKey() final  bool includeHourly;
/// Include service breakdown.
@override@JsonKey() final  bool includeServiceBreakdown;

/// Create a copy of DemandForecastRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DemandForecastRequestCopyWith<_DemandForecastRequest> get copyWith => __$DemandForecastRequestCopyWithImpl<_DemandForecastRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DemandForecastRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DemandForecastRequest&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.locationId, locationId) || other.locationId == locationId)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.forecastDays, forecastDays) || other.forecastDays == forecastDays)&&(identical(other.includeStaffing, includeStaffing) || other.includeStaffing == includeStaffing)&&(identical(other.currentCapacity, currentCapacity) || other.currentCapacity == currentCapacity)&&(identical(other.includeHourly, includeHourly) || other.includeHourly == includeHourly)&&(identical(other.includeServiceBreakdown, includeServiceBreakdown) || other.includeServiceBreakdown == includeServiceBreakdown));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,businessId,locationId,serviceId,startDate,forecastDays,includeStaffing,currentCapacity,includeHourly,includeServiceBreakdown);

@override
String toString() {
  return 'DemandForecastRequest(businessId: $businessId, locationId: $locationId, serviceId: $serviceId, startDate: $startDate, forecastDays: $forecastDays, includeStaffing: $includeStaffing, currentCapacity: $currentCapacity, includeHourly: $includeHourly, includeServiceBreakdown: $includeServiceBreakdown)';
}


}

/// @nodoc
abstract mixin class _$DemandForecastRequestCopyWith<$Res> implements $DemandForecastRequestCopyWith<$Res> {
  factory _$DemandForecastRequestCopyWith(_DemandForecastRequest value, $Res Function(_DemandForecastRequest) _then) = __$DemandForecastRequestCopyWithImpl;
@override @useResult
$Res call({
 String businessId, String? locationId, String? serviceId, DateTime startDate, int forecastDays, bool includeStaffing, int? currentCapacity, bool includeHourly, bool includeServiceBreakdown
});




}
/// @nodoc
class __$DemandForecastRequestCopyWithImpl<$Res>
    implements _$DemandForecastRequestCopyWith<$Res> {
  __$DemandForecastRequestCopyWithImpl(this._self, this._then);

  final _DemandForecastRequest _self;
  final $Res Function(_DemandForecastRequest) _then;

/// Create a copy of DemandForecastRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? businessId = null,Object? locationId = freezed,Object? serviceId = freezed,Object? startDate = null,Object? forecastDays = null,Object? includeStaffing = null,Object? currentCapacity = freezed,Object? includeHourly = null,Object? includeServiceBreakdown = null,}) {
  return _then(_DemandForecastRequest(
businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,locationId: freezed == locationId ? _self.locationId : locationId // ignore: cast_nullable_to_non_nullable
as String?,serviceId: freezed == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String?,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,forecastDays: null == forecastDays ? _self.forecastDays : forecastDays // ignore: cast_nullable_to_non_nullable
as int,includeStaffing: null == includeStaffing ? _self.includeStaffing : includeStaffing // ignore: cast_nullable_to_non_nullable
as bool,currentCapacity: freezed == currentCapacity ? _self.currentCapacity : currentCapacity // ignore: cast_nullable_to_non_nullable
as int?,includeHourly: null == includeHourly ? _self.includeHourly : includeHourly // ignore: cast_nullable_to_non_nullable
as bool,includeServiceBreakdown: null == includeServiceBreakdown ? _self.includeServiceBreakdown : includeServiceBreakdown // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
