// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_health_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ServiceHealthDetail {

/// Service name (prediction, sentiment, routing)
 String get serviceName;/// Current health status
 AIServiceHealth get status;/// Response time in milliseconds (if available)
 int? get responseTimeMs;/// Last successful request timestamp
 DateTime? get lastSuccessAt;/// Last error timestamp
 DateTime? get lastErrorAt;/// Last error message (if any)
 String? get lastErrorMessage;/// Number of consecutive failures
 int get consecutiveFailures;/// Whether circuit breaker is open
 bool get circuitBreakerOpen;/// Number of requests in the last minute
 int get requestsLastMinute;/// Number of errors in the last minute
 int get errorsLastMinute;
/// Create a copy of ServiceHealthDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceHealthDetailCopyWith<ServiceHealthDetail> get copyWith => _$ServiceHealthDetailCopyWithImpl<ServiceHealthDetail>(this as ServiceHealthDetail, _$identity);

  /// Serializes this ServiceHealthDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServiceHealthDetail&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName)&&(identical(other.status, status) || other.status == status)&&(identical(other.responseTimeMs, responseTimeMs) || other.responseTimeMs == responseTimeMs)&&(identical(other.lastSuccessAt, lastSuccessAt) || other.lastSuccessAt == lastSuccessAt)&&(identical(other.lastErrorAt, lastErrorAt) || other.lastErrorAt == lastErrorAt)&&(identical(other.lastErrorMessage, lastErrorMessage) || other.lastErrorMessage == lastErrorMessage)&&(identical(other.consecutiveFailures, consecutiveFailures) || other.consecutiveFailures == consecutiveFailures)&&(identical(other.circuitBreakerOpen, circuitBreakerOpen) || other.circuitBreakerOpen == circuitBreakerOpen)&&(identical(other.requestsLastMinute, requestsLastMinute) || other.requestsLastMinute == requestsLastMinute)&&(identical(other.errorsLastMinute, errorsLastMinute) || other.errorsLastMinute == errorsLastMinute));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,serviceName,status,responseTimeMs,lastSuccessAt,lastErrorAt,lastErrorMessage,consecutiveFailures,circuitBreakerOpen,requestsLastMinute,errorsLastMinute);

@override
String toString() {
  return 'ServiceHealthDetail(serviceName: $serviceName, status: $status, responseTimeMs: $responseTimeMs, lastSuccessAt: $lastSuccessAt, lastErrorAt: $lastErrorAt, lastErrorMessage: $lastErrorMessage, consecutiveFailures: $consecutiveFailures, circuitBreakerOpen: $circuitBreakerOpen, requestsLastMinute: $requestsLastMinute, errorsLastMinute: $errorsLastMinute)';
}


}

