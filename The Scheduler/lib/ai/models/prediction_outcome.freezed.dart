// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'prediction_outcome.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PredictionOutcome {

/// Unique identifier for this record
 String get id;/// Business this prediction belongs to
 String get businessId;/// Appointment ID that was predicted
 String get appointmentId;/// Client ID for the appointment
 String get clientId;/// Predicted no-show probability (0.0-1.0)
 double get predictedProbability;/// Risk level assigned at prediction time
 String get predictedRiskLevel;/// Model version that made the prediction
 String get modelVersion;/// Confidence score of the prediction (0.0-1.0)
 double get confidence;/// When the prediction was made
 DateTime get predictedAt;/// Scheduled time of the appointment
 DateTime get appointmentTime;/// Actual outcome of the appointment
 AppointmentOutcome get outcome;/// When the outcome was recorded
 DateTime? get outcomeRecordedAt;/// Whether prediction was correct (only set when outcome is usable)
/// True if high-risk prediction and no-show, or low-risk and attended
 bool? get predictionCorrect;/// Absolute prediction error (|predicted - actual|)
/// Only set when outcome is usable for evaluation
 double? get predictionError;/// Top feature names that contributed to this prediction
 List<String> get topFeatures;/// Optional provider ID for the appointment
 String? get providerId;/// Optional service ID for the appointment
 String? get serviceId;
/// Create a copy of PredictionOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PredictionOutcomeCopyWith<PredictionOutcome> get copyWith => _$PredictionOutcomeCopyWithImpl<PredictionOutcome>(this as PredictionOutcome, _$identity);

  /// Serializes this PredictionOutcome to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PredictionOutcome&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.predictedProbability, predictedProbability) || other.predictedProbability == predictedProbability)&&(identical(other.predictedRiskLevel, predictedRiskLevel) || other.predictedRiskLevel == predictedRiskLevel)&&(identical(other.modelVersion, modelVersion) || other.modelVersion == modelVersion)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.predictedAt, predictedAt) || other.predictedAt == predictedAt)&&(identical(other.appointmentTime, appointmentTime) || other.appointmentTime == appointmentTime)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.outcomeRecordedAt, outcomeRecordedAt) || other.outcomeRecordedAt == outcomeRecordedAt)&&(identical(other.predictionCorrect, predictionCorrect) || other.predictionCorrect == predictionCorrect)&&(identical(other.predictionError, predictionError) || other.predictionError == predictionError)&&const DeepCollectionEquality().equals(other.topFeatures, topFeatures)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,appointmentId,clientId,predictedProbability,predictedRiskLevel,modelVersion,confidence,predictedAt,appointmentTime,outcome,outcomeRecordedAt,predictionCorrect,predictionError,const DeepCollectionEquality().hash(topFeatures),providerId,serviceId);

@override
String toString() {
  return 'PredictionOutcome(id: $id, businessId: $businessId, appointmentId: $appointmentId, clientId: $clientId, predictedProbability: $predictedProbability, predictedRiskLevel: $predictedRiskLevel, modelVersion: $modelVersion, confidence: $confidence, predictedAt: $predictedAt, appointmentTime: $appointmentTime, outcome: $outcome, outcomeRecordedAt: $outcomeRecordedAt, predictionCorrect: $predictionCorrect, predictionError: $predictionError, topFeatures: $topFeatures, providerId: $providerId, serviceId: $serviceId)';
}


}

