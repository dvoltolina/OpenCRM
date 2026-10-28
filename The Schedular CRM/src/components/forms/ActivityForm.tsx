/**
 * ActivityForm Component
 * Form for creating and editing sales activities
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
import { FormDateTimePicker } from './FormDatePicker';
import {
  validateActivityForm,
  getFieldError,
  type ActivityFormData,
  type ValidationError,
} from './validation/schemas';
import type { SalesActivity, SalesActivityType } from '../../types/models';
import { applyTaskTemplate, type TaskTemplate } from '../../config/taskTemplates';
import './forms.css';

// ============================================
// Types
// ============================================

export interface ActivityFormProps {
  /** Initial data for edit mode */
  initialData?: Partial<SalesActivity>;
  /** Called when form is submitted with valid data */
  onSubmit: (data: ActivityFormData) => Promise<void>;
  /** Called when form is cancelled */
  onCancel: () => void;
  /** Whether form is in loading/submitting state */
  isLoading?: boolean;
  /** Available deals for linking */
  deals?: Array<{ id: string; title: string }>;
  /** Available clients for linking */
  clients?: Array<{ id: string; name: string }>;
  /** Available leads for linking */
  leads?: Array<{ id: string; name: string }>;
  /** Available companies for linking */
  companies?: Array<{ id: string; name: string }>;
  /** Team members for assignee dropdown */
  teamMembers?: Array<{ id: string; name: string }>;
  /** Pre-selected entity type */
  preSelectedEntityType?: 'deal' | 'client' | 'lead' | 'company';
  /** Pre-selected entity ID */
  preSelectedEntityId?: string;
  /** Default activity type */
  defaultType?: SalesActivityType;
  /** Optional task templates to speed up task creation */
  taskTemplates?: TaskTemplate[];
  /** Default template to apply when type=task */
  defaultTemplateId?: string;
}

// ============================================
// Options
// ============================================

const TYPE_OPTIONS: SelectOption[] = [
  { value: 'call', label: 'Call' },
  { value: 'email', label: 'Email' },
  { value: 'meeting', label: 'Meeting' },
  { value: 'note', label: 'Note' },
  { value: 'task', label: 'Task' },
];

// ============================================
// Component
// ============================================

/**
 * ActivityForm - Create/edit form for sales activities
 *
 * @example
 * ```tsx
 * <ActivityForm
 *   onSubmit={handleSubmit}
 *   onCancel={handleCancel}
 *   deals={dealList}
 *   clients={clientList}
 *   defaultType="call"
 * />
 * ```
 */
