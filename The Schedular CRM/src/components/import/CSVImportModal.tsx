import { useEffect, useMemo, useRef, useState } from 'react';
import type { ChangeEvent, DragEvent, ReactNode } from 'react';
import { useCSVImport } from '../../hooks/useCSVImport';
import { Modal } from '../modals';
import { FieldMapper } from './FieldMapper';
import { ImportStepTracker } from './ImportStepTracker';
import { ImportUploadStep } from './ImportUploadStep';
import { ImportPreview } from './ImportPreview';
import { ImportProgress } from './ImportProgress';
import { useAuth } from '../../context/AuthContext';
import { getLeadRepository } from '../../data/repositories/lead-repository';
import { getContactRepository } from '../../data/repositories/contact-repository';
import { createSecurityContextFromParams, sanitizeTeamIds } from '../../lib/security-context';
import {
  autoDetectMappingWithConfidence,
  type MappingConfidence,
} from '../../services/csv-import-service';
import './import.css';
import './import-professional.css';

interface CSVImportModalProps {
  entityType: 'lead' | 'contact' | 'deal' | 'company' | 'client' | 'appointment';
  isOpen: boolean;
  onClose: () => void;
  onSuccess?: () => void;
}

type Step = 'upload' | 'confirm' | 'map' | 'preview' | 'import' | 'complete';

interface DetectionResult {
  mappings: Record<string, MappingConfidence>;
  overallConfidence: number;
  hasFullName: boolean;
  fullNameColumn?: string;
}

