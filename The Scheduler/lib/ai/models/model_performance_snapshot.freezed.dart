// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'model_performance_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ModelPerformanceSnapshot {

/// Unique identifier for this snapshot
 String get id;/// Business this snapshot belongs to
 String get businessId;/// Model version being evaluated
 String get modelVersion;/// Start of the evaluation period
 DateTime get periodStart;/// End of the evaluation period
 DateTime get periodEnd;/// When this snapshot was created
 DateTime get createdAt;/// Number of predictions evaluated
 int get sampleSize;/// AUC-ROC score (0.0-1.0, higher is better)
/// Area Under the Receiver Operating Characteristic curve
 double get aucRoc;/// Precision at 0.5 threshold
 double get precisionAt50;/// Recall at 0.5 threshold
 double get recallAt50;/// F1 score at 0.5 threshold
 double get f1At50;/// Brier score (0.0-1.0, lower is better)
/// Measures calibration of probability predictions
 double get brierScore;/// Expected Calibration Error (0.0-1.0, lower is better)
 double get calibrationError;/// Log loss (lower is better)
 double? get logLoss;/// Overall performance status
 PerformanceStatus get status;/// Type of drift detected
 DriftType get driftType;/// Drift score (standard deviations from baseline)
 double get driftScore;/// Features showing significant drift
 List<String> get driftedFeatures;/// Baseline metrics for comparison (from initial training)
 ModelBaselineMetrics? get baseline;/// Whether retraining was triggered based on this snapshot
 bool get retrainingTriggered;/// Notes or alerts generated for this snapshot
 List<String> get alerts;
/// Create a copy of ModelPerformanceSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelPerformanceSnapshotCopyWith<ModelPerformanceSnapshot> get copyWith => _$ModelPerformanceSnapshotCopyWithImpl<ModelPerformanceSnapshot>(this as ModelPerformanceSnapshot, _$identity);

  /// Serializes this ModelPerformanceSnapshot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelPerformanceSnapshot&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.modelVersion, modelVersion) || other.modelVersion == modelVersion)&&(identical(other.periodStart, periodStart) || other.periodStart == periodStart)&&(identical(other.periodEnd, periodEnd) || other.periodEnd == periodEnd)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.sampleSize, sampleSize) || other.sampleSize == sampleSize)&&(identical(other.aucRoc, aucRoc) || other.aucRoc == aucRoc)&&(identical(other.precisionAt50, precisionAt50) || other.precisionAt50 == precisionAt50)&&(identical(other.recallAt50, recallAt50) || other.recallAt50 == recallAt50)&&(identical(other.f1At50, f1At50) || other.f1At50 == f1At50)&&(identical(other.brierScore, brierScore) || other.brierScore == brierScore)&&(identical(other.calibrationError, calibrationError) || other.calibrationError == calibrationError)&&(identical(other.logLoss, logLoss) || other.logLoss == logLoss)&&(identical(other.status, status) || other.status == status)&&(identical(other.driftType, driftType) || other.driftType == driftType)&&(identical(other.driftScore, driftScore) || other.driftScore == driftScore)&&const DeepCollectionEquality().equals(other.driftedFeatures, driftedFeatures)&&(identical(other.baseline, baseline) || other.baseline == baseline)&&(identical(other.retrainingTriggered, retrainingTriggered) || other.retrainingTriggered == retrainingTriggered)&&const DeepCollectionEquality().equals(other.alerts, alerts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,businessId,modelVersion,periodStart,periodEnd,createdAt,sampleSize,aucRoc,precisionAt50,recallAt50,f1At50,brierScore,calibrationError,logLoss,status,driftType,driftScore,const DeepCollectionEquality().hash(driftedFeatures),baseline,retrainingTriggered,const DeepCollectionEquality().hash(alerts)]);

@override
String toString() {
  return 'ModelPerformanceSnapshot(id: $id, businessId: $businessId, modelVersion: $modelVersion, periodStart: $periodStart, periodEnd: $periodEnd, createdAt: $createdAt, sampleSize: $sampleSize, aucRoc: $aucRoc, precisionAt50: $precisionAt50, recallAt50: $recallAt50, f1At50: $f1At50, brierScore: $brierScore, calibrationError: $calibrationError, logLoss: $logLoss, status: $status, driftType: $driftType, driftScore: $driftScore, driftedFeatures: $driftedFeatures, baseline: $baseline, retrainingTriggered: $retrainingTriggered, alerts: $alerts)';
}


}

/// @nodoc
abstract mixin class $ModelPerformanceSnapshotCopyWith<$Res>  {
  factory $ModelPerformanceSnapshotCopyWith(ModelPerformanceSnapshot value, $Res Function(ModelPerformanceSnapshot) _then) = _$ModelPerformanceSnapshotCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String modelVersion, DateTime periodStart, DateTime periodEnd, DateTime createdAt, int sampleSize, double aucRoc, double precisionAt50, double recallAt50, double f1At50, double brierScore, double calibrationError, double? logLoss, PerformanceStatus status, DriftType driftType, double driftScore, List<String> driftedFeatures, ModelBaselineMetrics? baseline, bool retrainingTriggered, List<String> alerts
});


