// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'model_metadata.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ModelMetadata {

/// Unique identifier for this model version
 String get modelId;/// Type of model (lightgbm, xgboost, llm, ortools)
 AIModelType get modelType;/// Semantic version string (e.g., '1.0.0')
 String get version;/// When the model was trained
 DateTime get trainedAt;/// Version of the feature schema this model expects
 int get featureSchemaVersion;/// Performance metrics from training/validation
/// Common keys: 'auc', 'accuracy', 'precision', 'recall', 'f1'
 Map<String, double> get metrics;/// Ordered list of feature names the model expects
 List<String> get featureNames;/// Optional human-readable description
 String? get description;/// Hyperparameters used during training
 Map<String, dynamic>? get hyperparameters;/// Number of training samples used
 int? get trainingSampleCount;/// Hash of training data for reproducibility verification
 String? get trainingDataHash;/// Who/what initiated the training (user, scheduled, auto-retrain)
 String? get trainedBy;/// Whether this is the currently active model for its type
 bool get isActive;/// When this model was deployed to production
 DateTime? get deployedAt;
/// Create a copy of ModelMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelMetadataCopyWith<ModelMetadata> get copyWith => _$ModelMetadataCopyWithImpl<ModelMetadata>(this as ModelMetadata, _$identity);

  /// Serializes this ModelMetadata to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelMetadata&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.modelType, modelType) || other.modelType == modelType)&&(identical(other.version, version) || other.version == version)&&(identical(other.trainedAt, trainedAt) || other.trainedAt == trainedAt)&&(identical(other.featureSchemaVersion, featureSchemaVersion) || other.featureSchemaVersion == featureSchemaVersion)&&const DeepCollectionEquality().equals(other.metrics, metrics)&&const DeepCollectionEquality().equals(other.featureNames, featureNames)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.hyperparameters, hyperparameters)&&(identical(other.trainingSampleCount, trainingSampleCount) || other.trainingSampleCount == trainingSampleCount)&&(identical(other.trainingDataHash, trainingDataHash) || other.trainingDataHash == trainingDataHash)&&(identical(other.trainedBy, trainedBy) || other.trainedBy == trainedBy)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.deployedAt, deployedAt) || other.deployedAt == deployedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,modelId,modelType,version,trainedAt,featureSchemaVersion,const DeepCollectionEquality().hash(metrics),const DeepCollectionEquality().hash(featureNames),description,const DeepCollectionEquality().hash(hyperparameters),trainingSampleCount,trainingDataHash,trainedBy,isActive,deployedAt);

@override
String toString() {
  return 'ModelMetadata(modelId: $modelId, modelType: $modelType, version: $version, trainedAt: $trainedAt, featureSchemaVersion: $featureSchemaVersion, metrics: $metrics, featureNames: $featureNames, description: $description, hyperparameters: $hyperparameters, trainingSampleCount: $trainingSampleCount, trainingDataHash: $trainingDataHash, trainedBy: $trainedBy, isActive: $isActive, deployedAt: $deployedAt)';
}


}

