// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'prediction_explanation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExplanationFactor {

/// Internal feature name (e.g., "clientHistoricalNoshowRate")
 String get feature;/// Human-readable feature name (e.g., "Client's Past No-Show Rate")
@JsonKey(name: 'display_name') String get displayName;/// Impact direction: "increases" or "decreases" risk
 String get impact;/// Normalized magnitude of impact (0.0 to 1.0)
 double get magnitude;/// Human-readable explanation (e.g., "Client has 40% historical no-show rate")
 String get explanation;/// Original feature value for display
@JsonKey(name: 'feature_value') dynamic get featureValue;
/// Create a copy of ExplanationFactor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExplanationFactorCopyWith<ExplanationFactor> get copyWith => _$ExplanationFactorCopyWithImpl<ExplanationFactor>(this as ExplanationFactor, _$identity);

  /// Serializes this ExplanationFactor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExplanationFactor&&(identical(other.feature, feature) || other.feature == feature)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.impact, impact) || other.impact == impact)&&(identical(other.magnitude, magnitude) || other.magnitude == magnitude)&&(identical(other.explanation, explanation) || other.explanation == explanation)&&const DeepCollectionEquality().equals(other.featureValue, featureValue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,feature,displayName,impact,magnitude,explanation,const DeepCollectionEquality().hash(featureValue));

@override
String toString() {
  return 'ExplanationFactor(feature: $feature, displayName: $displayName, impact: $impact, magnitude: $magnitude, explanation: $explanation, featureValue: $featureValue)';
}


}

/// @nodoc
abstract mixin class $ExplanationFactorCopyWith<$Res>  {
  factory $ExplanationFactorCopyWith(ExplanationFactor value, $Res Function(ExplanationFactor) _then) = _$ExplanationFactorCopyWithImpl;
@useResult
$Res call({
 String feature,@JsonKey(name: 'display_name') String displayName, String impact, double magnitude, String explanation,@JsonKey(name: 'feature_value') dynamic featureValue
});




}
/// @nodoc
class _$ExplanationFactorCopyWithImpl<$Res>
    implements $ExplanationFactorCopyWith<$Res> {
  _$ExplanationFactorCopyWithImpl(this._self, this._then);

  final ExplanationFactor _self;
  final $Res Function(ExplanationFactor) _then;

/// Create a copy of ExplanationFactor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? feature = null,Object? displayName = null,Object? impact = null,Object? magnitude = null,Object? explanation = null,Object? featureValue = freezed,}) {
  return _then(_self.copyWith(
feature: null == feature ? _self.feature : feature // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,impact: null == impact ? _self.impact : impact // ignore: cast_nullable_to_non_nullable
as String,magnitude: null == magnitude ? _self.magnitude : magnitude // ignore: cast_nullable_to_non_nullable
as double,explanation: null == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String,featureValue: freezed == featureValue ? _self.featureValue : featureValue // ignore: cast_nullable_to_non_nullable
as dynamic,
  ));
}

}


