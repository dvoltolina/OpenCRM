// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Business _$BusinessFromJson(Map<String, dynamic> json) => _Business(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  contactEmail: json['contactEmail'] as String?,
  contactPhone: json['contactPhone'] as String?,
  createdAt: const _TimestampConverter().fromJson(json['createdAt']),
  industry:
      $enumDecodeNullable(_$BusinessIndustryEnumMap, json['industry']) ??
      BusinessIndustry.other,
  requiresHipaaCompliance: json['requiresHipaaCompliance'] as bool? ?? false,
  mfaEnabled: json['mfaEnabled'] as bool? ?? false,
);

Map<String, dynamic> _$BusinessToJson(_Business instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'contactEmail': instance.contactEmail,
  'contactPhone': instance.contactPhone,
  'createdAt': const _TimestampConverter().toJson(instance.createdAt),
  'industry': _$BusinessIndustryEnumMap[instance.industry]!,
  'requiresHipaaCompliance': instance.requiresHipaaCompliance,
  'mfaEnabled': instance.mfaEnabled,
};

const _$BusinessIndustryEnumMap = {
  BusinessIndustry.healthcareMedical: 'healthcare_medical',
  BusinessIndustry.behavioralHealth: 'behavioral_health',
  BusinessIndustry.dentalOptometry: 'dental_optometry',
  BusinessIndustry.wellness: 'wellness',
  BusinessIndustry.beautySalon: 'beauty_salon',
  BusinessIndustry.fitness: 'fitness',
  BusinessIndustry.realEstate: 'real_estate',
  BusinessIndustry.coaching: 'coaching',
  BusinessIndustry.professionalServices: 'professional_services',
  BusinessIndustry.education: 'education',
  BusinessIndustry.other: 'other',
};
