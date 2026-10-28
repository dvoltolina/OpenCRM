// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feature_importance.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FeatureImportance {

/// Technical name of the feature (e.g., 'clientHistoricalNoshowRate')
 String get featureName;/// Human-readable name for display (e.g., 'Past No-Show Rate')
 String get featureDisplayName;/// Importance score (0.0-1.0, relative to other features)
 double get importance;/// Actual value of this feature for this prediction
 double get featureValue;/// Direction of impact on risk: 'increases_risk' or 'decreases_risk'
 String get impact;/// Human-readable explanation of this feature's contribution
 String? get explanation;
/// Create a copy of FeatureImportance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeatureImportanceCopyWith<FeatureImportance> get copyWith => _$FeatureImportanceCopyWithImpl<FeatureImportance>(this as FeatureImportance, _$identity);

  /// Serializes this FeatureImportance to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeatureImportance&&(identical(other.featureName, featureName) || other.featureName == featureName)&&(identical(other.featureDisplayName, featureDisplayName) || other.featureDisplayName == featureDisplayName)&&(identical(other.importance, importance) || other.importance == importance)&&(identical(other.featureValue, featureValue) || other.featureValue == featureValue)&&(identical(other.impact, impact) || other.impact == impact)&&(identical(other.explanation, explanation) || other.explanation == explanation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,featureName,featureDisplayName,importance,featureValue,impact,explanation);

@override
String toString() {
  return 'FeatureImportance(featureName: $featureName, featureDisplayName: $featureDisplayName, importance: $importance, featureValue: $featureValue, impact: $impact, explanation: $explanation)';
}


}

/// @nodoc
abstract mixin class $FeatureImportanceCopyWith<$Res>  {
  factory $FeatureImportanceCopyWith(FeatureImportance value, $Res Function(FeatureImportance) _then) = _$FeatureImportanceCopyWithImpl;
@useResult
$Res call({
 String featureName, String featureDisplayName, double importance, double featureValue, String impact, String? explanation
});




}
/// @nodoc
class _$FeatureImportanceCopyWithImpl<$Res>
    implements $FeatureImportanceCopyWith<$Res> {
  _$FeatureImportanceCopyWithImpl(this._self, this._then);

  final FeatureImportance _self;
  final $Res Function(FeatureImportance) _then;

/// Create a copy of FeatureImportance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? featureName = null,Object? featureDisplayName = null,Object? importance = null,Object? featureValue = null,Object? impact = null,Object? explanation = freezed,}) {
  return _then(_self.copyWith(
featureName: null == featureName ? _self.featureName : featureName // ignore: cast_nullable_to_non_nullable
as String,featureDisplayName: null == featureDisplayName ? _self.featureDisplayName : featureDisplayName // ignore: cast_nullable_to_non_nullable
as String,importance: null == importance ? _self.importance : importance // ignore: cast_nullable_to_non_nullable
as double,featureValue: null == featureValue ? _self.featureValue : featureValue // ignore: cast_nullable_to_non_nullable
as double,impact: null == impact ? _self.impact : impact // ignore: cast_nullable_to_non_nullable
as String,explanation: freezed == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FeatureImportance].
extension FeatureImportancePatterns on FeatureImportance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeatureImportance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeatureImportance() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeatureImportance value)  $default,){
final _that = this;
switch (_that) {
case _FeatureImportance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeatureImportance value)?  $default,){
final _that = this;
switch (_that) {
case _FeatureImportance() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String featureName,  String featureDisplayName,  double importance,  double featureValue,  String impact,  String? explanation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeatureImportance() when $default != null:
return $default(_that.featureName,_that.featureDisplayName,_that.importance,_that.featureValue,_that.impact,_that.explanation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String featureName,  String featureDisplayName,  double importance,  double featureValue,  String impact,  String? explanation)  $default,) {final _that = this;
switch (_that) {
case _FeatureImportance():
return $default(_that.featureName,_that.featureDisplayName,_that.importance,_that.featureValue,_that.impact,_that.explanation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String featureName,  String featureDisplayName,  double importance,  double featureValue,  String impact,  String? explanation)?  $default,) {final _that = this;
switch (_that) {
case _FeatureImportance() when $default != null:
return $default(_that.featureName,_that.featureDisplayName,_that.importance,_that.featureValue,_that.impact,_that.explanation);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FeatureImportance extends FeatureImportance {
  const _FeatureImportance({required this.featureName, required this.featureDisplayName, required this.importance, required this.featureValue, required this.impact, this.explanation}): super._();
  factory _FeatureImportance.fromJson(Map<String, dynamic> json) => _$FeatureImportanceFromJson(json);

/// Technical name of the feature (e.g., 'clientHistoricalNoshowRate')
@override final  String featureName;
/// Human-readable name for display (e.g., 'Past No-Show Rate')
@override final  String featureDisplayName;
/// Importance score (0.0-1.0, relative to other features)
@override final  double importance;
/// Actual value of this feature for this prediction
@override final  double featureValue;
/// Direction of impact on risk: 'increases_risk' or 'decreases_risk'
@override final  String impact;
/// Human-readable explanation of this feature's contribution
@override final  String? explanation;

/// Create a copy of FeatureImportance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeatureImportanceCopyWith<_FeatureImportance> get copyWith => __$FeatureImportanceCopyWithImpl<_FeatureImportance>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FeatureImportanceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeatureImportance&&(identical(other.featureName, featureName) || other.featureName == featureName)&&(identical(other.featureDisplayName, featureDisplayName) || other.featureDisplayName == featureDisplayName)&&(identical(other.importance, importance) || other.importance == importance)&&(identical(other.featureValue, featureValue) || other.featureValue == featureValue)&&(identical(other.impact, impact) || other.impact == impact)&&(identical(other.explanation, explanation) || other.explanation == explanation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,featureName,featureDisplayName,importance,featureValue,impact,explanation);

@override
String toString() {
  return 'FeatureImportance(featureName: $featureName, featureDisplayName: $featureDisplayName, importance: $importance, featureValue: $featureValue, impact: $impact, explanation: $explanation)';
}


}

/// @nodoc
abstract mixin class _$FeatureImportanceCopyWith<$Res> implements $FeatureImportanceCopyWith<$Res> {
  factory _$FeatureImportanceCopyWith(_FeatureImportance value, $Res Function(_FeatureImportance) _then) = __$FeatureImportanceCopyWithImpl;
@override @useResult
$Res call({
 String featureName, String featureDisplayName, double importance, double featureValue, String impact, String? explanation
});




}
/// @nodoc
class __$FeatureImportanceCopyWithImpl<$Res>
    implements _$FeatureImportanceCopyWith<$Res> {
  __$FeatureImportanceCopyWithImpl(this._self, this._then);

  final _FeatureImportance _self;
  final $Res Function(_FeatureImportance) _then;

/// Create a copy of FeatureImportance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? featureName = null,Object? featureDisplayName = null,Object? importance = null,Object? featureValue = null,Object? impact = null,Object? explanation = freezed,}) {
  return _then(_FeatureImportance(
featureName: null == featureName ? _self.featureName : featureName // ignore: cast_nullable_to_non_nullable
as String,featureDisplayName: null == featureDisplayName ? _self.featureDisplayName : featureDisplayName // ignore: cast_nullable_to_non_nullable
as String,importance: null == importance ? _self.importance : importance // ignore: cast_nullable_to_non_nullable
as double,featureValue: null == featureValue ? _self.featureValue : featureValue // ignore: cast_nullable_to_non_nullable
as double,impact: null == impact ? _self.impact : impact // ignore: cast_nullable_to_non_nullable
as String,explanation: freezed == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
