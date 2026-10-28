/**
 * MergeModal Component
 * Modal for merging duplicate entities with field-by-field comparison
 *
 * Agent CRM-27 Implementation
 */

import { useState, useCallback, useMemo } from 'react';
import { Modal } from '../modals/Modal';
import { FormButton } from '../forms/FormField';
import type { EntityType, MergeResult } from '../../services/DuplicateDetectionService';
import type { Lead, Client, Company } from '../../types/models';
import './duplicates.css';

// ============================================
// Types
// ============================================

export interface MergeModalProps<T = Lead | Client | Company> {
  /** Whether the modal is open */
  isOpen: boolean;
  /** Called when modal should close */
  onClose: () => void;
  /** Entity type being merged */
  entityType: EntityType;
  /** The primary entity to keep */
  primary: T | null;
  /** The secondary entity to merge and archive */
  secondary: T | null;
  /** Called after successful merge */
  onMerge: (
    primaryId: string,
    secondaryId: string,
    fieldPreferences: Record<string, 'primary' | 'secondary'>,
    transferRelatedRecords: boolean
  ) => Promise<MergeResult>;
  /** Whether merge is in progress */
  isMerging?: boolean;
}

interface FieldComparison {
  field: string;
  label: string;
  primaryValue: any;
  secondaryValue: any;
  isDifferent: boolean;
  isImportant: boolean;
}

// ============================================
// Helper Functions
// ============================================

/**
 * Get entity display name
 */
function getEntityName(entity: Lead | Client | Company, entityType: EntityType): string {
  if (entityType === 'company') {
    const companyName = (entity as Company).name;
    return typeof companyName === 'string' && companyName ? companyName : 'Unknown';
  }

  if ('firstName' in entity && 'lastName' in entity) {
    return `${entity.firstName} ${entity.lastName}`;
  }

  return 'Unknown';
}

/**
 * Format field value for display
 */
function formatValue(value: any, _field: string): string {
  if (value === null || value === undefined || value === '') {
    return '(empty)';
  }

  if (Array.isArray(value)) {
    return value.length > 0 ? value.join(', ') : '(empty)';
  }

  if (typeof value === 'boolean') {
    return value ? 'Yes' : 'No';
  }

  if (value instanceof Date) {
    return value.toLocaleDateString();
  }

  if (typeof value === 'object') {
    // Handle address object
    if ('street' in value || 'city' in value) {
      const parts = [
        value.street,
        value.city,
        value.state,
        value.zipCode,
        value.country,
      ].filter(Boolean);
      return parts.length > 0 ? parts.join(', ') : '(empty)';
    }
    return JSON.stringify(value);
  }

  return String(value);
}

/**
 * Compare two field values
 */
function areValuesEqual(value1: any, value2: any): boolean {
  if (value1 === value2) return true;

  if (Array.isArray(value1) && Array.isArray(value2)) {
    if (value1.length !== value2.length) return false;
    return value1.every((v, i) => v === value2[i]);
  }

  if (typeof value1 === 'object' && typeof value2 === 'object') {
    const keys1 = Object.keys(value1 || {});
    const keys2 = Object.keys(value2 || {});
    if (keys1.length !== keys2.length) return false;
    return keys1.every((key) => value1[key] === value2[key]);
  }

  return false;
}

/**
 * Get field comparisons for entities
 */
function getFieldComparisons(
  primary: Lead | Client | Company,
  secondary: Lead | Client | Company,
  entityType: EntityType
): FieldComparison[] {
  const comparisons: FieldComparison[] = [];

  // Define fields to compare based on entity type
  const fieldDefs: Array<{ field: string; label: string; isImportant?: boolean }> =
    entityType === 'company'
      ? [
          { field: 'name', label: 'Company Name', isImportant: true },
          { field: 'email', label: 'Email', isImportant: true },
          { field: 'phone', label: 'Phone', isImportant: true },
          { field: 'website', label: 'Website' },
          { field: 'industry', label: 'Industry' },
          { field: 'size', label: 'Company Size' },
          { field: 'address', label: 'Address' },
          { field: 'notes', label: 'Notes' },
          { field: 'tags', label: 'Tags' },
        ]
      : [
          { field: 'firstName', label: 'First Name', isImportant: true },
          { field: 'lastName', label: 'Last Name', isImportant: true },
          { field: 'email', label: 'Email', isImportant: true },
          { field: 'phone', label: 'Phone', isImportant: true },
          { field: 'companyName', label: 'Company' },
          { field: 'title', label: 'Title' },
          { field: 'status', label: 'Status' },
          { field: 'source', label: 'Source' },
          { field: 'lifecycle', label: 'Lifecycle' },
          { field: 'address', label: 'Address' },
          { field: 'notes', label: 'Notes' },
          { field: 'crmNotes', label: 'CRM Notes' },
          { field: 'tags', label: 'Tags' },
        ];

  for (const { field, label, isImportant = false } of fieldDefs) {
    if (field in primary || field in secondary) {
      const primaryValue = (primary as any)[field];
      const secondaryValue = (secondary as any)[field];
      const isDifferent = !areValuesEqual(primaryValue, secondaryValue);

      comparisons.push({
        field,
        label,
        primaryValue,
        secondaryValue,
        isDifferent,
        isImportant,
      });
    }
  }

  return comparisons;
}

