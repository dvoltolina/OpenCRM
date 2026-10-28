// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'experiment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExperimentVariant {

/// Unique identifier for this variant
 String get id;/// Human-readable name (e.g., "Control", "Treatment A")
 String get name;/// Description of what this variant does
 String? get description;/// Percentage of traffic allocated to this variant (0-100)
/// All variants in an experiment should sum to 100
 int get trafficPercentage;/// Whether this is the control variant (baseline)
 bool get isControl;/// Variant-specific configuration
/// For model_comparison: {"model_version": "v2.0"}
/// For threshold_testing: {"high_risk_threshold": 0.5}
/// For ui_treatment: {"show_explanation": true}
/// For feature_testing: {"enable_weather": true}
 Map<String, dynamic> get config;/// Number of users assigned to this variant
 int get assignmentCount;/// Number of conversions (positive outcomes)
 int get conversionCount;
/// Create a copy of ExperimentVariant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExperimentVariantCopyWith<ExperimentVariant> get copyWith => _$ExperimentVariantCopyWithImpl<ExperimentVariant>(this as ExperimentVariant, _$identity);

  /// Serializes this ExperimentVariant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExperimentVariant&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.trafficPercentage, trafficPercentage) || other.trafficPercentage == trafficPercentage)&&(identical(other.isControl, isControl) || other.isControl == isControl)&&const DeepCollectionEquality().equals(other.config, config)&&(identical(other.assignmentCount, assignmentCount) || other.assignmentCount == assignmentCount)&&(identical(other.conversionCount, conversionCount) || other.conversionCount == conversionCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,trafficPercentage,isControl,const DeepCollectionEquality().hash(config),assignmentCount,conversionCount);

@override
String toString() {
  return 'ExperimentVariant(id: $id, name: $name, description: $description, trafficPercentage: $trafficPercentage, isControl: $isControl, config: $config, assignmentCount: $assignmentCount, conversionCount: $conversionCount)';
}


}

