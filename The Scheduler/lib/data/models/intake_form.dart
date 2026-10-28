import 'package:freezed_annotation/freezed_annotation.dart';

import '../converters/timestamp_converters.dart';

part 'intake_form.freezed.dart';
part 'intake_form.g.dart';

/// Type of form field
enum FormFieldType {
  text,
  multiline,
  email,
  phone,
  date,
  dropdown,
  checkbox,
  radio,
  number,
}

/// Single field in a form template
@freezed
abstract class FormField with _$FormField {
  const factory FormField({
    required String id,
    required String label,
    required FormFieldType type,
    String? placeholder,
    String? helpText,
    @Default(false) bool required,
    @Default([]) List<String> options, // For dropdown/radio
    String? validation, // Regex pattern for validation
    @Default({}) Map<String, dynamic> metadata,
  }) = _FormField;

  factory FormField.fromJson(Map<String, dynamic> json) =>
      _$FormFieldFromJson(_normalizeFormFieldJson(json));

  static Map<String, dynamic> _normalizeFormFieldJson(
    Map<String, dynamic> json,
  ) {
    final normalized = Map<String, dynamic>.from(json);
    final metadata = normalized['metadata'];
    if (metadata is Map && metadata is! Map<String, dynamic>) {
      normalized['metadata'] = Map<String, dynamic>.from(metadata);
    }
    return normalized;
  }
}

/// Intake form template
@freezed
abstract class IntakeFormTemplate with _$IntakeFormTemplate {
  const factory IntakeFormTemplate({
    required String id,
    required String businessId,
    required String name,
    String? description,
    @Default([]) List<FormField> fields,
    @Default([]) List<String> applicableIndustries, // therapist, dentist, etc.
    @Default(true) bool isActive,
    @TimestampConverter() required DateTime createdAt,
    @NullableTimestampConverter() DateTime? updatedAt,
    int? version, // For versioning forms
  }) = _IntakeFormTemplate;

  factory IntakeFormTemplate.fromJson(Map<String, dynamic> json) =>
      _$IntakeFormTemplateFromJson(_normalizeTemplateJson(json));

  static Map<String, dynamic> _normalizeTemplateJson(
    Map<String, dynamic> json,
  ) {
    final normalized = Map<String, dynamic>.from(json);
    final fields = normalized['fields'];
    if (fields is List) {
      normalized['fields'] = fields
          .map(
            (field) => field is Map<String, dynamic>
                ? field
                : Map<String, dynamic>.from(field as Map<dynamic, dynamic>),
          )
          .toList();
    }
    return normalized;
  }

  const IntakeFormTemplate._();

  /// Get field count
  int get fieldCount => fields.length;

  /// Get required field count
  int get requiredFieldCount => fields.where((f) => f.required).length;
}

/// Completed intake form submission
@freezed
abstract class IntakeFormSubmission with _$IntakeFormSubmission {
  const factory IntakeFormSubmission({
    required String id,
    required String businessId,
    required String clientId,
    required String templateId,
    String? templateName,
    int? templateVersion,
    required Map<String, dynamic> responses, // fieldId -> value
    @TimestampConverter() required DateTime submittedAt,
    String? submittedBy, // userId if submitted by staff
  }) = _IntakeFormSubmission;

  factory IntakeFormSubmission.fromJson(Map<String, dynamic> json) =>
      _$IntakeFormSubmissionFromJson(json);

  const IntakeFormSubmission._();

  /// Alias for templateName for UI consistency
  String get formTitle => templateName ?? 'Untitled Form';

  /// Check if a specific field was answered
  bool hasResponse(String fieldId) => responses.containsKey(fieldId);

  /// Get response for a field
  dynamic getResponse(String fieldId) => responses[fieldId];
}

/// Default template factory for common form types
class DefaultIntakeTemplates {
  /// Medical/therapy intake form
  static IntakeFormTemplate medicalIntake({
    required String businessId,
  }) {
    return IntakeFormTemplate(
      id: 'template_medical_default',
      businessId: businessId,
      name: 'Medical Intake Form',
      description: 'Standard medical history and intake questionnaire',
      applicableIndustries: ['therapist', 'dentist', 'chiropractor'],
      fields: [
        const FormField(
          id: 'medical_history',
          label: 'Medical History',
          type: FormFieldType.multiline,
          placeholder: 'Please describe any relevant medical conditions...',
          required: true,
        ),
        const FormField(
          id: 'medications',
          label: 'Current Medications',
          type: FormFieldType.multiline,
          placeholder: 'List all medications you are currently taking...',
          required: false,
        ),
        const FormField(
          id: 'allergies',
          label: 'Allergies',
          type: FormFieldType.text,
          placeholder: 'Any known allergies?',
          required: false,
        ),
        const FormField(
          id: 'emergency_contact',
          label: 'Emergency Contact Name',
          type: FormFieldType.text,
          required: true,
        ),
        const FormField(
          id: 'emergency_phone',
          label: 'Emergency Contact Phone',
          type: FormFieldType.phone,
          required: true,
        ),
        const FormField(
          id: 'insurance_provider',
          label: 'Insurance Provider',
          type: FormFieldType.text,
          required: false,
        ),
        const FormField(
          id: 'insurance_id',
          label: 'Insurance ID Number',
          type: FormFieldType.text,
          required: false,
        ),
        const FormField(
          id: 'consent',
          label: 'I consent to treatment and understand the privacy policy',
          type: FormFieldType.checkbox,
          required: true,
        ),
      ],
      createdAt: DateTime.now(),
      version: 1,
    );
  }

  /// Real estate client preferences form
  static IntakeFormTemplate realEstatePreferences({
    required String businessId,
  }) {
    return IntakeFormTemplate(
      id: 'template_realestate_default',
      businessId: businessId,
      name: 'Client Preferences Form',
      description: 'Real estate client preferences and requirements',
      applicableIndustries: ['realtor'],
      fields: [
        const FormField(
          id: 'property_type',
          label: 'Property Type',
          type: FormFieldType.dropdown,
          options: ['House', 'Condo', 'Townhouse', 'Land', 'Commercial'],
          required: true,
        ),
        const FormField(
          id: 'budget_min',
          label: 'Minimum Budget',
          type: FormFieldType.number,
          required: true,
        ),
        const FormField(
          id: 'budget_max',
          label: 'Maximum Budget',
          type: FormFieldType.number,
          required: true,
        ),
        const FormField(
          id: 'bedrooms',
          label: 'Number of Bedrooms',
          type: FormFieldType.number,
          required: true,
        ),
        const FormField(
          id: 'bathrooms',
          label: 'Number of Bathrooms',
          type: FormFieldType.number,
          required: true,
        ),
        const FormField(
          id: 'preferred_areas',
          label: 'Preferred Areas/Neighborhoods',
          type: FormFieldType.multiline,
          placeholder: 'List your preferred areas...',
          required: false,
        ),
        const FormField(
          id: 'must_haves',
          label: 'Must-Have Features',
          type: FormFieldType.multiline,
          placeholder: 'e.g., backyard, garage, modern kitchen...',
          required: false,
        ),
        const FormField(
          id: 'timeline',
          label: 'Purchase Timeline',
          type: FormFieldType.dropdown,
          options: [
            'Immediately',
            'Within 3 months',
            'Within 6 months',
            'Within 1 year',
            'Just browsing',
          ],
          required: true,
        ),
      ],
      createdAt: DateTime.now(),
      version: 1,
    );
  }
}
