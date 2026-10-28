import { useState, useCallback } from 'react';
import {
  parseCSV,
  autoDetectMapping,
  autoDetectMappingWithConfidence,
  validateAllRows,
  AVAILABLE_FIELDS,
  type ExistingIdentifiers,
  type ImportResult,
} from '../services/csv-import-service';
import type {
  ImportConfig,
  ParsedCSV,
  ValidationError,
} from '../services/csv-import-service';
import { useAuth } from '../context/AuthContext';
import {
  startImportJob,
  type ImportDataRequest,
} from '../services/cloud-functions-integration';
import type { ImportJobResult } from '../services/import-export-service';
import type { MultiEntitySummary } from '../components/import/ImportProgress';
import {
  getImportRoutingDecision,
  type SupportedImportEntity,
} from '../services/import-routing';

type NormalizedImportJobResult = {
  result: ImportResult;
  multiEntitySummary: MultiEntitySummary | null;
};

function toEntitySummary(
  created?: number,
  updated?: number,
  skipped?: number
): MultiEntitySummary[keyof MultiEntitySummary] | null {
  if (
    typeof created !== 'number' &&
    typeof updated !== 'number' &&
    typeof skipped !== 'number'
  ) {
    return null;
  }

  return {
    created: created ?? 0,
    updated: updated ?? 0,
    skipped: skipped ?? 0,
  };
}

export function normalizeMultiEntitySummary(
  summary?: ImportJobResult['multiEntitySummary'] | null
): MultiEntitySummary | null {
  if (!summary) {
    return null;
  }

  const normalized: MultiEntitySummary = {};

  const companies = toEntitySummary(
    summary.companies?.created ?? summary.companiesCreated,
    summary.companies?.updated ?? summary.companiesUpdated,
    summary.companies?.skipped ?? summary.companiesSkipped
  );
  if (companies) normalized.companies = companies;

  const contacts = toEntitySummary(
    summary.contacts?.created ?? summary.contactsCreated,
    summary.contacts?.updated ?? summary.contactsUpdated,
    summary.contacts?.skipped ?? summary.contactsSkipped
  );
  if (contacts) normalized.contacts = contacts;

  const leads = toEntitySummary(
    summary.leads?.created ?? summary.leadsCreated,
    summary.leads?.updated ?? summary.leadsUpdated,
    summary.leads?.skipped ?? summary.leadsSkipped
  );
  if (leads) normalized.leads = leads;

  const deals = toEntitySummary(
    summary.deals?.created ?? summary.dealsCreated,
    summary.deals?.updated ?? summary.dealsUpdated,
    summary.deals?.skipped ?? summary.dealsSkipped
  );
  if (deals) normalized.deals = deals;

  return Object.keys(normalized).length > 0 ? normalized : null;
}

export function mapImportJobToResult(job: ImportJobResult): NormalizedImportJobResult {
  const validation = job.validationErrors || [];
  const imported = Math.max(0, job.processedRows || 0);
  const skipped = Math.max(0, job.totalRows - imported);
  const validationErrorsMapped = validation.map((err) => ({
    row: err.row,
    error: err.error,
  }));
  const generalErrors = (job.errors || []).map((message, idx) => ({
    row: validationErrorsMapped.length + idx + 1,
    error: message,
  }));

  return {
    result: {
      totalRows: job.totalRows,
      imported,
      skipped,
      errors: [...validationErrorsMapped, ...generalErrors],
      dryRun: false,
    },
    multiEntitySummary: normalizeMultiEntitySummary(job.multiEntitySummary),
  };
}

type ImportState =
  | 'idle'
  | 'parsing'
  | 'parsed'
  | 'validating'
  | 'validated'
  | 'importing'
  | 'complete'
  | 'error';

type SupportedEntity = SupportedImportEntity;

export interface UseCSVImportReturn {
  // State
  state: ImportState;
  error: string | null;
  parsedData: ParsedCSV | null;
  fieldMapping: Record<string, string>;
  validationErrors: ValidationError[];
  importResult: ImportResult | null;
  multiEntitySummary: MultiEntitySummary | null;
  progress: { current: number; total: number } | null;

  // Actions
  parseFile: (file: File, entityType: SupportedEntity) => Promise<void>;
  setFieldMapping: (mapping: Record<string, string>) => void;
  validateData: (duplicateHandling?: 'skip' | 'update' | 'create') => void;
  executeImport: (config: Omit<ImportConfig, 'fieldMapping'>) => Promise<void>;
  reset: () => void;
  setExistingIdentifiers: (identifiers: ExistingIdentifiers) => void;

  // Helpers
  getAvailableFields: (entityType: string) => { label: string; required: boolean }[];
  getMappedFieldsCount: () => number;
  getRequiredFieldsCount: (entityType: string) => number;
  areAllRequiredFieldsMapped: (entityType: string) => boolean;
}

