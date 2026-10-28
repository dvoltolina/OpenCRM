// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'accounting_connection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AccountingConnection {

/// Unique identifier.
 String get id;/// Business this connection belongs to.
 String get businessId;/// The accounting software provider.
 AccountingProvider get provider;/// Provider-specific company ID (QuickBooks Realm ID or Xero Tenant ID).
 String get providerCompanyId;/// Company name in the accounting software.
 String? get providerCompanyName;/// OAuth access token (encrypted at rest).
 String get accessToken;/// OAuth refresh token (encrypted at rest).
 String get refreshToken;/// When the access token expires.
@TimestampConverter() DateTime get tokenExpiresAt;/// Whether to sync invoices to accounting.
 bool get syncInvoices;/// Whether to sync payments to accounting.
 bool get syncPayments;/// Whether to sync clients/customers to accounting.
 bool get syncClients;/// Whether to sync products/services to accounting.
 bool get syncProducts;/// Mapped income account ID in accounting software.
 String? get incomeAccountId;/// Mapped income account name for display.
 String? get incomeAccountName;/// Mapped deposit/bank account ID.
 String? get depositAccountId;/// Mapped deposit/bank account name for display.
 String? get depositAccountName;/// Mapped tax code ID.
 String? get taxCodeId;/// Mapped tax code name for display.
 String? get taxCodeName;/// Current connection status.
 ConnectionStatus get status;/// Last successful sync timestamp.
@NullableTimestampConverter() DateTime? get lastSyncAt;/// Error message from last failed operation.
 String? get lastSyncError;/// When the connection was established.
@TimestampConverter() DateTime get connectedAt;/// User who set up the connection.
 String? get connectedByUserId;// ============================================
// HIPAA COMPLIANCE FIELDS
// ============================================
/// Whether HIPAA compliance mode is enabled.
/// When true, client data will be de-identified before sync unless BAA is verified.
/// Defaults to true for healthcare business safety.
 bool get hipaaMode;/// Whether a Business Associate Agreement (BAA) has been verified.
/// Only QuickBooks offers BAA - Xero does not.
/// When false and hipaaMode is true, all synced data will be de-identified.
 bool get baaVerified;/// When the BAA was verified by admin.
@NullableTimestampConverter() DateTime? get baaVerifiedAt;/// User ID of admin who verified the BAA.
 String? get baaVerifiedByUserId;/// Record creation timestamp.
@NullableTimestampConverter() DateTime? get createdAt;/// Last update timestamp.
@NullableTimestampConverter() DateTime? get updatedAt;
/// Create a copy of AccountingConnection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountingConnectionCopyWith<AccountingConnection> get copyWith => _$AccountingConnectionCopyWithImpl<AccountingConnection>(this as AccountingConnection, _$identity);

  /// Serializes this AccountingConnection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountingConnection&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.providerCompanyId, providerCompanyId) || other.providerCompanyId == providerCompanyId)&&(identical(other.providerCompanyName, providerCompanyName) || other.providerCompanyName == providerCompanyName)&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.tokenExpiresAt, tokenExpiresAt) || other.tokenExpiresAt == tokenExpiresAt)&&(identical(other.syncInvoices, syncInvoices) || other.syncInvoices == syncInvoices)&&(identical(other.syncPayments, syncPayments) || other.syncPayments == syncPayments)&&(identical(other.syncClients, syncClients) || other.syncClients == syncClients)&&(identical(other.syncProducts, syncProducts) || other.syncProducts == syncProducts)&&(identical(other.incomeAccountId, incomeAccountId) || other.incomeAccountId == incomeAccountId)&&(identical(other.incomeAccountName, incomeAccountName) || other.incomeAccountName == incomeAccountName)&&(identical(other.depositAccountId, depositAccountId) || other.depositAccountId == depositAccountId)&&(identical(other.depositAccountName, depositAccountName) || other.depositAccountName == depositAccountName)&&(identical(other.taxCodeId, taxCodeId) || other.taxCodeId == taxCodeId)&&(identical(other.taxCodeName, taxCodeName) || other.taxCodeName == taxCodeName)&&(identical(other.status, status) || other.status == status)&&(identical(other.lastSyncAt, lastSyncAt) || other.lastSyncAt == lastSyncAt)&&(identical(other.lastSyncError, lastSyncError) || other.lastSyncError == lastSyncError)&&(identical(other.connectedAt, connectedAt) || other.connectedAt == connectedAt)&&(identical(other.connectedByUserId, connectedByUserId) || other.connectedByUserId == connectedByUserId)&&(identical(other.hipaaMode, hipaaMode) || other.hipaaMode == hipaaMode)&&(identical(other.baaVerified, baaVerified) || other.baaVerified == baaVerified)&&(identical(other.baaVerifiedAt, baaVerifiedAt) || other.baaVerifiedAt == baaVerifiedAt)&&(identical(other.baaVerifiedByUserId, baaVerifiedByUserId) || other.baaVerifiedByUserId == baaVerifiedByUserId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,businessId,provider,providerCompanyId,providerCompanyName,accessToken,refreshToken,tokenExpiresAt,syncInvoices,syncPayments,syncClients,syncProducts,incomeAccountId,incomeAccountName,depositAccountId,depositAccountName,taxCodeId,taxCodeName,status,lastSyncAt,lastSyncError,connectedAt,connectedByUserId,hipaaMode,baaVerified,baaVerifiedAt,baaVerifiedByUserId,createdAt,updatedAt]);

