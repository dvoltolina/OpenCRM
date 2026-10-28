// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'prediction_feedback.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PredictionFeedback {

/// Unique identifier for this feedback
 String get id;/// Business this feedback belongs to
 String get businessId;/// Appointment ID the prediction was for
 String get appointmentId;/// Client ID for the appointment
 String get clientId;/// Prediction ID this feedback is about
 String? get predictionId;/// User who provided the feedback
 String get userId;/// Role of the user providing feedback
 FeedbackUserRole get userRole;/// Type of feedback (positive, negative, skipped)
 FeedbackType get feedbackType;/// Reason for negative feedback (only for negative)
 NegativeFeedbackReason? get negativeReason;/// Free-form comment explaining feedback
 String? get comment;/// Model version that made the prediction
 String get modelVersion;/// Predicted probability when feedback was given
 double get predictedProbability;/// Risk level when feedback was given
 String get predictedRiskLevel;/// When the feedback was submitted
@TimestampConverter() DateTime get submittedAt;/// Experiment variant ID (if from an experiment)
 String? get experimentVariantId;/// Experiment ID (if from an experiment)
 String? get experimentId;/// Calculated weight for this feedback (role * base weight)
 double get weight;/// Whether this feedback has been processed for training
 bool get processedForTraining;/// When this feedback was processed
@NullableTimestampConverter() DateTime? get processedAt;
/// Create a copy of PredictionFeedback
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PredictionFeedbackCopyWith<PredictionFeedback> get copyWith => _$PredictionFeedbackCopyWithImpl<PredictionFeedback>(this as PredictionFeedback, _$identity);

  /// Serializes this PredictionFeedback to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PredictionFeedback&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.predictionId, predictionId) || other.predictionId == predictionId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userRole, userRole) || other.userRole == userRole)&&(identical(other.feedbackType, feedbackType) || other.feedbackType == feedbackType)&&(identical(other.negativeReason, negativeReason) || other.negativeReason == negativeReason)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.modelVersion, modelVersion) || other.modelVersion == modelVersion)&&(identical(other.predictedProbability, predictedProbability) || other.predictedProbability == predictedProbability)&&(identical(other.predictedRiskLevel, predictedRiskLevel) || other.predictedRiskLevel == predictedRiskLevel)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.experimentVariantId, experimentVariantId) || other.experimentVariantId == experimentVariantId)&&(identical(other.experimentId, experimentId) || other.experimentId == experimentId)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.processedForTraining, processedForTraining) || other.processedForTraining == processedForTraining)&&(identical(other.processedAt, processedAt) || other.processedAt == processedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,businessId,appointmentId,clientId,predictionId,userId,userRole,feedbackType,negativeReason,comment,modelVersion,predictedProbability,predictedRiskLevel,submittedAt,experimentVariantId,experimentId,weight,processedForTraining,processedAt]);

@override
String toString() {
  return 'PredictionFeedback(id: $id, businessId: $businessId, appointmentId: $appointmentId, clientId: $clientId, predictionId: $predictionId, userId: $userId, userRole: $userRole, feedbackType: $feedbackType, negativeReason: $negativeReason, comment: $comment, modelVersion: $modelVersion, predictedProbability: $predictedProbability, predictedRiskLevel: $predictedRiskLevel, submittedAt: $submittedAt, experimentVariantId: $experimentVariantId, experimentId: $experimentId, weight: $weight, processedForTraining: $processedForTraining, processedAt: $processedAt)';
}


}