export function useCSVImport(): UseCSVImportReturn {
  const [state, setState] = useState<ImportState>('idle');
  const [error, setError] = useState<string | null>(null);
  const [parsedData, setParsedData] = useState<ParsedCSV | null>(null);
  const [fieldMapping, setFieldMapping] = useState<Record<string, string>>({});
  const [validationErrors, setValidationErrors] = useState<ValidationError[]>([]);
  const [importResult, setImportResult] = useState<ImportResult | null>(null);
  const [multiEntitySummary, setMultiEntitySummary] = useState<MultiEntitySummary | null>(null);
  const [progress, setProgress] = useState<{ current: number; total: number } | null>(null);
  const [entityType, setEntityType] = useState<SupportedEntity>('lead');
  const [existingIdentifiers, setExistingIdentifiers] = useState<ExistingIdentifiers>({});

  const { businessId } = useAuth();

  /**
   * Parse CSV file and auto-detect field mappings
   */
  const parseFile = useCallback(async (file: File, type: SupportedEntity) => {
    setState('parsing');
    setError(null);
    setEntityType(type);

    try {
      const parsed = await parseCSV(file);
      setParsedData(parsed);

      // Auto-detect field mappings
      const autoMapping = autoDetectMapping(parsed.headers, type);
      setFieldMapping(autoMapping);

      setState('parsed');
    } catch (err) {
      setState('error');
      setError(err instanceof Error ? err.message : 'Failed to parse CSV file');
    }
  }, []);

  /**
   * Update field mapping
   */
  const setMapping = useCallback((mapping: Record<string, string>) => {
    setFieldMapping(mapping);
    // Clear validation errors when mapping changes
    setValidationErrors([]);
  }, []);

  /**
   * Validate all rows with current field mapping
   */
  const validateData = useCallback((duplicateHandling: 'skip' | 'update' | 'create' = 'skip') => {
    if (!parsedData) {
      setError('No data to validate');
      return;
    }

    setState('validating');
    setError(null);

    try {
      const errors = validateAllRows(
        parsedData.rows,
        parsedData.headers,
        entityType,
        fieldMapping,
        existingIdentifiers,
        duplicateHandling
      );

      setValidationErrors(errors);
      setState('validated');
    } catch (err) {
      setState('error');
      setError(err instanceof Error ? err.message : 'Validation failed');
    }
  }, [parsedData, entityType, fieldMapping, existingIdentifiers]);

  /**
   * Execute the import
   */
  const executeImport = useCallback(async (config: Omit<ImportConfig, 'fieldMapping'>) => {
    if (!parsedData || !businessId) {
      setError('Cannot import: missing data or business ID');
      return;
    }

    setState('importing');
    setError(null);
    setProgress({ current: 0, total: parsedData.rows.length });

    try {
      const hasIdentifiers =
        (existingIdentifiers.emails && existingIdentifiers.emails.length > 0) ||
        (existingIdentifiers.phones && existingIdentifiers.phones.length > 0);

      const routing = getImportRoutingDecision(config.entityType, fieldMapping);

      const request: ImportDataRequest = {
        entityType: routing.entityType,
        primaryEntityType: routing.primaryEntityType,
        rows: parsedData.rows,
        headers: parsedData.headers,
        fieldMapping,
        sessionId: undefined,
        businessId,
        existingIdentifiers: hasIdentifiers ? existingIdentifiers : undefined,
        duplicateHandling: config.duplicateHandling,
        skipFirstRow: config.skipFirstRow,
        dryRun: config.dryRun,
      };

      const result = await startImportJob(request);

      const normalized = mapImportJobToResult(result);
      setImportResult(normalized.result);
      setMultiEntitySummary(normalized.multiEntitySummary);

      const isTotalFailure = !result.success && normalized.result.imported === 0;
      if (isTotalFailure) {
        setState('error');
        setError(result.errors?.[0] || 'Import failed');
        return;
      }

      setProgress({ current: normalized.result.imported, total: normalized.result.totalRows });
      setState('complete');
    } catch (err) {
      setState('error');
      setError(err instanceof Error ? err.message : 'Import failed');
    }
  }, [parsedData, businessId, fieldMapping, existingIdentifiers]);

  /**
   * Reset all state
   */
  const reset = useCallback(() => {
    setState('idle');
    setError(null);
    setParsedData(null);
    setFieldMapping({});
    setValidationErrors([]);
    setImportResult(null);
    setMultiEntitySummary(null);
    setProgress(null);
  }, []);

  /**
   * Get available fields for an entity type
   */
  const getAvailableFields = useCallback((type: string) => {
    return AVAILABLE_FIELDS[type] || [];
  }, []);

  /**
   * Get count of mapped fields
   */
  const getMappedFieldsCount = useCallback(() => {
    return Object.keys(fieldMapping).filter(key => fieldMapping[key]).length;
  }, [fieldMapping]);

  /**
   * Get count of required fields for entity type
   */
  const getRequiredFieldsCount = useCallback((type: string) => {
    const fields = AVAILABLE_FIELDS[type] || [];
    return fields.filter(f => f.required).length;
  }, []);

  /**
   * Check if all required fields are mapped
   */
  const areAllRequiredFieldsMapped = useCallback((type: string) => {
    const fields = AVAILABLE_FIELDS[type] || [];
    const requiredFields = fields.filter(f => f.required).map(f => f.label);
    const mappedFields = Object.values(fieldMapping);

    // Check if we have a fullName column that will be split into firstName + lastName
    const headers = parsedData?.headers || [];
    const detection = headers.length > 0 ? autoDetectMappingWithConfidence(headers, type) : null;
    const hasFullNameSplit = detection?.hasFullName === true;

    return requiredFields.every(field => {
      // If lastName is required and we have fullName split, it's satisfied
      if (field === 'lastName' && hasFullNameSplit && mappedFields.includes('firstName')) {
        return true;
      }
      return mappedFields.includes(field);
    });
  }, [fieldMapping, parsedData]);

  return {
    // State
    state,
    error,
    parsedData,
    fieldMapping,
    validationErrors,
    importResult,
    multiEntitySummary,
    progress,

    // Actions
    parseFile,
    setFieldMapping: setMapping,
    validateData,
    executeImport,
    reset,
    setExistingIdentifiers,

    // Helpers
    getAvailableFields,
    getMappedFieldsCount,
    getRequiredFieldsCount,
    areAllRequiredFieldsMapped
  };
}
