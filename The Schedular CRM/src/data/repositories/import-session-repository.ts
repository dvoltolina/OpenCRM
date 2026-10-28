import { doc, getDoc, setDoc, deleteDoc } from 'firebase/firestore';
import { businessPath } from '../../lib/collections';
import { getFirebaseDb } from '../../lib/firebase';
import type { ImportSessionState, ImportSessionStore } from '../../services/import-export-service';

const SESSION_TTL_MS = 24 * 60 * 60 * 1000;

export class ImportSessionRepository implements ImportSessionStore {
  private getDocRef(businessId: string, sessionId: string) {
    const db = getFirebaseDb();
    if (!db) {
      throw new Error('Firestore not initialized');
    }
    const basePath = `${businessPath(businessId)}/import_sessions`;
    return doc(db, basePath, sessionId);
  }

  async load(businessId: string, sessionId: string): Promise<ImportSessionState | null> {
    const ref = this.getDocRef(businessId, sessionId);
    const snap = await getDoc(ref);
    if (!snap.exists()) return null;
    const data = snap.data();
    const startedAt = data.startedAt?.toDate?.() ?? new Date();
    const expiresAt =
      data.expiresAt?.toDate?.() ??
      new Date(startedAt.getTime() + SESSION_TTL_MS);
    const errors = Array.isArray(data.errors)
      ? data.errors.map((err: any) => ({
          row: err?.row ?? 0,
          field: err?.field ?? 'unknown',
          error: err?.error ?? 'invalid',
        }))
      : [];
    return {
      businessId,
      createdBy: data.createdBy || 'unknown',
      createdByRole: data.createdByRole || 'unknown',
      entityType: data.entityType || 'lead',
      startedAt,
      expiresAt,
      processedRows: data.processedRows || 0,
      totalRows: data.totalRows || 0,
      errors,
      resumeToken: data.resumeToken || '',
      status: data.status || 'pending',
    };
  }

  async save(
    businessId: string,
    sessionId: string,
    state: ImportSessionState
  ): Promise<void> {
    const ref = this.getDocRef(businessId, sessionId);
    await setDoc(
      ref,
      {
        businessId,
        createdBy: state.createdBy,
        createdByRole: state.createdByRole,
        entityType: state.entityType,
        startedAt: state.startedAt,
        expiresAt: state.expiresAt,
        processedRows: state.processedRows,
        totalRows: state.totalRows,
        errors: state.errors,
        resumeToken: state.resumeToken,
        status: state.status,
        updatedAt: new Date(),
      },
      { merge: true }
    );
  }

  async delete(businessId: string, sessionId: string): Promise<void> {
    const ref = this.getDocRef(businessId, sessionId);
    await deleteDoc(ref);
  }
}

let importSessionStore: ImportSessionStore | null = null;

export function getImportSessionStore(): ImportSessionStore {
  if (!importSessionStore) {
    importSessionStore = new ImportSessionRepository();
  }
  return importSessionStore;
}
