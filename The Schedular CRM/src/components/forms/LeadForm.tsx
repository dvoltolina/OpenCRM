/**
 * LeadForm Component
 * Form for creating and editing leads
 *
 * Agent CRM-14 Implementation
 */

import React, { useState, useCallback } from 'react';
import {
  FormField,
  FormInput,
  FormTextarea,
  FormActions,
  FormButton,
  FormRow,
  FormSection,
} from './FormField';
import { FormSelect, type SelectOption } from './FormSelect';
import {
  validateLeadForm,
  getFieldError,
  type LeadFormData,
  type ValidationError,
} from './validation/schemas';
import type { Lead, LeadStatus, LeadSource } from '../../types/models';
import { useDuplicateDetection, type DuplicateMatch } from '../../hooks/useDuplicateDetection';
import { DuplicateList } from '../duplicates/DuplicateList';
import { useAuth } from '../../context/AuthContext';
import './forms.css';

// ============================================
// Types
// ============================================

export interface LeadFormProps {
  /** Initial data for edit mode */
  initialData?: Partial<Lead>;
  /** Called when form is submitted with valid data */
  onSubmit: (data: LeadFormData, options?: { allowDuplicate?: boolean }) => Promise<void>;
  /** Called when form is cancelled */
  onCancel: () => void;
  /** Whether form is in loading/submitting state */
  isLoading?: boolean;
  /** Team members for assignee dropdown */
  teamMembers?: Array<{ id: string; name: string }>;
}

// ============================================
// Options
// ============================================

const STATUS_OPTIONS: SelectOption[] = [
  { value: 'new', label: 'New' },
  { value: 'contacted', label: 'Contacted' },
  { value: 'qualified', label: 'Qualified' },
  { value: 'unqualified', label: 'Unqualified' },
];

const SOURCE_OPTIONS: SelectOption[] = [
  { value: 'website', label: 'Website' },
  { value: 'referral', label: 'Referral' },
  { value: 'coldCall', label: 'Cold Call' },
  { value: 'social', label: 'Social Media' },
  { value: 'event', label: 'Event' },
  { value: 'scheduler', label: 'Scheduler' },
  { value: 'other', label: 'Other' },
];

// ============================================
// Component
// ============================================

/**
 * LeadForm - Create/edit form for leads
 *
 * @example
 * ```tsx
 * <LeadForm
 *   onSubmit={handleSubmit}
 *   onCancel={handleCancel}
 *   isLoading={isSubmitting}
 *   teamMembers={team}
 * />
 * ```
 */