/// @nodoc
abstract mixin class $PredictionFeedbackCopyWith<$Res>  {
  factory $PredictionFeedbackCopyWith(PredictionFeedback value, $Res Function(PredictionFeedback) _then) = _$PredictionFeedbackCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String appointmentId, String clientId, String? predictionId, String userId, FeedbackUserRole userRole, FeedbackType feedbackType, NegativeFeedbackReason? negativeReason, String? comment, String modelVersion, double predictedProbability, String predictedRiskLevel,@TimestampConverter() DateTime submittedAt, String? experimentVariantId, String? experimentId, double weight, bool processedForTraining,@NullableTimestampConverter() DateTime? processedAt
});




}
/// @nodoc
class _$PredictionFeedbackCopyWithImpl<$Res>
    implements $PredictionFeedbackCopyWith<$Res> {
  _$PredictionFeedbackCopyWithImpl(this._self, this._then);

  final PredictionFeedback _self;
  final $Res Function(PredictionFeedback) _then;

/// Create a copy of PredictionFeedback
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? appointmentId = null,Object? clientId = null,Object? predictionId = freezed,Object? userId = null,Object? userRole = null,Object? feedbackType = null,Object? negativeReason = freezed,Object? comment = freezed,Object? modelVersion = null,Object? predictedProbability = null,Object? predictedRiskLevel = null,Object? submittedAt = null,Object? experimentVariantId = freezed,Object? experimentId = freezed,Object? weight = null,Object? processedForTraining = null,Object? processedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,appointmentId: null == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String,clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,predictionId: freezed == predictionId ? _self.predictionId : predictionId // ignore: cast_nullable_to_non_nullable
as String?,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userRole: null == userRole ? _self.userRole : userRole // ignore: cast_nullable_to_non_nullable
as FeedbackUserRole,feedbackType: null == feedbackType ? _self.feedbackType : feedbackType // ignore: cast_nullable_to_non_nullable
as FeedbackType,negativeReason: freezed == negativeReason ? _self.negativeReason : negativeReason // ignore: cast_nullable_to_non_nullable
as NegativeFeedbackReason?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,modelVersion: null == modelVersion ? _self.modelVersion : modelVersion // ignore: cast_nullable_to_non_nullable
as String,predictedProbability: null == predictedProbability ? _self.predictedProbability : predictedProbability // ignore: cast_nullable_to_non_nullable
as double,predictedRiskLevel: null == predictedRiskLevel ? _self.predictedRiskLevel : predictedRiskLevel // ignore: cast_nullable_to_non_nullable
as String,submittedAt: null == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime,experimentVariantId: freezed == experimentVariantId ? _self.experimentVariantId : experimentVariantId // ignore: cast_nullable_to_non_nullable
as String?,experimentId: freezed == experimentId ? _self.experimentId : experimentId // ignore: cast_nullable_to_non_nullable
as String?,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,processedForTraining: null == processedForTraining ? _self.processedForTraining : processedForTraining // ignore: cast_nullable_to_non_nullable
as bool,processedAt: freezed == processedAt ? _self.processedAt : processedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PredictionFeedback].
extension PredictionFeedbackPatterns on PredictionFeedback {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PredictionFeedback value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PredictionFeedback() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PredictionFeedback value)  $default,){
final _that = this;
switch (_that) {
case _PredictionFeedback():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PredictionFeedback value)?  $default,){
final _that = this;
switch (_that) {
case _PredictionFeedback() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String appointmentId,  String clientId,  String? predictionId,  String userId,  FeedbackUserRole userRole,  FeedbackType feedbackType,  NegativeFeedbackReason? negativeReason,  String? comment,  String modelVersion,  double predictedProbability,  String predictedRiskLevel, @TimestampConverter()  DateTime submittedAt,  String? experimentVariantId,  String? experimentId,  double weight,  bool processedForTraining, @NullableTimestampConverter()  DateTime? processedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PredictionFeedback() when $default != null:
return $default(_that.id,_that.businessId,_that.appointmentId,_that.clientId,_that.predictionId,_that.userId,_that.userRole,_that.feedbackType,_that.negativeReason,_that.comment,_that.modelVersion,_that.predictedProbability,_that.predictedRiskLevel,_that.submittedAt,_that.experimentVariantId,_that.experimentId,_that.weight,_that.processedForTraining,_that.processedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String appointmentId,  String clientId,  String? predictionId,  String userId,  FeedbackUserRole userRole,  FeedbackType feedbackType,  NegativeFeedbackReason? negativeReason,  String? comment,  String modelVersion,  double predictedProbability,  String predictedRiskLevel, @TimestampConverter()  DateTime submittedAt,  String? experimentVariantId,  String? experimentId,  double weight,  bool processedForTraining, @NullableTimestampConverter()  DateTime? processedAt)  $default,) {final _that = this;
switch (_that) {
case _PredictionFeedback():
return $default(_that.id,_that.businessId,_that.appointmentId,_that.clientId,_that.predictionId,_that.userId,_that.userRole,_that.feedbackType,_that.negativeReason,_that.comment,_that.modelVersion,_that.predictedProbability,_that.predictedRiskLevel,_that.submittedAt,_that.experimentVariantId,_that.experimentId,_that.weight,_that.processedForTraining,_that.processedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String appointmentId,  String clientId,  String? predictionId,  String userId,  FeedbackUserRole userRole,  FeedbackType feedbackType,  NegativeFeedbackReason? negativeReason,  String? comment,  String modelVersion,  double predictedProbability,  String predictedRiskLevel, @TimestampConverter()  DateTime submittedAt,  String? experimentVariantId,  String? experimentId,  double weight,  bool processedForTraining, @NullableTimestampConverter()  DateTime? processedAt)?  $default,) {final _that = this;
switch (_that) {
case _PredictionFeedback() when $default != null:
return $default(_that.id,_that.businessId,_that.appointmentId,_that.clientId,_that.predictionId,_that.userId,_that.userRole,_that.feedbackType,_that.negativeReason,_that.comment,_that.modelVersion,_that.predictedProbability,_that.predictedRiskLevel,_that.submittedAt,_that.experimentVariantId,_that.experimentId,_that.weight,_that.processedForTraining,_that.processedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PredictionFeedback extends PredictionFeedback {
  const _PredictionFeedback({required this.id, required this.businessId, required this.appointmentId, required this.clientId, this.predictionId, required this.userId, required this.userRole, required this.feedbackType, this.negativeReason, this.comment, required this.modelVersion, required this.predictedProbability, required this.predictedRiskLevel, @TimestampConverter() required this.submittedAt, this.experimentVariantId, this.experimentId, this.weight = 1.0, this.processedForTraining = false, @NullableTimestampConverter() this.processedAt}): super._();
  factory _PredictionFeedback.fromJson(Map<String, dynamic> json) => _$PredictionFeedbackFromJson(json);

/// Unique identifier for this feedback
@override final  String id;
/// Business this feedback belongs to
@override final  String businessId;
/// Appointment ID the prediction was for
@override final  String appointmentId;
/// Client ID for the appointment
@override final  String clientId;
/// Prediction ID this feedback is about
@override final  String? predictionId;
/// User who provided the feedback
@override final  String userId;
/// Role of the user providing feedback
@override final  FeedbackUserRole userRole;
/// Type of feedback (positive, negative, skipped)
@override final  FeedbackType feedbackType;
/// Reason for negative feedback (only for negative)
@override final  NegativeFeedbackReason? negativeReason;
/// Free-form comment explaining feedback
@override final  String? comment;
/// Model version that made the prediction
@override final  String modelVersion;
/// Predicted probability when feedback was given
@override final  double predictedProbability;
/// Risk level when feedback was given
@override final  String predictedRiskLevel;
/// When the feedback was submitted
@override@TimestampConverter() final  DateTime submittedAt;
/// Experiment variant ID (if from an experiment)
@override final  String? experimentVariantId;
/// Experiment ID (if from an experiment)
@override final  String? experimentId;
/// Calculated weight for this feedback (role * base weight)
@override@JsonKey() final  double weight;
/// Whether this feedback has been processed for training
@override@JsonKey() final  bool processedForTraining;
/// When this feedback was processed
@override@NullableTimestampConverter() final  DateTime? processedAt;

/// Create a copy of PredictionFeedback
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PredictionFeedbackCopyWith<_PredictionFeedback> get copyWith => __$PredictionFeedbackCopyWithImpl<_PredictionFeedback>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PredictionFeedbackToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PredictionFeedback&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.predictionId, predictionId) || other.predictionId == predictionId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userRole, userRole) || other.userRole == userRole)&&(identical(other.feedbackType, feedbackType) || other.feedbackType == feedbackType)&&(identical(other.negativeReason, negativeReason) || other.negativeReason == negativeReason)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.modelVersion, modelVersion) || other.modelVersion == modelVersion)&&(identical(other.predictedProbability, predictedProbability) || other.predictedProbability == predictedProbability)&&(identical(other.predictedRiskLevel, predictedRiskLevel) || other.predictedRiskLevel == predictedRiskLevel)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.experimentVariantId, experimentVariantId) || other.experimentVariantId == experimentVariantId)&&(identical(other.experimentId, experimentId) || other.experimentId == experimentId)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.processedForTraining, processedForTraining) || other.processedForTraining == processedForTraining)&&(identical(other.processedAt, processedAt) || other.processedAt == processedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,businessId,appointmentId,clientId,predictionId,userId,userRole,feedbackType,negativeReason,comment,modelVersion,predictedProbability,predictedRiskLevel,submittedAt,experimentVariantId,experimentId,weight,processedForTraining,processedAt]);

