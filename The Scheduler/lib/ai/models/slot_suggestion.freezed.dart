// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'slot_suggestion.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScoredSlot {

/// Unique slot identifier
 String get slotId;/// Provider ID for this slot
 String get providerId;/// Provider name for display
 String get providerName;/// Start time of the slot
 DateTime get startTime;/// End time of the slot
 DateTime get endTime;/// Predicted no-show risk for this client in this slot (0.0-1.0)
 double get predictedNoshowRisk;/// Overall score (higher is better) combining all factors
 double get score;/// Whether this slot is recommended for the client
 bool get isRecommended;/// Risk level classification
 SlotRiskLevel get riskLevel;/// Factors contributing to this score
 List<SlotScoreFactor> get scoreFactors;/// Human-readable reasoning for recommendation
 String? get recommendationReason;/// How much better/worse than baseline (percentage)
 double? get riskDifferencePercent;/// Service ID if specific to a service
 String? get serviceId;/// Location ID if relevant
 String? get locationId;/// Whether the slot is currently available
 bool get isAvailable;
/// Create a copy of ScoredSlot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScoredSlotCopyWith<ScoredSlot> get copyWith => _$ScoredSlotCopyWithImpl<ScoredSlot>(this as ScoredSlot, _$identity);

  /// Serializes this ScoredSlot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScoredSlot&&(identical(other.slotId, slotId) || other.slotId == slotId)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.providerName, providerName) || other.providerName == providerName)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.predictedNoshowRisk, predictedNoshowRisk) || other.predictedNoshowRisk == predictedNoshowRisk)&&(identical(other.score, score) || other.score == score)&&(identical(other.isRecommended, isRecommended) || other.isRecommended == isRecommended)&&(identical(other.riskLevel, riskLevel) || other.riskLevel == riskLevel)&&const DeepCollectionEquality().equals(other.scoreFactors, scoreFactors)&&(identical(other.recommendationReason, recommendationReason) || other.recommendationReason == recommendationReason)&&(identical(other.riskDifferencePercent, riskDifferencePercent) || other.riskDifferencePercent == riskDifferencePercent)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.locationId, locationId) || other.locationId == locationId)&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slotId,providerId,providerName,startTime,endTime,predictedNoshowRisk,score,isRecommended,riskLevel,const DeepCollectionEquality().hash(scoreFactors),recommendationReason,riskDifferencePercent,serviceId,locationId,isAvailable);

@override
String toString() {
  return 'ScoredSlot(slotId: $slotId, providerId: $providerId, providerName: $providerName, startTime: $startTime, endTime: $endTime, predictedNoshowRisk: $predictedNoshowRisk, score: $score, isRecommended: $isRecommended, riskLevel: $riskLevel, scoreFactors: $scoreFactors, recommendationReason: $recommendationReason, riskDifferencePercent: $riskDifferencePercent, serviceId: $serviceId, locationId: $locationId, isAvailable: $isAvailable)';
}


}