// ============================================
// Component
// ============================================

/**
 * MergeModal - Side-by-side comparison and merge workflow
 *
 * @example
 * ```tsx
 * const [showMerge, setShowMerge] = useState(false);
 * const [mergeData, setMergeData] = useState<{ primary: Client; secondary: Client }>();
 * const { mergeEntities, isMerging } = useDuplicateDetection();
 *
 * <MergeModal
 *   isOpen={showMerge}
 *   onClose={() => setShowMerge(false)}
 *   entityType="client"
 *   primary={mergeData?.primary}
 *   secondary={mergeData?.secondary}
 *   onMerge={async (primaryId, secondaryId, fieldPrefs, transferRecords) => {
 *     return await mergeEntities({
 *       entityType: 'client',
 *       primaryId,
 *       secondaryId,
 *       fieldPreferences: fieldPrefs,
 *       transferRelatedRecords: transferRecords,
 *     });
 *   }}
 *   isMerging={isMerging}
 * />
 * ```
 */
export function MergeModal<T extends Lead | Client | Company>({
  isOpen,
  onClose,
  entityType,
  primary,
  secondary,
  onMerge,
  isMerging = false,
}: MergeModalProps<T>) {
  const [fieldPreferences, setFieldPreferences] = useState<Record<string, 'primary' | 'secondary'>>(
    {}
  );
  const [transferRelatedRecords, setTransferRelatedRecords] = useState(true);
  const [step, setStep] = useState<'compare' | 'confirm' | 'merging' | 'success'>('compare');
  const [mergeResult, setMergeResult] = useState<MergeResult | null>(null);

  // Get field comparisons
  const comparisons = useMemo(() => {
    if (!primary || !secondary) return [];
    return getFieldComparisons(primary, secondary, entityType);
  }, [primary, secondary, entityType]);

  // Get merged preview (for future use)
  // This will be used when implementing preview functionality
  // const mergedPreview = useMemo(() => {
  //   if (!primary || !secondary) return null;

  //   const preview: Record<string, any> = {};

  //   for (const comparison of comparisons) {
  //     const preference = fieldPreferences[comparison.field] || 'primary';
  //     const value =
  //       preference === 'primary' ? comparison.primaryValue : comparison.secondaryValue;
  //     preview[comparison.field] = value;
  //   }

  //   // Handle tags specially - always merge
  //   if ('tags' in primary || 'tags' in secondary) {
  //     const primaryTags = (primary as any).tags || [];
  //     const secondaryTags = (secondary as any).tags || [];
  //     preview.tags = Array.from(new Set([...primaryTags, ...secondaryTags]));
  //   }

  //   return preview;
  // }, [primary, secondary, comparisons, fieldPreferences]);

  // Handle field selection
  const handleFieldSelect = useCallback((field: string, source: 'primary' | 'secondary') => {
    setFieldPreferences((prev) => ({
      ...prev,
      [field]: source,
    }));
  }, []);

  // Handle merge
  const handleMerge = useCallback(async () => {
    if (!primary || !secondary) return;

    setStep('merging');

    try {
      const result = await onMerge(
        primary.id,
        secondary.id,
        fieldPreferences,
        transferRelatedRecords
      );

      setMergeResult(result);
      setStep('success');
    } catch (error) {
      setStep('compare');
      // Error is handled by parent component
    }
  }, [primary, secondary, fieldPreferences, transferRelatedRecords, onMerge]);

  // Handle close
  const handleClose = useCallback(() => {
    setFieldPreferences({});
    setTransferRelatedRecords(true);
    setStep('compare');
    setMergeResult(null);
    onClose();
  }, [onClose]);

  // Don't render if no entities
  if (!primary || !secondary) {
    return null;
  }

  const primaryName = getEntityName(primary, entityType);
  const secondaryName = getEntityName(secondary, entityType);

  return (
    <Modal
      isOpen={isOpen}
      onClose={handleClose}
      title={`Merge ${entityType === 'company' ? 'Companies' : entityType === 'lead' ? 'Leads' : 'Contacts'}`}
      size="lg"
      closeOnOverlayClick={!isMerging}
      closeOnEscape={!isMerging}
    >
      {/* Compare Step */}
      {step === 'compare' && (
        <div className="merge-modal">
          <div className="merge-modal__header">
            <p className="merge-modal__description">
              Select which values to keep for each field. The primary record will be kept and the
              secondary will be archived.
            </p>
          </div>

          {/* Entity Headers */}
          <div className="merge-comparison">
            <div className="merge-comparison__headers">
              <div className="merge-comparison__header merge-comparison__header--primary">
                <h4 className="merge-comparison__title">Primary (Keep)</h4>
                <p className="merge-comparison__name">{primaryName}</p>
              </div>
              <div className="merge-comparison__divider" />
              <div className="merge-comparison__header merge-comparison__header--secondary">
                <h4 className="merge-comparison__title">Secondary (Archive)</h4>
                <p className="merge-comparison__name">{secondaryName}</p>
              </div>
            </div>

            {/* Field Comparisons */}
            <div className="merge-comparison__fields">
              {comparisons.map((comparison) => {
                const preference = fieldPreferences[comparison.field] || 'primary';
                const showComparison = comparison.isDifferent || comparison.isImportant;

                if (!showComparison && !comparison.isDifferent) {
                  return null; // Skip identical non-important fields
                }

                return (
                  <div
                    key={comparison.field}
                    className={`merge-field ${comparison.isDifferent ? 'merge-field--different' : ''}`}
                  >
                    <div className="merge-field__label">
                      {comparison.label}
                      {comparison.isDifferent && (
                        <span className="merge-field__badge">Different</span>
                      )}
                    </div>

                    <div className="merge-field__values">
                      <button
                        type="button"
                        className={`merge-field__value merge-field__value--primary ${
                          preference === 'primary' ? 'merge-field__value--selected' : ''
                        }`}
                        onClick={() => handleFieldSelect(comparison.field, 'primary')}
                        disabled={isMerging}
                      >
                        <div className="merge-field__value-content">
                          {formatValue(comparison.primaryValue, comparison.field)}
                        </div>
                        {preference === 'primary' && (
                          <div className="merge-field__checkmark">✓</div>
                        )}
                      </button>

                      <div className="merge-field__divider" />

                      <button
                        type="button"
                        className={`merge-field__value merge-field__value--secondary ${
                          preference === 'secondary' ? 'merge-field__value--selected' : ''
                        }`}
                        onClick={() => handleFieldSelect(comparison.field, 'secondary')}
                        disabled={isMerging}
                      >
                        <div className="merge-field__value-content">
                          {formatValue(comparison.secondaryValue, comparison.field)}
                        </div>
                        {preference === 'secondary' && (
                          <div className="merge-field__checkmark">✓</div>
                        )}
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Transfer Options */}
            <div className="merge-options">
              <label className="merge-options__checkbox">
                <input
                  type="checkbox"
                  checked={transferRelatedRecords}
                  onChange={(e) => setTransferRelatedRecords(e.target.checked)}
                  disabled={isMerging}
                />
                <span>
                  Transfer related records (deals, activities) from secondary to primary
                </span>
              </label>
            </div>
          </div>

          {/* Actions */}
          <div className="form-actions">
            <FormButton type="button" variant="secondary" onClick={handleClose} disabled={isMerging}>
              Cancel
            </FormButton>
            <FormButton type="button" variant="primary" onClick={handleMerge} disabled={isMerging}>
              Merge Records
            </FormButton>
          </div>
        </div>
      )}

      {/* Merging Step */}
      {step === 'merging' && (
        <div className="modal-loading">
          <div className="modal-loading__spinner" />
          <p className="modal-loading__text">Merging records...</p>
        </div>
      )}

      {/* Success Step */}
      {step === 'success' && mergeResult && (
        <div className="merge-success">
          <div className="merge-success__icon">✓</div>
          <h3 className="merge-success__title">Records Merged Successfully</h3>
          <p className="merge-success__description">
            The records have been merged into {primaryName}.
          </p>

          {mergeResult.recordsTransferred > 0 && (
            <div className="merge-success__stats">
              <p>
                <strong>{mergeResult.recordsTransferred}</strong> related records transferred
              </p>
              {mergeResult.transferredDealIds.length > 0 && (
                <p>
                  <strong>{mergeResult.transferredDealIds.length}</strong> deals
                </p>
              )}
              {mergeResult.transferredActivityIds.length > 0 && (
                <p>
                  <strong>{mergeResult.transferredActivityIds.length}</strong> activities
                </p>
              )}
            </div>
          )}

          <div className="form-actions">
            <FormButton type="button" variant="primary" onClick={handleClose}>
              Done
            </FormButton>
          </div>
        </div>
      )}
    </Modal>
  );
}

export default MergeModal;
