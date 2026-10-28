/**
 * DealForm Component
 * Form for creating and editing deals
 *
 * Agent CRM-14 Implementation
 */

import React, { useState, useCallback, useMemo } from 'react';
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
import { FormDatePicker } from './FormDatePicker';
import {
  validateDealForm,
  getFieldError,
  type DealFormData,
  type ValidationError,
} from './validation/schemas';
import type { Deal, Pipeline, Stage } from '../../types/models';
import './forms.css';

// ============================================
// Types
// ============================================

export interface DealFormProps {
  /** Initial data for edit mode */
  initialData?: Partial<Deal>;
  /** Called when form is submitted with valid data */
  onSubmit: (data: DealFormData) => Promise<void>;
  /** Called when form is cancelled */
  onCancel: () => void;
  /** Whether form is in loading/submitting state */
  isLoading?: boolean;
  /** Available pipelines */
  pipelines?: Pipeline[];
  /** Available stages (filtered by selected pipeline) */
  stages?: Stage[];
  /** Available clients for selection */
  clients?: Array<{ id: string; name: string }>;
  /** Available companies for selection */
  companies?: Array<{ id: string; name: string }>;
  /** Pre-selected client ID */
  preSelectedClientId?: string;
  /** Pre-selected company ID */
  preSelectedCompanyId?: string;
}

// ============================================
// Utilities
// ============================================

/**
 * Format cents to dollars for display
 */
function centsToDollars(cents: number): string {
  return (cents / 100).toFixed(2);
}

/**
 * Parse dollars to cents for storage
 */
function dollarsToCents(dollars: string): number {
  const num = parseFloat(dollars.replace(/[^0-9.-]/g, ''));
  if (isNaN(num)) return 0;
  return Math.round(num * 100);
}

// ============================================
// Component
// ============================================

/**
 * DealForm - Create/edit form for deals
 *
 * @example
 * ```tsx
 * <DealForm
 *   onSubmit={handleSubmit}
 *   onCancel={handleCancel}
 *   pipelines={pipelines}
 *   stages={stagesForPipeline}
 *   clients={clientList}
 * />
 * ```
 */
