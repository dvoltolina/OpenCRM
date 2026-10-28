import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/file_storage_service.dart';
import '../../../../data/models/file_attachment.dart';
import '../../../../data/models/intake_form.dart' as intake_models;
import '../../../../data/models/security_context.dart';
import '../../../../data/repositories/file_attachment_repository.dart';
import 'intake_attachment_picker.dart';

class IntakeFieldUtils {
  static bool isFileField(intake_models.FormField field) {
    final rawType = field.metadata['type'] ?? field.metadata['inputType'];
    return rawType is String && rawType.toLowerCase() == 'file';
  }

  static bool allowMultipleFiles(intake_models.FormField field) {
    final raw = field.metadata['allowMultiple'] ?? field.metadata['multiple'];
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    return true;
  }

  static int? maxFiles(intake_models.FormField field) {
    final raw = field.metadata['maxFiles'];
    if (raw is num) return raw.toInt();
    return null;
  }

  static List<String>? allowedExtensions(intake_models.FormField field) {
    final raw = field.metadata['allowedExtensions'];
    if (raw is List) {
      return raw.map((e) => e.toString().toLowerCase()).toList();
    }
    return null;
  }

  static int? intFromMetadata(intake_models.FormField field, String key) {
    final raw = field.metadata[key];
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  static num? numFromMetadata(intake_models.FormField field, String key) {
    final raw = field.metadata[key];
    if (raw is num) return raw;
    if (raw is String) return num.tryParse(raw);
    return null;
  }

  static TextInputType keyboardType(intake_models.FormField field) {
    switch (field.type) {
      case intake_models.FormFieldType.email:
        return TextInputType.emailAddress;
      case intake_models.FormFieldType.phone:
        return TextInputType.phone;
      case intake_models.FormFieldType.number:
        return TextInputType.number;
      case intake_models.FormFieldType.multiline:
        return TextInputType.multiline;
      default:
        return TextInputType.text;
    }
  }
}

class IntakeFieldValidator {
  static String? validate({
    required intake_models.FormField field,
    required Map<String, dynamic> responses,
    required Map<String, List<FileAttachment>> fieldAttachments,
  }) {
    final value = responses[field.id];

    if (IntakeFieldUtils.isFileField(field)) {
      final files = fieldAttachments[field.id] ?? [];
      if (field.required && files.isEmpty) {
        return 'Please upload a file.';
      }
      final maxFiles = IntakeFieldUtils.maxFiles(field);
      if (maxFiles != null && files.length > maxFiles) {
        return 'Maximum $maxFiles file(s) allowed.';
      }
      return null;
    }

    switch (field.type) {
      case intake_models.FormFieldType.checkbox:
        if (field.required && value != true) {
          return 'Please confirm to proceed.';
        }
        return null;
      case intake_models.FormFieldType.dropdown:
      case intake_models.FormFieldType.radio:
        if (field.required &&
            (value == null || (value is String && value.isEmpty))) {
          return 'Please choose an option.';
        }
        if (value != null &&
            field.options.isNotEmpty &&
            !field.options.contains(value)) {
          return 'Select a valid option.';
        }
        return null;
      case intake_models.FormFieldType.date:
        if (field.required &&
            (value == null || (value is String && value.isEmpty))) {
          return 'Date is required.';
        }
        return null;
      default:
        final textValue = value?.toString().trim() ?? '';
        if (field.required && textValue.isEmpty) {
          return 'This field is required.';
        }
        final minLength = IntakeFieldUtils.intFromMetadata(field, 'minLength');
        final maxLength = IntakeFieldUtils.intFromMetadata(field, 'maxLength');
        if (minLength != null &&
            textValue.isNotEmpty &&
            textValue.length < minLength) {
          return 'Enter at least $minLength characters.';
        }
        if (maxLength != null && textValue.length > maxLength) {
          return 'Maximum $maxLength characters.';
        }
        if (field.type == intake_models.FormFieldType.number &&
            textValue.isNotEmpty) {
          final number = num.tryParse(textValue);
          if (number == null) {
            return 'Enter a valid number.';
          }
          final min = IntakeFieldUtils.numFromMetadata(field, 'min') ??
              IntakeFieldUtils.numFromMetadata(field, 'minValue');
          final max = IntakeFieldUtils.numFromMetadata(field, 'max') ??
              IntakeFieldUtils.numFromMetadata(field, 'maxValue');
          if (min != null && number < min) {
            return 'Must be at least $min';
          }
          if (max != null && number > max) {
            return 'Must be $max or less';
          }
        }
        if (field.validation != null && textValue.isNotEmpty) {
          try {
            final regex = RegExp(field.validation!);
            if (!regex.hasMatch(textValue)) {
              return 'Invalid format.';
            }
          } catch (_) {}
        }
        return null;
    }
  }
}

class IntakeFieldRenderer extends StatelessWidget {
  const IntakeFieldRenderer({
    super.key,
    required this.field,
    required this.errorText,
    required this.responses,
    required this.controllers,
    required this.onChanged,
    required this.onFileChanged,
    required this.securityContext,
    required this.templateId,
    required this.clientId,
    required this.storageService,
    required this.attachments,
    required this.attachmentsEnabled,
    this.appointmentId,
    this.attachmentRepository,
  });

