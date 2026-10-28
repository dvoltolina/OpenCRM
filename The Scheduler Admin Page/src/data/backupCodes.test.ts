import { describe, expect, it, vi, beforeEach } from 'vitest';

import { generateBackupCodes, saveBackupCodes, verifyBackupCode } from './backupCodes';

// In-memory Firestore mocks
type DocRef = { path: string };
type CollectionRef = { path: string };
const store = new Map<string, any>();

vi.mock('../lib/firebase', () => ({
  getDb: () => ({}),
}));

vi.mock('firebase/firestore', () => {
  const Timestamp = {
    now: () => ({ seconds: Math.floor(Date.now() / 1000), nanoseconds: 0 }),
  };

  const doc = (first: any, ...rest: string[]): DocRef => {
    if (first && typeof first === 'object' && 'path' in first && rest.length === 0) {
      const id = Math.random().toString(36).slice(2);
      return { path: `${(first as any).path}/${id}` };
    }
    const segments = [first, ...rest].filter(Boolean) as string[];
    return { path: segments.join('/') };
  };
  const collection = (first: any, ...rest: string[]): CollectionRef => {
    const segments =
      typeof first === 'string'
        ? [first, ...rest]
        : rest; // ignore db arg when provided
    return { path: segments.join('/') };
  };

  const writeBatch = () => ({
    set: (ref: DocRef, data: any) => {
      store.set(ref.path, { ...(store.get(ref.path) ?? {}), ...data });
    },
    delete: (ref: DocRef) => store.delete(ref.path),
    commit: async () => Promise.resolve(),
  });

  const setDoc = async (ref: DocRef, data: any, options?: { merge?: boolean }) => {
    if (options?.merge && store.has(ref.path)) {
      store.set(ref.path, { ...store.get(ref.path), ...data });
    } else {
      store.set(ref.path, data);
    }
  };

  const getDocs = async (refOrQuery: any) => {
    const targetPath = refOrQuery.path ?? refOrQuery.collectionRef?.path;
    const filters = refOrQuery.filters ?? [];
    const entries = Array.from(store.entries()).filter(([path]) => path.startsWith(targetPath));
    const docs = entries
      .map(([path, data]) => ({ id: path.split('/').pop(), ref: { path }, data: () => data }))
      .filter((docSnap) =>
        filters.every((f: any) => {
          const value = docSnap.data()[f.fieldPath];
          return f.opStr === '==' ? value === f.value : true;
        }),
      );
    return {
      empty: docs.length === 0,
      docs,
      forEach: (fn: (docSnap: any) => void) => docs.forEach(fn),
    };
  };

  const where = (fieldPath: string, opStr: '==', value: any) => ({ fieldPath, opStr, value });
  const query = (collectionRef: CollectionRef, ...filters: any[]) => ({
    collectionRef,
    filters,
    path: collectionRef.path,
  });

  return {
    doc,
    collection,
    getDocs,
    setDoc,
    writeBatch,
    Timestamp,
    where,
    query,
  };
});

// Deterministic crypto mock for SHA-256
beforeEach(() => {
  store.clear();
  const subtle = {
    digest: vi.fn(async (_algo: string, data: ArrayBuffer) => {
      const bytes = Array.from(new Uint8Array(data));
      const hash = new Uint8Array(32);
      bytes.forEach((byte, idx) => {
        hash[idx % 32] = (hash[idx % 32] + byte + idx) % 256;
      });
      return hash.buffer;
    }),
  };
  vi.stubGlobal('crypto', { subtle });
});

describe('backupCodes', () => {
  it('generates unique codes with expected format', () => {
    const codes = generateBackupCodes(10);
    const unique = new Set(codes);
    expect(codes).toHaveLength(10);
    expect(unique.size).toBe(10);
    expect(codes[0]).toMatch(/^[A-Z0-9]{2,6}-[A-Z0-9]{2,6}-[A-Z0-9]{2,6}$/);
  });

  it('saves hashed codes and marks used on verification', async () => {
    const businessId = 'biz-123';
    const userId = 'user-abc';
    const codes = ['TEST-CODE-ONE', 'TEST-CODE-TWO'];

    await saveBackupCodes(businessId, userId, codes);

    // Stored in Firestore mock with hashed codes
    const stored = Array.from(store.entries()).filter(([path]) =>
      path.startsWith(`users/${userId}/mfaBackupCodes`),
    );
    expect(stored).toHaveLength(codes.length);
    stored.forEach(([, data]) => {
      expect(data.codeHash).toBeDefined();
      expect(data.usedAt).toBeNull();
    });

    const firstResult = await verifyBackupCode(businessId, userId, codes[0]);
    expect(firstResult).toBe(true);
    const secondResult = await verifyBackupCode(businessId, userId, codes[0]);
    expect(secondResult).toBe(false);
  });
});
