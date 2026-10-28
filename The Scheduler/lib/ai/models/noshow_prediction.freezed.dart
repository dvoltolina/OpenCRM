// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'noshow_prediction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecommendedAction {

/// Unique identifier for this action type
 String get actionId;/// Human-readable title for the action
 String get title;/// Detailed description of what to do
 String get description;/// Priority level of this action
 ActionPriority get priority;/// Whether this action can be automated (e.g., send reminder)
 bool get automatable;/// Icon name for UI display (optional)
 String? get iconName;/// Estimated impact on no-show probability reduction (0.0-1.0)
 double? get estimatedImpact;
/// Create a copy of RecommendedAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecommendedActionCopyWith<RecommendedAction> get copyWith => _$RecommendedActionCopyWithImpl<RecommendedAction>(this as RecommendedAction, _$identity);

  /// Serializes this RecommendedAction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecommendedAction&&(identical(other.actionId, actionId) || other.actionId == actionId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.automatable, automatable) || other.automatable == automatable)&&(identical(other.iconName, iconName) || other.iconName == iconName)&&(identical(other.estimatedImpact, estimatedImpact) || other.estimatedImpact == estimatedImpact));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,actionId,title,description,priority,automatable,iconName,estimatedImpact);

@override
String toString() {
  return 'RecommendedAction(actionId: $actionId, title: $title, description: $description, priority: $priority, automatable: $automatable, iconName: $iconName, estimatedImpact: $estimatedImpact)';
}


}

