import { describe, it, expect, beforeEach, vi } from 'vitest';
import { runImport } from '../importer';

// Minimal in-memory Firestore stub for importer unit tests
class FakeCollection {
  private records: Map<string, any>;

  constructor(records?: Map<string, any>) {
    this.records = records ?? new Map();
  }

  seed(docs: Array<{ id?: string; [key: string]: any }>) {
    docs.forEach((doc) => {
      const id = doc.id || `doc_${Math.random().toString(36).slice(2, 8)}`;
      this.records.set(id, { ...doc, id });
    });
  }

  where(field: string, _op: FirebaseFirestore.WhereFilterOp, value: any) {
    const filtered = new Map(
      Array.from(this.records.entries()).filter(([, data]) => data[field] === value)
    );
    return new FakeQuery(filtered);
  }

  limit(n: number) {
    return new FakeQuery(this.records).limit(n);
  }

  async get() {
    return new FakeQuery(this.records).get();
  }

  doc(id?: string) {
    const docId = id || `doc_${Math.random().toString(36).slice(2, 8)}`;
    return {
      id: docId,
      set: async (data: any, options?: FirebaseFirestore.SetOptions) => {
        const existing = this.records.get(docId) || { id: docId };
        const next =
          options && "merge" in options && options.merge
            ? { ...existing, ...data }
            : { ...data, id: docId };
        this.records.set(docId, next);
      },
    };
  }

  async add(data: any) {
    const ref = this.doc();
    await ref.set(data);
    return { id: ref.id };
  }

  getAll(): any[] {
    return Array.from(this.records.values());
  }
}

class FakeQuery {
  private filtered: Map<string, any>;
  private limitCount = Infinity;

  constructor(filtered: Map<string, any>) {
    this.filtered = filtered;
  }

  limit(n: number) {
    this.limitCount = n;
    return this;
  }

  async get() {
    const docs = Array.from(this.filtered.entries())
      .slice(0, this.limitCount)
      .map(([id, data]) => ({
        id,
        data: () => data,
      }));
    return { docs };
  }
}

class FakeDocument {
  constructor(private id: string, private collections: Map<string, FakeCollection>) {}

  collection(name: string) {
    const key = `${this.id}/${name}`;
    if (!this.collections.has(key)) {
      this.collections.set(key, new FakeCollection());
    }
    return this.collections.get(key)!;
  }
}

class FakeFirestore {
  private collections = new Map<string, FakeCollection>();
  private documents = new Map<string, Map<string, FakeCollection>>();

  private getOrCreateRootCollection(name: string): FakeCollection {
    if (!this.collections.has(name)) {
      this.collections.set(name, new FakeCollection());
    }
    return this.collections.get(name)!;
  }

  private getOrCreateBusinessCollections(businessId: string): Map<string, FakeCollection> {
    if (!this.documents.has(businessId)) {
      this.documents.set(businessId, new Map());
    }
    return this.documents.get(businessId)!;
  }

  collection(name: string) {
    // Support nested collections for businesses/{businessId}/collection pattern
    if (name === 'businesses') {
      return {
        doc: (id: string) => {
          if (!this.documents.has(id)) {
            this.documents.set(id, new Map());
          }
          return new FakeDocument(id, this.documents.get(id)!);
        },
      };
    }

    return this.getOrCreateRootCollection(name);
  }

  seed(name: string, docs: Array<{ id?: string; [key: string]: any }>, businessId?: string) {
    if (businessId) {
      const businessDoc = new FakeDocument(businessId, this.getOrCreateBusinessCollections(businessId));
      businessDoc.collection(name).seed(docs);
      return;
    }

    const groupedByBusiness = new Map<string, Array<{ id?: string; [key: string]: any }>>();
    const rootDocs: Array<{ id?: string; [key: string]: any }> = [];

    docs.forEach((doc) => {
      if (typeof doc.businessId === 'string' && doc.businessId) {
        if (!groupedByBusiness.has(doc.businessId)) {
          groupedByBusiness.set(doc.businessId, []);
        }
        groupedByBusiness.get(doc.businessId)!.push(doc);
      } else {
        rootDocs.push(doc);
      }
    });

    rootDocs.length && this.getOrCreateRootCollection(name).seed(rootDocs);

    groupedByBusiness.forEach((businessDocs, groupedBusinessId) => {
      const businessDoc = new FakeDocument(
        groupedBusinessId,
        this.getOrCreateBusinessCollections(groupedBusinessId)
      );
      businessDoc.collection(name).seed(businessDocs);
    });
  }

