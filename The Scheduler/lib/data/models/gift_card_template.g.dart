// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gift_card_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GiftCardTemplate _$GiftCardTemplateFromJson(Map<String, dynamic> json) =>
    _GiftCardTemplate(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      backgroundColor: json['backgroundColor'] as String,
      textColor: json['textColor'] as String,
      presetAmountsCents: (json['presetAmountsCents'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      minAmountCents: (json['minAmountCents'] as num?)?.toInt(),
      maxAmountCents: (json['maxAmountCents'] as num?)?.toInt(),
      validityDays: (json['validityDays'] as num?)?.toInt(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
    );

Map<String, dynamic> _$GiftCardTemplateToJson(_GiftCardTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'businessId': instance.businessId,
      'name': instance.name,
      'description': instance.description,
      'imageUrl': instance.imageUrl,
      'backgroundColor': instance.backgroundColor,
      'textColor': instance.textColor,
      'presetAmountsCents': instance.presetAmountsCents,
      'minAmountCents': instance.minAmountCents,
      'maxAmountCents': instance.maxAmountCents,
      'validityDays': instance.validityDays,
      'isActive': instance.isActive,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
    };
