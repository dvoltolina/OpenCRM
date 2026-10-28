/**
 * CompanyForm Component
 * Form for creating and editing companies
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
  validateCompanyForm,
  getFieldError,
  type CompanyFormData,
  type ValidationError,
} from './validation/schemas';
import type { Company, CompanySize } from '../../types/models';
import './forms.css';

// ============================================
// Types
// ============================================

export interface CompanyFormProps {
  /** Initial data for edit mode */
  initialData?: Partial<Company>;
  /** Called when form is submitted with valid data */
  onSubmit: (data: CompanyFormData) => Promise<void>;
  /** Called when form is cancelled */
  onCancel: () => void;
  /** Whether form is in loading/submitting state */
  isLoading?: boolean;
  /** Available industries for dropdown */
  industries?: string[];
}

// ============================================
// Options
// ============================================

const SIZE_OPTIONS: SelectOption[] = [
  { value: '', label: 'Select size' },
  { value: 'small', label: 'Small (1-50)' },
  { value: 'medium', label: 'Medium (51-200)' },
  { value: 'large', label: 'Large (201-1000)' },
  { value: 'enterprise', label: 'Enterprise (1000+)' },
];

const DEFAULT_INDUSTRIES = [
  'Technology',
  'Healthcare',
  'Finance',
  'Retail',
  'Manufacturing',
  'Education',
  'Real Estate',
  'Professional Services',
  'Media & Entertainment',
  'Other',
];

// ============================================
// Component
// ============================================

/**
 * CompanyForm - Create/edit form for companies
 *
 * @example
 * ```tsx
 * <CompanyForm
 *   onSubmit={handleSubmit}
 *   onCancel={handleCancel}
 *   industries={industryList}
 * />
 * ```
 */
export function CompanyForm({
  initialData,
  onSubmit,
  onCancel,
  isLoading = false,
  industries = DEFAULT_INDUSTRIES,
}: CompanyFormProps) {
  // Form state
  const [formData, setFormData] = useState<CompanyFormData>({
    name: initialData?.name || '',
    industry: initialData?.industry || '',
    size: initialData?.size || '',
    website: initialData?.website || '',
    phone: initialData?.phone || '',
    email: initialData?.email || '',
    address: initialData?.address || {},
    notes: initialData?.notes || '',
    tags: initialData?.tags || [],
  });

  const [errors, setErrors] = useState<ValidationError[]>([]);
  const [tagInput, setTagInput] = useState('');
  const [showAddress, setShowAddress] = useState(Boolean(initialData?.address?.street));

  // Check if editing
  const isEditing = Boolean(initialData?.id);

  // Update form field
  const updateField = useCallback(
    <K extends keyof CompanyFormData>(field: K, value: CompanyFormData[K]) => {
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

  // Handle form submission
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const validation = validateCompanyForm(formData);

    if (!validation.isValid) {
      setErrors(validation.errors);
      return;
    }

    try {
      await onSubmit(formData);
    } catch {
      // Error handling is done by the parent
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

  // Build industry options
  const industryOptions: SelectOption[] = [
    { value: '', label: 'Select industry' },
    ...industries.map((i) => ({ value: i, label: i })),
  ];

  return (
    <form onSubmit={handleSubmit} className="company-form">
      <FormSection title="Company Information">
        <FormField
          label="Company Name"
          name="name"
          required
          error={getFieldError(errors, 'name')}
        >
          <FormInput
            id="name"
            name="name"
            value={formData.name}
            onChange={(e) => updateField('name', e.target.value)}
            placeholder="Enter company name"
            hasError={Boolean(getFieldError(errors, 'name'))}
            disabled={isLoading}
          />
        </FormField>

        <FormRow>
          <FormField label="Industry" name="industry">
            <FormSelect
              id="industry"
              name="industry"
              options={industryOptions}
              value={formData.industry || ''}
              onChange={(value) => updateField('industry', value)}
              disabled={isLoading}
            />
          </FormField>

          <FormField label="Company Size" name="size">
            <FormSelect
              id="size"
              name="size"
              options={SIZE_OPTIONS}
              value={formData.size || ''}
              onChange={(value) => updateField('size', value as CompanySize)}
              disabled={isLoading}
            />
          </FormField>
        </FormRow>
      </FormSection>

      <FormSection title="Contact Details">
        <FormField
          label="Website"
          name="website"
          error={getFieldError(errors, 'website')}
        >
          <FormInput
            id="website"
            name="website"
            type="url"
            value={formData.website || ''}
            onChange={(e) => updateField('website', e.target.value)}
            placeholder="https://example.com"
            hasError={Boolean(getFieldError(errors, 'website'))}
            disabled={isLoading}
          />
        </FormField>

        <FormRow>
          <FormField
            label="Email"
            name="email"
            error={getFieldError(errors, 'email')}
          >
            <FormInput
              id="email"
              name="email"
              type="email"
              value={formData.email || ''}
              onChange={(e) => updateField('email', e.target.value)}
              placeholder="contact@example.com"
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
            placeholder="Enter any notes about this company (no PHI)"
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
          {isEditing ? 'Save Changes' : 'Create Company'}
        </FormButton>
      </FormActions>
    </form>
  );
}

export default CompanyForm;