export function ActivityForm({
  initialData,
  onSubmit,
  onCancel,
  isLoading = false,
  deals = [],
  clients = [],
  leads = [],
  companies = [],
  teamMembers = [],
  preSelectedEntityType,
  preSelectedEntityId,
  defaultType = 'note',
  taskTemplates = [],
  defaultTemplateId,
}: ActivityFormProps) {
  // Determine initial entity links
  const getInitialEntityId = (type: 'deal' | 'client' | 'lead' | 'company'): string => {
    if (preSelectedEntityType === type && preSelectedEntityId) {
      return preSelectedEntityId;
    }
    if (type === 'deal') return initialData?.dealId || '';
    if (type === 'client') return initialData?.clientId || '';
    if (type === 'lead') return initialData?.leadId || '';
    if (type === 'company') return initialData?.companyId || '';
    return '';
  };

  // Form state
  const [formData, setFormData] = useState<ActivityFormData>({
    type: initialData?.type || defaultType,
    title: initialData?.title || '',
    description: initialData?.description || '',
    dealId: getInitialEntityId('deal'),
    clientId: getInitialEntityId('client'),
    leadId: getInitialEntityId('lead'),
    companyId: getInitialEntityId('company'),
    dueDate: initialData?.dueDate,
    assigneeId: initialData?.assigneeId || '',
    assigneeName: initialData?.assigneeName || '',
    templateId: initialData?.templateId,
    slaMinutes: initialData?.slaMinutes,
    slaAt: initialData?.slaAt,
    reminderAt: initialData?.reminderAt,
  });

  const [errors, setErrors] = useState<ValidationError[]>([]);

  // Check if editing
  const isEditing = Boolean(initialData?.id);
  const isTask = formData.type === 'task';
  const hasTemplates = isTask && taskTemplates.length > 0;

  // Update form field
  const updateField = useCallback(
    <K extends keyof ActivityFormData>(field: K, value: ActivityFormData[K]) => {
      setFormData((prev) => ({ ...prev, [field]: value }));
      setErrors((prev) => prev.filter((e) => e.field !== field && e.field !== 'entity'));
    },
    []
  );

  // Handle assignee change
  const handleAssigneeChange = (assigneeId: string) => {
    const member = teamMembers.find((m) => m.id === assigneeId);
    setFormData((prev) => ({
      ...prev,
      assigneeId,
      assigneeName: member?.name || '',
    }));
  };

  const applyTemplateToForm = useCallback((templateId: string, overrideTitle = false) => {
    const template = taskTemplates.find((t) => t.id === templateId);
    if (!template) return;

    const applied = applyTaskTemplate(template);
    setFormData((prev) => ({
      ...prev,
      templateId,
      title: overrideTitle || !prev.title || prev.templateId === undefined ? applied.title : prev.title,
      dueDate: applied.dueDate,
      slaMinutes: applied.slaMinutes,
      slaAt: applied.slaAt,
      reminderAt: applied.reminderAt,
    }));
    setErrors((prev) => prev.filter((e) => e.field !== 'dueDate'));
  }, [taskTemplates]);

  // Auto-apply a default template once when switching to task mode and no due date present.
  const hasAppliedDefaultTemplate = React.useRef(false);
  React.useEffect(() => {
    if (!isTask) {
      hasAppliedDefaultTemplate.current = false;
      return;
    }
    if (hasAppliedDefaultTemplate.current) return;
    if (formData.dueDate) {
      hasAppliedDefaultTemplate.current = true;
      return;
    }
    const defaultId = formData.templateId || defaultTemplateId || taskTemplates[0]?.id;
    if (defaultId) {
      applyTemplateToForm(defaultId, true);
      hasAppliedDefaultTemplate.current = true;
    }
  }, [applyTemplateToForm, defaultTemplateId, formData.dueDate, formData.templateId, isTask, taskTemplates]);

  // Handle form submission
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const validation = validateActivityForm(formData);

    if (!validation.isValid) {
      setErrors(validation.errors);
      return;
    }

    const parseDateValue = (value?: Date | string) => {
      if (!value) return undefined;
      if (value instanceof Date) return value;
      const parsed = new Date(value);
      return Number.isNaN(parsed.getTime()) ? undefined : parsed;
    };

    const payload: ActivityFormData = {
      ...formData,
      dueDate: parseDateValue(formData.dueDate),
      slaAt: parseDateValue(formData.slaAt),
      reminderAt: parseDateValue(formData.reminderAt),
    };

    try {
      await onSubmit(payload);
    } catch {
      // Error handling is done by the parent
    }
  };

  // Build options
  const dealOptions: SelectOption[] = deals.map((d) => ({
    value: d.id,
    label: d.title,
  }));

  const clientOptions: SelectOption[] = clients.map((c) => ({
    value: c.id,
    label: c.name,
  }));

  const leadOptions: SelectOption[] = leads.map((l) => ({
    value: l.id,
    label: l.name,
  }));

  const companyOptions: SelectOption[] = companies.map((c) => ({
    value: c.id,
    label: c.name,
  }));

  const assigneeOptions: SelectOption[] = [
    { value: '', label: 'Unassigned' },
    ...teamMembers.map((m) => ({ value: m.id, label: m.name })),
  ];

  const templateOptions: SelectOption[] = taskTemplates.map((template) => ({
    value: template.id,
    label: template.label,
  }));

  // Check if any entity is selected
  const entityError = getFieldError(errors, 'entity');

  return (
    <form onSubmit={handleSubmit} className="activity-form">
      <FormSection title="Activity Details">
        <FormRow>
          <FormField label="Type" name="type" required>
            <FormSelect
              id="type"
              name="type"
              options={TYPE_OPTIONS}
              value={formData.type}
              onChange={(value) => updateField('type', value as SalesActivityType)}
              disabled={isLoading}
            />
          </FormField>

          {isTask && hasTemplates && (
            <FormField label="Template" name="templateId">
              <FormSelect
                id="templateId"
                name="templateId"
                options={templateOptions}
                value={formData.templateId || templateOptions[0]?.value || ''}
                onChange={(value) => {
                  const shouldOverrideTitle =
                    !formData.title ||
                    taskTemplates.some((template) => template.title === formData.title) ||
                    formData.templateId === undefined;
                  updateField('templateId', value || undefined);
                  applyTemplateToForm(value || templateOptions[0]?.value || '', shouldOverrideTitle);
                }}
                disabled={isLoading}
              />
            </FormField>
          )}

          {isTask && (
            <FormField
              label="Due Date"
              name="dueDate"
              required={isTask}
              error={getFieldError(errors, 'dueDate')}
            >
              <FormDateTimePicker
                id="dueDate"
                name="dueDate"
                value={formData.dueDate}
                onChange={(date) => updateField('dueDate', date || undefined)}
                hasError={Boolean(getFieldError(errors, 'dueDate'))}
                disabled={isLoading}
              />
              {(formData.slaAt || formData.reminderAt) && (
                <div style={{ fontSize: 12, color: 'var(--color-text-muted)', marginTop: 6 }}>
                  {formData.slaAt && (
                    <span>SLA target: {new Date(formData.slaAt).toLocaleString()}</span>
                  )}
                  {formData.reminderAt && (
                    <span style={{ marginLeft: formData.slaAt ? 12 : 0 }}>
                      Reminder: {new Date(formData.reminderAt).toLocaleString()}
                    </span>
                  )}
                </div>
              )}
            </FormField>
          )}
        </FormRow>

        <FormField
          label="Title"
          name="title"
          required
          error={getFieldError(errors, 'title')}
        >
          <FormInput
            id="title"
            name="title"
            value={formData.title}
            onChange={(e) => updateField('title', e.target.value)}
            placeholder={
              formData.type === 'call'
                ? 'Call with...'
                : formData.type === 'email'
                ? 'Email subject...'
                : formData.type === 'meeting'
                ? 'Meeting about...'
                : formData.type === 'task'
                ? 'Task title...'
                : 'Note title...'
            }
            hasError={Boolean(getFieldError(errors, 'title'))}
            disabled={isLoading}
          />
        </FormField>

        <FormField label="Description" name="description" helpText="Do not enter PHI, patient names, or health information">
          <FormTextarea
            id="description"
            name="description"
            value={formData.description || ''}
            onChange={(e) => updateField('description', e.target.value)}
            placeholder="Add details (no PHI)..."
            rows={4}
            disabled={isLoading}
          />
        </FormField>
      </FormSection>

      <FormSection title="Link to">
        {entityError && (
          <p style={{ color: 'var(--color-danger)', fontSize: 12, marginBottom: 12 }}>
            {entityError}
          </p>
        )}

        <FormRow>
          {deals.length > 0 && (
            <FormField label="Deal" name="dealId">
              <SearchableSelect
                id="dealId"
                name="dealId"
                options={dealOptions}
                value={formData.dealId || ''}
                onChange={(value) => updateField('dealId', value || undefined)}
                placeholder="Select deal..."
                hasError={Boolean(entityError)}
                disabled={isLoading}
              />
            </FormField>
          )}

          {clients.length > 0 && (
            <FormField label="Contact" name="clientId">
              <SearchableSelect
                id="clientId"
                name="clientId"
                options={clientOptions}
                value={formData.clientId || ''}
                onChange={(value) => updateField('clientId', value || undefined)}
                placeholder="Select contact..."
                hasError={Boolean(entityError)}
                disabled={isLoading}
              />
            </FormField>
          )}
        </FormRow>

        <FormRow>
          {leads.length > 0 && (
            <FormField label="Lead" name="leadId">
              <SearchableSelect
                id="leadId"
                name="leadId"
                options={leadOptions}
                value={formData.leadId || ''}
                onChange={(value) => updateField('leadId', value || undefined)}
                placeholder="Select lead..."
                hasError={Boolean(entityError)}
                disabled={isLoading}
              />
            </FormField>
          )}

          {companies.length > 0 && (
            <FormField label="Company" name="companyId">
              <SearchableSelect
                id="companyId"
                name="companyId"
                options={companyOptions}
                value={formData.companyId || ''}
                onChange={(value) => updateField('companyId', value || undefined)}
                placeholder="Select company..."
                hasError={Boolean(entityError)}
                disabled={isLoading}
              />
            </FormField>
          )}
        </FormRow>
      </FormSection>

      {isTask && teamMembers.length > 0 && (
        <FormSection title="Assignment">
          <FormField label="Assign To" name="assigneeId">
            <FormSelect
              id="assigneeId"
              name="assigneeId"
              options={assigneeOptions}
              value={formData.assigneeId || ''}
              onChange={handleAssigneeChange}
              disabled={isLoading}
            />
          </FormField>
        </FormSection>
      )}

      <FormActions>
        <FormButton type="button" variant="secondary" onClick={onCancel} disabled={isLoading}>
          Cancel
        </FormButton>
        <FormButton type="submit" variant="primary" isLoading={isLoading}>
          {isEditing ? 'Save Changes' : `Log ${formData.type.charAt(0).toUpperCase() + formData.type.slice(1)}`}
        </FormButton>
      </FormActions>
    </form>
  );
}

export default ActivityForm;
