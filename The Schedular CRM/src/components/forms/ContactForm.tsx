/**
 * ContactForm Component
 * Form for creating and editing contacts
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
import { FormSelect, SearchableSelect, type SelectOption } from './FormSelect';
import {
  validateContactForm,
  getFieldError,
  type ContactFormData,
  type ValidationError,
} from './validation/schemas';
import type { Client, ClientLifecycle } from '../../types/models';
import { useDuplicateDetection, type DuplicateMatch } from '../../hooks/useDuplicateDetection';
import { DuplicateList } from '../duplicates/DuplicateList';
import { useAuth } from '../../context/AuthContext';
import './forms.css';

// ============================================
// Types
// ============================================

export interface ContactFormProps {
  /** Initial data for edit mode */
  initialData?: Partial<Client>;
  /** Called when form is submitted with valid data */
  onSubmit: (data: ContactFormData, options?: { allowDuplicate?: boolean }) => Promise<void>;
  /** Called when form is cancelled */
  onCancel: () => void;
  /** Whether form is in loading/submitting state */
  isLoading?: boolean;
  /** Available companies for selection */
  companies?: Array<{ id: string; name: string }>;
  /** Pre-selected company ID */
  preSelectedCompanyId?: string;
}

// ============================================
// Options
// ============================================

const LIFECYCLE_OPTIONS: SelectOption[] = [
  { value: 'lead', label: 'Lead' },
  { value: 'prospect', label: 'Prospect' },
  { value: 'active', label: 'Active' },
  { value: 'inactive', label: 'Inactive' },
  { value: 'churned', label: 'Churned' },
];

// ============================================
// Component
// ============================================

/**
 * ContactForm - Create/edit form for contacts
 *
 * @example
 * ```tsx
 * <ContactForm
 *   onSubmit={handleSubmit}
 *   onCancel={handleCancel}
 *   companies={companyList}
 * />
 * ```
 */
export function ContactForm({
  initialData,
  onSubmit,
  onCancel,
  isLoading = false,
  companies = [],
  preSelectedCompanyId,
}: ContactFormProps) {
  // Form state
  const [formData, setFormData] = useState<ContactFormData>({
    firstName: initialData?.firstName || '',
    lastName: initialData?.lastName || '',
    email: initialData?.email || '',
    phone: initialData?.phone || '',
    companyId: preSelectedCompanyId || initialData?.companyId || '',
    companyName: initialData?.companyName || '',
    title: initialData?.title || '',
    lifecycle: initialData?.lifecycle || 'prospect',
    address: initialData?.address || {},
    notes: initialData?.crmNotes || '',
    tags: initialData?.tags || [],
  });

  const [errors, setErrors] = useState<ValidationError[]>([]);
  const [tagInput, setTagInput] = useState('');
  const [showAddress, setShowAddress] = useState(Boolean(initialData?.address?.street));
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [duplicateMatches, setDuplicateMatches] = useState<DuplicateMatch<Client>[]>([]);
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
    <K extends keyof ContactFormData>(field: K, value: ContactFormData[K]) => {
      setFormData((prev) => ({ ...prev, [field]: value }));
      setErrors((prev) => prev.filter((e) => e.field !== field));
    },
    []
  );

  // Update address field
  const updateAddressField = useCallback(
    (field: string, value: string) => {
      setFormData((prev) => ({
        ...prev,
        address: { ...prev.address, [field]: value },
      }));
    },
    []
  );

  // Handle company selection
  const handleCompanyChange = (companyId: string) => {
    const company = companies.find((c) => c.id === companyId);
    setFormData((prev) => ({
      ...prev,
      companyId,
      companyName: company?.name || '',
    }));
  };

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
        ...(initialData as Client),
        ...formData,
        id: initialData?.id || 'new',
        tags: formData.tags || [],
        createdAt: initialData?.createdAt || new Date(),
      } as Client;

      const matches = await checkEntity(entityForCheck, {
        entityType: 'client',
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

    const validation = validateContactForm(formData);

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
      const message = err instanceof Error ? err.message : 'Failed to save contact';
      setSubmitError(message);

      if (message.toLowerCase().includes('duplicate')) {
        void handleCheckDuplicates();
      }
    }
  };

  // Handle tags
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

  // Build options
  const companyOptions: SelectOption[] = companies.map((c) => ({
    value: c.id,
    label: c.name,
  }));

  return (
    <form onSubmit={handleSubmit} className="contact-form">
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
            entityType="client"
            entity={{
              ...(initialData as Client),
              ...formData,
              id: initialData?.id || 'new',
            } as Client}
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
      </FormSection>

      <FormSection title="Company & Role">
        <FormRow>
          <FormField label="Company" name="companyId">
            <SearchableSelect
              id="companyId"
              name="companyId"
              options={companyOptions}
              value={formData.companyId || ''}
              onChange={handleCompanyChange}
              placeholder="Search companies..."
              disabled={isLoading}
            />
          </FormField>

          <FormField label="Job Title" name="title">
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

        <FormField label="Lifecycle Stage" name="lifecycle">
          <FormSelect
            id="lifecycle"
            name="lifecycle"
            options={LIFECYCLE_OPTIONS}
            value={formData.lifecycle as string}
            onChange={(value) => updateField('lifecycle', value as ClientLifecycle)}
            disabled={isLoading}
          />
        </FormField>
      </FormSection>

      <FormSection>
        <div style={{ marginBottom: 16 }}>
          <button
            type="button"
            onClick={() => setShowAddress(!showAddress)}
            style={{
              background: 'none',
              border: 'none',
              color: 'var(--color-primary)',
              cursor: 'pointer',
              fontSize: 14,
              padding: 0,
            }}
          >
            {showAddress ? '- Hide Address' : '+ Add Address'}
          </button>
        </div>

        {showAddress && (
          <>
            <FormField label="Street Address" name="address.street">
              <FormInput
                id="address.street"
                name="address.street"
                value={formData.address?.street || ''}
                onChange={(e) => updateAddressField('street', e.target.value)}
                placeholder="Enter street address"
                disabled={isLoading}
              />
            </FormField>

            <FormRow>
              <FormField label="City" name="address.city">
                <FormInput
                  id="address.city"
                  name="address.city"
                  value={formData.address?.city || ''}
                  onChange={(e) => updateAddressField('city', e.target.value)}
                  placeholder="Enter city"
                  disabled={isLoading}
                />
              </FormField>

              <FormField label="State" name="address.state">
                <FormInput
                  id="address.state"
                  name="address.state"
                  value={formData.address?.state || ''}
                  onChange={(e) => updateAddressField('state', e.target.value)}
                  placeholder="Enter state"
                  disabled={isLoading}
                />
              </FormField>
            </FormRow>

            <FormRow>
              <FormField label="Zip Code" name="address.zipCode">
                <FormInput
                  id="address.zipCode"
                  name="address.zipCode"
                  value={formData.address?.zipCode || ''}
                  onChange={(e) => updateAddressField('zipCode', e.target.value)}
                  placeholder="Enter zip code"
                  disabled={isLoading}
                />
              </FormField>

              <FormField label="Country" name="address.country">
                <FormInput
                  id="address.country"
                  name="address.country"
                  value={formData.address?.country || ''}
                  onChange={(e) => updateAddressField('country', e.target.value)}
                  placeholder="Enter country"
                  disabled={isLoading}
                />
              </FormField>
            </FormRow>
          </>
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
            placeholder="Enter any notes about this contact (no PHI)"
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
          {isEditing ? 'Save Changes' : 'Create Contact'}
        </FormButton>
      </FormActions>
    </form>
  );
}

export default ContactForm;