$ModelBaselineMetricsCopyWith<$Res>? get baseline;

}
/// @nodoc
class _$ModelPerformanceSnapshotCopyWithImpl<$Res>
    implements $ModelPerformanceSnapshotCopyWith<$Res> {
  _$ModelPerformanceSnapshotCopyWithImpl(this._self, this._then);

  final ModelPerformanceSnapshot _self;
  final $Res Function(ModelPerformanceSnapshot) _then;

/// Create a copy of ModelPerformanceSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? modelVersion = null,Object? periodStart = null,Object? periodEnd = null,Object? createdAt = null,Object? sampleSize = null,Object? aucRoc = null,Object? precisionAt50 = null,Object? recallAt50 = null,Object? f1At50 = null,Object? brierScore = null,Object? calibrationError = null,Object? logLoss = freezed,Object? status = null,Object? driftType = null,Object? driftScore = null,Object? driftedFeatures = null,Object? baseline = freezed,Object? retrainingTriggered = null,Object? alerts = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,modelVersion: null == modelVersion ? _self.modelVersion : modelVersion // ignore: cast_nullable_to_non_nullable
as String,periodStart: null == periodStart ? _self.periodStart : periodStart // ignore: cast_nullable_to_non_nullable
as DateTime,periodEnd: null == periodEnd ? _self.periodEnd : periodEnd // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,sampleSize: null == sampleSize ? _self.sampleSize : sampleSize // ignore: cast_nullable_to_non_nullable
as int,aucRoc: null == aucRoc ? _self.aucRoc : aucRoc // ignore: cast_nullable_to_non_nullable
as double,precisionAt50: null == precisionAt50 ? _self.precisionAt50 : precisionAt50 // ignore: cast_nullable_to_non_nullable
as double,recallAt50: null == recallAt50 ? _self.recallAt50 : recallAt50 // ignore: cast_nullable_to_non_nullable
as double,f1At50: null == f1At50 ? _self.f1At50 : f1At50 // ignore: cast_nullable_to_non_nullable
as double,brierScore: null == brierScore ? _self.brierScore : brierScore // ignore: cast_nullable_to_non_nullable
as double,calibrationError: null == calibrationError ? _self.calibrationError : calibrationError // ignore: cast_nullable_to_non_nullable
as double,logLoss: freezed == logLoss ? _self.logLoss : logLoss // ignore: cast_nullable_to_non_nullable
as double?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PerformanceStatus,driftType: null == driftType ? _self.driftType : driftType // ignore: cast_nullable_to_non_nullable
as DriftType,driftScore: null == driftScore ? _self.driftScore : driftScore // ignore: cast_nullable_to_non_nullable
as double,driftedFeatures: null == driftedFeatures ? _self.driftedFeatures : driftedFeatures // ignore: cast_nullable_to_non_nullable
as List<String>,baseline: freezed == baseline ? _self.baseline : baseline // ignore: cast_nullable_to_non_nullable
as ModelBaselineMetrics?,retrainingTriggered: null == retrainingTriggered ? _self.retrainingTriggered : retrainingTriggered // ignore: cast_nullable_to_non_nullable
as bool,alerts: null == alerts ? _self.alerts : alerts // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of ModelPerformanceSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModelBaselineMetricsCopyWith<$Res>? get baseline {
    if (_self.baseline == null) {
    return null;
  }

  return $ModelBaselineMetricsCopyWith<$Res>(_self.baseline!, (value) {
    return _then(_self.copyWith(baseline: value));
  });
}
}