export function LeadForm({
  initialData,
  onSubmit,
  onCancel,
  isLoading = false,
  teamMembers = [],
}: LeadFormProps) {
  // Form state
  const [formData, setFormData] = useState<LeadFormData>({
    firstName: initialData?.firstName || '',
    lastName: initialData?.lastName || '',
    email: initialData?.email || '',
    phone: initialData?.phone || '',
    companyName: initialData?.companyName || '',
    title: initialData?.title || '',
    status: initialData?.status || 'new',
    source: initialData?.source || 'other',
    notes: initialData?.notes || '',
    tags: initialData?.tags || [],
  });

  const [errors, setErrors] = useState<ValidationError[]>([]);
  const [tagInput, setTagInput] = useState('');
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [duplicateMatches, setDuplicateMatches] = useState<DuplicateMatch<Lead>[]>([]);
  const [duplicateNotice, setDuplicateNotice] = useState<string | null>(null);
  const [allowDuplicate, setAllowDuplicate] = useState(false);

  // Check if editing
  const isEditing = Boolean(initialData?.id);
  const { crmUser } = useAuth();
  const canOverrideDuplicates = crmUser?.role === 'owner' || crmUser?.role === 'admin';
  const {
    checkEntity,
    isChecking,
    error: duplicateError,
    clearError: clearDuplicateError,
  } = useDuplicateDetection();

  // Update form field
  const updateField = useCallback(
    <K extends keyof LeadFormData>(field: K, value: LeadFormData[K]) => {
      setFormData((prev) => ({ ...prev, [field]: value }));
      // Clear field error when user edits
      setErrors((prev) => prev.filter((e) => e.field !== field));
    },
    []
  );

  const handleCheckDuplicates = useCallback(async () => {
    if (!formData.email && !formData.phone) {
      setDuplicateNotice('Add an email or phone number to run duplicate checks.');
      setDuplicateMatches([]);
      return;
    }

    clearDuplicateError();
    setDuplicateNotice(null);

    try {
      const entityForCheck = {
        ...(initialData as Lead),
        ...formData,
        id: initialData?.id || 'new',
        status: formData.status as LeadStatus,
        source: formData.source as LeadSource,
        tags: formData.tags || [],
        createdAt: initialData?.createdAt || new Date(),
      } as Lead;

      const matches = await checkEntity(entityForCheck, {
        entityType: 'lead',
        minConfidence: 60,
        excludeId: initialData?.id,
      });

      setDuplicateMatches(matches);
      setAllowDuplicate(false);
      setDuplicateNotice(
        matches.length > 0
          ? 'Potential duplicates found. Review before saving.'
          : 'No duplicates detected.'
      );
    } catch (err) {
      const message =
        err instanceof Error ? err.message : 'Duplicate check failed. Please try again.';
      setDuplicateNotice(message);
    }
  }, [checkEntity, clearDuplicateError, formData, initialData]);

  // Handle form submission
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitError(null);

    // Validate form
    const validation = validateLeadForm(formData);

    if (!validation.isValid) {
      setErrors(validation.errors);
      return;
    }

    try {
      await onSubmit(formData, allowDuplicate ? { allowDuplicate: true } : undefined);
      setAllowDuplicate(false);
      setDuplicateNotice(null);
      setDuplicateMatches([]);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to save lead';
      setSubmitError(message);

      // Surface duplicate hints and suggestions when server blocks on duplicates
      if (message.toLowerCase().includes('duplicate')) {
        void handleCheckDuplicates();
      }
    }
  };

  // Handle tag input
  const handleAddTag = () => {
    const tag = tagInput.trim();
    if (tag && !formData.tags?.includes(tag)) {
      updateField('tags', [...(formData.tags || []), tag]);
      setTagInput('');
    }
  };

  const handleRemoveTag = (tagToRemove: string) => {
    updateField(
      'tags',
      (formData.tags || []).filter((t) => t !== tagToRemove)
    );
  };

  const handleTagKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      e.preventDefault();
      handleAddTag();
    }
  };

  // Build team member options
  const assigneeOptions: SelectOption[] = [
    { value: '', label: 'Unassigned' },
    ...teamMembers.map((m) => ({ value: m.id, label: m.name })),
  ];

  return (
    <form onSubmit={handleSubmit} className="lead-form">
      {submitError && (
        <div
          role="alert"
          className="form-error-banner"
          style={{ color: '#b00020', marginBottom: 12, fontWeight: 500 }}
        >
          {submitError}
        </div>
      )}
      <div className="form-inline-actions" style={{ display: 'flex', gap: 12, alignItems: 'center', marginBottom: 12 }}>
        <button
          type="button"
          className="btn btn-secondary btn-sm"
          onClick={handleCheckDuplicates}
          disabled={isLoading || isChecking}
        >
          {isChecking ? 'Checking duplicates…' : 'Check duplicates'}
        </button>
        {duplicateNotice && <span className="text-muted">{duplicateNotice}</span>}
        {duplicateError && (
          <span style={{ color: '#b00020', fontSize: 13 }}>
            {duplicateError.message}
          </span>
        )}
      </div>
      {duplicateMatches.length > 0 && (
        <div className="alert warning" style={{ marginBottom: 16 }}>
          <strong>Heads up:</strong> We found {duplicateMatches.length} potential duplicate
          record{duplicateMatches.length > 1 ? 's' : ''}. Review before saving.
          <DuplicateList
            entityType="lead"
            entity={{
              ...(initialData as Lead),
              ...formData,
              id: initialData?.id || 'new',
            } as Lead}
            matches={duplicateMatches}
            isDisabled={isLoading || isChecking}
          />
          {canOverrideDuplicates ? (
            <label style={{ display: 'flex', gap: 8, alignItems: 'center', marginTop: 8 }}>
              <input
                type="checkbox"
                checked={allowDuplicate}
                onChange={(e) => setAllowDuplicate(e.target.checked)}
                disabled={isLoading}
              />
              <span>Save anyway (admin override — logs duplicate bypass)</span>
            </label>
          ) : (
            <p className="text-muted" style={{ marginTop: 8 }}>
              Contact an admin to merge or update an existing record before saving.
            </p>
          )}
        </div>
      )}
      <FormSection title="Contact Information">
        <FormRow>
          <FormField
            label="First Name"
            name="firstName"
            required
            error={getFieldError(errors, 'firstName')}
          >
            <FormInput
              id="firstName"
              name="firstName"
              value={formData.firstName}
              onChange={(e) => updateField('firstName', e.target.value)}
              placeholder="Enter first name"
              hasError={Boolean(getFieldError(errors, 'firstName'))}
              disabled={isLoading}
            />
          </FormField>

          <FormField
            label="Last Name"
            name="lastName"
            required
            error={getFieldError(errors, 'lastName')}
          >
            <FormInput
              id="lastName"
              name="lastName"
              value={formData.lastName}
              onChange={(e) => updateField('lastName', e.target.value)}
              placeholder="Enter last name"
              hasError={Boolean(getFieldError(errors, 'lastName'))}
              disabled={isLoading}
            />
          </FormField>
        </FormRow>

        <FormRow>
          <FormField
            label="Email"
            name="email"
            required
            error={getFieldError(errors, 'email')}
          >
            <FormInput
              id="email"
              name="email"
              type="email"
              value={formData.email}
              onChange={(e) => updateField('email', e.target.value)}
              placeholder="Enter email address"
              hasError={Boolean(getFieldError(errors, 'email'))}
              disabled={isLoading}
            />
          </FormField>

          <FormField
            label="Phone"
            name="phone"
            error={getFieldError(errors, 'phone')}
          >
            <FormInput
              id="phone"
              name="phone"
              type="tel"
              value={formData.phone || ''}
              onChange={(e) => updateField('phone', e.target.value)}
              placeholder="Enter phone number"
              hasError={Boolean(getFieldError(errors, 'phone'))}
              disabled={isLoading}
            />
          </FormField>
        </FormRow>

        <FormRow>
          <FormField label="Company" name="companyName">
            <FormInput
              id="companyName"
              name="companyName"
              value={formData.companyName || ''}
              onChange={(e) => updateField('companyName', e.target.value)}
              placeholder="Enter company name"
              disabled={isLoading}
            />
          </FormField>

          <FormField label="Title" name="title">
            <FormInput
              id="title"
              name="title"
              value={formData.title || ''}
              onChange={(e) => updateField('title', e.target.value)}
              placeholder="Enter job title"
              disabled={isLoading}
            />
          </FormField>
        </FormRow>
      </FormSection>

      <FormSection title="Lead Details">
        <FormRow>
          <FormField label="Status" name="status">
            <FormSelect
              id="status"
              name="status"
              options={STATUS_OPTIONS}
              value={formData.status as string}
              onChange={(value) => updateField('status', value as LeadStatus)}
              disabled={isLoading}
            />
          </FormField>

          <FormField label="Source" name="source">
            <FormSelect
              id="source"
              name="source"
              options={SOURCE_OPTIONS}
              value={formData.source as string}
              onChange={(value) => updateField('source', value as LeadSource)}
              disabled={isLoading}
            />
          </FormField>
        </FormRow>

        {teamMembers.length > 0 && (
          <FormField label="Assignee" name="assigneeId">
            <FormSelect
              id="assigneeId"
              name="assigneeId"
              options={assigneeOptions}
              value=""
              onChange={() => {}}
              placeholder="Select assignee"
              disabled={isLoading}
            />
          </FormField>
        )}
      </FormSection>

      <FormSection title="Additional Information">
        <FormField label="Tags" name="tags" helpText="Press Enter to add a tag">
          <div className="tags-input">
            {formData.tags?.map((tag) => (
              <span key={tag} className="tags-input__tag">
                {tag}
                <button
                  type="button"
                  className="tags-input__tag-remove"
                  onClick={() => handleRemoveTag(tag)}
                >
                  &times;
                </button>
              </span>
            ))}
            <input
              type="text"
              className="tags-input__input"
              value={tagInput}
              onChange={(e) => setTagInput(e.target.value)}
              onKeyDown={handleTagKeyDown}
              placeholder={formData.tags?.length ? '' : 'Add tags...'}
              disabled={isLoading}
            />
          </div>
        </FormField>

        <FormField label="Notes" name="notes" helpText="Do not enter PHI, patient names, or health information">
          <FormTextarea
            id="notes"
            name="notes"
            value={formData.notes || ''}
            onChange={(e) => updateField('notes', e.target.value)}
            placeholder="Enter any notes about this lead (no PHI)"
            rows={4}
            disabled={isLoading}
          />
        </FormField>
      </FormSection>

      <FormActions>
        <FormButton type="button" variant="secondary" onClick={onCancel} disabled={isLoading}>
          Cancel
        </FormButton>
        <FormButton type="submit" variant="primary" isLoading={isLoading}>
          {isEditing ? 'Save Changes' : 'Create Lead'}
        </FormButton>
      </FormActions>
    </form>
  );
}

export default LeadForm;
