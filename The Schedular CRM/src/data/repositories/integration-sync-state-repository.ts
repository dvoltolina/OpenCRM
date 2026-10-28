import { doc, getDoc, setDoc } from 'firebase/firestore';
import { getFirebaseDb } from '../../lib/firebase';
import { businessPath } from '../../lib/collections';
import type { IntegrationProvider } from '../../types/integrations';

export interface SyncStateRecord {
  integrationId: string;
  provider: IntegrationProvider;
  cursor?: string;
  lastSyncedAt: Date;
  lastStatus: 'success' | 'failed';
  backoffMs?: number;
  retried?: number;
}

export interface SyncStateStore {
  load: (
    businessId: string,
    integrationId: string,
    provider: IntegrationProvider
  ) => Promise<SyncStateRecord | null>;
  save: (businessId: string, state: SyncStateRecord) => Promise<void>;
}

export class IntegrationSyncStateRepository implements SyncStateStore {
  private getDocRef(businessId: string, integrationId: string, provider: IntegrationProvider) {
    const db = getFirebaseDb();
    if (!db) {
      throw new Error('Firestore not initialized');
    }
    const basePath = `${businessPath(businessId)}/integrations/${integrationId}/sync_state`;
    return doc(db, basePath, provider);
  }

  async load(
    businessId: string,
    integrationId: string,
    provider: IntegrationProvider
  ): Promise<SyncStateRecord | null> {
    const ref = this.getDocRef(businessId, integrationId, provider);
    const snap = await getDoc(ref);
    if (!snap.exists()) return null;
    const data = snap.data();
    return {
      integrationId,
      provider,
      cursor: typeof data.cursor === 'string' ? data.cursor : undefined,
      lastSyncedAt: data.lastSyncedAt?.toDate?.() ?? new Date(),
      lastStatus: data.lastStatus === 'failed' ? 'failed' : 'success',
      backoffMs: typeof data.backoffMs === 'number' ? data.backoffMs : undefined,
      retried: typeof data.retried === 'number' ? data.retried : undefined,
    };
  }

  async save(businessId: string, state: SyncStateRecord): Promise<void> {
    const ref = this.getDocRef(businessId, state.integrationId, state.provider);
    await setDoc(
      ref,
      {
        cursor: state.cursor ?? null,
        lastSyncedAt: state.lastSyncedAt,
        lastStatus: state.lastStatus,
        backoffMs: state.backoffMs ?? null,
        retried: state.retried ?? null,
        updatedAt: new Date(),
      },
      { merge: true }
    );
  }
}

let syncStateStore: SyncStateStore | null = null;

export function getSyncStateStore(): SyncStateStore {
  if (!syncStateStore) {
    syncStateStore = new IntegrationSyncStateRepository();
  }
  return syncStateStore;
}