/// Adds pattern-matching-related methods to [ModelPerformanceSnapshot].
extension ModelPerformanceSnapshotPatterns on ModelPerformanceSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModelPerformanceSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModelPerformanceSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModelPerformanceSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _ModelPerformanceSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModelPerformanceSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _ModelPerformanceSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String modelVersion,  DateTime periodStart,  DateTime periodEnd,  DateTime createdAt,  int sampleSize,  double aucRoc,  double precisionAt50,  double recallAt50,  double f1At50,  double brierScore,  double calibrationError,  double? logLoss,  PerformanceStatus status,  DriftType driftType,  double driftScore,  List<String> driftedFeatures,  ModelBaselineMetrics? baseline,  bool retrainingTriggered,  List<String> alerts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModelPerformanceSnapshot() when $default != null:
return $default(_that.id,_that.businessId,_that.modelVersion,_that.periodStart,_that.periodEnd,_that.createdAt,_that.sampleSize,_that.aucRoc,_that.precisionAt50,_that.recallAt50,_that.f1At50,_that.brierScore,_that.calibrationError,_that.logLoss,_that.status,_that.driftType,_that.driftScore,_that.driftedFeatures,_that.baseline,_that.retrainingTriggered,_that.alerts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String modelVersion,  DateTime periodStart,  DateTime periodEnd,  DateTime createdAt,  int sampleSize,  double aucRoc,  double precisionAt50,  double recallAt50,  double f1At50,  double brierScore,  double calibrationError,  double? logLoss,  PerformanceStatus status,  DriftType driftType,  double driftScore,  List<String> driftedFeatures,  ModelBaselineMetrics? baseline,  bool retrainingTriggered,  List<String> alerts)  $default,) {final _that = this;
switch (_that) {
case _ModelPerformanceSnapshot():
return $default(_that.id,_that.businessId,_that.modelVersion,_that.periodStart,_that.periodEnd,_that.createdAt,_that.sampleSize,_that.aucRoc,_that.precisionAt50,_that.recallAt50,_that.f1At50,_that.brierScore,_that.calibrationError,_that.logLoss,_that.status,_that.driftType,_that.driftScore,_that.driftedFeatures,_that.baseline,_that.retrainingTriggered,_that.alerts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String modelVersion,  DateTime periodStart,  DateTime periodEnd,  DateTime createdAt,  int sampleSize,  double aucRoc,  double precisionAt50,  double recallAt50,  double f1At50,  double brierScore,  double calibrationError,  double? logLoss,  PerformanceStatus status,  DriftType driftType,  double driftScore,  List<String> driftedFeatures,  ModelBaselineMetrics? baseline,  bool retrainingTriggered,  List<String> alerts)?  $default,) {final _that = this;
switch (_that) {
case _ModelPerformanceSnapshot() when $default != null:
return $default(_that.id,_that.businessId,_that.modelVersion,_that.periodStart,_that.periodEnd,_that.createdAt,_that.sampleSize,_that.aucRoc,_that.precisionAt50,_that.recallAt50,_that.f1At50,_that.brierScore,_that.calibrationError,_that.logLoss,_that.status,_that.driftType,_that.driftScore,_that.driftedFeatures,_that.baseline,_that.retrainingTriggered,_that.alerts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModelPerformanceSnapshot extends ModelPerformanceSnapshot {
  const _ModelPerformanceSnapshot({required this.id, required this.businessId, required this.modelVersion, required this.periodStart, required this.periodEnd, required this.createdAt, required this.sampleSize, required this.aucRoc, required this.precisionAt50, required this.recallAt50, required this.f1At50, required this.brierScore, required this.calibrationError, this.logLoss, required this.status, this.driftType = DriftType.none, this.driftScore = 0.0, final  List<String> driftedFeatures = const [], this.baseline, this.retrainingTriggered = false, final  List<String> alerts = const []}): _driftedFeatures = driftedFeatures,_alerts = alerts,super._();
  factory _ModelPerformanceSnapshot.fromJson(Map<String, dynamic> json) => _$ModelPerformanceSnapshotFromJson(json);

/// Unique identifier for this snapshot
@override final  String id;
/// Business this snapshot belongs to
@override final  String businessId;
/// Model version being evaluated
@override final  String modelVersion;
/// Start of the evaluation period
@override final  DateTime periodStart;
/// End of the evaluation period
@override final  DateTime periodEnd;
/// When this snapshot was created
@override final  DateTime createdAt;
/// Number of predictions evaluated
@override final  int sampleSize;
/// AUC-ROC score (0.0-1.0, higher is better)
/// Area Under the Receiver Operating Characteristic curve
@override final  double aucRoc;
/// Precision at 0.5 threshold
@override final  double precisionAt50;
/// Recall at 0.5 threshold
@override final  double recallAt50;
/// F1 score at 0.5 threshold
@override final  double f1At50;
/// Brier score (0.0-1.0, lower is better)
/// Measures calibration of probability predictions
@override final  double brierScore;
/// Expected Calibration Error (0.0-1.0, lower is better)
@override final  double calibrationError;
/// Log loss (lower is better)
@override final  double? logLoss;
/// Overall performance status
@override final  PerformanceStatus status;
/// Type of drift detected
@override@JsonKey() final  DriftType driftType;
/// Drift score (standard deviations from baseline)
@override@JsonKey() final  double driftScore;
/// Features showing significant drift
 final  List<String> _driftedFeatures;
/// Features showing significant drift
@override@JsonKey() List<String> get driftedFeatures {
  if (_driftedFeatures is EqualUnmodifiableListView) return _driftedFeatures;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_driftedFeatures);
}

/// Baseline metrics for comparison (from initial training)
@override final  ModelBaselineMetrics? baseline;
/// Whether retraining was triggered based on this snapshot
@override@JsonKey() final  bool retrainingTriggered;
/// Notes or alerts generated for this snapshot
 final  List<String> _alerts;
/// Notes or alerts generated for this snapshot
@override@JsonKey() List<String> get alerts {
  if (_alerts is EqualUnmodifiableListView) return _alerts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_alerts);
}


/// Create a copy of ModelPerformanceSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModelPerformanceSnapshotCopyWith<_ModelPerformanceSnapshot> get copyWith => __$ModelPerformanceSnapshotCopyWithImpl<_ModelPerformanceSnapshot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModelPerformanceSnapshotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModelPerformanceSnapshot&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.modelVersion, modelVersion) || other.modelVersion == modelVersion)&&(identical(other.periodStart, periodStart) || other.periodStart == periodStart)&&(identical(other.periodEnd, periodEnd) || other.periodEnd == periodEnd)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.sampleSize, sampleSize) || other.sampleSize == sampleSize)&&(identical(other.aucRoc, aucRoc) || other.aucRoc == aucRoc)&&(identical(other.precisionAt50, precisionAt50) || other.precisionAt50 == precisionAt50)&&(identical(other.recallAt50, recallAt50) || other.recallAt50 == recallAt50)&&(identical(other.f1At50, f1At50) || other.f1At50 == f1At50)&&(identical(other.brierScore, brierScore) || other.brierScore == brierScore)&&(identical(other.calibrationError, calibrationError) || other.calibrationError == calibrationError)&&(identical(other.logLoss, logLoss) || other.logLoss == logLoss)&&(identical(other.status, status) || other.status == status)&&(identical(other.driftType, driftType) || other.driftType == driftType)&&(identical(other.driftScore, driftScore) || other.driftScore == driftScore)&&const DeepCollectionEquality().equals(other._driftedFeatures, _driftedFeatures)&&(identical(other.baseline, baseline) || other.baseline == baseline)&&(identical(other.retrainingTriggered, retrainingTriggered) || other.retrainingTriggered == retrainingTriggered)&&const DeepCollectionEquality().equals(other._alerts, _alerts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,businessId,modelVersion,periodStart,periodEnd,createdAt,sampleSize,aucRoc,precisionAt50,recallAt50,f1At50,brierScore,calibrationError,logLoss,status,driftType,driftScore,const DeepCollectionEquality().hash(_driftedFeatures),baseline,retrainingTriggered,const DeepCollectionEquality().hash(_alerts)]);

@override
String toString() {
  return 'ModelPerformanceSnapshot(id: $id, businessId: $businessId, modelVersion: $modelVersion, periodStart: $periodStart, periodEnd: $periodEnd, createdAt: $createdAt, sampleSize: $sampleSize, aucRoc: $aucRoc, precisionAt50: $precisionAt50, recallAt50: $recallAt50, f1At50: $f1At50, brierScore: $brierScore, calibrationError: $calibrationError, logLoss: $logLoss, status: $status, driftType: $driftType, driftScore: $driftScore, driftedFeatures: $driftedFeatures, baseline: $baseline, retrainingTriggered: $retrainingTriggered, alerts: $alerts)';
}


}

/// @nodoc
abstract mixin class _$ModelPerformanceSnapshotCopyWith<$Res> implements $ModelPerformanceSnapshotCopyWith<$Res> {
  factory _$ModelPerformanceSnapshotCopyWith(_ModelPerformanceSnapshot value, $Res Function(_ModelPerformanceSnapshot) _then) = __$ModelPerformanceSnapshotCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String modelVersion, DateTime periodStart, DateTime periodEnd, DateTime createdAt, int sampleSize, double aucRoc, double precisionAt50, double recallAt50, double f1At50, double brierScore, double calibrationError, double? logLoss, PerformanceStatus status, DriftType driftType, double driftScore, List<String> driftedFeatures, ModelBaselineMetrics? baseline, bool retrainingTriggered, List<String> alerts
});


@override $ModelBaselineMetricsCopyWith<$Res>? get baseline;

}
/// @nodoc
class __$ModelPerformanceSnapshotCopyWithImpl<$Res>
    implements _$ModelPerformanceSnapshotCopyWith<$Res> {
  __$ModelPerformanceSnapshotCopyWithImpl(this._self, this._then);

  final _ModelPerformanceSnapshot _self;
  final $Res Function(_ModelPerformanceSnapshot) _then;

/// Create a copy of ModelPerformanceSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? modelVersion = null,Object? periodStart = null,Object? periodEnd = null,Object? createdAt = null,Object? sampleSize = null,Object? aucRoc = null,Object? precisionAt50 = null,Object? recallAt50 = null,Object? f1At50 = null,Object? brierScore = null,Object? calibrationError = null,Object? logLoss = freezed,Object? status = null,Object? driftType = null,Object? driftScore = null,Object? driftedFeatures = null,Object? baseline = freezed,Object? retrainingTriggered = null,Object? alerts = null,}) {
  return _then(_ModelPerformanceSnapshot(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,modelVersion: null == modelVersion ? _self.modelVersion : modelVersion // ignore: cast_nullable_to_non_nullable
as String,periodStart: null == periodStart ? _self.periodStart : periodStart // ignore: cast_nullable_to_non_nullable
as DateTime,periodEnd: null == periodEnd ? _self.periodEnd : periodEnd // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,sampleSize: null == sampleSize ? _self.sampleSize : sampleSize // ignore: cast_nullable_to_non_nullable
as int,aucRoc: null == aucRoc ? _self.aucRoc : aucRoc // ignore: cast_nullable_to_non_nullable
as double,precisionAt50: null == precisionAt50 ? _self.precisionAt50 : precisionAt50 // ignore: cast_nullable_to_non_nullable
as double,recallAt50: null == recallAt50 ? _self.recallAt50 : recallAt50 // ignore: cast_nullable_to_non_nullable
as double,f1At50: null == f1At50 ? _self.f1At50 : f1At50 // ignore: cast_nullable_to_non_nullable
as double,brierScore: null == brierScore ? _self.brierScore : brierScore // ignore: cast_nullable_to_non_nullable
as double,calibrationError: null == calibrationError ? _self.calibrationError : calibrationError // ignore: cast_nullable_to_non_nullable
as double,logLoss: freezed == logLoss ? _self.logLoss : logLoss // ignore: cast_nullable_to_non_nullable
as double?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PerformanceStatus,driftType: null == driftType ? _self.driftType : driftType // ignore: cast_nullable_to_non_nullable
as DriftType,driftScore: null == driftScore ? _self.driftScore : driftScore // ignore: cast_nullable_to_non_nullable
as double,driftedFeatures: null == driftedFeatures ? _self._driftedFeatures : driftedFeatures // ignore: cast_nullable_to_non_nullable
as List<String>,baseline: freezed == baseline ? _self.baseline : baseline // ignore: cast_nullable_to_non_nullable
as ModelBaselineMetrics?,retrainingTriggered: null == retrainingTriggered ? _self.retrainingTriggered : retrainingTriggered // ignore: cast_nullable_to_non_nullable
as bool,alerts: null == alerts ? _self._alerts : alerts // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of ModelPerformanceSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModelBaselineMetricsCopyWith<$Res>? get baseline {
    if (_self.baseline == null) {
    return null;
  }

  return $ModelBaselineMetricsCopyWith<$Res>(_self.baseline!, (value) {
    return _then(_self.copyWith(baseline: value));
  });
}
}


/// @nodoc
mixin _$ModelBaselineMetrics {

/// Model version
 String get modelVersion;/// When baseline was established
 DateTime get establishedAt;/// Baseline AUC-ROC
 double get aucRoc;/// Baseline precision
 double get precision;/// Baseline recall
 double get recall;/// Baseline F1 score
 double get f1;/// Baseline Brier score
 double get brierScore;/// Baseline calibration error
 double get calibrationError;/// Training sample size
 int get trainingSampleSize;/// Feature importance rankings at training time
 Map<String, double> get featureImportances;/// Feature distribution statistics at training time
 Map<String, FeatureStats> get featureStats;
/// Create a copy of ModelBaselineMetrics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelBaselineMetricsCopyWith<ModelBaselineMetrics> get copyWith => _$ModelBaselineMetricsCopyWithImpl<ModelBaselineMetrics>(this as ModelBaselineMetrics, _$identity);

  /// Serializes this ModelBaselineMetrics to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelBaselineMetrics&&(identical(other.modelVersion, modelVersion) || other.modelVersion == modelVersion)&&(identical(other.establishedAt, establishedAt) || other.establishedAt == establishedAt)&&(identical(other.aucRoc, aucRoc) || other.aucRoc == aucRoc)&&(identical(other.precision, precision) || other.precision == precision)&&(identical(other.recall, recall) || other.recall == recall)&&(identical(other.f1, f1) || other.f1 == f1)&&(identical(other.brierScore, brierScore) || other.brierScore == brierScore)&&(identical(other.calibrationError, calibrationError) || other.calibrationError == calibrationError)&&(identical(other.trainingSampleSize, trainingSampleSize) || other.trainingSampleSize == trainingSampleSize)&&const DeepCollectionEquality().equals(other.featureImportances, featureImportances)&&const DeepCollectionEquality().equals(other.featureStats, featureStats));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,modelVersion,establishedAt,aucRoc,precision,recall,f1,brierScore,calibrationError,trainingSampleSize,const DeepCollectionEquality().hash(featureImportances),const DeepCollectionEquality().hash(featureStats));

@override
String toString() {
  return 'ModelBaselineMetrics(modelVersion: $modelVersion, establishedAt: $establishedAt, aucRoc: $aucRoc, precision: $precision, recall: $recall, f1: $f1, brierScore: $brierScore, calibrationError: $calibrationError, trainingSampleSize: $trainingSampleSize, featureImportances: $featureImportances, featureStats: $featureStats)';
}


}

/// @nodoc
abstract mixin class $ModelBaselineMetricsCopyWith<$Res>  {
  factory $ModelBaselineMetricsCopyWith(ModelBaselineMetrics value, $Res Function(ModelBaselineMetrics) _then) = _$ModelBaselineMetricsCopyWithImpl;
@useResult
$Res call({
 String modelVersion, DateTime establishedAt, double aucRoc, double precision, double recall, double f1, double brierScore, double calibrationError, int trainingSampleSize, Map<String, double> featureImportances, Map<String, FeatureStats> featureStats
});




}
/// @nodoc
class _$ModelBaselineMetricsCopyWithImpl<$Res>
    implements $ModelBaselineMetricsCopyWith<$Res> {
  _$ModelBaselineMetricsCopyWithImpl(this._self, this._then);

  final ModelBaselineMetrics _self;
  final $Res Function(ModelBaselineMetrics) _then;

/// Create a copy of ModelBaselineMetrics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? modelVersion = null,Object? establishedAt = null,Object? aucRoc = null,Object? precision = null,Object? recall = null,Object? f1 = null,Object? brierScore = null,Object? calibrationError = null,Object? trainingSampleSize = null,Object? featureImportances = null,Object? featureStats = null,}) {
  return _then(_self.copyWith(
modelVersion: null == modelVersion ? _self.modelVersion : modelVersion // ignore: cast_nullable_to_non_nullable
as String,establishedAt: null == establishedAt ? _self.establishedAt : establishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,aucRoc: null == aucRoc ? _self.aucRoc : aucRoc // ignore: cast_nullable_to_non_nullable
as double,precision: null == precision ? _self.precision : precision // ignore: cast_nullable_to_non_nullable
as double,recall: null == recall ? _self.recall : recall // ignore: cast_nullable_to_non_nullable
as double,f1: null == f1 ? _self.f1 : f1 // ignore: cast_nullable_to_non_nullable
as double,brierScore: null == brierScore ? _self.brierScore : brierScore // ignore: cast_nullable_to_non_nullable
as double,calibrationError: null == calibrationError ? _self.calibrationError : calibrationError // ignore: cast_nullable_to_non_nullable
as double,trainingSampleSize: null == trainingSampleSize ? _self.trainingSampleSize : trainingSampleSize // ignore: cast_nullable_to_non_nullable
as int,featureImportances: null == featureImportances ? _self.featureImportances : featureImportances // ignore: cast_nullable_to_non_nullable
as Map<String, double>,featureStats: null == featureStats ? _self.featureStats : featureStats // ignore: cast_nullable_to_non_nullable
as Map<String, FeatureStats>,
  ));
}

}