  final intake_models.FormField field;
  final String? errorText;
  final Map<String, dynamic> responses;
  final Map<String, TextEditingController> controllers;
  final ValueChanged<dynamic> onChanged;
  final ValueChanged<List<FileAttachment>> onFileChanged;
  final SecurityContext securityContext;
  final String templateId;
  final String clientId;
  final String? appointmentId;
  final FileStorageService storageService;
  final FileAttachmentRepository? attachmentRepository;
  final List<FileAttachment> attachments;
  final bool attachmentsEnabled;

  @override
  Widget build(BuildContext context) {
    if (IntakeFieldUtils.isFileField(field)) {
      return _buildFileField(context);
    }

    switch (field.type) {
      case intake_models.FormFieldType.text:
      case intake_models.FormFieldType.email:
      case intake_models.FormFieldType.phone:
      case intake_models.FormFieldType.number:
      case intake_models.FormFieldType.multiline:
        final controller = _controllerForField();
        return TextField(
          controller: controller,
          keyboardType: IntakeFieldUtils.keyboardType(field),
          minLines: field.type == intake_models.FormFieldType.multiline ? 3 : 1,
          maxLines: field.type == intake_models.FormFieldType.multiline ? 6 : 1,
          decoration: InputDecoration(
            labelText: '${field.label}${field.required ? ' *' : ''}',
            hintText: field.placeholder,
            helperText: field.helpText,
            errorText: errorText,
            counterText: '',
          ),
          onChanged: onChanged,
        );
      case intake_models.FormFieldType.dropdown:
        if (field.options.isEmpty) {
          return Text(
            '${field.label}: No options configured',
            style: Theme.of(context).textTheme.bodySmall,
          );
        }
        return DropdownButtonFormField<String>(
          initialValue: responses[field.id] as String?,
          items: field.options
              .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
              .toList(),
          decoration: InputDecoration(
            labelText: '${field.label}${field.required ? ' *' : ''}',
            errorText: errorText,
          ),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        );
      case intake_models.FormFieldType.radio:
        if (field.options.isEmpty) {
          return Text(
            '${field.label}: No options configured',
            style: Theme.of(context).textTheme.bodySmall,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${field.label}${field.required ? ' *' : ''}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            RadioGroup<String>(
              groupValue: responses[field.id] as String?,
              onChanged: (value) {
                if (value != null) onChanged(value);
              },
              child: Column(
                children: field.options
                    .map(
                      (opt) => RadioListTile<String>(
                        dense: true,
                        title: Text(opt),
                        value: opt,
                      ),
                    )
                    .toList(),
              ),
            ),
            if (errorText != null)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  errorText!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        );
      case intake_models.FormFieldType.checkbox:
        final current = responses[field.id] as bool? ?? false;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              value: current,
              onChanged: (value) => onChanged(value ?? false),
              title: Text('${field.label}${field.required ? ' *' : ''}'),
              subtitle:
                  field.helpText != null ? Text(field.helpText!) : null,
            ),
            if (errorText != null)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  errorText!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        );
      case intake_models.FormFieldType.date:
        final value = responses[field.id] as String?;
        final subtitle = value != null
            ? DateFormat('yMMMd h:mm a')
                .format(DateTime.parse(value).toLocal())
            : 'Select date';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${field.label}${field.required ? ' *' : ''}'),
              subtitle: Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  onChanged(picked.toIso8601String());
                }
              },
            ),
            if (errorText != null)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  errorText!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        );
    }
  }

  TextEditingController _controllerForField() {
    final existing = controllers[field.id];
    if (existing != null) return existing;
    final controller = TextEditingController(
      text: responses[field.id]?.toString() ?? '',
    );
    controllers[field.id] = controller;
    return controller;
  }

  Widget _buildFileField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntakeAttachmentPicker(
          label: '${field.label}${field.required ? ' *' : ''}',
          securityContext: securityContext,
          clientId: clientId,
          templateId: templateId,
          appointmentId: appointmentId,
          attachments: attachments,
          storageService: storageService,
          attachmentRepository: attachmentRepository,
          enabled: attachmentsEnabled,
          allowMultiple: IntakeFieldUtils.allowMultipleFiles(field),
          maxFiles: IntakeFieldUtils.maxFiles(field),
          allowedExtensions: IntakeFieldUtils.allowedExtensions(field),
          extraMetadata: {'fieldId': field.id},
          onChanged: onFileChanged,
        ),
        if (!attachmentsEnabled)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Sign in or provide your client link to upload documents.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}