/// @nodoc
abstract mixin class $RecommendedActionCopyWith<$Res>  {
  factory $RecommendedActionCopyWith(RecommendedAction value, $Res Function(RecommendedAction) _then) = _$RecommendedActionCopyWithImpl;
@useResult
$Res call({
 String actionId, String title, String description, ActionPriority priority, bool automatable, String? iconName, double? estimatedImpact
});




}
/// @nodoc
class _$RecommendedActionCopyWithImpl<$Res>
    implements $RecommendedActionCopyWith<$Res> {
  _$RecommendedActionCopyWithImpl(this._self, this._then);

  final RecommendedAction _self;
  final $Res Function(RecommendedAction) _then;

/// Create a copy of RecommendedAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? actionId = null,Object? title = null,Object? description = null,Object? priority = null,Object? automatable = null,Object? iconName = freezed,Object? estimatedImpact = freezed,}) {
  return _then(_self.copyWith(
actionId: null == actionId ? _self.actionId : actionId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as ActionPriority,automatable: null == automatable ? _self.automatable : automatable // ignore: cast_nullable_to_non_nullable
as bool,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,estimatedImpact: freezed == estimatedImpact ? _self.estimatedImpact : estimatedImpact // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [RecommendedAction].
extension RecommendedActionPatterns on RecommendedAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecommendedAction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecommendedAction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecommendedAction value)  $default,){
final _that = this;
switch (_that) {
case _RecommendedAction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecommendedAction value)?  $default,){
final _that = this;
switch (_that) {
case _RecommendedAction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String actionId,  String title,  String description,  ActionPriority priority,  bool automatable,  String? iconName,  double? estimatedImpact)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecommendedAction() when $default != null:
return $default(_that.actionId,_that.title,_that.description,_that.priority,_that.automatable,_that.iconName,_that.estimatedImpact);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String actionId,  String title,  String description,  ActionPriority priority,  bool automatable,  String? iconName,  double? estimatedImpact)  $default,) {final _that = this;
switch (_that) {
case _RecommendedAction():
return $default(_that.actionId,_that.title,_that.description,_that.priority,_that.automatable,_that.iconName,_that.estimatedImpact);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String actionId,  String title,  String description,  ActionPriority priority,  bool automatable,  String? iconName,  double? estimatedImpact)?  $default,) {final _that = this;
switch (_that) {
case _RecommendedAction() when $default != null:
return $default(_that.actionId,_that.title,_that.description,_that.priority,_that.automatable,_that.iconName,_that.estimatedImpact);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecommendedAction extends RecommendedAction {
  const _RecommendedAction({required this.actionId, required this.title, required this.description, required this.priority, required this.automatable, this.iconName, this.estimatedImpact}): super._();
  factory _RecommendedAction.fromJson(Map<String, dynamic> json) => _$RecommendedActionFromJson(json);

/// Unique identifier for this action type
@override final  String actionId;
/// Human-readable title for the action
@override final  String title;
/// Detailed description of what to do
@override final  String description;
/// Priority level of this action
@override final  ActionPriority priority;
/// Whether this action can be automated (e.g., send reminder)
@override final  bool automatable;
/// Icon name for UI display (optional)
@override final  String? iconName;
/// Estimated impact on no-show probability reduction (0.0-1.0)
@override final  double? estimatedImpact;

/// Create a copy of RecommendedAction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecommendedActionCopyWith<_RecommendedAction> get copyWith => __$RecommendedActionCopyWithImpl<_RecommendedAction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecommendedActionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecommendedAction&&(identical(other.actionId, actionId) || other.actionId == actionId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.automatable, automatable) || other.automatable == automatable)&&(identical(other.iconName, iconName) || other.iconName == iconName)&&(identical(other.estimatedImpact, estimatedImpact) || other.estimatedImpact == estimatedImpact));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,actionId,title,description,priority,automatable,iconName,estimatedImpact);

@override
String toString() {
  return 'RecommendedAction(actionId: $actionId, title: $title, description: $description, priority: $priority, automatable: $automatable, iconName: $iconName, estimatedImpact: $estimatedImpact)';
}


}

/// @nodoc
abstract mixin class _$RecommendedActionCopyWith<$Res> implements $RecommendedActionCopyWith<$Res> {
  factory _$RecommendedActionCopyWith(_RecommendedAction value, $Res Function(_RecommendedAction) _then) = __$RecommendedActionCopyWithImpl;
@override @useResult
$Res call({
 String actionId, String title, String description, ActionPriority priority, bool automatable, String? iconName, double? estimatedImpact
});




}
/// @nodoc
class __$RecommendedActionCopyWithImpl<$Res>
    implements _$RecommendedActionCopyWith<$Res> {
  __$RecommendedActionCopyWithImpl(this._self, this._then);

  final _RecommendedAction _self;
  final $Res Function(_RecommendedAction) _then;

/// Create a copy of RecommendedAction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? actionId = null,Object? title = null,Object? description = null,Object? priority = null,Object? automatable = null,Object? iconName = freezed,Object? estimatedImpact = freezed,}) {
  return _then(_RecommendedAction(
actionId: null == actionId ? _self.actionId : actionId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as ActionPriority,automatable: null == automatable ? _self.automatable : automatable // ignore: cast_nullable_to_non_nullable
as bool,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,estimatedImpact: freezed == estimatedImpact ? _self.estimatedImpact : estimatedImpact // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$NoshowPrediction {

/// Appointment ID this prediction is for
 String get appointmentId;/// Probability of no-show (0.0-1.0)
/// 0.0 = definitely will show, 1.0 = definitely will no-show
 double get probability;/// Calculated risk level based on probability and thresholds
 RiskLevel get riskLevel;/// Model's confidence in this prediction (0.0-1.0)
/// Lower confidence may indicate edge cases or unusual patterns
 double get confidence;/// Recommended actions to reduce no-show risk, ordered by priority
 List<RecommendedAction> get recommendedActions;/// Top features that contributed to this prediction, ordered by importance
 List<FeatureImportance> get topFeatures;/// Version of the model that made this prediction
 String get modelVersion;/// Timestamp when prediction was made
 DateTime get predictedAt;/// Timestamp when this prediction expires and should be refreshed
 DateTime get expiresAt;/// Request ID for tracing/debugging
 String? get requestId;
/// Create a copy of NoshowPrediction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NoshowPredictionCopyWith<NoshowPrediction> get copyWith => _$NoshowPredictionCopyWithImpl<NoshowPrediction>(this as NoshowPrediction, _$identity);

  /// Serializes this NoshowPrediction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NoshowPrediction&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.probability, probability) || other.probability == probability)&&(identical(other.riskLevel, riskLevel) || other.riskLevel == riskLevel)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&const DeepCollectionEquality().equals(other.recommendedActions, recommendedActions)&&const DeepCollectionEquality().equals(other.topFeatures, topFeatures)&&(identical(other.modelVersion, modelVersion) || other.modelVersion == modelVersion)&&(identical(other.predictedAt, predictedAt) || other.predictedAt == predictedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.requestId, requestId) || other.requestId == requestId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appointmentId,probability,riskLevel,confidence,const DeepCollectionEquality().hash(recommendedActions),const DeepCollectionEquality().hash(topFeatures),modelVersion,predictedAt,expiresAt,requestId);

@override
String toString() {
  return 'NoshowPrediction(appointmentId: $appointmentId, probability: $probability, riskLevel: $riskLevel, confidence: $confidence, recommendedActions: $recommendedActions, topFeatures: $topFeatures, modelVersion: $modelVersion, predictedAt: $predictedAt, expiresAt: $expiresAt, requestId: $requestId)';
}


}

/// @nodoc
abstract mixin class $NoshowPredictionCopyWith<$Res>  {
  factory $NoshowPredictionCopyWith(NoshowPrediction value, $Res Function(NoshowPrediction) _then) = _$NoshowPredictionCopyWithImpl;
@useResult
$Res call({
 String appointmentId, double probability, RiskLevel riskLevel, double confidence, List<RecommendedAction> recommendedActions, List<FeatureImportance> topFeatures, String modelVersion, DateTime predictedAt, DateTime expiresAt, String? requestId
});




}
/// @nodoc
class _$NoshowPredictionCopyWithImpl<$Res>
    implements $NoshowPredictionCopyWith<$Res> {
  _$NoshowPredictionCopyWithImpl(this._self, this._then);

  final NoshowPrediction _self;
  final $Res Function(NoshowPrediction) _then;

/// Create a copy of NoshowPrediction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? appointmentId = null,Object? probability = null,Object? riskLevel = null,Object? confidence = null,Object? recommendedActions = null,Object? topFeatures = null,Object? modelVersion = null,Object? predictedAt = null,Object? expiresAt = null,Object? requestId = freezed,}) {
  return _then(_self.copyWith(
appointmentId: null == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String,probability: null == probability ? _self.probability : probability // ignore: cast_nullable_to_non_nullable
as double,riskLevel: null == riskLevel ? _self.riskLevel : riskLevel // ignore: cast_nullable_to_non_nullable
as RiskLevel,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,recommendedActions: null == recommendedActions ? _self.recommendedActions : recommendedActions // ignore: cast_nullable_to_non_nullable
as List<RecommendedAction>,topFeatures: null == topFeatures ? _self.topFeatures : topFeatures // ignore: cast_nullable_to_non_nullable
as List<FeatureImportance>,modelVersion: null == modelVersion ? _self.modelVersion : modelVersion // ignore: cast_nullable_to_non_nullable
as String,predictedAt: null == predictedAt ? _self.predictedAt : predictedAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,requestId: freezed == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [NoshowPrediction].
extension NoshowPredictionPatterns on NoshowPrediction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NoshowPrediction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NoshowPrediction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NoshowPrediction value)  $default,){
final _that = this;
switch (_that) {
case _NoshowPrediction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NoshowPrediction value)?  $default,){
final _that = this;
switch (_that) {
case _NoshowPrediction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String appointmentId,  double probability,  RiskLevel riskLevel,  double confidence,  List<RecommendedAction> recommendedActions,  List<FeatureImportance> topFeatures,  String modelVersion,  DateTime predictedAt,  DateTime expiresAt,  String? requestId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NoshowPrediction() when $default != null:
return $default(_that.appointmentId,_that.probability,_that.riskLevel,_that.confidence,_that.recommendedActions,_that.topFeatures,_that.modelVersion,_that.predictedAt,_that.expiresAt,_that.requestId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String appointmentId,  double probability,  RiskLevel riskLevel,  double confidence,  List<RecommendedAction> recommendedActions,  List<FeatureImportance> topFeatures,  String modelVersion,  DateTime predictedAt,  DateTime expiresAt,  String? requestId)  $default,) {final _that = this;
switch (_that) {
case _NoshowPrediction():
return $default(_that.appointmentId,_that.probability,_that.riskLevel,_that.confidence,_that.recommendedActions,_that.topFeatures,_that.modelVersion,_that.predictedAt,_that.expiresAt,_that.requestId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String appointmentId,  double probability,  RiskLevel riskLevel,  double confidence,  List<RecommendedAction> recommendedActions,  List<FeatureImportance> topFeatures,  String modelVersion,  DateTime predictedAt,  DateTime expiresAt,  String? requestId)?  $default,) {final _that = this;
switch (_that) {
case _NoshowPrediction() when $default != null:
return $default(_that.appointmentId,_that.probability,_that.riskLevel,_that.confidence,_that.recommendedActions,_that.topFeatures,_that.modelVersion,_that.predictedAt,_that.expiresAt,_that.requestId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NoshowPrediction extends NoshowPrediction {
  const _NoshowPrediction({required this.appointmentId, required this.probability, required this.riskLevel, required this.confidence, required final  List<RecommendedAction> recommendedActions, required final  List<FeatureImportance> topFeatures, required this.modelVersion, required this.predictedAt, required this.expiresAt, this.requestId}): _recommendedActions = recommendedActions,_topFeatures = topFeatures,super._();
  factory _NoshowPrediction.fromJson(Map<String, dynamic> json) => _$NoshowPredictionFromJson(json);

/// Appointment ID this prediction is for
@override final  String appointmentId;
/// Probability of no-show (0.0-1.0)
/// 0.0 = definitely will show, 1.0 = definitely will no-show
@override final  double probability;
/// Calculated risk level based on probability and thresholds
@override final  RiskLevel riskLevel;
/// Model's confidence in this prediction (0.0-1.0)
/// Lower confidence may indicate edge cases or unusual patterns
@override final  double confidence;
/// Recommended actions to reduce no-show risk, ordered by priority
 final  List<RecommendedAction> _recommendedActions;
/// Recommended actions to reduce no-show risk, ordered by priority
@override List<RecommendedAction> get recommendedActions {
  if (_recommendedActions is EqualUnmodifiableListView) return _recommendedActions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recommendedActions);
}

/// Top features that contributed to this prediction, ordered by importance
 final  List<FeatureImportance> _topFeatures;
/// Top features that contributed to this prediction, ordered by importance
@override List<FeatureImportance> get topFeatures {
  if (_topFeatures is EqualUnmodifiableListView) return _topFeatures;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topFeatures);
}

/// Version of the model that made this prediction
@override final  String modelVersion;
/// Timestamp when prediction was made
@override final  DateTime predictedAt;
/// Timestamp when this prediction expires and should be refreshed
@override final  DateTime expiresAt;
/// Request ID for tracing/debugging
@override final  String? requestId;

/// Create a copy of NoshowPrediction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NoshowPredictionCopyWith<_NoshowPrediction> get copyWith => __$NoshowPredictionCopyWithImpl<_NoshowPrediction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NoshowPredictionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NoshowPrediction&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.probability, probability) || other.probability == probability)&&(identical(other.riskLevel, riskLevel) || other.riskLevel == riskLevel)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&const DeepCollectionEquality().equals(other._recommendedActions, _recommendedActions)&&const DeepCollectionEquality().equals(other._topFeatures, _topFeatures)&&(identical(other.modelVersion, modelVersion) || other.modelVersion == modelVersion)&&(identical(other.predictedAt, predictedAt) || other.predictedAt == predictedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.requestId, requestId) || other.requestId == requestId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appointmentId,probability,riskLevel,confidence,const DeepCollectionEquality().hash(_recommendedActions),const DeepCollectionEquality().hash(_topFeatures),modelVersion,predictedAt,expiresAt,requestId);

@override
String toString() {
  return 'NoshowPrediction(appointmentId: $appointmentId, probability: $probability, riskLevel: $riskLevel, confidence: $confidence, recommendedActions: $recommendedActions, topFeatures: $topFeatures, modelVersion: $modelVersion, predictedAt: $predictedAt, expiresAt: $expiresAt, requestId: $requestId)';
}


}

/// @nodoc
abstract mixin class _$NoshowPredictionCopyWith<$Res> implements $NoshowPredictionCopyWith<$Res> {
  factory _$NoshowPredictionCopyWith(_NoshowPrediction value, $Res Function(_NoshowPrediction) _then) = __$NoshowPredictionCopyWithImpl;
@override @useResult
$Res call({
 String appointmentId, double probability, RiskLevel riskLevel, double confidence, List<RecommendedAction> recommendedActions, List<FeatureImportance> topFeatures, String modelVersion, DateTime predictedAt, DateTime expiresAt, String? requestId
});




}
/// @nodoc
class __$NoshowPredictionCopyWithImpl<$Res>
    implements _$NoshowPredictionCopyWith<$Res> {
  __$NoshowPredictionCopyWithImpl(this._self, this._then);

  final _NoshowPrediction _self;
  final $Res Function(_NoshowPrediction) _then;

/// Create a copy of NoshowPrediction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? appointmentId = null,Object? probability = null,Object? riskLevel = null,Object? confidence = null,Object? recommendedActions = null,Object? topFeatures = null,Object? modelVersion = null,Object? predictedAt = null,Object? expiresAt = null,Object? requestId = freezed,}) {
  return _then(_NoshowPrediction(
appointmentId: null == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String,probability: null == probability ? _self.probability : probability // ignore: cast_nullable_to_non_nullable
as double,riskLevel: null == riskLevel ? _self.riskLevel : riskLevel // ignore: cast_nullable_to_non_nullable
as RiskLevel,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,recommendedActions: null == recommendedActions ? _self._recommendedActions : recommendedActions // ignore: cast_nullable_to_non_nullable
as List<RecommendedAction>,topFeatures: null == topFeatures ? _self._topFeatures : topFeatures // ignore: cast_nullable_to_non_nullable
as List<FeatureImportance>,modelVersion: null == modelVersion ? _self.modelVersion : modelVersion // ignore: cast_nullable_to_non_nullable
as String,predictedAt: null == predictedAt ? _self.predictedAt : predictedAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,requestId: freezed == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
