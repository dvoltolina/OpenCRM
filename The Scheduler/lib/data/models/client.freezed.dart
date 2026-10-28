// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'client.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Client {

 String get id; String get businessId; String get firstName; String get lastName; String? get email; String? get phone; String? get address;@NullableTimestampConverter() DateTime? get birthDate; String? get notes; List<String> get tags; ClientLifecycle get lifecycle;@NullableTimestampConverter() DateTime? get lastContactDate;@NullableTimestampConverter() DateTime? get lastAppointmentDate; Map<String, dynamic> get preferences; Map<String, dynamic> get customFields;@TimestampConverter() DateTime get createdAt;@NullableTimestampConverter() DateTime? get updatedAt;/// Optional Firebase Auth user ID if client has a login account
/// This links the client profile to a Firebase Auth user for customer portal access
 String? get userId;// ========== AI Prediction Fields ==========
/// Whether client has a payment method on file (card, bank account, etc.)
/// Used by no-show prediction model as a trust indicator.
 bool get hasPaymentMethod;/// Stripe customer ID for payment processing (optional)
 String? get stripeCustomerId;// ========== Route Optimization Fields (for mobile providers) ==========
/// Service address latitude (for mobile providers)
/// Used by route optimization in Phase 3.
 double? get serviceLatitude;/// Service address longitude (for mobile providers)
/// Used by route optimization in Phase 3.
 double? get serviceLongitude;/// Service location notes (e.g., "Gate code: 1234", "Park in back")
 String? get serviceNotes;
/// Create a copy of Client
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClientCopyWith<Client> get copyWith => _$ClientCopyWithImpl<Client>(this as Client, _$identity);

  /// Serializes this Client to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Client&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.address, address) || other.address == address)&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.notes, notes) || other.notes == notes)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.lifecycle, lifecycle) || other.lifecycle == lifecycle)&&(identical(other.lastContactDate, lastContactDate) || other.lastContactDate == lastContactDate)&&(identical(other.lastAppointmentDate, lastAppointmentDate) || other.lastAppointmentDate == lastAppointmentDate)&&const DeepCollectionEquality().equals(other.preferences, preferences)&&const DeepCollectionEquality().equals(other.customFields, customFields)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.hasPaymentMethod, hasPaymentMethod) || other.hasPaymentMethod == hasPaymentMethod)&&(identical(other.stripeCustomerId, stripeCustomerId) || other.stripeCustomerId == stripeCustomerId)&&(identical(other.serviceLatitude, serviceLatitude) || other.serviceLatitude == serviceLatitude)&&(identical(other.serviceLongitude, serviceLongitude) || other.serviceLongitude == serviceLongitude)&&(identical(other.serviceNotes, serviceNotes) || other.serviceNotes == serviceNotes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,businessId,firstName,lastName,email,phone,address,birthDate,notes,const DeepCollectionEquality().hash(tags),lifecycle,lastContactDate,lastAppointmentDate,const DeepCollectionEquality().hash(preferences),const DeepCollectionEquality().hash(customFields),createdAt,updatedAt,userId,hasPaymentMethod,stripeCustomerId,serviceLatitude,serviceLongitude,serviceNotes]);

@override
String toString() {
  return 'Client(id: $id, businessId: $businessId, firstName: $firstName, lastName: $lastName, email: $email, phone: $phone, address: $address, birthDate: $birthDate, notes: $notes, tags: $tags, lifecycle: $lifecycle, lastContactDate: $lastContactDate, lastAppointmentDate: $lastAppointmentDate, preferences: $preferences, customFields: $customFields, createdAt: $createdAt, updatedAt: $updatedAt, userId: $userId, hasPaymentMethod: $hasPaymentMethod, stripeCustomerId: $stripeCustomerId, serviceLatitude: $serviceLatitude, serviceLongitude: $serviceLongitude, serviceNotes: $serviceNotes)';
}


}

