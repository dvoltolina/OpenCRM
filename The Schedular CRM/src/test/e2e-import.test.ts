/**
 * E2E Import Tests (Agent M5)
 *
 * End-to-end verification of CSV import flow:
 * - Frontend: useCSVImport hook + csv-import-service
 * - Backend: Functions importer.ts
 * - Database: Firestore writes/reads
 *
 * HIPAA Compliance:
 * - Tests use synthetic data only (no real PHI)
 * - Validates that NO PHI appears in logs/metrics
 * - Verifies tenant isolation and RBAC enforcement
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import { readFileSync } from 'fs';
import { join } from 'path';
import { parseCSV, validateAllRows, autoDetectMapping, AVAILABLE_FIELDS } from '../services/csv-import-service';
import { getImportRoutingDecision } from '../services/import-routing';
import { runImport } from '../../functions/src/importer';
import type { ImportJobPayload } from '../../functions/src/importer';
import { runMultiEntityImport } from '../../functions/src/multi-entity-import-handler';

// ============================================
// Test Helpers
// ============================================

function loadFixture(filename: string): File {
  const path = join(__dirname, 'fixtures', filename);
  const content = readFileSync(path, 'utf-8');
  const blob = new Blob([content], { type: 'text/csv' });
  return new File([blob], filename, { type: 'text/csv' });
}

// Mock Firestore for E2E tests
class MockFirestore {
  private collections = new Map<string, Map<string, any>>();

  collection(path: string) {
    if (!this.collections.has(path)) {
      this.collections.set(path, new Map());
    }
    const buildSnapshot = (entries: Array<[string, any]>) => ({
      empty: entries.length === 0,
      docs: entries.map(([id, data]) => ({ id, data: () => data })),
    });
    const buildQuery = (entries: Array<[string, any]>) => ({
      where: (field: string, _op: unknown, value: unknown) =>
        buildQuery(entries.filter(([, data]) => data?.[field] === value)),
      orderBy: (field: string, direction: 'asc' | 'desc' = 'asc') =>
        buildQuery(
          [...entries].sort((a, b) => {
            const left = a[1]?.[field];
            const right = b[1]?.[field];
            if (left === right) return 0;
            if (left === undefined) return direction === 'asc' ? 1 : -1;
            if (right === undefined) return direction === 'asc' ? -1 : 1;
            return left > right
              ? (direction === 'asc' ? 1 : -1)
              : (direction === 'asc' ? -1 : 1);
          })
        ),
      limit: (n: number) => ({
        get: async () => buildSnapshot(entries.slice(0, n)),
      }),
      get: async () => buildSnapshot(entries),
    });

    return {
      doc: (id?: string) => {
        const docId = id || `doc_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
        const collectionMap = this.collections.get(path)!;
        return {
          id: docId,
          collection: (subPath: string) => this.collection(`${path}/${docId}/${subPath}`),
          set: async (data: any, options?: any) => {
            const existing = collectionMap.get(docId) || {};
            const merged = options?.merge ? { ...existing, ...data, id: docId } : { ...data, id: docId };
            collectionMap.set(docId, merged);
            return Promise.resolve();
          },
          get: async () => ({
            exists: collectionMap.has(docId),
            id: docId,
            data: () => collectionMap.get(docId),
          }),
        };
      },
      where: (field: string, _op: unknown, value: unknown) =>
        buildQuery(
          Array.from(this.collections.get(path)?.entries() || []).filter(
            ([, data]) => data?.[field] === value
          )
        ),
      limit: (n: number) => ({
        get: async () => buildSnapshot(Array.from(this.collections.get(path)?.entries() || []).slice(0, n)),
      }),
      add: async (data: any) => {
        const docId = `doc_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
        const collectionMap = this.collections.get(path)!;
        collectionMap.set(docId, { ...data, id: docId });
        return { id: docId };
      },
    };
  }

  getAll(path: string): any[] {
    return Array.from(this.collections.get(path)?.values() || []);
  }

  clear() {
    this.collections.clear();
  }
}

// Mock FieldValue
vi.mock('../../functions/src/firebaseAdmin', () => ({
  FieldValue: {
    serverTimestamp: () => new Date().toISOString(),
  },
}));

// ============================================
// E2E Test Suite
// ============================================

describe('E2E CSV Import Flow', () => {
  let mockDb: MockFirestore;
  const testBusinessId = 'test-business-123';
  const testUserId = 'test-user-456';
  const testUserRole = 'admin';

  beforeEach(() => {
    mockDb = new MockFirestore();
  });

  it('routes only relational imports through the multi-entity backend path', () => {
    expect(getImportRoutingDecision('lead', { firstName: 'firstName', email: 'email' })).toEqual({
      entityType: 'lead',
    });

    expect(getImportRoutingDecision('company', { name: 'name' })).toEqual({
      entityType: 'company',
    });

    expect(
      getImportRoutingDecision('contact', {
        firstName: 'firstName',
        dealTitle: 'dealTitle',
      })
    ).toEqual({
      entityType: 'multi',
      primaryEntityType: 'contact',
    });

    expect(getImportRoutingDecision('deal', { title: 'title', clientEmail: 'clientEmail' })).toEqual({
      entityType: 'multi',
      primaryEntityType: 'deal',
    });
  });

  // ============================================
  // Test 1: Company-Only Import
  // ============================================

  it('imports company-only CSV end-to-end', async () => {
    const file = loadFixture('company-only.csv');
    const parsed = await parseCSV(file);

    expect(parsed.headers).toEqual(['name', 'industry', 'size', 'website', 'phone', 'email', 'address', 'notes']);
    expect(parsed.rows).toHaveLength(3);

    // Auto-detect mapping
    const mapping = autoDetectMapping(parsed.headers, 'company');
    expect(getImportRoutingDecision('company', mapping)).toEqual({ entityType: 'company' });
    expect(mapping).toMatchObject({
      name: 'name',
      industry: 'industry',
      size: 'size',
      website: 'website',
      phone: 'phone',
      email: 'email',
      address: 'address',
      notes: 'notes',
    });

    // Validate
    const validationErrors = validateAllRows(parsed.rows, parsed.headers, 'company', mapping);
    expect(validationErrors).toHaveLength(0);

    // Import via backend function
    const payload: ImportJobPayload = {
      entityType: 'company',
      headers: parsed.headers,
      rows: parsed.rows,
      fieldMapping: mapping,
      businessId: testBusinessId,
      duplicateHandling: 'skip',
      userId: testUserId,
      userRole: testUserRole,
      userBusinessId: testBusinessId,
    };

    const result = await runImport(mockDb as any, payload);

    expect(result.imported).toBe(3);
    expect(result.skipped).toBe(0);
    expect(result.validationErrors).toHaveLength(0);

    // Verify database writes
    const companies = mockDb.getAll(`businesses/${testBusinessId}/companies`);
    expect(companies).toHaveLength(3);
    expect(companies[0].name).toBe('Acme Corp');
    expect(companies[0].industry).toBe('Technology');
  });

  // ============================================
  // Test 2: Contact-Only Import
  // ============================================

  it('imports contact-only CSV with leadStatus and rep assignment', async () => {
    const file = loadFixture('contact-only.csv');
    const parsed = await parseCSV(file);

    expect(parsed.headers).toContain('leadStatus');
    expect(parsed.headers).toContain('assignedRepEmail');
    expect(parsed.rows).toHaveLength(4);

    const mapping = autoDetectMapping(parsed.headers, 'contact');
    expect(getImportRoutingDecision('contact', mapping)).toEqual({ entityType: 'contact' });
    const validationErrors = validateAllRows(parsed.rows, parsed.headers, 'contact', mapping);
    expect(validationErrors).toHaveLength(0);

    const payload: ImportJobPayload = {
      entityType: 'contact',
      headers: parsed.headers,
      rows: parsed.rows,
      fieldMapping: mapping,
      businessId: testBusinessId,
      duplicateHandling: 'skip',
      userId: testUserId,
      userRole: testUserRole,
      userBusinessId: testBusinessId,
    };

    const result = await runImport(mockDb as any, payload);

    expect(result.imported).toBe(4);
    expect(result.skipped).toBe(0);

    const contacts = mockDb.getAll(`businesses/${testBusinessId}/clients`);
    expect(mockDb.getAll(`businesses/${testBusinessId}/contacts`)).toHaveLength(0);
    expect(contacts).toHaveLength(4);
    expect(contacts[0].firstName).toBe('John');
    expect(contacts[0].email).toBe('john.doe@example.com');
  });

  // ============================================
  // Test 3: Lead + Contact Combined
  // ============================================

  it('imports lead+contact CSV', async () => {
    const file = loadFixture('lead-contact.csv');
    const parsed = await parseCSV(file);

    const mapping = autoDetectMapping(parsed.headers, 'lead');
    expect(getImportRoutingDecision('lead', mapping)).toEqual({ entityType: 'lead' });
    const validationErrors = validateAllRows(parsed.rows, parsed.headers, 'lead', mapping);
    expect(validationErrors).toHaveLength(0);

    const payload: ImportJobPayload = {
      entityType: 'lead',
      headers: parsed.headers,
      rows: parsed.rows,
      fieldMapping: mapping,
      businessId: testBusinessId,
      duplicateHandling: 'skip',
      userId: testUserId,
      userRole: testUserRole,
      userBusinessId: testBusinessId,
    };

    const result = await runImport(mockDb as any, payload);

    expect(result.imported).toBe(3);
    expect(result.skipped).toBe(0);

    const leads = mockDb.getAll(`businesses/${testBusinessId}/leads`);
    expect(leads).toHaveLength(3);
    expect(leads[0].firstName).toBe('Sarah');
    expect(leads[0].status).toBe('qualified');
    expect(leads[0].source).toBe('website');
  });

  // ============================================
  // Test 4: Deal + Company + Contact (Multi-Entity)
  // ============================================

  it('imports deal+company+contact CSV with auto-linking', async () => {
    const file = loadFixture('deal-company-contact.csv');
    const parsed = await parseCSV(file);

    const mapping = autoDetectMapping(parsed.headers, 'deal');
    const validationErrors = validateAllRows(parsed.rows, parsed.headers, 'deal', mapping);
    expect(validationErrors).toHaveLength(0);
    const routing = getImportRoutingDecision('deal', mapping);
    expect(routing).toEqual({
      entityType: 'multi',
      primaryEntityType: 'deal',
    });

    const payload: ImportJobPayload = {
      entityType: 'multi',
      primaryEntityType: routing.primaryEntityType,
      headers: parsed.headers,
      rows: parsed.rows,
      fieldMapping: mapping,
      businessId: testBusinessId,
      duplicateHandling: 'skip',
      userId: testUserId,
      userRole: testUserRole,
      userBusinessId: testBusinessId,
    };

    await mockDb.collection(`businesses/${testBusinessId}/pipelines`).doc('pipeline-default').set({
      name: 'Default Pipeline',
      isDefault: true,
      businessId: testBusinessId,
    });
    await mockDb.collection(`businesses/${testBusinessId}/stages`).doc('stage-default').set({
      name: 'Qualification',
      pipelineId: 'pipeline-default',
      order: 1,
      probability: 25,
      businessId: testBusinessId,
    });

    const result = await runMultiEntityImport(mockDb as any, payload);

    expect(result.imported).toBe(4);
    expect(result.skipped).toBe(0);

    const deals = mockDb.getAll(`businesses/${testBusinessId}/deals`);
    const contacts = mockDb.getAll(`businesses/${testBusinessId}/clients`);
    expect(mockDb.getAll(`businesses/${testBusinessId}/contacts`)).toHaveLength(0);
    expect(deals).toHaveLength(4);
    expect(contacts).toHaveLength(4);
    expect(deals[0].title).toBe('Enterprise License Deal');
    expect(deals[0].valueCents).toBe(500000);
    expect(deals[0].clientId).toBeTruthy();
    expect(deals[0].clientEmail).toBe('john.doe@example.com');
  });

  // ============================================
  // Test 5: Duplicate Handling
  // ============================================

  it('detects and skips duplicates', async () => {
    const file = loadFixture('duplicates.csv');
    const parsed = await parseCSV(file);

    const mapping = autoDetectMapping(parsed.headers, 'lead');

    // First import
    const payload1: ImportJobPayload = {
      entityType: 'lead',
      headers: parsed.headers,
      rows: parsed.rows.slice(0, 1), // Import first row
      fieldMapping: mapping,
      businessId: testBusinessId,
      duplicateHandling: 'skip',
      userId: testUserId,
      userRole: testUserRole,
      userBusinessId: testBusinessId,
    };

    const result1 = await runImport(mockDb as any, payload1);
    expect(result1.imported).toBe(1);

    // Second import with duplicates
    const payload2: ImportJobPayload = {
      entityType: 'lead',
      headers: parsed.headers,
      rows: parsed.rows, // All rows including duplicate
      fieldMapping: mapping,
      businessId: testBusinessId,
      duplicateHandling: 'skip',
      userId: testUserId,
      userRole: testUserRole,
      userBusinessId: testBusinessId,
    };

    const result2 = await runImport(mockDb as any, payload2);

    // Should skip duplicates
    expect(result2.skipped).toBeGreaterThan(0);
    expect(result2.imported).toBeLessThan(4);
  });

  // ============================================
  // Test 6: Missing Required Fields
  // ============================================

  it('rejects imports with missing required fields', async () => {
    const file = loadFixture('missing-required-fields.csv');
    const parsed = await parseCSV(file);

    const mapping = autoDetectMapping(parsed.headers, 'lead');
    const validationErrors = validateAllRows(parsed.rows, parsed.headers, 'lead', mapping);

    // Lead imports now require only firstName; email/lastName are optional.
    expect(validationErrors.length).toBeGreaterThan(0);
    expect(validationErrors.some(e => e.field === 'firstName')).toBe(true);

    const payload: ImportJobPayload = {
      entityType: 'lead',
      headers: parsed.headers,
      rows: parsed.rows,
      fieldMapping: mapping,
      businessId: testBusinessId,
      duplicateHandling: 'skip',
      userId: testUserId,
      userRole: testUserRole,
      userBusinessId: testBusinessId,
    };

    const result = await runImport(mockDb as any, payload);

    // Import should fail validation
    expect(result.imported).toBe(0);
    expect(result.skipped).toBe(parsed.rows.length);
    expect(result.errors).toBeDefined();
  });

  // ============================================
  // Test 7: RBAC Enforcement
  // ============================================

  it('blocks imports from unauthorized roles', async () => {
    const file = loadFixture('company-only.csv');
    const parsed = await parseCSV(file);
    const mapping = autoDetectMapping(parsed.headers, 'company');

    const payload: ImportJobPayload = {
      entityType: 'company',
      headers: parsed.headers,
      rows: parsed.rows,
      fieldMapping: mapping,
      businessId: testBusinessId,
      duplicateHandling: 'skip',
      userId: testUserId,
      userRole: 'client', // Not allowed to import
      userBusinessId: testBusinessId,
    };

    const result = await runImport(mockDb as any, payload);

    expect(result.imported).toBe(0);
    expect(result.skipped).toBe(parsed.rows.length);
    expect(result.errors).toBeDefined();
    expect(result.errors![0]).toContain('Access denied');
  });

  // ============================================
  // Test 8: Tenant Isolation
  // ============================================

  it('blocks cross-tenant imports', async () => {
    const file = loadFixture('company-only.csv');
    const parsed = await parseCSV(file);
    const mapping = autoDetectMapping(parsed.headers, 'company');

    const payload: ImportJobPayload = {
      entityType: 'company',
      headers: parsed.headers,
      rows: parsed.rows,
      fieldMapping: mapping,
      businessId: 'different-business-999',
      duplicateHandling: 'skip',
      userId: testUserId,
      userRole: testUserRole,
      userBusinessId: testBusinessId, // Mismatch
    };

    const result = await runImport(mockDb as any, payload);

    expect(result.imported).toBe(0);
    expect(result.skipped).toBe(parsed.rows.length);
    expect(result.errors).toBeDefined();
    expect(result.errors![0]).toContain('Security violation');
  });

  // ============================================
  // Test 9: Metrics/Logging (NO PHI)
  // ============================================

  it('logs metrics without PHI', async () => {
    const consoleSpy = vi.spyOn(console, 'log');

    const file = loadFixture('contact-only.csv');
    const parsed = await parseCSV(file);
    const mapping = autoDetectMapping(parsed.headers, 'contact');

    const payload: ImportJobPayload = {
      entityType: 'contact',
      headers: parsed.headers,
      rows: parsed.rows,
      fieldMapping: mapping,
      businessId: testBusinessId,
      duplicateHandling: 'skip',
      userId: testUserId,
      userRole: testUserRole,
      userBusinessId: testBusinessId,
    };

    await runImport(mockDb as any, payload);

    // Check that metrics were logged
    const metricsLogs = consoleSpy.mock.calls.filter(call => call[0] === '[IMPORT_METRICS]');
    expect(metricsLogs.length).toBeGreaterThan(0);

    // Verify NO PHI in logs
    const allLogs = consoleSpy.mock.calls.flatMap(call => JSON.stringify(call));
    expect(allLogs.some(log => log.includes('john.doe@example.com'))).toBe(false);
    expect(allLogs.some(log => log.includes('Jane'))).toBe(false);
    expect(allLogs.some(log => log.includes('555-1001'))).toBe(false);

    consoleSpy.mockRestore();
  });

  // ============================================
  // Test 10: Dry Run Mode
  // ============================================

  it('validates without writing in dry run mode', async () => {
    const file = loadFixture('company-only.csv');
    const parsed = await parseCSV(file);
    const mapping = autoDetectMapping(parsed.headers, 'company');

    const payload: ImportJobPayload = {
      entityType: 'company',
      headers: parsed.headers,
      rows: parsed.rows,
      fieldMapping: mapping,
      businessId: testBusinessId,
      duplicateHandling: 'skip',
      dryRun: true,
      userId: testUserId,
      userRole: testUserRole,
      userBusinessId: testBusinessId,
    };

    const result = await runImport(mockDb as any, payload);

    expect(result.imported).toBe(0);
    expect(result.skipped).toBe(3);
    expect(result.validationErrors).toHaveLength(0);

    // Verify NO writes to database
    const companies = mockDb.getAll(`businesses/${testBusinessId}/companies`);
    expect(companies).toHaveLength(0);
  });
});

// ============================================
// Test Available Fields Configuration
// ============================================

describe('CSV Import Field Configuration', () => {
  it('defines all entity types with correct required fields', () => {
    expect(AVAILABLE_FIELDS).toHaveProperty('lead');
    expect(AVAILABLE_FIELDS).toHaveProperty('contact');
    expect(AVAILABLE_FIELDS).toHaveProperty('deal');
    expect(AVAILABLE_FIELDS).toHaveProperty('company');
    expect(AVAILABLE_FIELDS).toHaveProperty('client');
    expect(AVAILABLE_FIELDS).toHaveProperty('appointment');

    // Lead required fields
    const leadFields = AVAILABLE_FIELDS.lead;
    const leadRequired = leadFields.filter(f => f.required).map(f => f.label);
    expect(leadRequired).toContain('firstName');
    expect(leadRequired).not.toContain('lastName');
    expect(leadRequired).not.toContain('email');

    // Deal required fields
    const dealFields = AVAILABLE_FIELDS.deal;
    const dealRequired = dealFields.filter(f => f.required).map(f => f.label);
    expect(dealRequired).toContain('title');

    // Company required fields
    const companyFields = AVAILABLE_FIELDS.company;
    const companyRequired = companyFields.filter(f => f.required).map(f => f.label);
    expect(companyRequired).toContain('name');
  });
});