/// @nodoc
abstract mixin class $PredictionOutcomeCopyWith<$Res>  {
  factory $PredictionOutcomeCopyWith(PredictionOutcome value, $Res Function(PredictionOutcome) _then) = _$PredictionOutcomeCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String appointmentId, String clientId, double predictedProbability, String predictedRiskLevel, String modelVersion, double confidence, DateTime predictedAt, DateTime appointmentTime, AppointmentOutcome outcome, DateTime? outcomeRecordedAt, bool? predictionCorrect, double? predictionError, List<String> topFeatures, String? providerId, String? serviceId
});




}
/// @nodoc
class _$PredictionOutcomeCopyWithImpl<$Res>
    implements $PredictionOutcomeCopyWith<$Res> {
  _$PredictionOutcomeCopyWithImpl(this._self, this._then);

  final PredictionOutcome _self;
  final $Res Function(PredictionOutcome) _then;

/// Create a copy of PredictionOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? appointmentId = null,Object? clientId = null,Object? predictedProbability = null,Object? predictedRiskLevel = null,Object? modelVersion = null,Object? confidence = null,Object? predictedAt = null,Object? appointmentTime = null,Object? outcome = null,Object? outcomeRecordedAt = freezed,Object? predictionCorrect = freezed,Object? predictionError = freezed,Object? topFeatures = null,Object? providerId = freezed,Object? serviceId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,appointmentId: null == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String,clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,predictedProbability: null == predictedProbability ? _self.predictedProbability : predictedProbability // ignore: cast_nullable_to_non_nullable
as double,predictedRiskLevel: null == predictedRiskLevel ? _self.predictedRiskLevel : predictedRiskLevel // ignore: cast_nullable_to_non_nullable
as String,modelVersion: null == modelVersion ? _self.modelVersion : modelVersion // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,predictedAt: null == predictedAt ? _self.predictedAt : predictedAt // ignore: cast_nullable_to_non_nullable
as DateTime,appointmentTime: null == appointmentTime ? _self.appointmentTime : appointmentTime // ignore: cast_nullable_to_non_nullable
as DateTime,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as AppointmentOutcome,outcomeRecordedAt: freezed == outcomeRecordedAt ? _self.outcomeRecordedAt : outcomeRecordedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,predictionCorrect: freezed == predictionCorrect ? _self.predictionCorrect : predictionCorrect // ignore: cast_nullable_to_non_nullable
as bool?,predictionError: freezed == predictionError ? _self.predictionError : predictionError // ignore: cast_nullable_to_non_nullable
as double?,topFeatures: null == topFeatures ? _self.topFeatures : topFeatures // ignore: cast_nullable_to_non_nullable
as List<String>,providerId: freezed == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String?,serviceId: freezed == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PredictionOutcome].
extension PredictionOutcomePatterns on PredictionOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PredictionOutcome value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PredictionOutcome() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PredictionOutcome value)  $default,){
final _that = this;
switch (_that) {
case _PredictionOutcome():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PredictionOutcome value)?  $default,){
final _that = this;
switch (_that) {
case _PredictionOutcome() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String appointmentId,  String clientId,  double predictedProbability,  String predictedRiskLevel,  String modelVersion,  double confidence,  DateTime predictedAt,  DateTime appointmentTime,  AppointmentOutcome outcome,  DateTime? outcomeRecordedAt,  bool? predictionCorrect,  double? predictionError,  List<String> topFeatures,  String? providerId,  String? serviceId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PredictionOutcome() when $default != null:
return $default(_that.id,_that.businessId,_that.appointmentId,_that.clientId,_that.predictedProbability,_that.predictedRiskLevel,_that.modelVersion,_that.confidence,_that.predictedAt,_that.appointmentTime,_that.outcome,_that.outcomeRecordedAt,_that.predictionCorrect,_that.predictionError,_that.topFeatures,_that.providerId,_that.serviceId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String appointmentId,  String clientId,  double predictedProbability,  String predictedRiskLevel,  String modelVersion,  double confidence,  DateTime predictedAt,  DateTime appointmentTime,  AppointmentOutcome outcome,  DateTime? outcomeRecordedAt,  bool? predictionCorrect,  double? predictionError,  List<String> topFeatures,  String? providerId,  String? serviceId)  $default,) {final _that = this;
switch (_that) {
case _PredictionOutcome():
return $default(_that.id,_that.businessId,_that.appointmentId,_that.clientId,_that.predictedProbability,_that.predictedRiskLevel,_that.modelVersion,_that.confidence,_that.predictedAt,_that.appointmentTime,_that.outcome,_that.outcomeRecordedAt,_that.predictionCorrect,_that.predictionError,_that.topFeatures,_that.providerId,_that.serviceId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String appointmentId,  String clientId,  double predictedProbability,  String predictedRiskLevel,  String modelVersion,  double confidence,  DateTime predictedAt,  DateTime appointmentTime,  AppointmentOutcome outcome,  DateTime? outcomeRecordedAt,  bool? predictionCorrect,  double? predictionError,  List<String> topFeatures,  String? providerId,  String? serviceId)?  $default,) {final _that = this;
switch (_that) {
case _PredictionOutcome() when $default != null:
return $default(_that.id,_that.businessId,_that.appointmentId,_that.clientId,_that.predictedProbability,_that.predictedRiskLevel,_that.modelVersion,_that.confidence,_that.predictedAt,_that.appointmentTime,_that.outcome,_that.outcomeRecordedAt,_that.predictionCorrect,_that.predictionError,_that.topFeatures,_that.providerId,_that.serviceId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PredictionOutcome extends PredictionOutcome {
  const _PredictionOutcome({required this.id, required this.businessId, required this.appointmentId, required this.clientId, required this.predictedProbability, required this.predictedRiskLevel, required this.modelVersion, required this.confidence, required this.predictedAt, required this.appointmentTime, this.outcome = AppointmentOutcome.pending, this.outcomeRecordedAt, this.predictionCorrect, this.predictionError, final  List<String> topFeatures = const [], this.providerId, this.serviceId}): _topFeatures = topFeatures,super._();
  factory _PredictionOutcome.fromJson(Map<String, dynamic> json) => _$PredictionOutcomeFromJson(json);

/// Unique identifier for this record
@override final  String id;
/// Business this prediction belongs to
@override final  String businessId;
/// Appointment ID that was predicted
@override final  String appointmentId;
/// Client ID for the appointment
@override final  String clientId;
/// Predicted no-show probability (0.0-1.0)
@override final  double predictedProbability;
/// Risk level assigned at prediction time
@override final  String predictedRiskLevel;
/// Model version that made the prediction
@override final  String modelVersion;
/// Confidence score of the prediction (0.0-1.0)
@override final  double confidence;
/// When the prediction was made
@override final  DateTime predictedAt;
/// Scheduled time of the appointment
@override final  DateTime appointmentTime;
/// Actual outcome of the appointment
@override@JsonKey() final  AppointmentOutcome outcome;
/// When the outcome was recorded
@override final  DateTime? outcomeRecordedAt;
/// Whether prediction was correct (only set when outcome is usable)
/// True if high-risk prediction and no-show, or low-risk and attended
@override final  bool? predictionCorrect;
/// Absolute prediction error (|predicted - actual|)
/// Only set when outcome is usable for evaluation
@override final  double? predictionError;
/// Top feature names that contributed to this prediction
 final  List<String> _topFeatures;
/// Top feature names that contributed to this prediction
@override@JsonKey() List<String> get topFeatures {
  if (_topFeatures is EqualUnmodifiableListView) return _topFeatures;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topFeatures);
}

/// Optional provider ID for the appointment
@override final  String? providerId;
/// Optional service ID for the appointment
@override final  String? serviceId;

/// Create a copy of PredictionOutcome
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PredictionOutcomeCopyWith<_PredictionOutcome> get copyWith => __$PredictionOutcomeCopyWithImpl<_PredictionOutcome>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PredictionOutcomeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PredictionOutcome&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.predictedProbability, predictedProbability) || other.predictedProbability == predictedProbability)&&(identical(other.predictedRiskLevel, predictedRiskLevel) || other.predictedRiskLevel == predictedRiskLevel)&&(identical(other.modelVersion, modelVersion) || other.modelVersion == modelVersion)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.predictedAt, predictedAt) || other.predictedAt == predictedAt)&&(identical(other.appointmentTime, appointmentTime) || other.appointmentTime == appointmentTime)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.outcomeRecordedAt, outcomeRecordedAt) || other.outcomeRecordedAt == outcomeRecordedAt)&&(identical(other.predictionCorrect, predictionCorrect) || other.predictionCorrect == predictionCorrect)&&(identical(other.predictionError, predictionError) || other.predictionError == predictionError)&&const DeepCollectionEquality().equals(other._topFeatures, _topFeatures)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,appointmentId,clientId,predictedProbability,predictedRiskLevel,modelVersion,confidence,predictedAt,appointmentTime,outcome,outcomeRecordedAt,predictionCorrect,predictionError,const DeepCollectionEquality().hash(_topFeatures),providerId,serviceId);