  getCollectionData(name: string, businessId?: string) {
    // Support nested collections: businesses/{businessId}/collectionName
    if (businessId) {
      const businessDoc = this.documents.get(businessId);
      if (businessDoc) {
        const nestedCollection = businessDoc.get(`${businessId}/${name}`);
        return nestedCollection ? nestedCollection.getAll() : [];
      }
      return [];
    }
    return this.getOrCreateRootCollection(name).getAll();
  }
}

// Mock only the FieldValue used by importer
vi.mock('firebase-admin', () => ({
  firestore: {
    FieldValue: {
      serverTimestamp: () => 'ts',
    },
  },
}));

describe('runImport', () => {
  let db: FakeFirestore;

  beforeEach(() => {
    db = new FakeFirestore();
  });

  it('imports new leads and creates documents', async () => {
    const result = await runImport(db as any, {
      entityType: 'lead',
      headers: ['first', 'last', 'email'],
      rows: [['Jane', 'Doe', 'jane@example.com']],
      fieldMapping: { first: 'firstName', last: 'lastName', email: 'email' },
      businessId: 'biz1',
      duplicateHandling: 'skip',
      userId: 'user-basic-1',
      userRole: 'admin',
      userBusinessId: 'biz1',
    });

    expect(result.validationErrors).toHaveLength(0);
    expect(result.imported).toBe(1);
    expect(result.skipped).toBe(0);

    const stored = db.getCollectionData('leads', 'biz1');
    expect(stored).toHaveLength(1);
    expect(stored[0].email).toBe('jane@example.com');
    expect(stored[0].businessId).toBe('biz1');
  });

  it('updates existing duplicates when configured', async () => {
    db.seed('leads', [
      { id: 'lead1', email: 'dup@example.com', phone: '111', businessId: 'biz1' },
    ]);

    const result = await runImport(db as any, {
      entityType: 'lead',
      headers: ['first', 'last', 'email', 'phone'],
      rows: [['Dup', 'User', 'dup@example.com', '(999) 999-9999']],
      fieldMapping: {
        first: 'firstName',
        last: 'lastName',
        email: 'email',
        phone: 'phone',
      },
      businessId: 'biz1',
      duplicateHandling: 'update',
      userId: 'user-basic-2',
      userRole: 'admin',
      userBusinessId: 'biz1',
    });

    expect(result.validationErrors).toHaveLength(0);
    expect(result.imported).toBe(1);
    expect(result.skipped).toBe(0);

    const stored = db.getCollectionData('leads', 'biz1');
    expect(stored).toHaveLength(1);
    expect(stored[0].phone).toBe('9999999999'); // normalized phone
    expect(stored[0].firstName).toBe('Dup');
  });

  it('returns validation errors and skips when required fields are missing', async () => {
    const result = await runImport(db as any, {
      entityType: 'lead',
      headers: ['email'],
      rows: [['missing-names@example.com']],
      fieldMapping: { email: 'email' },
      businessId: 'biz1',
      duplicateHandling: 'skip',
      userId: 'user-basic-3',
      userRole: 'admin',
      userBusinessId: 'biz1',
    });

    expect(result.imported).toBe(0);
    expect(result.skipped).toBe(1);
    expect(result.validationErrors.length).toBeGreaterThan(0);
    expect(result.errors?.[0]).toMatch(/Validation required/i);
  });

  // ============================================
  // RBAC & Security Tests (Agent M4)
  // ============================================

  describe('RBAC - Role Validation', () => {
    it('allows import for owner role', async () => {
      const result = await runImport(db as any, {
        entityType: 'lead',
        headers: ['first', 'last', 'email'],
        rows: [['Test', 'Owner', 'owner@example.com']],
        fieldMapping: { first: 'firstName', last: 'lastName', email: 'email' },
        businessId: 'biz1',
        duplicateHandling: 'skip',
        userId: 'user1',
        userRole: 'owner',
        userBusinessId: 'biz1',
      });

      expect(result.errors).toBeUndefined();
      expect(result.imported).toBe(1);
      expect(result.skipped).toBe(0);
    });

    it('allows import for admin role', async () => {
      const result = await runImport(db as any, {
        entityType: 'lead',
        headers: ['first', 'last', 'email'],
        rows: [['Test', 'Admin', 'admin@example.com']],
        fieldMapping: { first: 'firstName', last: 'lastName', email: 'email' },
        businessId: 'biz1',
        duplicateHandling: 'skip',
        userId: 'user2',
        userRole: 'admin',
        userBusinessId: 'biz1',
      });

      expect(result.errors).toBeUndefined();
      expect(result.imported).toBe(1);
      expect(result.skipped).toBe(0);
    });

    it('allows import for manager role', async () => {
      const result = await runImport(db as any, {
        entityType: 'lead',
        headers: ['first', 'last', 'email'],
        rows: [['Test', 'Manager', 'manager@example.com']],
        fieldMapping: { first: 'firstName', last: 'lastName', email: 'email' },
        businessId: 'biz1',
        duplicateHandling: 'skip',
        userId: 'user3',
        userRole: 'manager',
        userBusinessId: 'biz1',
      });

      expect(result.errors).toBeUndefined();
      expect(result.imported).toBe(1);
      expect(result.skipped).toBe(0);
    });

    it('allows import for sales role', async () => {
      const result = await runImport(db as any, {
        entityType: 'lead',
        headers: ['first', 'last', 'email'],
        rows: [['Test', 'Sales', 'sales@example.com']],
        fieldMapping: { first: 'firstName', last: 'lastName', email: 'email' },
        businessId: 'biz1',
        duplicateHandling: 'skip',
        userId: 'user4',
        userRole: 'sales',
        userBusinessId: 'biz1',
      });

      expect(result.errors).toBeUndefined();
      expect(result.imported).toBe(1);
      expect(result.skipped).toBe(0);
    });

    it('allows import for staff role', async () => {
      const result = await runImport(db as any, {
        entityType: 'lead',
        headers: ['first', 'last', 'email'],
        rows: [['Test', 'Staff', 'staff@example.com']],
        fieldMapping: { first: 'firstName', last: 'lastName', email: 'email' },
        businessId: 'biz1',
        duplicateHandling: 'skip',
        userId: 'user5',
        userRole: 'staff',
        userBusinessId: 'biz1',
      });

      expect(result.errors).toBeUndefined();
      expect(result.imported).toBe(1);
      expect(result.skipped).toBe(0);
    });

    it('denies import for client role', async () => {
      const result = await runImport(db as any, {
        entityType: 'lead',
        headers: ['first', 'last', 'email'],
        rows: [['Test', 'Client', 'client@example.com']],
        fieldMapping: { first: 'firstName', last: 'lastName', email: 'email' },
        businessId: 'biz1',
        duplicateHandling: 'skip',
        userId: 'user6',
        userRole: 'client',
        userBusinessId: 'biz1',
      });

      expect(result.imported).toBe(0);
      expect(result.skipped).toBe(1);
      expect(result.errors).toBeDefined();
      expect(result.errors![0]).toMatch(/Access denied/i);
      expect(result.errors![0]).toMatch(/client/i);
    });

    it('denies import for viewer role', async () => {
      const result = await runImport(db as any, {
        entityType: 'lead',
        headers: ['first', 'last', 'email'],
        rows: [['Test', 'Viewer', 'viewer@example.com']],
        fieldMapping: { first: 'firstName', last: 'lastName', email: 'email' },
        businessId: 'biz1',
        duplicateHandling: 'skip',
        userId: 'user7',
        userRole: 'viewer',
        userBusinessId: 'biz1',
      });

      expect(result.imported).toBe(0);
      expect(result.skipped).toBe(1);
      expect(result.errors).toBeDefined();
      expect(result.errors![0]).toMatch(/Access denied/i);
    });

    it('denies import for front desk role', async () => {
      const result = await runImport(db as any, {
        entityType: 'lead',
        headers: ['first', 'last', 'email'],
        rows: [['Test', 'FrontDesk', 'frontdesk@example.com']],
        fieldMapping: { first: 'firstName', last: 'lastName', email: 'email' },
        businessId: 'biz1',
        duplicateHandling: 'skip',
        userId: 'user8',
        userRole: 'frontDesk',
        userBusinessId: 'biz1',
      });

      expect(result.imported).toBe(0);
      expect(result.skipped).toBe(1);
      expect(result.errors).toBeDefined();
      expect(result.errors![0]).toMatch(/Access denied/i);
    });

    it('denies import when no role is provided', async () => {
      const result = await runImport(db as any, {
        entityType: 'lead',
        headers: ['first', 'last', 'email'],
        rows: [['Test', 'NoRole', 'norole@example.com']],
        fieldMapping: { first: 'firstName', last: 'lastName', email: 'email' },
        businessId: 'biz1',
        duplicateHandling: 'skip',
        userId: 'user9',
        userRole: '',
        userBusinessId: 'biz1',
      });

      expect(result.imported).toBe(0);
      expect(result.skipped).toBe(1);
      expect(result.errors).toBeDefined();
      expect(result.errors![0]).toMatch(/Access denied/i);
      expect(result.errors![0]).toMatch(/No role specified/i);
    });

    it('denies import for unknown role', async () => {
      const result = await runImport(db as any, {
        entityType: 'lead',
        headers: ['first', 'last', 'email'],
        rows: [['Test', 'Unknown', 'unknown@example.com']],
        fieldMapping: { first: 'firstName', last: 'lastName', email: 'email' },
        businessId: 'biz1',
        duplicateHandling: 'skip',
        userId: 'user10',
        userRole: 'hacker',
        userBusinessId: 'biz1',
      });

      expect(result.imported).toBe(0);
      expect(result.skipped).toBe(1);
      expect(result.errors).toBeDefined();
      expect(result.errors![0]).toMatch(/Access denied/i);
    });
  });

  describe('Multi-Tenant Isolation', () => {
    it('prevents cross-tenant import when businessId mismatch', async () => {
      const result = await runImport(db as any, {
        entityType: 'lead',
        headers: ['first', 'last', 'email'],
        rows: [['Cross', 'Tenant', 'cross@example.com']],
        fieldMapping: { first: 'firstName', last: 'lastName', email: 'email' },
        businessId: 'biz1',
        duplicateHandling: 'skip',
        userId: 'user11',
        userRole: 'admin',
        userBusinessId: 'biz2', // Different business!
      });

      expect(result.imported).toBe(0);
      expect(result.skipped).toBe(1);
      expect(result.errors).toBeDefined();
      expect(result.errors![0]).toMatch(/Security violation/i);
      expect(result.errors![0]).toMatch(/cross-tenant/i);
    });

    it('prevents import when businessId is missing', async () => {
      const result = await runImport(db as any, {
        entityType: 'lead',
        headers: ['first', 'last', 'email'],
        rows: [['No', 'Business', 'nobiz@example.com']],
        fieldMapping: { first: 'firstName', last: 'lastName', email: 'email' },
        businessId: '', // Empty businessId!
        duplicateHandling: 'skip',
        userId: 'user12',
        userRole: 'admin',
        userBusinessId: 'biz1',
      });

      expect(result.imported).toBe(0);
      expect(result.skipped).toBe(1);
      expect(result.errors).toBeDefined();
      expect(result.errors![0]).toMatch(/Security violation/i);
      expect(result.errors![0]).toMatch(/No businessId/i);
    });

    it('allows import when businessId matches', async () => {
      const result = await runImport(db as any, {
        entityType: 'lead',
        headers: ['first', 'last', 'email'],
        rows: [['Valid', 'Tenant', 'valid@example.com']],
        fieldMapping: { first: 'firstName', last: 'lastName', email: 'email' },
        businessId: 'biz1',
        duplicateHandling: 'skip',
        userId: 'user13',
        userRole: 'admin',
        userBusinessId: 'biz1',
      });

      expect(result.errors).toBeUndefined();
      expect(result.imported).toBe(1);
      expect(result.skipped).toBe(0);
    });
  });

  describe('Deal validation', () => {
    it('allows deal imports without valueCents when a contact anchor is provided', async () => {
      const result = await runImport(db as any, {
        entityType: 'deal',
        headers: ['title', 'clientEmail'],
        rows: [['Follow-up Opportunity', 'buyer@example.com']],
        fieldMapping: {
          title: 'title',
          clientEmail: 'clientEmail',
        },
        businessId: 'biz1',
        duplicateHandling: 'skip',
        userId: 'user16',
        userRole: 'admin',
        userBusinessId: 'biz1',
      });

      expect(result.errors).toBeUndefined();
      expect(result.validationErrors).toHaveLength(0);
      expect(result.imported).toBe(1);
    });

    it('rejects deal imports that have no contact or company anchor', async () => {
      const result = await runImport(db as any, {
        entityType: 'deal',
        headers: ['title'],
        rows: [['Unlinked Opportunity']],
        fieldMapping: {
          title: 'title',
        },
        businessId: 'biz1',
        duplicateHandling: 'skip',
        userId: 'user17',
        userRole: 'admin',
        userBusinessId: 'biz1',
      });

      expect(result.imported).toBe(0);
      expect(result.validationErrors.some((error) => error.field === 'clientEmail')).toBe(true);
      expect(result.errors?.[0]).toContain('Validation required before import');
    });

  });

  describe('Audit Logging', () => {
    it('creates audit log entry after successful import', async () => {
      const result = await runImport(db as any, {
        entityType: 'lead',
        headers: ['first', 'last', 'email'],
        rows: [['Audit', 'Test', 'audit@example.com']],
        fieldMapping: { first: 'firstName', last: 'lastName', email: 'email' },
        businessId: 'biz1',
        duplicateHandling: 'skip',
        userId: 'user14',
        userRole: 'admin',
        userBusinessId: 'biz1',
      });

      expect(result.imported).toBe(1);

      // Check audit log was created (nested under businesses/biz1/auditLogs)
      const auditLogs = db.getCollectionData('auditLogs', 'biz1');
      expect(auditLogs.length).toBeGreaterThan(0);

      const lastAudit = auditLogs[auditLogs.length - 1];
      expect(lastAudit.action).toBe('import');
      expect(lastAudit.businessId).toBe('biz1');
      expect(lastAudit.userId).toBe('user14');
      expect(lastAudit.entityType).toBe('lead');
      expect(lastAudit.metadata.imported).toBe(1);
      expect(lastAudit.metadata.totalRows).toBe(1);

      // CRITICAL: Verify NO PHI in audit log
      expect(lastAudit.metadata.email).toBeUndefined();
      expect(lastAudit.metadata.firstName).toBeUndefined();
      expect(lastAudit.metadata.lastName).toBeUndefined();
      expect(lastAudit.metadata.phone).toBeUndefined();
      expect(lastAudit.metadata.name).toBeUndefined();
    });

    it('does not include PHI in audit logs', async () => {
      await runImport(db as any, {
        entityType: 'lead',
        headers: ['first', 'last', 'email', 'phone'],
        rows: [['PHI', 'Test', 'phi@example.com', '1234567890']],
        fieldMapping: {
          first: 'firstName',
          last: 'lastName',
          email: 'email',
          phone: 'phone',
        },
        businessId: 'biz1',
        duplicateHandling: 'skip',
        userId: 'user15',
        userRole: 'admin',
        userBusinessId: 'biz1',
      });

      const auditLogs = db.getCollectionData('auditLogs', 'biz1');
      const lastAudit = auditLogs[auditLogs.length - 1];

      // Verify metadata does not contain PHI fields
      expect(lastAudit.metadata.email).toBeUndefined();
      expect(lastAudit.metadata.phone).toBeUndefined();
      expect(lastAudit.metadata.firstName).toBeUndefined();
      expect(lastAudit.metadata.lastName).toBeUndefined();
      expect(lastAudit.metadata.address).toBeUndefined();
      expect(lastAudit.metadata.notes).toBeUndefined();
    });
  });
});
