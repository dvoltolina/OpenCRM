import { describe, expect, it } from 'vitest';
import type { ImportJobResult } from '../../services/import-export-service';
import { mapImportJobToResult, normalizeMultiEntitySummary } from '../useCSVImport';

describe('useCSVImport helpers', () => {
  it('normalizes flat backend multi-entity summaries into the UI shape', () => {
    const normalized = normalizeMultiEntitySummary({
      companiesCreated: 2,
      contactsCreated: 4,
      leadsCreated: 1,
      dealsCreated: 3,
    });

    expect(normalized).toEqual({
      companies: { created: 2, updated: 0, skipped: 0 },
      contacts: { created: 4, updated: 0, skipped: 0 },
      leads: { created: 1, updated: 0, skipped: 0 },
      deals: { created: 3, updated: 0, skipped: 0 },
    });
  });

  it('preserves imported row counts on partial success responses', () => {
    const job: ImportJobResult = {
      success: false,
      sessionId: 'import_123',
      processedRows: 3,
      totalRows: 4,
      validationErrors: [{ row: 4, field: 'email', error: 'Duplicate email' }],
      errors: ['Validation required before import'],
      multiEntitySummary: {
        contactsCreated: 3,
      },
    };

    const normalized = mapImportJobToResult(job);

    expect(normalized.result.imported).toBe(3);
    expect(normalized.result.skipped).toBe(1);
    expect(normalized.result.errors).toEqual([
      { row: 4, error: 'Duplicate email' },
      { row: 2, error: 'Validation required before import' },
    ]);
    expect(normalized.multiEntitySummary).toEqual({
      contacts: { created: 3, updated: 0, skipped: 0 },
    });
  });

  it('accepts already-normalized multi-entity summaries', () => {
    const normalized = normalizeMultiEntitySummary({
      companies: { created: 1, updated: 2, skipped: 3 },
    });

    expect(normalized).toEqual({
      companies: { created: 1, updated: 2, skipped: 3 },
    });
  });
});
