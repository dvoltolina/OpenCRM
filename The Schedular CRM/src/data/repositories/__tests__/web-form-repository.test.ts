/**
 * Web Form Repository Tests
 * Agent Web Forms Implementation
 */

import { describe, it, expect } from 'vitest';
import { validateWebForm, validateWebFormCreate } from '../web-form-repository';
import type { WebForm, WebFormField } from '../../../types/web-forms';

describe('Web Form Repository Validation', () => {
  describe('validateWebForm', () => {
    it('should pass for valid form data', () => {
      const validForm: Partial<WebForm> = {
        name: 'Contact Us',
        description: 'A simple contact form',
        status: 'active',
        fields: [
          {
            id: 'email-1',
            type: 'email',
            label: 'Email',
            required: true,
            mapToField: 'email',
          },
        ],
        settings: {
          submitButtonText: 'Submit',
          successMessage: 'Thank you!',
        },
        spamProtection: {
          honeypot: true,
          rateLimit: 10,
          recaptchaEnabled: false,
        },
        styling: {
          theme: 'light',
          primaryColor: '#3B82F6',
        },
      };

      const result = validateWebForm(validForm);
      expect(result.isValid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });

    it('should fail for empty name', () => {
      const result = validateWebForm({ name: '' });
      expect(result.isValid).toBe(false);
      expect(result.errors.some((e) => e.field === 'name')).toBe(true);
    });

    it('should fail for name exceeding 100 characters', () => {
      const result = validateWebForm({ name: 'a'.repeat(101) });
      expect(result.isValid).toBe(false);
      expect(result.errors.some((e) => e.field === 'name' && e.code === 'TOO_LONG')).toBe(true);
    });

    it('should fail for description exceeding 500 characters', () => {
      const result = validateWebForm({
        name: 'Test Form',
        description: 'a'.repeat(501),
      });
      expect(result.isValid).toBe(false);
      expect(result.errors.some((e) => e.field === 'description')).toBe(true);
    });

    it('should fail for invalid status', () => {
      const result = validateWebForm({
        name: 'Test',
        status: 'invalid' as any,
      });
      expect(result.isValid).toBe(false);
      expect(result.errors.some((e) => e.field === 'status')).toBe(true);
    });

    it('should fail for invalid redirect URL', () => {
      const result = validateWebForm({
        name: 'Test',
        settings: {
          submitButtonText: 'Submit',
          successMessage: 'Thanks',
          redirectUrl: 'not-a-url',
        },
      });
      expect(result.isValid).toBe(false);
      expect(result.errors.some((e) => e.field === 'settings.redirectUrl')).toBe(true);
    });

    it('should fail for invalid notify emails', () => {
      const result = validateWebForm({
        name: 'Test',
        settings: {
          submitButtonText: 'Submit',
          successMessage: 'Thanks',
          notifyEmails: ['valid@example.com', 'invalid-email'],
        },
      });
      expect(result.isValid).toBe(false);
      expect(result.errors.some((e) => e.field.includes('notifyEmails'))).toBe(true);
    });

    it('should fail for rate limit out of range', () => {
      const result = validateWebForm({
        name: 'Test',
        spamProtection: {
          honeypot: true,
          rateLimit: 200, // Max is 100
          recaptchaEnabled: false,
        },
      });
      expect(result.isValid).toBe(false);
      expect(result.errors.some((e) => e.field === 'spamProtection.rateLimit')).toBe(true);
    });

    it('should fail for invalid primary color', () => {
      const result = validateWebForm({
        name: 'Test',
        styling: {
          theme: 'light',
          primaryColor: 'not-a-color',
        },
      });
      expect(result.isValid).toBe(false);
      expect(result.errors.some((e) => e.field === 'styling.primaryColor')).toBe(true);
    });
  });

  describe('validateWebFormCreate', () => {
    it('should require name for creation', () => {
      const result = validateWebFormCreate({
        fields: [
          { id: 'email', type: 'email', label: 'Email', required: true, mapToField: 'email' },
        ],
      });
      expect(result.isValid).toBe(false);
      expect(result.errors.some((e) => e.field === 'name' && e.code === 'REQUIRED')).toBe(true);
    });

    it('should require at least one field', () => {
      const result = validateWebFormCreate({
        name: 'Test Form',
        fields: [],
      });
      expect(result.isValid).toBe(false);
      expect(result.errors.some((e) => e.field === 'fields' && e.code === 'REQUIRED')).toBe(true);
    });

    it('should require an email field', () => {
      const result = validateWebFormCreate({
        name: 'Test Form',
        fields: [
          { id: 'name', type: 'text', label: 'Name', required: true, mapToField: 'firstName' },
        ],
      });
      expect(result.isValid).toBe(false);
      expect(result.errors.some((e) => e.message.includes('email field'))).toBe(true);
    });

    it('should pass for valid form creation data', () => {
      const result = validateWebFormCreate({
        name: 'Valid Form',
        fields: [
          { id: 'firstName', type: 'text', label: 'First Name', required: true, mapToField: 'firstName' },
          { id: 'email', type: 'email', label: 'Email', required: true, mapToField: 'email' },
        ],
        settings: {
          submitButtonText: 'Submit',
          successMessage: 'Thanks',
        },
      });
      expect(result.isValid).toBe(true);
    });
  });

  describe('Field Validation', () => {
    it('should fail for duplicate field IDs', () => {
      const result = validateWebForm({
        name: 'Test',
        fields: [
          { id: 'same-id', type: 'text', label: 'Field 1', required: false, mapToField: 'firstName' },
          { id: 'same-id', type: 'text', label: 'Field 2', required: false, mapToField: 'lastName' },
          { id: 'email', type: 'email', label: 'Email', required: true, mapToField: 'email' },
        ],
      });
      expect(result.isValid).toBe(false);
      expect(result.errors.some((e) => e.code === 'DUPLICATE')).toBe(true);
    });

    it('should fail for missing field ID', () => {
      const result = validateWebForm({
        name: 'Test',
        fields: [
          { id: '', type: 'text', label: 'Field', required: false, mapToField: 'firstName' } as WebFormField,
          { id: 'email', type: 'email', label: 'Email', required: true, mapToField: 'email' },
        ],
      });
      expect(result.isValid).toBe(false);
      expect(result.errors.some((e) => e.message.includes('Field ID is required'))).toBe(true);
    });

    it('should fail for missing field label', () => {
      const result = validateWebForm({
        name: 'Test',
        fields: [
          { id: 'field1', type: 'text', label: '', required: false, mapToField: 'firstName' } as WebFormField,
          { id: 'email', type: 'email', label: 'Email', required: true, mapToField: 'email' },
        ],
      });
      expect(result.isValid).toBe(false);
      expect(result.errors.some((e) => e.message.includes('Field label is required'))).toBe(true);
    });

    it('should fail for invalid field type', () => {
      const result = validateWebForm({
        name: 'Test',
        fields: [
          { id: 'field1', type: 'invalid' as any, label: 'Field', required: false, mapToField: 'firstName' },
          { id: 'email', type: 'email', label: 'Email', required: true, mapToField: 'email' },
        ],
      });
      expect(result.isValid).toBe(false);
      expect(result.errors.some((e) => e.message.includes('Invalid field type'))).toBe(true);
    });

    it('should fail for select field without options', () => {
      const result = validateWebForm({
        name: 'Test',
        fields: [
          { id: 'select1', type: 'select', label: 'Select', required: false, mapToField: 'source', options: [] },
          { id: 'email', type: 'email', label: 'Email', required: true, mapToField: 'email' },
        ],
      });
      expect(result.isValid).toBe(false);
      expect(result.errors.some((e) => e.message.includes('at least one option'))).toBe(true);
    });

    it('should fail for invalid field mapping', () => {
      const result = validateWebForm({
        name: 'Test',
        fields: [
          { id: 'field1', type: 'text', label: 'Field', required: false, mapToField: 'invalidMapping' as any },
          { id: 'email', type: 'email', label: 'Email', required: true, mapToField: 'email' },
        ],
      });
      expect(result.isValid).toBe(false);
      expect(result.errors.some((e) => e.message.includes('Invalid field mapping'))).toBe(true);
    });

    it('should allow custom field mappings', () => {
      const result = validateWebForm({
        name: 'Test',
        fields: [
          { id: 'field1', type: 'text', label: 'Custom', required: false, mapToField: 'customField_myField' },
          { id: 'email', type: 'email', label: 'Email', required: true, mapToField: 'email' },
        ],
      });
      expect(result.isValid).toBe(true);
    });
  });
});