/// @nodoc
abstract mixin class $ServiceHealthDetailCopyWith<$Res>  {
  factory $ServiceHealthDetailCopyWith(ServiceHealthDetail value, $Res Function(ServiceHealthDetail) _then) = _$ServiceHealthDetailCopyWithImpl;
@useResult
$Res call({
 String serviceName, AIServiceHealth status, int? responseTimeMs, DateTime? lastSuccessAt, DateTime? lastErrorAt, String? lastErrorMessage, int consecutiveFailures, bool circuitBreakerOpen, int requestsLastMinute, int errorsLastMinute
});




}
/// @nodoc
class _$ServiceHealthDetailCopyWithImpl<$Res>
    implements $ServiceHealthDetailCopyWith<$Res> {
  _$ServiceHealthDetailCopyWithImpl(this._self, this._then);

  final ServiceHealthDetail _self;
  final $Res Function(ServiceHealthDetail) _then;

/// Create a copy of ServiceHealthDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? serviceName = null,Object? status = null,Object? responseTimeMs = freezed,Object? lastSuccessAt = freezed,Object? lastErrorAt = freezed,Object? lastErrorMessage = freezed,Object? consecutiveFailures = null,Object? circuitBreakerOpen = null,Object? requestsLastMinute = null,Object? errorsLastMinute = null,}) {
  return _then(_self.copyWith(
serviceName: null == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AIServiceHealth,responseTimeMs: freezed == responseTimeMs ? _self.responseTimeMs : responseTimeMs // ignore: cast_nullable_to_non_nullable
as int?,lastSuccessAt: freezed == lastSuccessAt ? _self.lastSuccessAt : lastSuccessAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastErrorAt: freezed == lastErrorAt ? _self.lastErrorAt : lastErrorAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastErrorMessage: freezed == lastErrorMessage ? _self.lastErrorMessage : lastErrorMessage // ignore: cast_nullable_to_non_nullable
as String?,consecutiveFailures: null == consecutiveFailures ? _self.consecutiveFailures : consecutiveFailures // ignore: cast_nullable_to_non_nullable
as int,circuitBreakerOpen: null == circuitBreakerOpen ? _self.circuitBreakerOpen : circuitBreakerOpen // ignore: cast_nullable_to_non_nullable
as bool,requestsLastMinute: null == requestsLastMinute ? _self.requestsLastMinute : requestsLastMinute // ignore: cast_nullable_to_non_nullable
as int,errorsLastMinute: null == errorsLastMinute ? _self.errorsLastMinute : errorsLastMinute // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ServiceHealthDetail].
extension ServiceHealthDetailPatterns on ServiceHealthDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServiceHealthDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServiceHealthDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServiceHealthDetail value)  $default,){
final _that = this;
switch (_that) {
case _ServiceHealthDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServiceHealthDetail value)?  $default,){
final _that = this;
switch (_that) {
case _ServiceHealthDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String serviceName,  AIServiceHealth status,  int? responseTimeMs,  DateTime? lastSuccessAt,  DateTime? lastErrorAt,  String? lastErrorMessage,  int consecutiveFailures,  bool circuitBreakerOpen,  int requestsLastMinute,  int errorsLastMinute)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServiceHealthDetail() when $default != null:
return $default(_that.serviceName,_that.status,_that.responseTimeMs,_that.lastSuccessAt,_that.lastErrorAt,_that.lastErrorMessage,_that.consecutiveFailures,_that.circuitBreakerOpen,_that.requestsLastMinute,_that.errorsLastMinute);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String serviceName,  AIServiceHealth status,  int? responseTimeMs,  DateTime? lastSuccessAt,  DateTime? lastErrorAt,  String? lastErrorMessage,  int consecutiveFailures,  bool circuitBreakerOpen,  int requestsLastMinute,  int errorsLastMinute)  $default,) {final _that = this;
switch (_that) {
case _ServiceHealthDetail():
return $default(_that.serviceName,_that.status,_that.responseTimeMs,_that.lastSuccessAt,_that.lastErrorAt,_that.lastErrorMessage,_that.consecutiveFailures,_that.circuitBreakerOpen,_that.requestsLastMinute,_that.errorsLastMinute);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String serviceName,  AIServiceHealth status,  int? responseTimeMs,  DateTime? lastSuccessAt,  DateTime? lastErrorAt,  String? lastErrorMessage,  int consecutiveFailures,  bool circuitBreakerOpen,  int requestsLastMinute,  int errorsLastMinute)?  $default,) {final _that = this;
switch (_that) {
case _ServiceHealthDetail() when $default != null:
return $default(_that.serviceName,_that.status,_that.responseTimeMs,_that.lastSuccessAt,_that.lastErrorAt,_that.lastErrorMessage,_that.consecutiveFailures,_that.circuitBreakerOpen,_that.requestsLastMinute,_that.errorsLastMinute);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ServiceHealthDetail extends ServiceHealthDetail {
  const _ServiceHealthDetail({required this.serviceName, required this.status, this.responseTimeMs, this.lastSuccessAt, this.lastErrorAt, this.lastErrorMessage, this.consecutiveFailures = 0, this.circuitBreakerOpen = false, this.requestsLastMinute = 0, this.errorsLastMinute = 0}): super._();
  factory _ServiceHealthDetail.fromJson(Map<String, dynamic> json) => _$ServiceHealthDetailFromJson(json);

/// Service name (prediction, sentiment, routing)
@override final  String serviceName;
/// Current health status
@override final  AIServiceHealth status;
/// Response time in milliseconds (if available)
@override final  int? responseTimeMs;
/// Last successful request timestamp
@override final  DateTime? lastSuccessAt;
/// Last error timestamp
@override final  DateTime? lastErrorAt;
/// Last error message (if any)
@override final  String? lastErrorMessage;
/// Number of consecutive failures
@override@JsonKey() final  int consecutiveFailures;
/// Whether circuit breaker is open
@override@JsonKey() final  bool circuitBreakerOpen;
/// Number of requests in the last minute
@override@JsonKey() final  int requestsLastMinute;
/// Number of errors in the last minute
@override@JsonKey() final  int errorsLastMinute;

/// Create a copy of ServiceHealthDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServiceHealthDetailCopyWith<_ServiceHealthDetail> get copyWith => __$ServiceHealthDetailCopyWithImpl<_ServiceHealthDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ServiceHealthDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServiceHealthDetail&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName)&&(identical(other.status, status) || other.status == status)&&(identical(other.responseTimeMs, responseTimeMs) || other.responseTimeMs == responseTimeMs)&&(identical(other.lastSuccessAt, lastSuccessAt) || other.lastSuccessAt == lastSuccessAt)&&(identical(other.lastErrorAt, lastErrorAt) || other.lastErrorAt == lastErrorAt)&&(identical(other.lastErrorMessage, lastErrorMessage) || other.lastErrorMessage == lastErrorMessage)&&(identical(other.consecutiveFailures, consecutiveFailures) || other.consecutiveFailures == consecutiveFailures)&&(identical(other.circuitBreakerOpen, circuitBreakerOpen) || other.circuitBreakerOpen == circuitBreakerOpen)&&(identical(other.requestsLastMinute, requestsLastMinute) || other.requestsLastMinute == requestsLastMinute)&&(identical(other.errorsLastMinute, errorsLastMinute) || other.errorsLastMinute == errorsLastMinute));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,serviceName,status,responseTimeMs,lastSuccessAt,lastErrorAt,lastErrorMessage,consecutiveFailures,circuitBreakerOpen,requestsLastMinute,errorsLastMinute);

@override
String toString() {
  return 'ServiceHealthDetail(serviceName: $serviceName, status: $status, responseTimeMs: $responseTimeMs, lastSuccessAt: $lastSuccessAt, lastErrorAt: $lastErrorAt, lastErrorMessage: $lastErrorMessage, consecutiveFailures: $consecutiveFailures, circuitBreakerOpen: $circuitBreakerOpen, requestsLastMinute: $requestsLastMinute, errorsLastMinute: $errorsLastMinute)';
}


}

/// @nodoc
abstract mixin class _$ServiceHealthDetailCopyWith<$Res> implements $ServiceHealthDetailCopyWith<$Res> {
  factory _$ServiceHealthDetailCopyWith(_ServiceHealthDetail value, $Res Function(_ServiceHealthDetail) _then) = __$ServiceHealthDetailCopyWithImpl;
@override @useResult
$Res call({
 String serviceName, AIServiceHealth status, int? responseTimeMs, DateTime? lastSuccessAt, DateTime? lastErrorAt, String? lastErrorMessage, int consecutiveFailures, bool circuitBreakerOpen, int requestsLastMinute, int errorsLastMinute
});




}
/// @nodoc
class __$ServiceHealthDetailCopyWithImpl<$Res>
    implements _$ServiceHealthDetailCopyWith<$Res> {
  __$ServiceHealthDetailCopyWithImpl(this._self, this._then);

  final _ServiceHealthDetail _self;
  final $Res Function(_ServiceHealthDetail) _then;

/// Create a copy of ServiceHealthDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? serviceName = null,Object? status = null,Object? responseTimeMs = freezed,Object? lastSuccessAt = freezed,Object? lastErrorAt = freezed,Object? lastErrorMessage = freezed,Object? consecutiveFailures = null,Object? circuitBreakerOpen = null,Object? requestsLastMinute = null,Object? errorsLastMinute = null,}) {
  return _then(_ServiceHealthDetail(
serviceName: null == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AIServiceHealth,responseTimeMs: freezed == responseTimeMs ? _self.responseTimeMs : responseTimeMs // ignore: cast_nullable_to_non_nullable
as int?,lastSuccessAt: freezed == lastSuccessAt ? _self.lastSuccessAt : lastSuccessAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastErrorAt: freezed == lastErrorAt ? _self.lastErrorAt : lastErrorAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastErrorMessage: freezed == lastErrorMessage ? _self.lastErrorMessage : lastErrorMessage // ignore: cast_nullable_to_non_nullable
as String?,consecutiveFailures: null == consecutiveFailures ? _self.consecutiveFailures : consecutiveFailures // ignore: cast_nullable_to_non_nullable
as int,circuitBreakerOpen: null == circuitBreakerOpen ? _self.circuitBreakerOpen : circuitBreakerOpen // ignore: cast_nullable_to_non_nullable
as bool,requestsLastMinute: null == requestsLastMinute ? _self.requestsLastMinute : requestsLastMinute // ignore: cast_nullable_to_non_nullable
as int,errorsLastMinute: null == errorsLastMinute ? _self.errorsLastMinute : errorsLastMinute // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$AIHealthStatus {

/// Overall health across all services
 AIServiceHealth get overallStatus;/// Prediction service health details
 ServiceHealthDetail get predictionService;/// Sentiment service health details
 ServiceHealthDetail get sentimentService;/// Routing service health details
 ServiceHealthDetail get routingService;/// When this health check was performed
 DateTime? get lastHealthCheck;/// Last successful prediction timestamp (any service)
 DateTime? get lastSuccessfulPrediction;/// Overall error message if unhealthy
 String? get errorMessage;/// Currently loaded models
 LoadedModels get loadedModels;/// Server version (if reported)
 String? get serverVersion;/// Server uptime in seconds
 int? get serverUptimeSeconds;/// GPU availability status
 bool get gpuAvailable;/// GPU memory usage percentage (0-100)
 double? get gpuMemoryUsagePercent;
/// Create a copy of AIHealthStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AIHealthStatusCopyWith<AIHealthStatus> get copyWith => _$AIHealthStatusCopyWithImpl<AIHealthStatus>(this as AIHealthStatus, _$identity);

  /// Serializes this AIHealthStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AIHealthStatus&&(identical(other.overallStatus, overallStatus) || other.overallStatus == overallStatus)&&(identical(other.predictionService, predictionService) || other.predictionService == predictionService)&&(identical(other.sentimentService, sentimentService) || other.sentimentService == sentimentService)&&(identical(other.routingService, routingService) || other.routingService == routingService)&&(identical(other.lastHealthCheck, lastHealthCheck) || other.lastHealthCheck == lastHealthCheck)&&(identical(other.lastSuccessfulPrediction, lastSuccessfulPrediction) || other.lastSuccessfulPrediction == lastSuccessfulPrediction)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.loadedModels, loadedModels) || other.loadedModels == loadedModels)&&(identical(other.serverVersion, serverVersion) || other.serverVersion == serverVersion)&&(identical(other.serverUptimeSeconds, serverUptimeSeconds) || other.serverUptimeSeconds == serverUptimeSeconds)&&(identical(other.gpuAvailable, gpuAvailable) || other.gpuAvailable == gpuAvailable)&&(identical(other.gpuMemoryUsagePercent, gpuMemoryUsagePercent) || other.gpuMemoryUsagePercent == gpuMemoryUsagePercent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,overallStatus,predictionService,sentimentService,routingService,lastHealthCheck,lastSuccessfulPrediction,errorMessage,loadedModels,serverVersion,serverUptimeSeconds,gpuAvailable,gpuMemoryUsagePercent);

@override
String toString() {
  return 'AIHealthStatus(overallStatus: $overallStatus, predictionService: $predictionService, sentimentService: $sentimentService, routingService: $routingService, lastHealthCheck: $lastHealthCheck, lastSuccessfulPrediction: $lastSuccessfulPrediction, errorMessage: $errorMessage, loadedModels: $loadedModels, serverVersion: $serverVersion, serverUptimeSeconds: $serverUptimeSeconds, gpuAvailable: $gpuAvailable, gpuMemoryUsagePercent: $gpuMemoryUsagePercent)';
}


}

/// @nodoc
abstract mixin class $AIHealthStatusCopyWith<$Res>  {
  factory $AIHealthStatusCopyWith(AIHealthStatus value, $Res Function(AIHealthStatus) _then) = _$AIHealthStatusCopyWithImpl;
@useResult
$Res call({
 AIServiceHealth overallStatus, ServiceHealthDetail predictionService, ServiceHealthDetail sentimentService, ServiceHealthDetail routingService, DateTime? lastHealthCheck, DateTime? lastSuccessfulPrediction, String? errorMessage, LoadedModels loadedModels, String? serverVersion, int? serverUptimeSeconds, bool gpuAvailable, double? gpuMemoryUsagePercent
});


$ServiceHealthDetailCopyWith<$Res> get predictionService;$ServiceHealthDetailCopyWith<$Res> get sentimentService;$ServiceHealthDetailCopyWith<$Res> get routingService;$LoadedModelsCopyWith<$Res> get loadedModels;

}
/// @nodoc
class _$AIHealthStatusCopyWithImpl<$Res>
    implements $AIHealthStatusCopyWith<$Res> {
  _$AIHealthStatusCopyWithImpl(this._self, this._then);

  final AIHealthStatus _self;
  final $Res Function(AIHealthStatus) _then;

/// Create a copy of AIHealthStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? overallStatus = null,Object? predictionService = null,Object? sentimentService = null,Object? routingService = null,Object? lastHealthCheck = freezed,Object? lastSuccessfulPrediction = freezed,Object? errorMessage = freezed,Object? loadedModels = null,Object? serverVersion = freezed,Object? serverUptimeSeconds = freezed,Object? gpuAvailable = null,Object? gpuMemoryUsagePercent = freezed,}) {
  return _then(_self.copyWith(
overallStatus: null == overallStatus ? _self.overallStatus : overallStatus // ignore: cast_nullable_to_non_nullable
as AIServiceHealth,predictionService: null == predictionService ? _self.predictionService : predictionService // ignore: cast_nullable_to_non_nullable
as ServiceHealthDetail,sentimentService: null == sentimentService ? _self.sentimentService : sentimentService // ignore: cast_nullable_to_non_nullable
as ServiceHealthDetail,routingService: null == routingService ? _self.routingService : routingService // ignore: cast_nullable_to_non_nullable
as ServiceHealthDetail,lastHealthCheck: freezed == lastHealthCheck ? _self.lastHealthCheck : lastHealthCheck // ignore: cast_nullable_to_non_nullable
as DateTime?,lastSuccessfulPrediction: freezed == lastSuccessfulPrediction ? _self.lastSuccessfulPrediction : lastSuccessfulPrediction // ignore: cast_nullable_to_non_nullable
as DateTime?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,loadedModels: null == loadedModels ? _self.loadedModels : loadedModels // ignore: cast_nullable_to_non_nullable
as LoadedModels,serverVersion: freezed == serverVersion ? _self.serverVersion : serverVersion // ignore: cast_nullable_to_non_nullable
as String?,serverUptimeSeconds: freezed == serverUptimeSeconds ? _self.serverUptimeSeconds : serverUptimeSeconds // ignore: cast_nullable_to_non_nullable
as int?,gpuAvailable: null == gpuAvailable ? _self.gpuAvailable : gpuAvailable // ignore: cast_nullable_to_non_nullable
as bool,gpuMemoryUsagePercent: freezed == gpuMemoryUsagePercent ? _self.gpuMemoryUsagePercent : gpuMemoryUsagePercent // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}
/// Create a copy of AIHealthStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ServiceHealthDetailCopyWith<$Res> get predictionService {
  
  return $ServiceHealthDetailCopyWith<$Res>(_self.predictionService, (value) {
    return _then(_self.copyWith(predictionService: value));
  });
}/// Create a copy of AIHealthStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ServiceHealthDetailCopyWith<$Res> get sentimentService {
  
  return $ServiceHealthDetailCopyWith<$Res>(_self.sentimentService, (value) {
    return _then(_self.copyWith(sentimentService: value));
  });
}/// Create a copy of AIHealthStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ServiceHealthDetailCopyWith<$Res> get routingService {
  
  return $ServiceHealthDetailCopyWith<$Res>(_self.routingService, (value) {
    return _then(_self.copyWith(routingService: value));
  });
}/// Create a copy of AIHealthStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LoadedModelsCopyWith<$Res> get loadedModels {
  
  return $LoadedModelsCopyWith<$Res>(_self.loadedModels, (value) {
    return _then(_self.copyWith(loadedModels: value));
  });
}
}


/// Adds pattern-matching-related methods to [AIHealthStatus].
extension AIHealthStatusPatterns on AIHealthStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AIHealthStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AIHealthStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AIHealthStatus value)  $default,){
final _that = this;
switch (_that) {
case _AIHealthStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AIHealthStatus value)?  $default,){
final _that = this;
switch (_that) {
case _AIHealthStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AIServiceHealth overallStatus,  ServiceHealthDetail predictionService,  ServiceHealthDetail sentimentService,  ServiceHealthDetail routingService,  DateTime? lastHealthCheck,  DateTime? lastSuccessfulPrediction,  String? errorMessage,  LoadedModels loadedModels,  String? serverVersion,  int? serverUptimeSeconds,  bool gpuAvailable,  double? gpuMemoryUsagePercent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AIHealthStatus() when $default != null:
return $default(_that.overallStatus,_that.predictionService,_that.sentimentService,_that.routingService,_that.lastHealthCheck,_that.lastSuccessfulPrediction,_that.errorMessage,_that.loadedModels,_that.serverVersion,_that.serverUptimeSeconds,_that.gpuAvailable,_that.gpuMemoryUsagePercent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AIServiceHealth overallStatus,  ServiceHealthDetail predictionService,  ServiceHealthDetail sentimentService,  ServiceHealthDetail routingService,  DateTime? lastHealthCheck,  DateTime? lastSuccessfulPrediction,  String? errorMessage,  LoadedModels loadedModels,  String? serverVersion,  int? serverUptimeSeconds,  bool gpuAvailable,  double? gpuMemoryUsagePercent)  $default,) {final _that = this;
switch (_that) {
case _AIHealthStatus():
return $default(_that.overallStatus,_that.predictionService,_that.sentimentService,_that.routingService,_that.lastHealthCheck,_that.lastSuccessfulPrediction,_that.errorMessage,_that.loadedModels,_that.serverVersion,_that.serverUptimeSeconds,_that.gpuAvailable,_that.gpuMemoryUsagePercent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AIServiceHealth overallStatus,  ServiceHealthDetail predictionService,  ServiceHealthDetail sentimentService,  ServiceHealthDetail routingService,  DateTime? lastHealthCheck,  DateTime? lastSuccessfulPrediction,  String? errorMessage,  LoadedModels loadedModels,  String? serverVersion,  int? serverUptimeSeconds,  bool gpuAvailable,  double? gpuMemoryUsagePercent)?  $default,) {final _that = this;
switch (_that) {
case _AIHealthStatus() when $default != null:
return $default(_that.overallStatus,_that.predictionService,_that.sentimentService,_that.routingService,_that.lastHealthCheck,_that.lastSuccessfulPrediction,_that.errorMessage,_that.loadedModels,_that.serverVersion,_that.serverUptimeSeconds,_that.gpuAvailable,_that.gpuMemoryUsagePercent);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AIHealthStatus extends AIHealthStatus {
  const _AIHealthStatus({required this.overallStatus, required this.predictionService, required this.sentimentService, required this.routingService, this.lastHealthCheck, this.lastSuccessfulPrediction, this.errorMessage, required this.loadedModels, this.serverVersion, this.serverUptimeSeconds, this.gpuAvailable = false, this.gpuMemoryUsagePercent}): super._();
  factory _AIHealthStatus.fromJson(Map<String, dynamic> json) => _$AIHealthStatusFromJson(json);

/// Overall health across all services
@override final  AIServiceHealth overallStatus;
/// Prediction service health details
@override final  ServiceHealthDetail predictionService;
/// Sentiment service health details
@override final  ServiceHealthDetail sentimentService;
/// Routing service health details
@override final  ServiceHealthDetail routingService;
/// When this health check was performed
@override final  DateTime? lastHealthCheck;
/// Last successful prediction timestamp (any service)
@override final  DateTime? lastSuccessfulPrediction;
/// Overall error message if unhealthy
@override final  String? errorMessage;
/// Currently loaded models
@override final  LoadedModels loadedModels;
/// Server version (if reported)
@override final  String? serverVersion;
/// Server uptime in seconds
@override final  int? serverUptimeSeconds;
/// GPU availability status
@override@JsonKey() final  bool gpuAvailable;
/// GPU memory usage percentage (0-100)
@override final  double? gpuMemoryUsagePercent;

/// Create a copy of AIHealthStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AIHealthStatusCopyWith<_AIHealthStatus> get copyWith => __$AIHealthStatusCopyWithImpl<_AIHealthStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AIHealthStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AIHealthStatus&&(identical(other.overallStatus, overallStatus) || other.overallStatus == overallStatus)&&(identical(other.predictionService, predictionService) || other.predictionService == predictionService)&&(identical(other.sentimentService, sentimentService) || other.sentimentService == sentimentService)&&(identical(other.routingService, routingService) || other.routingService == routingService)&&(identical(other.lastHealthCheck, lastHealthCheck) || other.lastHealthCheck == lastHealthCheck)&&(identical(other.lastSuccessfulPrediction, lastSuccessfulPrediction) || other.lastSuccessfulPrediction == lastSuccessfulPrediction)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.loadedModels, loadedModels) || other.loadedModels == loadedModels)&&(identical(other.serverVersion, serverVersion) || other.serverVersion == serverVersion)&&(identical(other.serverUptimeSeconds, serverUptimeSeconds) || other.serverUptimeSeconds == serverUptimeSeconds)&&(identical(other.gpuAvailable, gpuAvailable) || other.gpuAvailable == gpuAvailable)&&(identical(other.gpuMemoryUsagePercent, gpuMemoryUsagePercent) || other.gpuMemoryUsagePercent == gpuMemoryUsagePercent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,overallStatus,predictionService,sentimentService,routingService,lastHealthCheck,lastSuccessfulPrediction,errorMessage,loadedModels,serverVersion,serverUptimeSeconds,gpuAvailable,gpuMemoryUsagePercent);

@override
String toString() {
  return 'AIHealthStatus(overallStatus: $overallStatus, predictionService: $predictionService, sentimentService: $sentimentService, routingService: $routingService, lastHealthCheck: $lastHealthCheck, lastSuccessfulPrediction: $lastSuccessfulPrediction, errorMessage: $errorMessage, loadedModels: $loadedModels, serverVersion: $serverVersion, serverUptimeSeconds: $serverUptimeSeconds, gpuAvailable: $gpuAvailable, gpuMemoryUsagePercent: $gpuMemoryUsagePercent)';
}


}

/// @nodoc
abstract mixin class _$AIHealthStatusCopyWith<$Res> implements $AIHealthStatusCopyWith<$Res> {
  factory _$AIHealthStatusCopyWith(_AIHealthStatus value, $Res Function(_AIHealthStatus) _then) = __$AIHealthStatusCopyWithImpl;
@override @useResult
$Res call({
 AIServiceHealth overallStatus, ServiceHealthDetail predictionService, ServiceHealthDetail sentimentService, ServiceHealthDetail routingService, DateTime? lastHealthCheck, DateTime? lastSuccessfulPrediction, String? errorMessage, LoadedModels loadedModels, String? serverVersion, int? serverUptimeSeconds, bool gpuAvailable, double? gpuMemoryUsagePercent
});


@override $ServiceHealthDetailCopyWith<$Res> get predictionService;@override $ServiceHealthDetailCopyWith<$Res> get sentimentService;@override $ServiceHealthDetailCopyWith<$Res> get routingService;@override $LoadedModelsCopyWith<$Res> get loadedModels;

}
/// @nodoc
class __$AIHealthStatusCopyWithImpl<$Res>
    implements _$AIHealthStatusCopyWith<$Res> {
  __$AIHealthStatusCopyWithImpl(this._self, this._then);

  final _AIHealthStatus _self;
  final $Res Function(_AIHealthStatus) _then;

/// Create a copy of AIHealthStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? overallStatus = null,Object? predictionService = null,Object? sentimentService = null,Object? routingService = null,Object? lastHealthCheck = freezed,Object? lastSuccessfulPrediction = freezed,Object? errorMessage = freezed,Object? loadedModels = null,Object? serverVersion = freezed,Object? serverUptimeSeconds = freezed,Object? gpuAvailable = null,Object? gpuMemoryUsagePercent = freezed,}) {
  return _then(_AIHealthStatus(
overallStatus: null == overallStatus ? _self.overallStatus : overallStatus // ignore: cast_nullable_to_non_nullable
as AIServiceHealth,predictionService: null == predictionService ? _self.predictionService : predictionService // ignore: cast_nullable_to_non_nullable
as ServiceHealthDetail,sentimentService: null == sentimentService ? _self.sentimentService : sentimentService // ignore: cast_nullable_to_non_nullable
as ServiceHealthDetail,routingService: null == routingService ? _self.routingService : routingService // ignore: cast_nullable_to_non_nullable
as ServiceHealthDetail,lastHealthCheck: freezed == lastHealthCheck ? _self.lastHealthCheck : lastHealthCheck // ignore: cast_nullable_to_non_nullable
as DateTime?,lastSuccessfulPrediction: freezed == lastSuccessfulPrediction ? _self.lastSuccessfulPrediction : lastSuccessfulPrediction // ignore: cast_nullable_to_non_nullable
as DateTime?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,loadedModels: null == loadedModels ? _self.loadedModels : loadedModels // ignore: cast_nullable_to_non_nullable
as LoadedModels,serverVersion: freezed == serverVersion ? _self.serverVersion : serverVersion // ignore: cast_nullable_to_non_nullable
as String?,serverUptimeSeconds: freezed == serverUptimeSeconds ? _self.serverUptimeSeconds : serverUptimeSeconds // ignore: cast_nullable_to_non_nullable
as int?,gpuAvailable: null == gpuAvailable ? _self.gpuAvailable : gpuAvailable // ignore: cast_nullable_to_non_nullable
as bool,gpuMemoryUsagePercent: freezed == gpuMemoryUsagePercent ? _self.gpuMemoryUsagePercent : gpuMemoryUsagePercent // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

/// Create a copy of AIHealthStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ServiceHealthDetailCopyWith<$Res> get predictionService {
  
  return $ServiceHealthDetailCopyWith<$Res>(_self.predictionService, (value) {
    return _then(_self.copyWith(predictionService: value));
  });
}/// Create a copy of AIHealthStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ServiceHealthDetailCopyWith<$Res> get sentimentService {
  
  return $ServiceHealthDetailCopyWith<$Res>(_self.sentimentService, (value) {
    return _then(_self.copyWith(sentimentService: value));
  });
}/// Create a copy of AIHealthStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ServiceHealthDetailCopyWith<$Res> get routingService {
  
  return $ServiceHealthDetailCopyWith<$Res>(_self.routingService, (value) {
    return _then(_self.copyWith(routingService: value));
  });
}/// Create a copy of AIHealthStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LoadedModelsCopyWith<$Res> get loadedModels {
  
  return $LoadedModelsCopyWith<$Res>(_self.loadedModels, (value) {
    return _then(_self.copyWith(loadedModels: value));
  });
}
}

// dart format on