/// @nodoc
abstract mixin class $ClientCopyWith<$Res>  {
  factory $ClientCopyWith(Client value, $Res Function(Client) _then) = _$ClientCopyWithImpl;
@useResult
$Res call({
 String id, String businessId, String firstName, String lastName, String? email, String? phone, String? address,@NullableTimestampConverter() DateTime? birthDate, String? notes, List<String> tags, ClientLifecycle lifecycle,@NullableTimestampConverter() DateTime? lastContactDate,@NullableTimestampConverter() DateTime? lastAppointmentDate, Map<String, dynamic> preferences, Map<String, dynamic> customFields,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? updatedAt, String? userId, bool hasPaymentMethod, String? stripeCustomerId, double? serviceLatitude, double? serviceLongitude, String? serviceNotes
});




}
/// @nodoc
class _$ClientCopyWithImpl<$Res>
    implements $ClientCopyWith<$Res> {
  _$ClientCopyWithImpl(this._self, this._then);

  final Client _self;
  final $Res Function(Client) _then;

/// Create a copy of Client
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessId = null,Object? firstName = null,Object? lastName = null,Object? email = freezed,Object? phone = freezed,Object? address = freezed,Object? birthDate = freezed,Object? notes = freezed,Object? tags = null,Object? lifecycle = null,Object? lastContactDate = freezed,Object? lastAppointmentDate = freezed,Object? preferences = null,Object? customFields = null,Object? createdAt = null,Object? updatedAt = freezed,Object? userId = freezed,Object? hasPaymentMethod = null,Object? stripeCustomerId = freezed,Object? serviceLatitude = freezed,Object? serviceLongitude = freezed,Object? serviceNotes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,birthDate: freezed == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
as DateTime?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,lifecycle: null == lifecycle ? _self.lifecycle : lifecycle // ignore: cast_nullable_to_non_nullable
as ClientLifecycle,lastContactDate: freezed == lastContactDate ? _self.lastContactDate : lastContactDate // ignore: cast_nullable_to_non_nullable
as DateTime?,lastAppointmentDate: freezed == lastAppointmentDate ? _self.lastAppointmentDate : lastAppointmentDate // ignore: cast_nullable_to_non_nullable
as DateTime?,preferences: null == preferences ? _self.preferences : preferences // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,customFields: null == customFields ? _self.customFields : customFields // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,hasPaymentMethod: null == hasPaymentMethod ? _self.hasPaymentMethod : hasPaymentMethod // ignore: cast_nullable_to_non_nullable
as bool,stripeCustomerId: freezed == stripeCustomerId ? _self.stripeCustomerId : stripeCustomerId // ignore: cast_nullable_to_non_nullable
as String?,serviceLatitude: freezed == serviceLatitude ? _self.serviceLatitude : serviceLatitude // ignore: cast_nullable_to_non_nullable
as double?,serviceLongitude: freezed == serviceLongitude ? _self.serviceLongitude : serviceLongitude // ignore: cast_nullable_to_non_nullable
as double?,serviceNotes: freezed == serviceNotes ? _self.serviceNotes : serviceNotes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Client].
extension ClientPatterns on Client {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Client value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Client() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Client value)  $default,){
final _that = this;
switch (_that) {
case _Client():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Client value)?  $default,){
final _that = this;
switch (_that) {
case _Client() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessId,  String firstName,  String lastName,  String? email,  String? phone,  String? address, @NullableTimestampConverter()  DateTime? birthDate,  String? notes,  List<String> tags,  ClientLifecycle lifecycle, @NullableTimestampConverter()  DateTime? lastContactDate, @NullableTimestampConverter()  DateTime? lastAppointmentDate,  Map<String, dynamic> preferences,  Map<String, dynamic> customFields, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt,  String? userId,  bool hasPaymentMethod,  String? stripeCustomerId,  double? serviceLatitude,  double? serviceLongitude,  String? serviceNotes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Client() when $default != null:
return $default(_that.id,_that.businessId,_that.firstName,_that.lastName,_that.email,_that.phone,_that.address,_that.birthDate,_that.notes,_that.tags,_that.lifecycle,_that.lastContactDate,_that.lastAppointmentDate,_that.preferences,_that.customFields,_that.createdAt,_that.updatedAt,_that.userId,_that.hasPaymentMethod,_that.stripeCustomerId,_that.serviceLatitude,_that.serviceLongitude,_that.serviceNotes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessId,  String firstName,  String lastName,  String? email,  String? phone,  String? address, @NullableTimestampConverter()  DateTime? birthDate,  String? notes,  List<String> tags,  ClientLifecycle lifecycle, @NullableTimestampConverter()  DateTime? lastContactDate, @NullableTimestampConverter()  DateTime? lastAppointmentDate,  Map<String, dynamic> preferences,  Map<String, dynamic> customFields, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt,  String? userId,  bool hasPaymentMethod,  String? stripeCustomerId,  double? serviceLatitude,  double? serviceLongitude,  String? serviceNotes)  $default,) {final _that = this;
switch (_that) {
case _Client():
return $default(_that.id,_that.businessId,_that.firstName,_that.lastName,_that.email,_that.phone,_that.address,_that.birthDate,_that.notes,_that.tags,_that.lifecycle,_that.lastContactDate,_that.lastAppointmentDate,_that.preferences,_that.customFields,_that.createdAt,_that.updatedAt,_that.userId,_that.hasPaymentMethod,_that.stripeCustomerId,_that.serviceLatitude,_that.serviceLongitude,_that.serviceNotes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessId,  String firstName,  String lastName,  String? email,  String? phone,  String? address, @NullableTimestampConverter()  DateTime? birthDate,  String? notes,  List<String> tags,  ClientLifecycle lifecycle, @NullableTimestampConverter()  DateTime? lastContactDate, @NullableTimestampConverter()  DateTime? lastAppointmentDate,  Map<String, dynamic> preferences,  Map<String, dynamic> customFields, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt,  String? userId,  bool hasPaymentMethod,  String? stripeCustomerId,  double? serviceLatitude,  double? serviceLongitude,  String? serviceNotes)?  $default,) {final _that = this;
switch (_that) {
case _Client() when $default != null:
return $default(_that.id,_that.businessId,_that.firstName,_that.lastName,_that.email,_that.phone,_that.address,_that.birthDate,_that.notes,_that.tags,_that.lifecycle,_that.lastContactDate,_that.lastAppointmentDate,_that.preferences,_that.customFields,_that.createdAt,_that.updatedAt,_that.userId,_that.hasPaymentMethod,_that.stripeCustomerId,_that.serviceLatitude,_that.serviceLongitude,_that.serviceNotes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Client extends Client {
  const _Client({required this.id, required this.businessId, required this.firstName, required this.lastName, this.email, this.phone, this.address, @NullableTimestampConverter() this.birthDate, this.notes, final  List<String> tags = const [], this.lifecycle = ClientLifecycle.newClient, @NullableTimestampConverter() this.lastContactDate, @NullableTimestampConverter() this.lastAppointmentDate, final  Map<String, dynamic> preferences = const {}, final  Map<String, dynamic> customFields = const {}, @TimestampConverter() required this.createdAt, @NullableTimestampConverter() this.updatedAt, this.userId, this.hasPaymentMethod = false, this.stripeCustomerId, this.serviceLatitude, this.serviceLongitude, this.serviceNotes}): _tags = tags,_preferences = preferences,_customFields = customFields,super._();
  factory _Client.fromJson(Map<String, dynamic> json) => _$ClientFromJson(json);

@override final  String id;
@override final  String businessId;
@override final  String firstName;
@override final  String lastName;
@override final  String? email;
@override final  String? phone;
@override final  String? address;
@override@NullableTimestampConverter() final  DateTime? birthDate;
@override final  String? notes;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override@JsonKey() final  ClientLifecycle lifecycle;
@override@NullableTimestampConverter() final  DateTime? lastContactDate;
@override@NullableTimestampConverter() final  DateTime? lastAppointmentDate;
 final  Map<String, dynamic> _preferences;
@override@JsonKey() Map<String, dynamic> get preferences {
  if (_preferences is EqualUnmodifiableMapView) return _preferences;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_preferences);
}

 final  Map<String, dynamic> _customFields;
@override@JsonKey() Map<String, dynamic> get customFields {
  if (_customFields is EqualUnmodifiableMapView) return _customFields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_customFields);
}

@override@TimestampConverter() final  DateTime createdAt;
@override@NullableTimestampConverter() final  DateTime? updatedAt;
/// Optional Firebase Auth user ID if client has a login account
/// This links the client profile to a Firebase Auth user for customer portal access
@override final  String? userId;
// ========== AI Prediction Fields ==========
/// Whether client has a payment method on file (card, bank account, etc.)
/// Used by no-show prediction model as a trust indicator.
@override@JsonKey() final  bool hasPaymentMethod;
/// Stripe customer ID for payment processing (optional)
@override final  String? stripeCustomerId;
// ========== Route Optimization Fields (for mobile providers) ==========
/// Service address latitude (for mobile providers)
/// Used by route optimization in Phase 3.
@override final  double? serviceLatitude;
/// Service address longitude (for mobile providers)
/// Used by route optimization in Phase 3.
@override final  double? serviceLongitude;
/// Service location notes (e.g., "Gate code: 1234", "Park in back")
@override final  String? serviceNotes;

/// Create a copy of Client
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClientCopyWith<_Client> get copyWith => __$ClientCopyWithImpl<_Client>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClientToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Client&&(identical(other.id, id) || other.id == id)&&(identical(other.businessId, businessId) || other.businessId == businessId)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.address, address) || other.address == address)&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.notes, notes) || other.notes == notes)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.lifecycle, lifecycle) || other.lifecycle == lifecycle)&&(identical(other.lastContactDate, lastContactDate) || other.lastContactDate == lastContactDate)&&(identical(other.lastAppointmentDate, lastAppointmentDate) || other.lastAppointmentDate == lastAppointmentDate)&&const DeepCollectionEquality().equals(other._preferences, _preferences)&&const DeepCollectionEquality().equals(other._customFields, _customFields)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.hasPaymentMethod, hasPaymentMethod) || other.hasPaymentMethod == hasPaymentMethod)&&(identical(other.stripeCustomerId, stripeCustomerId) || other.stripeCustomerId == stripeCustomerId)&&(identical(other.serviceLatitude, serviceLatitude) || other.serviceLatitude == serviceLatitude)&&(identical(other.serviceLongitude, serviceLongitude) || other.serviceLongitude == serviceLongitude)&&(identical(other.serviceNotes, serviceNotes) || other.serviceNotes == serviceNotes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,businessId,firstName,lastName,email,phone,address,birthDate,notes,const DeepCollectionEquality().hash(_tags),lifecycle,lastContactDate,lastAppointmentDate,const DeepCollectionEquality().hash(_preferences),const DeepCollectionEquality().hash(_customFields),createdAt,updatedAt,userId,hasPaymentMethod,stripeCustomerId,serviceLatitude,serviceLongitude,serviceNotes]);

