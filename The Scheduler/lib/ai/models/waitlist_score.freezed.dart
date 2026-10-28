// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'waitlist_score.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WaitlistScore {

/// Overall match score (0-100).
 double get overallScore;/// Time flexibility score (0-30).
/// Higher if entry's preferred times match the slot.
 double get timeFlexibilityScore;/// Geographic proximity score (0-20).
/// For mobile services, closer clients score higher.
 double get proximityScore;/// Historical confirm rate score (0-30).
/// Based on client's past waitlist offer acceptance rate.
 double get confirmRateScore;/// Revenue priority score (0-10).
/// Higher-value services or loyal clients score higher.
 double get revenueScore;/// Wait time fairness score (0-10).
/// Longer wait = higher priority (fairness factor).
 double get fairnessScore;/// Individual factor details for UI display.
 List<WaitlistScoreFactor> get factors;
/// Create a copy of WaitlistScore
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WaitlistScoreCopyWith<WaitlistScore> get copyWith => _$WaitlistScoreCopyWithImpl<WaitlistScore>(this as WaitlistScore, _$identity);

  /// Serializes this WaitlistScore to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WaitlistScore&&(identical(other.overallScore, overallScore) || other.overallScore == overallScore)&&(identical(other.timeFlexibilityScore, timeFlexibilityScore) || other.timeFlexibilityScore == timeFlexibilityScore)&&(identical(other.proximityScore, proximityScore) || other.proximityScore == proximityScore)&&(identical(other.confirmRateScore, confirmRateScore) || other.confirmRateScore == confirmRateScore)&&(identical(other.revenueScore, revenueScore) || other.revenueScore == revenueScore)&&(identical(other.fairnessScore, fairnessScore) || other.fairnessScore == fairnessScore)&&const DeepCollectionEquality().equals(other.factors, factors));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,overallScore,timeFlexibilityScore,proximityScore,confirmRateScore,revenueScore,fairnessScore,const DeepCollectionEquality().hash(factors));

@override
String toString() {
  return 'WaitlistScore(overallScore: $overallScore, timeFlexibilityScore: $timeFlexibilityScore, proximityScore: $proximityScore, confirmRateScore: $confirmRateScore, revenueScore: $revenueScore, fairnessScore: $fairnessScore, factors: $factors)';
}


}

/// @nodoc
abstract mixin class $WaitlistScoreCopyWith<$Res>  {
  factory $WaitlistScoreCopyWith(WaitlistScore value, $Res Function(WaitlistScore) _then) = _$WaitlistScoreCopyWithImpl;
@useResult
$Res call({
 double overallScore, double timeFlexibilityScore, double proximityScore, double confirmRateScore, double revenueScore, double fairnessScore, List<WaitlistScoreFactor> factors
});




}
/// @nodoc
class _$WaitlistScoreCopyWithImpl<$Res>
    implements $WaitlistScoreCopyWith<$Res> {
  _$WaitlistScoreCopyWithImpl(this._self, this._then);

  final WaitlistScore _self;
  final $Res Function(WaitlistScore) _then;

/// Create a copy of WaitlistScore
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? overallScore = null,Object? timeFlexibilityScore = null,Object? proximityScore = null,Object? confirmRateScore = null,Object? revenueScore = null,Object? fairnessScore = null,Object? factors = null,}) {
  return _then(_self.copyWith(
overallScore: null == overallScore ? _self.overallScore : overallScore // ignore: cast_nullable_to_non_nullable
as double,timeFlexibilityScore: null == timeFlexibilityScore ? _self.timeFlexibilityScore : timeFlexibilityScore // ignore: cast_nullable_to_non_nullable
as double,proximityScore: null == proximityScore ? _self.proximityScore : proximityScore // ignore: cast_nullable_to_non_nullable
as double,confirmRateScore: null == confirmRateScore ? _self.confirmRateScore : confirmRateScore // ignore: cast_nullable_to_non_nullable
as double,revenueScore: null == revenueScore ? _self.revenueScore : revenueScore // ignore: cast_nullable_to_non_nullable
as double,fairnessScore: null == fairnessScore ? _self.fairnessScore : fairnessScore // ignore: cast_nullable_to_non_nullable
as double,factors: null == factors ? _self.factors : factors // ignore: cast_nullable_to_non_nullable
as List<WaitlistScoreFactor>,
  ));
}

}


/// Adds pattern-matching-related methods to [WaitlistScore].
extension WaitlistScorePatterns on WaitlistScore {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WaitlistScore value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WaitlistScore() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WaitlistScore value)  $default,){
final _that = this;
switch (_that) {
case _WaitlistScore():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WaitlistScore value)?  $default,){
final _that = this;
switch (_that) {
case _WaitlistScore() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double overallScore,  double timeFlexibilityScore,  double proximityScore,  double confirmRateScore,  double revenueScore,  double fairnessScore,  List<WaitlistScoreFactor> factors)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WaitlistScore() when $default != null:
return $default(_that.overallScore,_that.timeFlexibilityScore,_that.proximityScore,_that.confirmRateScore,_that.revenueScore,_that.fairnessScore,_that.factors);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double overallScore,  double timeFlexibilityScore,  double proximityScore,  double confirmRateScore,  double revenueScore,  double fairnessScore,  List<WaitlistScoreFactor> factors)  $default,) {final _that = this;
switch (_that) {
case _WaitlistScore():
return $default(_that.overallScore,_that.timeFlexibilityScore,_that.proximityScore,_that.confirmRateScore,_that.revenueScore,_that.fairnessScore,_that.factors);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double overallScore,  double timeFlexibilityScore,  double proximityScore,  double confirmRateScore,  double revenueScore,  double fairnessScore,  List<WaitlistScoreFactor> factors)?  $default,) {final _that = this;
switch (_that) {
case _WaitlistScore() when $default != null:
return $default(_that.overallScore,_that.timeFlexibilityScore,_that.proximityScore,_that.confirmRateScore,_that.revenueScore,_that.fairnessScore,_that.factors);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WaitlistScore extends WaitlistScore {
  const _WaitlistScore({required this.overallScore, required this.timeFlexibilityScore, required this.proximityScore, required this.confirmRateScore, required this.revenueScore, required this.fairnessScore, final  List<WaitlistScoreFactor> factors = const []}): _factors = factors,super._();
  factory _WaitlistScore.fromJson(Map<String, dynamic> json) => _$WaitlistScoreFromJson(json);

/// Overall match score (0-100).
@override final  double overallScore;
/// Time flexibility score (0-30).
/// Higher if entry's preferred times match the slot.
@override final  double timeFlexibilityScore;
/// Geographic proximity score (0-20).
/// For mobile services, closer clients score higher.
@override final  double proximityScore;
/// Historical confirm rate score (0-30).
/// Based on client's past waitlist offer acceptance rate.
@override final  double confirmRateScore;
/// Revenue priority score (0-10).
/// Higher-value services or loyal clients score higher.
@override final  double revenueScore;
/// Wait time fairness score (0-10).
/// Longer wait = higher priority (fairness factor).
@override final  double fairnessScore;
/// Individual factor details for UI display.
 final  List<WaitlistScoreFactor> _factors;
/// Individual factor details for UI display.
@override@JsonKey() List<WaitlistScoreFactor> get factors {
  if (_factors is EqualUnmodifiableListView) return _factors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_factors);
}


/// Create a copy of WaitlistScore
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WaitlistScoreCopyWith<_WaitlistScore> get copyWith => __$WaitlistScoreCopyWithImpl<_WaitlistScore>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WaitlistScoreToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WaitlistScore&&(identical(other.overallScore, overallScore) || other.overallScore == overallScore)&&(identical(other.timeFlexibilityScore, timeFlexibilityScore) || other.timeFlexibilityScore == timeFlexibilityScore)&&(identical(other.proximityScore, proximityScore) || other.proximityScore == proximityScore)&&(identical(other.confirmRateScore, confirmRateScore) || other.confirmRateScore == confirmRateScore)&&(identical(other.revenueScore, revenueScore) || other.revenueScore == revenueScore)&&(identical(other.fairnessScore, fairnessScore) || other.fairnessScore == fairnessScore)&&const DeepCollectionEquality().equals(other._factors, _factors));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,overallScore,timeFlexibilityScore,proximityScore,confirmRateScore,revenueScore,fairnessScore,const DeepCollectionEquality().hash(_factors));