@override
String toString() {
  return 'AccountingConnection(id: $id, businessId: $businessId, provider: $provider, providerCompanyId: $providerCompanyId, providerCompanyName: $providerCompanyName, accessToken: $accessToken, refreshToken: $refreshToken, tokenExpiresAt: $tokenExpiresAt, syncInvoices: $syncInvoices, syncPayments: $syncPayments, syncClients: $syncClients, syncProducts: $syncProducts, incomeAccountId: $incomeAccountId, incomeAccountName: $incomeAccountName, depositAccountId: $depositAccountId, depositAccountName: $depositAccountName, taxCodeId: $taxCodeId, taxCodeName: $taxCodeName, status: $status, lastSyncAt: $lastSyncAt, lastSyncError: $lastSyncError, connectedAt: $connectedAt, connectedByUserId: $connectedByUserId, hipaaMode: $hipaaMode, baaVerified: $baaVerified, baaVerifiedAt: $baaVerifiedAt, baaVerifiedByUserId: $baaVerifiedByUserId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $AccountingConnectionCopyWith<$Res>  {
  factory $AccountingConnectionCopyWith(AccountingConnection value, $Res Function(AccountingConnection) _then) = _$AccountingConnectionCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, AccountingProvider provider, String providerCompanyId, String? providerCompanyName, String accessToken, String refreshToken,@TimestampConverter() DateTime tokenExpiresAt, bool syncInvoices, bool syncPayments, bool syncClients, bool syncProducts, String? incomeAccountId, String? incomeAccountName, String? depositAccountId, String? depositAccountName, String? taxCodeId, String? taxCodeName, ConnectionStatus status,@NullableTimestampConverter() DateTime? lastSyncAt, String? lastSyncError,@TimestampConverter() DateTime connectedAt, String? connectedByUserId, bool hipaaMode, bool baaVerified,@NullableTimestampConverter() DateTime? baaVerifiedAt, String? baaVerifiedByUserId,@NullableTimestampConverter() DateTime? createdAt,@NullableTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$AccountingConnectionCopyWithImpl<$Res>
    implements $AccountingConnectionCopyWith<$Res> {
  _$AccountingConnectionCopyWithImpl(this._self, this._then);

  final AccountingConnection _self;
  final $Res Function(AccountingConnection) _then;

/// Create a copy of AccountingConnection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? provider = null,Object? providerCompanyId = null,Object? providerCompanyName = freezed,Object? accessToken = null,Object? refreshToken = null,Object? tokenExpiresAt = null,Object? syncInvoices = null,Object? syncPayments = null,Object? syncClients = null,Object? syncProducts = null,Object? incomeAccountId = freezed,Object? incomeAccountName = freezed,Object? depositAccountId = freezed,Object? depositAccountName = freezed,Object? taxCodeId = freezed,Object? taxCodeName = freezed,Object? status = null,Object? lastSyncAt = freezed,Object? lastSyncError = freezed,Object? connectedAt = null,Object? connectedByUserId = freezed,Object? hipaaMode = null,Object? baaVerified = null,Object? baaVerifiedAt = freezed,Object? baaVerifiedByUserId = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as AccountingProvider,providerCompanyId: null == providerCompanyId ? _self.providerCompanyId : providerCompanyId // ignore: cast_nullable_to_non_nullable
as String,providerCompanyName: freezed == providerCompanyName ? _self.providerCompanyName : providerCompanyName // ignore: cast_nullable_to_non_nullable
as String?,accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,tokenExpiresAt: null == tokenExpiresAt ? _self.tokenExpiresAt : tokenExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,syncInvoices: null == syncInvoices ? _self.syncInvoices : syncInvoices // ignore: cast_nullable_to_non_nullable
as bool,syncPayments: null == syncPayments ? _self.syncPayments : syncPayments // ignore: cast_nullable_to_non_nullable
as bool,syncClients: null == syncClients ? _self.syncClients : syncClients // ignore: cast_nullable_to_non_nullable
as bool,syncProducts: null == syncProducts ? _self.syncProducts : syncProducts // ignore: cast_nullable_to_non_nullable
as bool,incomeAccountId: freezed == incomeAccountId ? _self.incomeAccountId : incomeAccountId // ignore: cast_nullable_to_non_nullable
as String?,incomeAccountName: freezed == incomeAccountName ? _self.incomeAccountName : incomeAccountName // ignore: cast_nullable_to_non_nullable
as String?,depositAccountId: freezed == depositAccountId ? _self.depositAccountId : depositAccountId // ignore: cast_nullable_to_non_nullable
as String?,depositAccountName: freezed == depositAccountName ? _self.depositAccountName : depositAccountName // ignore: cast_nullable_to_non_nullable
as String?,taxCodeId: freezed == taxCodeId ? _self.taxCodeId : taxCodeId // ignore: cast_nullable_to_non_nullable
as String?,taxCodeName: freezed == taxCodeName ? _self.taxCodeName : taxCodeName // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ConnectionStatus,lastSyncAt: freezed == lastSyncAt ? _self.lastSyncAt : lastSyncAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastSyncError: freezed == lastSyncError ? _self.lastSyncError : lastSyncError // ignore: cast_nullable_to_non_nullable
as String?,connectedAt: null == connectedAt ? _self.connectedAt : connectedAt // ignore: cast_nullable_to_non_nullable
as DateTime,connectedByUserId: freezed == connectedByUserId ? _self.connectedByUserId : connectedByUserId // ignore: cast_nullable_to_non_nullable
as String?,hipaaMode: null == hipaaMode ? _self.hipaaMode : hipaaMode // ignore: cast_nullable_to_non_nullable
as bool,baaVerified: null == baaVerified ? _self.baaVerified : baaVerified // ignore: cast_nullable_to_non_nullable
as bool,baaVerifiedAt: freezed == baaVerifiedAt ? _self.baaVerifiedAt : baaVerifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,baaVerifiedByUserId: freezed == baaVerifiedByUserId ? _self.baaVerifiedByUserId : baaVerifiedByUserId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AccountingConnection].
extension AccountingConnectionPatterns on AccountingConnection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccountingConnection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccountingConnection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccountingConnection value)  $default,){
final _that = this;
switch (_that) {
case _AccountingConnection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccountingConnection value)?  $default,){
final _that = this;
switch (_that) {
case _AccountingConnection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  AccountingProvider provider,  String providerCompanyId,  String? providerCompanyName,  String accessToken,  String refreshToken, @TimestampConverter()  DateTime tokenExpiresAt,  bool syncInvoices,  bool syncPayments,  bool syncClients,  bool syncProducts,  String? incomeAccountId,  String? incomeAccountName,  String? depositAccountId,  String? depositAccountName,  String? taxCodeId,  String? taxCodeName,  ConnectionStatus status, @NullableTimestampConverter()  DateTime? lastSyncAt,  String? lastSyncError, @TimestampConverter()  DateTime connectedAt,  String? connectedByUserId,  bool hipaaMode,  bool baaVerified, @NullableTimestampConverter()  DateTime? baaVerifiedAt,  String? baaVerifiedByUserId, @NullableTimestampConverter()  DateTime? createdAt, @NullableTimestampConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccountingConnection() when $default != null:
return $default(_that.id,_that.businessId,_that.provider,_that.providerCompanyId,_that.providerCompanyName,_that.accessToken,_that.refreshToken,_that.tokenExpiresAt,_that.syncInvoices,_that.syncPayments,_that.syncClients,_that.syncProducts,_that.incomeAccountId,_that.incomeAccountName,_that.depositAccountId,_that.depositAccountName,_that.taxCodeId,_that.taxCodeName,_that.status,_that.lastSyncAt,_that.lastSyncError,_that.connectedAt,_that.connectedByUserId,_that.hipaaMode,_that.baaVerified,_that.baaVerifiedAt,_that.baaVerifiedByUserId,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  AccountingProvider provider,  String providerCompanyId,  String? providerCompanyName,  String accessToken,  String refreshToken, @TimestampConverter()  DateTime tokenExpiresAt,  bool syncInvoices,  bool syncPayments,  bool syncClients,  bool syncProducts,  String? incomeAccountId,  String? incomeAccountName,  String? depositAccountId,  String? depositAccountName,  String? taxCodeId,  String? taxCodeName,  ConnectionStatus status, @NullableTimestampConverter()  DateTime? lastSyncAt,  String? lastSyncError, @TimestampConverter()  DateTime connectedAt,  String? connectedByUserId,  bool hipaaMode,  bool baaVerified, @NullableTimestampConverter()  DateTime? baaVerifiedAt,  String? baaVerifiedByUserId, @NullableTimestampConverter()  DateTime? createdAt, @NullableTimestampConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _AccountingConnection():
return $default(_that.id,_that.businessId,_that.provider,_that.providerCompanyId,_that.providerCompanyName,_that.accessToken,_that.refreshToken,_that.tokenExpiresAt,_that.syncInvoices,_that.syncPayments,_that.syncClients,_that.syncProducts,_that.incomeAccountId,_that.incomeAccountName,_that.depositAccountId,_that.depositAccountName,_that.taxCodeId,_that.taxCodeName,_that.status,_that.lastSyncAt,_that.lastSyncError,_that.connectedAt,_that.connectedByUserId,_that.hipaaMode,_that.baaVerified,_that.baaVerifiedAt,_that.baaVerifiedByUserId,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  AccountingProvider provider,  String providerCompanyId,  String? providerCompanyName,  String accessToken,  String refreshToken, @TimestampConverter()  DateTime tokenExpiresAt,  bool syncInvoices,  bool syncPayments,  bool syncClients,  bool syncProducts,  String? incomeAccountId,  String? incomeAccountName,  String? depositAccountId,  String? depositAccountName,  String? taxCodeId,  String? taxCodeName,  ConnectionStatus status, @NullableTimestampConverter()  DateTime? lastSyncAt,  String? lastSyncError, @TimestampConverter()  DateTime connectedAt,  String? connectedByUserId,  bool hipaaMode,  bool baaVerified, @NullableTimestampConverter()  DateTime? baaVerifiedAt,  String? baaVerifiedByUserId, @NullableTimestampConverter()  DateTime? createdAt, @NullableTimestampConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _AccountingConnection() when $default != null:
return $default(_that.id,_that.businessId,_that.provider,_that.providerCompanyId,_that.providerCompanyName,_that.accessToken,_that.refreshToken,_that.tokenExpiresAt,_that.syncInvoices,_that.syncPayments,_that.syncClients,_that.syncProducts,_that.incomeAccountId,_that.incomeAccountName,_that.depositAccountId,_that.depositAccountName,_that.taxCodeId,_that.taxCodeName,_that.status,_that.lastSyncAt,_that.lastSyncError,_that.connectedAt,_that.connectedByUserId,_that.hipaaMode,_that.baaVerified,_that.baaVerifiedAt,_that.baaVerifiedByUserId,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AccountingConnection extends AccountingConnection {
  const _AccountingConnection({required this.id, required this.businessId, required this.provider, required this.providerCompanyId, this.providerCompanyName, required this.accessToken, required this.refreshToken, @TimestampConverter() required this.tokenExpiresAt, this.syncInvoices = true, this.syncPayments = true, this.syncClients = true, this.syncProducts = false, this.incomeAccountId, this.incomeAccountName, this.depositAccountId, this.depositAccountName, this.taxCodeId, this.taxCodeName, this.status = ConnectionStatus.active, @NullableTimestampConverter() this.lastSyncAt, this.lastSyncError, @TimestampConverter() required this.connectedAt, this.connectedByUserId, this.hipaaMode = true, this.baaVerified = false, @NullableTimestampConverter() this.baaVerifiedAt, this.baaVerifiedByUserId, @NullableTimestampConverter() this.createdAt, @NullableTimestampConverter() this.updatedAt}): super._();
  factory _AccountingConnection.fromJson(Map<String, dynamic> json) => _$AccountingConnectionFromJson(json);

/// Unique identifier.
@override final  String id;
/// Business this connection belongs to.
@override final  String businessId;
/// The accounting software provider.
@override final  AccountingProvider provider;
/// Provider-specific company ID (QuickBooks Realm ID or Xero Tenant ID).
@override final  String providerCompanyId;
/// Company name in the accounting software.
@override final  String? providerCompanyName;
/// OAuth access token (encrypted at rest).
@override final  String accessToken;
/// OAuth refresh token (encrypted at rest).
@override final  String refreshToken;
/// When the access token expires.
@override@TimestampConverter() final  DateTime tokenExpiresAt;
/// Whether to sync invoices to accounting.
@override@JsonKey() final  bool syncInvoices;
/// Whether to sync payments to accounting.
@override@JsonKey() final  bool syncPayments;
/// Whether to sync clients/customers to accounting.
@override@JsonKey() final  bool syncClients;
/// Whether to sync products/services to accounting.
@override@JsonKey() final  bool syncProducts;
/// Mapped income account ID in accounting software.
@override final  String? incomeAccountId;
/// Mapped income account name for display.
@override final  String? incomeAccountName;
/// Mapped deposit/bank account ID.
@override final  String? depositAccountId;
/// Mapped deposit/bank account name for display.
@override final  String? depositAccountName;
/// Mapped tax code ID.
@override final  String? taxCodeId;
/// Mapped tax code name for display.
@override final  String? taxCodeName;
/// Current connection status.
@override@JsonKey() final  ConnectionStatus status;
/// Last successful sync timestamp.
@override@NullableTimestampConverter() final  DateTime? lastSyncAt;
/// Error message from last failed operation.
@override final  String? lastSyncError;
/// When the connection was established.
@override@TimestampConverter() final  DateTime connectedAt;
/// User who set up the connection.
@override final  String? connectedByUserId;
// ============================================
// HIPAA COMPLIANCE FIELDS
// ============================================
/// Whether HIPAA compliance mode is enabled.
/// When true, client data will be de-identified before sync unless BAA is verified.
/// Defaults to true for healthcare business safety.
@override@JsonKey() final  bool hipaaMode;
/// Whether a Business Associate Agreement (BAA) has been verified.
/// Only QuickBooks offers BAA - Xero does not.
/// When false and hipaaMode is true, all synced data will be de-identified.
@override@JsonKey() final  bool baaVerified;
/// When the BAA was verified by admin.
@override@NullableTimestampConverter() final  DateTime? baaVerifiedAt;
/// User ID of admin who verified the BAA.
@override final  String? baaVerifiedByUserId;
/// Record creation timestamp.
@override@NullableTimestampConverter() final  DateTime? createdAt;
/// Last update timestamp.
@override@NullableTimestampConverter() final  DateTime? updatedAt;

/// Create a copy of AccountingConnection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountingConnectionCopyWith<_AccountingConnection> get copyWith => __$AccountingConnectionCopyWithImpl<_AccountingConnection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AccountingConnectionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountingConnection&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.providerCompanyId, providerCompanyId) || other.providerCompanyId == providerCompanyId)&&(identical(other.providerCompanyName, providerCompanyName) || other.providerCompanyName == providerCompanyName)&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.tokenExpiresAt, tokenExpiresAt) || other.tokenExpiresAt == tokenExpiresAt)&&(identical(other.syncInvoices, syncInvoices) || other.syncInvoices == syncInvoices)&&(identical(other.syncPayments, syncPayments) || other.syncPayments == syncPayments)&&(identical(other.syncClients, syncClients) || other.syncClients == syncClients)&&(identical(other.syncProducts, syncProducts) || other.syncProducts == syncProducts)&&(identical(other.incomeAccountId, incomeAccountId) || other.incomeAccountId == incomeAccountId)&&(identical(other.incomeAccountName, incomeAccountName) || other.incomeAccountName == incomeAccountName)&&(identical(other.depositAccountId, depositAccountId) || other.depositAccountId == depositAccountId)&&(identical(other.depositAccountName, depositAccountName) || other.depositAccountName == depositAccountName)&&(identical(other.taxCodeId, taxCodeId) || other.taxCodeId == taxCodeId)&&(identical(other.taxCodeName, taxCodeName) || other.taxCodeName == taxCodeName)&&(identical(other.status, status) || other.status == status)&&(identical(other.lastSyncAt, lastSyncAt) || other.lastSyncAt == lastSyncAt)&&(identical(other.lastSyncError, lastSyncError) || other.lastSyncError == lastSyncError)&&(identical(other.connectedAt, connectedAt) || other.connectedAt == connectedAt)&&(identical(other.connectedByUserId, connectedByUserId) || other.connectedByUserId == connectedByUserId)&&(identical(other.hipaaMode, hipaaMode) || other.hipaaMode == hipaaMode)&&(identical(other.baaVerified, baaVerified) || other.baaVerified == baaVerified)&&(identical(other.baaVerifiedAt, baaVerifiedAt) || other.baaVerifiedAt == baaVerifiedAt)&&(identical(other.baaVerifiedByUserId, baaVerifiedByUserId) || other.baaVerifiedByUserId == baaVerifiedByUserId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,businessId,provider,providerCompanyId,providerCompanyName,accessToken,refreshToken,tokenExpiresAt,syncInvoices,syncPayments,syncClients,syncProducts,incomeAccountId,incomeAccountName,depositAccountId,depositAccountName,taxCodeId,taxCodeName,status,lastSyncAt,lastSyncError,connectedAt,connectedByUserId,hipaaMode,baaVerified,baaVerifiedAt,baaVerifiedByUserId,createdAt,updatedAt]);

@override
String toString() {
  return 'AccountingConnection(id: $id, businessId: $businessId, provider: $provider, providerCompanyId: $providerCompanyId, providerCompanyName: $providerCompanyName, accessToken: $accessToken, refreshToken: $refreshToken, tokenExpiresAt: $tokenExpiresAt, syncInvoices: $syncInvoices, syncPayments: $syncPayments, syncClients: $syncClients, syncProducts: $syncProducts, incomeAccountId: $incomeAccountId, incomeAccountName: $incomeAccountName, depositAccountId: $depositAccountId, depositAccountName: $depositAccountName, taxCodeId: $taxCodeId, taxCodeName: $taxCodeName, status: $status, lastSyncAt: $lastSyncAt, lastSyncError: $lastSyncError, connectedAt: $connectedAt, connectedByUserId: $connectedByUserId, hipaaMode: $hipaaMode, baaVerified: $baaVerified, baaVerifiedAt: $baaVerifiedAt, baaVerifiedByUserId: $baaVerifiedByUserId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$AccountingConnectionCopyWith<$Res> implements $AccountingConnectionCopyWith<$Res> {
  factory _$AccountingConnectionCopyWith(_AccountingConnection value, $Res Function(_AccountingConnection) _then) = __$AccountingConnectionCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, AccountingProvider provider, String providerCompanyId, String? providerCompanyName, String accessToken, String refreshToken,@TimestampConverter() DateTime tokenExpiresAt, bool syncInvoices, bool syncPayments, bool syncClients, bool syncProducts, String? incomeAccountId, String? incomeAccountName, String? depositAccountId, String? depositAccountName, String? taxCodeId, String? taxCodeName, ConnectionStatus status,@NullableTimestampConverter() DateTime? lastSyncAt, String? lastSyncError,@TimestampConverter() DateTime connectedAt, String? connectedByUserId, bool hipaaMode, bool baaVerified,@NullableTimestampConverter() DateTime? baaVerifiedAt, String? baaVerifiedByUserId,@NullableTimestampConverter() DateTime? createdAt,@NullableTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$AccountingConnectionCopyWithImpl<$Res>
    implements _$AccountingConnectionCopyWith<$Res> {
  __$AccountingConnectionCopyWithImpl(this._self, this._then);

  final _AccountingConnection _self;
  final $Res Function(_AccountingConnection) _then;

/// Create a copy of AccountingConnection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? provider = null,Object? providerCompanyId = null,Object? providerCompanyName = freezed,Object? accessToken = null,Object? refreshToken = null,Object? tokenExpiresAt = null,Object? syncInvoices = null,Object? syncPayments = null,Object? syncClients = null,Object? syncProducts = null,Object? incomeAccountId = freezed,Object? incomeAccountName = freezed,Object? depositAccountId = freezed,Object? depositAccountName = freezed,Object? taxCodeId = freezed,Object? taxCodeName = freezed,Object? status = null,Object? lastSyncAt = freezed,Object? lastSyncError = freezed,Object? connectedAt = null,Object? connectedByUserId = freezed,Object? hipaaMode = null,Object? baaVerified = null,Object? baaVerifiedAt = freezed,Object? baaVerifiedByUserId = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_AccountingConnection(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as AccountingProvider,providerCompanyId: null == providerCompanyId ? _self.providerCompanyId : providerCompanyId // ignore: cast_nullable_to_non_nullable
as String,providerCompanyName: freezed == providerCompanyName ? _self.providerCompanyName : providerCompanyName // ignore: cast_nullable_to_non_nullable
as String?,accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,tokenExpiresAt: null == tokenExpiresAt ? _self.tokenExpiresAt : tokenExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,syncInvoices: null == syncInvoices ? _self.syncInvoices : syncInvoices // ignore: cast_nullable_to_non_nullable
as bool,syncPayments: null == syncPayments ? _self.syncPayments : syncPayments // ignore: cast_nullable_to_non_nullable
as bool,syncClients: null == syncClients ? _self.syncClients : syncClients // ignore: cast_nullable_to_non_nullable
as bool,syncProducts: null == syncProducts ? _self.syncProducts : syncProducts // ignore: cast_nullable_to_non_nullable
as bool,incomeAccountId: freezed == incomeAccountId ? _self.incomeAccountId : incomeAccountId // ignore: cast_nullable_to_non_nullable
as String?,incomeAccountName: freezed == incomeAccountName ? _self.incomeAccountName : incomeAccountName // ignore: cast_nullable_to_non_nullable
as String?,depositAccountId: freezed == depositAccountId ? _self.depositAccountId : depositAccountId // ignore: cast_nullable_to_non_nullable
as String?,depositAccountName: freezed == depositAccountName ? _self.depositAccountName : depositAccountName // ignore: cast_nullable_to_non_nullable
as String?,taxCodeId: freezed == taxCodeId ? _self.taxCodeId : taxCodeId // ignore: cast_nullable_to_non_nullable
as String?,taxCodeName: freezed == taxCodeName ? _self.taxCodeName : taxCodeName // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ConnectionStatus,lastSyncAt: freezed == lastSyncAt ? _self.lastSyncAt : lastSyncAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastSyncError: freezed == lastSyncError ? _self.lastSyncError : lastSyncError // ignore: cast_nullable_to_non_nullable
as String?,connectedAt: null == connectedAt ? _self.connectedAt : connectedAt // ignore: cast_nullable_to_non_nullable
as DateTime,connectedByUserId: freezed == connectedByUserId ? _self.connectedByUserId : connectedByUserId // ignore: cast_nullable_to_non_nullable
as String?,hipaaMode: null == hipaaMode ? _self.hipaaMode : hipaaMode // ignore: cast_nullable_to_non_nullable
as bool,baaVerified: null == baaVerified ? _self.baaVerified : baaVerified // ignore: cast_nullable_to_non_nullable
as bool,baaVerifiedAt: freezed == baaVerifiedAt ? _self.baaVerifiedAt : baaVerifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,baaVerifiedByUserId: freezed == baaVerifiedByUserId ? _self.baaVerifiedByUserId : baaVerifiedByUserId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