@override
String toString() {
  return 'Client(id: $id, businessId: $businessId, firstName: $firstName, lastName: $lastName, email: $email, phone: $phone, address: $address, birthDate: $birthDate, notes: $notes, tags: $tags, lifecycle: $lifecycle, lastContactDate: $lastContactDate, lastAppointmentDate: $lastAppointmentDate, preferences: $preferences, customFields: $customFields, createdAt: $createdAt, updatedAt: $updatedAt, userId: $userId, hasPaymentMethod: $hasPaymentMethod, stripeCustomerId: $stripeCustomerId, serviceLatitude: $serviceLatitude, serviceLongitude: $serviceLongitude, serviceNotes: $serviceNotes)';
}


}

/// @nodoc
abstract mixin class _$ClientCopyWith<$Res> implements $ClientCopyWith<$Res> {
  factory _$ClientCopyWith(_Client value, $Res Function(_Client) _then) = __$ClientCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessId, String firstName, String lastName, String? email, String? phone, String? address,@NullableTimestampConverter() DateTime? birthDate, String? notes, List<String> tags, ClientLifecycle lifecycle,@NullableTimestampConverter() DateTime? lastContactDate,@NullableTimestampConverter() DateTime? lastAppointmentDate, Map<String, dynamic> preferences, Map<String, dynamic> customFields,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? updatedAt, String? userId, bool hasPaymentMethod, String? stripeCustomerId, double? serviceLatitude, double? serviceLongitude, String? serviceNotes
});




}
/// @nodoc
class __$ClientCopyWithImpl<$Res>
    implements _$ClientCopyWith<$Res> {
  __$ClientCopyWithImpl(this._self, this._then);

  final _Client _self;
  final $Res Function(_Client) _then;

/// Create a copy of Client
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessId = null,Object? firstName = null,Object? lastName = null,Object? email = freezed,Object? phone = freezed,Object? address = freezed,Object? birthDate = freezed,Object? notes = freezed,Object? tags = null,Object? lifecycle = null,Object? lastContactDate = freezed,Object? lastAppointmentDate = freezed,Object? preferences = null,Object? customFields = null,Object? createdAt = null,Object? updatedAt = freezed,Object? userId = freezed,Object? hasPaymentMethod = null,Object? stripeCustomerId = freezed,Object? serviceLatitude = freezed,Object? serviceLongitude = freezed,Object? serviceNotes = freezed,}) {
  return _then(_Client(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessId: null == businessId ? _self.businessId : businessId // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,birthDate: freezed == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
as DateTime?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,lifecycle: null == lifecycle ? _self.lifecycle : lifecycle // ignore: cast_nullable_to_non_nullable
as ClientLifecycle,lastContactDate: freezed == lastContactDate ? _self.lastContactDate : lastContactDate // ignore: cast_nullable_to_non_nullable
as DateTime?,lastAppointmentDate: freezed == lastAppointmentDate ? _self.lastAppointmentDate : lastAppointmentDate // ignore: cast_nullable_to_non_nullable
as DateTime?,preferences: null == preferences ? _self._preferences : preferences // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,customFields: null == customFields ? _self._customFields : customFields // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,hasPaymentMethod: null == hasPaymentMethod ? _self.hasPaymentMethod : hasPaymentMethod // ignore: cast_nullable_to_non_nullable
as bool,stripeCustomerId: freezed == stripeCustomerId ? _self.stripeCustomerId : stripeCustomerId // ignore: cast_nullable_to_non_nullable
as String?,serviceLatitude: freezed == serviceLatitude ? _self.serviceLatitude : serviceLatitude // ignore: cast_nullable_to_non_nullable
as double?,serviceLongitude: freezed == serviceLongitude ? _self.serviceLongitude : serviceLongitude // ignore: cast_nullable_to_non_nullable
as double?,serviceNotes: freezed == serviceNotes ? _self.serviceNotes : serviceNotes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
