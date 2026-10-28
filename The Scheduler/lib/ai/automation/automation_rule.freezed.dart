// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'automation_rule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AutomationTriggerConfig {

/// Type of trigger.
 AutomationTriggerType get type;/// Threshold value for the trigger (e.g., 0.7 for 70% no-show risk).
 double get threshold;/// Comparison operator: 'gte' (>=), 'lte' (<=), 'gt' (>), 'lt' (<).
 String get comparison;/// Optional: Specific risk/VIP indicators to check.
 List<String> get indicatorTypes;/// Optional: Minimum confidence required for trigger to fire.
 double get minConfidence;
/// Create a copy of AutomationTriggerConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AutomationTriggerConfigCopyWith<AutomationTriggerConfig> get copyWith => _$AutomationTriggerConfigCopyWithImpl<AutomationTriggerConfig>(this as AutomationTriggerConfig, _$identity);

  /// Serializes this AutomationTriggerConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AutomationTriggerConfig&&(identical(other.type, type) || other.type == type)&&(identical(other.threshold, threshold) || other.threshold == threshold)&&(identical(other.comparison, comparison) || other.comparison == comparison)&&const DeepCollectionEquality().equals(other.indicatorTypes, indicatorTypes)&&(identical(other.minConfidence, minConfidence) || other.minConfidence == minConfidence));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,threshold,comparison,const DeepCollectionEquality().hash(indicatorTypes),minConfidence);

@override
String toString() {
  return 'AutomationTriggerConfig(type: $type, threshold: $threshold, comparison: $comparison, indicatorTypes: $indicatorTypes, minConfidence: $minConfidence)';
}


}