/// Adds pattern-matching-related methods to [ModelBaselineMetrics].
extension ModelBaselineMetricsPatterns on ModelBaselineMetrics {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModelBaselineMetrics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModelBaselineMetrics() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModelBaselineMetrics value)  $default,){
final _that = this;
switch (_that) {
case _ModelBaselineMetrics():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModelBaselineMetrics value)?  $default,){
final _that = this;
switch (_that) {
case _ModelBaselineMetrics() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String modelVersion,  DateTime establishedAt,  double aucRoc,  double precision,  double recall,  double f1,  double brierScore,  double calibrationError,  int trainingSampleSize,  Map<String, double> featureImportances,  Map<String, FeatureStats> featureStats)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModelBaselineMetrics() when $default != null:
return $default(_that.modelVersion,_that.establishedAt,_that.aucRoc,_that.precision,_that.recall,_that.f1,_that.brierScore,_that.calibrationError,_that.trainingSampleSize,_that.featureImportances,_that.featureStats);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String modelVersion,  DateTime establishedAt,  double aucRoc,  double precision,  double recall,  double f1,  double brierScore,  double calibrationError,  int trainingSampleSize,  Map<String, double> featureImportances,  Map<String, FeatureStats> featureStats)  $default,) {final _that = this;
switch (_that) {
case _ModelBaselineMetrics():
return $default(_that.modelVersion,_that.establishedAt,_that.aucRoc,_that.precision,_that.recall,_that.f1,_that.brierScore,_that.calibrationError,_that.trainingSampleSize,_that.featureImportances,_that.featureStats);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String modelVersion,  DateTime establishedAt,  double aucRoc,  double precision,  double recall,  double f1,  double brierScore,  double calibrationError,  int trainingSampleSize,  Map<String, double> featureImportances,  Map<String, FeatureStats> featureStats)?  $default,) {final _that = this;
switch (_that) {
case _ModelBaselineMetrics() when $default != null:
return $default(_that.modelVersion,_that.establishedAt,_that.aucRoc,_that.precision,_that.recall,_that.f1,_that.brierScore,_that.calibrationError,_that.trainingSampleSize,_that.featureImportances,_that.featureStats);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModelBaselineMetrics extends ModelBaselineMetrics {
  const _ModelBaselineMetrics({required this.modelVersion, required this.establishedAt, required this.aucRoc, required this.precision, required this.recall, required this.f1, required this.brierScore, required this.calibrationError, required this.trainingSampleSize, final  Map<String, double> featureImportances = const {}, final  Map<String, FeatureStats> featureStats = const {}}): _featureImportances = featureImportances,_featureStats = featureStats,super._();
  factory _ModelBaselineMetrics.fromJson(Map<String, dynamic> json) => _$ModelBaselineMetricsFromJson(json);

/// Model version
@override final  String modelVersion;
/// When baseline was established
@override final  DateTime establishedAt;
/// Baseline AUC-ROC
@override final  double aucRoc;
/// Baseline precision
@override final  double precision;
/// Baseline recall
@override final  double recall;
/// Baseline F1 score
@override final  double f1;
/// Baseline Brier score
@override final  double brierScore;
/// Baseline calibration error
@override final  double calibrationError;
/// Training sample size
@override final  int trainingSampleSize;
/// Feature importance rankings at training time
 final  Map<String, double> _featureImportances;
/// Feature importance rankings at training time
@override@JsonKey() Map<String, double> get featureImportances {
  if (_featureImportances is EqualUnmodifiableMapView) return _featureImportances;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_featureImportances);
}

/// Feature distribution statistics at training time
 final  Map<String, FeatureStats> _featureStats;
/// Feature distribution statistics at training time
@override@JsonKey() Map<String, FeatureStats> get featureStats {
  if (_featureStats is EqualUnmodifiableMapView) return _featureStats;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_featureStats);
}


/// Create a copy of ModelBaselineMetrics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModelBaselineMetricsCopyWith<_ModelBaselineMetrics> get copyWith => __$ModelBaselineMetricsCopyWithImpl<_ModelBaselineMetrics>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModelBaselineMetricsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModelBaselineMetrics&&(identical(other.modelVersion, modelVersion) || other.modelVersion == modelVersion)&&(identical(other.establishedAt, establishedAt) || other.establishedAt == establishedAt)&&(identical(other.aucRoc, aucRoc) || other.aucRoc == aucRoc)&&(identical(other.precision, precision) || other.precision == precision)&&(identical(other.recall, recall) || other.recall == recall)&&(identical(other.f1, f1) || other.f1 == f1)&&(identical(other.brierScore, brierScore) || other.brierScore == brierScore)&&(identical(other.calibrationError, calibrationError) || other.calibrationError == calibrationError)&&(identical(other.trainingSampleSize, trainingSampleSize) || other.trainingSampleSize == trainingSampleSize)&&const DeepCollectionEquality().equals(other._featureImportances, _featureImportances)&&const DeepCollectionEquality().equals(other._featureStats, _featureStats));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,modelVersion,establishedAt,aucRoc,precision,recall,f1,brierScore,calibrationError,trainingSampleSize,const DeepCollectionEquality().hash(_featureImportances),const DeepCollectionEquality().hash(_featureStats));

@override
String toString() {
  return 'ModelBaselineMetrics(modelVersion: $modelVersion, establishedAt: $establishedAt, aucRoc: $aucRoc, precision: $precision, recall: $recall, f1: $f1, brierScore: $brierScore, calibrationError: $calibrationError, trainingSampleSize: $trainingSampleSize, featureImportances: $featureImportances, featureStats: $featureStats)';
}


}