@override
String toString() {
  return 'PredictionOutcome(id: $id, businessId: $businessId, appointmentId: $appointmentId, clientId: $clientId, predictedProbability: $predictedProbability, predictedRiskLevel: $predictedRiskLevel, modelVersion: $modelVersion, confidence: $confidence, predictedAt: $predictedAt, appointmentTime: $appointmentTime, outcome: $outcome, outcomeRecordedAt: $outcomeRecordedAt, predictionCorrect: $predictionCorrect, predictionError: $predictionError, topFeatures: $topFeatures, providerId: $providerId, serviceId: $serviceId)';
}


}

/// @nodoc
abstract mixin class _$PredictionOutcomeCopyWith<$Res> implements $PredictionOutcomeCopyWith<$Res> {
  factory _$PredictionOutcomeCopyWith(_PredictionOutcome value, $Res Function(_PredictionOutcome) _then) = __$PredictionOutcomeCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String appointmentId, String clientId, double predictedProbability, String predictedRiskLevel, String modelVersion, double confidence, DateTime predictedAt, DateTime appointmentTime, AppointmentOutcome outcome, DateTime? outcomeRecordedAt, bool? predictionCorrect, double? predictionError, List<String> topFeatures, String? providerId, String? serviceId
});




}
/// @nodoc
class __$PredictionOutcomeCopyWithImpl<$Res>
    implements _$PredictionOutcomeCopyWith<$Res> {
  __$PredictionOutcomeCopyWithImpl(this._self, this._then);

  final _PredictionOutcome _self;
  final $Res Function(_PredictionOutcome) _then;

/// Create a copy of PredictionOutcome
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? appointmentId = null,Object? clientId = null,Object? predictedProbability = null,Object? predictedRiskLevel = null,Object? modelVersion = null,Object? confidence = null,Object? predictedAt = null,Object? appointmentTime = null,Object? outcome = null,Object? outcomeRecordedAt = freezed,Object? predictionCorrect = freezed,Object? predictionError = freezed,Object? topFeatures = null,Object? providerId = freezed,Object? serviceId = freezed,}) {
  return _then(_PredictionOutcome(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,appointmentId: null == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String,clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,predictedProbability: null == predictedProbability ? _self.predictedProbability : predictedProbability // ignore: cast_nullable_to_non_nullable
as double,predictedRiskLevel: null == predictedRiskLevel ? _self.predictedRiskLevel : predictedRiskLevel // ignore: cast_nullable_to_non_nullable
as String,modelVersion: null == modelVersion ? _self.modelVersion : modelVersion // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,predictedAt: null == predictedAt ? _self.predictedAt : predictedAt // ignore: cast_nullable_to_non_nullable
as DateTime,appointmentTime: null == appointmentTime ? _self.appointmentTime : appointmentTime // ignore: cast_nullable_to_non_nullable
as DateTime,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as AppointmentOutcome,outcomeRecordedAt: freezed == outcomeRecordedAt ? _self.outcomeRecordedAt : outcomeRecordedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,predictionCorrect: freezed == predictionCorrect ? _self.predictionCorrect : predictionCorrect // ignore: cast_nullable_to_non_nullable
as bool?,predictionError: freezed == predictionError ? _self.predictionError : predictionError // ignore: cast_nullable_to_non_nullable
as double?,topFeatures: null == topFeatures ? _self._topFeatures : topFeatures // ignore: cast_nullable_to_non_nullable
as List<String>,providerId: freezed == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String?,serviceId: freezed == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PredictionOutcomeSummary {

/// Time period start
 DateTime get periodStart;/// Time period end
 DateTime get periodEnd;/// Total predictions made
 int get totalPredictions;/// Predictions with outcomes (attended or no-show)
 int get evaluatedPredictions;/// Number of correct predictions
 int get correctPredictions;/// Number of actual no-shows
 int get actualNoShows;/// Number of predicted high-risk that were no-shows (true positives)
 int get truePositives;/// Number of predicted low-risk that attended (true negatives)
 int get trueNegatives;/// Number of predicted high-risk that attended (false positives)
 int get falsePositives;/// Number of predicted low-risk that were no-shows (false negatives)
 int get falseNegatives;/// Model version(s) evaluated
 List<String> get modelVersions;
/// Create a copy of PredictionOutcomeSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PredictionOutcomeSummaryCopyWith<PredictionOutcomeSummary> get copyWith => _$PredictionOutcomeSummaryCopyWithImpl<PredictionOutcomeSummary>(this as PredictionOutcomeSummary, _$identity);

  /// Serializes this PredictionOutcomeSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PredictionOutcomeSummary&&(identical(other.periodStart, periodStart) || other.periodStart == periodStart)&&(identical(other.periodEnd, periodEnd) || other.periodEnd == periodEnd)&&(identical(other.totalPredictions, totalPredictions) || other.totalPredictions == totalPredictions)&&(identical(other.evaluatedPredictions, evaluatedPredictions) || other.evaluatedPredictions == evaluatedPredictions)&&(identical(other.correctPredictions, correctPredictions) || other.correctPredictions == correctPredictions)&&(identical(other.actualNoShows, actualNoShows) || other.actualNoShows == actualNoShows)&&(identical(other.truePositives, truePositives) || other.truePositives == truePositives)&&(identical(other.trueNegatives, trueNegatives) || other.trueNegatives == trueNegatives)&&(identical(other.falsePositives, falsePositives) || other.falsePositives == falsePositives)&&(identical(other.falseNegatives, falseNegatives) || other.falseNegatives == falseNegatives)&&const DeepCollectionEquality().equals(other.modelVersions, modelVersions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,periodStart,periodEnd,totalPredictions,evaluatedPredictions,correctPredictions,actualNoShows,truePositives,trueNegatives,falsePositives,falseNegatives,const DeepCollectionEquality().hash(modelVersions));

@override
String toString() {
  return 'PredictionOutcomeSummary(periodStart: $periodStart, periodEnd: $periodEnd, totalPredictions: $totalPredictions, evaluatedPredictions: $evaluatedPredictions, correctPredictions: $correctPredictions, actualNoShows: $actualNoShows, truePositives: $truePositives, trueNegatives: $trueNegatives, falsePositives: $falsePositives, falseNegatives: $falseNegatives, modelVersions: $modelVersions)';
}


}

/// @nodoc
abstract mixin class $PredictionOutcomeSummaryCopyWith<$Res>  {
  factory $PredictionOutcomeSummaryCopyWith(PredictionOutcomeSummary value, $Res Function(PredictionOutcomeSummary) _then) = _$PredictionOutcomeSummaryCopyWithImpl;
@useResult
$Res call({
 DateTime periodStart, DateTime periodEnd, int totalPredictions, int evaluatedPredictions, int correctPredictions, int actualNoShows, int truePositives, int trueNegatives, int falsePositives, int falseNegatives, List<String> modelVersions
});




}
/// @nodoc
class _$PredictionOutcomeSummaryCopyWithImpl<$Res>
    implements $PredictionOutcomeSummaryCopyWith<$Res> {
  _$PredictionOutcomeSummaryCopyWithImpl(this._self, this._then);

  final PredictionOutcomeSummary _self;
  final $Res Function(PredictionOutcomeSummary) _then;

/// Create a copy of PredictionOutcomeSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? periodStart = null,Object? periodEnd = null,Object? totalPredictions = null,Object? evaluatedPredictions = null,Object? correctPredictions = null,Object? actualNoShows = null,Object? truePositives = null,Object? trueNegatives = null,Object? falsePositives = null,Object? falseNegatives = null,Object? modelVersions = null,}) {
  return _then(_self.copyWith(
periodStart: null == periodStart ? _self.periodStart : periodStart // ignore: cast_nullable_to_non_nullable
as DateTime,periodEnd: null == periodEnd ? _self.periodEnd : periodEnd // ignore: cast_nullable_to_non_nullable
as DateTime,totalPredictions: null == totalPredictions ? _self.totalPredictions : totalPredictions // ignore: cast_nullable_to_non_nullable
as int,evaluatedPredictions: null == evaluatedPredictions ? _self.evaluatedPredictions : evaluatedPredictions // ignore: cast_nullable_to_non_nullable
as int,correctPredictions: null == correctPredictions ? _self.correctPredictions : correctPredictions // ignore: cast_nullable_to_non_nullable
as int,actualNoShows: null == actualNoShows ? _self.actualNoShows : actualNoShows // ignore: cast_nullable_to_non_nullable
as int,truePositives: null == truePositives ? _self.truePositives : truePositives // ignore: cast_nullable_to_non_nullable
as int,trueNegatives: null == trueNegatives ? _self.trueNegatives : trueNegatives // ignore: cast_nullable_to_non_nullable
as int,falsePositives: null == falsePositives ? _self.falsePositives : falsePositives // ignore: cast_nullable_to_non_nullable
as int,falseNegatives: null == falseNegatives ? _self.falseNegatives : falseNegatives // ignore: cast_nullable_to_non_nullable
as int,modelVersions: null == modelVersions ? _self.modelVersions : modelVersions // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [PredictionOutcomeSummary].
extension PredictionOutcomeSummaryPatterns on PredictionOutcomeSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PredictionOutcomeSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PredictionOutcomeSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PredictionOutcomeSummary value)  $default,){
final _that = this;
switch (_that) {
case _PredictionOutcomeSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PredictionOutcomeSummary value)?  $default,){
final _that = this;
switch (_that) {
case _PredictionOutcomeSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime periodStart,  DateTime periodEnd,  int totalPredictions,  int evaluatedPredictions,  int correctPredictions,  int actualNoShows,  int truePositives,  int trueNegatives,  int falsePositives,  int falseNegatives,  List<String> modelVersions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PredictionOutcomeSummary() when $default != null:
return $default(_that.periodStart,_that.periodEnd,_that.totalPredictions,_that.evaluatedPredictions,_that.correctPredictions,_that.actualNoShows,_that.truePositives,_that.trueNegatives,_that.falsePositives,_that.falseNegatives,_that.modelVersions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime periodStart,  DateTime periodEnd,  int totalPredictions,  int evaluatedPredictions,  int correctPredictions,  int actualNoShows,  int truePositives,  int trueNegatives,  int falsePositives,  int falseNegatives,  List<String> modelVersions)  $default,) {final _that = this;
switch (_that) {
case _PredictionOutcomeSummary():
return $default(_that.periodStart,_that.periodEnd,_that.totalPredictions,_that.evaluatedPredictions,_that.correctPredictions,_that.actualNoShows,_that.truePositives,_that.trueNegatives,_that.falsePositives,_that.falseNegatives,_that.modelVersions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime periodStart,  DateTime periodEnd,  int totalPredictions,  int evaluatedPredictions,  int correctPredictions,  int actualNoShows,  int truePositives,  int trueNegatives,  int falsePositives,  int falseNegatives,  List<String> modelVersions)?  $default,) {final _that = this;
switch (_that) {
case _PredictionOutcomeSummary() when $default != null:
return $default(_that.periodStart,_that.periodEnd,_that.totalPredictions,_that.evaluatedPredictions,_that.correctPredictions,_that.actualNoShows,_that.truePositives,_that.trueNegatives,_that.falsePositives,_that.falseNegatives,_that.modelVersions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PredictionOutcomeSummary extends PredictionOutcomeSummary {
  const _PredictionOutcomeSummary({required this.periodStart, required this.periodEnd, required this.totalPredictions, required this.evaluatedPredictions, required this.correctPredictions, required this.actualNoShows, required this.truePositives, required this.trueNegatives, required this.falsePositives, required this.falseNegatives, required final  List<String> modelVersions}): _modelVersions = modelVersions,super._();
  factory _PredictionOutcomeSummary.fromJson(Map<String, dynamic> json) => _$PredictionOutcomeSummaryFromJson(json);

/// Time period start
@override final  DateTime periodStart;
/// Time period end
@override final  DateTime periodEnd;
/// Total predictions made
@override final  int totalPredictions;
/// Predictions with outcomes (attended or no-show)
@override final  int evaluatedPredictions;
/// Number of correct predictions
@override final  int correctPredictions;
/// Number of actual no-shows
@override final  int actualNoShows;
/// Number of predicted high-risk that were no-shows (true positives)
@override final  int truePositives;
/// Number of predicted low-risk that attended (true negatives)
@override final  int trueNegatives;
/// Number of predicted high-risk that attended (false positives)
@override final  int falsePositives;
/// Number of predicted low-risk that were no-shows (false negatives)
@override final  int falseNegatives;
/// Model version(s) evaluated
 final  List<String> _modelVersions;
/// Model version(s) evaluated
@override List<String> get modelVersions {
  if (_modelVersions is EqualUnmodifiableListView) return _modelVersions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_modelVersions);
}


/// Create a copy of PredictionOutcomeSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PredictionOutcomeSummaryCopyWith<_PredictionOutcomeSummary> get copyWith => __$PredictionOutcomeSummaryCopyWithImpl<_PredictionOutcomeSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PredictionOutcomeSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PredictionOutcomeSummary&&(identical(other.periodStart, periodStart) || other.periodStart == periodStart)&&(identical(other.periodEnd, periodEnd) || other.periodEnd == periodEnd)&&(identical(other.totalPredictions, totalPredictions) || other.totalPredictions == totalPredictions)&&(identical(other.evaluatedPredictions, evaluatedPredictions) || other.evaluatedPredictions == evaluatedPredictions)&&(identical(other.correctPredictions, correctPredictions) || other.correctPredictions == correctPredictions)&&(identical(other.actualNoShows, actualNoShows) || other.actualNoShows == actualNoShows)&&(identical(other.truePositives, truePositives) || other.truePositives == truePositives)&&(identical(other.trueNegatives, trueNegatives) || other.trueNegatives == trueNegatives)&&(identical(other.falsePositives, falsePositives) || other.falsePositives == falsePositives)&&(identical(other.falseNegatives, falseNegatives) || other.falseNegatives == falseNegatives)&&const DeepCollectionEquality().equals(other._modelVersions, _modelVersions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,periodStart,periodEnd,totalPredictions,evaluatedPredictions,correctPredictions,actualNoShows,truePositives,trueNegatives,falsePositives,falseNegatives,const DeepCollectionEquality().hash(_modelVersions));

@override
String toString() {
  return 'PredictionOutcomeSummary(periodStart: $periodStart, periodEnd: $periodEnd, totalPredictions: $totalPredictions, evaluatedPredictions: $evaluatedPredictions, correctPredictions: $correctPredictions, actualNoShows: $actualNoShows, truePositives: $truePositives, trueNegatives: $trueNegatives, falsePositives: $falsePositives, falseNegatives: $falseNegatives, modelVersions: $modelVersions)';
}


}

/// @nodoc
abstract mixin class _$PredictionOutcomeSummaryCopyWith<$Res> implements $PredictionOutcomeSummaryCopyWith<$Res> {
  factory _$PredictionOutcomeSummaryCopyWith(_PredictionOutcomeSummary value, $Res Function(_PredictionOutcomeSummary) _then) = __$PredictionOutcomeSummaryCopyWithImpl;
@override @useResult
$Res call({
 DateTime periodStart, DateTime periodEnd, int totalPredictions, int evaluatedPredictions, int correctPredictions, int actualNoShows, int truePositives, int trueNegatives, int falsePositives, int falseNegatives, List<String> modelVersions
});




}
/// @nodoc
class __$PredictionOutcomeSummaryCopyWithImpl<$Res>
    implements _$PredictionOutcomeSummaryCopyWith<$Res> {
  __$PredictionOutcomeSummaryCopyWithImpl(this._self, this._then);

  final _PredictionOutcomeSummary _self;
  final $Res Function(_PredictionOutcomeSummary) _then;

/// Create a copy of PredictionOutcomeSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? periodStart = null,Object? periodEnd = null,Object? totalPredictions = null,Object? evaluatedPredictions = null,Object? correctPredictions = null,Object? actualNoShows = null,Object? truePositives = null,Object? trueNegatives = null,Object? falsePositives = null,Object? falseNegatives = null,Object? modelVersions = null,}) {
  return _then(_PredictionOutcomeSummary(
periodStart: null == periodStart ? _self.periodStart : periodStart // ignore: cast_nullable_to_non_nullable
as DateTime,periodEnd: null == periodEnd ? _self.periodEnd : periodEnd // ignore: cast_nullable_to_non_nullable
as DateTime,totalPredictions: null == totalPredictions ? _self.totalPredictions : totalPredictions // ignore: cast_nullable_to_non_nullable
as int,evaluatedPredictions: null == evaluatedPredictions ? _self.evaluatedPredictions : evaluatedPredictions // ignore: cast_nullable_to_non_nullable
as int,correctPredictions: null == correctPredictions ? _self.correctPredictions : correctPredictions // ignore: cast_nullable_to_non_nullable
as int,actualNoShows: null == actualNoShows ? _self.actualNoShows : actualNoShows // ignore: cast_nullable_to_non_nullable
as int,truePositives: null == truePositives ? _self.truePositives : truePositives // ignore: cast_nullable_to_non_nullable
as int,trueNegatives: null == trueNegatives ? _self.trueNegatives : trueNegatives // ignore: cast_nullable_to_non_nullable
as int,falsePositives: null == falsePositives ? _self.falsePositives : falsePositives // ignore: cast_nullable_to_non_nullable
as int,falseNegatives: null == falseNegatives ? _self.falseNegatives : falseNegatives // ignore: cast_nullable_to_non_nullable
as int,modelVersions: null == modelVersions ? _self._modelVersions : modelVersions // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