/// @nodoc
abstract mixin class $ExperimentVariantCopyWith<$Res>  {
  factory $ExperimentVariantCopyWith(ExperimentVariant value, $Res Function(ExperimentVariant) _then) = _$ExperimentVariantCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? description, int trafficPercentage, bool isControl, Map<String, dynamic> config, int assignmentCount, int conversionCount
});




}
/// @nodoc
class _$ExperimentVariantCopyWithImpl<$Res>
    implements $ExperimentVariantCopyWith<$Res> {
  _$ExperimentVariantCopyWithImpl(this._self, this._then);

  final ExperimentVariant _self;
  final $Res Function(ExperimentVariant) _then;

/// Create a copy of ExperimentVariant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? trafficPercentage = null,Object? isControl = null,Object? config = null,Object? assignmentCount = null,Object? conversionCount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,trafficPercentage: null == trafficPercentage ? _self.trafficPercentage : trafficPercentage // ignore: cast_nullable_to_non_nullable
as int,isControl: null == isControl ? _self.isControl : isControl // ignore: cast_nullable_to_non_nullable
as bool,config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,assignmentCount: null == assignmentCount ? _self.assignmentCount : assignmentCount // ignore: cast_nullable_to_non_nullable
as int,conversionCount: null == conversionCount ? _self.conversionCount : conversionCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ExperimentVariant].
extension ExperimentVariantPatterns on ExperimentVariant {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExperimentVariant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExperimentVariant() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExperimentVariant value)  $default,){
final _that = this;
switch (_that) {
case _ExperimentVariant():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExperimentVariant value)?  $default,){
final _that = this;
switch (_that) {
case _ExperimentVariant() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? description,  int trafficPercentage,  bool isControl,  Map<String, dynamic> config,  int assignmentCount,  int conversionCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExperimentVariant() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.trafficPercentage,_that.isControl,_that.config,_that.assignmentCount,_that.conversionCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? description,  int trafficPercentage,  bool isControl,  Map<String, dynamic> config,  int assignmentCount,  int conversionCount)  $default,) {final _that = this;
switch (_that) {
case _ExperimentVariant():
return $default(_that.id,_that.name,_that.description,_that.trafficPercentage,_that.isControl,_that.config,_that.assignmentCount,_that.conversionCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? description,  int trafficPercentage,  bool isControl,  Map<String, dynamic> config,  int assignmentCount,  int conversionCount)?  $default,) {final _that = this;
switch (_that) {
case _ExperimentVariant() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.trafficPercentage,_that.isControl,_that.config,_that.assignmentCount,_that.conversionCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExperimentVariant extends ExperimentVariant {
  const _ExperimentVariant({required this.id, required this.name, this.description, required this.trafficPercentage, this.isControl = false, final  Map<String, dynamic> config = const {}, this.assignmentCount = 0, this.conversionCount = 0}): _config = config,super._();
  factory _ExperimentVariant.fromJson(Map<String, dynamic> json) => _$ExperimentVariantFromJson(json);

/// Unique identifier for this variant
@override final  String id;
/// Human-readable name (e.g., "Control", "Treatment A")
@override final  String name;
/// Description of what this variant does
@override final  String? description;
/// Percentage of traffic allocated to this variant (0-100)
/// All variants in an experiment should sum to 100
@override final  int trafficPercentage;
/// Whether this is the control variant (baseline)
@override@JsonKey() final  bool isControl;
/// Variant-specific configuration
/// For model_comparison: {"model_version": "v2.0"}
/// For threshold_testing: {"high_risk_threshold": 0.5}
/// For ui_treatment: {"show_explanation": true}
/// For feature_testing: {"enable_weather": true}
 final  Map<String, dynamic> _config;
/// Variant-specific configuration
/// For model_comparison: {"model_version": "v2.0"}
/// For threshold_testing: {"high_risk_threshold": 0.5}
/// For ui_treatment: {"show_explanation": true}
/// For feature_testing: {"enable_weather": true}
@override@JsonKey() Map<String, dynamic> get config {
  if (_config is EqualUnmodifiableMapView) return _config;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_config);
}

/// Number of users assigned to this variant
@override@JsonKey() final  int assignmentCount;
/// Number of conversions (positive outcomes)
@override@JsonKey() final  int conversionCount;

/// Create a copy of ExperimentVariant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExperimentVariantCopyWith<_ExperimentVariant> get copyWith => __$ExperimentVariantCopyWithImpl<_ExperimentVariant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExperimentVariantToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExperimentVariant&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.trafficPercentage, trafficPercentage) || other.trafficPercentage == trafficPercentage)&&(identical(other.isControl, isControl) || other.isControl == isControl)&&const DeepCollectionEquality().equals(other._config, _config)&&(identical(other.assignmentCount, assignmentCount) || other.assignmentCount == assignmentCount)&&(identical(other.conversionCount, conversionCount) || other.conversionCount == conversionCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,trafficPercentage,isControl,const DeepCollectionEquality().hash(_config),assignmentCount,conversionCount);

@override
String toString() {
  return 'ExperimentVariant(id: $id, name: $name, description: $description, trafficPercentage: $trafficPercentage, isControl: $isControl, config: $config, assignmentCount: $assignmentCount, conversionCount: $conversionCount)';
}


}

/// @nodoc
abstract mixin class _$ExperimentVariantCopyWith<$Res> implements $ExperimentVariantCopyWith<$Res> {
  factory _$ExperimentVariantCopyWith(_ExperimentVariant value, $Res Function(_ExperimentVariant) _then) = __$ExperimentVariantCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? description, int trafficPercentage, bool isControl, Map<String, dynamic> config, int assignmentCount, int conversionCount
});




}
/// @nodoc
class __$ExperimentVariantCopyWithImpl<$Res>
    implements _$ExperimentVariantCopyWith<$Res> {
  __$ExperimentVariantCopyWithImpl(this._self, this._then);

  final _ExperimentVariant _self;
  final $Res Function(_ExperimentVariant) _then;

/// Create a copy of ExperimentVariant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? trafficPercentage = null,Object? isControl = null,Object? config = null,Object? assignmentCount = null,Object? conversionCount = null,}) {
  return _then(_ExperimentVariant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,trafficPercentage: null == trafficPercentage ? _self.trafficPercentage : trafficPercentage // ignore: cast_nullable_to_non_nullable
as int,isControl: null == isControl ? _self.isControl : isControl // ignore: cast_nullable_to_non_nullable
as bool,config: null == config ? _self._config : config // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,assignmentCount: null == assignmentCount ? _self.assignmentCount : assignmentCount // ignore: cast_nullable_to_non_nullable
as int,conversionCount: null == conversionCount ? _self.conversionCount : conversionCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Experiment {

/// Unique identifier for this experiment
 String get id;/// Business this experiment belongs to
 String get businessId;/// Human-readable name
 String get name;/// Detailed description of the experiment
 String? get description;/// Type of experiment
 ExperimentType get type;/// Current status
 ExperimentStatus get status;/// List of variants in this experiment
 List<ExperimentVariant> get variants;/// When the experiment was created
@TimestampConverter() DateTime get createdAt;/// User who created the experiment
 String get createdBy;/// When the experiment was last updated
@NullableTimestampConverter() DateTime? get updatedAt;/// When the experiment was activated
@NullableTimestampConverter() DateTime? get startedAt;/// When the experiment ended
@NullableTimestampConverter() DateTime? get endedAt;/// Target sample size (optional)
 int? get targetSampleSize;/// Minimum days to run before concluding
 int get minimumRunDays;/// Maximum days to run
 int get maximumRunDays;/// Key metric to measure (e.g., "prediction_accuracy", "user_satisfaction")
 String get primaryMetric;/// Additional metrics to track
 List<String> get secondaryMetrics;/// Winning variant ID (set when experiment completes)
 String? get winningVariantId;/// Statistical significance level required (default 95%)
 double get requiredConfidence;/// Tags for categorization
 List<String> get tags;
/// Create a copy of Experiment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExperimentCopyWith<Experiment> get copyWith => _$ExperimentCopyWithImpl<Experiment>(this as Experiment, _$identity);

  /// Serializes this Experiment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Experiment&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.variants, variants)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.targetSampleSize, targetSampleSize) || other.targetSampleSize == targetSampleSize)&&(identical(other.minimumRunDays, minimumRunDays) || other.minimumRunDays == minimumRunDays)&&(identical(other.maximumRunDays, maximumRunDays) || other.maximumRunDays == maximumRunDays)&&(identical(other.primaryMetric, primaryMetric) || other.primaryMetric == primaryMetric)&&const DeepCollectionEquality().equals(other.secondaryMetrics, secondaryMetrics)&&(identical(other.winningVariantId, winningVariantId) || other.winningVariantId == winningVariantId)&&(identical(other.requiredConfidence, requiredConfidence) || other.requiredConfidence == requiredConfidence)&&const DeepCollectionEquality().equals(other.tags, tags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,businessId,name,description,type,status,const DeepCollectionEquality().hash(variants),createdAt,createdBy,updatedAt,startedAt,endedAt,targetSampleSize,minimumRunDays,maximumRunDays,primaryMetric,const DeepCollectionEquality().hash(secondaryMetrics),winningVariantId,requiredConfidence,const DeepCollectionEquality().hash(tags)]);

@override
String toString() {
  return 'Experiment(id: $id, businessId: $businessId, name: $name, description: $description, type: $type, status: $status, variants: $variants, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, startedAt: $startedAt, endedAt: $endedAt, targetSampleSize: $targetSampleSize, minimumRunDays: $minimumRunDays, maximumRunDays: $maximumRunDays, primaryMetric: $primaryMetric, secondaryMetrics: $secondaryMetrics, winningVariantId: $winningVariantId, requiredConfidence: $requiredConfidence, tags: $tags)';
}


}

/// @nodoc
abstract mixin class $ExperimentCopyWith<$Res>  {
  factory $ExperimentCopyWith(Experiment value, $Res Function(Experiment) _then) = _$ExperimentCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String name, String? description, ExperimentType type, ExperimentStatus status, List<ExperimentVariant> variants,@TimestampConverter() DateTime createdAt, String createdBy,@NullableTimestampConverter() DateTime? updatedAt,@NullableTimestampConverter() DateTime? startedAt,@NullableTimestampConverter() DateTime? endedAt, int? targetSampleSize, int minimumRunDays, int maximumRunDays, String primaryMetric, List<String> secondaryMetrics, String? winningVariantId, double requiredConfidence, List<String> tags
});




}
/// @nodoc
class _$ExperimentCopyWithImpl<$Res>
    implements $ExperimentCopyWith<$Res> {
  _$ExperimentCopyWithImpl(this._self, this._then);

  final Experiment _self;
  final $Res Function(Experiment) _then;

/// Create a copy of Experiment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? name = null,Object? description = freezed,Object? type = null,Object? status = null,Object? variants = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = freezed,Object? startedAt = freezed,Object? endedAt = freezed,Object? targetSampleSize = freezed,Object? minimumRunDays = null,Object? maximumRunDays = null,Object? primaryMetric = null,Object? secondaryMetrics = null,Object? winningVariantId = freezed,Object? requiredConfidence = null,Object? tags = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ExperimentType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ExperimentStatus,variants: null == variants ? _self.variants : variants // ignore: cast_nullable_to_non_nullable
as List<ExperimentVariant>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,targetSampleSize: freezed == targetSampleSize ? _self.targetSampleSize : targetSampleSize // ignore: cast_nullable_to_non_nullable
as int?,minimumRunDays: null == minimumRunDays ? _self.minimumRunDays : minimumRunDays // ignore: cast_nullable_to_non_nullable
as int,maximumRunDays: null == maximumRunDays ? _self.maximumRunDays : maximumRunDays // ignore: cast_nullable_to_non_nullable
as int,primaryMetric: null == primaryMetric ? _self.primaryMetric : primaryMetric // ignore: cast_nullable_to_non_nullable
as String,secondaryMetrics: null == secondaryMetrics ? _self.secondaryMetrics : secondaryMetrics // ignore: cast_nullable_to_non_nullable
as List<String>,winningVariantId: freezed == winningVariantId ? _self.winningVariantId : winningVariantId // ignore: cast_nullable_to_non_nullable
as String?,requiredConfidence: null == requiredConfidence ? _self.requiredConfidence : requiredConfidence // ignore: cast_nullable_to_non_nullable
as double,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [Experiment].
extension ExperimentPatterns on Experiment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Experiment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Experiment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Experiment value)  $default,){
final _that = this;
switch (_that) {
case _Experiment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Experiment value)?  $default,){
final _that = this;
switch (_that) {
case _Experiment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String name,  String? description,  ExperimentType type,  ExperimentStatus status,  List<ExperimentVariant> variants, @TimestampConverter()  DateTime createdAt,  String createdBy, @NullableTimestampConverter()  DateTime? updatedAt, @NullableTimestampConverter()  DateTime? startedAt, @NullableTimestampConverter()  DateTime? endedAt,  int? targetSampleSize,  int minimumRunDays,  int maximumRunDays,  String primaryMetric,  List<String> secondaryMetrics,  String? winningVariantId,  double requiredConfidence,  List<String> tags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Experiment() when $default != null:
return $default(_that.id,_that.businessId,_that.name,_that.description,_that.type,_that.status,_that.variants,_that.createdAt,_that.createdBy,_that.updatedAt,_that.startedAt,_that.endedAt,_that.targetSampleSize,_that.minimumRunDays,_that.maximumRunDays,_that.primaryMetric,_that.secondaryMetrics,_that.winningVariantId,_that.requiredConfidence,_that.tags);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String name,  String? description,  ExperimentType type,  ExperimentStatus status,  List<ExperimentVariant> variants, @TimestampConverter()  DateTime createdAt,  String createdBy, @NullableTimestampConverter()  DateTime? updatedAt, @NullableTimestampConverter()  DateTime? startedAt, @NullableTimestampConverter()  DateTime? endedAt,  int? targetSampleSize,  int minimumRunDays,  int maximumRunDays,  String primaryMetric,  List<String> secondaryMetrics,  String? winningVariantId,  double requiredConfidence,  List<String> tags)  $default,) {final _that = this;
switch (_that) {
case _Experiment():
return $default(_that.id,_that.businessId,_that.name,_that.description,_that.type,_that.status,_that.variants,_that.createdAt,_that.createdBy,_that.updatedAt,_that.startedAt,_that.endedAt,_that.targetSampleSize,_that.minimumRunDays,_that.maximumRunDays,_that.primaryMetric,_that.secondaryMetrics,_that.winningVariantId,_that.requiredConfidence,_that.tags);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String name,  String? description,  ExperimentType type,  ExperimentStatus status,  List<ExperimentVariant> variants, @TimestampConverter()  DateTime createdAt,  String createdBy, @NullableTimestampConverter()  DateTime? updatedAt, @NullableTimestampConverter()  DateTime? startedAt, @NullableTimestampConverter()  DateTime? endedAt,  int? targetSampleSize,  int minimumRunDays,  int maximumRunDays,  String primaryMetric,  List<String> secondaryMetrics,  String? winningVariantId,  double requiredConfidence,  List<String> tags)?  $default,) {final _that = this;
switch (_that) {
case _Experiment() when $default != null:
return $default(_that.id,_that.businessId,_that.name,_that.description,_that.type,_that.status,_that.variants,_that.createdAt,_that.createdBy,_that.updatedAt,_that.startedAt,_that.endedAt,_that.targetSampleSize,_that.minimumRunDays,_that.maximumRunDays,_that.primaryMetric,_that.secondaryMetrics,_that.winningVariantId,_that.requiredConfidence,_that.tags);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Experiment extends Experiment {
  const _Experiment({required this.id, required this.businessId, required this.name, this.description, required this.type, this.status = ExperimentStatus.draft, required final  List<ExperimentVariant> variants, @TimestampConverter() required this.createdAt, required this.createdBy, @NullableTimestampConverter() this.updatedAt, @NullableTimestampConverter() this.startedAt, @NullableTimestampConverter() this.endedAt, this.targetSampleSize, this.minimumRunDays = 7, this.maximumRunDays = 30, this.primaryMetric = 'prediction_accuracy', final  List<String> secondaryMetrics = const [], this.winningVariantId, this.requiredConfidence = 0.95, final  List<String> tags = const []}): _variants = variants,_secondaryMetrics = secondaryMetrics,_tags = tags,super._();
  factory _Experiment.fromJson(Map<String, dynamic> json) => _$ExperimentFromJson(json);

/// Unique identifier for this experiment
@override final  String id;
/// Business this experiment belongs to
@override final  String businessId;
/// Human-readable name
@override final  String name;
/// Detailed description of the experiment
@override final  String? description;
/// Type of experiment
@override final  ExperimentType type;
/// Current status
@override@JsonKey() final  ExperimentStatus status;
/// List of variants in this experiment
 final  List<ExperimentVariant> _variants;
/// List of variants in this experiment
@override List<ExperimentVariant> get variants {
  if (_variants is EqualUnmodifiableListView) return _variants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_variants);
}

/// When the experiment was created
@override@TimestampConverter() final  DateTime createdAt;
/// User who created the experiment
@override final  String createdBy;
/// When the experiment was last updated
@override@NullableTimestampConverter() final  DateTime? updatedAt;
/// When the experiment was activated
@override@NullableTimestampConverter() final  DateTime? startedAt;
/// When the experiment ended
@override@NullableTimestampConverter() final  DateTime? endedAt;
/// Target sample size (optional)
@override final  int? targetSampleSize;
/// Minimum days to run before concluding
@override@JsonKey() final  int minimumRunDays;
/// Maximum days to run
@override@JsonKey() final  int maximumRunDays;
/// Key metric to measure (e.g., "prediction_accuracy", "user_satisfaction")
@override@JsonKey() final  String primaryMetric;
/// Additional metrics to track
 final  List<String> _secondaryMetrics;
/// Additional metrics to track
@override@JsonKey() List<String> get secondaryMetrics {
  if (_secondaryMetrics is EqualUnmodifiableListView) return _secondaryMetrics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_secondaryMetrics);
}

/// Winning variant ID (set when experiment completes)
@override final  String? winningVariantId;
/// Statistical significance level required (default 95%)
@override@JsonKey() final  double requiredConfidence;
/// Tags for categorization
 final  List<String> _tags;
/// Tags for categorization
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}