@override
String toString() {
  return 'PredictionFeedback(id: $id, businessId: $businessId, appointmentId: $appointmentId, clientId: $clientId, predictionId: $predictionId, userId: $userId, userRole: $userRole, feedbackType: $feedbackType, negativeReason: $negativeReason, comment: $comment, modelVersion: $modelVersion, predictedProbability: $predictedProbability, predictedRiskLevel: $predictedRiskLevel, submittedAt: $submittedAt, experimentVariantId: $experimentVariantId, experimentId: $experimentId, weight: $weight, processedForTraining: $processedForTraining, processedAt: $processedAt)';
}


}

/// @nodoc
abstract mixin class _$PredictionFeedbackCopyWith<$Res> implements $PredictionFeedbackCopyWith<$Res> {
  factory _$PredictionFeedbackCopyWith(_PredictionFeedback value, $Res Function(_PredictionFeedback) _then) = __$PredictionFeedbackCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String appointmentId, String clientId, String? predictionId, String userId, FeedbackUserRole userRole, FeedbackType feedbackType, NegativeFeedbackReason? negativeReason, String? comment, String modelVersion, double predictedProbability, String predictedRiskLevel,@TimestampConverter() DateTime submittedAt, String? experimentVariantId, String? experimentId, double weight, bool processedForTraining,@NullableTimestampConverter() DateTime? processedAt
});




}
/// @nodoc
class __$PredictionFeedbackCopyWithImpl<$Res>
    implements _$PredictionFeedbackCopyWith<$Res> {
  __$PredictionFeedbackCopyWithImpl(this._self, this._then);

  final _PredictionFeedback _self;
  final $Res Function(_PredictionFeedback) _then;

/// Create a copy of PredictionFeedback
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? appointmentId = null,Object? clientId = null,Object? predictionId = freezed,Object? userId = null,Object? userRole = null,Object? feedbackType = null,Object? negativeReason = freezed,Object? comment = freezed,Object? modelVersion = null,Object? predictedProbability = null,Object? predictedRiskLevel = null,Object? submittedAt = null,Object? experimentVariantId = freezed,Object? experimentId = freezed,Object? weight = null,Object? processedForTraining = null,Object? processedAt = freezed,}) {
  return _then(_PredictionFeedback(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,appointmentId: null == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String,clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,predictionId: freezed == predictionId ? _self.predictionId : predictionId // ignore: cast_nullable_to_non_nullable
as String?,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userRole: null == userRole ? _self.userRole : userRole // ignore: cast_nullable_to_non_nullable
as FeedbackUserRole,feedbackType: null == feedbackType ? _self.feedbackType : feedbackType // ignore: cast_nullable_to_non_nullable
as FeedbackType,negativeReason: freezed == negativeReason ? _self.negativeReason : negativeReason // ignore: cast_nullable_to_non_nullable
as NegativeFeedbackReason?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,modelVersion: null == modelVersion ? _self.modelVersion : modelVersion // ignore: cast_nullable_to_non_nullable
as String,predictedProbability: null == predictedProbability ? _self.predictedProbability : predictedProbability // ignore: cast_nullable_to_non_nullable
as double,predictedRiskLevel: null == predictedRiskLevel ? _self.predictedRiskLevel : predictedRiskLevel // ignore: cast_nullable_to_non_nullable
as String,submittedAt: null == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime,experimentVariantId: freezed == experimentVariantId ? _self.experimentVariantId : experimentVariantId // ignore: cast_nullable_to_non_nullable
as String?,experimentId: freezed == experimentId ? _self.experimentId : experimentId // ignore: cast_nullable_to_non_nullable
as String?,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,processedForTraining: null == processedForTraining ? _self.processedForTraining : processedForTraining // ignore: cast_nullable_to_non_nullable
as bool,processedAt: freezed == processedAt ? _self.processedAt : processedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$FeedbackSummary {

/// Model version these metrics are for
 String get modelVersion;/// Time period start
@TimestampConverter() DateTime get periodStart;/// Time period end
@TimestampConverter() DateTime get periodEnd;/// Total feedback submissions
 int get totalFeedback;/// Positive feedback count
 int get positiveCount;/// Negative feedback count
 int get negativeCount;/// Skipped count
 int get skippedCount;/// Sum of weighted scores
 double get weightedScoreSum;/// Sum of weights (for averaging)
 double get totalWeight;/// Breakdown by negative reason
 Map<String, int> get negativeReasonCounts;/// Most common negative reasons
 List<String> get topNegativeReasons;/// Business ID (if scoped to one business)
 String? get businessId;/// Experiment ID (if scoped to an experiment)
 String? get experimentId;/// Variant ID (if scoped to a variant)
 String? get variantId;
/// Create a copy of FeedbackSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeedbackSummaryCopyWith<FeedbackSummary> get copyWith => _$FeedbackSummaryCopyWithImpl<FeedbackSummary>(this as FeedbackSummary, _$identity);

  /// Serializes this FeedbackSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedbackSummary&&(identical(other.modelVersion, modelVersion) || other.modelVersion == modelVersion)&&(identical(other.periodStart, periodStart) || other.periodStart == periodStart)&&(identical(other.periodEnd, periodEnd) || other.periodEnd == periodEnd)&&(identical(other.totalFeedback, totalFeedback) || other.totalFeedback == totalFeedback)&&(identical(other.positiveCount, positiveCount) || other.positiveCount == positiveCount)&&(identical(other.negativeCount, negativeCount) || other.negativeCount == negativeCount)&&(identical(other.skippedCount, skippedCount) || other.skippedCount == skippedCount)&&(identical(other.weightedScoreSum, weightedScoreSum) || other.weightedScoreSum == weightedScoreSum)&&(identical(other.totalWeight, totalWeight) || other.totalWeight == totalWeight)&&const DeepCollectionEquality().equals(other.negativeReasonCounts, negativeReasonCounts)&&const DeepCollectionEquality().equals(other.topNegativeReasons, topNegativeReasons)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.experimentId, experimentId) || other.experimentId == experimentId)&&(identical(other.variantId, variantId) || other.variantId == variantId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,modelVersion,periodStart,periodEnd,totalFeedback,positiveCount,negativeCount,skippedCount,weightedScoreSum,totalWeight,const DeepCollectionEquality().hash(negativeReasonCounts),const DeepCollectionEquality().hash(topNegativeReasons),businessId,experimentId,variantId);

@override
String toString() {
  return 'FeedbackSummary(modelVersion: $modelVersion, periodStart: $periodStart, periodEnd: $periodEnd, totalFeedback: $totalFeedback, positiveCount: $positiveCount, negativeCount: $negativeCount, skippedCount: $skippedCount, weightedScoreSum: $weightedScoreSum, totalWeight: $totalWeight, negativeReasonCounts: $negativeReasonCounts, topNegativeReasons: $topNegativeReasons, businessId: $businessId, experimentId: $experimentId, variantId: $variantId)';
}


}

/// @nodoc
abstract mixin class $FeedbackSummaryCopyWith<$Res>  {
  factory $FeedbackSummaryCopyWith(FeedbackSummary value, $Res Function(FeedbackSummary) _then) = _$FeedbackSummaryCopyWithImpl;
@useResult
$Res call({
 String modelVersion,@TimestampConverter() DateTime periodStart,@TimestampConverter() DateTime periodEnd, int totalFeedback, int positiveCount, int negativeCount, int skippedCount, double weightedScoreSum, double totalWeight, Map<String, int> negativeReasonCounts, List<String> topNegativeReasons, String? businessId, String? experimentId, String? variantId
});




}
/// @nodoc
class _$FeedbackSummaryCopyWithImpl<$Res>
    implements $FeedbackSummaryCopyWith<$Res> {
  _$FeedbackSummaryCopyWithImpl(this._self, this._then);

  final FeedbackSummary _self;
  final $Res Function(FeedbackSummary) _then;

/// Create a copy of FeedbackSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? modelVersion = null,Object? periodStart = null,Object? periodEnd = null,Object? totalFeedback = null,Object? positiveCount = null,Object? negativeCount = null,Object? skippedCount = null,Object? weightedScoreSum = null,Object? totalWeight = null,Object? negativeReasonCounts = null,Object? topNegativeReasons = null,Object? businessId = freezed,Object? experimentId = freezed,Object? variantId = freezed,}) {
  return _then(_self.copyWith(
modelVersion: null == modelVersion ? _self.modelVersion : modelVersion // ignore: cast_nullable_to_non_nullable
as String,periodStart: null == periodStart ? _self.periodStart : periodStart // ignore: cast_nullable_to_non_nullable
as DateTime,periodEnd: null == periodEnd ? _self.periodEnd : periodEnd // ignore: cast_nullable_to_non_nullable
as DateTime,totalFeedback: null == totalFeedback ? _self.totalFeedback : totalFeedback // ignore: cast_nullable_to_non_nullable
as int,positiveCount: null == positiveCount ? _self.positiveCount : positiveCount // ignore: cast_nullable_to_non_nullable
as int,negativeCount: null == negativeCount ? _self.negativeCount : negativeCount // ignore: cast_nullable_to_non_nullable
as int,skippedCount: null == skippedCount ? _self.skippedCount : skippedCount // ignore: cast_nullable_to_non_nullable
as int,weightedScoreSum: null == weightedScoreSum ? _self.weightedScoreSum : weightedScoreSum // ignore: cast_nullable_to_non_nullable
as double,totalWeight: null == totalWeight ? _self.totalWeight : totalWeight // ignore: cast_nullable_to_non_nullable
as double,negativeReasonCounts: null == negativeReasonCounts ? _self.negativeReasonCounts : negativeReasonCounts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,topNegativeReasons: null == topNegativeReasons ? _self.topNegativeReasons : topNegativeReasons // ignore: cast_nullable_to_non_nullable
as List<String>,businessId: freezed == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String?,experimentId: freezed == experimentId ? _self.experimentId : experimentId // ignore: cast_nullable_to_non_nullable
as String?,variantId: freezed == variantId ? _self.variantId : variantId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FeedbackSummary].
extension FeedbackSummaryPatterns on FeedbackSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeedbackSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeedbackSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeedbackSummary value)  $default,){
final _that = this;
switch (_that) {
case _FeedbackSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeedbackSummary value)?  $default,){
final _that = this;
switch (_that) {
case _FeedbackSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String modelVersion, @TimestampConverter()  DateTime periodStart, @TimestampConverter()  DateTime periodEnd,  int totalFeedback,  int positiveCount,  int negativeCount,  int skippedCount,  double weightedScoreSum,  double totalWeight,  Map<String, int> negativeReasonCounts,  List<String> topNegativeReasons,  String? businessId,  String? experimentId,  String? variantId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeedbackSummary() when $default != null:
return $default(_that.modelVersion,_that.periodStart,_that.periodEnd,_that.totalFeedback,_that.positiveCount,_that.negativeCount,_that.skippedCount,_that.weightedScoreSum,_that.totalWeight,_that.negativeReasonCounts,_that.topNegativeReasons,_that.businessId,_that.experimentId,_that.variantId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String modelVersion, @TimestampConverter()  DateTime periodStart, @TimestampConverter()  DateTime periodEnd,  int totalFeedback,  int positiveCount,  int negativeCount,  int skippedCount,  double weightedScoreSum,  double totalWeight,  Map<String, int> negativeReasonCounts,  List<String> topNegativeReasons,  String? businessId,  String? experimentId,  String? variantId)  $default,) {final _that = this;
switch (_that) {
case _FeedbackSummary():
return $default(_that.modelVersion,_that.periodStart,_that.periodEnd,_that.totalFeedback,_that.positiveCount,_that.negativeCount,_that.skippedCount,_that.weightedScoreSum,_that.totalWeight,_that.negativeReasonCounts,_that.topNegativeReasons,_that.businessId,_that.experimentId,_that.variantId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String modelVersion, @TimestampConverter()  DateTime periodStart, @TimestampConverter()  DateTime periodEnd,  int totalFeedback,  int positiveCount,  int negativeCount,  int skippedCount,  double weightedScoreSum,  double totalWeight,  Map<String, int> negativeReasonCounts,  List<String> topNegativeReasons,  String? businessId,  String? experimentId,  String? variantId)?  $default,) {final _that = this;
switch (_that) {
case _FeedbackSummary() when $default != null:
return $default(_that.modelVersion,_that.periodStart,_that.periodEnd,_that.totalFeedback,_that.positiveCount,_that.negativeCount,_that.skippedCount,_that.weightedScoreSum,_that.totalWeight,_that.negativeReasonCounts,_that.topNegativeReasons,_that.businessId,_that.experimentId,_that.variantId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FeedbackSummary extends FeedbackSummary {
  const _FeedbackSummary({required this.modelVersion, @TimestampConverter() required this.periodStart, @TimestampConverter() required this.periodEnd, required this.totalFeedback, required this.positiveCount, required this.negativeCount, required this.skippedCount, required this.weightedScoreSum, required this.totalWeight, final  Map<String, int> negativeReasonCounts = const {}, final  List<String> topNegativeReasons = const [], this.businessId, this.experimentId, this.variantId}): _negativeReasonCounts = negativeReasonCounts,_topNegativeReasons = topNegativeReasons,super._();
  factory _FeedbackSummary.fromJson(Map<String, dynamic> json) => _$FeedbackSummaryFromJson(json);

/// Model version these metrics are for
@override final  String modelVersion;
/// Time period start
@override@TimestampConverter() final  DateTime periodStart;
/// Time period end
@override@TimestampConverter() final  DateTime periodEnd;
/// Total feedback submissions
@override final  int totalFeedback;
/// Positive feedback count
@override final  int positiveCount;
/// Negative feedback count
@override final  int negativeCount;
/// Skipped count
@override final  int skippedCount;
/// Sum of weighted scores
@override final  double weightedScoreSum;
/// Sum of weights (for averaging)
@override final  double totalWeight;
/// Breakdown by negative reason
 final  Map<String, int> _negativeReasonCounts;
/// Breakdown by negative reason
@override@JsonKey() Map<String, int> get negativeReasonCounts {
  if (_negativeReasonCounts is EqualUnmodifiableMapView) return _negativeReasonCounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_negativeReasonCounts);
}

/// Most common negative reasons
 final  List<String> _topNegativeReasons;
/// Most common negative reasons
@override@JsonKey() List<String> get topNegativeReasons {
  if (_topNegativeReasons is EqualUnmodifiableListView) return _topNegativeReasons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topNegativeReasons);
}

/// Business ID (if scoped to one business)
@override final  String? businessId;
/// Experiment ID (if scoped to an experiment)
@override final  String? experimentId;
/// Variant ID (if scoped to a variant)
@override final  String? variantId;

/// Create a copy of FeedbackSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeedbackSummaryCopyWith<_FeedbackSummary> get copyWith => __$FeedbackSummaryCopyWithImpl<_FeedbackSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FeedbackSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeedbackSummary&&(identical(other.modelVersion, modelVersion) || other.modelVersion == modelVersion)&&(identical(other.periodStart, periodStart) || other.periodStart == periodStart)&&(identical(other.periodEnd, periodEnd) || other.periodEnd == periodEnd)&&(identical(other.totalFeedback, totalFeedback) || other.totalFeedback == totalFeedback)&&(identical(other.positiveCount, positiveCount) || other.positiveCount == positiveCount)&&(identical(other.negativeCount, negativeCount) || other.negativeCount == negativeCount)&&(identical(other.skippedCount, skippedCount) || other.skippedCount == skippedCount)&&(identical(other.weightedScoreSum, weightedScoreSum) || other.weightedScoreSum == weightedScoreSum)&&(identical(other.totalWeight, totalWeight) || other.totalWeight == totalWeight)&&const DeepCollectionEquality().equals(other._negativeReasonCounts, _negativeReasonCounts)&&const DeepCollectionEquality().equals(other._topNegativeReasons, _topNegativeReasons)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.experimentId, experimentId) || other.experimentId == experimentId)&&(identical(other.variantId, variantId) || other.variantId == variantId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,modelVersion,periodStart,periodEnd,totalFeedback,positiveCount,negativeCount,skippedCount,weightedScoreSum,totalWeight,const DeepCollectionEquality().hash(_negativeReasonCounts),const DeepCollectionEquality().hash(_topNegativeReasons),businessId,experimentId,variantId);

@override
String toString() {
  return 'FeedbackSummary(modelVersion: $modelVersion, periodStart: $periodStart, periodEnd: $periodEnd, totalFeedback: $totalFeedback, positiveCount: $positiveCount, negativeCount: $negativeCount, skippedCount: $skippedCount, weightedScoreSum: $weightedScoreSum, totalWeight: $totalWeight, negativeReasonCounts: $negativeReasonCounts, topNegativeReasons: $topNegativeReasons, businessId: $businessId, experimentId: $experimentId, variantId: $variantId)';
}


}

/// @nodoc
abstract mixin class _$FeedbackSummaryCopyWith<$Res> implements $FeedbackSummaryCopyWith<$Res> {
  factory _$FeedbackSummaryCopyWith(_FeedbackSummary value, $Res Function(_FeedbackSummary) _then) = __$FeedbackSummaryCopyWithImpl;
@override @useResult
$Res call({
 String modelVersion,@TimestampConverter() DateTime periodStart,@TimestampConverter() DateTime periodEnd, int totalFeedback, int positiveCount, int negativeCount, int skippedCount, double weightedScoreSum, double totalWeight, Map<String, int> negativeReasonCounts, List<String> topNegativeReasons, String? businessId, String? experimentId, String? variantId
});




}
/// @nodoc
class __$FeedbackSummaryCopyWithImpl<$Res>
    implements _$FeedbackSummaryCopyWith<$Res> {
  __$FeedbackSummaryCopyWithImpl(this._self, this._then);

  final _FeedbackSummary _self;
  final $Res Function(_FeedbackSummary) _then;

/// Create a copy of FeedbackSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? modelVersion = null,Object? periodStart = null,Object? periodEnd = null,Object? totalFeedback = null,Object? positiveCount = null,Object? negativeCount = null,Object? skippedCount = null,Object? weightedScoreSum = null,Object? totalWeight = null,Object? negativeReasonCounts = null,Object? topNegativeReasons = null,Object? businessId = freezed,Object? experimentId = freezed,Object? variantId = freezed,}) {
  return _then(_FeedbackSummary(
modelVersion: null == modelVersion ? _self.modelVersion : modelVersion // ignore: cast_nullable_to_non_nullable
as String,periodStart: null == periodStart ? _self.periodStart : periodStart // ignore: cast_nullable_to_non_nullable
as DateTime,periodEnd: null == periodEnd ? _self.periodEnd : periodEnd // ignore: cast_nullable_to_non_nullable
as DateTime,totalFeedback: null == totalFeedback ? _self.totalFeedback : totalFeedback // ignore: cast_nullable_to_non_nullable
as int,positiveCount: null == positiveCount ? _self.positiveCount : positiveCount // ignore: cast_nullable_to_non_nullable
as int,negativeCount: null == negativeCount ? _self.negativeCount : negativeCount // ignore: cast_nullable_to_non_nullable
as int,skippedCount: null == skippedCount ? _self.skippedCount : skippedCount // ignore: cast_nullable_to_non_nullable
as int,weightedScoreSum: null == weightedScoreSum ? _self.weightedScoreSum : weightedScoreSum // ignore: cast_nullable_to_non_nullable
as double,totalWeight: null == totalWeight ? _self.totalWeight : totalWeight // ignore: cast_nullable_to_non_nullable
as double,negativeReasonCounts: null == negativeReasonCounts ? _self._negativeReasonCounts : negativeReasonCounts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,topNegativeReasons: null == topNegativeReasons ? _self._topNegativeReasons : topNegativeReasons // ignore: cast_nullable_to_non_nullable
as List<String>,businessId: freezed == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String?,experimentId: freezed == experimentId ? _self.experimentId : experimentId // ignore: cast_nullable_to_non_nullable
as String?,variantId: freezed == variantId ? _self.variantId : variantId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