/// @nodoc
abstract mixin class _$ModelBaselineMetricsCopyWith<$Res> implements $ModelBaselineMetricsCopyWith<$Res> {
  factory _$ModelBaselineMetricsCopyWith(_ModelBaselineMetrics value, $Res Function(_ModelBaselineMetrics) _then) = __$ModelBaselineMetricsCopyWithImpl;
@override @useResult
$Res call({
 String modelVersion, DateTime establishedAt, double aucRoc, double precision, double recall, double f1, double brierScore, double calibrationError, int trainingSampleSize, Map<String, double> featureImportances, Map<String, FeatureStats> featureStats
});




}
/// @nodoc
class __$ModelBaselineMetricsCopyWithImpl<$Res>
    implements _$ModelBaselineMetricsCopyWith<$Res> {
  __$ModelBaselineMetricsCopyWithImpl(this._self, this._then);

  final _ModelBaselineMetrics _self;
  final $Res Function(_ModelBaselineMetrics) _then;

/// Create a copy of ModelBaselineMetrics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? modelVersion = null,Object? establishedAt = null,Object? aucRoc = null,Object? precision = null,Object? recall = null,Object? f1 = null,Object? brierScore = null,Object? calibrationError = null,Object? trainingSampleSize = null,Object? featureImportances = null,Object? featureStats = null,}) {
  return _then(_ModelBaselineMetrics(
modelVersion: null == modelVersion ? _self.modelVersion : modelVersion // ignore: cast_nullable_to_non_nullable
as String,establishedAt: null == establishedAt ? _self.establishedAt : establishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,aucRoc: null == aucRoc ? _self.aucRoc : aucRoc // ignore: cast_nullable_to_non_nullable
as double,precision: null == precision ? _self.precision : precision // ignore: cast_nullable_to_non_nullable
as double,recall: null == recall ? _self.recall : recall // ignore: cast_nullable_to_non_nullable
as double,f1: null == f1 ? _self.f1 : f1 // ignore: cast_nullable_to_non_nullable
as double,brierScore: null == brierScore ? _self.brierScore : brierScore // ignore: cast_nullable_to_non_nullable
as double,calibrationError: null == calibrationError ? _self.calibrationError : calibrationError // ignore: cast_nullable_to_non_nullable
as double,trainingSampleSize: null == trainingSampleSize ? _self.trainingSampleSize : trainingSampleSize // ignore: cast_nullable_to_non_nullable
as int,featureImportances: null == featureImportances ? _self._featureImportances : featureImportances // ignore: cast_nullable_to_non_nullable
as Map<String, double>,featureStats: null == featureStats ? _self._featureStats : featureStats // ignore: cast_nullable_to_non_nullable
as Map<String, FeatureStats>,
  ));
}


}