@override
String toString() {
  return 'WaitlistScore(overallScore: $overallScore, timeFlexibilityScore: $timeFlexibilityScore, proximityScore: $proximityScore, confirmRateScore: $confirmRateScore, revenueScore: $revenueScore, fairnessScore: $fairnessScore, factors: $factors)';
}


}

/// @nodoc
abstract mixin class _$WaitlistScoreCopyWith<$Res> implements $WaitlistScoreCopyWith<$Res> {
  factory _$WaitlistScoreCopyWith(_WaitlistScore value, $Res Function(_WaitlistScore) _then) = __$WaitlistScoreCopyWithImpl;
@override @useResult
$Res call({
 double overallScore, double timeFlexibilityScore, double proximityScore, double confirmRateScore, double revenueScore, double fairnessScore, List<WaitlistScoreFactor> factors
});




}
/// @nodoc
class __$WaitlistScoreCopyWithImpl<$Res>
    implements _$WaitlistScoreCopyWith<$Res> {
  __$WaitlistScoreCopyWithImpl(this._self, this._then);

  final _WaitlistScore _self;
  final $Res Function(_WaitlistScore) _then;

/// Create a copy of WaitlistScore
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? overallScore = null,Object? timeFlexibilityScore = null,Object? proximityScore = null,Object? confirmRateScore = null,Object? revenueScore = null,Object? fairnessScore = null,Object? factors = null,}) {
  return _then(_WaitlistScore(
overallScore: null == overallScore ? _self.overallScore : overallScore // ignore: cast_nullable_to_non_nullable
as double,timeFlexibilityScore: null == timeFlexibilityScore ? _self.timeFlexibilityScore : timeFlexibilityScore // ignore: cast_nullable_to_non_nullable
as double,proximityScore: null == proximityScore ? _self.proximityScore : proximityScore // ignore: cast_nullable_to_non_nullable
as double,confirmRateScore: null == confirmRateScore ? _self.confirmRateScore : confirmRateScore // ignore: cast_nullable_to_non_nullable
as double,revenueScore: null == revenueScore ? _self.revenueScore : revenueScore // ignore: cast_nullable_to_non_nullable
as double,fairnessScore: null == fairnessScore ? _self.fairnessScore : fairnessScore // ignore: cast_nullable_to_non_nullable
as double,factors: null == factors ? _self._factors : factors // ignore: cast_nullable_to_non_nullable
as List<WaitlistScoreFactor>,
  ));
}


}


/// @nodoc
mixin _$WaitlistScoreFactor {

/// Factor type identifier.
 WaitlistFactorType get factorType;/// Human-readable description.
 String get description;/// Impact on overall score (0-100 scale contribution).
 double get impact;/// Maximum possible impact for this factor.
 double get maxImpact;/// Icon name for UI.
 String get iconName;
/// Create a copy of WaitlistScoreFactor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WaitlistScoreFactorCopyWith<WaitlistScoreFactor> get copyWith => _$WaitlistScoreFactorCopyWithImpl<WaitlistScoreFactor>(this as WaitlistScoreFactor, _$identity);

  /// Serializes this WaitlistScoreFactor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WaitlistScoreFactor&&(identical(other.factorType, factorType) || other.factorType == factorType)&&(identical(other.description, description) || other.description == description)&&(identical(other.impact, impact) || other.impact == impact)&&(identical(other.maxImpact, maxImpact) || other.maxImpact == maxImpact)&&(identical(other.iconName, iconName) || other.iconName == iconName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,factorType,description,impact,maxImpact,iconName);

@override
String toString() {
  return 'WaitlistScoreFactor(factorType: $factorType, description: $description, impact: $impact, maxImpact: $maxImpact, iconName: $iconName)';
}


}

