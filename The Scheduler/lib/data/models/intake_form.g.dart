// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intake_form.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FormField _$FormFieldFromJson(Map<String, dynamic> json) => _FormField(
  id: json['id'] as String,
  label: json['label'] as String,
  type: $enumDecode(_$FormFieldTypeEnumMap, json['type']),
  placeholder: json['placeholder'] as String?,
  helpText: json['helpText'] as String?,
  required: json['required'] as bool? ?? false,
  options:
      (json['options'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  validation: json['validation'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$FormFieldToJson(_FormField instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'type': _$FormFieldTypeEnumMap[instance.type]!,
      'placeholder': instance.placeholder,
      'helpText': instance.helpText,
      'required': instance.required,
      'options': instance.options,
      'validation': instance.validation,
      'metadata': instance.metadata,
    };

const _$FormFieldTypeEnumMap = {
  FormFieldType.text: 'text',
  FormFieldType.multiline: 'multiline',
  FormFieldType.email: 'email',
  FormFieldType.phone: 'phone',
  FormFieldType.date: 'date',
  FormFieldType.dropdown: 'dropdown',
  FormFieldType.checkbox: 'checkbox',
  FormFieldType.radio: 'radio',
  FormFieldType.number: 'number',
};

_IntakeFormTemplate _$IntakeFormTemplateFromJson(Map<String, dynamic> json) =>
    _IntakeFormTemplate(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      fields:
          (json['fields'] as List<dynamic>?)
              ?.map((e) => FormField.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      applicableIndustries:
          (json['applicableIndustries'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isActive: json['isActive'] as bool? ?? true,
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
      version: (json['version'] as num?)?.toInt(),
    );

Map<String, dynamic> _$IntakeFormTemplateToJson(
  _IntakeFormTemplate instance,
) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'name': instance.name,
  'description': instance.description,
  'fields': instance.fields.map((e) => e.toJson()).toList(),
  'applicableIndustries': instance.applicableIndustries,
  'isActive': instance.isActive,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'updatedAt': const NullableTimestampConverter().toJson(instance.updatedAt),
  'version': instance.version,
};

_IntakeFormSubmission _$IntakeFormSubmissionFromJson(
  Map<String, dynamic> json,
) => _IntakeFormSubmission(
  id: json['id'] as String,
  businessId: json['businessId'] as String,
  clientId: json['clientId'] as String,
  templateId: json['templateId'] as String,
  templateName: json['templateName'] as String?,
  templateVersion: (json['templateVersion'] as num?)?.toInt(),
  responses: json['responses'] as Map<String, dynamic>,
  submittedAt: const TimestampConverter().fromJson(json['submittedAt']),
  submittedBy: json['submittedBy'] as String?,
);

Map<String, dynamic> _$IntakeFormSubmissionToJson(
  _IntakeFormSubmission instance,
) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'clientId': instance.clientId,
  'templateId': instance.templateId,
  'templateName': instance.templateName,
  'templateVersion': instance.templateVersion,
  'responses': instance.responses,
  'submittedAt': const TimestampConverter().toJson(instance.submittedAt),
  'submittedBy': instance.submittedBy,
};