/// @nodoc
mixin _$FeatureStats {

/// Feature name
 String get featureName;/// Mean value (for numeric features)
 double? get mean;/// Standard deviation (for numeric features)
 double? get stdDev;/// Minimum value
 double? get min;/// Maximum value
 double? get max;/// Distribution of values (for categorical features)
 Map<String, double> get distribution;/// Number of samples
 int get sampleCount;
/// Create a copy of FeatureStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeatureStatsCopyWith<FeatureStats> get copyWith => _$FeatureStatsCopyWithImpl<FeatureStats>(this as FeatureStats, _$identity);

  /// Serializes this FeatureStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeatureStats&&(identical(other.featureName, featureName) || other.featureName == featureName)&&(identical(other.mean, mean) || other.mean == mean)&&(identical(other.stdDev, stdDev) || other.stdDev == stdDev)&&(identical(other.min, min) || other.min == min)&&(identical(other.max, max) || other.max == max)&&const DeepCollectionEquality().equals(other.distribution, distribution)&&(identical(other.sampleCount, sampleCount) || other.sampleCount == sampleCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,featureName,mean,stdDev,min,max,const DeepCollectionEquality().hash(distribution),sampleCount);

@override
String toString() {
  return 'FeatureStats(featureName: $featureName, mean: $mean, stdDev: $stdDev, min: $min, max: $max, distribution: $distribution, sampleCount: $sampleCount)';
}


}