export function DealForm({
  initialData,
  onSubmit,
  onCancel,
  isLoading = false,
  pipelines = [],
  stages = [],
  clients = [],
  companies = [],
  preSelectedClientId,
  preSelectedCompanyId,
}: DealFormProps) {
  // Form state
  const [formData, setFormData] = useState<DealFormData>({
    title: initialData?.title || '',
    valueCents: initialData?.valueCents || 0,
    pipelineId: initialData?.pipelineId || pipelines[0]?.id || '',
    stageId: initialData?.stageId || '',
    currency: initialData?.currency || 'USD',
    probability: initialData?.probability,
    expectedCloseDate: initialData?.expectedCloseDate,
    clientId: preSelectedClientId || initialData?.clientId || '',
    clientName: initialData?.clientName || '',
    companyId: preSelectedCompanyId || initialData?.companyId || '',
    companyName: initialData?.companyName || '',
    notes: initialData?.notes || '',
    tags: initialData?.tags || [],
  });

  const [valueDisplay, setValueDisplay] = useState(
    initialData?.valueCents ? centsToDollars(initialData.valueCents) : ''
  );
  const [errors, setErrors] = useState<ValidationError[]>([]);
  const [tagInput, setTagInput] = useState('');

  // Check if editing
  const isEditing = Boolean(initialData?.id);

  // Filter stages by selected pipeline
  const filteredStages = useMemo(() => {
    return stages.filter((s) => s.pipelineId === formData.pipelineId && s.isActive);
  }, [stages, formData.pipelineId]);

  // Update form field
  const updateField = useCallback(
    <K extends keyof DealFormData>(field: K, value: DealFormData[K]) => {
      setFormData((prev) => ({ ...prev, [field]: value }));
      setErrors((prev) => prev.filter((e) => e.field !== field));
    },
    []
  );

  // Handle pipeline change (reset stage)
  const handlePipelineChange = (pipelineId: string) => {
    setFormData((prev) => ({
      ...prev,
      pipelineId,
      stageId: '', // Reset stage when pipeline changes
    }));
    setErrors((prev) => prev.filter((e) => e.field !== 'pipelineId'));
  };

  // Handle stage change (update probability)
  const handleStageChange = (stageId: string) => {
    const stage = stages.find((s) => s.id === stageId);
    setFormData((prev) => ({
      ...prev,
      stageId,
      probability: stage?.probability,
    }));
    setErrors((prev) => prev.filter((e) => e.field !== 'stageId'));
  };

  // Handle value change
  const handleValueChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const input = e.target.value;
    setValueDisplay(input);
    updateField('valueCents', dollarsToCents(input));
  };

  // Handle client selection
  const handleClientChange = (clientId: string) => {
    const client = clients.find((c) => c.id === clientId);
    setFormData((prev) => ({
      ...prev,
      clientId,
      clientName: client?.name || '',
    }));
  };

  // Handle company selection
  const handleCompanyChange = (companyId: string) => {
    const company = companies.find((c) => c.id === companyId);
    setFormData((prev) => ({
      ...prev,
      companyId,
      companyName: company?.name || '',
    }));
  };

  // Handle form submission
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const validation = validateDealForm(formData);

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

  // Build options
  const pipelineOptions: SelectOption[] = pipelines.map((p) => ({
    value: p.id,
    label: p.name,
  }));

  const stageOptions: SelectOption[] = filteredStages.map((s) => ({
    value: s.id,
    label: `${s.name} (${s.probability}%)`,
  }));

  const clientOptions: SelectOption[] = clients.map((c) => ({
    value: c.id,
    label: c.name,
  }));

  const companyOptions: SelectOption[] = companies.map((c) => ({
    value: c.id,
    label: c.name,
  }));

  return (
    <form onSubmit={handleSubmit} className="deal-form">
      <FormSection title="Opportunity Information">
        <FormField
          label="Opportunity Title"
          name="title"
          required
          error={getFieldError(errors, 'title')}
        >
          <FormInput
            id="title"
            name="title"
            value={formData.title}
            onChange={(e) => updateField('title', e.target.value)}
            placeholder="Enter opportunity title"
            hasError={Boolean(getFieldError(errors, 'title'))}
            disabled={isLoading}
          />
        </FormField>

        <FormRow>
          <FormField
            label="Value"
            name="valueCents"
            required
            error={getFieldError(errors, 'valueCents')}
          >
            <div style={{ position: 'relative' }}>
              <span
                style={{
                  position: 'absolute',
                  left: 12,
                  top: '50%',
                  transform: 'translateY(-50%)',
                  color: 'var(--color-text-muted)',
                }}
              >
                $
              </span>
              <FormInput
                id="valueCents"
                name="valueCents"
                type="text"
                inputMode="decimal"
                value={valueDisplay}
                onChange={handleValueChange}
                placeholder="0.00"
                hasError={Boolean(getFieldError(errors, 'valueCents'))}
                disabled={isLoading}
                style={{ paddingLeft: 28 }}
              />
            </div>
          </FormField>

          <FormField label="Expected Close Date" name="expectedCloseDate">
            <FormDatePicker
              id="expectedCloseDate"
              name="expectedCloseDate"
              value={formData.expectedCloseDate}
              onChange={(date) => updateField('expectedCloseDate', date || undefined)}
              min={new Date()}
              disabled={isLoading}
            />
          </FormField>
        </FormRow>
      </FormSection>

      <FormSection title="Pipeline">
        <FormRow>
          <FormField
            label="Pipeline"
            name="pipelineId"
            required
            error={getFieldError(errors, 'pipelineId')}
          >
            <FormSelect
              id="pipelineId"
              name="pipelineId"
              options={pipelineOptions}
              value={formData.pipelineId}
              onChange={handlePipelineChange}
              placeholder="Select pipeline"
              hasError={Boolean(getFieldError(errors, 'pipelineId'))}
              disabled={isLoading || pipelines.length === 0}
            />
          </FormField>

          <FormField
            label="Stage"
            name="stageId"
            required
            error={getFieldError(errors, 'stageId')}
          >
            <FormSelect
              id="stageId"
              name="stageId"
              options={stageOptions}
              value={formData.stageId}
              onChange={handleStageChange}
              placeholder="Select stage"
              hasError={Boolean(getFieldError(errors, 'stageId'))}
              disabled={isLoading || !formData.pipelineId || stageOptions.length === 0}
            />
          </FormField>
        </FormRow>

        {formData.probability !== undefined && (
          <FormField label="Probability" name="probability">
            <FormInput
              id="probability"
              name="probability"
              type="number"
              min={0}
              max={100}
              value={formData.probability}
              onChange={(e) => updateField('probability', parseInt(e.target.value, 10))}
              disabled={isLoading}
            />
          </FormField>
        )}
      </FormSection>

      <FormSection title="Associations">
        <FormRow>
          <FormField label="Client" name="clientId">
            <SearchableSelect
              id="clientId"
              name="clientId"
              options={clientOptions}
              value={formData.clientId || ''}
              onChange={handleClientChange}
              placeholder="Search clients..."
              disabled={isLoading}
            />
          </FormField>

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
        </FormRow>
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
            placeholder="Enter any notes about this opportunity (no PHI)"
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
          {isEditing ? 'Save Changes' : 'Create Opportunity'}
        </FormButton>
      </FormActions>
    </form>
  );
}

export default DealForm;