/// @nodoc
abstract mixin class $AutomationTriggerConfigCopyWith<$Res>  {
  factory $AutomationTriggerConfigCopyWith(AutomationTriggerConfig value, $Res Function(AutomationTriggerConfig) _then) = _$AutomationTriggerConfigCopyWithImpl;
@useResult
$Res call({
 AutomationTriggerType type, double threshold, String comparison, List<String> indicatorTypes, double minConfidence
});




}
/// @nodoc
class _$AutomationTriggerConfigCopyWithImpl<$Res>
    implements $AutomationTriggerConfigCopyWith<$Res> {
  _$AutomationTriggerConfigCopyWithImpl(this._self, this._then);

  final AutomationTriggerConfig _self;
  final $Res Function(AutomationTriggerConfig) _then;

/// Create a copy of AutomationTriggerConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? threshold = null,Object? comparison = null,Object? indicatorTypes = null,Object? minConfidence = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AutomationTriggerType,threshold: null == threshold ? _self.threshold : threshold // ignore: cast_nullable_to_non_nullable
as double,comparison: null == comparison ? _self.comparison : comparison // ignore: cast_nullable_to_non_nullable
as String,indicatorTypes: null == indicatorTypes ? _self.indicatorTypes : indicatorTypes // ignore: cast_nullable_to_non_nullable
as List<String>,minConfidence: null == minConfidence ? _self.minConfidence : minConfidence // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [AutomationTriggerConfig].
extension AutomationTriggerConfigPatterns on AutomationTriggerConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AutomationTriggerConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AutomationTriggerConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AutomationTriggerConfig value)  $default,){
final _that = this;
switch (_that) {
case _AutomationTriggerConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AutomationTriggerConfig value)?  $default,){
final _that = this;
switch (_that) {
case _AutomationTriggerConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AutomationTriggerType type,  double threshold,  String comparison,  List<String> indicatorTypes,  double minConfidence)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AutomationTriggerConfig() when $default != null:
return $default(_that.type,_that.threshold,_that.comparison,_that.indicatorTypes,_that.minConfidence);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AutomationTriggerType type,  double threshold,  String comparison,  List<String> indicatorTypes,  double minConfidence)  $default,) {final _that = this;
switch (_that) {
case _AutomationTriggerConfig():
return $default(_that.type,_that.threshold,_that.comparison,_that.indicatorTypes,_that.minConfidence);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AutomationTriggerType type,  double threshold,  String comparison,  List<String> indicatorTypes,  double minConfidence)?  $default,) {final _that = this;
switch (_that) {
case _AutomationTriggerConfig() when $default != null:
return $default(_that.type,_that.threshold,_that.comparison,_that.indicatorTypes,_that.minConfidence);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AutomationTriggerConfig implements AutomationTriggerConfig {
  const _AutomationTriggerConfig({required this.type, required this.threshold, this.comparison = 'gte', final  List<String> indicatorTypes = const [], this.minConfidence = 0.5}): _indicatorTypes = indicatorTypes;
  factory _AutomationTriggerConfig.fromJson(Map<String, dynamic> json) => _$AutomationTriggerConfigFromJson(json);

/// Type of trigger.
@override final  AutomationTriggerType type;
/// Threshold value for the trigger (e.g., 0.7 for 70% no-show risk).
@override final  double threshold;
/// Comparison operator: 'gte' (>=), 'lte' (<=), 'gt' (>), 'lt' (<).
@override@JsonKey() final  String comparison;
/// Optional: Specific risk/VIP indicators to check.
 final  List<String> _indicatorTypes;
/// Optional: Specific risk/VIP indicators to check.
@override@JsonKey() List<String> get indicatorTypes {
  if (_indicatorTypes is EqualUnmodifiableListView) return _indicatorTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_indicatorTypes);
}

/// Optional: Minimum confidence required for trigger to fire.
@override@JsonKey() final  double minConfidence;

/// Create a copy of AutomationTriggerConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AutomationTriggerConfigCopyWith<_AutomationTriggerConfig> get copyWith => __$AutomationTriggerConfigCopyWithImpl<_AutomationTriggerConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AutomationTriggerConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AutomationTriggerConfig&&(identical(other.type, type) || other.type == type)&&(identical(other.threshold, threshold) || other.threshold == threshold)&&(identical(other.comparison, comparison) || other.comparison == comparison)&&const DeepCollectionEquality().equals(other._indicatorTypes, _indicatorTypes)&&(identical(other.minConfidence, minConfidence) || other.minConfidence == minConfidence));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,threshold,comparison,const DeepCollectionEquality().hash(_indicatorTypes),minConfidence);

@override
String toString() {
  return 'AutomationTriggerConfig(type: $type, threshold: $threshold, comparison: $comparison, indicatorTypes: $indicatorTypes, minConfidence: $minConfidence)';
}


}

/// @nodoc
abstract mixin class _$AutomationTriggerConfigCopyWith<$Res> implements $AutomationTriggerConfigCopyWith<$Res> {
  factory _$AutomationTriggerConfigCopyWith(_AutomationTriggerConfig value, $Res Function(_AutomationTriggerConfig) _then) = __$AutomationTriggerConfigCopyWithImpl;
@override @useResult
$Res call({
 AutomationTriggerType type, double threshold, String comparison, List<String> indicatorTypes, double minConfidence
});




}
/// @nodoc
class __$AutomationTriggerConfigCopyWithImpl<$Res>
    implements _$AutomationTriggerConfigCopyWith<$Res> {
  __$AutomationTriggerConfigCopyWithImpl(this._self, this._then);

  final _AutomationTriggerConfig _self;
  final $Res Function(_AutomationTriggerConfig) _then;

/// Create a copy of AutomationTriggerConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? threshold = null,Object? comparison = null,Object? indicatorTypes = null,Object? minConfidence = null,}) {
  return _then(_AutomationTriggerConfig(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AutomationTriggerType,threshold: null == threshold ? _self.threshold : threshold // ignore: cast_nullable_to_non_nullable
as double,comparison: null == comparison ? _self.comparison : comparison // ignore: cast_nullable_to_non_nullable
as String,indicatorTypes: null == indicatorTypes ? _self._indicatorTypes : indicatorTypes // ignore: cast_nullable_to_non_nullable
as List<String>,minConfidence: null == minConfidence ? _self.minConfidence : minConfidence // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$AutomationActionConfig {

/// Type of action.
 AutomationActionType get type;/// Template ID for message content (SMS/email).
 String? get templateId;/// Custom message template (if not using templateId).
 String? get messageTemplate;/// Subject line for emails.
 String? get emailSubject;/// Flag/tag name for flagClient action.
 String? get flagName;/// Task title for createTask action.
 String? get taskTitle;/// Task description for createTask action.
 String? get taskDescription;/// Task priority for createTask action.
 String get taskPriority;/// Alert recipients for alertStaff action (role IDs).
 List<String> get alertRecipients;/// Whether to delay action execution.
 bool get delayed;/// Delay duration in minutes (if delayed is true).
 int get delayMinutes;/// Additional metadata for the action.
 Map<String, dynamic> get metadata;
/// Create a copy of AutomationActionConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AutomationActionConfigCopyWith<AutomationActionConfig> get copyWith => _$AutomationActionConfigCopyWithImpl<AutomationActionConfig>(this as AutomationActionConfig, _$identity);

  /// Serializes this AutomationActionConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AutomationActionConfig&&(identical(other.type, type) || other.type == type)&&(identical(other.templateId, templateId) || other.templateId == templateId)&&(identical(other.messageTemplate, messageTemplate) || other.messageTemplate == messageTemplate)&&(identical(other.emailSubject, emailSubject) || other.emailSubject == emailSubject)&&(identical(other.flagName, flagName) || other.flagName == flagName)&&(identical(other.taskTitle, taskTitle) || other.taskTitle == taskTitle)&&(identical(other.taskDescription, taskDescription) || other.taskDescription == taskDescription)&&(identical(other.taskPriority, taskPriority) || other.taskPriority == taskPriority)&&const DeepCollectionEquality().equals(other.alertRecipients, alertRecipients)&&(identical(other.delayed, delayed) || other.delayed == delayed)&&(identical(other.delayMinutes, delayMinutes) || other.delayMinutes == delayMinutes)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,templateId,messageTemplate,emailSubject,flagName,taskTitle,taskDescription,taskPriority,const DeepCollectionEquality().hash(alertRecipients),delayed,delayMinutes,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'AutomationActionConfig(type: $type, templateId: $templateId, messageTemplate: $messageTemplate, emailSubject: $emailSubject, flagName: $flagName, taskTitle: $taskTitle, taskDescription: $taskDescription, taskPriority: $taskPriority, alertRecipients: $alertRecipients, delayed: $delayed, delayMinutes: $delayMinutes, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $AutomationActionConfigCopyWith<$Res>  {
  factory $AutomationActionConfigCopyWith(AutomationActionConfig value, $Res Function(AutomationActionConfig) _then) = _$AutomationActionConfigCopyWithImpl;
@useResult
$Res call({
 AutomationActionType type, String? templateId, String? messageTemplate, String? emailSubject, String? flagName, String? taskTitle, String? taskDescription, String taskPriority, List<String> alertRecipients, bool delayed, int delayMinutes, Map<String, dynamic> metadata
});




}
/// @nodoc
class _$AutomationActionConfigCopyWithImpl<$Res>
    implements $AutomationActionConfigCopyWith<$Res> {
  _$AutomationActionConfigCopyWithImpl(this._self, this._then);

  final AutomationActionConfig _self;
  final $Res Function(AutomationActionConfig) _then;

/// Create a copy of AutomationActionConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? templateId = freezed,Object? messageTemplate = freezed,Object? emailSubject = freezed,Object? flagName = freezed,Object? taskTitle = freezed,Object? taskDescription = freezed,Object? taskPriority = null,Object? alertRecipients = null,Object? delayed = null,Object? delayMinutes = null,Object? metadata = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AutomationActionType,templateId: freezed == templateId ? _self.templateId : templateId // ignore: cast_nullable_to_non_nullable
as String?,messageTemplate: freezed == messageTemplate ? _self.messageTemplate : messageTemplate // ignore: cast_nullable_to_non_nullable
as String?,emailSubject: freezed == emailSubject ? _self.emailSubject : emailSubject // ignore: cast_nullable_to_non_nullable
as String?,flagName: freezed == flagName ? _self.flagName : flagName // ignore: cast_nullable_to_non_nullable
as String?,taskTitle: freezed == taskTitle ? _self.taskTitle : taskTitle // ignore: cast_nullable_to_non_nullable
as String?,taskDescription: freezed == taskDescription ? _self.taskDescription : taskDescription // ignore: cast_nullable_to_non_nullable
as String?,taskPriority: null == taskPriority ? _self.taskPriority : taskPriority // ignore: cast_nullable_to_non_nullable
as String,alertRecipients: null == alertRecipients ? _self.alertRecipients : alertRecipients // ignore: cast_nullable_to_non_nullable
as List<String>,delayed: null == delayed ? _self.delayed : delayed // ignore: cast_nullable_to_non_nullable
as bool,delayMinutes: null == delayMinutes ? _self.delayMinutes : delayMinutes // ignore: cast_nullable_to_non_nullable
as int,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [AutomationActionConfig].
extension AutomationActionConfigPatterns on AutomationActionConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AutomationActionConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AutomationActionConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AutomationActionConfig value)  $default,){
final _that = this;
switch (_that) {
case _AutomationActionConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AutomationActionConfig value)?  $default,){
final _that = this;
switch (_that) {
case _AutomationActionConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AutomationActionType type,  String? templateId,  String? messageTemplate,  String? emailSubject,  String? flagName,  String? taskTitle,  String? taskDescription,  String taskPriority,  List<String> alertRecipients,  bool delayed,  int delayMinutes,  Map<String, dynamic> metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AutomationActionConfig() when $default != null:
return $default(_that.type,_that.templateId,_that.messageTemplate,_that.emailSubject,_that.flagName,_that.taskTitle,_that.taskDescription,_that.taskPriority,_that.alertRecipients,_that.delayed,_that.delayMinutes,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AutomationActionType type,  String? templateId,  String? messageTemplate,  String? emailSubject,  String? flagName,  String? taskTitle,  String? taskDescription,  String taskPriority,  List<String> alertRecipients,  bool delayed,  int delayMinutes,  Map<String, dynamic> metadata)  $default,) {final _that = this;
switch (_that) {
case _AutomationActionConfig():
return $default(_that.type,_that.templateId,_that.messageTemplate,_that.emailSubject,_that.flagName,_that.taskTitle,_that.taskDescription,_that.taskPriority,_that.alertRecipients,_that.delayed,_that.delayMinutes,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AutomationActionType type,  String? templateId,  String? messageTemplate,  String? emailSubject,  String? flagName,  String? taskTitle,  String? taskDescription,  String taskPriority,  List<String> alertRecipients,  bool delayed,  int delayMinutes,  Map<String, dynamic> metadata)?  $default,) {final _that = this;
switch (_that) {
case _AutomationActionConfig() when $default != null:
return $default(_that.type,_that.templateId,_that.messageTemplate,_that.emailSubject,_that.flagName,_that.taskTitle,_that.taskDescription,_that.taskPriority,_that.alertRecipients,_that.delayed,_that.delayMinutes,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AutomationActionConfig implements AutomationActionConfig {
  const _AutomationActionConfig({required this.type, this.templateId, this.messageTemplate, this.emailSubject, this.flagName, this.taskTitle, this.taskDescription, this.taskPriority = 'medium', final  List<String> alertRecipients = const [], this.delayed = false, this.delayMinutes = 0, final  Map<String, dynamic> metadata = const {}}): _alertRecipients = alertRecipients,_metadata = metadata;
  factory _AutomationActionConfig.fromJson(Map<String, dynamic> json) => _$AutomationActionConfigFromJson(json);

/// Type of action.
@override final  AutomationActionType type;
/// Template ID for message content (SMS/email).
@override final  String? templateId;
/// Custom message template (if not using templateId).
@override final  String? messageTemplate;
/// Subject line for emails.
@override final  String? emailSubject;
/// Flag/tag name for flagClient action.
@override final  String? flagName;
/// Task title for createTask action.
@override final  String? taskTitle;
/// Task description for createTask action.
@override final  String? taskDescription;
/// Task priority for createTask action.
@override@JsonKey() final  String taskPriority;
/// Alert recipients for alertStaff action (role IDs).
 final  List<String> _alertRecipients;
/// Alert recipients for alertStaff action (role IDs).
@override@JsonKey() List<String> get alertRecipients {
  if (_alertRecipients is EqualUnmodifiableListView) return _alertRecipients;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_alertRecipients);
}

/// Whether to delay action execution.
@override@JsonKey() final  bool delayed;
/// Delay duration in minutes (if delayed is true).
@override@JsonKey() final  int delayMinutes;
/// Additional metadata for the action.
 final  Map<String, dynamic> _metadata;
/// Additional metadata for the action.
@override@JsonKey() Map<String, dynamic> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}


/// Create a copy of AutomationActionConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AutomationActionConfigCopyWith<_AutomationActionConfig> get copyWith => __$AutomationActionConfigCopyWithImpl<_AutomationActionConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AutomationActionConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AutomationActionConfig&&(identical(other.type, type) || other.type == type)&&(identical(other.templateId, templateId) || other.templateId == templateId)&&(identical(other.messageTemplate, messageTemplate) || other.messageTemplate == messageTemplate)&&(identical(other.emailSubject, emailSubject) || other.emailSubject == emailSubject)&&(identical(other.flagName, flagName) || other.flagName == flagName)&&(identical(other.taskTitle, taskTitle) || other.taskTitle == taskTitle)&&(identical(other.taskDescription, taskDescription) || other.taskDescription == taskDescription)&&(identical(other.taskPriority, taskPriority) || other.taskPriority == taskPriority)&&const DeepCollectionEquality().equals(other._alertRecipients, _alertRecipients)&&(identical(other.delayed, delayed) || other.delayed == delayed)&&(identical(other.delayMinutes, delayMinutes) || other.delayMinutes == delayMinutes)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,templateId,messageTemplate,emailSubject,flagName,taskTitle,taskDescription,taskPriority,const DeepCollectionEquality().hash(_alertRecipients),delayed,delayMinutes,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'AutomationActionConfig(type: $type, templateId: $templateId, messageTemplate: $messageTemplate, emailSubject: $emailSubject, flagName: $flagName, taskTitle: $taskTitle, taskDescription: $taskDescription, taskPriority: $taskPriority, alertRecipients: $alertRecipients, delayed: $delayed, delayMinutes: $delayMinutes, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$AutomationActionConfigCopyWith<$Res> implements $AutomationActionConfigCopyWith<$Res> {
  factory _$AutomationActionConfigCopyWith(_AutomationActionConfig value, $Res Function(_AutomationActionConfig) _then) = __$AutomationActionConfigCopyWithImpl;
@override @useResult
$Res call({
 AutomationActionType type, String? templateId, String? messageTemplate, String? emailSubject, String? flagName, String? taskTitle, String? taskDescription, String taskPriority, List<String> alertRecipients, bool delayed, int delayMinutes, Map<String, dynamic> metadata
});




}
/// @nodoc
class __$AutomationActionConfigCopyWithImpl<$Res>
    implements _$AutomationActionConfigCopyWith<$Res> {
  __$AutomationActionConfigCopyWithImpl(this._self, this._then);

  final _AutomationActionConfig _self;
  final $Res Function(_AutomationActionConfig) _then;

/// Create a copy of AutomationActionConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? templateId = freezed,Object? messageTemplate = freezed,Object? emailSubject = freezed,Object? flagName = freezed,Object? taskTitle = freezed,Object? taskDescription = freezed,Object? taskPriority = null,Object? alertRecipients = null,Object? delayed = null,Object? delayMinutes = null,Object? metadata = null,}) {
  return _then(_AutomationActionConfig(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AutomationActionType,templateId: freezed == templateId ? _self.templateId : templateId // ignore: cast_nullable_to_non_nullable
as String?,messageTemplate: freezed == messageTemplate ? _self.messageTemplate : messageTemplate // ignore: cast_nullable_to_non_nullable
as String?,emailSubject: freezed == emailSubject ? _self.emailSubject : emailSubject // ignore: cast_nullable_to_non_nullable
as String?,flagName: freezed == flagName ? _self.flagName : flagName // ignore: cast_nullable_to_non_nullable
as String?,taskTitle: freezed == taskTitle ? _self.taskTitle : taskTitle // ignore: cast_nullable_to_non_nullable
as String?,taskDescription: freezed == taskDescription ? _self.taskDescription : taskDescription // ignore: cast_nullable_to_non_nullable
as String?,taskPriority: null == taskPriority ? _self.taskPriority : taskPriority // ignore: cast_nullable_to_non_nullable
as String,alertRecipients: null == alertRecipients ? _self._alertRecipients : alertRecipients // ignore: cast_nullable_to_non_nullable
as List<String>,delayed: null == delayed ? _self.delayed : delayed // ignore: cast_nullable_to_non_nullable
as bool,delayMinutes: null == delayMinutes ? _self.delayMinutes : delayMinutes // ignore: cast_nullable_to_non_nullable
as int,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}


/// @nodoc
mixin _$AutomationConditions {

/// Restrict to specific days of week (1=Mon, 7=Sun). Empty = all days.
 List<int> get daysOfWeek;/// Restrict to business hours only.
 bool get businessHoursOnly;/// Start hour for business hours (24h format).
 int get businessHoursStart;/// End hour for business hours (24h format).
 int get businessHoursEnd;/// Minimum days until appointment for trigger to fire.
 int get minDaysBeforeAppointment;/// Maximum days until appointment for trigger to fire.
 int get maxDaysBeforeAppointment;/// Exclude clients with these tags.
 List<String> get excludeClientTags;/// Only include clients with these tags.
 List<String> get includeClientTags;/// Exclude specific service IDs.
 List<String> get excludeServiceIds;/// Only include specific service IDs.
 List<String> get includeServiceIds;/// Minimum client lifetime value (cents) to trigger.
 int get minClientLifetimeValue;/// Skip if client already has this flag.
 String? get skipIfHasFlag;/// Skip if payment is already collected.
 bool get skipIfPaymentCollected;
/// Create a copy of AutomationConditions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AutomationConditionsCopyWith<AutomationConditions> get copyWith => _$AutomationConditionsCopyWithImpl<AutomationConditions>(this as AutomationConditions, _$identity);

  /// Serializes this AutomationConditions to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AutomationConditions&&const DeepCollectionEquality().equals(other.daysOfWeek, daysOfWeek)&&(identical(other.businessHoursOnly, businessHoursOnly) || other.businessHoursOnly == businessHoursOnly)&&(identical(other.businessHoursStart, businessHoursStart) || other.businessHoursStart == businessHoursStart)&&(identical(other.businessHoursEnd, businessHoursEnd) || other.businessHoursEnd == businessHoursEnd)&&(identical(other.minDaysBeforeAppointment, minDaysBeforeAppointment) || other.minDaysBeforeAppointment == minDaysBeforeAppointment)&&(identical(other.maxDaysBeforeAppointment, maxDaysBeforeAppointment) || other.maxDaysBeforeAppointment == maxDaysBeforeAppointment)&&const DeepCollectionEquality().equals(other.excludeClientTags, excludeClientTags)&&const DeepCollectionEquality().equals(other.includeClientTags, includeClientTags)&&const DeepCollectionEquality().equals(other.excludeServiceIds, excludeServiceIds)&&const DeepCollectionEquality().equals(other.includeServiceIds, includeServiceIds)&&(identical(other.minClientLifetimeValue, minClientLifetimeValue) || other.minClientLifetimeValue == minClientLifetimeValue)&&(identical(other.skipIfHasFlag, skipIfHasFlag) || other.skipIfHasFlag == skipIfHasFlag)&&(identical(other.skipIfPaymentCollected, skipIfPaymentCollected) || other.skipIfPaymentCollected == skipIfPaymentCollected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(daysOfWeek),businessHoursOnly,businessHoursStart,businessHoursEnd,minDaysBeforeAppointment,maxDaysBeforeAppointment,const DeepCollectionEquality().hash(excludeClientTags),const DeepCollectionEquality().hash(includeClientTags),const DeepCollectionEquality().hash(excludeServiceIds),const DeepCollectionEquality().hash(includeServiceIds),minClientLifetimeValue,skipIfHasFlag,skipIfPaymentCollected);

@override
String toString() {
  return 'AutomationConditions(daysOfWeek: $daysOfWeek, businessHoursOnly: $businessHoursOnly, businessHoursStart: $businessHoursStart, businessHoursEnd: $businessHoursEnd, minDaysBeforeAppointment: $minDaysBeforeAppointment, maxDaysBeforeAppointment: $maxDaysBeforeAppointment, excludeClientTags: $excludeClientTags, includeClientTags: $includeClientTags, excludeServiceIds: $excludeServiceIds, includeServiceIds: $includeServiceIds, minClientLifetimeValue: $minClientLifetimeValue, skipIfHasFlag: $skipIfHasFlag, skipIfPaymentCollected: $skipIfPaymentCollected)';
}


}

/// @nodoc
abstract mixin class $AutomationConditionsCopyWith<$Res>  {
  factory $AutomationConditionsCopyWith(AutomationConditions value, $Res Function(AutomationConditions) _then) = _$AutomationConditionsCopyWithImpl;
@useResult
$Res call({
 List<int> daysOfWeek, bool businessHoursOnly, int businessHoursStart, int businessHoursEnd, int minDaysBeforeAppointment, int maxDaysBeforeAppointment, List<String> excludeClientTags, List<String> includeClientTags, List<String> excludeServiceIds, List<String> includeServiceIds, int minClientLifetimeValue, String? skipIfHasFlag, bool skipIfPaymentCollected
});




}
/// @nodoc
class _$AutomationConditionsCopyWithImpl<$Res>
    implements $AutomationConditionsCopyWith<$Res> {
  _$AutomationConditionsCopyWithImpl(this._self, this._then);

  final AutomationConditions _self;
  final $Res Function(AutomationConditions) _then;

/// Create a copy of AutomationConditions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? daysOfWeek = null,Object? businessHoursOnly = null,Object? businessHoursStart = null,Object? businessHoursEnd = null,Object? minDaysBeforeAppointment = null,Object? maxDaysBeforeAppointment = null,Object? excludeClientTags = null,Object? includeClientTags = null,Object? excludeServiceIds = null,Object? includeServiceIds = null,Object? minClientLifetimeValue = null,Object? skipIfHasFlag = freezed,Object? skipIfPaymentCollected = null,}) {
  return _then(_self.copyWith(
daysOfWeek: null == daysOfWeek ? _self.daysOfWeek : daysOfWeek // ignore: cast_nullable_to_non_nullable
as List<int>,businessHoursOnly: null == businessHoursOnly ? _self.businessHoursOnly : businessHoursOnly // ignore: cast_nullable_to_non_nullable
as bool,businessHoursStart: null == businessHoursStart ? _self.businessHoursStart : businessHoursStart // ignore: cast_nullable_to_non_nullable
as int,businessHoursEnd: null == businessHoursEnd ? _self.businessHoursEnd : businessHoursEnd // ignore: cast_nullable_to_non_nullable
as int,minDaysBeforeAppointment: null == minDaysBeforeAppointment ? _self.minDaysBeforeAppointment : minDaysBeforeAppointment // ignore: cast_nullable_to_non_nullable
as int,maxDaysBeforeAppointment: null == maxDaysBeforeAppointment ? _self.maxDaysBeforeAppointment : maxDaysBeforeAppointment // ignore: cast_nullable_to_non_nullable
as int,excludeClientTags: null == excludeClientTags ? _self.excludeClientTags : excludeClientTags // ignore: cast_nullable_to_non_nullable
as List<String>,includeClientTags: null == includeClientTags ? _self.includeClientTags : includeClientTags // ignore: cast_nullable_to_non_nullable
as List<String>,excludeServiceIds: null == excludeServiceIds ? _self.excludeServiceIds : excludeServiceIds // ignore: cast_nullable_to_non_nullable
as List<String>,includeServiceIds: null == includeServiceIds ? _self.includeServiceIds : includeServiceIds // ignore: cast_nullable_to_non_nullable
as List<String>,minClientLifetimeValue: null == minClientLifetimeValue ? _self.minClientLifetimeValue : minClientLifetimeValue // ignore: cast_nullable_to_non_nullable
as int,skipIfHasFlag: freezed == skipIfHasFlag ? _self.skipIfHasFlag : skipIfHasFlag // ignore: cast_nullable_to_non_nullable
as String?,skipIfPaymentCollected: null == skipIfPaymentCollected ? _self.skipIfPaymentCollected : skipIfPaymentCollected // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AutomationConditions].
extension AutomationConditionsPatterns on AutomationConditions {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AutomationConditions value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AutomationConditions() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AutomationConditions value)  $default,){
final _that = this;
switch (_that) {
case _AutomationConditions():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AutomationConditions value)?  $default,){
final _that = this;
switch (_that) {
case _AutomationConditions() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<int> daysOfWeek,  bool businessHoursOnly,  int businessHoursStart,  int businessHoursEnd,  int minDaysBeforeAppointment,  int maxDaysBeforeAppointment,  List<String> excludeClientTags,  List<String> includeClientTags,  List<String> excludeServiceIds,  List<String> includeServiceIds,  int minClientLifetimeValue,  String? skipIfHasFlag,  bool skipIfPaymentCollected)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AutomationConditions() when $default != null:
return $default(_that.daysOfWeek,_that.businessHoursOnly,_that.businessHoursStart,_that.businessHoursEnd,_that.minDaysBeforeAppointment,_that.maxDaysBeforeAppointment,_that.excludeClientTags,_that.includeClientTags,_that.excludeServiceIds,_that.includeServiceIds,_that.minClientLifetimeValue,_that.skipIfHasFlag,_that.skipIfPaymentCollected);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<int> daysOfWeek,  bool businessHoursOnly,  int businessHoursStart,  int businessHoursEnd,  int minDaysBeforeAppointment,  int maxDaysBeforeAppointment,  List<String> excludeClientTags,  List<String> includeClientTags,  List<String> excludeServiceIds,  List<String> includeServiceIds,  int minClientLifetimeValue,  String? skipIfHasFlag,  bool skipIfPaymentCollected)  $default,) {final _that = this;
switch (_that) {
case _AutomationConditions():
return $default(_that.daysOfWeek,_that.businessHoursOnly,_that.businessHoursStart,_that.businessHoursEnd,_that.minDaysBeforeAppointment,_that.maxDaysBeforeAppointment,_that.excludeClientTags,_that.includeClientTags,_that.excludeServiceIds,_that.includeServiceIds,_that.minClientLifetimeValue,_that.skipIfHasFlag,_that.skipIfPaymentCollected);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<int> daysOfWeek,  bool businessHoursOnly,  int businessHoursStart,  int businessHoursEnd,  int minDaysBeforeAppointment,  int maxDaysBeforeAppointment,  List<String> excludeClientTags,  List<String> includeClientTags,  List<String> excludeServiceIds,  List<String> includeServiceIds,  int minClientLifetimeValue,  String? skipIfHasFlag,  bool skipIfPaymentCollected)?  $default,) {final _that = this;
switch (_that) {
case _AutomationConditions() when $default != null:
return $default(_that.daysOfWeek,_that.businessHoursOnly,_that.businessHoursStart,_that.businessHoursEnd,_that.minDaysBeforeAppointment,_that.maxDaysBeforeAppointment,_that.excludeClientTags,_that.includeClientTags,_that.excludeServiceIds,_that.includeServiceIds,_that.minClientLifetimeValue,_that.skipIfHasFlag,_that.skipIfPaymentCollected);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AutomationConditions extends AutomationConditions {
  const _AutomationConditions({final  List<int> daysOfWeek = const [], this.businessHoursOnly = true, this.businessHoursStart = 8, this.businessHoursEnd = 18, this.minDaysBeforeAppointment = 0, this.maxDaysBeforeAppointment = 30, final  List<String> excludeClientTags = const [], final  List<String> includeClientTags = const [], final  List<String> excludeServiceIds = const [], final  List<String> includeServiceIds = const [], this.minClientLifetimeValue = 0, this.skipIfHasFlag, this.skipIfPaymentCollected = false}): _daysOfWeek = daysOfWeek,_excludeClientTags = excludeClientTags,_includeClientTags = includeClientTags,_excludeServiceIds = excludeServiceIds,_includeServiceIds = includeServiceIds,super._();
  factory _AutomationConditions.fromJson(Map<String, dynamic> json) => _$AutomationConditionsFromJson(json);

/// Restrict to specific days of week (1=Mon, 7=Sun). Empty = all days.
 final  List<int> _daysOfWeek;
/// Restrict to specific days of week (1=Mon, 7=Sun). Empty = all days.
@override@JsonKey() List<int> get daysOfWeek {
  if (_daysOfWeek is EqualUnmodifiableListView) return _daysOfWeek;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_daysOfWeek);
}

/// Restrict to business hours only.
@override@JsonKey() final  bool businessHoursOnly;
/// Start hour for business hours (24h format).
@override@JsonKey() final  int businessHoursStart;
/// End hour for business hours (24h format).
@override@JsonKey() final  int businessHoursEnd;
/// Minimum days until appointment for trigger to fire.
@override@JsonKey() final  int minDaysBeforeAppointment;
/// Maximum days until appointment for trigger to fire.
@override@JsonKey() final  int maxDaysBeforeAppointment;
/// Exclude clients with these tags.
 final  List<String> _excludeClientTags;
/// Exclude clients with these tags.
@override@JsonKey() List<String> get excludeClientTags {
  if (_excludeClientTags is EqualUnmodifiableListView) return _excludeClientTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_excludeClientTags);
}

/// Only include clients with these tags.
 final  List<String> _includeClientTags;
/// Only include clients with these tags.
@override@JsonKey() List<String> get includeClientTags {
  if (_includeClientTags is EqualUnmodifiableListView) return _includeClientTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_includeClientTags);
}

/// Exclude specific service IDs.
 final  List<String> _excludeServiceIds;
/// Exclude specific service IDs.
@override@JsonKey() List<String> get excludeServiceIds {
  if (_excludeServiceIds is EqualUnmodifiableListView) return _excludeServiceIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_excludeServiceIds);
}

/// Only include specific service IDs.
 final  List<String> _includeServiceIds;
/// Only include specific service IDs.
@override@JsonKey() List<String> get includeServiceIds {
  if (_includeServiceIds is EqualUnmodifiableListView) return _includeServiceIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_includeServiceIds);
}

/// Minimum client lifetime value (cents) to trigger.
@override@JsonKey() final  int minClientLifetimeValue;
/// Skip if client already has this flag.
@override final  String? skipIfHasFlag;
/// Skip if payment is already collected.
@override@JsonKey() final  bool skipIfPaymentCollected;

/// Create a copy of AutomationConditions
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AutomationConditionsCopyWith<_AutomationConditions> get copyWith => __$AutomationConditionsCopyWithImpl<_AutomationConditions>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AutomationConditionsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AutomationConditions&&const DeepCollectionEquality().equals(other._daysOfWeek, _daysOfWeek)&&(identical(other.businessHoursOnly, businessHoursOnly) || other.businessHoursOnly == businessHoursOnly)&&(identical(other.businessHoursStart, businessHoursStart) || other.businessHoursStart == businessHoursStart)&&(identical(other.businessHoursEnd, businessHoursEnd) || other.businessHoursEnd == businessHoursEnd)&&(identical(other.minDaysBeforeAppointment, minDaysBeforeAppointment) || other.minDaysBeforeAppointment == minDaysBeforeAppointment)&&(identical(other.maxDaysBeforeAppointment, maxDaysBeforeAppointment) || other.maxDaysBeforeAppointment == maxDaysBeforeAppointment)&&const DeepCollectionEquality().equals(other._excludeClientTags, _excludeClientTags)&&const DeepCollectionEquality().equals(other._includeClientTags, _includeClientTags)&&const DeepCollectionEquality().equals(other._excludeServiceIds, _excludeServiceIds)&&const DeepCollectionEquality().equals(other._includeServiceIds, _includeServiceIds)&&(identical(other.minClientLifetimeValue, minClientLifetimeValue) || other.minClientLifetimeValue == minClientLifetimeValue)&&(identical(other.skipIfHasFlag, skipIfHasFlag) || other.skipIfHasFlag == skipIfHasFlag)&&(identical(other.skipIfPaymentCollected, skipIfPaymentCollected) || other.skipIfPaymentCollected == skipIfPaymentCollected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_daysOfWeek),businessHoursOnly,businessHoursStart,businessHoursEnd,minDaysBeforeAppointment,maxDaysBeforeAppointment,const DeepCollectionEquality().hash(_excludeClientTags),const DeepCollectionEquality().hash(_includeClientTags),const DeepCollectionEquality().hash(_excludeServiceIds),const DeepCollectionEquality().hash(_includeServiceIds),minClientLifetimeValue,skipIfHasFlag,skipIfPaymentCollected);

@override
String toString() {
  return 'AutomationConditions(daysOfWeek: $daysOfWeek, businessHoursOnly: $businessHoursOnly, businessHoursStart: $businessHoursStart, businessHoursEnd: $businessHoursEnd, minDaysBeforeAppointment: $minDaysBeforeAppointment, maxDaysBeforeAppointment: $maxDaysBeforeAppointment, excludeClientTags: $excludeClientTags, includeClientTags: $includeClientTags, excludeServiceIds: $excludeServiceIds, includeServiceIds: $includeServiceIds, minClientLifetimeValue: $minClientLifetimeValue, skipIfHasFlag: $skipIfHasFlag, skipIfPaymentCollected: $skipIfPaymentCollected)';
}


}

/// @nodoc
abstract mixin class _$AutomationConditionsCopyWith<$Res> implements $AutomationConditionsCopyWith<$Res> {
  factory _$AutomationConditionsCopyWith(_AutomationConditions value, $Res Function(_AutomationConditions) _then) = __$AutomationConditionsCopyWithImpl;
@override @useResult
$Res call({
 List<int> daysOfWeek, bool businessHoursOnly, int businessHoursStart, int businessHoursEnd, int minDaysBeforeAppointment, int maxDaysBeforeAppointment, List<String> excludeClientTags, List<String> includeClientTags, List<String> excludeServiceIds, List<String> includeServiceIds, int minClientLifetimeValue, String? skipIfHasFlag, bool skipIfPaymentCollected
});




}
/// @nodoc
class __$AutomationConditionsCopyWithImpl<$Res>
    implements _$AutomationConditionsCopyWith<$Res> {
  __$AutomationConditionsCopyWithImpl(this._self, this._then);

  final _AutomationConditions _self;
  final $Res Function(_AutomationConditions) _then;

/// Create a copy of AutomationConditions
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? daysOfWeek = null,Object? businessHoursOnly = null,Object? businessHoursStart = null,Object? businessHoursEnd = null,Object? minDaysBeforeAppointment = null,Object? maxDaysBeforeAppointment = null,Object? excludeClientTags = null,Object? includeClientTags = null,Object? excludeServiceIds = null,Object? includeServiceIds = null,Object? minClientLifetimeValue = null,Object? skipIfHasFlag = freezed,Object? skipIfPaymentCollected = null,}) {
  return _then(_AutomationConditions(
daysOfWeek: null == daysOfWeek ? _self._daysOfWeek : daysOfWeek // ignore: cast_nullable_to_non_nullable
as List<int>,businessHoursOnly: null == businessHoursOnly ? _self.businessHoursOnly : businessHoursOnly // ignore: cast_nullable_to_non_nullable
as bool,businessHoursStart: null == businessHoursStart ? _self.businessHoursStart : businessHoursStart // ignore: cast_nullable_to_non_nullable
as int,businessHoursEnd: null == businessHoursEnd ? _self.businessHoursEnd : businessHoursEnd // ignore: cast_nullable_to_non_nullable
as int,minDaysBeforeAppointment: null == minDaysBeforeAppointment ? _self.minDaysBeforeAppointment : minDaysBeforeAppointment // ignore: cast_nullable_to_non_nullable
as int,maxDaysBeforeAppointment: null == maxDaysBeforeAppointment ? _self.maxDaysBeforeAppointment : maxDaysBeforeAppointment // ignore: cast_nullable_to_non_nullable
as int,excludeClientTags: null == excludeClientTags ? _self._excludeClientTags : excludeClientTags // ignore: cast_nullable_to_non_nullable
as List<String>,includeClientTags: null == includeClientTags ? _self._includeClientTags : includeClientTags // ignore: cast_nullable_to_non_nullable
as List<String>,excludeServiceIds: null == excludeServiceIds ? _self._excludeServiceIds : excludeServiceIds // ignore: cast_nullable_to_non_nullable
as List<String>,includeServiceIds: null == includeServiceIds ? _self._includeServiceIds : includeServiceIds // ignore: cast_nullable_to_non_nullable
as List<String>,minClientLifetimeValue: null == minClientLifetimeValue ? _self.minClientLifetimeValue : minClientLifetimeValue // ignore: cast_nullable_to_non_nullable
as int,skipIfHasFlag: freezed == skipIfHasFlag ? _self.skipIfHasFlag : skipIfHasFlag // ignore: cast_nullable_to_non_nullable
as String?,skipIfPaymentCollected: null == skipIfPaymentCollected ? _self.skipIfPaymentCollected : skipIfPaymentCollected // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$AutomationCooldown {

/// Cooldown period in minutes per client.
 int get perClientMinutes;// 24 hours default
/// Cooldown period in minutes per appointment.
 int get perAppointmentMinutes;// 1 hour default
/// Maximum triggers per client per day.
 int get maxTriggersPerClientPerDay;/// Maximum triggers per rule per day (across all clients).
 int get maxTriggersPerRulePerDay;
/// Create a copy of AutomationCooldown
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AutomationCooldownCopyWith<AutomationCooldown> get copyWith => _$AutomationCooldownCopyWithImpl<AutomationCooldown>(this as AutomationCooldown, _$identity);

  /// Serializes this AutomationCooldown to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AutomationCooldown&&(identical(other.perClientMinutes, perClientMinutes) || other.perClientMinutes == perClientMinutes)&&(identical(other.perAppointmentMinutes, perAppointmentMinutes) || other.perAppointmentMinutes == perAppointmentMinutes)&&(identical(other.maxTriggersPerClientPerDay, maxTriggersPerClientPerDay) || other.maxTriggersPerClientPerDay == maxTriggersPerClientPerDay)&&(identical(other.maxTriggersPerRulePerDay, maxTriggersPerRulePerDay) || other.maxTriggersPerRulePerDay == maxTriggersPerRulePerDay));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,perClientMinutes,perAppointmentMinutes,maxTriggersPerClientPerDay,maxTriggersPerRulePerDay);

@override
String toString() {
  return 'AutomationCooldown(perClientMinutes: $perClientMinutes, perAppointmentMinutes: $perAppointmentMinutes, maxTriggersPerClientPerDay: $maxTriggersPerClientPerDay, maxTriggersPerRulePerDay: $maxTriggersPerRulePerDay)';
}


}

/// @nodoc
abstract mixin class $AutomationCooldownCopyWith<$Res>  {
  factory $AutomationCooldownCopyWith(AutomationCooldown value, $Res Function(AutomationCooldown) _then) = _$AutomationCooldownCopyWithImpl;
@useResult
$Res call({
 int perClientMinutes, int perAppointmentMinutes, int maxTriggersPerClientPerDay, int maxTriggersPerRulePerDay
});




}
/// @nodoc
class _$AutomationCooldownCopyWithImpl<$Res>
    implements $AutomationCooldownCopyWith<$Res> {
  _$AutomationCooldownCopyWithImpl(this._self, this._then);

  final AutomationCooldown _self;
  final $Res Function(AutomationCooldown) _then;

/// Create a copy of AutomationCooldown
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? perClientMinutes = null,Object? perAppointmentMinutes = null,Object? maxTriggersPerClientPerDay = null,Object? maxTriggersPerRulePerDay = null,}) {
  return _then(_self.copyWith(
perClientMinutes: null == perClientMinutes ? _self.perClientMinutes : perClientMinutes // ignore: cast_nullable_to_non_nullable
as int,perAppointmentMinutes: null == perAppointmentMinutes ? _self.perAppointmentMinutes : perAppointmentMinutes // ignore: cast_nullable_to_non_nullable
as int,maxTriggersPerClientPerDay: null == maxTriggersPerClientPerDay ? _self.maxTriggersPerClientPerDay : maxTriggersPerClientPerDay // ignore: cast_nullable_to_non_nullable
as int,maxTriggersPerRulePerDay: null == maxTriggersPerRulePerDay ? _self.maxTriggersPerRulePerDay : maxTriggersPerRulePerDay // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AutomationCooldown].
extension AutomationCooldownPatterns on AutomationCooldown {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AutomationCooldown value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AutomationCooldown() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AutomationCooldown value)  $default,){
final _that = this;
switch (_that) {
case _AutomationCooldown():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AutomationCooldown value)?  $default,){
final _that = this;
switch (_that) {
case _AutomationCooldown() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int perClientMinutes,  int perAppointmentMinutes,  int maxTriggersPerClientPerDay,  int maxTriggersPerRulePerDay)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AutomationCooldown() when $default != null:
return $default(_that.perClientMinutes,_that.perAppointmentMinutes,_that.maxTriggersPerClientPerDay,_that.maxTriggersPerRulePerDay);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int perClientMinutes,  int perAppointmentMinutes,  int maxTriggersPerClientPerDay,  int maxTriggersPerRulePerDay)  $default,) {final _that = this;
switch (_that) {
case _AutomationCooldown():
return $default(_that.perClientMinutes,_that.perAppointmentMinutes,_that.maxTriggersPerClientPerDay,_that.maxTriggersPerRulePerDay);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int perClientMinutes,  int perAppointmentMinutes,  int maxTriggersPerClientPerDay,  int maxTriggersPerRulePerDay)?  $default,) {final _that = this;
switch (_that) {
case _AutomationCooldown() when $default != null:
return $default(_that.perClientMinutes,_that.perAppointmentMinutes,_that.maxTriggersPerClientPerDay,_that.maxTriggersPerRulePerDay);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AutomationCooldown implements AutomationCooldown {
  const _AutomationCooldown({this.perClientMinutes = 1440, this.perAppointmentMinutes = 60, this.maxTriggersPerClientPerDay = 3, this.maxTriggersPerRulePerDay = 100});
  factory _AutomationCooldown.fromJson(Map<String, dynamic> json) => _$AutomationCooldownFromJson(json);

/// Cooldown period in minutes per client.
@override@JsonKey() final  int perClientMinutes;
// 24 hours default
/// Cooldown period in minutes per appointment.
@override@JsonKey() final  int perAppointmentMinutes;
// 1 hour default
/// Maximum triggers per client per day.
@override@JsonKey() final  int maxTriggersPerClientPerDay;
/// Maximum triggers per rule per day (across all clients).
@override@JsonKey() final  int maxTriggersPerRulePerDay;

/// Create a copy of AutomationCooldown
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AutomationCooldownCopyWith<_AutomationCooldown> get copyWith => __$AutomationCooldownCopyWithImpl<_AutomationCooldown>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AutomationCooldownToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AutomationCooldown&&(identical(other.perClientMinutes, perClientMinutes) || other.perClientMinutes == perClientMinutes)&&(identical(other.perAppointmentMinutes, perAppointmentMinutes) || other.perAppointmentMinutes == perAppointmentMinutes)&&(identical(other.maxTriggersPerClientPerDay, maxTriggersPerClientPerDay) || other.maxTriggersPerClientPerDay == maxTriggersPerClientPerDay)&&(identical(other.maxTriggersPerRulePerDay, maxTriggersPerRulePerDay) || other.maxTriggersPerRulePerDay == maxTriggersPerRulePerDay));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,perClientMinutes,perAppointmentMinutes,maxTriggersPerClientPerDay,maxTriggersPerRulePerDay);

@override
String toString() {
  return 'AutomationCooldown(perClientMinutes: $perClientMinutes, perAppointmentMinutes: $perAppointmentMinutes, maxTriggersPerClientPerDay: $maxTriggersPerClientPerDay, maxTriggersPerRulePerDay: $maxTriggersPerRulePerDay)';
}


}

/// @nodoc
abstract mixin class _$AutomationCooldownCopyWith<$Res> implements $AutomationCooldownCopyWith<$Res> {
  factory _$AutomationCooldownCopyWith(_AutomationCooldown value, $Res Function(_AutomationCooldown) _then) = __$AutomationCooldownCopyWithImpl;
@override @useResult
$Res call({
 int perClientMinutes, int perAppointmentMinutes, int maxTriggersPerClientPerDay, int maxTriggersPerRulePerDay
});




}
/// @nodoc
class __$AutomationCooldownCopyWithImpl<$Res>
    implements _$AutomationCooldownCopyWith<$Res> {
  __$AutomationCooldownCopyWithImpl(this._self, this._then);

  final _AutomationCooldown _self;
  final $Res Function(_AutomationCooldown) _then;

/// Create a copy of AutomationCooldown
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? perClientMinutes = null,Object? perAppointmentMinutes = null,Object? maxTriggersPerClientPerDay = null,Object? maxTriggersPerRulePerDay = null,}) {
  return _then(_AutomationCooldown(
perClientMinutes: null == perClientMinutes ? _self.perClientMinutes : perClientMinutes // ignore: cast_nullable_to_non_nullable
as int,perAppointmentMinutes: null == perAppointmentMinutes ? _self.perAppointmentMinutes : perAppointmentMinutes // ignore: cast_nullable_to_non_nullable
as int,maxTriggersPerClientPerDay: null == maxTriggersPerClientPerDay ? _self.maxTriggersPerClientPerDay : maxTriggersPerClientPerDay // ignore: cast_nullable_to_non_nullable
as int,maxTriggersPerRulePerDay: null == maxTriggersPerRulePerDay ? _self.maxTriggersPerRulePerDay : maxTriggersPerRulePerDay // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$AutomationRule {

/// Unique rule identifier.
 String get id;/// Business ID (multi-tenant isolation).
 String get businessId;/// Human-readable rule name.
 String get name;/// Optional description of what the rule does.
 String? get description;/// Whether the rule is currently active.
 bool get isEnabled;/// Priority for rule execution order.
 AutomationPriority get priority;/// Trigger configuration.
 AutomationTriggerConfig get trigger;/// Actions to execute when triggered.
 List<AutomationActionConfig> get actions;/// Conditions that must be met.
 AutomationConditions get conditions;/// Cooldown settings to prevent spam.
 AutomationCooldown get cooldown;/// When the rule was last triggered.
 DateTime? get lastTriggeredAt;/// Total number of times the rule has triggered.
 int get triggerCount;/// Number of successful action executions.
 int get successCount;/// Number of failed action executions.
 int get failureCount;/// When the rule was created.
 DateTime get createdAt;/// When the rule was last updated.
 DateTime? get updatedAt;/// User ID who created the rule.
 String get createdBy;/// User ID who last updated the rule.
 String? get updatedBy;/// Version number for optimistic locking.
 int get version;
/// Create a copy of AutomationRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AutomationRuleCopyWith<AutomationRule> get copyWith => _$AutomationRuleCopyWithImpl<AutomationRule>(this as AutomationRule, _$identity);

  /// Serializes this AutomationRule to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AutomationRule&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.trigger, trigger) || other.trigger == trigger)&&const DeepCollectionEquality().equals(other.actions, actions)&&(identical(other.conditions, conditions) || other.conditions == conditions)&&(identical(other.cooldown, cooldown) || other.cooldown == cooldown)&&(identical(other.lastTriggeredAt, lastTriggeredAt) || other.lastTriggeredAt == lastTriggeredAt)&&(identical(other.triggerCount, triggerCount) || other.triggerCount == triggerCount)&&(identical(other.successCount, successCount) || other.successCount == successCount)&&(identical(other.failureCount, failureCount) || other.failureCount == failureCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.version, version) || other.version == version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,businessId,name,description,isEnabled,priority,trigger,const DeepCollectionEquality().hash(actions),conditions,cooldown,lastTriggeredAt,triggerCount,successCount,failureCount,createdAt,updatedAt,createdBy,updatedBy,version]);

@override
String toString() {
  return 'AutomationRule(id: $id, businessId: $businessId, name: $name, description: $description, isEnabled: $isEnabled, priority: $priority, trigger: $trigger, actions: $actions, conditions: $conditions, cooldown: $cooldown, lastTriggeredAt: $lastTriggeredAt, triggerCount: $triggerCount, successCount: $successCount, failureCount: $failureCount, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, updatedBy: $updatedBy, version: $version)';
}


}

/// @nodoc
abstract mixin class $AutomationRuleCopyWith<$Res>  {
  factory $AutomationRuleCopyWith(AutomationRule value, $Res Function(AutomationRule) _then) = _$AutomationRuleCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String name, String? description, bool isEnabled, AutomationPriority priority, AutomationTriggerConfig trigger, List<AutomationActionConfig> actions, AutomationConditions conditions, AutomationCooldown cooldown, DateTime? lastTriggeredAt, int triggerCount, int successCount, int failureCount, DateTime createdAt, DateTime? updatedAt, String createdBy, String? updatedBy, int version
});


$AutomationTriggerConfigCopyWith<$Res> get trigger;$AutomationConditionsCopyWith<$Res> get conditions;$AutomationCooldownCopyWith<$Res> get cooldown;

}
/// @nodoc
class _$AutomationRuleCopyWithImpl<$Res>
    implements $AutomationRuleCopyWith<$Res> {
  _$AutomationRuleCopyWithImpl(this._self, this._then);

  final AutomationRule _self;
  final $Res Function(AutomationRule) _then;

/// Create a copy of AutomationRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? name = null,Object? description = freezed,Object? isEnabled = null,Object? priority = null,Object? trigger = null,Object? actions = null,Object? conditions = null,Object? cooldown = null,Object? lastTriggeredAt = freezed,Object? triggerCount = null,Object? successCount = null,Object? failureCount = null,Object? createdAt = null,Object? updatedAt = freezed,Object? createdBy = null,Object? updatedBy = freezed,Object? version = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as AutomationPriority,trigger: null == trigger ? _self.trigger : trigger // ignore: cast_nullable_to_non_nullable
as AutomationTriggerConfig,actions: null == actions ? _self.actions : actions // ignore: cast_nullable_to_non_nullable
as List<AutomationActionConfig>,conditions: null == conditions ? _self.conditions : conditions // ignore: cast_nullable_to_non_nullable
as AutomationConditions,cooldown: null == cooldown ? _self.cooldown : cooldown // ignore: cast_nullable_to_non_nullable
as AutomationCooldown,lastTriggeredAt: freezed == lastTriggeredAt ? _self.lastTriggeredAt : lastTriggeredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,triggerCount: null == triggerCount ? _self.triggerCount : triggerCount // ignore: cast_nullable_to_non_nullable
as int,successCount: null == successCount ? _self.successCount : successCount // ignore: cast_nullable_to_non_nullable
as int,failureCount: null == failureCount ? _self.failureCount : failureCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedBy: freezed == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String?,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of AutomationRule
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AutomationTriggerConfigCopyWith<$Res> get trigger {
  
  return $AutomationTriggerConfigCopyWith<$Res>(_self.trigger, (value) {
    return _then(_self.copyWith(trigger: value));
  });
}/// Create a copy of AutomationRule
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AutomationConditionsCopyWith<$Res> get conditions {
  
  return $AutomationConditionsCopyWith<$Res>(_self.conditions, (value) {
    return _then(_self.copyWith(conditions: value));
  });
}/// Create a copy of AutomationRule
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AutomationCooldownCopyWith<$Res> get cooldown {
  
  return $AutomationCooldownCopyWith<$Res>(_self.cooldown, (value) {
    return _then(_self.copyWith(cooldown: value));
  });
}
}


/// Adds pattern-matching-related methods to [AutomationRule].
extension AutomationRulePatterns on AutomationRule {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AutomationRule value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AutomationRule() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AutomationRule value)  $default,){
final _that = this;
switch (_that) {
case _AutomationRule():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AutomationRule value)?  $default,){
final _that = this;
switch (_that) {
case _AutomationRule() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String name,  String? description,  bool isEnabled,  AutomationPriority priority,  AutomationTriggerConfig trigger,  List<AutomationActionConfig> actions,  AutomationConditions conditions,  AutomationCooldown cooldown,  DateTime? lastTriggeredAt,  int triggerCount,  int successCount,  int failureCount,  DateTime createdAt,  DateTime? updatedAt,  String createdBy,  String? updatedBy,  int version)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AutomationRule() when $default != null:
return $default(_that.id,_that.businessId,_that.name,_that.description,_that.isEnabled,_that.priority,_that.trigger,_that.actions,_that.conditions,_that.cooldown,_that.lastTriggeredAt,_that.triggerCount,_that.successCount,_that.failureCount,_that.createdAt,_that.updatedAt,_that.createdBy,_that.updatedBy,_that.version);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String name,  String? description,  bool isEnabled,  AutomationPriority priority,  AutomationTriggerConfig trigger,  List<AutomationActionConfig> actions,  AutomationConditions conditions,  AutomationCooldown cooldown,  DateTime? lastTriggeredAt,  int triggerCount,  int successCount,  int failureCount,  DateTime createdAt,  DateTime? updatedAt,  String createdBy,  String? updatedBy,  int version)  $default,) {final _that = this;
switch (_that) {
case _AutomationRule():
return $default(_that.id,_that.businessId,_that.name,_that.description,_that.isEnabled,_that.priority,_that.trigger,_that.actions,_that.conditions,_that.cooldown,_that.lastTriggeredAt,_that.triggerCount,_that.successCount,_that.failureCount,_that.createdAt,_that.updatedAt,_that.createdBy,_that.updatedBy,_that.version);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String name,  String? description,  bool isEnabled,  AutomationPriority priority,  AutomationTriggerConfig trigger,  List<AutomationActionConfig> actions,  AutomationConditions conditions,  AutomationCooldown cooldown,  DateTime? lastTriggeredAt,  int triggerCount,  int successCount,  int failureCount,  DateTime createdAt,  DateTime? updatedAt,  String createdBy,  String? updatedBy,  int version)?  $default,) {final _that = this;
switch (_that) {
case _AutomationRule() when $default != null:
return $default(_that.id,_that.businessId,_that.name,_that.description,_that.isEnabled,_that.priority,_that.trigger,_that.actions,_that.conditions,_that.cooldown,_that.lastTriggeredAt,_that.triggerCount,_that.successCount,_that.failureCount,_that.createdAt,_that.updatedAt,_that.createdBy,_that.updatedBy,_that.version);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AutomationRule extends AutomationRule {
  const _AutomationRule({required this.id, required this.businessId, required this.name, this.description, this.isEnabled = true, this.priority = AutomationPriority.medium, required this.trigger, required final  List<AutomationActionConfig> actions, this.conditions = const AutomationConditions(), this.cooldown = const AutomationCooldown(), this.lastTriggeredAt, this.triggerCount = 0, this.successCount = 0, this.failureCount = 0, required this.createdAt, this.updatedAt, required this.createdBy, this.updatedBy, this.version = 1}): _actions = actions,super._();
  factory _AutomationRule.fromJson(Map<String, dynamic> json) => _$AutomationRuleFromJson(json);

/// Unique rule identifier.
@override final  String id;
/// Business ID (multi-tenant isolation).
@override final  String businessId;
/// Human-readable rule name.
@override final  String name;
/// Optional description of what the rule does.
@override final  String? description;
/// Whether the rule is currently active.
@override@JsonKey() final  bool isEnabled;
/// Priority for rule execution order.
@override@JsonKey() final  AutomationPriority priority;
/// Trigger configuration.
@override final  AutomationTriggerConfig trigger;
/// Actions to execute when triggered.
 final  List<AutomationActionConfig> _actions;
/// Actions to execute when triggered.
@override List<AutomationActionConfig> get actions {
  if (_actions is EqualUnmodifiableListView) return _actions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_actions);
}

/// Conditions that must be met.
@override@JsonKey() final  AutomationConditions conditions;
/// Cooldown settings to prevent spam.
@override@JsonKey() final  AutomationCooldown cooldown;
/// When the rule was last triggered.
@override final  DateTime? lastTriggeredAt;
/// Total number of times the rule has triggered.
@override@JsonKey() final  int triggerCount;
/// Number of successful action executions.
@override@JsonKey() final  int successCount;
/// Number of failed action executions.
@override@JsonKey() final  int failureCount;
/// When the rule was created.
@override final  DateTime createdAt;
/// When the rule was last updated.
@override final  DateTime? updatedAt;
/// User ID who created the rule.
@override final  String createdBy;
/// User ID who last updated the rule.
@override final  String? updatedBy;
/// Version number for optimistic locking.
@override@JsonKey() final  int version;

/// Create a copy of AutomationRule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AutomationRuleCopyWith<_AutomationRule> get copyWith => __$AutomationRuleCopyWithImpl<_AutomationRule>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AutomationRuleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AutomationRule&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.trigger, trigger) || other.trigger == trigger)&&const DeepCollectionEquality().equals(other._actions, _actions)&&(identical(other.conditions, conditions) || other.conditions == conditions)&&(identical(other.cooldown, cooldown) || other.cooldown == cooldown)&&(identical(other.lastTriggeredAt, lastTriggeredAt) || other.lastTriggeredAt == lastTriggeredAt)&&(identical(other.triggerCount, triggerCount) || other.triggerCount == triggerCount)&&(identical(other.successCount, successCount) || other.successCount == successCount)&&(identical(other.failureCount, failureCount) || other.failureCount == failureCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.version, version) || other.version == version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,businessId,name,description,isEnabled,priority,trigger,const DeepCollectionEquality().hash(_actions),conditions,cooldown,lastTriggeredAt,triggerCount,successCount,failureCount,createdAt,updatedAt,createdBy,updatedBy,version]);

@override
String toString() {
  return 'AutomationRule(id: $id, businessId: $businessId, name: $name, description: $description, isEnabled: $isEnabled, priority: $priority, trigger: $trigger, actions: $actions, conditions: $conditions, cooldown: $cooldown, lastTriggeredAt: $lastTriggeredAt, triggerCount: $triggerCount, successCount: $successCount, failureCount: $failureCount, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, updatedBy: $updatedBy, version: $version)';
}


}

/// @nodoc
abstract mixin class _$AutomationRuleCopyWith<$Res> implements $AutomationRuleCopyWith<$Res> {
  factory _$AutomationRuleCopyWith(_AutomationRule value, $Res Function(_AutomationRule) _then) = __$AutomationRuleCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String name, String? description, bool isEnabled, AutomationPriority priority, AutomationTriggerConfig trigger, List<AutomationActionConfig> actions, AutomationConditions conditions, AutomationCooldown cooldown, DateTime? lastTriggeredAt, int triggerCount, int successCount, int failureCount, DateTime createdAt, DateTime? updatedAt, String createdBy, String? updatedBy, int version
});


@override $AutomationTriggerConfigCopyWith<$Res> get trigger;@override $AutomationConditionsCopyWith<$Res> get conditions;@override $AutomationCooldownCopyWith<$Res> get cooldown;

}
/// @nodoc
class __$AutomationRuleCopyWithImpl<$Res>
    implements _$AutomationRuleCopyWith<$Res> {
  __$AutomationRuleCopyWithImpl(this._self, this._then);

  final _AutomationRule _self;
  final $Res Function(_AutomationRule) _then;

/// Create a copy of AutomationRule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? name = null,Object? description = freezed,Object? isEnabled = null,Object? priority = null,Object? trigger = null,Object? actions = null,Object? conditions = null,Object? cooldown = null,Object? lastTriggeredAt = freezed,Object? triggerCount = null,Object? successCount = null,Object? failureCount = null,Object? createdAt = null,Object? updatedAt = freezed,Object? createdBy = null,Object? updatedBy = freezed,Object? version = null,}) {
  return _then(_AutomationRule(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as AutomationPriority,trigger: null == trigger ? _self.trigger : trigger // ignore: cast_nullable_to_non_nullable
as AutomationTriggerConfig,actions: null == actions ? _self._actions : actions // ignore: cast_nullable_to_non_nullable
as List<AutomationActionConfig>,conditions: null == conditions ? _self.conditions : conditions // ignore: cast_nullable_to_non_nullable
as AutomationConditions,cooldown: null == cooldown ? _self.cooldown : cooldown // ignore: cast_nullable_to_non_nullable
as AutomationCooldown,lastTriggeredAt: freezed == lastTriggeredAt ? _self.lastTriggeredAt : lastTriggeredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,triggerCount: null == triggerCount ? _self.triggerCount : triggerCount // ignore: cast_nullable_to_non_nullable
as int,successCount: null == successCount ? _self.successCount : successCount // ignore: cast_nullable_to_non_nullable
as int,failureCount: null == failureCount ? _self.failureCount : failureCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedBy: freezed == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String?,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of AutomationRule
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AutomationTriggerConfigCopyWith<$Res> get trigger {
  
  return $AutomationTriggerConfigCopyWith<$Res>(_self.trigger, (value) {
    return _then(_self.copyWith(trigger: value));
  });
}/// Create a copy of AutomationRule
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AutomationConditionsCopyWith<$Res> get conditions {
  
  return $AutomationConditionsCopyWith<$Res>(_self.conditions, (value) {
    return _then(_self.copyWith(conditions: value));
  });
}/// Create a copy of AutomationRule
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AutomationCooldownCopyWith<$Res> get cooldown {
  
  return $AutomationCooldownCopyWith<$Res>(_self.cooldown, (value) {
    return _then(_self.copyWith(cooldown: value));
  });
}
}


/// @nodoc
mixin _$TriggerEvaluationResult {

/// Whether the trigger should fire.
 bool get shouldFire;/// The value that was evaluated.
 double get evaluatedValue;/// The threshold that was compared against.
 double get threshold;/// Confidence level of the evaluation.
 double get confidence;/// Reason for the result (useful for logging).
 String get reason;/// Additional context data.
 Map<String, dynamic> get context;
/// Create a copy of TriggerEvaluationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TriggerEvaluationResultCopyWith<TriggerEvaluationResult> get copyWith => _$TriggerEvaluationResultCopyWithImpl<TriggerEvaluationResult>(this as TriggerEvaluationResult, _$identity);

  /// Serializes this TriggerEvaluationResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TriggerEvaluationResult&&(identical(other.shouldFire, shouldFire) || other.shouldFire == shouldFire)&&(identical(other.evaluatedValue, evaluatedValue) || other.evaluatedValue == evaluatedValue)&&(identical(other.threshold, threshold) || other.threshold == threshold)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.reason, reason) || other.reason == reason)&&const DeepCollectionEquality().equals(other.context, context));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,shouldFire,evaluatedValue,threshold,confidence,reason,const DeepCollectionEquality().hash(context));

@override
String toString() {
  return 'TriggerEvaluationResult(shouldFire: $shouldFire, evaluatedValue: $evaluatedValue, threshold: $threshold, confidence: $confidence, reason: $reason, context: $context)';
}


}

/// @nodoc
abstract mixin class $TriggerEvaluationResultCopyWith<$Res>  {
  factory $TriggerEvaluationResultCopyWith(TriggerEvaluationResult value, $Res Function(TriggerEvaluationResult) _then) = _$TriggerEvaluationResultCopyWithImpl;
@useResult
$Res call({
 bool shouldFire, double evaluatedValue, double threshold, double confidence, String reason, Map<String, dynamic> context
});




}
/// @nodoc
class _$TriggerEvaluationResultCopyWithImpl<$Res>
    implements $TriggerEvaluationResultCopyWith<$Res> {
  _$TriggerEvaluationResultCopyWithImpl(this._self, this._then);

  final TriggerEvaluationResult _self;
  final $Res Function(TriggerEvaluationResult) _then;

/// Create a copy of TriggerEvaluationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? shouldFire = null,Object? evaluatedValue = null,Object? threshold = null,Object? confidence = null,Object? reason = null,Object? context = null,}) {
  return _then(_self.copyWith(
shouldFire: null == shouldFire ? _self.shouldFire : shouldFire // ignore: cast_nullable_to_non_nullable
as bool,evaluatedValue: null == evaluatedValue ? _self.evaluatedValue : evaluatedValue // ignore: cast_nullable_to_non_nullable
as double,threshold: null == threshold ? _self.threshold : threshold // ignore: cast_nullable_to_non_nullable
as double,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,context: null == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [TriggerEvaluationResult].
extension TriggerEvaluationResultPatterns on TriggerEvaluationResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TriggerEvaluationResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TriggerEvaluationResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TriggerEvaluationResult value)  $default,){
final _that = this;
switch (_that) {
case _TriggerEvaluationResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TriggerEvaluationResult value)?  $default,){
final _that = this;
switch (_that) {
case _TriggerEvaluationResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool shouldFire,  double evaluatedValue,  double threshold,  double confidence,  String reason,  Map<String, dynamic> context)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TriggerEvaluationResult() when $default != null:
return $default(_that.shouldFire,_that.evaluatedValue,_that.threshold,_that.confidence,_that.reason,_that.context);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool shouldFire,  double evaluatedValue,  double threshold,  double confidence,  String reason,  Map<String, dynamic> context)  $default,) {final _that = this;
switch (_that) {
case _TriggerEvaluationResult():
return $default(_that.shouldFire,_that.evaluatedValue,_that.threshold,_that.confidence,_that.reason,_that.context);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool shouldFire,  double evaluatedValue,  double threshold,  double confidence,  String reason,  Map<String, dynamic> context)?  $default,) {final _that = this;
switch (_that) {
case _TriggerEvaluationResult() when $default != null:
return $default(_that.shouldFire,_that.evaluatedValue,_that.threshold,_that.confidence,_that.reason,_that.context);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TriggerEvaluationResult implements TriggerEvaluationResult {
  const _TriggerEvaluationResult({required this.shouldFire, required this.evaluatedValue, required this.threshold, required this.confidence, required this.reason, final  Map<String, dynamic> context = const {}}): _context = context;
  factory _TriggerEvaluationResult.fromJson(Map<String, dynamic> json) => _$TriggerEvaluationResultFromJson(json);

/// Whether the trigger should fire.
@override final  bool shouldFire;
/// The value that was evaluated.
@override final  double evaluatedValue;
/// The threshold that was compared against.
@override final  double threshold;
/// Confidence level of the evaluation.
@override final  double confidence;
/// Reason for the result (useful for logging).
@override final  String reason;
/// Additional context data.
 final  Map<String, dynamic> _context;
/// Additional context data.
@override@JsonKey() Map<String, dynamic> get context {
  if (_context is EqualUnmodifiableMapView) return _context;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_context);
}


/// Create a copy of TriggerEvaluationResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TriggerEvaluationResultCopyWith<_TriggerEvaluationResult> get copyWith => __$TriggerEvaluationResultCopyWithImpl<_TriggerEvaluationResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TriggerEvaluationResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TriggerEvaluationResult&&(identical(other.shouldFire, shouldFire) || other.shouldFire == shouldFire)&&(identical(other.evaluatedValue, evaluatedValue) || other.evaluatedValue == evaluatedValue)&&(identical(other.threshold, threshold) || other.threshold == threshold)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.reason, reason) || other.reason == reason)&&const DeepCollectionEquality().equals(other._context, _context));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,shouldFire,evaluatedValue,threshold,confidence,reason,const DeepCollectionEquality().hash(_context));

@override
String toString() {
  return 'TriggerEvaluationResult(shouldFire: $shouldFire, evaluatedValue: $evaluatedValue, threshold: $threshold, confidence: $confidence, reason: $reason, context: $context)';
}


}

/// @nodoc
abstract mixin class _$TriggerEvaluationResultCopyWith<$Res> implements $TriggerEvaluationResultCopyWith<$Res> {
  factory _$TriggerEvaluationResultCopyWith(_TriggerEvaluationResult value, $Res Function(_TriggerEvaluationResult) _then) = __$TriggerEvaluationResultCopyWithImpl;
@override @useResult
$Res call({
 bool shouldFire, double evaluatedValue, double threshold, double confidence, String reason, Map<String, dynamic> context
});




}
/// @nodoc
class __$TriggerEvaluationResultCopyWithImpl<$Res>
    implements _$TriggerEvaluationResultCopyWith<$Res> {
  __$TriggerEvaluationResultCopyWithImpl(this._self, this._then);

  final _TriggerEvaluationResult _self;
  final $Res Function(_TriggerEvaluationResult) _then;

/// Create a copy of TriggerEvaluationResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? shouldFire = null,Object? evaluatedValue = null,Object? threshold = null,Object? confidence = null,Object? reason = null,Object? context = null,}) {
  return _then(_TriggerEvaluationResult(
shouldFire: null == shouldFire ? _self.shouldFire : shouldFire // ignore: cast_nullable_to_non_nullable
as bool,evaluatedValue: null == evaluatedValue ? _self.evaluatedValue : evaluatedValue // ignore: cast_nullable_to_non_nullable
as double,threshold: null == threshold ? _self.threshold : threshold // ignore: cast_nullable_to_non_nullable
as double,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,context: null == context ? _self._context : context // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}


/// @nodoc
mixin _$ActionExecutionResult {

/// Whether the action executed successfully.
 bool get success;/// Action type that was executed.
 AutomationActionType get actionType;/// Message describing the result.
 String get message;/// External reference ID (e.g., SMS message ID).
 String? get externalId;/// Error details if failed.
 String? get error;/// Execution timestamp.
 DateTime get executedAt;/// Execution duration in milliseconds.
 int? get durationMs;/// Additional result data.
 Map<String, dynamic> get metadata;
/// Create a copy of ActionExecutionResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActionExecutionResultCopyWith<ActionExecutionResult> get copyWith => _$ActionExecutionResultCopyWithImpl<ActionExecutionResult>(this as ActionExecutionResult, _$identity);

  /// Serializes this ActionExecutionResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActionExecutionResult&&(identical(other.success, success) || other.success == success)&&(identical(other.actionType, actionType) || other.actionType == actionType)&&(identical(other.message, message) || other.message == message)&&(identical(other.externalId, externalId) || other.externalId == externalId)&&(identical(other.error, error) || other.error == error)&&(identical(other.executedAt, executedAt) || other.executedAt == executedAt)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,success,actionType,message,externalId,error,executedAt,durationMs,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'ActionExecutionResult(success: $success, actionType: $actionType, message: $message, externalId: $externalId, error: $error, executedAt: $executedAt, durationMs: $durationMs, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $ActionExecutionResultCopyWith<$Res>  {
  factory $ActionExecutionResultCopyWith(ActionExecutionResult value, $Res Function(ActionExecutionResult) _then) = _$ActionExecutionResultCopyWithImpl;
@useResult
$Res call({
 bool success, AutomationActionType actionType, String message, String? externalId, String? error, DateTime executedAt, int? durationMs, Map<String, dynamic> metadata
});




}
/// @nodoc
class _$ActionExecutionResultCopyWithImpl<$Res>
    implements $ActionExecutionResultCopyWith<$Res> {
  _$ActionExecutionResultCopyWithImpl(this._self, this._then);

  final ActionExecutionResult _self;
  final $Res Function(ActionExecutionResult) _then;

/// Create a copy of ActionExecutionResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? success = null,Object? actionType = null,Object? message = null,Object? externalId = freezed,Object? error = freezed,Object? executedAt = null,Object? durationMs = freezed,Object? metadata = null,}) {
  return _then(_self.copyWith(
success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,actionType: null == actionType ? _self.actionType : actionType // ignore: cast_nullable_to_non_nullable
as AutomationActionType,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,externalId: freezed == externalId ? _self.externalId : externalId // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,executedAt: null == executedAt ? _self.executedAt : executedAt // ignore: cast_nullable_to_non_nullable
as DateTime,durationMs: freezed == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int?,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [ActionExecutionResult].
extension ActionExecutionResultPatterns on ActionExecutionResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActionExecutionResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActionExecutionResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActionExecutionResult value)  $default,){
final _that = this;
switch (_that) {
case _ActionExecutionResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActionExecutionResult value)?  $default,){
final _that = this;
switch (_that) {
case _ActionExecutionResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool success,  AutomationActionType actionType,  String message,  String? externalId,  String? error,  DateTime executedAt,  int? durationMs,  Map<String, dynamic> metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActionExecutionResult() when $default != null:
return $default(_that.success,_that.actionType,_that.message,_that.externalId,_that.error,_that.executedAt,_that.durationMs,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool success,  AutomationActionType actionType,  String message,  String? externalId,  String? error,  DateTime executedAt,  int? durationMs,  Map<String, dynamic> metadata)  $default,) {final _that = this;
switch (_that) {
case _ActionExecutionResult():
return $default(_that.success,_that.actionType,_that.message,_that.externalId,_that.error,_that.executedAt,_that.durationMs,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool success,  AutomationActionType actionType,  String message,  String? externalId,  String? error,  DateTime executedAt,  int? durationMs,  Map<String, dynamic> metadata)?  $default,) {final _that = this;
switch (_that) {
case _ActionExecutionResult() when $default != null:
return $default(_that.success,_that.actionType,_that.message,_that.externalId,_that.error,_that.executedAt,_that.durationMs,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActionExecutionResult implements ActionExecutionResult {
  const _ActionExecutionResult({required this.success, required this.actionType, required this.message, this.externalId, this.error, required this.executedAt, this.durationMs, final  Map<String, dynamic> metadata = const {}}): _metadata = metadata;
  factory _ActionExecutionResult.fromJson(Map<String, dynamic> json) => _$ActionExecutionResultFromJson(json);

/// Whether the action executed successfully.
@override final  bool success;
/// Action type that was executed.
@override final  AutomationActionType actionType;
/// Message describing the result.
@override final  String message;
/// External reference ID (e.g., SMS message ID).
@override final  String? externalId;
/// Error details if failed.
@override final  String? error;
/// Execution timestamp.
@override final  DateTime executedAt;
/// Execution duration in milliseconds.
@override final  int? durationMs;
/// Additional result data.
 final  Map<String, dynamic> _metadata;
/// Additional result data.
@override@JsonKey() Map<String, dynamic> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}


/// Create a copy of ActionExecutionResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActionExecutionResultCopyWith<_ActionExecutionResult> get copyWith => __$ActionExecutionResultCopyWithImpl<_ActionExecutionResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActionExecutionResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActionExecutionResult&&(identical(other.success, success) || other.success == success)&&(identical(other.actionType, actionType) || other.actionType == actionType)&&(identical(other.message, message) || other.message == message)&&(identical(other.externalId, externalId) || other.externalId == externalId)&&(identical(other.error, error) || other.error == error)&&(identical(other.executedAt, executedAt) || other.executedAt == executedAt)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,success,actionType,message,externalId,error,executedAt,durationMs,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'ActionExecutionResult(success: $success, actionType: $actionType, message: $message, externalId: $externalId, error: $error, executedAt: $executedAt, durationMs: $durationMs, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$ActionExecutionResultCopyWith<$Res> implements $ActionExecutionResultCopyWith<$Res> {
  factory _$ActionExecutionResultCopyWith(_ActionExecutionResult value, $Res Function(_ActionExecutionResult) _then) = __$ActionExecutionResultCopyWithImpl;
@override @useResult
$Res call({
 bool success, AutomationActionType actionType, String message, String? externalId, String? error, DateTime executedAt, int? durationMs, Map<String, dynamic> metadata
});




}
/// @nodoc
class __$ActionExecutionResultCopyWithImpl<$Res>
    implements _$ActionExecutionResultCopyWith<$Res> {
  __$ActionExecutionResultCopyWithImpl(this._self, this._then);

  final _ActionExecutionResult _self;
  final $Res Function(_ActionExecutionResult) _then;

/// Create a copy of ActionExecutionResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? success = null,Object? actionType = null,Object? message = null,Object? externalId = freezed,Object? error = freezed,Object? executedAt = null,Object? durationMs = freezed,Object? metadata = null,}) {
  return _then(_ActionExecutionResult(
success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,actionType: null == actionType ? _self.actionType : actionType // ignore: cast_nullable_to_non_nullable
as AutomationActionType,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,externalId: freezed == externalId ? _self.externalId : externalId // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,executedAt: null == executedAt ? _self.executedAt : executedAt // ignore: cast_nullable_to_non_nullable
as DateTime,durationMs: freezed == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int?,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}


/// @nodoc
mixin _$AutomationExecutionResult {

/// Rule that was processed.
 String get ruleId;/// Rule name for display.
 String get ruleName;/// Trigger evaluation result.
 TriggerEvaluationResult get triggerResult;/// Results of each action executed.
 List<ActionExecutionResult> get actionResults;/// Whether dry run mode was enabled.
 bool get dryRun;/// Skipped reason if rule was skipped.
 String? get skippedReason;/// Target entity type (appointment, client).
 String get entityType;/// Target entity ID.
 String get entityId;/// When execution started.
 DateTime get startedAt;/// When execution completed.
 DateTime get completedAt;
/// Create a copy of AutomationExecutionResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AutomationExecutionResultCopyWith<AutomationExecutionResult> get copyWith => _$AutomationExecutionResultCopyWithImpl<AutomationExecutionResult>(this as AutomationExecutionResult, _$identity);

  /// Serializes this AutomationExecutionResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AutomationExecutionResult&&(identical(other.ruleId, ruleId) || other.ruleId == ruleId)&&(identical(other.ruleName, ruleName) || other.ruleName == ruleName)&&(identical(other.triggerResult, triggerResult) || other.triggerResult == triggerResult)&&const DeepCollectionEquality().equals(other.actionResults, actionResults)&&(identical(other.dryRun, dryRun) || other.dryRun == dryRun)&&(identical(other.skippedReason, skippedReason) || other.skippedReason == skippedReason)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ruleId,ruleName,triggerResult,const DeepCollectionEquality().hash(actionResults),dryRun,skippedReason,entityType,entityId,startedAt,completedAt);

@override
String toString() {
  return 'AutomationExecutionResult(ruleId: $ruleId, ruleName: $ruleName, triggerResult: $triggerResult, actionResults: $actionResults, dryRun: $dryRun, skippedReason: $skippedReason, entityType: $entityType, entityId: $entityId, startedAt: $startedAt, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class $AutomationExecutionResultCopyWith<$Res>  {
  factory $AutomationExecutionResultCopyWith(AutomationExecutionResult value, $Res Function(AutomationExecutionResult) _then) = _$AutomationExecutionResultCopyWithImpl;
@useResult
$Res call({
 String ruleId, String ruleName, TriggerEvaluationResult triggerResult, List<ActionExecutionResult> actionResults, bool dryRun, String? skippedReason, String entityType, String entityId, DateTime startedAt, DateTime completedAt
});


$TriggerEvaluationResultCopyWith<$Res> get triggerResult;

}
/// @nodoc
class _$AutomationExecutionResultCopyWithImpl<$Res>
    implements $AutomationExecutionResultCopyWith<$Res> {
  _$AutomationExecutionResultCopyWithImpl(this._self, this._then);

  final AutomationExecutionResult _self;
  final $Res Function(AutomationExecutionResult) _then;

/// Create a copy of AutomationExecutionResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ruleId = null,Object? ruleName = null,Object? triggerResult = null,Object? actionResults = null,Object? dryRun = null,Object? skippedReason = freezed,Object? entityType = null,Object? entityId = null,Object? startedAt = null,Object? completedAt = null,}) {
  return _then(_self.copyWith(
ruleId: null == ruleId ? _self.ruleId : ruleId // ignore: cast_nullable_to_non_nullable
as String,ruleName: null == ruleName ? _self.ruleName : ruleName // ignore: cast_nullable_to_non_nullable
as String,triggerResult: null == triggerResult ? _self.triggerResult : triggerResult // ignore: cast_nullable_to_non_nullable
as TriggerEvaluationResult,actionResults: null == actionResults ? _self.actionResults : actionResults // ignore: cast_nullable_to_non_nullable
as List<ActionExecutionResult>,dryRun: null == dryRun ? _self.dryRun : dryRun // ignore: cast_nullable_to_non_nullable
as bool,skippedReason: freezed == skippedReason ? _self.skippedReason : skippedReason // ignore: cast_nullable_to_non_nullable
as String?,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as String,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: null == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of AutomationExecutionResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TriggerEvaluationResultCopyWith<$Res> get triggerResult {
  
  return $TriggerEvaluationResultCopyWith<$Res>(_self.triggerResult, (value) {
    return _then(_self.copyWith(triggerResult: value));
  });
}
}


/// Adds pattern-matching-related methods to [AutomationExecutionResult].
extension AutomationExecutionResultPatterns on AutomationExecutionResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AutomationExecutionResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AutomationExecutionResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AutomationExecutionResult value)  $default,){
final _that = this;
switch (_that) {
case _AutomationExecutionResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AutomationExecutionResult value)?  $default,){
final _that = this;
switch (_that) {
case _AutomationExecutionResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String ruleId,  String ruleName,  TriggerEvaluationResult triggerResult,  List<ActionExecutionResult> actionResults,  bool dryRun,  String? skippedReason,  String entityType,  String entityId,  DateTime startedAt,  DateTime completedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AutomationExecutionResult() when $default != null:
return $default(_that.ruleId,_that.ruleName,_that.triggerResult,_that.actionResults,_that.dryRun,_that.skippedReason,_that.entityType,_that.entityId,_that.startedAt,_that.completedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String ruleId,  String ruleName,  TriggerEvaluationResult triggerResult,  List<ActionExecutionResult> actionResults,  bool dryRun,  String? skippedReason,  String entityType,  String entityId,  DateTime startedAt,  DateTime completedAt)  $default,) {final _that = this;
switch (_that) {
case _AutomationExecutionResult():
return $default(_that.ruleId,_that.ruleName,_that.triggerResult,_that.actionResults,_that.dryRun,_that.skippedReason,_that.entityType,_that.entityId,_that.startedAt,_that.completedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String ruleId,  String ruleName,  TriggerEvaluationResult triggerResult,  List<ActionExecutionResult> actionResults,  bool dryRun,  String? skippedReason,  String entityType,  String entityId,  DateTime startedAt,  DateTime completedAt)?  $default,) {final _that = this;
switch (_that) {
case _AutomationExecutionResult() when $default != null:
return $default(_that.ruleId,_that.ruleName,_that.triggerResult,_that.actionResults,_that.dryRun,_that.skippedReason,_that.entityType,_that.entityId,_that.startedAt,_that.completedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AutomationExecutionResult extends AutomationExecutionResult {
  const _AutomationExecutionResult({required this.ruleId, required this.ruleName, required this.triggerResult, required final  List<ActionExecutionResult> actionResults, this.dryRun = false, this.skippedReason, required this.entityType, required this.entityId, required this.startedAt, required this.completedAt}): _actionResults = actionResults,super._();
  factory _AutomationExecutionResult.fromJson(Map<String, dynamic> json) => _$AutomationExecutionResultFromJson(json);

/// Rule that was processed.
@override final  String ruleId;
/// Rule name for display.
@override final  String ruleName;
/// Trigger evaluation result.
@override final  TriggerEvaluationResult triggerResult;
/// Results of each action executed.
 final  List<ActionExecutionResult> _actionResults;
/// Results of each action executed.
@override List<ActionExecutionResult> get actionResults {
  if (_actionResults is EqualUnmodifiableListView) return _actionResults;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_actionResults);
}

/// Whether dry run mode was enabled.
@override@JsonKey() final  bool dryRun;
/// Skipped reason if rule was skipped.
@override final  String? skippedReason;
/// Target entity type (appointment, client).
@override final  String entityType;
/// Target entity ID.
@override final  String entityId;
/// When execution started.
@override final  DateTime startedAt;
/// When execution completed.
@override final  DateTime completedAt;

/// Create a copy of AutomationExecutionResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AutomationExecutionResultCopyWith<_AutomationExecutionResult> get copyWith => __$AutomationExecutionResultCopyWithImpl<_AutomationExecutionResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AutomationExecutionResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AutomationExecutionResult&&(identical(other.ruleId, ruleId) || other.ruleId == ruleId)&&(identical(other.ruleName, ruleName) || other.ruleName == ruleName)&&(identical(other.triggerResult, triggerResult) || other.triggerResult == triggerResult)&&const DeepCollectionEquality().equals(other._actionResults, _actionResults)&&(identical(other.dryRun, dryRun) || other.dryRun == dryRun)&&(identical(other.skippedReason, skippedReason) || other.skippedReason == skippedReason)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ruleId,ruleName,triggerResult,const DeepCollectionEquality().hash(_actionResults),dryRun,skippedReason,entityType,entityId,startedAt,completedAt);

@override
String toString() {
  return 'AutomationExecutionResult(ruleId: $ruleId, ruleName: $ruleName, triggerResult: $triggerResult, actionResults: $actionResults, dryRun: $dryRun, skippedReason: $skippedReason, entityType: $entityType, entityId: $entityId, startedAt: $startedAt, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class _$AutomationExecutionResultCopyWith<$Res> implements $AutomationExecutionResultCopyWith<$Res> {
  factory _$AutomationExecutionResultCopyWith(_AutomationExecutionResult value, $Res Function(_AutomationExecutionResult) _then) = __$AutomationExecutionResultCopyWithImpl;
@override @useResult
$Res call({
 String ruleId, String ruleName, TriggerEvaluationResult triggerResult, List<ActionExecutionResult> actionResults, bool dryRun, String? skippedReason, String entityType, String entityId, DateTime startedAt, DateTime completedAt
});


@override $TriggerEvaluationResultCopyWith<$Res> get triggerResult;

}
/// @nodoc
class __$AutomationExecutionResultCopyWithImpl<$Res>
    implements _$AutomationExecutionResultCopyWith<$Res> {
  __$AutomationExecutionResultCopyWithImpl(this._self, this._then);

  final _AutomationExecutionResult _self;
  final $Res Function(_AutomationExecutionResult) _then;

/// Create a copy of AutomationExecutionResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ruleId = null,Object? ruleName = null,Object? triggerResult = null,Object? actionResults = null,Object? dryRun = null,Object? skippedReason = freezed,Object? entityType = null,Object? entityId = null,Object? startedAt = null,Object? completedAt = null,}) {
  return _then(_AutomationExecutionResult(
ruleId: null == ruleId ? _self.ruleId : ruleId // ignore: cast_nullable_to_non_nullable
as String,ruleName: null == ruleName ? _self.ruleName : ruleName // ignore: cast_nullable_to_non_nullable
as String,triggerResult: null == triggerResult ? _self.triggerResult : triggerResult // ignore: cast_nullable_to_non_nullable
as TriggerEvaluationResult,actionResults: null == actionResults ? _self._actionResults : actionResults // ignore: cast_nullable_to_non_nullable
as List<ActionExecutionResult>,dryRun: null == dryRun ? _self.dryRun : dryRun // ignore: cast_nullable_to_non_nullable
as bool,skippedReason: freezed == skippedReason ? _self.skippedReason : skippedReason // ignore: cast_nullable_to_non_nullable
as String?,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as String,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: null == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of AutomationExecutionResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TriggerEvaluationResultCopyWith<$Res> get triggerResult {
  
  return $TriggerEvaluationResultCopyWith<$Res>(_self.triggerResult, (value) {
    return _then(_self.copyWith(triggerResult: value));
  });
}
}

// dart format on