/// @nodoc
abstract mixin class $FeatureStatsCopyWith<$Res>  {
  factory $FeatureStatsCopyWith(FeatureStats value, $Res Function(FeatureStats) _then) = _$FeatureStatsCopyWithImpl;
@useResult
$Res call({
 String featureName, double? mean, double? stdDev, double? min, double? max, Map<String, double> distribution, int sampleCount
});




}
/// @nodoc
class _$FeatureStatsCopyWithImpl<$Res>
    implements $FeatureStatsCopyWith<$Res> {
  _$FeatureStatsCopyWithImpl(this._self, this._then);

  final FeatureStats _self;
  final $Res Function(FeatureStats) _then;

/// Create a copy of FeatureStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? featureName = null,Object? mean = freezed,Object? stdDev = freezed,Object? min = freezed,Object? max = freezed,Object? distribution = null,Object? sampleCount = null,}) {
  return _then(_self.copyWith(
featureName: null == featureName ? _self.featureName : featureName // ignore: cast_nullable_to_non_nullable
as String,mean: freezed == mean ? _self.mean : mean // ignore: cast_nullable_to_non_nullable
as double?,stdDev: freezed == stdDev ? _self.stdDev : stdDev // ignore: cast_nullable_to_non_nullable
as double?,min: freezed == min ? _self.min : min // ignore: cast_nullable_to_non_nullable
as double?,max: freezed == max ? _self.max : max // ignore: cast_nullable_to_non_nullable
as double?,distribution: null == distribution ? _self.distribution : distribution // ignore: cast_nullable_to_non_nullable
as Map<String, double>,sampleCount: null == sampleCount ? _self.sampleCount : sampleCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [FeatureStats].
extension FeatureStatsPatterns on FeatureStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeatureStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeatureStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeatureStats value)  $default,){
final _that = this;
switch (_that) {
case _FeatureStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeatureStats value)?  $default,){
final _that = this;
switch (_that) {
case _FeatureStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String featureName,  double? mean,  double? stdDev,  double? min,  double? max,  Map<String, double> distribution,  int sampleCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeatureStats() when $default != null:
return $default(_that.featureName,_that.mean,_that.stdDev,_that.min,_that.max,_that.distribution,_that.sampleCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String featureName,  double? mean,  double? stdDev,  double? min,  double? max,  Map<String, double> distribution,  int sampleCount)  $default,) {final _that = this;
switch (_that) {
case _FeatureStats():
return $default(_that.featureName,_that.mean,_that.stdDev,_that.min,_that.max,_that.distribution,_that.sampleCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String featureName,  double? mean,  double? stdDev,  double? min,  double? max,  Map<String, double> distribution,  int sampleCount)?  $default,) {final _that = this;
switch (_that) {
case _FeatureStats() when $default != null:
return $default(_that.featureName,_that.mean,_that.stdDev,_that.min,_that.max,_that.distribution,_that.sampleCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FeatureStats extends FeatureStats {
  const _FeatureStats({required this.featureName, this.mean, this.stdDev, this.min, this.max, final  Map<String, double> distribution = const {}, required this.sampleCount}): _distribution = distribution,super._();
  factory _FeatureStats.fromJson(Map<String, dynamic> json) => _$FeatureStatsFromJson(json);

/// Feature name
@override final  String featureName;
/// Mean value (for numeric features)
@override final  double? mean;
/// Standard deviation (for numeric features)
@override final  double? stdDev;
/// Minimum value
@override final  double? min;
/// Maximum value
@override final  double? max;
/// Distribution of values (for categorical features)
 final  Map<String, double> _distribution;
/// Distribution of values (for categorical features)
@override@JsonKey() Map<String, double> get distribution {
  if (_distribution is EqualUnmodifiableMapView) return _distribution;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_distribution);
}

/// Number of samples
@override final  int sampleCount;

/// Create a copy of FeatureStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeatureStatsCopyWith<_FeatureStats> get copyWith => __$FeatureStatsCopyWithImpl<_FeatureStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FeatureStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeatureStats&&(identical(other.featureName, featureName) || other.featureName == featureName)&&(identical(other.mean, mean) || other.mean == mean)&&(identical(other.stdDev, stdDev) || other.stdDev == stdDev)&&(identical(other.min, min) || other.min == min)&&(identical(other.max, max) || other.max == max)&&const DeepCollectionEquality().equals(other._distribution, _distribution)&&(identical(other.sampleCount, sampleCount) || other.sampleCount == sampleCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,featureName,mean,stdDev,min,max,const DeepCollectionEquality().hash(_distribution),sampleCount);

@override
String toString() {
  return 'FeatureStats(featureName: $featureName, mean: $mean, stdDev: $stdDev, min: $min, max: $max, distribution: $distribution, sampleCount: $sampleCount)';
}


}

/// @nodoc
abstract mixin class _$FeatureStatsCopyWith<$Res> implements $FeatureStatsCopyWith<$Res> {
  factory _$FeatureStatsCopyWith(_FeatureStats value, $Res Function(_FeatureStats) _then) = __$FeatureStatsCopyWithImpl;
@override @useResult
$Res call({
 String featureName, double? mean, double? stdDev, double? min, double? max, Map<String, double> distribution, int sampleCount
});




}
/// @nodoc
class __$FeatureStatsCopyWithImpl<$Res>
    implements _$FeatureStatsCopyWith<$Res> {
  __$FeatureStatsCopyWithImpl(this._self, this._then);

  final _FeatureStats _self;
  final $Res Function(_FeatureStats) _then;

/// Create a copy of FeatureStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? featureName = null,Object? mean = freezed,Object? stdDev = freezed,Object? min = freezed,Object? max = freezed,Object? distribution = null,Object? sampleCount = null,}) {
  return _then(_FeatureStats(
featureName: null == featureName ? _self.featureName : featureName // ignore: cast_nullable_to_non_nullable
as String,mean: freezed == mean ? _self.mean : mean // ignore: cast_nullable_to_non_nullable
as double?,stdDev: freezed == stdDev ? _self.stdDev : stdDev // ignore: cast_nullable_to_non_nullable
as double?,min: freezed == min ? _self.min : min // ignore: cast_nullable_to_non_nullable
as double?,max: freezed == max ? _self.max : max // ignore: cast_nullable_to_non_nullable
as double?,distribution: null == distribution ? _self._distribution : distribution // ignore: cast_nullable_to_non_nullable
as Map<String, double>,sampleCount: null == sampleCount ? _self.sampleCount : sampleCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$MonitoringThresholds {

/// Minimum acceptable AUC (default: 0.75)
 double get minAuc;/// Maximum acceptable calibration error (default: 0.1)
 double get maxCalibrationError;/// AUC drop percentage to trigger alert (default: 5%)
 double get aucDropThreshold;/// Drift score threshold in standard deviations (default: 2.0)
 double get driftThreshold;/// Minimum sample size for evaluation (default: 50)
 int get minSampleSize;/// Minimum outcomes needed before triggering retraining (default: 1000)
 int get minOutcomesForRetraining;
/// Create a copy of MonitoringThresholds
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonitoringThresholdsCopyWith<MonitoringThresholds> get copyWith => _$MonitoringThresholdsCopyWithImpl<MonitoringThresholds>(this as MonitoringThresholds, _$identity);

  /// Serializes this MonitoringThresholds to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonitoringThresholds&&(identical(other.minAuc, minAuc) || other.minAuc == minAuc)&&(identical(other.maxCalibrationError, maxCalibrationError) || other.maxCalibrationError == maxCalibrationError)&&(identical(other.aucDropThreshold, aucDropThreshold) || other.aucDropThreshold == aucDropThreshold)&&(identical(other.driftThreshold, driftThreshold) || other.driftThreshold == driftThreshold)&&(identical(other.minSampleSize, minSampleSize) || other.minSampleSize == minSampleSize)&&(identical(other.minOutcomesForRetraining, minOutcomesForRetraining) || other.minOutcomesForRetraining == minOutcomesForRetraining));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,minAuc,maxCalibrationError,aucDropThreshold,driftThreshold,minSampleSize,minOutcomesForRetraining);

@override
String toString() {
  return 'MonitoringThresholds(minAuc: $minAuc, maxCalibrationError: $maxCalibrationError, aucDropThreshold: $aucDropThreshold, driftThreshold: $driftThreshold, minSampleSize: $minSampleSize, minOutcomesForRetraining: $minOutcomesForRetraining)';
}


}

/// @nodoc
abstract mixin class $MonitoringThresholdsCopyWith<$Res>  {
  factory $MonitoringThresholdsCopyWith(MonitoringThresholds value, $Res Function(MonitoringThresholds) _then) = _$MonitoringThresholdsCopyWithImpl;
@useResult
$Res call({
 double minAuc, double maxCalibrationError, double aucDropThreshold, double driftThreshold, int minSampleSize, int minOutcomesForRetraining
});




}
/// @nodoc
class _$MonitoringThresholdsCopyWithImpl<$Res>
    implements $MonitoringThresholdsCopyWith<$Res> {
  _$MonitoringThresholdsCopyWithImpl(this._self, this._then);

  final MonitoringThresholds _self;
  final $Res Function(MonitoringThresholds) _then;

/// Create a copy of MonitoringThresholds
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? minAuc = null,Object? maxCalibrationError = null,Object? aucDropThreshold = null,Object? driftThreshold = null,Object? minSampleSize = null,Object? minOutcomesForRetraining = null,}) {
  return _then(_self.copyWith(
minAuc: null == minAuc ? _self.minAuc : minAuc // ignore: cast_nullable_to_non_nullable
as double,maxCalibrationError: null == maxCalibrationError ? _self.maxCalibrationError : maxCalibrationError // ignore: cast_nullable_to_non_nullable
as double,aucDropThreshold: null == aucDropThreshold ? _self.aucDropThreshold : aucDropThreshold // ignore: cast_nullable_to_non_nullable
as double,driftThreshold: null == driftThreshold ? _self.driftThreshold : driftThreshold // ignore: cast_nullable_to_non_nullable
as double,minSampleSize: null == minSampleSize ? _self.minSampleSize : minSampleSize // ignore: cast_nullable_to_non_nullable
as int,minOutcomesForRetraining: null == minOutcomesForRetraining ? _self.minOutcomesForRetraining : minOutcomesForRetraining // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MonitoringThresholds].
extension MonitoringThresholdsPatterns on MonitoringThresholds {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonitoringThresholds value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonitoringThresholds() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonitoringThresholds value)  $default,){
final _that = this;
switch (_that) {
case _MonitoringThresholds():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonitoringThresholds value)?  $default,){
final _that = this;
switch (_that) {
case _MonitoringThresholds() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double minAuc,  double maxCalibrationError,  double aucDropThreshold,  double driftThreshold,  int minSampleSize,  int minOutcomesForRetraining)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonitoringThresholds() when $default != null:
return $default(_that.minAuc,_that.maxCalibrationError,_that.aucDropThreshold,_that.driftThreshold,_that.minSampleSize,_that.minOutcomesForRetraining);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double minAuc,  double maxCalibrationError,  double aucDropThreshold,  double driftThreshold,  int minSampleSize,  int minOutcomesForRetraining)  $default,) {final _that = this;
switch (_that) {
case _MonitoringThresholds():
return $default(_that.minAuc,_that.maxCalibrationError,_that.aucDropThreshold,_that.driftThreshold,_that.minSampleSize,_that.minOutcomesForRetraining);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double minAuc,  double maxCalibrationError,  double aucDropThreshold,  double driftThreshold,  int minSampleSize,  int minOutcomesForRetraining)?  $default,) {final _that = this;
switch (_that) {
case _MonitoringThresholds() when $default != null:
return $default(_that.minAuc,_that.maxCalibrationError,_that.aucDropThreshold,_that.driftThreshold,_that.minSampleSize,_that.minOutcomesForRetraining);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MonitoringThresholds extends MonitoringThresholds {
  const _MonitoringThresholds({this.minAuc = 0.75, this.maxCalibrationError = 0.1, this.aucDropThreshold = 0.05, this.driftThreshold = 2.0, this.minSampleSize = 50, this.minOutcomesForRetraining = 1000}): super._();
  factory _MonitoringThresholds.fromJson(Map<String, dynamic> json) => _$MonitoringThresholdsFromJson(json);

/// Minimum acceptable AUC (default: 0.75)
@override@JsonKey() final  double minAuc;
/// Maximum acceptable calibration error (default: 0.1)
@override@JsonKey() final  double maxCalibrationError;
/// AUC drop percentage to trigger alert (default: 5%)
@override@JsonKey() final  double aucDropThreshold;
/// Drift score threshold in standard deviations (default: 2.0)
@override@JsonKey() final  double driftThreshold;
/// Minimum sample size for evaluation (default: 50)
@override@JsonKey() final  int minSampleSize;
/// Minimum outcomes needed before triggering retraining (default: 1000)
@override@JsonKey() final  int minOutcomesForRetraining;

/// Create a copy of MonitoringThresholds
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonitoringThresholdsCopyWith<_MonitoringThresholds> get copyWith => __$MonitoringThresholdsCopyWithImpl<_MonitoringThresholds>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MonitoringThresholdsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonitoringThresholds&&(identical(other.minAuc, minAuc) || other.minAuc == minAuc)&&(identical(other.maxCalibrationError, maxCalibrationError) || other.maxCalibrationError == maxCalibrationError)&&(identical(other.aucDropThreshold, aucDropThreshold) || other.aucDropThreshold == aucDropThreshold)&&(identical(other.driftThreshold, driftThreshold) || other.driftThreshold == driftThreshold)&&(identical(other.minSampleSize, minSampleSize) || other.minSampleSize == minSampleSize)&&(identical(other.minOutcomesForRetraining, minOutcomesForRetraining) || other.minOutcomesForRetraining == minOutcomesForRetraining));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,minAuc,maxCalibrationError,aucDropThreshold,driftThreshold,minSampleSize,minOutcomesForRetraining);

@override
String toString() {
  return 'MonitoringThresholds(minAuc: $minAuc, maxCalibrationError: $maxCalibrationError, aucDropThreshold: $aucDropThreshold, driftThreshold: $driftThreshold, minSampleSize: $minSampleSize, minOutcomesForRetraining: $minOutcomesForRetraining)';
}


}

/// @nodoc
abstract mixin class _$MonitoringThresholdsCopyWith<$Res> implements $MonitoringThresholdsCopyWith<$Res> {
  factory _$MonitoringThresholdsCopyWith(_MonitoringThresholds value, $Res Function(_MonitoringThresholds) _then) = __$MonitoringThresholdsCopyWithImpl;
@override @useResult
$Res call({
 double minAuc, double maxCalibrationError, double aucDropThreshold, double driftThreshold, int minSampleSize, int minOutcomesForRetraining
});




}
/// @nodoc
class __$MonitoringThresholdsCopyWithImpl<$Res>
    implements _$MonitoringThresholdsCopyWith<$Res> {
  __$MonitoringThresholdsCopyWithImpl(this._self, this._then);

  final _MonitoringThresholds _self;
  final $Res Function(_MonitoringThresholds) _then;

/// Create a copy of MonitoringThresholds
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? minAuc = null,Object? maxCalibrationError = null,Object? aucDropThreshold = null,Object? driftThreshold = null,Object? minSampleSize = null,Object? minOutcomesForRetraining = null,}) {
  return _then(_MonitoringThresholds(
minAuc: null == minAuc ? _self.minAuc : minAuc // ignore: cast_nullable_to_non_nullable
as double,maxCalibrationError: null == maxCalibrationError ? _self.maxCalibrationError : maxCalibrationError // ignore: cast_nullable_to_non_nullable
as double,aucDropThreshold: null == aucDropThreshold ? _self.aucDropThreshold : aucDropThreshold // ignore: cast_nullable_to_non_nullable
as double,driftThreshold: null == driftThreshold ? _self.driftThreshold : driftThreshold // ignore: cast_nullable_to_non_nullable
as double,minSampleSize: null == minSampleSize ? _self.minSampleSize : minSampleSize // ignore: cast_nullable_to_non_nullable
as int,minOutcomesForRetraining: null == minOutcomesForRetraining ? _self.minOutcomesForRetraining : minOutcomesForRetraining // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
