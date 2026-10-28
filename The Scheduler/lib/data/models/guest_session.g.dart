// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guest_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GuestSession _$GuestSessionFromJson(Map<String, dynamic> json) =>
    _GuestSession(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      verificationMethod: $enumDecode(
        _$GuestVerificationMethodEnumMap,
        json['verificationMethod'],
      ),
      isVerified: json['isVerified'] as bool,
      expiresAt: const _TimestampConverter().fromJson(json['expiresAt']),
      verifiedAt: const _TimestampConverter().fromJson(json['verifiedAt']),
      createdAt: const _TimestampConverter().fromJson(json['createdAt']),
    );

Map<String, dynamic> _$GuestSessionToJson(_GuestSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'businessId': instance.businessId,
      'fullName': instance.fullName,
      'email': instance.email,
      'phone': instance.phone,
      'verificationMethod':
          _$GuestVerificationMethodEnumMap[instance.verificationMethod]!,
      'isVerified': instance.isVerified,
      'expiresAt': const _TimestampConverter().toJson(instance.expiresAt),
      'verifiedAt': _$JsonConverterToJson<dynamic, DateTime>(
        instance.verifiedAt,
        const _TimestampConverter().toJson,
      ),
      'createdAt': _$JsonConverterToJson<dynamic, DateTime>(
        instance.createdAt,
        const _TimestampConverter().toJson,
      ),
    };

const _$GuestVerificationMethodEnumMap = {
  GuestVerificationMethod.sms: 'sms',
  GuestVerificationMethod.email: 'email',
};

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);

_VerificationResult _$VerificationResultFromJson(Map<String, dynamic> json) =>
    _VerificationResult(
      sessionId: json['sessionId'] as String,
      expiresAt: const _TimestampConverter().fromJson(json['expiresAt']),
      attemptsRemaining: (json['attemptsRemaining'] as num).toInt(),
    );

Map<String, dynamic> _$VerificationResultToJson(_VerificationResult instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'expiresAt': const _TimestampConverter().toJson(instance.expiresAt),
      'attemptsRemaining': instance.attemptsRemaining,
    };