/// @nodoc
abstract mixin class $WaitlistScoreFactorCopyWith<$Res>  {
  factory $WaitlistScoreFactorCopyWith(WaitlistScoreFactor value, $Res Function(WaitlistScoreFactor) _then) = _$WaitlistScoreFactorCopyWithImpl;
@useResult
$Res call({
 WaitlistFactorType factorType, String description, double impact, double maxImpact, String iconName
});




}
/// @nodoc
class _$WaitlistScoreFactorCopyWithImpl<$Res>
    implements $WaitlistScoreFactorCopyWith<$Res> {
  _$WaitlistScoreFactorCopyWithImpl(this._self, this._then);

  final WaitlistScoreFactor _self;
  final $Res Function(WaitlistScoreFactor) _then;

/// Create a copy of WaitlistScoreFactor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? factorType = null,Object? description = null,Object? impact = null,Object? maxImpact = null,Object? iconName = null,}) {
  return _then(_self.copyWith(
factorType: null == factorType ? _self.factorType : factorType // ignore: cast_nullable_to_non_nullable
as WaitlistFactorType,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,impact: null == impact ? _self.impact : impact // ignore: cast_nullable_to_non_nullable
as double,maxImpact: null == maxImpact ? _self.maxImpact : maxImpact // ignore: cast_nullable_to_non_nullable
as double,iconName: null == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WaitlistScoreFactor].
extension WaitlistScoreFactorPatterns on WaitlistScoreFactor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WaitlistScoreFactor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WaitlistScoreFactor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WaitlistScoreFactor value)  $default,){
final _that = this;
switch (_that) {
case _WaitlistScoreFactor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WaitlistScoreFactor value)?  $default,){
final _that = this;
switch (_that) {
case _WaitlistScoreFactor() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WaitlistFactorType factorType,  String description,  double impact,  double maxImpact,  String iconName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WaitlistScoreFactor() when $default != null:
return $default(_that.factorType,_that.description,_that.impact,_that.maxImpact,_that.iconName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WaitlistFactorType factorType,  String description,  double impact,  double maxImpact,  String iconName)  $default,) {final _that = this;
switch (_that) {
case _WaitlistScoreFactor():
return $default(_that.factorType,_that.description,_that.impact,_that.maxImpact,_that.iconName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WaitlistFactorType factorType,  String description,  double impact,  double maxImpact,  String iconName)?  $default,) {final _that = this;
switch (_that) {
case _WaitlistScoreFactor() when $default != null:
return $default(_that.factorType,_that.description,_that.impact,_that.maxImpact,_that.iconName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WaitlistScoreFactor extends WaitlistScoreFactor {
  const _WaitlistScoreFactor({required this.factorType, required this.description, required this.impact, required this.maxImpact, this.iconName = 'info'}): super._();
  factory _WaitlistScoreFactor.fromJson(Map<String, dynamic> json) => _$WaitlistScoreFactorFromJson(json);

/// Factor type identifier.
@override final  WaitlistFactorType factorType;
/// Human-readable description.
@override final  String description;
/// Impact on overall score (0-100 scale contribution).
@override final  double impact;
/// Maximum possible impact for this factor.
@override final  double maxImpact;
/// Icon name for UI.
@override@JsonKey() final  String iconName;

/// Create a copy of WaitlistScoreFactor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WaitlistScoreFactorCopyWith<_WaitlistScoreFactor> get copyWith => __$WaitlistScoreFactorCopyWithImpl<_WaitlistScoreFactor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WaitlistScoreFactorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WaitlistScoreFactor&&(identical(other.factorType, factorType) || other.factorType == factorType)&&(identical(other.description, description) || other.description == description)&&(identical(other.impact, impact) || other.impact == impact)&&(identical(other.maxImpact, maxImpact) || other.maxImpact == maxImpact)&&(identical(other.iconName, iconName) || other.iconName == iconName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,factorType,description,impact,maxImpact,iconName);

@override
String toString() {
  return 'WaitlistScoreFactor(factorType: $factorType, description: $description, impact: $impact, maxImpact: $maxImpact, iconName: $iconName)';
}


}

/// @nodoc
abstract mixin class _$WaitlistScoreFactorCopyWith<$Res> implements $WaitlistScoreFactorCopyWith<$Res> {
  factory _$WaitlistScoreFactorCopyWith(_WaitlistScoreFactor value, $Res Function(_WaitlistScoreFactor) _then) = __$WaitlistScoreFactorCopyWithImpl;
@override @useResult
$Res call({
 WaitlistFactorType factorType, String description, double impact, double maxImpact, String iconName
});




}
/// @nodoc
class __$WaitlistScoreFactorCopyWithImpl<$Res>
    implements _$WaitlistScoreFactorCopyWith<$Res> {
  __$WaitlistScoreFactorCopyWithImpl(this._self, this._then);

  final _WaitlistScoreFactor _self;
  final $Res Function(_WaitlistScoreFactor) _then;

/// Create a copy of WaitlistScoreFactor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? factorType = null,Object? description = null,Object? impact = null,Object? maxImpact = null,Object? iconName = null,}) {
  return _then(_WaitlistScoreFactor(
factorType: null == factorType ? _self.factorType : factorType // ignore: cast_nullable_to_non_nullable
as WaitlistFactorType,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,impact: null == impact ? _self.impact : impact // ignore: cast_nullable_to_non_nullable
as double,maxImpact: null == maxImpact ? _self.maxImpact : maxImpact // ignore: cast_nullable_to_non_nullable
as double,iconName: null == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$RankedWaitlistEntry {

/// Waitlist entry ID.
 String get entryId;/// Client ID.
 String get clientId;/// Client name for display.
 String get clientName;/// Client phone for contact.
 String? get clientPhone;/// Requested service ID.
 String get serviceId;/// Service name for display.
 String get serviceName;/// Match score details.
 WaitlistScore get score;/// Rank in the matched list (1 = best).
 int get rank;/// When the entry was added to waitlist.
 DateTime get addedAt;/// Client's preferred time windows.
 List<TimeWindow> get preferredTimes;/// Distance to service location (km), if applicable.
 double? get distanceKm;/// Client's historical confirm rate (0-1).
 double? get historicalConfirmRate;/// Estimated revenue if booked.
 double? get estimatedRevenue;/// Notes from the waitlist entry.
 String? get notes;/// Whether an offer has been sent.
 bool get offerSent;/// When the offer was sent.
 DateTime? get offerSentAt;/// Offer response (accepted, declined, expired, null).
 String? get offerResponse;/// Short explanation of why this is a good/poor match.
 String? get matchReasoning;
/// Create a copy of RankedWaitlistEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RankedWaitlistEntryCopyWith<RankedWaitlistEntry> get copyWith => _$RankedWaitlistEntryCopyWithImpl<RankedWaitlistEntry>(this as RankedWaitlistEntry, _$identity);

  /// Serializes this RankedWaitlistEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RankedWaitlistEntry&&(identical(other.entryId, entryId) || other.entryId == entryId)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.clientName, clientName) || other.clientName == clientName)&&(identical(other.clientPhone, clientPhone) || other.clientPhone == clientPhone)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName)&&(identical(other.score, score) || other.score == score)&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt)&&const DeepCollectionEquality().equals(other.preferredTimes, preferredTimes)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.historicalConfirmRate, historicalConfirmRate) || other.historicalConfirmRate == historicalConfirmRate)&&(identical(other.estimatedRevenue, estimatedRevenue) || other.estimatedRevenue == estimatedRevenue)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.offerSent, offerSent) || other.offerSent == offerSent)&&(identical(other.offerSentAt, offerSentAt) || other.offerSentAt == offerSentAt)&&(identical(other.offerResponse, offerResponse) || other.offerResponse == offerResponse)&&(identical(other.matchReasoning, matchReasoning) || other.matchReasoning == matchReasoning));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,entryId,clientId,clientName,clientPhone,serviceId,serviceName,score,rank,addedAt,const DeepCollectionEquality().hash(preferredTimes),distanceKm,historicalConfirmRate,estimatedRevenue,notes,offerSent,offerSentAt,offerResponse,matchReasoning);

@override
String toString() {
  return 'RankedWaitlistEntry(entryId: $entryId, clientId: $clientId, clientName: $clientName, clientPhone: $clientPhone, serviceId: $serviceId, serviceName: $serviceName, score: $score, rank: $rank, addedAt: $addedAt, preferredTimes: $preferredTimes, distanceKm: $distanceKm, historicalConfirmRate: $historicalConfirmRate, estimatedRevenue: $estimatedRevenue, notes: $notes, offerSent: $offerSent, offerSentAt: $offerSentAt, offerResponse: $offerResponse, matchReasoning: $matchReasoning)';
}


}

/// @nodoc
abstract mixin class $RankedWaitlistEntryCopyWith<$Res>  {
  factory $RankedWaitlistEntryCopyWith(RankedWaitlistEntry value, $Res Function(RankedWaitlistEntry) _then) = _$RankedWaitlistEntryCopyWithImpl;
@useResult
$Res call({
 String entryId, String clientId, String clientName, String? clientPhone, String serviceId, String serviceName, WaitlistScore score, int rank, DateTime addedAt, List<TimeWindow> preferredTimes, double? distanceKm, double? historicalConfirmRate, double? estimatedRevenue, String? notes, bool offerSent, DateTime? offerSentAt, String? offerResponse, String? matchReasoning
});


$WaitlistScoreCopyWith<$Res> get score;

}
/// @nodoc
class _$RankedWaitlistEntryCopyWithImpl<$Res>
    implements $RankedWaitlistEntryCopyWith<$Res> {
  _$RankedWaitlistEntryCopyWithImpl(this._self, this._then);

  final RankedWaitlistEntry _self;
  final $Res Function(RankedWaitlistEntry) _then;

/// Create a copy of RankedWaitlistEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? entryId = null,Object? clientId = null,Object? clientName = null,Object? clientPhone = freezed,Object? serviceId = null,Object? serviceName = null,Object? score = null,Object? rank = null,Object? addedAt = null,Object? preferredTimes = null,Object? distanceKm = freezed,Object? historicalConfirmRate = freezed,Object? estimatedRevenue = freezed,Object? notes = freezed,Object? offerSent = null,Object? offerSentAt = freezed,Object? offerResponse = freezed,Object? matchReasoning = freezed,}) {
  return _then(_self.copyWith(
entryId: null == entryId ? _self.entryId : entryId // ignore: cast_nullable_to_non_nullable
as String,clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,clientName: null == clientName ? _self.clientName : clientName // ignore: cast_nullable_to_non_nullable
as String,clientPhone: freezed == clientPhone ? _self.clientPhone : clientPhone // ignore: cast_nullable_to_non_nullable
as String?,serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String,serviceName: null == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as String,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as WaitlistScore,rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int,addedAt: null == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as DateTime,preferredTimes: null == preferredTimes ? _self.preferredTimes : preferredTimes // ignore: cast_nullable_to_non_nullable
as List<TimeWindow>,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double?,historicalConfirmRate: freezed == historicalConfirmRate ? _self.historicalConfirmRate : historicalConfirmRate // ignore: cast_nullable_to_non_nullable
as double?,estimatedRevenue: freezed == estimatedRevenue ? _self.estimatedRevenue : estimatedRevenue // ignore: cast_nullable_to_non_nullable
as double?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,offerSent: null == offerSent ? _self.offerSent : offerSent // ignore: cast_nullable_to_non_nullable
as bool,offerSentAt: freezed == offerSentAt ? _self.offerSentAt : offerSentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,offerResponse: freezed == offerResponse ? _self.offerResponse : offerResponse // ignore: cast_nullable_to_non_nullable
as String?,matchReasoning: freezed == matchReasoning ? _self.matchReasoning : matchReasoning // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of RankedWaitlistEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WaitlistScoreCopyWith<$Res> get score {
  
  return $WaitlistScoreCopyWith<$Res>(_self.score, (value) {
    return _then(_self.copyWith(score: value));
  });
}
}


/// Adds pattern-matching-related methods to [RankedWaitlistEntry].
extension RankedWaitlistEntryPatterns on RankedWaitlistEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RankedWaitlistEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RankedWaitlistEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RankedWaitlistEntry value)  $default,){
final _that = this;
switch (_that) {
case _RankedWaitlistEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RankedWaitlistEntry value)?  $default,){
final _that = this;
switch (_that) {
case _RankedWaitlistEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String entryId,  String clientId,  String clientName,  String? clientPhone,  String serviceId,  String serviceName,  WaitlistScore score,  int rank,  DateTime addedAt,  List<TimeWindow> preferredTimes,  double? distanceKm,  double? historicalConfirmRate,  double? estimatedRevenue,  String? notes,  bool offerSent,  DateTime? offerSentAt,  String? offerResponse,  String? matchReasoning)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RankedWaitlistEntry() when $default != null:
return $default(_that.entryId,_that.clientId,_that.clientName,_that.clientPhone,_that.serviceId,_that.serviceName,_that.score,_that.rank,_that.addedAt,_that.preferredTimes,_that.distanceKm,_that.historicalConfirmRate,_that.estimatedRevenue,_that.notes,_that.offerSent,_that.offerSentAt,_that.offerResponse,_that.matchReasoning);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String entryId,  String clientId,  String clientName,  String? clientPhone,  String serviceId,  String serviceName,  WaitlistScore score,  int rank,  DateTime addedAt,  List<TimeWindow> preferredTimes,  double? distanceKm,  double? historicalConfirmRate,  double? estimatedRevenue,  String? notes,  bool offerSent,  DateTime? offerSentAt,  String? offerResponse,  String? matchReasoning)  $default,) {final _that = this;
switch (_that) {
case _RankedWaitlistEntry():
return $default(_that.entryId,_that.clientId,_that.clientName,_that.clientPhone,_that.serviceId,_that.serviceName,_that.score,_that.rank,_that.addedAt,_that.preferredTimes,_that.distanceKm,_that.historicalConfirmRate,_that.estimatedRevenue,_that.notes,_that.offerSent,_that.offerSentAt,_that.offerResponse,_that.matchReasoning);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String entryId,  String clientId,  String clientName,  String? clientPhone,  String serviceId,  String serviceName,  WaitlistScore score,  int rank,  DateTime addedAt,  List<TimeWindow> preferredTimes,  double? distanceKm,  double? historicalConfirmRate,  double? estimatedRevenue,  String? notes,  bool offerSent,  DateTime? offerSentAt,  String? offerResponse,  String? matchReasoning)?  $default,) {final _that = this;
switch (_that) {
case _RankedWaitlistEntry() when $default != null:
return $default(_that.entryId,_that.clientId,_that.clientName,_that.clientPhone,_that.serviceId,_that.serviceName,_that.score,_that.rank,_that.addedAt,_that.preferredTimes,_that.distanceKm,_that.historicalConfirmRate,_that.estimatedRevenue,_that.notes,_that.offerSent,_that.offerSentAt,_that.offerResponse,_that.matchReasoning);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RankedWaitlistEntry extends RankedWaitlistEntry {
  const _RankedWaitlistEntry({required this.entryId, required this.clientId, required this.clientName, this.clientPhone, required this.serviceId, required this.serviceName, required this.score, required this.rank, required this.addedAt, final  List<TimeWindow> preferredTimes = const [], this.distanceKm, this.historicalConfirmRate, this.estimatedRevenue, this.notes, this.offerSent = false, this.offerSentAt, this.offerResponse, this.matchReasoning}): _preferredTimes = preferredTimes,super._();
  factory _RankedWaitlistEntry.fromJson(Map<String, dynamic> json) => _$RankedWaitlistEntryFromJson(json);

/// Waitlist entry ID.
@override final  String entryId;
/// Client ID.
@override final  String clientId;
/// Client name for display.
@override final  String clientName;
/// Client phone for contact.
@override final  String? clientPhone;
/// Requested service ID.
@override final  String serviceId;
/// Service name for display.
@override final  String serviceName;
/// Match score details.
@override final  WaitlistScore score;
/// Rank in the matched list (1 = best).
@override final  int rank;
/// When the entry was added to waitlist.
@override final  DateTime addedAt;
/// Client's preferred time windows.
 final  List<TimeWindow> _preferredTimes;
/// Client's preferred time windows.
@override@JsonKey() List<TimeWindow> get preferredTimes {
  if (_preferredTimes is EqualUnmodifiableListView) return _preferredTimes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_preferredTimes);
}

/// Distance to service location (km), if applicable.
@override final  double? distanceKm;
/// Client's historical confirm rate (0-1).
@override final  double? historicalConfirmRate;
/// Estimated revenue if booked.
@override final  double? estimatedRevenue;
/// Notes from the waitlist entry.
@override final  String? notes;
/// Whether an offer has been sent.
@override@JsonKey() final  bool offerSent;
/// When the offer was sent.
@override final  DateTime? offerSentAt;
/// Offer response (accepted, declined, expired, null).
@override final  String? offerResponse;
/// Short explanation of why this is a good/poor match.
@override final  String? matchReasoning;

/// Create a copy of RankedWaitlistEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RankedWaitlistEntryCopyWith<_RankedWaitlistEntry> get copyWith => __$RankedWaitlistEntryCopyWithImpl<_RankedWaitlistEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RankedWaitlistEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RankedWaitlistEntry&&(identical(other.entryId, entryId) || other.entryId == entryId)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.clientName, clientName) || other.clientName == clientName)&&(identical(other.clientPhone, clientPhone) || other.clientPhone == clientPhone)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName)&&(identical(other.score, score) || other.score == score)&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt)&&const DeepCollectionEquality().equals(other._preferredTimes, _preferredTimes)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.historicalConfirmRate, historicalConfirmRate) || other.historicalConfirmRate == historicalConfirmRate)&&(identical(other.estimatedRevenue, estimatedRevenue) || other.estimatedRevenue == estimatedRevenue)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.offerSent, offerSent) || other.offerSent == offerSent)&&(identical(other.offerSentAt, offerSentAt) || other.offerSentAt == offerSentAt)&&(identical(other.offerResponse, offerResponse) || other.offerResponse == offerResponse)&&(identical(other.matchReasoning, matchReasoning) || other.matchReasoning == matchReasoning));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,entryId,clientId,clientName,clientPhone,serviceId,serviceName,score,rank,addedAt,const DeepCollectionEquality().hash(_preferredTimes),distanceKm,historicalConfirmRate,estimatedRevenue,notes,offerSent,offerSentAt,offerResponse,matchReasoning);

@override
String toString() {
  return 'RankedWaitlistEntry(entryId: $entryId, clientId: $clientId, clientName: $clientName, clientPhone: $clientPhone, serviceId: $serviceId, serviceName: $serviceName, score: $score, rank: $rank, addedAt: $addedAt, preferredTimes: $preferredTimes, distanceKm: $distanceKm, historicalConfirmRate: $historicalConfirmRate, estimatedRevenue: $estimatedRevenue, notes: $notes, offerSent: $offerSent, offerSentAt: $offerSentAt, offerResponse: $offerResponse, matchReasoning: $matchReasoning)';
}


}

/// @nodoc
abstract mixin class _$RankedWaitlistEntryCopyWith<$Res> implements $RankedWaitlistEntryCopyWith<$Res> {
  factory _$RankedWaitlistEntryCopyWith(_RankedWaitlistEntry value, $Res Function(_RankedWaitlistEntry) _then) = __$RankedWaitlistEntryCopyWithImpl;
@override @useResult
$Res call({
 String entryId, String clientId, String clientName, String? clientPhone, String serviceId, String serviceName, WaitlistScore score, int rank, DateTime addedAt, List<TimeWindow> preferredTimes, double? distanceKm, double? historicalConfirmRate, double? estimatedRevenue, String? notes, bool offerSent, DateTime? offerSentAt, String? offerResponse, String? matchReasoning
});


@override $WaitlistScoreCopyWith<$Res> get score;

}
/// @nodoc
class __$RankedWaitlistEntryCopyWithImpl<$Res>
    implements _$RankedWaitlistEntryCopyWith<$Res> {
  __$RankedWaitlistEntryCopyWithImpl(this._self, this._then);

  final _RankedWaitlistEntry _self;
  final $Res Function(_RankedWaitlistEntry) _then;

/// Create a copy of RankedWaitlistEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entryId = null,Object? clientId = null,Object? clientName = null,Object? clientPhone = freezed,Object? serviceId = null,Object? serviceName = null,Object? score = null,Object? rank = null,Object? addedAt = null,Object? preferredTimes = null,Object? distanceKm = freezed,Object? historicalConfirmRate = freezed,Object? estimatedRevenue = freezed,Object? notes = freezed,Object? offerSent = null,Object? offerSentAt = freezed,Object? offerResponse = freezed,Object? matchReasoning = freezed,}) {
  return _then(_RankedWaitlistEntry(
entryId: null == entryId ? _self.entryId : entryId // ignore: cast_nullable_to_non_nullable
as String,clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,clientName: null == clientName ? _self.clientName : clientName // ignore: cast_nullable_to_non_nullable
as String,clientPhone: freezed == clientPhone ? _self.clientPhone : clientPhone // ignore: cast_nullable_to_non_nullable
as String?,serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String,serviceName: null == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as String,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as WaitlistScore,rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int,addedAt: null == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as DateTime,preferredTimes: null == preferredTimes ? _self._preferredTimes : preferredTimes // ignore: cast_nullable_to_non_nullable
as List<TimeWindow>,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double?,historicalConfirmRate: freezed == historicalConfirmRate ? _self.historicalConfirmRate : historicalConfirmRate // ignore: cast_nullable_to_non_nullable
as double?,estimatedRevenue: freezed == estimatedRevenue ? _self.estimatedRevenue : estimatedRevenue // ignore: cast_nullable_to_non_nullable
as double?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,offerSent: null == offerSent ? _self.offerSent : offerSent // ignore: cast_nullable_to_non_nullable
as bool,offerSentAt: freezed == offerSentAt ? _self.offerSentAt : offerSentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,offerResponse: freezed == offerResponse ? _self.offerResponse : offerResponse // ignore: cast_nullable_to_non_nullable
as String?,matchReasoning: freezed == matchReasoning ? _self.matchReasoning : matchReasoning // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of RankedWaitlistEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WaitlistScoreCopyWith<$Res> get score {
  
  return $WaitlistScoreCopyWith<$Res>(_self.score, (value) {
    return _then(_self.copyWith(score: value));
  });
}
}


/// @nodoc
mixin _$TimeWindow {

/// Day of week (1=Monday, 7=Sunday).
 int get dayOfWeek;/// Start hour (0-23).
 int get startHour;/// End hour (0-23).
 int get endHour;
/// Create a copy of TimeWindow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimeWindowCopyWith<TimeWindow> get copyWith => _$TimeWindowCopyWithImpl<TimeWindow>(this as TimeWindow, _$identity);

  /// Serializes this TimeWindow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimeWindow&&(identical(other.dayOfWeek, dayOfWeek) || other.dayOfWeek == dayOfWeek)&&(identical(other.startHour, startHour) || other.startHour == startHour)&&(identical(other.endHour, endHour) || other.endHour == endHour));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dayOfWeek,startHour,endHour);

@override
String toString() {
  return 'TimeWindow(dayOfWeek: $dayOfWeek, startHour: $startHour, endHour: $endHour)';
}


}

/// @nodoc
abstract mixin class $TimeWindowCopyWith<$Res>  {
  factory $TimeWindowCopyWith(TimeWindow value, $Res Function(TimeWindow) _then) = _$TimeWindowCopyWithImpl;
@useResult
$Res call({
 int dayOfWeek, int startHour, int endHour
});




}
/// @nodoc
class _$TimeWindowCopyWithImpl<$Res>
    implements $TimeWindowCopyWith<$Res> {
  _$TimeWindowCopyWithImpl(this._self, this._then);

  final TimeWindow _self;
  final $Res Function(TimeWindow) _then;

/// Create a copy of TimeWindow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dayOfWeek = null,Object? startHour = null,Object? endHour = null,}) {
  return _then(_self.copyWith(
dayOfWeek: null == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as int,startHour: null == startHour ? _self.startHour : startHour // ignore: cast_nullable_to_non_nullable
as int,endHour: null == endHour ? _self.endHour : endHour // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TimeWindow].
extension TimeWindowPatterns on TimeWindow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TimeWindow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TimeWindow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TimeWindow value)  $default,){
final _that = this;
switch (_that) {
case _TimeWindow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TimeWindow value)?  $default,){
final _that = this;
switch (_that) {
case _TimeWindow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int dayOfWeek,  int startHour,  int endHour)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TimeWindow() when $default != null:
return $default(_that.dayOfWeek,_that.startHour,_that.endHour);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int dayOfWeek,  int startHour,  int endHour)  $default,) {final _that = this;
switch (_that) {
case _TimeWindow():
return $default(_that.dayOfWeek,_that.startHour,_that.endHour);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int dayOfWeek,  int startHour,  int endHour)?  $default,) {final _that = this;
switch (_that) {
case _TimeWindow() when $default != null:
return $default(_that.dayOfWeek,_that.startHour,_that.endHour);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TimeWindow extends TimeWindow {
  const _TimeWindow({required this.dayOfWeek, required this.startHour, required this.endHour}): super._();
  factory _TimeWindow.fromJson(Map<String, dynamic> json) => _$TimeWindowFromJson(json);

/// Day of week (1=Monday, 7=Sunday).
@override final  int dayOfWeek;
/// Start hour (0-23).
@override final  int startHour;
/// End hour (0-23).
@override final  int endHour;

/// Create a copy of TimeWindow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TimeWindowCopyWith<_TimeWindow> get copyWith => __$TimeWindowCopyWithImpl<_TimeWindow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TimeWindowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TimeWindow&&(identical(other.dayOfWeek, dayOfWeek) || other.dayOfWeek == dayOfWeek)&&(identical(other.startHour, startHour) || other.startHour == startHour)&&(identical(other.endHour, endHour) || other.endHour == endHour));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dayOfWeek,startHour,endHour);

@override
String toString() {
  return 'TimeWindow(dayOfWeek: $dayOfWeek, startHour: $startHour, endHour: $endHour)';
}


}

/// @nodoc
abstract mixin class _$TimeWindowCopyWith<$Res> implements $TimeWindowCopyWith<$Res> {
  factory _$TimeWindowCopyWith(_TimeWindow value, $Res Function(_TimeWindow) _then) = __$TimeWindowCopyWithImpl;
@override @useResult
$Res call({
 int dayOfWeek, int startHour, int endHour
});




}
/// @nodoc
class __$TimeWindowCopyWithImpl<$Res>
    implements _$TimeWindowCopyWith<$Res> {
  __$TimeWindowCopyWithImpl(this._self, this._then);

  final _TimeWindow _self;
  final $Res Function(_TimeWindow) _then;

/// Create a copy of TimeWindow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dayOfWeek = null,Object? startHour = null,Object? endHour = null,}) {
  return _then(_TimeWindow(
dayOfWeek: null == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as int,startHour: null == startHour ? _self.startHour : startHour // ignore: cast_nullable_to_non_nullable
as int,endHour: null == endHour ? _self.endHour : endHour // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$WaitlistMatchResult {

/// Cancelled slot ID being filled.
 String get slotId;/// Service ID of the slot.
 String get serviceId;/// Provider ID of the slot.
 String get providerId;/// Slot date/time.
 DateTime get slotDateTime;/// Ranked candidates.
 List<RankedWaitlistEntry> get candidates;/// Top candidates (automatically offered).
 List<RankedWaitlistEntry> get topCandidates;/// When this match was generated.
 DateTime get generatedAt;/// Total waitlist entries considered.
 int get totalConsidered;/// Whether any strong matches found.
 bool get hasStrongMatches;/// Reason if no matches found.
 String? get noMatchReason;
/// Create a copy of WaitlistMatchResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WaitlistMatchResultCopyWith<WaitlistMatchResult> get copyWith => _$WaitlistMatchResultCopyWithImpl<WaitlistMatchResult>(this as WaitlistMatchResult, _$identity);

  /// Serializes this WaitlistMatchResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WaitlistMatchResult&&(identical(other.slotId, slotId) || other.slotId == slotId)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.slotDateTime, slotDateTime) || other.slotDateTime == slotDateTime)&&const DeepCollectionEquality().equals(other.candidates, candidates)&&const DeepCollectionEquality().equals(other.topCandidates, topCandidates)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.totalConsidered, totalConsidered) || other.totalConsidered == totalConsidered)&&(identical(other.hasStrongMatches, hasStrongMatches) || other.hasStrongMatches == hasStrongMatches)&&(identical(other.noMatchReason, noMatchReason) || other.noMatchReason == noMatchReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slotId,serviceId,providerId,slotDateTime,const DeepCollectionEquality().hash(candidates),const DeepCollectionEquality().hash(topCandidates),generatedAt,totalConsidered,hasStrongMatches,noMatchReason);

@override
String toString() {
  return 'WaitlistMatchResult(slotId: $slotId, serviceId: $serviceId, providerId: $providerId, slotDateTime: $slotDateTime, candidates: $candidates, topCandidates: $topCandidates, generatedAt: $generatedAt, totalConsidered: $totalConsidered, hasStrongMatches: $hasStrongMatches, noMatchReason: $noMatchReason)';
}


}

/// @nodoc
abstract mixin class $WaitlistMatchResultCopyWith<$Res>  {
  factory $WaitlistMatchResultCopyWith(WaitlistMatchResult value, $Res Function(WaitlistMatchResult) _then) = _$WaitlistMatchResultCopyWithImpl;
@useResult
$Res call({
 String slotId, String serviceId, String providerId, DateTime slotDateTime, List<RankedWaitlistEntry> candidates, List<RankedWaitlistEntry> topCandidates, DateTime generatedAt, int totalConsidered, bool hasStrongMatches, String? noMatchReason
});




}
/// @nodoc
class _$WaitlistMatchResultCopyWithImpl<$Res>
    implements $WaitlistMatchResultCopyWith<$Res> {
  _$WaitlistMatchResultCopyWithImpl(this._self, this._then);

  final WaitlistMatchResult _self;
  final $Res Function(WaitlistMatchResult) _then;

/// Create a copy of WaitlistMatchResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slotId = null,Object? serviceId = null,Object? providerId = null,Object? slotDateTime = null,Object? candidates = null,Object? topCandidates = null,Object? generatedAt = null,Object? totalConsidered = null,Object? hasStrongMatches = null,Object? noMatchReason = freezed,}) {
  return _then(_self.copyWith(
slotId: null == slotId ? _self.slotId : slotId // ignore: cast_nullable_to_non_nullable
as String,serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,slotDateTime: null == slotDateTime ? _self.slotDateTime : slotDateTime // ignore: cast_nullable_to_non_nullable
as DateTime,candidates: null == candidates ? _self.candidates : candidates // ignore: cast_nullable_to_non_nullable
as List<RankedWaitlistEntry>,topCandidates: null == topCandidates ? _self.topCandidates : topCandidates // ignore: cast_nullable_to_non_nullable
as List<RankedWaitlistEntry>,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,totalConsidered: null == totalConsidered ? _self.totalConsidered : totalConsidered // ignore: cast_nullable_to_non_nullable
as int,hasStrongMatches: null == hasStrongMatches ? _self.hasStrongMatches : hasStrongMatches // ignore: cast_nullable_to_non_nullable
as bool,noMatchReason: freezed == noMatchReason ? _self.noMatchReason : noMatchReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WaitlistMatchResult].
extension WaitlistMatchResultPatterns on WaitlistMatchResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WaitlistMatchResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WaitlistMatchResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WaitlistMatchResult value)  $default,){
final _that = this;
switch (_that) {
case _WaitlistMatchResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WaitlistMatchResult value)?  $default,){
final _that = this;
switch (_that) {
case _WaitlistMatchResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String slotId,  String serviceId,  String providerId,  DateTime slotDateTime,  List<RankedWaitlistEntry> candidates,  List<RankedWaitlistEntry> topCandidates,  DateTime generatedAt,  int totalConsidered,  bool hasStrongMatches,  String? noMatchReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WaitlistMatchResult() when $default != null:
return $default(_that.slotId,_that.serviceId,_that.providerId,_that.slotDateTime,_that.candidates,_that.topCandidates,_that.generatedAt,_that.totalConsidered,_that.hasStrongMatches,_that.noMatchReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String slotId,  String serviceId,  String providerId,  DateTime slotDateTime,  List<RankedWaitlistEntry> candidates,  List<RankedWaitlistEntry> topCandidates,  DateTime generatedAt,  int totalConsidered,  bool hasStrongMatches,  String? noMatchReason)  $default,) {final _that = this;
switch (_that) {
case _WaitlistMatchResult():
return $default(_that.slotId,_that.serviceId,_that.providerId,_that.slotDateTime,_that.candidates,_that.topCandidates,_that.generatedAt,_that.totalConsidered,_that.hasStrongMatches,_that.noMatchReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String slotId,  String serviceId,  String providerId,  DateTime slotDateTime,  List<RankedWaitlistEntry> candidates,  List<RankedWaitlistEntry> topCandidates,  DateTime generatedAt,  int totalConsidered,  bool hasStrongMatches,  String? noMatchReason)?  $default,) {final _that = this;
switch (_that) {
case _WaitlistMatchResult() when $default != null:
return $default(_that.slotId,_that.serviceId,_that.providerId,_that.slotDateTime,_that.candidates,_that.topCandidates,_that.generatedAt,_that.totalConsidered,_that.hasStrongMatches,_that.noMatchReason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WaitlistMatchResult extends WaitlistMatchResult {
  const _WaitlistMatchResult({required this.slotId, required this.serviceId, required this.providerId, required this.slotDateTime, required final  List<RankedWaitlistEntry> candidates, final  List<RankedWaitlistEntry> topCandidates = const [], required this.generatedAt, required this.totalConsidered, this.hasStrongMatches = false, this.noMatchReason}): _candidates = candidates,_topCandidates = topCandidates,super._();
  factory _WaitlistMatchResult.fromJson(Map<String, dynamic> json) => _$WaitlistMatchResultFromJson(json);

/// Cancelled slot ID being filled.
@override final  String slotId;
/// Service ID of the slot.
@override final  String serviceId;
/// Provider ID of the slot.
@override final  String providerId;
/// Slot date/time.
@override final  DateTime slotDateTime;
/// Ranked candidates.
 final  List<RankedWaitlistEntry> _candidates;
/// Ranked candidates.
@override List<RankedWaitlistEntry> get candidates {
  if (_candidates is EqualUnmodifiableListView) return _candidates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_candidates);
}

/// Top candidates (automatically offered).
 final  List<RankedWaitlistEntry> _topCandidates;
/// Top candidates (automatically offered).
@override@JsonKey() List<RankedWaitlistEntry> get topCandidates {
  if (_topCandidates is EqualUnmodifiableListView) return _topCandidates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topCandidates);
}

/// When this match was generated.
@override final  DateTime generatedAt;
/// Total waitlist entries considered.
@override final  int totalConsidered;
/// Whether any strong matches found.
@override@JsonKey() final  bool hasStrongMatches;
/// Reason if no matches found.
@override final  String? noMatchReason;

/// Create a copy of WaitlistMatchResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WaitlistMatchResultCopyWith<_WaitlistMatchResult> get copyWith => __$WaitlistMatchResultCopyWithImpl<_WaitlistMatchResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WaitlistMatchResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WaitlistMatchResult&&(identical(other.slotId, slotId) || other.slotId == slotId)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.slotDateTime, slotDateTime) || other.slotDateTime == slotDateTime)&&const DeepCollectionEquality().equals(other._candidates, _candidates)&&const DeepCollectionEquality().equals(other._topCandidates, _topCandidates)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.totalConsidered, totalConsidered) || other.totalConsidered == totalConsidered)&&(identical(other.hasStrongMatches, hasStrongMatches) || other.hasStrongMatches == hasStrongMatches)&&(identical(other.noMatchReason, noMatchReason) || other.noMatchReason == noMatchReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slotId,serviceId,providerId,slotDateTime,const DeepCollectionEquality().hash(_candidates),const DeepCollectionEquality().hash(_topCandidates),generatedAt,totalConsidered,hasStrongMatches,noMatchReason);

@override
String toString() {
  return 'WaitlistMatchResult(slotId: $slotId, serviceId: $serviceId, providerId: $providerId, slotDateTime: $slotDateTime, candidates: $candidates, topCandidates: $topCandidates, generatedAt: $generatedAt, totalConsidered: $totalConsidered, hasStrongMatches: $hasStrongMatches, noMatchReason: $noMatchReason)';
}


}

/// @nodoc
abstract mixin class _$WaitlistMatchResultCopyWith<$Res> implements $WaitlistMatchResultCopyWith<$Res> {
  factory _$WaitlistMatchResultCopyWith(_WaitlistMatchResult value, $Res Function(_WaitlistMatchResult) _then) = __$WaitlistMatchResultCopyWithImpl;
@override @useResult
$Res call({
 String slotId, String serviceId, String providerId, DateTime slotDateTime, List<RankedWaitlistEntry> candidates, List<RankedWaitlistEntry> topCandidates, DateTime generatedAt, int totalConsidered, bool hasStrongMatches, String? noMatchReason
});




}
/// @nodoc
class __$WaitlistMatchResultCopyWithImpl<$Res>
    implements _$WaitlistMatchResultCopyWith<$Res> {
  __$WaitlistMatchResultCopyWithImpl(this._self, this._then);

  final _WaitlistMatchResult _self;
  final $Res Function(_WaitlistMatchResult) _then;

/// Create a copy of WaitlistMatchResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slotId = null,Object? serviceId = null,Object? providerId = null,Object? slotDateTime = null,Object? candidates = null,Object? topCandidates = null,Object? generatedAt = null,Object? totalConsidered = null,Object? hasStrongMatches = null,Object? noMatchReason = freezed,}) {
  return _then(_WaitlistMatchResult(
slotId: null == slotId ? _self.slotId : slotId // ignore: cast_nullable_to_non_nullable
as String,serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,slotDateTime: null == slotDateTime ? _self.slotDateTime : slotDateTime // ignore: cast_nullable_to_non_nullable
as DateTime,candidates: null == candidates ? _self._candidates : candidates // ignore: cast_nullable_to_non_nullable
as List<RankedWaitlistEntry>,topCandidates: null == topCandidates ? _self._topCandidates : topCandidates // ignore: cast_nullable_to_non_nullable
as List<RankedWaitlistEntry>,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,totalConsidered: null == totalConsidered ? _self.totalConsidered : totalConsidered // ignore: cast_nullable_to_non_nullable
as int,hasStrongMatches: null == hasStrongMatches ? _self.hasStrongMatches : hasStrongMatches // ignore: cast_nullable_to_non_nullable
as bool,noMatchReason: freezed == noMatchReason ? _self.noMatchReason : noMatchReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$WaitlistMatchRequest {

/// Slot ID to fill.
 String get slotId;/// Service ID.
 String get serviceId;/// Provider ID.
 String get providerId;/// Slot date/time.
 DateTime get slotDateTime;/// Location ID (for proximity scoring).
 String? get locationId;/// Maximum candidates to return.
 int get maxCandidates;/// Auto-send offers to top N candidates.
 int get autoOfferCount;/// Minimum score to include (0-100).
 double get minScore;
/// Create a copy of WaitlistMatchRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WaitlistMatchRequestCopyWith<WaitlistMatchRequest> get copyWith => _$WaitlistMatchRequestCopyWithImpl<WaitlistMatchRequest>(this as WaitlistMatchRequest, _$identity);

  /// Serializes this WaitlistMatchRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WaitlistMatchRequest&&(identical(other.slotId, slotId) || other.slotId == slotId)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.slotDateTime, slotDateTime) || other.slotDateTime == slotDateTime)&&(identical(other.locationId, locationId) || other.locationId == locationId)&&(identical(other.maxCandidates, maxCandidates) || other.maxCandidates == maxCandidates)&&(identical(other.autoOfferCount, autoOfferCount) || other.autoOfferCount == autoOfferCount)&&(identical(other.minScore, minScore) || other.minScore == minScore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slotId,serviceId,providerId,slotDateTime,locationId,maxCandidates,autoOfferCount,minScore);

@override
String toString() {
  return 'WaitlistMatchRequest(slotId: $slotId, serviceId: $serviceId, providerId: $providerId, slotDateTime: $slotDateTime, locationId: $locationId, maxCandidates: $maxCandidates, autoOfferCount: $autoOfferCount, minScore: $minScore)';
}


}

/// @nodoc
abstract mixin class $WaitlistMatchRequestCopyWith<$Res>  {
  factory $WaitlistMatchRequestCopyWith(WaitlistMatchRequest value, $Res Function(WaitlistMatchRequest) _then) = _$WaitlistMatchRequestCopyWithImpl;
@useResult
$Res call({
 String slotId, String serviceId, String providerId, DateTime slotDateTime, String? locationId, int maxCandidates, int autoOfferCount, double minScore
});




}
/// @nodoc
class _$WaitlistMatchRequestCopyWithImpl<$Res>
    implements $WaitlistMatchRequestCopyWith<$Res> {
  _$WaitlistMatchRequestCopyWithImpl(this._self, this._then);

  final WaitlistMatchRequest _self;
  final $Res Function(WaitlistMatchRequest) _then;

/// Create a copy of WaitlistMatchRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slotId = null,Object? serviceId = null,Object? providerId = null,Object? slotDateTime = null,Object? locationId = freezed,Object? maxCandidates = null,Object? autoOfferCount = null,Object? minScore = null,}) {
  return _then(_self.copyWith(
slotId: null == slotId ? _self.slotId : slotId // ignore: cast_nullable_to_non_nullable
as String,serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,slotDateTime: null == slotDateTime ? _self.slotDateTime : slotDateTime // ignore: cast_nullable_to_non_nullable
as DateTime,locationId: freezed == locationId ? _self.locationId : locationId // ignore: cast_nullable_to_non_nullable
as String?,maxCandidates: null == maxCandidates ? _self.maxCandidates : maxCandidates // ignore: cast_nullable_to_non_nullable
as int,autoOfferCount: null == autoOfferCount ? _self.autoOfferCount : autoOfferCount // ignore: cast_nullable_to_non_nullable
as int,minScore: null == minScore ? _self.minScore : minScore // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [WaitlistMatchRequest].
extension WaitlistMatchRequestPatterns on WaitlistMatchRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WaitlistMatchRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WaitlistMatchRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WaitlistMatchRequest value)  $default,){
final _that = this;
switch (_that) {
case _WaitlistMatchRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WaitlistMatchRequest value)?  $default,){
final _that = this;
switch (_that) {
case _WaitlistMatchRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String slotId,  String serviceId,  String providerId,  DateTime slotDateTime,  String? locationId,  int maxCandidates,  int autoOfferCount,  double minScore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WaitlistMatchRequest() when $default != null:
return $default(_that.slotId,_that.serviceId,_that.providerId,_that.slotDateTime,_that.locationId,_that.maxCandidates,_that.autoOfferCount,_that.minScore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String slotId,  String serviceId,  String providerId,  DateTime slotDateTime,  String? locationId,  int maxCandidates,  int autoOfferCount,  double minScore)  $default,) {final _that = this;
switch (_that) {
case _WaitlistMatchRequest():
return $default(_that.slotId,_that.serviceId,_that.providerId,_that.slotDateTime,_that.locationId,_that.maxCandidates,_that.autoOfferCount,_that.minScore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String slotId,  String serviceId,  String providerId,  DateTime slotDateTime,  String? locationId,  int maxCandidates,  int autoOfferCount,  double minScore)?  $default,) {final _that = this;
switch (_that) {
case _WaitlistMatchRequest() when $default != null:
return $default(_that.slotId,_that.serviceId,_that.providerId,_that.slotDateTime,_that.locationId,_that.maxCandidates,_that.autoOfferCount,_that.minScore);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WaitlistMatchRequest implements WaitlistMatchRequest {
  const _WaitlistMatchRequest({required this.slotId, required this.serviceId, required this.providerId, required this.slotDateTime, this.locationId, this.maxCandidates = 10, this.autoOfferCount = 3, this.minScore = 30});
  factory _WaitlistMatchRequest.fromJson(Map<String, dynamic> json) => _$WaitlistMatchRequestFromJson(json);

/// Slot ID to fill.
@override final  String slotId;
/// Service ID.
@override final  String serviceId;
/// Provider ID.
@override final  String providerId;
/// Slot date/time.
@override final  DateTime slotDateTime;
/// Location ID (for proximity scoring).
@override final  String? locationId;
/// Maximum candidates to return.
@override@JsonKey() final  int maxCandidates;
/// Auto-send offers to top N candidates.
@override@JsonKey() final  int autoOfferCount;
/// Minimum score to include (0-100).
@override@JsonKey() final  double minScore;

/// Create a copy of WaitlistMatchRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WaitlistMatchRequestCopyWith<_WaitlistMatchRequest> get copyWith => __$WaitlistMatchRequestCopyWithImpl<_WaitlistMatchRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WaitlistMatchRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WaitlistMatchRequest&&(identical(other.slotId, slotId) || other.slotId == slotId)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.slotDateTime, slotDateTime) || other.slotDateTime == slotDateTime)&&(identical(other.locationId, locationId) || other.locationId == locationId)&&(identical(other.maxCandidates, maxCandidates) || other.maxCandidates == maxCandidates)&&(identical(other.autoOfferCount, autoOfferCount) || other.autoOfferCount == autoOfferCount)&&(identical(other.minScore, minScore) || other.minScore == minScore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slotId,serviceId,providerId,slotDateTime,locationId,maxCandidates,autoOfferCount,minScore);

@override
String toString() {
  return 'WaitlistMatchRequest(slotId: $slotId, serviceId: $serviceId, providerId: $providerId, slotDateTime: $slotDateTime, locationId: $locationId, maxCandidates: $maxCandidates, autoOfferCount: $autoOfferCount, minScore: $minScore)';
}


}

/// @nodoc
abstract mixin class _$WaitlistMatchRequestCopyWith<$Res> implements $WaitlistMatchRequestCopyWith<$Res> {
  factory _$WaitlistMatchRequestCopyWith(_WaitlistMatchRequest value, $Res Function(_WaitlistMatchRequest) _then) = __$WaitlistMatchRequestCopyWithImpl;
@override @useResult
$Res call({
 String slotId, String serviceId, String providerId, DateTime slotDateTime, String? locationId, int maxCandidates, int autoOfferCount, double minScore
});




}
/// @nodoc
class __$WaitlistMatchRequestCopyWithImpl<$Res>
    implements _$WaitlistMatchRequestCopyWith<$Res> {
  __$WaitlistMatchRequestCopyWithImpl(this._self, this._then);

  final _WaitlistMatchRequest _self;
  final $Res Function(_WaitlistMatchRequest) _then;

/// Create a copy of WaitlistMatchRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slotId = null,Object? serviceId = null,Object? providerId = null,Object? slotDateTime = null,Object? locationId = freezed,Object? maxCandidates = null,Object? autoOfferCount = null,Object? minScore = null,}) {
  return _then(_WaitlistMatchRequest(
slotId: null == slotId ? _self.slotId : slotId // ignore: cast_nullable_to_non_nullable
as String,serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,slotDateTime: null == slotDateTime ? _self.slotDateTime : slotDateTime // ignore: cast_nullable_to_non_nullable
as DateTime,locationId: freezed == locationId ? _self.locationId : locationId // ignore: cast_nullable_to_non_nullable
as String?,maxCandidates: null == maxCandidates ? _self.maxCandidates : maxCandidates // ignore: cast_nullable_to_non_nullable
as int,autoOfferCount: null == autoOfferCount ? _self.autoOfferCount : autoOfferCount // ignore: cast_nullable_to_non_nullable
as int,minScore: null == minScore ? _self.minScore : minScore // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