/// @nodoc
abstract mixin class $ModelMetadataCopyWith<$Res>  {
  factory $ModelMetadataCopyWith(ModelMetadata value, $Res Function(ModelMetadata) _then) = _$ModelMetadataCopyWithImpl;
@useResult
$Res call({
 String modelId, AIModelType modelType, String version, DateTime trainedAt, int featureSchemaVersion, Map<String, double> metrics, List<String> featureNames, String? description, Map<String, dynamic>? hyperparameters, int? trainingSampleCount, String? trainingDataHash, String? trainedBy, bool isActive, DateTime? deployedAt
});




}
/// @nodoc
class _$ModelMetadataCopyWithImpl<$Res>
    implements $ModelMetadataCopyWith<$Res> {
  _$ModelMetadataCopyWithImpl(this._self, this._then);

  final ModelMetadata _self;
  final $Res Function(ModelMetadata) _then;

/// Create a copy of ModelMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? modelId = null,Object? modelType = null,Object? version = null,Object? trainedAt = null,Object? featureSchemaVersion = null,Object? metrics = null,Object? featureNames = null,Object? description = freezed,Object? hyperparameters = freezed,Object? trainingSampleCount = freezed,Object? trainingDataHash = freezed,Object? trainedBy = freezed,Object? isActive = null,Object? deployedAt = freezed,}) {
  return _then(_self.copyWith(
modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,modelType: null == modelType ? _self.modelType : modelType // ignore: cast_nullable_to_non_nullable
as AIModelType,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,trainedAt: null == trainedAt ? _self.trainedAt : trainedAt // ignore: cast_nullable_to_non_nullable
as DateTime,featureSchemaVersion: null == featureSchemaVersion ? _self.featureSchemaVersion : featureSchemaVersion // ignore: cast_nullable_to_non_nullable
as int,metrics: null == metrics ? _self.metrics : metrics // ignore: cast_nullable_to_non_nullable
as Map<String, double>,featureNames: null == featureNames ? _self.featureNames : featureNames // ignore: cast_nullable_to_non_nullable
as List<String>,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,hyperparameters: freezed == hyperparameters ? _self.hyperparameters : hyperparameters // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,trainingSampleCount: freezed == trainingSampleCount ? _self.trainingSampleCount : trainingSampleCount // ignore: cast_nullable_to_non_nullable
as int?,trainingDataHash: freezed == trainingDataHash ? _self.trainingDataHash : trainingDataHash // ignore: cast_nullable_to_non_nullable
as String?,trainedBy: freezed == trainedBy ? _self.trainedBy : trainedBy // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,deployedAt: freezed == deployedAt ? _self.deployedAt : deployedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ModelMetadata].
extension ModelMetadataPatterns on ModelMetadata {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModelMetadata value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModelMetadata() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModelMetadata value)  $default,){
final _that = this;
switch (_that) {
case _ModelMetadata():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModelMetadata value)?  $default,){
final _that = this;
switch (_that) {
case _ModelMetadata() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String modelId,  AIModelType modelType,  String version,  DateTime trainedAt,  int featureSchemaVersion,  Map<String, double> metrics,  List<String> featureNames,  String? description,  Map<String, dynamic>? hyperparameters,  int? trainingSampleCount,  String? trainingDataHash,  String? trainedBy,  bool isActive,  DateTime? deployedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModelMetadata() when $default != null:
return $default(_that.modelId,_that.modelType,_that.version,_that.trainedAt,_that.featureSchemaVersion,_that.metrics,_that.featureNames,_that.description,_that.hyperparameters,_that.trainingSampleCount,_that.trainingDataHash,_that.trainedBy,_that.isActive,_that.deployedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String modelId,  AIModelType modelType,  String version,  DateTime trainedAt,  int featureSchemaVersion,  Map<String, double> metrics,  List<String> featureNames,  String? description,  Map<String, dynamic>? hyperparameters,  int? trainingSampleCount,  String? trainingDataHash,  String? trainedBy,  bool isActive,  DateTime? deployedAt)  $default,) {final _that = this;
switch (_that) {
case _ModelMetadata():
return $default(_that.modelId,_that.modelType,_that.version,_that.trainedAt,_that.featureSchemaVersion,_that.metrics,_that.featureNames,_that.description,_that.hyperparameters,_that.trainingSampleCount,_that.trainingDataHash,_that.trainedBy,_that.isActive,_that.deployedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String modelId,  AIModelType modelType,  String version,  DateTime trainedAt,  int featureSchemaVersion,  Map<String, double> metrics,  List<String> featureNames,  String? description,  Map<String, dynamic>? hyperparameters,  int? trainingSampleCount,  String? trainingDataHash,  String? trainedBy,  bool isActive,  DateTime? deployedAt)?  $default,) {final _that = this;
switch (_that) {
case _ModelMetadata() when $default != null:
return $default(_that.modelId,_that.modelType,_that.version,_that.trainedAt,_that.featureSchemaVersion,_that.metrics,_that.featureNames,_that.description,_that.hyperparameters,_that.trainingSampleCount,_that.trainingDataHash,_that.trainedBy,_that.isActive,_that.deployedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModelMetadata extends ModelMetadata {
  const _ModelMetadata({required this.modelId, required this.modelType, required this.version, required this.trainedAt, required this.featureSchemaVersion, required final  Map<String, double> metrics, required final  List<String> featureNames, this.description, final  Map<String, dynamic>? hyperparameters, this.trainingSampleCount, this.trainingDataHash, this.trainedBy, this.isActive = false, this.deployedAt}): _metrics = metrics,_featureNames = featureNames,_hyperparameters = hyperparameters,super._();
  factory _ModelMetadata.fromJson(Map<String, dynamic> json) => _$ModelMetadataFromJson(json);

/// Unique identifier for this model version
@override final  String modelId;
/// Type of model (lightgbm, xgboost, llm, ortools)
@override final  AIModelType modelType;
/// Semantic version string (e.g., '1.0.0')
@override final  String version;
/// When the model was trained
@override final  DateTime trainedAt;
/// Version of the feature schema this model expects
@override final  int featureSchemaVersion;
/// Performance metrics from training/validation
/// Common keys: 'auc', 'accuracy', 'precision', 'recall', 'f1'
 final  Map<String, double> _metrics;
/// Performance metrics from training/validation
/// Common keys: 'auc', 'accuracy', 'precision', 'recall', 'f1'
@override Map<String, double> get metrics {
  if (_metrics is EqualUnmodifiableMapView) return _metrics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metrics);
}

/// Ordered list of feature names the model expects
 final  List<String> _featureNames;
/// Ordered list of feature names the model expects
@override List<String> get featureNames {
  if (_featureNames is EqualUnmodifiableListView) return _featureNames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_featureNames);
}

/// Optional human-readable description
@override final  String? description;
/// Hyperparameters used during training
 final  Map<String, dynamic>? _hyperparameters;
/// Hyperparameters used during training
@override Map<String, dynamic>? get hyperparameters {
  final value = _hyperparameters;
  if (value == null) return null;
  if (_hyperparameters is EqualUnmodifiableMapView) return _hyperparameters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// Number of training samples used
@override final  int? trainingSampleCount;
/// Hash of training data for reproducibility verification
@override final  String? trainingDataHash;
/// Who/what initiated the training (user, scheduled, auto-retrain)
@override final  String? trainedBy;
/// Whether this is the currently active model for its type
@override@JsonKey() final  bool isActive;
/// When this model was deployed to production
@override final  DateTime? deployedAt;

/// Create a copy of ModelMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModelMetadataCopyWith<_ModelMetadata> get copyWith => __$ModelMetadataCopyWithImpl<_ModelMetadata>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModelMetadataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModelMetadata&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.modelType, modelType) || other.modelType == modelType)&&(identical(other.version, version) || other.version == version)&&(identical(other.trainedAt, trainedAt) || other.trainedAt == trainedAt)&&(identical(other.featureSchemaVersion, featureSchemaVersion) || other.featureSchemaVersion == featureSchemaVersion)&&const DeepCollectionEquality().equals(other._metrics, _metrics)&&const DeepCollectionEquality().equals(other._featureNames, _featureNames)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._hyperparameters, _hyperparameters)&&(identical(other.trainingSampleCount, trainingSampleCount) || other.trainingSampleCount == trainingSampleCount)&&(identical(other.trainingDataHash, trainingDataHash) || other.trainingDataHash == trainingDataHash)&&(identical(other.trainedBy, trainedBy) || other.trainedBy == trainedBy)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.deployedAt, deployedAt) || other.deployedAt == deployedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,modelId,modelType,version,trainedAt,featureSchemaVersion,const DeepCollectionEquality().hash(_metrics),const DeepCollectionEquality().hash(_featureNames),description,const DeepCollectionEquality().hash(_hyperparameters),trainingSampleCount,trainingDataHash,trainedBy,isActive,deployedAt);

@override
String toString() {
  return 'ModelMetadata(modelId: $modelId, modelType: $modelType, version: $version, trainedAt: $trainedAt, featureSchemaVersion: $featureSchemaVersion, metrics: $metrics, featureNames: $featureNames, description: $description, hyperparameters: $hyperparameters, trainingSampleCount: $trainingSampleCount, trainingDataHash: $trainingDataHash, trainedBy: $trainedBy, isActive: $isActive, deployedAt: $deployedAt)';
}


}

/// @nodoc
abstract mixin class _$ModelMetadataCopyWith<$Res> implements $ModelMetadataCopyWith<$Res> {
  factory _$ModelMetadataCopyWith(_ModelMetadata value, $Res Function(_ModelMetadata) _then) = __$ModelMetadataCopyWithImpl;
@override @useResult
$Res call({
 String modelId, AIModelType modelType, String version, DateTime trainedAt, int featureSchemaVersion, Map<String, double> metrics, List<String> featureNames, String? description, Map<String, dynamic>? hyperparameters, int? trainingSampleCount, String? trainingDataHash, String? trainedBy, bool isActive, DateTime? deployedAt
});




}
/// @nodoc
class __$ModelMetadataCopyWithImpl<$Res>
    implements _$ModelMetadataCopyWith<$Res> {
  __$ModelMetadataCopyWithImpl(this._self, this._then);

  final _ModelMetadata _self;
  final $Res Function(_ModelMetadata) _then;

/// Create a copy of ModelMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? modelId = null,Object? modelType = null,Object? version = null,Object? trainedAt = null,Object? featureSchemaVersion = null,Object? metrics = null,Object? featureNames = null,Object? description = freezed,Object? hyperparameters = freezed,Object? trainingSampleCount = freezed,Object? trainingDataHash = freezed,Object? trainedBy = freezed,Object? isActive = null,Object? deployedAt = freezed,}) {
  return _then(_ModelMetadata(
modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,modelType: null == modelType ? _self.modelType : modelType // ignore: cast_nullable_to_non_nullable
as AIModelType,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,trainedAt: null == trainedAt ? _self.trainedAt : trainedAt // ignore: cast_nullable_to_non_nullable
as DateTime,featureSchemaVersion: null == featureSchemaVersion ? _self.featureSchemaVersion : featureSchemaVersion // ignore: cast_nullable_to_non_nullable
as int,metrics: null == metrics ? _self._metrics : metrics // ignore: cast_nullable_to_non_nullable
as Map<String, double>,featureNames: null == featureNames ? _self._featureNames : featureNames // ignore: cast_nullable_to_non_nullable
as List<String>,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,hyperparameters: freezed == hyperparameters ? _self._hyperparameters : hyperparameters // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,trainingSampleCount: freezed == trainingSampleCount ? _self.trainingSampleCount : trainingSampleCount // ignore: cast_nullable_to_non_nullable
as int?,trainingDataHash: freezed == trainingDataHash ? _self.trainingDataHash : trainingDataHash // ignore: cast_nullable_to_non_nullable
as String?,trainedBy: freezed == trainedBy ? _self.trainedBy : trainedBy // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,deployedAt: freezed == deployedAt ? _self.deployedAt : deployedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$LoadedModels {

/// No-show prediction model metadata
 ModelMetadata? get predictionModel;/// Sentiment analysis model metadata (LLM info)
 ModelMetadata? get sentimentModel;/// Route optimization model metadata
 ModelMetadata? get routeModel;/// When models were last refreshed
 DateTime? get lastRefreshed;
/// Create a copy of LoadedModels
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoadedModelsCopyWith<LoadedModels> get copyWith => _$LoadedModelsCopyWithImpl<LoadedModels>(this as LoadedModels, _$identity);

  /// Serializes this LoadedModels to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoadedModels&&(identical(other.predictionModel, predictionModel) || other.predictionModel == predictionModel)&&(identical(other.sentimentModel, sentimentModel) || other.sentimentModel == sentimentModel)&&(identical(other.routeModel, routeModel) || other.routeModel == routeModel)&&(identical(other.lastRefreshed, lastRefreshed) || other.lastRefreshed == lastRefreshed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,predictionModel,sentimentModel,routeModel,lastRefreshed);

@override
String toString() {
  return 'LoadedModels(predictionModel: $predictionModel, sentimentModel: $sentimentModel, routeModel: $routeModel, lastRefreshed: $lastRefreshed)';
}


}

/// @nodoc
abstract mixin class $LoadedModelsCopyWith<$Res>  {
  factory $LoadedModelsCopyWith(LoadedModels value, $Res Function(LoadedModels) _then) = _$LoadedModelsCopyWithImpl;
@useResult
$Res call({
 ModelMetadata? predictionModel, ModelMetadata? sentimentModel, ModelMetadata? routeModel, DateTime? lastRefreshed
});


$ModelMetadataCopyWith<$Res>? get predictionModel;$ModelMetadataCopyWith<$Res>? get sentimentModel;$ModelMetadataCopyWith<$Res>? get routeModel;

}
/// @nodoc
class _$LoadedModelsCopyWithImpl<$Res>
    implements $LoadedModelsCopyWith<$Res> {
  _$LoadedModelsCopyWithImpl(this._self, this._then);

  final LoadedModels _self;
  final $Res Function(LoadedModels) _then;

/// Create a copy of LoadedModels
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? predictionModel = freezed,Object? sentimentModel = freezed,Object? routeModel = freezed,Object? lastRefreshed = freezed,}) {
  return _then(_self.copyWith(
predictionModel: freezed == predictionModel ? _self.predictionModel : predictionModel // ignore: cast_nullable_to_non_nullable
as ModelMetadata?,sentimentModel: freezed == sentimentModel ? _self.sentimentModel : sentimentModel // ignore: cast_nullable_to_non_nullable
as ModelMetadata?,routeModel: freezed == routeModel ? _self.routeModel : routeModel // ignore: cast_nullable_to_non_nullable
as ModelMetadata?,lastRefreshed: freezed == lastRefreshed ? _self.lastRefreshed : lastRefreshed // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of LoadedModels
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModelMetadataCopyWith<$Res>? get predictionModel {
    if (_self.predictionModel == null) {
    return null;
  }

  return $ModelMetadataCopyWith<$Res>(_self.predictionModel!, (value) {
    return _then(_self.copyWith(predictionModel: value));
  });
}/// Create a copy of LoadedModels
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModelMetadataCopyWith<$Res>? get sentimentModel {
    if (_self.sentimentModel == null) {
    return null;
  }

  return $ModelMetadataCopyWith<$Res>(_self.sentimentModel!, (value) {
    return _then(_self.copyWith(sentimentModel: value));
  });
}/// Create a copy of LoadedModels
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModelMetadataCopyWith<$Res>? get routeModel {
    if (_self.routeModel == null) {
    return null;
  }

  return $ModelMetadataCopyWith<$Res>(_self.routeModel!, (value) {
    return _then(_self.copyWith(routeModel: value));
  });
}
}


/// Adds pattern-matching-related methods to [LoadedModels].
extension LoadedModelsPatterns on LoadedModels {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LoadedModels value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LoadedModels() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LoadedModels value)  $default,){
final _that = this;
switch (_that) {
case _LoadedModels():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LoadedModels value)?  $default,){
final _that = this;
switch (_that) {
case _LoadedModels() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ModelMetadata? predictionModel,  ModelMetadata? sentimentModel,  ModelMetadata? routeModel,  DateTime? lastRefreshed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LoadedModels() when $default != null:
return $default(_that.predictionModel,_that.sentimentModel,_that.routeModel,_that.lastRefreshed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ModelMetadata? predictionModel,  ModelMetadata? sentimentModel,  ModelMetadata? routeModel,  DateTime? lastRefreshed)  $default,) {final _that = this;
switch (_that) {
case _LoadedModels():
return $default(_that.predictionModel,_that.sentimentModel,_that.routeModel,_that.lastRefreshed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ModelMetadata? predictionModel,  ModelMetadata? sentimentModel,  ModelMetadata? routeModel,  DateTime? lastRefreshed)?  $default,) {final _that = this;
switch (_that) {
case _LoadedModels() when $default != null:
return $default(_that.predictionModel,_that.sentimentModel,_that.routeModel,_that.lastRefreshed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LoadedModels extends LoadedModels {
  const _LoadedModels({this.predictionModel, this.sentimentModel, this.routeModel, this.lastRefreshed}): super._();
  factory _LoadedModels.fromJson(Map<String, dynamic> json) => _$LoadedModelsFromJson(json);

/// No-show prediction model metadata
@override final  ModelMetadata? predictionModel;
/// Sentiment analysis model metadata (LLM info)
@override final  ModelMetadata? sentimentModel;
/// Route optimization model metadata
@override final  ModelMetadata? routeModel;
/// When models were last refreshed
@override final  DateTime? lastRefreshed;

/// Create a copy of LoadedModels
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedModelsCopyWith<_LoadedModels> get copyWith => __$LoadedModelsCopyWithImpl<_LoadedModels>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LoadedModelsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadedModels&&(identical(other.predictionModel, predictionModel) || other.predictionModel == predictionModel)&&(identical(other.sentimentModel, sentimentModel) || other.sentimentModel == sentimentModel)&&(identical(other.routeModel, routeModel) || other.routeModel == routeModel)&&(identical(other.lastRefreshed, lastRefreshed) || other.lastRefreshed == lastRefreshed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,predictionModel,sentimentModel,routeModel,lastRefreshed);

@override
String toString() {
  return 'LoadedModels(predictionModel: $predictionModel, sentimentModel: $sentimentModel, routeModel: $routeModel, lastRefreshed: $lastRefreshed)';
}


}

/// @nodoc
abstract mixin class _$LoadedModelsCopyWith<$Res> implements $LoadedModelsCopyWith<$Res> {
  factory _$LoadedModelsCopyWith(_LoadedModels value, $Res Function(_LoadedModels) _then) = __$LoadedModelsCopyWithImpl;
@override @useResult
$Res call({
 ModelMetadata? predictionModel, ModelMetadata? sentimentModel, ModelMetadata? routeModel, DateTime? lastRefreshed
});


@override $ModelMetadataCopyWith<$Res>? get predictionModel;@override $ModelMetadataCopyWith<$Res>? get sentimentModel;@override $ModelMetadataCopyWith<$Res>? get routeModel;

}
/// @nodoc
class __$LoadedModelsCopyWithImpl<$Res>
    implements _$LoadedModelsCopyWith<$Res> {
  __$LoadedModelsCopyWithImpl(this._self, this._then);

  final _LoadedModels _self;
  final $Res Function(_LoadedModels) _then;

/// Create a copy of LoadedModels
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? predictionModel = freezed,Object? sentimentModel = freezed,Object? routeModel = freezed,Object? lastRefreshed = freezed,}) {
  return _then(_LoadedModels(
predictionModel: freezed == predictionModel ? _self.predictionModel : predictionModel // ignore: cast_nullable_to_non_nullable
as ModelMetadata?,sentimentModel: freezed == sentimentModel ? _self.sentimentModel : sentimentModel // ignore: cast_nullable_to_non_nullable
as ModelMetadata?,routeModel: freezed == routeModel ? _self.routeModel : routeModel // ignore: cast_nullable_to_non_nullable
as ModelMetadata?,lastRefreshed: freezed == lastRefreshed ? _self.lastRefreshed : lastRefreshed // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of LoadedModels
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModelMetadataCopyWith<$Res>? get predictionModel {
    if (_self.predictionModel == null) {
    return null;
  }

  return $ModelMetadataCopyWith<$Res>(_self.predictionModel!, (value) {
    return _then(_self.copyWith(predictionModel: value));
  });
}/// Create a copy of LoadedModels
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModelMetadataCopyWith<$Res>? get sentimentModel {
    if (_self.sentimentModel == null) {
    return null;
  }

  return $ModelMetadataCopyWith<$Res>(_self.sentimentModel!, (value) {
    return _then(_self.copyWith(sentimentModel: value));
  });
}/// Create a copy of LoadedModels
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModelMetadataCopyWith<$Res>? get routeModel {
    if (_self.routeModel == null) {
    return null;
  }

  return $ModelMetadataCopyWith<$Res>(_self.routeModel!, (value) {
    return _then(_self.copyWith(routeModel: value));
  });
}
}

// dart format on