/// Create a copy of Experiment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExperimentCopyWith<_Experiment> get copyWith => __$ExperimentCopyWithImpl<_Experiment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExperimentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Experiment&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._variants, _variants)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.targetSampleSize, targetSampleSize) || other.targetSampleSize == targetSampleSize)&&(identical(other.minimumRunDays, minimumRunDays) || other.minimumRunDays == minimumRunDays)&&(identical(other.maximumRunDays, maximumRunDays) || other.maximumRunDays == maximumRunDays)&&(identical(other.primaryMetric, primaryMetric) || other.primaryMetric == primaryMetric)&&const DeepCollectionEquality().equals(other._secondaryMetrics, _secondaryMetrics)&&(identical(other.winningVariantId, winningVariantId) || other.winningVariantId == winningVariantId)&&(identical(other.requiredConfidence, requiredConfidence) || other.requiredConfidence == requiredConfidence)&&const DeepCollectionEquality().equals(other._tags, _tags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,businessId,name,description,type,status,const DeepCollectionEquality().hash(_variants),createdAt,createdBy,updatedAt,startedAt,endedAt,targetSampleSize,minimumRunDays,maximumRunDays,primaryMetric,const DeepCollectionEquality().hash(_secondaryMetrics),winningVariantId,requiredConfidence,const DeepCollectionEquality().hash(_tags)]);

