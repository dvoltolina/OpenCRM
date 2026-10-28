/**
 * CustomFieldsSettings Component
 * Full implementation of custom fields configuration
 *
 * Agent CRM-39 Implementation
 * Dependencies: useCustomFields hook, CustomFieldEditor component
 */

import { useState } from 'react';
import { useAuth } from '../../context/AuthContext';
import { useCustomFields } from '../../hooks/useCustomFields';
import { CustomFieldEditor } from '../forms/CustomFieldEditor';
import { useModal } from '../../hooks/useModal';
import type { CustomFieldEntityType, CustomFieldDefinition, CustomFieldInput } from '../../types/custom-fields';
import './settings.css';

// ============================================
// Types
// ============================================

export interface CustomFieldsSettingsProps {
  /** Optional callback when fields change */
  onFieldsChange?: () => void;
}

// ============================================
// Component
// ============================================

/**
 * CustomFieldsSettings - Full custom fields management UI
 *
 * Features:
 * - Define custom fields for leads, deals, contacts, companies
 * - Multiple field types (text, number, date, select, multiselect, checkbox, url, email, phone)
 * - Required field validation
 * - Field ordering and management
 * - Archive/restore fields
 *
 * @example
 * ```tsx
 * <CustomFieldsSettings />
 * ```
 */