/// Adds pattern-matching-related methods to [ExplanationFactor].
extension ExplanationFactorPatterns on ExplanationFactor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExplanationFactor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExplanationFactor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExplanationFactor value)  $default,){
final _that = this;
switch (_that) {
case _ExplanationFactor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExplanationFactor value)?  $default,){
final _that = this;
switch (_that) {
case _ExplanationFactor() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String feature, @JsonKey(name: 'display_name')  String displayName,  String impact,  double magnitude,  String explanation, @JsonKey(name: 'feature_value')  dynamic featureValue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExplanationFactor() when $default != null:
return $default(_that.feature,_that.displayName,_that.impact,_that.magnitude,_that.explanation,_that.featureValue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String feature, @JsonKey(name: 'display_name')  String displayName,  String impact,  double magnitude,  String explanation, @JsonKey(name: 'feature_value')  dynamic featureValue)  $default,) {final _that = this;
switch (_that) {
case _ExplanationFactor():
return $default(_that.feature,_that.displayName,_that.impact,_that.magnitude,_that.explanation,_that.featureValue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String feature, @JsonKey(name: 'display_name')  String displayName,  String impact,  double magnitude,  String explanation, @JsonKey(name: 'feature_value')  dynamic featureValue)?  $default,) {final _that = this;
switch (_that) {
case _ExplanationFactor() when $default != null:
return $default(_that.feature,_that.displayName,_that.impact,_that.magnitude,_that.explanation,_that.featureValue);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExplanationFactor implements ExplanationFactor {
  const _ExplanationFactor({required this.feature, @JsonKey(name: 'display_name') required this.displayName, required this.impact, required this.magnitude, required this.explanation, @JsonKey(name: 'feature_value') this.featureValue});
  factory _ExplanationFactor.fromJson(Map<String, dynamic> json) => _$ExplanationFactorFromJson(json);

/// Internal feature name (e.g., "clientHistoricalNoshowRate")
@override final  String feature;
/// Human-readable feature name (e.g., "Client's Past No-Show Rate")
@override@JsonKey(name: 'display_name') final  String displayName;
/// Impact direction: "increases" or "decreases" risk
@override final  String impact;
/// Normalized magnitude of impact (0.0 to 1.0)
@override final  double magnitude;
/// Human-readable explanation (e.g., "Client has 40% historical no-show rate")
@override final  String explanation;
/// Original feature value for display
@override@JsonKey(name: 'feature_value') final  dynamic featureValue;

/// Create a copy of ExplanationFactor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExplanationFactorCopyWith<_ExplanationFactor> get copyWith => __$ExplanationFactorCopyWithImpl<_ExplanationFactor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExplanationFactorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExplanationFactor&&(identical(other.feature, feature) || other.feature == feature)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.impact, impact) || other.impact == impact)&&(identical(other.magnitude, magnitude) || other.magnitude == magnitude)&&(identical(other.explanation, explanation) || other.explanation == explanation)&&const DeepCollectionEquality().equals(other.featureValue, featureValue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,feature,displayName,impact,magnitude,explanation,const DeepCollectionEquality().hash(featureValue));

@override
String toString() {
  return 'ExplanationFactor(feature: $feature, displayName: $displayName, impact: $impact, magnitude: $magnitude, explanation: $explanation, featureValue: $featureValue)';
}


}

/// @nodoc
abstract mixin class _$ExplanationFactorCopyWith<$Res> implements $ExplanationFactorCopyWith<$Res> {
  factory _$ExplanationFactorCopyWith(_ExplanationFactor value, $Res Function(_ExplanationFactor) _then) = __$ExplanationFactorCopyWithImpl;
@override @useResult
$Res call({
 String feature,@JsonKey(name: 'display_name') String displayName, String impact, double magnitude, String explanation,@JsonKey(name: 'feature_value') dynamic featureValue
});




}
/// @nodoc
class __$ExplanationFactorCopyWithImpl<$Res>
    implements _$ExplanationFactorCopyWith<$Res> {
  __$ExplanationFactorCopyWithImpl(this._self, this._then);

  final _ExplanationFactor _self;
  final $Res Function(_ExplanationFactor) _then;

/// Create a copy of ExplanationFactor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? feature = null,Object? displayName = null,Object? impact = null,Object? magnitude = null,Object? explanation = null,Object? featureValue = freezed,}) {
  return _then(_ExplanationFactor(
feature: null == feature ? _self.feature : feature // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,impact: null == impact ? _self.impact : impact // ignore: cast_nullable_to_non_nullable
as String,magnitude: null == magnitude ? _self.magnitude : magnitude // ignore: cast_nullable_to_non_nullable
as double,explanation: null == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String,featureValue: freezed == featureValue ? _self.featureValue : featureValue // ignore: cast_nullable_to_non_nullable
as dynamic,
  ));
}


}


/// @nodoc
mixin _$PredictionExplanation {

/// Appointment ID this explanation is for
 String get appointmentId;/// Predicted no-show probability (0.0 to 1.0)
 double get probability;/// Risk level: "high", "medium", "low"
 String get riskLevel;/// One-sentence summary of the prediction
 String get summary;/// Top factors contributing to this prediction (typically 3)
 List<ExplanationFactor> get topFactors;/// Model version that made this prediction
 String get modelVersion;/// Explanation algorithm version
 String get explanationVersion;/// When this explanation was generated
 DateTime? get generatedAt;
/// Create a copy of PredictionExplanation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PredictionExplanationCopyWith<PredictionExplanation> get copyWith => _$PredictionExplanationCopyWithImpl<PredictionExplanation>(this as PredictionExplanation, _$identity);

  /// Serializes this PredictionExplanation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PredictionExplanation&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.probability, probability) || other.probability == probability)&&(identical(other.riskLevel, riskLevel) || other.riskLevel == riskLevel)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other.topFactors, topFactors)&&(identical(other.modelVersion, modelVersion) || other.modelVersion == modelVersion)&&(identical(other.explanationVersion, explanationVersion) || other.explanationVersion == explanationVersion)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appointmentId,probability,riskLevel,summary,const DeepCollectionEquality().hash(topFactors),modelVersion,explanationVersion,generatedAt);

@override
String toString() {
  return 'PredictionExplanation(appointmentId: $appointmentId, probability: $probability, riskLevel: $riskLevel, summary: $summary, topFactors: $topFactors, modelVersion: $modelVersion, explanationVersion: $explanationVersion, generatedAt: $generatedAt)';
}


}

/// @nodoc
abstract mixin class $PredictionExplanationCopyWith<$Res>  {
  factory $PredictionExplanationCopyWith(PredictionExplanation value, $Res Function(PredictionExplanation) _then) = _$PredictionExplanationCopyWithImpl;
@useResult
$Res call({
 String appointmentId, double probability, String riskLevel, String summary, List<ExplanationFactor> topFactors, String modelVersion, String explanationVersion, DateTime? generatedAt
});




}
/// @nodoc
class _$PredictionExplanationCopyWithImpl<$Res>
    implements $PredictionExplanationCopyWith<$Res> {
  _$PredictionExplanationCopyWithImpl(this._self, this._then);

  final PredictionExplanation _self;
  final $Res Function(PredictionExplanation) _then;

/// Create a copy of PredictionExplanation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? appointmentId = null,Object? probability = null,Object? riskLevel = null,Object? summary = null,Object? topFactors = null,Object? modelVersion = null,Object? explanationVersion = null,Object? generatedAt = freezed,}) {
  return _then(_self.copyWith(
appointmentId: null == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String,probability: null == probability ? _self.probability : probability // ignore: cast_nullable_to_non_nullable
as double,riskLevel: null == riskLevel ? _self.riskLevel : riskLevel // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,topFactors: null == topFactors ? _self.topFactors : topFactors // ignore: cast_nullable_to_non_nullable
as List<ExplanationFactor>,modelVersion: null == modelVersion ? _self.modelVersion : modelVersion // ignore: cast_nullable_to_non_nullable
as String,explanationVersion: null == explanationVersion ? _self.explanationVersion : explanationVersion // ignore: cast_nullable_to_non_nullable
as String,generatedAt: freezed == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PredictionExplanation].
extension PredictionExplanationPatterns on PredictionExplanation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PredictionExplanation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PredictionExplanation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PredictionExplanation value)  $default,){
final _that = this;
switch (_that) {
case _PredictionExplanation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PredictionExplanation value)?  $default,){
final _that = this;
switch (_that) {
case _PredictionExplanation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String appointmentId,  double probability,  String riskLevel,  String summary,  List<ExplanationFactor> topFactors,  String modelVersion,  String explanationVersion,  DateTime? generatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PredictionExplanation() when $default != null:
return $default(_that.appointmentId,_that.probability,_that.riskLevel,_that.summary,_that.topFactors,_that.modelVersion,_that.explanationVersion,_that.generatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String appointmentId,  double probability,  String riskLevel,  String summary,  List<ExplanationFactor> topFactors,  String modelVersion,  String explanationVersion,  DateTime? generatedAt)  $default,) {final _that = this;
switch (_that) {
case _PredictionExplanation():
return $default(_that.appointmentId,_that.probability,_that.riskLevel,_that.summary,_that.topFactors,_that.modelVersion,_that.explanationVersion,_that.generatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String appointmentId,  double probability,  String riskLevel,  String summary,  List<ExplanationFactor> topFactors,  String modelVersion,  String explanationVersion,  DateTime? generatedAt)?  $default,) {final _that = this;
switch (_that) {
case _PredictionExplanation() when $default != null:
return $default(_that.appointmentId,_that.probability,_that.riskLevel,_that.summary,_that.topFactors,_that.modelVersion,_that.explanationVersion,_that.generatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PredictionExplanation extends PredictionExplanation {
  const _PredictionExplanation({required this.appointmentId, required this.probability, required this.riskLevel, required this.summary, required final  List<ExplanationFactor> topFactors, required this.modelVersion, this.explanationVersion = '1.0.0', this.generatedAt}): _topFactors = topFactors,super._();
  factory _PredictionExplanation.fromJson(Map<String, dynamic> json) => _$PredictionExplanationFromJson(json);

/// Appointment ID this explanation is for
@override final  String appointmentId;
/// Predicted no-show probability (0.0 to 1.0)
@override final  double probability;
/// Risk level: "high", "medium", "low"
@override final  String riskLevel;
/// One-sentence summary of the prediction
@override final  String summary;
/// Top factors contributing to this prediction (typically 3)
 final  List<ExplanationFactor> _topFactors;
/// Top factors contributing to this prediction (typically 3)
@override List<ExplanationFactor> get topFactors {
  if (_topFactors is EqualUnmodifiableListView) return _topFactors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topFactors);
}

/// Model version that made this prediction
@override final  String modelVersion;
/// Explanation algorithm version
@override@JsonKey() final  String explanationVersion;
/// When this explanation was generated
@override final  DateTime? generatedAt;

/// Create a copy of PredictionExplanation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PredictionExplanationCopyWith<_PredictionExplanation> get copyWith => __$PredictionExplanationCopyWithImpl<_PredictionExplanation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PredictionExplanationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PredictionExplanation&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.probability, probability) || other.probability == probability)&&(identical(other.riskLevel, riskLevel) || other.riskLevel == riskLevel)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other._topFactors, _topFactors)&&(identical(other.modelVersion, modelVersion) || other.modelVersion == modelVersion)&&(identical(other.explanationVersion, explanationVersion) || other.explanationVersion == explanationVersion)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appointmentId,probability,riskLevel,summary,const DeepCollectionEquality().hash(_topFactors),modelVersion,explanationVersion,generatedAt);

@override
String toString() {
  return 'PredictionExplanation(appointmentId: $appointmentId, probability: $probability, riskLevel: $riskLevel, summary: $summary, topFactors: $topFactors, modelVersion: $modelVersion, explanationVersion: $explanationVersion, generatedAt: $generatedAt)';
}


}

/// @nodoc
abstract mixin class _$PredictionExplanationCopyWith<$Res> implements $PredictionExplanationCopyWith<$Res> {
  factory _$PredictionExplanationCopyWith(_PredictionExplanation value, $Res Function(_PredictionExplanation) _then) = __$PredictionExplanationCopyWithImpl;
@override @useResult
$Res call({
 String appointmentId, double probability, String riskLevel, String summary, List<ExplanationFactor> topFactors, String modelVersion, String explanationVersion, DateTime? generatedAt
});




}
/// @nodoc
class __$PredictionExplanationCopyWithImpl<$Res>
    implements _$PredictionExplanationCopyWith<$Res> {
  __$PredictionExplanationCopyWithImpl(this._self, this._then);

  final _PredictionExplanation _self;
  final $Res Function(_PredictionExplanation) _then;

/// Create a copy of PredictionExplanation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? appointmentId = null,Object? probability = null,Object? riskLevel = null,Object? summary = null,Object? topFactors = null,Object? modelVersion = null,Object? explanationVersion = null,Object? generatedAt = freezed,}) {
  return _then(_PredictionExplanation(
appointmentId: null == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String,probability: null == probability ? _self.probability : probability // ignore: cast_nullable_to_non_nullable
as double,riskLevel: null == riskLevel ? _self.riskLevel : riskLevel // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,topFactors: null == topFactors ? _self._topFactors : topFactors // ignore: cast_nullable_to_non_nullable
as List<ExplanationFactor>,modelVersion: null == modelVersion ? _self.modelVersion : modelVersion // ignore: cast_nullable_to_non_nullable
as String,explanationVersion: null == explanationVersion ? _self.explanationVersion : explanationVersion // ignore: cast_nullable_to_non_nullable
as String,generatedAt: freezed == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$ExplanationRequest {

/// Appointment ID to explain
@JsonKey(name: 'appointment_id') String get appointmentId;/// Include all factors, not just top 3
@JsonKey(name: 'include_all_factors') bool get includeAllFactors;/// Number of factors to return (default 3)
@JsonKey(name: 'num_factors') int get numFactors;
/// Create a copy of ExplanationRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExplanationRequestCopyWith<ExplanationRequest> get copyWith => _$ExplanationRequestCopyWithImpl<ExplanationRequest>(this as ExplanationRequest, _$identity);

  /// Serializes this ExplanationRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExplanationRequest&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.includeAllFactors, includeAllFactors) || other.includeAllFactors == includeAllFactors)&&(identical(other.numFactors, numFactors) || other.numFactors == numFactors));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appointmentId,includeAllFactors,numFactors);

@override
String toString() {
  return 'ExplanationRequest(appointmentId: $appointmentId, includeAllFactors: $includeAllFactors, numFactors: $numFactors)';
}


}

/// @nodoc
abstract mixin class $ExplanationRequestCopyWith<$Res>  {
  factory $ExplanationRequestCopyWith(ExplanationRequest value, $Res Function(ExplanationRequest) _then) = _$ExplanationRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'appointment_id') String appointmentId,@JsonKey(name: 'include_all_factors') bool includeAllFactors,@JsonKey(name: 'num_factors') int numFactors
});




}
/// @nodoc
class _$ExplanationRequestCopyWithImpl<$Res>
    implements $ExplanationRequestCopyWith<$Res> {
  _$ExplanationRequestCopyWithImpl(this._self, this._then);

  final ExplanationRequest _self;
  final $Res Function(ExplanationRequest) _then;

/// Create a copy of ExplanationRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? appointmentId = null,Object? includeAllFactors = null,Object? numFactors = null,}) {
  return _then(_self.copyWith(
appointmentId: null == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String,includeAllFactors: null == includeAllFactors ? _self.includeAllFactors : includeAllFactors // ignore: cast_nullable_to_non_nullable
as bool,numFactors: null == numFactors ? _self.numFactors : numFactors // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ExplanationRequest].
extension ExplanationRequestPatterns on ExplanationRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExplanationRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExplanationRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExplanationRequest value)  $default,){
final _that = this;
switch (_that) {
case _ExplanationRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExplanationRequest value)?  $default,){
final _that = this;
switch (_that) {
case _ExplanationRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'appointment_id')  String appointmentId, @JsonKey(name: 'include_all_factors')  bool includeAllFactors, @JsonKey(name: 'num_factors')  int numFactors)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExplanationRequest() when $default != null:
return $default(_that.appointmentId,_that.includeAllFactors,_that.numFactors);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'appointment_id')  String appointmentId, @JsonKey(name: 'include_all_factors')  bool includeAllFactors, @JsonKey(name: 'num_factors')  int numFactors)  $default,) {final _that = this;
switch (_that) {
case _ExplanationRequest():
return $default(_that.appointmentId,_that.includeAllFactors,_that.numFactors);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'appointment_id')  String appointmentId, @JsonKey(name: 'include_all_factors')  bool includeAllFactors, @JsonKey(name: 'num_factors')  int numFactors)?  $default,) {final _that = this;
switch (_that) {
case _ExplanationRequest() when $default != null:
return $default(_that.appointmentId,_that.includeAllFactors,_that.numFactors);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExplanationRequest implements ExplanationRequest {
  const _ExplanationRequest({@JsonKey(name: 'appointment_id') required this.appointmentId, @JsonKey(name: 'include_all_factors') this.includeAllFactors = false, @JsonKey(name: 'num_factors') this.numFactors = 3});
  factory _ExplanationRequest.fromJson(Map<String, dynamic> json) => _$ExplanationRequestFromJson(json);

/// Appointment ID to explain
@override@JsonKey(name: 'appointment_id') final  String appointmentId;
/// Include all factors, not just top 3
@override@JsonKey(name: 'include_all_factors') final  bool includeAllFactors;
/// Number of factors to return (default 3)
@override@JsonKey(name: 'num_factors') final  int numFactors;

/// Create a copy of ExplanationRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExplanationRequestCopyWith<_ExplanationRequest> get copyWith => __$ExplanationRequestCopyWithImpl<_ExplanationRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExplanationRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExplanationRequest&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.includeAllFactors, includeAllFactors) || other.includeAllFactors == includeAllFactors)&&(identical(other.numFactors, numFactors) || other.numFactors == numFactors));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appointmentId,includeAllFactors,numFactors);

@override
String toString() {
  return 'ExplanationRequest(appointmentId: $appointmentId, includeAllFactors: $includeAllFactors, numFactors: $numFactors)';
}


}

/// @nodoc
abstract mixin class _$ExplanationRequestCopyWith<$Res> implements $ExplanationRequestCopyWith<$Res> {
  factory _$ExplanationRequestCopyWith(_ExplanationRequest value, $Res Function(_ExplanationRequest) _then) = __$ExplanationRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'appointment_id') String appointmentId,@JsonKey(name: 'include_all_factors') bool includeAllFactors,@JsonKey(name: 'num_factors') int numFactors
});




}
/// @nodoc
class __$ExplanationRequestCopyWithImpl<$Res>
    implements _$ExplanationRequestCopyWith<$Res> {
  __$ExplanationRequestCopyWithImpl(this._self, this._then);

  final _ExplanationRequest _self;
  final $Res Function(_ExplanationRequest) _then;

/// Create a copy of ExplanationRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? appointmentId = null,Object? includeAllFactors = null,Object? numFactors = null,}) {
  return _then(_ExplanationRequest(
appointmentId: null == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String,includeAllFactors: null == includeAllFactors ? _self.includeAllFactors : includeAllFactors // ignore: cast_nullable_to_non_nullable
as bool,numFactors: null == numFactors ? _self.numFactors : numFactors // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$CachedExplanation {

 PredictionExplanation get explanation; DateTime get cachedAt; DateTime get expiresAt;
/// Create a copy of CachedExplanation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CachedExplanationCopyWith<CachedExplanation> get copyWith => _$CachedExplanationCopyWithImpl<CachedExplanation>(this as CachedExplanation, _$identity);

  /// Serializes this CachedExplanation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CachedExplanation&&(identical(other.explanation, explanation) || other.explanation == explanation)&&(identical(other.cachedAt, cachedAt) || other.cachedAt == cachedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,explanation,cachedAt,expiresAt);

@override
String toString() {
  return 'CachedExplanation(explanation: $explanation, cachedAt: $cachedAt, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $CachedExplanationCopyWith<$Res>  {
  factory $CachedExplanationCopyWith(CachedExplanation value, $Res Function(CachedExplanation) _then) = _$CachedExplanationCopyWithImpl;
@useResult
$Res call({
 PredictionExplanation explanation, DateTime cachedAt, DateTime expiresAt
});


$PredictionExplanationCopyWith<$Res> get explanation;

}
/// @nodoc
class _$CachedExplanationCopyWithImpl<$Res>
    implements $CachedExplanationCopyWith<$Res> {
  _$CachedExplanationCopyWithImpl(this._self, this._then);

  final CachedExplanation _self;
  final $Res Function(CachedExplanation) _then;

/// Create a copy of CachedExplanation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? explanation = null,Object? cachedAt = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
explanation: null == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as PredictionExplanation,cachedAt: null == cachedAt ? _self.cachedAt : cachedAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of CachedExplanation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PredictionExplanationCopyWith<$Res> get explanation {
  
  return $PredictionExplanationCopyWith<$Res>(_self.explanation, (value) {
    return _then(_self.copyWith(explanation: value));
  });
}
}


/// Adds pattern-matching-related methods to [CachedExplanation].
extension CachedExplanationPatterns on CachedExplanation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CachedExplanation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CachedExplanation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CachedExplanation value)  $default,){
final _that = this;
switch (_that) {
case _CachedExplanation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CachedExplanation value)?  $default,){
final _that = this;
switch (_that) {
case _CachedExplanation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PredictionExplanation explanation,  DateTime cachedAt,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CachedExplanation() when $default != null:
return $default(_that.explanation,_that.cachedAt,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PredictionExplanation explanation,  DateTime cachedAt,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _CachedExplanation():
return $default(_that.explanation,_that.cachedAt,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PredictionExplanation explanation,  DateTime cachedAt,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _CachedExplanation() when $default != null:
return $default(_that.explanation,_that.cachedAt,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CachedExplanation extends CachedExplanation {
  const _CachedExplanation({required this.explanation, required this.cachedAt, required this.expiresAt}): super._();
  factory _CachedExplanation.fromJson(Map<String, dynamic> json) => _$CachedExplanationFromJson(json);

@override final  PredictionExplanation explanation;
@override final  DateTime cachedAt;
@override final  DateTime expiresAt;

/// Create a copy of CachedExplanation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CachedExplanationCopyWith<_CachedExplanation> get copyWith => __$CachedExplanationCopyWithImpl<_CachedExplanation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CachedExplanationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CachedExplanation&&(identical(other.explanation, explanation) || other.explanation == explanation)&&(identical(other.cachedAt, cachedAt) || other.cachedAt == cachedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,explanation,cachedAt,expiresAt);

@override
String toString() {
  return 'CachedExplanation(explanation: $explanation, cachedAt: $cachedAt, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$CachedExplanationCopyWith<$Res> implements $CachedExplanationCopyWith<$Res> {
  factory _$CachedExplanationCopyWith(_CachedExplanation value, $Res Function(_CachedExplanation) _then) = __$CachedExplanationCopyWithImpl;
@override @useResult
$Res call({
 PredictionExplanation explanation, DateTime cachedAt, DateTime expiresAt
});


@override $PredictionExplanationCopyWith<$Res> get explanation;

}
/// @nodoc
class __$CachedExplanationCopyWithImpl<$Res>
    implements _$CachedExplanationCopyWith<$Res> {
  __$CachedExplanationCopyWithImpl(this._self, this._then);

  final _CachedExplanation _self;
  final $Res Function(_CachedExplanation) _then;

/// Create a copy of CachedExplanation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? explanation = null,Object? cachedAt = null,Object? expiresAt = null,}) {
  return _then(_CachedExplanation(
explanation: null == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as PredictionExplanation,cachedAt: null == cachedAt ? _self.cachedAt : cachedAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of CachedExplanation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PredictionExplanationCopyWith<$Res> get explanation {
  
  return $PredictionExplanationCopyWith<$Res>(_self.explanation, (value) {
    return _then(_self.copyWith(explanation: value));
  });
}
}

// dart format on