@override
String toString() {
  return 'Experiment(id: $id, businessId: $businessId, name: $name, description: $description, type: $type, status: $status, variants: $variants, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, startedAt: $startedAt, endedAt: $endedAt, targetSampleSize: $targetSampleSize, minimumRunDays: $minimumRunDays, maximumRunDays: $maximumRunDays, primaryMetric: $primaryMetric, secondaryMetrics: $secondaryMetrics, winningVariantId: $winningVariantId, requiredConfidence: $requiredConfidence, tags: $tags)';
}


}

/// @nodoc
abstract mixin class _$ExperimentCopyWith<$Res> implements $ExperimentCopyWith<$Res> {
  factory _$ExperimentCopyWith(_Experiment value, $Res Function(_Experiment) _then) = __$ExperimentCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String name, String? description, ExperimentType type, ExperimentStatus status, List<ExperimentVariant> variants,@TimestampConverter() DateTime createdAt, String createdBy,@NullableTimestampConverter() DateTime? updatedAt,@NullableTimestampConverter() DateTime? startedAt,@NullableTimestampConverter() DateTime? endedAt, int? targetSampleSize, int minimumRunDays, int maximumRunDays, String primaryMetric, List<String> secondaryMetrics, String? winningVariantId, double requiredConfidence, List<String> tags
});




}
/// @nodoc
class __$ExperimentCopyWithImpl<$Res>
    implements _$ExperimentCopyWith<$Res> {
  __$ExperimentCopyWithImpl(this._self, this._then);

  final _Experiment _self;
  final $Res Function(_Experiment) _then;

/// Create a copy of Experiment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? name = null,Object? description = freezed,Object? type = null,Object? status = null,Object? variants = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = freezed,Object? startedAt = freezed,Object? endedAt = freezed,Object? targetSampleSize = freezed,Object? minimumRunDays = null,Object? maximumRunDays = null,Object? primaryMetric = null,Object? secondaryMetrics = null,Object? winningVariantId = freezed,Object? requiredConfidence = null,Object? tags = null,}) {
  return _then(_Experiment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ExperimentType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ExperimentStatus,variants: null == variants ? _self._variants : variants // ignore: cast_nullable_to_non_nullable
as List<ExperimentVariant>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,targetSampleSize: freezed == targetSampleSize ? _self.targetSampleSize : targetSampleSize // ignore: cast_nullable_to_non_nullable
as int?,minimumRunDays: null == minimumRunDays ? _self.minimumRunDays : minimumRunDays // ignore: cast_nullable_to_non_nullable
as int,maximumRunDays: null == maximumRunDays ? _self.maximumRunDays : maximumRunDays // ignore: cast_nullable_to_non_nullable
as int,primaryMetric: null == primaryMetric ? _self.primaryMetric : primaryMetric // ignore: cast_nullable_to_non_nullable
as String,secondaryMetrics: null == secondaryMetrics ? _self._secondaryMetrics : secondaryMetrics // ignore: cast_nullable_to_non_nullable
as List<String>,winningVariantId: freezed == winningVariantId ? _self.winningVariantId : winningVariantId // ignore: cast_nullable_to_non_nullable
as String?,requiredConfidence: null == requiredConfidence ? _self.requiredConfidence : requiredConfidence // ignore: cast_nullable_to_non_nullable
as double,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$ExperimentAssignment {

/// Unique identifier for this assignment
 String get id;/// Business ID
 String get businessId;/// Experiment this assignment belongs to
 String get experimentId;/// Variant the user was assigned to
 String get variantId;/// User ID (staff member)
 String get userId;/// When the assignment was made
@TimestampConverter() DateTime get assignedAt;/// Entity that the experiment applies to (e.g., appointment ID)
 String? get entityId;/// Entity type (e.g., "appointment", "client")
 String? get entityType;/// Whether the user converted (positive outcome)
 bool? get converted;/// When conversion was recorded
@NullableTimestampConverter() DateTime? get convertedAt;/// Metadata about the conversion
 Map<String, dynamic> get conversionMetadata;
/// Create a copy of ExperimentAssignment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExperimentAssignmentCopyWith<ExperimentAssignment> get copyWith => _$ExperimentAssignmentCopyWithImpl<ExperimentAssignment>(this as ExperimentAssignment, _$identity);

  /// Serializes this ExperimentAssignment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExperimentAssignment&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.experimentId, experimentId) || other.experimentId == experimentId)&&(identical(other.variantId, variantId) || other.variantId == variantId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.assignedAt, assignedAt) || other.assignedAt == assignedAt)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.converted, converted) || other.converted == converted)&&(identical(other.convertedAt, convertedAt) || other.convertedAt == convertedAt)&&const DeepCollectionEquality().equals(other.conversionMetadata, conversionMetadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,experimentId,variantId,userId,assignedAt,entityId,entityType,converted,convertedAt,const DeepCollectionEquality().hash(conversionMetadata));

@override
String toString() {
  return 'ExperimentAssignment(id: $id, businessId: $businessId, experimentId: $experimentId, variantId: $variantId, userId: $userId, assignedAt: $assignedAt, entityId: $entityId, entityType: $entityType, converted: $converted, convertedAt: $convertedAt, conversionMetadata: $conversionMetadata)';
}


}

/// @nodoc
abstract mixin class $ExperimentAssignmentCopyWith<$Res>  {
  factory $ExperimentAssignmentCopyWith(ExperimentAssignment value, $Res Function(ExperimentAssignment) _then) = _$ExperimentAssignmentCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String experimentId, String variantId, String userId,@TimestampConverter() DateTime assignedAt, String? entityId, String? entityType, bool? converted,@NullableTimestampConverter() DateTime? convertedAt, Map<String, dynamic> conversionMetadata
});




}
/// @nodoc
class _$ExperimentAssignmentCopyWithImpl<$Res>
    implements $ExperimentAssignmentCopyWith<$Res> {
  _$ExperimentAssignmentCopyWithImpl(this._self, this._then);

  final ExperimentAssignment _self;
  final $Res Function(ExperimentAssignment) _then;

/// Create a copy of ExperimentAssignment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? experimentId = null,Object? variantId = null,Object? userId = null,Object? assignedAt = null,Object? entityId = freezed,Object? entityType = freezed,Object? converted = freezed,Object? convertedAt = freezed,Object? conversionMetadata = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,experimentId: null == experimentId ? _self.experimentId : experimentId // ignore: cast_nullable_to_non_nullable
as String,variantId: null == variantId ? _self.variantId : variantId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,assignedAt: null == assignedAt ? _self.assignedAt : assignedAt // ignore: cast_nullable_to_non_nullable
as DateTime,entityId: freezed == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String?,entityType: freezed == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as String?,converted: freezed == converted ? _self.converted : converted // ignore: cast_nullable_to_non_nullable
as bool?,convertedAt: freezed == convertedAt ? _self.convertedAt : convertedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,conversionMetadata: null == conversionMetadata ? _self.conversionMetadata : conversionMetadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [ExperimentAssignment].
extension ExperimentAssignmentPatterns on ExperimentAssignment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExperimentAssignment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExperimentAssignment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExperimentAssignment value)  $default,){
final _that = this;
switch (_that) {
case _ExperimentAssignment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExperimentAssignment value)?  $default,){
final _that = this;
switch (_that) {
case _ExperimentAssignment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String experimentId,  String variantId,  String userId, @TimestampConverter()  DateTime assignedAt,  String? entityId,  String? entityType,  bool? converted, @NullableTimestampConverter()  DateTime? convertedAt,  Map<String, dynamic> conversionMetadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExperimentAssignment() when $default != null:
return $default(_that.id,_that.businessId,_that.experimentId,_that.variantId,_that.userId,_that.assignedAt,_that.entityId,_that.entityType,_that.converted,_that.convertedAt,_that.conversionMetadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String experimentId,  String variantId,  String userId, @TimestampConverter()  DateTime assignedAt,  String? entityId,  String? entityType,  bool? converted, @NullableTimestampConverter()  DateTime? convertedAt,  Map<String, dynamic> conversionMetadata)  $default,) {final _that = this;
switch (_that) {
case _ExperimentAssignment():
return $default(_that.id,_that.businessId,_that.experimentId,_that.variantId,_that.userId,_that.assignedAt,_that.entityId,_that.entityType,_that.converted,_that.convertedAt,_that.conversionMetadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String experimentId,  String variantId,  String userId, @TimestampConverter()  DateTime assignedAt,  String? entityId,  String? entityType,  bool? converted, @NullableTimestampConverter()  DateTime? convertedAt,  Map<String, dynamic> conversionMetadata)?  $default,) {final _that = this;
switch (_that) {
case _ExperimentAssignment() when $default != null:
return $default(_that.id,_that.businessId,_that.experimentId,_that.variantId,_that.userId,_that.assignedAt,_that.entityId,_that.entityType,_that.converted,_that.convertedAt,_that.conversionMetadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExperimentAssignment extends ExperimentAssignment {
  const _ExperimentAssignment({required this.id, required this.businessId, required this.experimentId, required this.variantId, required this.userId, @TimestampConverter() required this.assignedAt, this.entityId, this.entityType, this.converted, @NullableTimestampConverter() this.convertedAt, final  Map<String, dynamic> conversionMetadata = const {}}): _conversionMetadata = conversionMetadata,super._();
  factory _ExperimentAssignment.fromJson(Map<String, dynamic> json) => _$ExperimentAssignmentFromJson(json);

/// Unique identifier for this assignment
@override final  String id;
/// Business ID
@override final  String businessId;
/// Experiment this assignment belongs to
@override final  String experimentId;
/// Variant the user was assigned to
@override final  String variantId;
/// User ID (staff member)
@override final  String userId;
/// When the assignment was made
@override@TimestampConverter() final  DateTime assignedAt;
/// Entity that the experiment applies to (e.g., appointment ID)
@override final  String? entityId;
/// Entity type (e.g., "appointment", "client")
@override final  String? entityType;
/// Whether the user converted (positive outcome)
@override final  bool? converted;
/// When conversion was recorded
@override@NullableTimestampConverter() final  DateTime? convertedAt;
/// Metadata about the conversion
 final  Map<String, dynamic> _conversionMetadata;
/// Metadata about the conversion
@override@JsonKey() Map<String, dynamic> get conversionMetadata {
  if (_conversionMetadata is EqualUnmodifiableMapView) return _conversionMetadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_conversionMetadata);
}


/// Create a copy of ExperimentAssignment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExperimentAssignmentCopyWith<_ExperimentAssignment> get copyWith => __$ExperimentAssignmentCopyWithImpl<_ExperimentAssignment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExperimentAssignmentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExperimentAssignment&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.experimentId, experimentId) || other.experimentId == experimentId)&&(identical(other.variantId, variantId) || other.variantId == variantId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.assignedAt, assignedAt) || other.assignedAt == assignedAt)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.converted, converted) || other.converted == converted)&&(identical(other.convertedAt, convertedAt) || other.convertedAt == convertedAt)&&const DeepCollectionEquality().equals(other._conversionMetadata, _conversionMetadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,businessId,experimentId,variantId,userId,assignedAt,entityId,entityType,converted,convertedAt,const DeepCollectionEquality().hash(_conversionMetadata));

@override
String toString() {
  return 'ExperimentAssignment(id: $id, businessId: $businessId, experimentId: $experimentId, variantId: $variantId, userId: $userId, assignedAt: $assignedAt, entityId: $entityId, entityType: $entityType, converted: $converted, convertedAt: $convertedAt, conversionMetadata: $conversionMetadata)';
}


}

/// @nodoc
abstract mixin class _$ExperimentAssignmentCopyWith<$Res> implements $ExperimentAssignmentCopyWith<$Res> {
  factory _$ExperimentAssignmentCopyWith(_ExperimentAssignment value, $Res Function(_ExperimentAssignment) _then) = __$ExperimentAssignmentCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String experimentId, String variantId, String userId,@TimestampConverter() DateTime assignedAt, String? entityId, String? entityType, bool? converted,@NullableTimestampConverter() DateTime? convertedAt, Map<String, dynamic> conversionMetadata
});




}
/// @nodoc
class __$ExperimentAssignmentCopyWithImpl<$Res>
    implements _$ExperimentAssignmentCopyWith<$Res> {
  __$ExperimentAssignmentCopyWithImpl(this._self, this._then);

  final _ExperimentAssignment _self;
  final $Res Function(_ExperimentAssignment) _then;

/// Create a copy of ExperimentAssignment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? experimentId = null,Object? variantId = null,Object? userId = null,Object? assignedAt = null,Object? entityId = freezed,Object? entityType = freezed,Object? converted = freezed,Object? convertedAt = freezed,Object? conversionMetadata = null,}) {
  return _then(_ExperimentAssignment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,experimentId: null == experimentId ? _self.experimentId : experimentId // ignore: cast_nullable_to_non_nullable
as String,variantId: null == variantId ? _self.variantId : variantId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,assignedAt: null == assignedAt ? _self.assignedAt : assignedAt // ignore: cast_nullable_to_non_nullable
as DateTime,entityId: freezed == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String?,entityType: freezed == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as String?,converted: freezed == converted ? _self.converted : converted // ignore: cast_nullable_to_non_nullable
as bool?,convertedAt: freezed == convertedAt ? _self.convertedAt : convertedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,conversionMetadata: null == conversionMetadata ? _self._conversionMetadata : conversionMetadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