export function CustomFieldsSettings({ onFieldsChange }: CustomFieldsSettingsProps) {
  const { businessId, crmUser } = useAuth();
  const [selectedEntity, setSelectedEntity] = useState<CustomFieldEntityType>('lead');
  const [editingField, setEditingField] = useState<CustomFieldDefinition | null>(null);
  const { isOpen, open, close } = useModal();
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // RBAC: Only admin and owner can modify custom fields (per shared_data_contract.md)
  const canModifyFields = crmUser?.role === 'owner' || crmUser?.role === 'admin';

  const {
    fields,
    isLoading,
    error: fetchError,
    createField,
    updateField,
    deleteField,
    archiveField,
    restoreField,
    reorderFields,
    duplicateField,
  } = useCustomFields(selectedEntity);

  if (!businessId) {
    return (
      <div className="custom-fields-settings">
        <p className="custom-fields-settings__error">Business ID not found</p>
      </div>
    );
  }

  // Handle create field
  const handleCreate = () => {
    setEditingField(null);
    setError(null);
    open();
  };

  // Handle edit field
  const handleEdit = (field: CustomFieldDefinition) => {
    setEditingField(field);
    setError(null);
    open();
  };

  // Handle save field
  const handleSave = async (data: CustomFieldInput) => {
    setIsSaving(true);
    setError(null);

    try {
      if (editingField) {
        await updateField(editingField.id, data);
      } else {
        await createField(data);
      }
      close();
      onFieldsChange?.();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save field');
      throw err; // Re-throw so editor can handle it
    } finally {
      setIsSaving(false);
    }
  };

  // Handle delete field
  const handleDelete = async (fieldId: string) => {
    if (!confirm('Are you sure you want to delete this field? This action cannot be undone.')) {
      return;
    }

    try {
      await deleteField(fieldId);
      onFieldsChange?.();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete field');
    }
  };

  // Handle archive/restore
  const handleToggleActive = async (field: CustomFieldDefinition) => {
    try {
      if (field.isActive) {
        await archiveField(field.id);
      } else {
        await restoreField(field.id);
      }
      onFieldsChange?.();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update field');
    }
  };

  // Handle duplicate
  const handleDuplicate = async (fieldId: string) => {
    try {
      await duplicateField(fieldId);
      onFieldsChange?.();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to duplicate field');
    }
  };

  // Handle reorder (drag and drop would be ideal, but using up/down for now)
  const handleMoveUp = async (index: number) => {
    if (index === 0) return;
    const newOrder = [...fields];
    [newOrder[index - 1], newOrder[index]] = [newOrder[index], newOrder[index - 1]];
    await reorderFields(newOrder.map(f => f.id));
  };

  const handleMoveDown = async (index: number) => {
    if (index === fields.length - 1) return;
    const newOrder = [...fields];
    [newOrder[index], newOrder[index + 1]] = [newOrder[index + 1], newOrder[index]];
    await reorderFields(newOrder.map(f => f.id));
  };

  const activeFields = fields.filter(f => f.isActive);
  const archivedFields = fields.filter(f => !f.isActive);

  return (
    <div className="custom-fields-settings" data-testid="custom-fields-settings">
      {/* RBAC Warning */}
      {!canModifyFields && (
        <div className="custom-fields-settings__rbac-warning" role="alert">
          <svg
            width="20"
            height="20"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
          >
            <circle cx="12" cy="12" r="10" />
            <line x1="12" y1="8" x2="12" y2="12" />
            <line x1="12" y1="16" x2="12.01" y2="16" />
          </svg>
          <span>
            You have view-only access to custom field settings. Contact an administrator to make changes.
          </span>
        </div>
      )}

      <div className="custom-fields-settings__header">
        <h3 className="custom-fields-settings__title">Custom Fields</h3>
        <p className="custom-fields-settings__description">
          Define custom fields to capture additional information for your CRM entities.
        </p>
      </div>

      {(error || fetchError) && (
        <div className="custom-fields-settings__error" role="alert">
          {error || fetchError?.message}
        </div>
      )}

      {/* Entity Type Tabs */}
      <div className="custom-fields-settings__tabs">
        <button
          className={`custom-fields-settings__tab ${selectedEntity === 'lead' ? 'custom-fields-settings__tab--active' : ''}`}
          onClick={() => setSelectedEntity('lead')}
        >
          Leads
        </button>
        <button
          className={`custom-fields-settings__tab ${selectedEntity === 'deal' ? 'custom-fields-settings__tab--active' : ''}`}
          onClick={() => setSelectedEntity('deal')}
        >
          Opportunities
        </button>
        <button
          className={`custom-fields-settings__tab ${selectedEntity === 'contact' ? 'custom-fields-settings__tab--active' : ''}`}
          onClick={() => setSelectedEntity('contact')}
        >
          Contacts
        </button>
        <button
          className={`custom-fields-settings__tab ${selectedEntity === 'company' ? 'custom-fields-settings__tab--active' : ''}`}
          onClick={() => setSelectedEntity('company')}
        >
          Companies
        </button>
      </div>

      {/* Create Button */}
      <div className="custom-fields-settings__actions">
        <button
          className="custom-fields-settings__create-btn"
          onClick={handleCreate}
          disabled={isLoading || !canModifyFields}
          title={!canModifyFields ? 'Only owners and admins can add custom fields' : undefined}
        >
          + Add Custom Field
        </button>
      </div>

      {/* Fields List */}
      {isLoading ? (
        <div className="custom-fields-settings__loading">Loading fields...</div>
      ) : (
        <>
          {/* Active Fields */}
          {activeFields.length > 0 && (
            <div className="custom-fields-settings__section">
              <h4 className="custom-fields-settings__section-title">Active Fields</h4>
              <div className="custom-fields-settings__list">
                {activeFields.map((field, index) => (
                  <div key={field.id} className="custom-field-item">
                    <div className="custom-field-item__header">
                      <div className="custom-field-item__info">
                        <h5 className="custom-field-item__label">
                          {field.label}
                          {field.required && <span className="custom-field-item__required">*</span>}
                        </h5>
                        <p className="custom-field-item__meta">
                          <span className="custom-field-item__name">{field.name}</span>
                          <span className="custom-field-item__separator">•</span>
                          <span className="custom-field-item__type">{field.fieldType}</span>
                        </p>
                      </div>
                      <div className="custom-field-item__actions">
                        <button
                          className="custom-field-item__action"
                          onClick={() => handleMoveUp(index)}
                          disabled={index === 0 || !canModifyFields}
                          title={!canModifyFields ? 'Only owners and admins can reorder fields' : 'Move up'}
                        >
                          ↑
                        </button>
                        <button
                          className="custom-field-item__action"
                          onClick={() => handleMoveDown(index)}
                          disabled={index === activeFields.length - 1 || !canModifyFields}
                          title={!canModifyFields ? 'Only owners and admins can reorder fields' : 'Move down'}
                        >
                          ↓
                        </button>
                        <button
                          className="custom-field-item__action"
                          onClick={() => handleEdit(field)}
                          disabled={!canModifyFields}
                          title={!canModifyFields ? 'Only owners and admins can edit fields' : 'Edit'}
                        >
                          Edit
                        </button>
                        <button
                          className="custom-field-item__action"
                          onClick={() => handleDuplicate(field.id)}
                          disabled={!canModifyFields}
                          title={!canModifyFields ? 'Only owners and admins can duplicate fields' : 'Duplicate'}
                        >
                          Duplicate
                        </button>
                        <button
                          className="custom-field-item__action"
                          onClick={() => handleToggleActive(field)}
                          disabled={!canModifyFields}
                          title={!canModifyFields ? 'Only owners and admins can archive fields' : 'Archive'}
                        >
                          Archive
                        </button>
                        <button
                          className="custom-field-item__action custom-field-item__action--danger"
                          onClick={() => handleDelete(field.id)}
                          disabled={!canModifyFields}
                          title={!canModifyFields ? 'Only owners and admins can delete fields' : 'Delete'}
                        >
                          Delete
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Archived Fields */}
          {archivedFields.length > 0 && (
            <div className="custom-fields-settings__section">
              <h4 className="custom-fields-settings__section-title">Archived Fields</h4>
              <div className="custom-fields-settings__list">
                {archivedFields.map((field) => (
                  <div key={field.id} className="custom-field-item custom-field-item--archived">
                    <div className="custom-field-item__header">
                      <div className="custom-field-item__info">
                        <h5 className="custom-field-item__label">{field.label}</h5>
                        <p className="custom-field-item__meta">
                          <span className="custom-field-item__name">{field.name}</span>
                          <span className="custom-field-item__separator">•</span>
                          <span className="custom-field-item__type">{field.fieldType}</span>
                        </p>
                      </div>
                      <div className="custom-field-item__actions">
                        <button
                          className="custom-field-item__action"
                          onClick={() => handleToggleActive(field)}
                          disabled={!canModifyFields}
                          title={!canModifyFields ? 'Only owners and admins can restore fields' : 'Restore'}
                        >
                          Restore
                        </button>
                        <button
                          className="custom-field-item__action custom-field-item__action--danger"
                          onClick={() => handleDelete(field.id)}
                          disabled={!canModifyFields}
                          title={!canModifyFields ? 'Only owners and admins can delete fields' : 'Delete'}
                        >
                          Delete
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Empty State */}
          {activeFields.length === 0 && archivedFields.length === 0 && (
            <div className="custom-fields-settings__empty">
              <p>No custom fields defined for {selectedEntity}s yet.</p>
              <p>Click "Add Custom Field" to create your first field.</p>
            </div>
          )}
        </>
      )}

      {/* Editor Modal */}
      {isOpen && (
        <div className="custom-fields-settings__modal-overlay" onClick={close}>
          <div className="custom-fields-settings__modal" onClick={(e) => e.stopPropagation()}>
            <div className="custom-fields-settings__modal-header">
              <h3>{editingField ? 'Edit Custom Field' : 'Create Custom Field'}</h3>
              <button className="custom-fields-settings__modal-close" onClick={close}>
                ×
              </button>
            </div>
            <div className="custom-fields-settings__modal-content">
              <CustomFieldEditor
                field={editingField || undefined}
                businessId={businessId}
                entityType={selectedEntity}
                onSave={handleSave}
                onCancel={close}
                isSaving={isSaving}
              />
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default CustomFieldsSettings;