export function CSVImportModal({ entityType, isOpen, onClose, onSuccess }: CSVImportModalProps) {
  const [currentStep, setCurrentStep] = useState<Step>('upload');
  const [duplicateHandling, setDuplicateHandling] = useState<'skip' | 'update' | 'create'>('skip');
  const [isDragging, setIsDragging] = useState(false);
  const [validationBlock, setValidationBlock] = useState<string | null>(null);
  const [identifierNotice, setIdentifierNotice] = useState<string | null>(null);
  const [detectionResult, setDetectionResult] = useState<DetectionResult | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const { crmUser, businessId } = useAuth();

  const {
    state,
    error,
    parsedData,
    fieldMapping,
    validationErrors,
    importResult,
    multiEntitySummary,
    progress,
    parseFile,
    setFieldMapping,
    validateData,
    executeImport,
    reset,
    areAllRequiredFieldsMapped,
    setExistingIdentifiers,
  } = useCSVImport();

  const normalizePhoneForValidation = useMemo(() => (value: string) => value.replace(/\D/g, ''), []);

  useEffect(() => {
    let isCancelled = false;

    const loadExistingIdentifiers = async () => {
      if (!isOpen || !businessId || !crmUser) {
        if (!isCancelled) {
          setExistingIdentifiers({});
          setIdentifierNotice(null);
        }
        return;
      }

      if (entityType === 'appointment') {
        if (!isCancelled) {
          setExistingIdentifiers({});
          setIdentifierNotice(null);
        }
        return;
      }

      try {
        const repo = entityType === 'lead' ? getLeadRepository() : getContactRepository();
        const context = createSecurityContextFromParams(
          businessId,
          crmUser.id,
          crmUser.displayName,
          crmUser.role,
          sanitizeTeamIds(crmUser.teamIds || []),
          sanitizeTeamIds(crmUser.managedTeamIds || []),
          crmUser.managerId
        );

        const result = await repo.getAll(context, {
          limit: 500,
          orderBy: { field: 'createdAt', direction: 'desc' },
        });

        if (!result.success) {
          throw new Error(result.error.message);
        }

        const emails = new Set<string>();
        const phones = new Set<string>();
        result.data.data.forEach((record: any) => {
          if (record.email) {
            emails.add(String(record.email).toLowerCase());
          }
          if (record.phone) {
            phones.add(normalizePhoneForValidation(String(record.phone)));
          }
        });

        if (!isCancelled) {
          setExistingIdentifiers({
            emails: Array.from(emails),
            phones: Array.from(phones),
          });
          setIdentifierNotice(
            `Preloaded ${result.data.data.length} existing ${entityType === 'lead' ? 'leads' : 'contacts'} to block duplicate emails/phones during import.`
          );
        }
      } catch (err) {
        if (!isCancelled) {
          setExistingIdentifiers({});
          setIdentifierNotice(
            'Could not preload existing records. Duplicate checks will only apply within the CSV.'
          );
        }
      }
    };

    void loadExistingIdentifiers();

    return () => {
      isCancelled = true;
    };
  }, [businessId, crmUser, entityType, isOpen, normalizePhoneForValidation, setExistingIdentifiers]);

  const handleClose = (didImport = false) => {
    reset();
    setCurrentStep('upload');
    setDuplicateHandling('skip');
    setDetectionResult(null);
    setValidationBlock(null);
    setIdentifierNotice(null);
    if (didImport && onSuccess) {
      onSuccess();
    }
    onClose();
  };

  const handleFileSelect = async (file: File) => {
    if (!file.name.endsWith('.csv')) {
      alert('Please select a CSV file');
      return;
    }

    await parseFile(file, entityType);
  };

  // After parsing, analyze the data and decide next step
  useEffect(() => {
    if (state === 'parsed' && parsedData) {
      const detection = autoDetectMappingWithConfidence(parsedData.headers, entityType);
      setDetectionResult(detection);

      // If all required fields are detected with high confidence, skip to confirm
      if (detection.overallConfidence >= 1.0) {
        setCurrentStep('confirm');
      } else {
        setCurrentStep('map');
      }
    }
  }, [state, parsedData, entityType]);

  const handleFileInputChange = (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      handleFileSelect(file);
    }
  };

  const handleDragOver = (e: DragEvent) => {
    e.preventDefault();
    setIsDragging(true);
  };

  const handleDragLeave = (e: DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
  };

  const handleDrop = (e: DragEvent) => {
    e.preventDefault();
    setIsDragging(false);

    const file = e.dataTransfer.files[0];
    if (file) {
      handleFileSelect(file);
    }
  };

  const handleClickUpload = () => {
    fileInputRef.current?.click();
  };

  const handleNextFromMapping = () => {
    if (!areAllRequiredFieldsMapped(entityType)) {
      alert('Please map all required fields before continuing');
      return;
    }

    setValidationBlock(null);
    validateData(duplicateHandling);
    setCurrentStep('preview');
  };

  const handleStartImport = (skipErrors = false) => {
    if (validationErrors.length > 0 && !skipErrors) {
      setValidationBlock('Some rows have validation errors. You can fix them or import anyway — invalid rows will be skipped.');
      return;
    }

    setValidationBlock(null);
    setCurrentStep('import');
    executeImport({
      entityType,
      skipFirstRow: false, // Already handled during parsing
      duplicateHandling
    });
  };

  const handleBackToUpload = () => {
    reset();
    setCurrentStep('upload');
    setDetectionResult(null);
  };

  // Quick import directly from confirm step (skipping preview)
  const handleQuickImport = () => {
    // First validate, which will transition to 'validated' state
    validateData(duplicateHandling);
    // The actual import will be triggered by the effect below
  };

  // Effect to handle quick import after validation completes
  useEffect(() => {
    if (state === 'validated' && currentStep === 'confirm') {
      if (validationErrors.length > 0) {
        setValidationBlock('Some rows have validation errors. Please review before importing.');
        setCurrentStep('preview');
      } else {
        // No errors, proceed to import
        setValidationBlock(null);
        setCurrentStep('import');
        executeImport({
          entityType,
          skipFirstRow: false,
          duplicateHandling
        });
      }
    }
  }, [state, currentStep, validationErrors.length, entityType, duplicateHandling, executeImport]);

  const getEntityTypeLabel = () => {
    const map: Record<typeof entityType, string> = {
      lead: 'Leads',
      contact: 'Contacts',
      deal: 'Opportunities',
      company: 'Companies',
      client: 'Clients',
      appointment: 'Appointments',
    };
    return map[entityType] || `${entityType}s`;
  };

  let footer: ReactNode = null;

  if (currentStep === 'upload') {
    footer = (
      <button className="btn btn-secondary" onClick={() => handleClose()}>
        Cancel
      </button>
    );
  } else if (currentStep === 'confirm') {
    footer = (
      <>
        <button className="btn btn-secondary" onClick={handleBackToUpload}>
          Back
        </button>
        <button className="btn btn-primary" onClick={handleQuickImport}>
          Import {parsedData?.rows.length || 0} {getEntityTypeLabel()}
        </button>
      </>
    );
  } else if (currentStep === 'map') {
    footer = (
      <>
        <button className="btn btn-secondary" onClick={handleBackToUpload}>
          Back
        </button>
        <button
          className="btn btn-primary"
          onClick={handleNextFromMapping}
          disabled={!areAllRequiredFieldsMapped(entityType)}
        >
          Next: Preview Data
        </button>
      </>
    );
  } else if (currentStep === 'preview') {
    footer = (
      <>
        <button className="btn btn-secondary" onClick={() => setCurrentStep('map')}>
          Back to Mapping
        </button>
        {validationErrors.length > 0 ? (
          <button
            className="btn btn-primary"
            onClick={() => handleStartImport(true)}
          >
            Import Anyway (skip {validationErrors.length} invalid rows)
          </button>
        ) : (
          <button
            className="btn btn-primary"
            onClick={() => handleStartImport()}
          >
            Start Import
          </button>
        )}
      </>
    );
  } else if (currentStep === 'import' && state === 'importing') {
    footer = (
      <button className="btn btn-secondary" disabled>
        Importing...
      </button>
    );
  } else if (state === 'complete') {
    footer = (
      <button className="btn btn-primary" onClick={() => handleClose(true)}>
        Done
      </button>
    );
  }

  return (
    <Modal
      isOpen={isOpen}
      onClose={() => handleClose()}
      title={`Import ${getEntityTypeLabel()} from CSV`}
      size="xl"
      className="import-modal"
      footer={footer}
    >
      <ImportStepTracker currentStep={currentStep} />
      <div className="import-modal__body">
          {/* Step 1: Upload File */}
          {currentStep === 'upload' && (
            <ImportUploadStep
              entityType={entityType}
              isDragging={isDragging}
              fileInputRef={fileInputRef}
              onFileInputChange={handleFileInputChange}
              onDragOver={handleDragOver}
              onDragLeave={handleDragLeave}
              onDrop={handleDrop}
              onClickUpload={handleClickUpload}
            />
          )}

          {/* Step 2a: Smart Confirm (when auto-detection successful) */}
          {currentStep === 'confirm' && parsedData && detectionResult && (
            <div className="import-step-content">
              <div className="smart-import-summary">
                <div className="smart-import-header">
                  <span className="smart-import-icon">✓</span>
                  <div>
                    <h3>Ready to Import</h3>
                    <p className="text-muted">
                      We detected {parsedData.rows.length} {getEntityTypeLabel().toLowerCase()} in your file
                    </p>
                  </div>
                </div>

                <div className="detected-fields">
                  <h4>Detected Fields</h4>
                  <div className="detected-fields-grid">
                    {Object.entries(detectionResult.mappings)
                      .filter(([, conf]) => conf.field && conf.confidence > 0)
                      .map(([header, conf]) => (
                        <div key={header} className="detected-field-item">
                          <span className="detected-field-csv">{header}</span>
                          <span className="detected-field-arrow">→</span>
                          <span className="detected-field-target">
                            {conf.field}
                            {conf.needsTransform === 'splitName' && ' (will split into first/last)'}
                          </span>
                          <span className={`confidence-badge confidence-${conf.confidence >= 0.8 ? 'high' : 'medium'}`}>
                            {conf.confidence >= 0.8 ? '✓' : '~'}
                          </span>
                        </div>
                      ))}
                  </div>
                </div>

                {detectionResult.hasFullName && (
                  <div className="alert alert-info">
                    <strong>Smart Detection:</strong> We found a "name" column and will automatically split it into first and last name.
                  </div>
                )}

                <div className="sample-preview">
                  <h4>Sample Data (first 3 rows)</h4>
                  <div className="sample-table-wrapper">
                    <table className="sample-table">
                      <thead>
                        <tr>
                          {Object.entries(detectionResult.mappings)
                            .filter(([, conf]) => conf.field)
                            .map(([header]) => (
                              <th key={header}>{header}</th>
                            ))}
                        </tr>
                      </thead>
                      <tbody>
                        {parsedData.rows.slice(0, 3).map((row, idx) => (
                          <tr key={idx}>
                            {Object.entries(detectionResult.mappings)
                              .filter(([, conf]) => conf.field)
                              .map(([header]) => {
                                const colIdx = parsedData.headers.indexOf(header);
                                return <td key={header}>{row[colIdx] || '-'}</td>;
                              })}
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>

                <button
                  className="btn btn-ghost"
                  onClick={() => setCurrentStep('map')}
                  type="button"
                >
                  Adjust field mapping manually
                </button>
              </div>
            </div>
          )}

          {/* Step 2b: Manual Map Fields (when auto-detection needs help) */}
          {currentStep === 'map' && parsedData && (
            <div className="import-step-content">
              {error && (
                <div className="alert alert-error">
                  {error}
                </div>
              )}

              {detectionResult && detectionResult.overallConfidence < 1.0 && (
                <div className="alert alert-warning import-map-notice">
                  <strong>Some fields need your help:</strong> We couldn't auto-detect all required fields. Please map them below.
                </div>
              )}

              <FieldMapper
                csvHeaders={parsedData.headers}
                entityType={entityType}
                fieldMapping={fieldMapping}
                onMappingChange={setFieldMapping}
              />

              <div className="duplicate-handling-section">
                <h4>Duplicate Handling</h4>
                <p className="text-muted">How should we handle records with matching email or phone?</p>
                <div className="radio-group">
                  <label>
                    <input
                      type="radio"
                      value="skip"
                      checked={duplicateHandling === 'skip'}
                      onChange={(e) => setDuplicateHandling(e.target.value as 'skip')}
                    />
                    <span>Skip duplicates (keep existing records)</span>
                  </label>
                  <label>
                    <input
                      type="radio"
                      value="update"
                      checked={duplicateHandling === 'update'}
                      onChange={(e) => setDuplicateHandling(e.target.value as 'update')}
                    />
                    <span>Update duplicates (overwrite existing records)</span>
                  </label>
                  <label>
                    <input
                      type="radio"
                      value="create"
                      checked={duplicateHandling === 'create'}
                      onChange={(e) => setDuplicateHandling(e.target.value as 'create')}
                    />
                    <span>Create anyway (allow duplicate records)</span>
                  </label>
                </div>
              </div>

              {identifierNotice && (
                <div className="alert alert-info import-map-notice">
                  {identifierNotice}
                </div>
              )}
            </div>
          )}

          {/* Step 3: Preview Data */}
          {currentStep === 'preview' && parsedData && (
            <div className="import-step-content">
              {validationBlock && <div className="alert alert-error">{validationBlock}</div>}
              <ImportPreview
                headers={parsedData.headers}
                rows={parsedData.rows}
                fieldMapping={fieldMapping}
                validationErrors={validationErrors}
                maxRows={10}
              />
            </div>
          )}

          {/* Step 4: Import Progress / Results */}
          {(currentStep === 'import' || currentStep === 'complete') && (
            <div className="import-step-content">
              <ImportProgress
                progress={progress}
                result={importResult}
                isComplete={state === 'complete'}
                error={error}
                multiEntitySummary={multiEntitySummary}
              />
            </div>
          )}
      </div>
    </Modal>
  );
}
