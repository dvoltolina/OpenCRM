import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/intake_form.dart';
import '../../helpers/test_data_factories.dart';

void main() {
  group('IntakeForm Models', () {
    group('FormField', () {
      group('JSON Serialization', () {
        test('creates form field from JSON', () {
          final json = {
            'id': 'field-1',
            'label': 'Medical History',
            'type': 'multiline',
            'placeholder': 'Please describe...',
            'helpText': 'Include any allergies or conditions',
            'required': true,
            'options': [],
            'validation': null,
            'metadata': {},
          };

          final field = FormField.fromJson(json);

          expect(field.id, 'field-1');
          expect(field.label, 'Medical History');
          expect(field.type, FormFieldType.multiline);
          expect(field.placeholder, 'Please describe...');
          expect(field.required, true);
        });

        test('converts form field to JSON', () {
          const field = FormField(
            id: 'field-1',
            label: 'Name',
            type: FormFieldType.text,
            required: true,
          );

          final json = field.toJson();

          expect(json['id'], 'field-1');
          expect(json['label'], 'Name');
          expect(json['type'], 'text');
          expect(json['required'], true);
        });

        test('handles all field types', () {
          expect(FormFieldType.text.name, 'text');
          expect(FormFieldType.multiline.name, 'multiline');
          expect(FormFieldType.email.name, 'email');
          expect(FormFieldType.phone.name, 'phone');
          expect(FormFieldType.date.name, 'date');
          expect(FormFieldType.dropdown.name, 'dropdown');
          expect(FormFieldType.checkbox.name, 'checkbox');
          expect(FormFieldType.radio.name, 'radio');
          expect(FormFieldType.number.name, 'number');
        });
      });

      test('dropdown field with options', () {
        const field = FormField(
          id: 'insurance-type',
          label: 'Insurance Type',
          type: FormFieldType.dropdown,
          options: ['Private', 'Medicare', 'Medicaid', 'None'],
          required: true,
        );

        expect(field.type, FormFieldType.dropdown);
        expect(field.options.length, 4);
        expect(field.options.contains('Medicare'), true);
      });

      test('radio field with options', () {
        const field = FormField(
          id: 'gender',
          label: 'Gender',
          type: FormFieldType.radio,
          options: ['Male', 'Female', 'Other', 'Prefer not to say'],
          required: false,
        );

        expect(field.type, FormFieldType.radio);
        expect(field.options.length, 4);
      });

      test('email field with validation', () {
        const field = FormField(
          id: 'email',
          label: 'Email Address',
          type: FormFieldType.email,
          validation: r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
          required: true,
        );

        expect(field.type, FormFieldType.email);
        expect(field.validation, isNotNull);
      });
    });

    group('IntakeFormTemplate', () {
      group('JSON Serialization', () {
        test('creates template from JSON', () {
          final json = {
            'id': 'template-1',
            'businessId': 'business-1',
            'name': 'Medical Intake',
            'description': 'Standard medical history form',
            'fields': [
              {
                'id': 'field-1',
                'label': 'Name',
                'type': 'text',
                'required': true,
                'options': [],
                'metadata': {},
              }
            ],
            'applicableIndustries': ['medical', 'dental'],
            'isActive': true,
            'createdAt': '2025-12-01T10:00:00.000Z',
            'version': 1,
          };

          final template = IntakeFormTemplate.fromJson(json);

          expect(template.id, 'template-1');
          expect(template.businessId, 'business-1');
          expect(template.name, 'Medical Intake');
          expect(template.fields.length, 1);
          expect(template.applicableIndustries.length, 2);
          expect(template.version, 1);
        });

        test('converts template to JSON', () {
          final template = TestData.intakeFormTemplate(
            id: 'template-1',
            name: 'Test Form',
          );

          final json = template.toJson();

          expect(json['id'], 'template-1');
          expect(json['name'], 'Test Form');
          expect(json['isActive'], true);
        });
      });

      test('fieldCount returns correct count', () {
        final template = IntakeFormTemplate(
          id: 'template-1',
          businessId: 'business-1',
          name: 'Test Form',
          fields: const [
            FormField(id: 'f1', label: 'Field 1', type: FormFieldType.text),
            FormField(id: 'f2', label: 'Field 2', type: FormFieldType.email),
            FormField(id: 'f3', label: 'Field 3', type: FormFieldType.phone),
          ],
          createdAt: TestData.testDate,
        );

        expect(template.fieldCount, 3);
      });

      test('requiredFieldCount returns correct count', () {
        final template = IntakeFormTemplate(
          id: 'template-1',
          businessId: 'business-1',
          name: 'Test Form',
          fields: const [
            FormField(
                id: 'f1', label: 'Field 1', type: FormFieldType.text, required: true),
            FormField(
                id: 'f2', label: 'Field 2', type: FormFieldType.email, required: true),
            FormField(id: 'f3', label: 'Field 3', type: FormFieldType.phone),
          ],
          createdAt: TestData.testDate,
        );

        expect(template.requiredFieldCount, 2);
      });

      test('supports multi-tenant isolation', () {
        final template1 =
            TestData.intakeFormTemplate(businessId: 'business-1');
        final template2 =
            TestData.intakeFormTemplate(businessId: 'business-2');

        expect(template1.businessId, 'business-1');
        expect(template2.businessId, 'business-2');
        expect(template1.businessId, isNot(template2.businessId));
      });

      test('can be activated and deactivated', () {
        var template = TestData.intakeFormTemplate(isActive: true);
        expect(template.isActive, true);

        template = template.copyWith(isActive: false);
        expect(template.isActive, false);
      });
    });

    group('IntakeFormSubmission', () {
      group('JSON Serialization', () {
        test('creates submission from JSON', () {
          final json = {
            'id': 'submission-1',
            'businessId': 'business-1',
            'clientId': 'client-1',
            'templateId': 'template-1',
            'templateName': 'Medical Intake',
            'templateVersion': 1,
            'responses': {
              'field-1': 'John Doe',
              'field-2': 'john@example.com',
            },
            'submittedAt': '2025-12-01T10:00:00.000Z',
            'submittedBy': 'user-1',
          };

          final submission = IntakeFormSubmission.fromJson(json);

          expect(submission.id, 'submission-1');
          expect(submission.businessId, 'business-1');
          expect(submission.clientId, 'client-1');
          expect(submission.templateId, 'template-1');
          expect(submission.responses.length, 2);
          expect(submission.responses['field-1'], 'John Doe');
        });

        test('converts submission to JSON', () {
          final submission = TestData.intakeFormSubmission(
            id: 'submission-1',
            responses: {'field-1': 'Test Value'},
          );

          final json = submission.toJson();

          expect(json['id'], 'submission-1');
          expect(json['responses']['field-1'], 'Test Value');
        });
      });

      test('supports multi-tenant isolation', () {
        final submission1 =
            TestData.intakeFormSubmission(businessId: 'business-1');
        final submission2 =
            TestData.intakeFormSubmission(businessId: 'business-2');

        expect(submission1.businessId, 'business-1');
        expect(submission2.businessId, 'business-2');
        expect(submission1.businessId, isNot(submission2.businessId));
      });

      test('tracks who submitted', () {
        // Client self-submitted
        final clientSubmission = TestData.intakeFormSubmission(
          submittedBy: null,
        );

        expect(clientSubmission.submittedBy, null);

        // Staff submitted on behalf of client
        final staffSubmission = TestData.intakeFormSubmission(
          submittedBy: 'staff-user-1',
        );

        expect(staffSubmission.submittedBy, 'staff-user-1');
      });
    });

    group('Real-World Examples', () {
      test('medical intake form', () {
        final medicalForm = IntakeFormTemplate(
          id: 'medical-intake',
          businessId: 'clinic-1',
          name: 'Medical History Form',
          description: 'Comprehensive medical history and allergies',
          fields: const [
            FormField(
              id: 'full-name',
              label: 'Full Name',
              type: FormFieldType.text,
              required: true,
            ),
            FormField(
              id: 'dob',
              label: 'Date of Birth',
              type: FormFieldType.date,
              required: true,
            ),
            FormField(
              id: 'allergies',
              label: 'Known Allergies',
              type: FormFieldType.multiline,
              helpText: 'List all known allergies',
              required: false,
            ),
            FormField(
              id: 'medications',
              label: 'Current Medications',
              type: FormFieldType.multiline,
              required: false,
            ),
            FormField(
              id: 'insurance',
              label: 'Insurance Provider',
              type: FormFieldType.dropdown,
              options: ['Blue Cross', 'Aetna', 'Medicare', 'Self-Pay'],
              required: true,
            ),
          ],
          applicableIndustries: ['medical', 'dental'],
          createdAt: TestData.testDate,
          version: 1,
        );

        expect(medicalForm.fieldCount, 5);
        expect(medicalForm.requiredFieldCount, 3);
      });

      test('therapy intake form', () {
        final therapyForm = IntakeFormTemplate(
          id: 'therapy-intake',
          businessId: 'therapy-center-1',
          name: 'Therapy Intake Questionnaire',
          description: 'Initial assessment for new therapy clients',
          fields: const [
            FormField(
              id: 'name',
              label: 'Name',
              type: FormFieldType.text,
              required: true,
            ),
            FormField(
              id: 'reason',
              label: 'Reason for Seeking Therapy',
              type: FormFieldType.multiline,
              placeholder: 'Please describe...',
              required: true,
            ),
            FormField(
              id: 'previous-therapy',
              label: 'Have you been in therapy before?',
              type: FormFieldType.radio,
              options: ['Yes', 'No'],
              required: true,
            ),
            FormField(
              id: 'emergency-contact',
              label: 'Emergency Contact',
              type: FormFieldType.text,
              required: true,
            ),
            FormField(
              id: 'emergency-phone',
              label: 'Emergency Contact Phone',
              type: FormFieldType.phone,
              required: true,
            ),
          ],
          applicableIndustries: ['therapy', 'counseling'],
          createdAt: TestData.testDate,
          version: 1,
        );

        expect(therapyForm.fieldCount, 5);
        expect(therapyForm.requiredFieldCount, 5);
        expect(therapyForm.applicableIndustries.contains('therapy'), true);
      });

      test('completed medical submission', () {
        final submission = IntakeFormSubmission(
          id: 'sub-1',
          businessId: 'clinic-1',
          clientId: 'client-1',
          templateId: 'medical-intake',
          templateName: 'Medical History Form',
          templateVersion: 1,
          responses: {
            'full-name': 'Jane Smith',
            'dob': '1990-05-15',
            'allergies': 'Penicillin',
            'medications': 'None',
            'insurance': 'Blue Cross',
          },
          submittedAt: DateTime(2025, 12, 1, 9, 30),
        );

        expect(submission.responses['full-name'], 'Jane Smith');
        expect(submission.responses['allergies'], 'Penicillin');
        expect(submission.responses.length, 5);
      });
    });

    group('Test Data Factories', () {
      test('creates form field with defaults', () {
        const field = FormField(
          id: 'test-field',
          label: 'Test Field',
          type: FormFieldType.text,
        );

        expect(field.id, 'test-field');
        expect(field.required, false);
        expect(field.options, isEmpty);
        expect(field.metadata, isEmpty);
      });

      test('creates template with defaults', () {
        final template = TestData.intakeFormTemplate();

        expect(template.id, isNotEmpty);
        expect(template.businessId, TestData.businessId);
        expect(template.name, isNotEmpty);
        expect(template.isActive, true);
      });

      test('creates submission with defaults', () {
        final submission = TestData.intakeFormSubmission();

        expect(submission.id, isNotEmpty);
        expect(submission.businessId, TestData.businessId);
        expect(submission.clientId, isNotEmpty);
        expect(submission.responses, isNotEmpty);
      });
    });
  });
}