/// @nodoc
abstract mixin class $ScoredSlotCopyWith<$Res>  {
  factory $ScoredSlotCopyWith(ScoredSlot value, $Res Function(ScoredSlot) _then) = _$ScoredSlotCopyWithImpl;
@useResult
$Res call({
 String slotId, String providerId, String providerName, DateTime startTime, DateTime endTime, double predictedNoshowRisk, double score, bool isRecommended, SlotRiskLevel riskLevel, List<SlotScoreFactor> scoreFactors, String? recommendationReason, double? riskDifferencePercent, String? serviceId, String? locationId, bool isAvailable
});




}
/// @nodoc
class _$ScoredSlotCopyWithImpl<$Res>
    implements $ScoredSlotCopyWith<$Res> {
  _$ScoredSlotCopyWithImpl(this._self, this._then);

  final ScoredSlot _self;
  final $Res Function(ScoredSlot) _then;

/// Create a copy of ScoredSlot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slotId = null,Object? providerId = null,Object? providerName = null,Object? startTime = null,Object? endTime = null,Object? predictedNoshowRisk = null,Object? score = null,Object? isRecommended = null,Object? riskLevel = null,Object? scoreFactors = null,Object? recommendationReason = freezed,Object? riskDifferencePercent = freezed,Object? serviceId = freezed,Object? locationId = freezed,Object? isAvailable = null,}) {
  return _then(_self.copyWith(
slotId: null == slotId ? _self.slotId : slotId // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,providerName: null == providerName ? _self.providerName : providerName // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime,predictedNoshowRisk: null == predictedNoshowRisk ? _self.predictedNoshowRisk : predictedNoshowRisk // ignore: cast_nullable_to_non_nullable
as double,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double,isRecommended: null == isRecommended ? _self.isRecommended : isRecommended // ignore: cast_nullable_to_non_nullable
as bool,riskLevel: null == riskLevel ? _self.riskLevel : riskLevel // ignore: cast_nullable_to_non_nullable
as SlotRiskLevel,scoreFactors: null == scoreFactors ? _self.scoreFactors : scoreFactors // ignore: cast_nullable_to_non_nullable
as List<SlotScoreFactor>,recommendationReason: freezed == recommendationReason ? _self.recommendationReason : recommendationReason // ignore: cast_nullable_to_non_nullable
as String?,riskDifferencePercent: freezed == riskDifferencePercent ? _self.riskDifferencePercent : riskDifferencePercent // ignore: cast_nullable_to_non_nullable
as double?,serviceId: freezed == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String?,locationId: freezed == locationId ? _self.locationId : locationId // ignore: cast_nullable_to_non_nullable
as String?,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ScoredSlot].
extension ScoredSlotPatterns on ScoredSlot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScoredSlot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScoredSlot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScoredSlot value)  $default,){
final _that = this;
switch (_that) {
case _ScoredSlot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScoredSlot value)?  $default,){
final _that = this;
switch (_that) {
case _ScoredSlot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String slotId,  String providerId,  String providerName,  DateTime startTime,  DateTime endTime,  double predictedNoshowRisk,  double score,  bool isRecommended,  SlotRiskLevel riskLevel,  List<SlotScoreFactor> scoreFactors,  String? recommendationReason,  double? riskDifferencePercent,  String? serviceId,  String? locationId,  bool isAvailable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScoredSlot() when $default != null:
return $default(_that.slotId,_that.providerId,_that.providerName,_that.startTime,_that.endTime,_that.predictedNoshowRisk,_that.score,_that.isRecommended,_that.riskLevel,_that.scoreFactors,_that.recommendationReason,_that.riskDifferencePercent,_that.serviceId,_that.locationId,_that.isAvailable);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String slotId,  String providerId,  String providerName,  DateTime startTime,  DateTime endTime,  double predictedNoshowRisk,  double score,  bool isRecommended,  SlotRiskLevel riskLevel,  List<SlotScoreFactor> scoreFactors,  String? recommendationReason,  double? riskDifferencePercent,  String? serviceId,  String? locationId,  bool isAvailable)  $default,) {final _that = this;
switch (_that) {
case _ScoredSlot():
return $default(_that.slotId,_that.providerId,_that.providerName,_that.startTime,_that.endTime,_that.predictedNoshowRisk,_that.score,_that.isRecommended,_that.riskLevel,_that.scoreFactors,_that.recommendationReason,_that.riskDifferencePercent,_that.serviceId,_that.locationId,_that.isAvailable);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String slotId,  String providerId,  String providerName,  DateTime startTime,  DateTime endTime,  double predictedNoshowRisk,  double score,  bool isRecommended,  SlotRiskLevel riskLevel,  List<SlotScoreFactor> scoreFactors,  String? recommendationReason,  double? riskDifferencePercent,  String? serviceId,  String? locationId,  bool isAvailable)?  $default,) {final _that = this;
switch (_that) {
case _ScoredSlot() when $default != null:
return $default(_that.slotId,_that.providerId,_that.providerName,_that.startTime,_that.endTime,_that.predictedNoshowRisk,_that.score,_that.isRecommended,_that.riskLevel,_that.scoreFactors,_that.recommendationReason,_that.riskDifferencePercent,_that.serviceId,_that.locationId,_that.isAvailable);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScoredSlot extends ScoredSlot {
  const _ScoredSlot({required this.slotId, required this.providerId, required this.providerName, required this.startTime, required this.endTime, required this.predictedNoshowRisk, required this.score, required this.isRecommended, required this.riskLevel, required final  List<SlotScoreFactor> scoreFactors, this.recommendationReason, this.riskDifferencePercent, this.serviceId, this.locationId, this.isAvailable = true}): _scoreFactors = scoreFactors,super._();
  factory _ScoredSlot.fromJson(Map<String, dynamic> json) => _$ScoredSlotFromJson(json);

/// Unique slot identifier
@override final  String slotId;
/// Provider ID for this slot
@override final  String providerId;
/// Provider name for display
@override final  String providerName;
/// Start time of the slot
@override final  DateTime startTime;
/// End time of the slot
@override final  DateTime endTime;
/// Predicted no-show risk for this client in this slot (0.0-1.0)
@override final  double predictedNoshowRisk;
/// Overall score (higher is better) combining all factors
@override final  double score;
/// Whether this slot is recommended for the client
@override final  bool isRecommended;
/// Risk level classification
@override final  SlotRiskLevel riskLevel;
/// Factors contributing to this score
 final  List<SlotScoreFactor> _scoreFactors;
/// Factors contributing to this score
@override List<SlotScoreFactor> get scoreFactors {
  if (_scoreFactors is EqualUnmodifiableListView) return _scoreFactors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_scoreFactors);
}

/// Human-readable reasoning for recommendation
@override final  String? recommendationReason;
/// How much better/worse than baseline (percentage)
@override final  double? riskDifferencePercent;
/// Service ID if specific to a service
@override final  String? serviceId;
/// Location ID if relevant
@override final  String? locationId;
/// Whether the slot is currently available
@override@JsonKey() final  bool isAvailable;

/// Create a copy of ScoredSlot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScoredSlotCopyWith<_ScoredSlot> get copyWith => __$ScoredSlotCopyWithImpl<_ScoredSlot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScoredSlotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScoredSlot&&(identical(other.slotId, slotId) || other.slotId == slotId)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.providerName, providerName) || other.providerName == providerName)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.predictedNoshowRisk, predictedNoshowRisk) || other.predictedNoshowRisk == predictedNoshowRisk)&&(identical(other.score, score) || other.score == score)&&(identical(other.isRecommended, isRecommended) || other.isRecommended == isRecommended)&&(identical(other.riskLevel, riskLevel) || other.riskLevel == riskLevel)&&const DeepCollectionEquality().equals(other._scoreFactors, _scoreFactors)&&(identical(other.recommendationReason, recommendationReason) || other.recommendationReason == recommendationReason)&&(identical(other.riskDifferencePercent, riskDifferencePercent) || other.riskDifferencePercent == riskDifferencePercent)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.locationId, locationId) || other.locationId == locationId)&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slotId,providerId,providerName,startTime,endTime,predictedNoshowRisk,score,isRecommended,riskLevel,const DeepCollectionEquality().hash(_scoreFactors),recommendationReason,riskDifferencePercent,serviceId,locationId,isAvailable);

@override
String toString() {
  return 'ScoredSlot(slotId: $slotId, providerId: $providerId, providerName: $providerName, startTime: $startTime, endTime: $endTime, predictedNoshowRisk: $predictedNoshowRisk, score: $score, isRecommended: $isRecommended, riskLevel: $riskLevel, scoreFactors: $scoreFactors, recommendationReason: $recommendationReason, riskDifferencePercent: $riskDifferencePercent, serviceId: $serviceId, locationId: $locationId, isAvailable: $isAvailable)';
}


}

/// @nodoc
abstract mixin class _$ScoredSlotCopyWith<$Res> implements $ScoredSlotCopyWith<$Res> {
  factory _$ScoredSlotCopyWith(_ScoredSlot value, $Res Function(_ScoredSlot) _then) = __$ScoredSlotCopyWithImpl;
@override @useResult
$Res call({
 String slotId, String providerId, String providerName, DateTime startTime, DateTime endTime, double predictedNoshowRisk, double score, bool isRecommended, SlotRiskLevel riskLevel, List<SlotScoreFactor> scoreFactors, String? recommendationReason, double? riskDifferencePercent, String? serviceId, String? locationId, bool isAvailable
});




}
/// @nodoc
class __$ScoredSlotCopyWithImpl<$Res>
    implements _$ScoredSlotCopyWith<$Res> {
  __$ScoredSlotCopyWithImpl(this._self, this._then);

  final _ScoredSlot _self;
  final $Res Function(_ScoredSlot) _then;

/// Create a copy of ScoredSlot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slotId = null,Object? providerId = null,Object? providerName = null,Object? startTime = null,Object? endTime = null,Object? predictedNoshowRisk = null,Object? score = null,Object? isRecommended = null,Object? riskLevel = null,Object? scoreFactors = null,Object? recommendationReason = freezed,Object? riskDifferencePercent = freezed,Object? serviceId = freezed,Object? locationId = freezed,Object? isAvailable = null,}) {
  return _then(_ScoredSlot(
slotId: null == slotId ? _self.slotId : slotId // ignore: cast_nullable_to_non_nullable
as String,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,providerName: null == providerName ? _self.providerName : providerName // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime,predictedNoshowRisk: null == predictedNoshowRisk ? _self.predictedNoshowRisk : predictedNoshowRisk // ignore: cast_nullable_to_non_nullable
as double,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double,isRecommended: null == isRecommended ? _self.isRecommended : isRecommended // ignore: cast_nullable_to_non_nullable
as bool,riskLevel: null == riskLevel ? _self.riskLevel : riskLevel // ignore: cast_nullable_to_non_nullable
as SlotRiskLevel,scoreFactors: null == scoreFactors ? _self._scoreFactors : scoreFactors // ignore: cast_nullable_to_non_nullable
as List<SlotScoreFactor>,recommendationReason: freezed == recommendationReason ? _self.recommendationReason : recommendationReason // ignore: cast_nullable_to_non_nullable
as String?,riskDifferencePercent: freezed == riskDifferencePercent ? _self.riskDifferencePercent : riskDifferencePercent // ignore: cast_nullable_to_non_nullable
as double?,serviceId: freezed == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String?,locationId: freezed == locationId ? _self.locationId : locationId // ignore: cast_nullable_to_non_nullable
as String?,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$SlotScoreFactor {

/// Factor type (e.g., "day_of_week", "hour", "provider", "lead_time")
 String get factorType;/// Human-readable description
 String get description;/// Impact on score (-1.0 to 1.0, negative is bad, positive is good)
 double get impact;/// Weight of this factor in overall score (0.0-1.0)
 double get weight;/// Icon name for UI display
 String? get iconName;
/// Create a copy of SlotScoreFactor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SlotScoreFactorCopyWith<SlotScoreFactor> get copyWith => _$SlotScoreFactorCopyWithImpl<SlotScoreFactor>(this as SlotScoreFactor, _$identity);

  /// Serializes this SlotScoreFactor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SlotScoreFactor&&(identical(other.factorType, factorType) || other.factorType == factorType)&&(identical(other.description, description) || other.description == description)&&(identical(other.impact, impact) || other.impact == impact)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.iconName, iconName) || other.iconName == iconName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,factorType,description,impact,weight,iconName);

@override
String toString() {
  return 'SlotScoreFactor(factorType: $factorType, description: $description, impact: $impact, weight: $weight, iconName: $iconName)';
}


}

/// @nodoc
abstract mixin class $SlotScoreFactorCopyWith<$Res>  {
  factory $SlotScoreFactorCopyWith(SlotScoreFactor value, $Res Function(SlotScoreFactor) _then) = _$SlotScoreFactorCopyWithImpl;
@useResult
$Res call({
 String factorType, String description, double impact, double weight, String? iconName
});




}
/// @nodoc
class _$SlotScoreFactorCopyWithImpl<$Res>
    implements $SlotScoreFactorCopyWith<$Res> {
  _$SlotScoreFactorCopyWithImpl(this._self, this._then);

  final SlotScoreFactor _self;
  final $Res Function(SlotScoreFactor) _then;

/// Create a copy of SlotScoreFactor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? factorType = null,Object? description = null,Object? impact = null,Object? weight = null,Object? iconName = freezed,}) {
  return _then(_self.copyWith(
factorType: null == factorType ? _self.factorType : factorType // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,impact: null == impact ? _self.impact : impact // ignore: cast_nullable_to_non_nullable
as double,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SlotScoreFactor].
extension SlotScoreFactorPatterns on SlotScoreFactor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SlotScoreFactor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SlotScoreFactor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SlotScoreFactor value)  $default,){
final _that = this;
switch (_that) {
case _SlotScoreFactor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SlotScoreFactor value)?  $default,){
final _that = this;
switch (_that) {
case _SlotScoreFactor() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String factorType,  String description,  double impact,  double weight,  String? iconName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SlotScoreFactor() when $default != null:
return $default(_that.factorType,_that.description,_that.impact,_that.weight,_that.iconName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String factorType,  String description,  double impact,  double weight,  String? iconName)  $default,) {final _that = this;
switch (_that) {
case _SlotScoreFactor():
return $default(_that.factorType,_that.description,_that.impact,_that.weight,_that.iconName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String factorType,  String description,  double impact,  double weight,  String? iconName)?  $default,) {final _that = this;
switch (_that) {
case _SlotScoreFactor() when $default != null:
return $default(_that.factorType,_that.description,_that.impact,_that.weight,_that.iconName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SlotScoreFactor implements SlotScoreFactor {
  const _SlotScoreFactor({required this.factorType, required this.description, required this.impact, required this.weight, this.iconName});
  factory _SlotScoreFactor.fromJson(Map<String, dynamic> json) => _$SlotScoreFactorFromJson(json);

/// Factor type (e.g., "day_of_week", "hour", "provider", "lead_time")
@override final  String factorType;
/// Human-readable description
@override final  String description;
/// Impact on score (-1.0 to 1.0, negative is bad, positive is good)
@override final  double impact;
/// Weight of this factor in overall score (0.0-1.0)
@override final  double weight;
/// Icon name for UI display
@override final  String? iconName;

/// Create a copy of SlotScoreFactor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SlotScoreFactorCopyWith<_SlotScoreFactor> get copyWith => __$SlotScoreFactorCopyWithImpl<_SlotScoreFactor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SlotScoreFactorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SlotScoreFactor&&(identical(other.factorType, factorType) || other.factorType == factorType)&&(identical(other.description, description) || other.description == description)&&(identical(other.impact, impact) || other.impact == impact)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.iconName, iconName) || other.iconName == iconName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,factorType,description,impact,weight,iconName);

@override
String toString() {
  return 'SlotScoreFactor(factorType: $factorType, description: $description, impact: $impact, weight: $weight, iconName: $iconName)';
}


}

/// @nodoc
abstract mixin class _$SlotScoreFactorCopyWith<$Res> implements $SlotScoreFactorCopyWith<$Res> {
  factory _$SlotScoreFactorCopyWith(_SlotScoreFactor value, $Res Function(_SlotScoreFactor) _then) = __$SlotScoreFactorCopyWithImpl;
@override @useResult
$Res call({
 String factorType, String description, double impact, double weight, String? iconName
});




}
/// @nodoc
class __$SlotScoreFactorCopyWithImpl<$Res>
    implements _$SlotScoreFactorCopyWith<$Res> {
  __$SlotScoreFactorCopyWithImpl(this._self, this._then);

  final _SlotScoreFactor _self;
  final $Res Function(_SlotScoreFactor) _then;

/// Create a copy of SlotScoreFactor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? factorType = null,Object? description = null,Object? impact = null,Object? weight = null,Object? iconName = freezed,}) {
  return _then(_SlotScoreFactor(
factorType: null == factorType ? _self.factorType : factorType // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,impact: null == impact ? _self.impact : impact // ignore: cast_nullable_to_non_nullable
as double,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SlotSuggestion {

/// The scored slot
 ScoredSlot get slot;/// Rank in the suggestion list (1 = best)
 int get rank;/// Main recommendation text
 String get headline;/// Detailed reasoning for this suggestion
 String get reasoning;/// Comparison to client's baseline risk
 String? get comparisonText;/// Alternative slots if this one is high risk
 List<ScoredSlot> get alternatives;/// Confidence in this suggestion (0.0-1.0)
 double get confidence;
/// Create a copy of SlotSuggestion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SlotSuggestionCopyWith<SlotSuggestion> get copyWith => _$SlotSuggestionCopyWithImpl<SlotSuggestion>(this as SlotSuggestion, _$identity);

  /// Serializes this SlotSuggestion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SlotSuggestion&&(identical(other.slot, slot) || other.slot == slot)&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.headline, headline) || other.headline == headline)&&(identical(other.reasoning, reasoning) || other.reasoning == reasoning)&&(identical(other.comparisonText, comparisonText) || other.comparisonText == comparisonText)&&const DeepCollectionEquality().equals(other.alternatives, alternatives)&&(identical(other.confidence, confidence) || other.confidence == confidence));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slot,rank,headline,reasoning,comparisonText,const DeepCollectionEquality().hash(alternatives),confidence);

@override
String toString() {
  return 'SlotSuggestion(slot: $slot, rank: $rank, headline: $headline, reasoning: $reasoning, comparisonText: $comparisonText, alternatives: $alternatives, confidence: $confidence)';
}


}

/// @nodoc
abstract mixin class $SlotSuggestionCopyWith<$Res>  {
  factory $SlotSuggestionCopyWith(SlotSuggestion value, $Res Function(SlotSuggestion) _then) = _$SlotSuggestionCopyWithImpl;
@useResult
$Res call({
 ScoredSlot slot, int rank, String headline, String reasoning, String? comparisonText, List<ScoredSlot> alternatives, double confidence
});


$ScoredSlotCopyWith<$Res> get slot;

}
/// @nodoc
class _$SlotSuggestionCopyWithImpl<$Res>
    implements $SlotSuggestionCopyWith<$Res> {
  _$SlotSuggestionCopyWithImpl(this._self, this._then);

  final SlotSuggestion _self;
  final $Res Function(SlotSuggestion) _then;

/// Create a copy of SlotSuggestion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slot = null,Object? rank = null,Object? headline = null,Object? reasoning = null,Object? comparisonText = freezed,Object? alternatives = null,Object? confidence = null,}) {
  return _then(_self.copyWith(
slot: null == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as ScoredSlot,rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int,headline: null == headline ? _self.headline : headline // ignore: cast_nullable_to_non_nullable
as String,reasoning: null == reasoning ? _self.reasoning : reasoning // ignore: cast_nullable_to_non_nullable
as String,comparisonText: freezed == comparisonText ? _self.comparisonText : comparisonText // ignore: cast_nullable_to_non_nullable
as String?,alternatives: null == alternatives ? _self.alternatives : alternatives // ignore: cast_nullable_to_non_nullable
as List<ScoredSlot>,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,
  ));
}
/// Create a copy of SlotSuggestion
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScoredSlotCopyWith<$Res> get slot {
  
  return $ScoredSlotCopyWith<$Res>(_self.slot, (value) {
    return _then(_self.copyWith(slot: value));
  });
}
}


/// Adds pattern-matching-related methods to [SlotSuggestion].
extension SlotSuggestionPatterns on SlotSuggestion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SlotSuggestion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SlotSuggestion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SlotSuggestion value)  $default,){
final _that = this;
switch (_that) {
case _SlotSuggestion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SlotSuggestion value)?  $default,){
final _that = this;
switch (_that) {
case _SlotSuggestion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ScoredSlot slot,  int rank,  String headline,  String reasoning,  String? comparisonText,  List<ScoredSlot> alternatives,  double confidence)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SlotSuggestion() when $default != null:
return $default(_that.slot,_that.rank,_that.headline,_that.reasoning,_that.comparisonText,_that.alternatives,_that.confidence);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ScoredSlot slot,  int rank,  String headline,  String reasoning,  String? comparisonText,  List<ScoredSlot> alternatives,  double confidence)  $default,) {final _that = this;
switch (_that) {
case _SlotSuggestion():
return $default(_that.slot,_that.rank,_that.headline,_that.reasoning,_that.comparisonText,_that.alternatives,_that.confidence);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ScoredSlot slot,  int rank,  String headline,  String reasoning,  String? comparisonText,  List<ScoredSlot> alternatives,  double confidence)?  $default,) {final _that = this;
switch (_that) {
case _SlotSuggestion() when $default != null:
return $default(_that.slot,_that.rank,_that.headline,_that.reasoning,_that.comparisonText,_that.alternatives,_that.confidence);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SlotSuggestion extends SlotSuggestion {
  const _SlotSuggestion({required this.slot, required this.rank, required this.headline, required this.reasoning, this.comparisonText, final  List<ScoredSlot> alternatives = const [], required this.confidence}): _alternatives = alternatives,super._();
  factory _SlotSuggestion.fromJson(Map<String, dynamic> json) => _$SlotSuggestionFromJson(json);

/// The scored slot
@override final  ScoredSlot slot;
/// Rank in the suggestion list (1 = best)
@override final  int rank;
/// Main recommendation text
@override final  String headline;
/// Detailed reasoning for this suggestion
@override final  String reasoning;
/// Comparison to client's baseline risk
@override final  String? comparisonText;
/// Alternative slots if this one is high risk
 final  List<ScoredSlot> _alternatives;
/// Alternative slots if this one is high risk
@override@JsonKey() List<ScoredSlot> get alternatives {
  if (_alternatives is EqualUnmodifiableListView) return _alternatives;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_alternatives);
}

/// Confidence in this suggestion (0.0-1.0)
@override final  double confidence;

/// Create a copy of SlotSuggestion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SlotSuggestionCopyWith<_SlotSuggestion> get copyWith => __$SlotSuggestionCopyWithImpl<_SlotSuggestion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SlotSuggestionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SlotSuggestion&&(identical(other.slot, slot) || other.slot == slot)&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.headline, headline) || other.headline == headline)&&(identical(other.reasoning, reasoning) || other.reasoning == reasoning)&&(identical(other.comparisonText, comparisonText) || other.comparisonText == comparisonText)&&const DeepCollectionEquality().equals(other._alternatives, _alternatives)&&(identical(other.confidence, confidence) || other.confidence == confidence));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slot,rank,headline,reasoning,comparisonText,const DeepCollectionEquality().hash(_alternatives),confidence);

@override
String toString() {
  return 'SlotSuggestion(slot: $slot, rank: $rank, headline: $headline, reasoning: $reasoning, comparisonText: $comparisonText, alternatives: $alternatives, confidence: $confidence)';
}


}

/// @nodoc
abstract mixin class _$SlotSuggestionCopyWith<$Res> implements $SlotSuggestionCopyWith<$Res> {
  factory _$SlotSuggestionCopyWith(_SlotSuggestion value, $Res Function(_SlotSuggestion) _then) = __$SlotSuggestionCopyWithImpl;
@override @useResult
$Res call({
 ScoredSlot slot, int rank, String headline, String reasoning, String? comparisonText, List<ScoredSlot> alternatives, double confidence
});


@override $ScoredSlotCopyWith<$Res> get slot;

}
/// @nodoc
class __$SlotSuggestionCopyWithImpl<$Res>
    implements _$SlotSuggestionCopyWith<$Res> {
  __$SlotSuggestionCopyWithImpl(this._self, this._then);

  final _SlotSuggestion _self;
  final $Res Function(_SlotSuggestion) _then;

/// Create a copy of SlotSuggestion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slot = null,Object? rank = null,Object? headline = null,Object? reasoning = null,Object? comparisonText = freezed,Object? alternatives = null,Object? confidence = null,}) {
  return _then(_SlotSuggestion(
slot: null == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as ScoredSlot,rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int,headline: null == headline ? _self.headline : headline // ignore: cast_nullable_to_non_nullable
as String,reasoning: null == reasoning ? _self.reasoning : reasoning // ignore: cast_nullable_to_non_nullable
as String,comparisonText: freezed == comparisonText ? _self.comparisonText : comparisonText // ignore: cast_nullable_to_non_nullable
as String?,alternatives: null == alternatives ? _self._alternatives : alternatives // ignore: cast_nullable_to_non_nullable
as List<ScoredSlot>,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

/// Create a copy of SlotSuggestion
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScoredSlotCopyWith<$Res> get slot {
  
  return $ScoredSlotCopyWith<$Res>(_self.slot, (value) {
    return _then(_self.copyWith(slot: value));
  });
}
}


/// @nodoc
mixin _$SlotSuggestionResult {

/// Client ID these suggestions are for
 String get clientId;/// Service being booked
 String get serviceId;/// All scored slots, sorted by score (best first)
 List<ScoredSlot> get scoredSlots;/// Top recommendations (typically top 3)
 List<SlotSuggestion> get topSuggestions;/// Slots to avoid (high risk)
 List<ScoredSlot> get slotsToAvoid;/// Client's baseline no-show rate for comparison
 double get clientBaselineNoshowRate;/// Average risk across all available slots
 double get averageSlotRisk;/// Best available slot
 ScoredSlot? get bestSlot;/// When this result was generated
 DateTime get generatedAt;/// Whether client has enough history for reliable suggestions
 bool get hasReliableHistory;/// Message if no reliable history
 String? get insufficientHistoryMessage;
/// Create a copy of SlotSuggestionResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SlotSuggestionResultCopyWith<SlotSuggestionResult> get copyWith => _$SlotSuggestionResultCopyWithImpl<SlotSuggestionResult>(this as SlotSuggestionResult, _$identity);

  /// Serializes this SlotSuggestionResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SlotSuggestionResult&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&const DeepCollectionEquality().equals(other.scoredSlots, scoredSlots)&&const DeepCollectionEquality().equals(other.topSuggestions, topSuggestions)&&const DeepCollectionEquality().equals(other.slotsToAvoid, slotsToAvoid)&&(identical(other.clientBaselineNoshowRate, clientBaselineNoshowRate) || other.clientBaselineNoshowRate == clientBaselineNoshowRate)&&(identical(other.averageSlotRisk, averageSlotRisk) || other.averageSlotRisk == averageSlotRisk)&&(identical(other.bestSlot, bestSlot) || other.bestSlot == bestSlot)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.hasReliableHistory, hasReliableHistory) || other.hasReliableHistory == hasReliableHistory)&&(identical(other.insufficientHistoryMessage, insufficientHistoryMessage) || other.insufficientHistoryMessage == insufficientHistoryMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,clientId,serviceId,const DeepCollectionEquality().hash(scoredSlots),const DeepCollectionEquality().hash(topSuggestions),const DeepCollectionEquality().hash(slotsToAvoid),clientBaselineNoshowRate,averageSlotRisk,bestSlot,generatedAt,hasReliableHistory,insufficientHistoryMessage);

@override
String toString() {
  return 'SlotSuggestionResult(clientId: $clientId, serviceId: $serviceId, scoredSlots: $scoredSlots, topSuggestions: $topSuggestions, slotsToAvoid: $slotsToAvoid, clientBaselineNoshowRate: $clientBaselineNoshowRate, averageSlotRisk: $averageSlotRisk, bestSlot: $bestSlot, generatedAt: $generatedAt, hasReliableHistory: $hasReliableHistory, insufficientHistoryMessage: $insufficientHistoryMessage)';
}


}

/// @nodoc
abstract mixin class $SlotSuggestionResultCopyWith<$Res>  {
  factory $SlotSuggestionResultCopyWith(SlotSuggestionResult value, $Res Function(SlotSuggestionResult) _then) = _$SlotSuggestionResultCopyWithImpl;
@useResult
$Res call({
 String clientId, String serviceId, List<ScoredSlot> scoredSlots, List<SlotSuggestion> topSuggestions, List<ScoredSlot> slotsToAvoid, double clientBaselineNoshowRate, double averageSlotRisk, ScoredSlot? bestSlot, DateTime generatedAt, bool hasReliableHistory, String? insufficientHistoryMessage
});


$ScoredSlotCopyWith<$Res>? get bestSlot;

}
/// @nodoc
class _$SlotSuggestionResultCopyWithImpl<$Res>
    implements $SlotSuggestionResultCopyWith<$Res> {
  _$SlotSuggestionResultCopyWithImpl(this._self, this._then);

  final SlotSuggestionResult _self;
  final $Res Function(SlotSuggestionResult) _then;

/// Create a copy of SlotSuggestionResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? clientId = null,Object? serviceId = null,Object? scoredSlots = null,Object? topSuggestions = null,Object? slotsToAvoid = null,Object? clientBaselineNoshowRate = null,Object? averageSlotRisk = null,Object? bestSlot = freezed,Object? generatedAt = null,Object? hasReliableHistory = null,Object? insufficientHistoryMessage = freezed,}) {
  return _then(_self.copyWith(
clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String,scoredSlots: null == scoredSlots ? _self.scoredSlots : scoredSlots // ignore: cast_nullable_to_non_nullable
as List<ScoredSlot>,topSuggestions: null == topSuggestions ? _self.topSuggestions : topSuggestions // ignore: cast_nullable_to_non_nullable
as List<SlotSuggestion>,slotsToAvoid: null == slotsToAvoid ? _self.slotsToAvoid : slotsToAvoid // ignore: cast_nullable_to_non_nullable
as List<ScoredSlot>,clientBaselineNoshowRate: null == clientBaselineNoshowRate ? _self.clientBaselineNoshowRate : clientBaselineNoshowRate // ignore: cast_nullable_to_non_nullable
as double,averageSlotRisk: null == averageSlotRisk ? _self.averageSlotRisk : averageSlotRisk // ignore: cast_nullable_to_non_nullable
as double,bestSlot: freezed == bestSlot ? _self.bestSlot : bestSlot // ignore: cast_nullable_to_non_nullable
as ScoredSlot?,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,hasReliableHistory: null == hasReliableHistory ? _self.hasReliableHistory : hasReliableHistory // ignore: cast_nullable_to_non_nullable
as bool,insufficientHistoryMessage: freezed == insufficientHistoryMessage ? _self.insufficientHistoryMessage : insufficientHistoryMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of SlotSuggestionResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScoredSlotCopyWith<$Res>? get bestSlot {
    if (_self.bestSlot == null) {
    return null;
  }

  return $ScoredSlotCopyWith<$Res>(_self.bestSlot!, (value) {
    return _then(_self.copyWith(bestSlot: value));
  });
}
}


/// Adds pattern-matching-related methods to [SlotSuggestionResult].
extension SlotSuggestionResultPatterns on SlotSuggestionResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SlotSuggestionResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SlotSuggestionResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SlotSuggestionResult value)  $default,){
final _that = this;
switch (_that) {
case _SlotSuggestionResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SlotSuggestionResult value)?  $default,){
final _that = this;
switch (_that) {
case _SlotSuggestionResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String clientId,  String serviceId,  List<ScoredSlot> scoredSlots,  List<SlotSuggestion> topSuggestions,  List<ScoredSlot> slotsToAvoid,  double clientBaselineNoshowRate,  double averageSlotRisk,  ScoredSlot? bestSlot,  DateTime generatedAt,  bool hasReliableHistory,  String? insufficientHistoryMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SlotSuggestionResult() when $default != null:
return $default(_that.clientId,_that.serviceId,_that.scoredSlots,_that.topSuggestions,_that.slotsToAvoid,_that.clientBaselineNoshowRate,_that.averageSlotRisk,_that.bestSlot,_that.generatedAt,_that.hasReliableHistory,_that.insufficientHistoryMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String clientId,  String serviceId,  List<ScoredSlot> scoredSlots,  List<SlotSuggestion> topSuggestions,  List<ScoredSlot> slotsToAvoid,  double clientBaselineNoshowRate,  double averageSlotRisk,  ScoredSlot? bestSlot,  DateTime generatedAt,  bool hasReliableHistory,  String? insufficientHistoryMessage)  $default,) {final _that = this;
switch (_that) {
case _SlotSuggestionResult():
return $default(_that.clientId,_that.serviceId,_that.scoredSlots,_that.topSuggestions,_that.slotsToAvoid,_that.clientBaselineNoshowRate,_that.averageSlotRisk,_that.bestSlot,_that.generatedAt,_that.hasReliableHistory,_that.insufficientHistoryMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String clientId,  String serviceId,  List<ScoredSlot> scoredSlots,  List<SlotSuggestion> topSuggestions,  List<ScoredSlot> slotsToAvoid,  double clientBaselineNoshowRate,  double averageSlotRisk,  ScoredSlot? bestSlot,  DateTime generatedAt,  bool hasReliableHistory,  String? insufficientHistoryMessage)?  $default,) {final _that = this;
switch (_that) {
case _SlotSuggestionResult() when $default != null:
return $default(_that.clientId,_that.serviceId,_that.scoredSlots,_that.topSuggestions,_that.slotsToAvoid,_that.clientBaselineNoshowRate,_that.averageSlotRisk,_that.bestSlot,_that.generatedAt,_that.hasReliableHistory,_that.insufficientHistoryMessage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SlotSuggestionResult extends SlotSuggestionResult {
  const _SlotSuggestionResult({required this.clientId, required this.serviceId, required final  List<ScoredSlot> scoredSlots, required final  List<SlotSuggestion> topSuggestions, required final  List<ScoredSlot> slotsToAvoid, required this.clientBaselineNoshowRate, required this.averageSlotRisk, this.bestSlot, required this.generatedAt, required this.hasReliableHistory, this.insufficientHistoryMessage}): _scoredSlots = scoredSlots,_topSuggestions = topSuggestions,_slotsToAvoid = slotsToAvoid,super._();
  factory _SlotSuggestionResult.fromJson(Map<String, dynamic> json) => _$SlotSuggestionResultFromJson(json);

/// Client ID these suggestions are for
@override final  String clientId;
/// Service being booked
@override final  String serviceId;
/// All scored slots, sorted by score (best first)
 final  List<ScoredSlot> _scoredSlots;
/// All scored slots, sorted by score (best first)
@override List<ScoredSlot> get scoredSlots {
  if (_scoredSlots is EqualUnmodifiableListView) return _scoredSlots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_scoredSlots);
}

/// Top recommendations (typically top 3)
 final  List<SlotSuggestion> _topSuggestions;
/// Top recommendations (typically top 3)
@override List<SlotSuggestion> get topSuggestions {
  if (_topSuggestions is EqualUnmodifiableListView) return _topSuggestions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topSuggestions);
}

/// Slots to avoid (high risk)
 final  List<ScoredSlot> _slotsToAvoid;
/// Slots to avoid (high risk)
@override List<ScoredSlot> get slotsToAvoid {
  if (_slotsToAvoid is EqualUnmodifiableListView) return _slotsToAvoid;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_slotsToAvoid);
}

/// Client's baseline no-show rate for comparison
@override final  double clientBaselineNoshowRate;
/// Average risk across all available slots
@override final  double averageSlotRisk;
/// Best available slot
@override final  ScoredSlot? bestSlot;
/// When this result was generated
@override final  DateTime generatedAt;
/// Whether client has enough history for reliable suggestions
@override final  bool hasReliableHistory;
/// Message if no reliable history
@override final  String? insufficientHistoryMessage;

/// Create a copy of SlotSuggestionResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SlotSuggestionResultCopyWith<_SlotSuggestionResult> get copyWith => __$SlotSuggestionResultCopyWithImpl<_SlotSuggestionResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SlotSuggestionResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SlotSuggestionResult&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&const DeepCollectionEquality().equals(other._scoredSlots, _scoredSlots)&&const DeepCollectionEquality().equals(other._topSuggestions, _topSuggestions)&&const DeepCollectionEquality().equals(other._slotsToAvoid, _slotsToAvoid)&&(identical(other.clientBaselineNoshowRate, clientBaselineNoshowRate) || other.clientBaselineNoshowRate == clientBaselineNoshowRate)&&(identical(other.averageSlotRisk, averageSlotRisk) || other.averageSlotRisk == averageSlotRisk)&&(identical(other.bestSlot, bestSlot) || other.bestSlot == bestSlot)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.hasReliableHistory, hasReliableHistory) || other.hasReliableHistory == hasReliableHistory)&&(identical(other.insufficientHistoryMessage, insufficientHistoryMessage) || other.insufficientHistoryMessage == insufficientHistoryMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,clientId,serviceId,const DeepCollectionEquality().hash(_scoredSlots),const DeepCollectionEquality().hash(_topSuggestions),const DeepCollectionEquality().hash(_slotsToAvoid),clientBaselineNoshowRate,averageSlotRisk,bestSlot,generatedAt,hasReliableHistory,insufficientHistoryMessage);

@override
String toString() {
  return 'SlotSuggestionResult(clientId: $clientId, serviceId: $serviceId, scoredSlots: $scoredSlots, topSuggestions: $topSuggestions, slotsToAvoid: $slotsToAvoid, clientBaselineNoshowRate: $clientBaselineNoshowRate, averageSlotRisk: $averageSlotRisk, bestSlot: $bestSlot, generatedAt: $generatedAt, hasReliableHistory: $hasReliableHistory, insufficientHistoryMessage: $insufficientHistoryMessage)';
}


}

/// @nodoc
abstract mixin class _$SlotSuggestionResultCopyWith<$Res> implements $SlotSuggestionResultCopyWith<$Res> {
  factory _$SlotSuggestionResultCopyWith(_SlotSuggestionResult value, $Res Function(_SlotSuggestionResult) _then) = __$SlotSuggestionResultCopyWithImpl;
@override @useResult
$Res call({
 String clientId, String serviceId, List<ScoredSlot> scoredSlots, List<SlotSuggestion> topSuggestions, List<ScoredSlot> slotsToAvoid, double clientBaselineNoshowRate, double averageSlotRisk, ScoredSlot? bestSlot, DateTime generatedAt, bool hasReliableHistory, String? insufficientHistoryMessage
});


@override $ScoredSlotCopyWith<$Res>? get bestSlot;

}
/// @nodoc
class __$SlotSuggestionResultCopyWithImpl<$Res>
    implements _$SlotSuggestionResultCopyWith<$Res> {
  __$SlotSuggestionResultCopyWithImpl(this._self, this._then);

  final _SlotSuggestionResult _self;
  final $Res Function(_SlotSuggestionResult) _then;

/// Create a copy of SlotSuggestionResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? clientId = null,Object? serviceId = null,Object? scoredSlots = null,Object? topSuggestions = null,Object? slotsToAvoid = null,Object? clientBaselineNoshowRate = null,Object? averageSlotRisk = null,Object? bestSlot = freezed,Object? generatedAt = null,Object? hasReliableHistory = null,Object? insufficientHistoryMessage = freezed,}) {
  return _then(_SlotSuggestionResult(
clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String,scoredSlots: null == scoredSlots ? _self._scoredSlots : scoredSlots // ignore: cast_nullable_to_non_nullable
as List<ScoredSlot>,topSuggestions: null == topSuggestions ? _self._topSuggestions : topSuggestions // ignore: cast_nullable_to_non_nullable
as List<SlotSuggestion>,slotsToAvoid: null == slotsToAvoid ? _self._slotsToAvoid : slotsToAvoid // ignore: cast_nullable_to_non_nullable
as List<ScoredSlot>,clientBaselineNoshowRate: null == clientBaselineNoshowRate ? _self.clientBaselineNoshowRate : clientBaselineNoshowRate // ignore: cast_nullable_to_non_nullable
as double,averageSlotRisk: null == averageSlotRisk ? _self.averageSlotRisk : averageSlotRisk // ignore: cast_nullable_to_non_nullable
as double,bestSlot: freezed == bestSlot ? _self.bestSlot : bestSlot // ignore: cast_nullable_to_non_nullable
as ScoredSlot?,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,hasReliableHistory: null == hasReliableHistory ? _self.hasReliableHistory : hasReliableHistory // ignore: cast_nullable_to_non_nullable
as bool,insufficientHistoryMessage: freezed == insufficientHistoryMessage ? _self.insufficientHistoryMessage : insufficientHistoryMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of SlotSuggestionResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScoredSlotCopyWith<$Res>? get bestSlot {
    if (_self.bestSlot == null) {
    return null;
  }

  return $ScoredSlotCopyWith<$Res>(_self.bestSlot!, (value) {
    return _then(_self.copyWith(bestSlot: value));
  });
}
}


/// @nodoc
mixin _$SlotSuggestionRequest {

/// Client to get suggestions for
 String get clientId;/// Service being booked
 String get serviceId;/// Date range to search
 DateTime get startDate; DateTime get endDate;/// Specific provider (optional)
 String? get providerId;/// Location filter (optional)
 String? get locationId;/// Maximum number of suggestions
 int get maxSuggestions;/// Whether to include high-risk slots in results
 bool get includeHighRisk;
/// Create a copy of SlotSuggestionRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SlotSuggestionRequestCopyWith<SlotSuggestionRequest> get copyWith => _$SlotSuggestionRequestCopyWithImpl<SlotSuggestionRequest>(this as SlotSuggestionRequest, _$identity);

  /// Serializes this SlotSuggestionRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SlotSuggestionRequest&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.locationId, locationId) || other.locationId == locationId)&&(identical(other.maxSuggestions, maxSuggestions) || other.maxSuggestions == maxSuggestions)&&(identical(other.includeHighRisk, includeHighRisk) || other.includeHighRisk == includeHighRisk));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,clientId,serviceId,startDate,endDate,providerId,locationId,maxSuggestions,includeHighRisk);

@override
String toString() {
  return 'SlotSuggestionRequest(clientId: $clientId, serviceId: $serviceId, startDate: $startDate, endDate: $endDate, providerId: $providerId, locationId: $locationId, maxSuggestions: $maxSuggestions, includeHighRisk: $includeHighRisk)';
}


}

/// @nodoc
abstract mixin class $SlotSuggestionRequestCopyWith<$Res>  {
  factory $SlotSuggestionRequestCopyWith(SlotSuggestionRequest value, $Res Function(SlotSuggestionRequest) _then) = _$SlotSuggestionRequestCopyWithImpl;
@useResult
$Res call({
 String clientId, String serviceId, DateTime startDate, DateTime endDate, String? providerId, String? locationId, int maxSuggestions, bool includeHighRisk
});




}
/// @nodoc
class _$SlotSuggestionRequestCopyWithImpl<$Res>
    implements $SlotSuggestionRequestCopyWith<$Res> {
  _$SlotSuggestionRequestCopyWithImpl(this._self, this._then);

  final SlotSuggestionRequest _self;
  final $Res Function(SlotSuggestionRequest) _then;

/// Create a copy of SlotSuggestionRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? clientId = null,Object? serviceId = null,Object? startDate = null,Object? endDate = null,Object? providerId = freezed,Object? locationId = freezed,Object? maxSuggestions = null,Object? includeHighRisk = null,}) {
  return _then(_self.copyWith(
clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,providerId: freezed == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String?,locationId: freezed == locationId ? _self.locationId : locationId // ignore: cast_nullable_to_non_nullable
as String?,maxSuggestions: null == maxSuggestions ? _self.maxSuggestions : maxSuggestions // ignore: cast_nullable_to_non_nullable
as int,includeHighRisk: null == includeHighRisk ? _self.includeHighRisk : includeHighRisk // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SlotSuggestionRequest].
extension SlotSuggestionRequestPatterns on SlotSuggestionRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SlotSuggestionRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SlotSuggestionRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SlotSuggestionRequest value)  $default,){
final _that = this;
switch (_that) {
case _SlotSuggestionRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SlotSuggestionRequest value)?  $default,){
final _that = this;
switch (_that) {
case _SlotSuggestionRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String clientId,  String serviceId,  DateTime startDate,  DateTime endDate,  String? providerId,  String? locationId,  int maxSuggestions,  bool includeHighRisk)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SlotSuggestionRequest() when $default != null:
return $default(_that.clientId,_that.serviceId,_that.startDate,_that.endDate,_that.providerId,_that.locationId,_that.maxSuggestions,_that.includeHighRisk);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String clientId,  String serviceId,  DateTime startDate,  DateTime endDate,  String? providerId,  String? locationId,  int maxSuggestions,  bool includeHighRisk)  $default,) {final _that = this;
switch (_that) {
case _SlotSuggestionRequest():
return $default(_that.clientId,_that.serviceId,_that.startDate,_that.endDate,_that.providerId,_that.locationId,_that.maxSuggestions,_that.includeHighRisk);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String clientId,  String serviceId,  DateTime startDate,  DateTime endDate,  String? providerId,  String? locationId,  int maxSuggestions,  bool includeHighRisk)?  $default,) {final _that = this;
switch (_that) {
case _SlotSuggestionRequest() when $default != null:
return $default(_that.clientId,_that.serviceId,_that.startDate,_that.endDate,_that.providerId,_that.locationId,_that.maxSuggestions,_that.includeHighRisk);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SlotSuggestionRequest implements SlotSuggestionRequest {
  const _SlotSuggestionRequest({required this.clientId, required this.serviceId, required this.startDate, required this.endDate, this.providerId, this.locationId, this.maxSuggestions = 10, this.includeHighRisk = true});
  factory _SlotSuggestionRequest.fromJson(Map<String, dynamic> json) => _$SlotSuggestionRequestFromJson(json);

/// Client to get suggestions for
@override final  String clientId;
/// Service being booked
@override final  String serviceId;
/// Date range to search
@override final  DateTime startDate;
@override final  DateTime endDate;
/// Specific provider (optional)
@override final  String? providerId;
/// Location filter (optional)
@override final  String? locationId;
/// Maximum number of suggestions
@override@JsonKey() final  int maxSuggestions;
/// Whether to include high-risk slots in results
@override@JsonKey() final  bool includeHighRisk;

/// Create a copy of SlotSuggestionRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SlotSuggestionRequestCopyWith<_SlotSuggestionRequest> get copyWith => __$SlotSuggestionRequestCopyWithImpl<_SlotSuggestionRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SlotSuggestionRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SlotSuggestionRequest&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.locationId, locationId) || other.locationId == locationId)&&(identical(other.maxSuggestions, maxSuggestions) || other.maxSuggestions == maxSuggestions)&&(identical(other.includeHighRisk, includeHighRisk) || other.includeHighRisk == includeHighRisk));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,clientId,serviceId,startDate,endDate,providerId,locationId,maxSuggestions,includeHighRisk);

@override
String toString() {
  return 'SlotSuggestionRequest(clientId: $clientId, serviceId: $serviceId, startDate: $startDate, endDate: $endDate, providerId: $providerId, locationId: $locationId, maxSuggestions: $maxSuggestions, includeHighRisk: $includeHighRisk)';
}


}

/// @nodoc
abstract mixin class _$SlotSuggestionRequestCopyWith<$Res> implements $SlotSuggestionRequestCopyWith<$Res> {
  factory _$SlotSuggestionRequestCopyWith(_SlotSuggestionRequest value, $Res Function(_SlotSuggestionRequest) _then) = __$SlotSuggestionRequestCopyWithImpl;
@override @useResult
$Res call({
 String clientId, String serviceId, DateTime startDate, DateTime endDate, String? providerId, String? locationId, int maxSuggestions, bool includeHighRisk
});




}
/// @nodoc
class __$SlotSuggestionRequestCopyWithImpl<$Res>
    implements _$SlotSuggestionRequestCopyWith<$Res> {
  __$SlotSuggestionRequestCopyWithImpl(this._self, this._then);

  final _SlotSuggestionRequest _self;
  final $Res Function(_SlotSuggestionRequest) _then;

/// Create a copy of SlotSuggestionRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? clientId = null,Object? serviceId = null,Object? startDate = null,Object? endDate = null,Object? providerId = freezed,Object? locationId = freezed,Object? maxSuggestions = null,Object? includeHighRisk = null,}) {
  return _then(_SlotSuggestionRequest(
clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,providerId: freezed == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String?,locationId: freezed == locationId ? _self.locationId : locationId // ignore: cast_nullable_to_non_nullable
as String?,maxSuggestions: null == maxSuggestions ? _self.maxSuggestions : maxSuggestions // ignore: cast_nullable_to_non_nullable
as int,includeHighRisk: null == includeHighRisk ? _self.includeHighRisk : includeHighRisk // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
