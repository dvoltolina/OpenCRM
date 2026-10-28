import { doc, setDoc, collection, addDoc, getDocs, Timestamp, getDoc } from 'firebase/firestore';
import { getFirebaseDb } from '../../lib/firebase';
import { businessPath } from '../../lib/collections';
import type { DeadLetterEvent } from '../../types/integrations';

export interface WebhookInboundRecord {
  id: string;
  type: string;
  payloadHash: string;
  occurredAt: Date;
  receivedAt: Date;
}

export interface WebhookPersistence {
  hasInbound: (businessId: string, id: string) => Promise<boolean>;
  recordInbound: (
    businessId: string,
    record: WebhookInboundRecord
  ) => Promise<void>;
  recordDeadLetter: (
    businessId: string,
    deadLetter: Omit<DeadLetterEvent, 'id' | 'lastAttemptAt'>
  ) => Promise<string>;
  listDeadLetters: (businessId: string) => Promise<DeadLetterEvent[]>;
}

export class WebhookRepository implements WebhookPersistence {
  private getDb() {
    const db = getFirebaseDb();
    if (!db) {
      throw new Error('Firestore not initialized');
    }
    return db;
  }

  private inboundPath(businessId: string) {
    return `${businessPath(businessId)}/lead_intake_events`;
  }

  private deadLetterPath(businessId: string) {
    return `${businessPath(businessId)}/webhook_dead_letters`;
  }

  async hasInbound(businessId: string, id: string): Promise<boolean> {
    const db = this.getDb();
    const ref = doc(db, this.inboundPath(businessId), id);
    const snap = await getDoc(ref);
    return snap.exists();
  }

  async recordInbound(businessId: string, record: WebhookInboundRecord): Promise<void> {
    const db = this.getDb();
    const ref = doc(db, this.inboundPath(businessId), record.id);
    await setDoc(
      ref,
      {
        type: record.type,
        payloadHash: record.payloadHash,
        occurredAt: record.occurredAt,
        receivedAt: record.receivedAt,
        createdAt: new Date(),
      },
      { merge: true }
    );
  }

  async recordDeadLetter(
    businessId: string,
    deadLetter: Omit<DeadLetterEvent, 'id' | 'lastAttemptAt'>
  ): Promise<string> {
    const db = this.getDb();
    const ref = await addDoc(collection(db, this.deadLetterPath(businessId)), {
      businessId,
      destination: deadLetter.destination,
      reason: deadLetter.reason,
      attempts: deadLetter.attempts,
      payloadHash: deadLetter.payloadHash,
      status: deadLetter.status,
      createdAt: new Date(),
      lastAttemptAt: Timestamp.now(),
    });
    return ref.id;
  }

  async listDeadLetters(businessId: string): Promise<DeadLetterEvent[]> {
    const db = this.getDb();
    const snap = await getDocs(collection(db, this.deadLetterPath(businessId)));
    return snap.docs.map((docSnap) => {
      const data = docSnap.data();
      return {
        id: docSnap.id,
        businessId: data.businessId || businessId,
        destination: data.destination,
        reason: data.reason,
        attempts: data.attempts,
        payloadHash: data.payloadHash,
        status: data.status || 'failed',
        lastAttemptAt: data.lastAttemptAt?.toDate?.() ?? new Date(),
      } as DeadLetterEvent;
    });
  }
}

let webhookRepo: WebhookPersistence | null = null;

export function getWebhookPersistence(): WebhookPersistence {
  if (!webhookRepo) {
    webhookRepo = new WebhookRepository();
  }
  return webhookRepo;
}
