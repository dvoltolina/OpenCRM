/**
 * Scheduler Integration Service
 * READ-ONLY access to The Scheduler collections
 *
 * Agent CRM-43 Implementation
 *
 * IMPORTANT: This service provides READ-ONLY access to Scheduler data.
 * CRM NEVER writes to Scheduler collections (appointments, message_history, etc.)
 *
 * Shared Collections (Read-Only):
 * - appointments/{appointmentId}
 * - message_history/{messageId}
 * - clientRiskScores/{clientId}
 * - sentimentResults/{clientId}
 */

import {
  collection,
  doc,
  query,
  where,
  orderBy,
  limit,
  getDocs,
  getDoc,
  QueryConstraint,
  Timestamp,
} from 'firebase/firestore';
import { db } from '../lib/firebase';
import {
  appointmentsCollection,
  clientRiskScoreDoc,
  messageHistoryCollection,
  sentimentResultsCollection,
} from '../lib/collections';

// ============================================
// Types
// ============================================

export interface AppointmentRecord {
  id: string;
  clientId: string;
  providerId: string;
  providerName?: string;
  startTime: Date;
  endTime: Date;
  status: 'pending' | 'confirmed' | 'cancelled' | 'completed' | 'noShow' | 'scheduled' | 'missed';
  serviceType: string;
  notes?: string;
}

export interface AIInsightsRecord {
  clientId: string;
  riskScore: number; // 0-100
  sentiment: 'positive' | 'neutral' | 'negative';
  lastUpdated: Date;
  factors?: string[];
}

export interface CommunicationRecord {
  id: string;
  clientId: string;
  type: 'email' | 'sms';
  direction: 'inbound' | 'outbound';
  subject?: string;
  preview: string;
  sentAt: Date;
  status: 'sent' | 'delivered' | 'opened' | 'failed';
}

export interface SchedulerDataFilters {
  clientId?: string;
  limit?: number;
  orderBy?: 'startTime' | 'sentAt' | 'createdAt';
  orderDirection?: 'asc' | 'desc';
}

// ============================================
// Repository Functions
// ============================================

/**
 * Fetch appointments for a client
 * READ-ONLY - CRM never writes to appointments
 *
 * @param businessId - Business ID for tenant isolation
 * @param clientId - Client ID to fetch appointments for
 * @param options - Query options (limit, ordering)
 * @returns Array of appointment records
 *
 * @example
 * ```ts
 * const appointments = await getClientAppointments(businessId, clientId, { limit: 50 });
 * ```
 */
export async function getClientAppointments(
  businessId: string,
  clientId: string,
  options: { limit?: number; orderDirection?: 'asc' | 'desc' } = {}
): Promise<AppointmentRecord[]> {
  if (!db) {
    throw new Error('Firestore not initialized');
  }

  if (!businessId || !clientId) {
    return [];
  }

  try {
    const appointmentsRef = collection(db, appointmentsCollection(businessId));

    const constraints: QueryConstraint[] = [
      where('clientId', '==', clientId),
      orderBy('startTime', options.orderDirection || 'desc'),
    ];

    if (options.limit) {
      constraints.push(limit(options.limit));
    }

    const q = query(appointmentsRef, ...constraints);
    const snapshot = await getDocs(q);

    return snapshot.docs.map((docSnap) => {
      const data = docSnap.data();
      return {
        id: docSnap.id,
        clientId: data.clientId,
        providerId: data.providerId || data.staffId,
        providerName: data.providerName || data.staffName,
        startTime: convertToDate(data.startTime),
        endTime: convertToDate(data.endTime),
        status: normalizeAppointmentStatus(data.status),
        serviceType: data.serviceType || data.serviceName || 'Appointment',
        notes: data.notes,
      };
    });
  } catch (err) {
    // Gracefully handle missing collections or permissions
    if (isNotFoundOrPermissionError(err)) {
      return []; // Return empty array if collection doesn't exist
    }
    throw err; // Re-throw other errors
  }
}

/**
 * Fetch last appointment date for a client
 * Used for contact cards and quick context
 *
 * @param businessId - Business ID for tenant isolation
 * @param clientId - Client ID
 * @returns Date of last appointment or null
 *
 * @example
 * ```ts
 * const lastAppt = await getLastAppointmentDate(businessId, clientId);
 * if (lastAppt) {
 *   console.log('Last seen:', lastAppt.toLocaleDateString());
 * }
 * ```
 */
export async function getLastAppointmentDate(
  businessId: string,
  clientId: string
): Promise<Date | null> {
  const appointments = await getClientAppointments(businessId, clientId, {
    limit: 1,
    orderDirection: 'desc',
  });

  return appointments.length > 0 ? appointments[0].startTime : null;
}

/**
 * Fetch upcoming appointments for a client
 *
 * @param businessId - Business ID for tenant isolation
 * @param clientId - Client ID
 * @param options - Query options
 * @returns Array of upcoming appointments
 */
export async function getUpcomingAppointments(
  businessId: string,
  clientId: string,
  options: { limit?: number } = {}
): Promise<AppointmentRecord[]> {
  if (!db) {
    throw new Error('Firestore not initialized');
  }

  if (!businessId || !clientId) {
    return [];
  }

  try {
    const appointmentsRef = collection(db, appointmentsCollection(businessId));
    const now = Timestamp.now();

    const constraints: QueryConstraint[] = [
      where('clientId', '==', clientId),
      where('startTime', '>=', now),
      orderBy('startTime', 'asc'),
    ];

    if (options.limit) {
      constraints.push(limit(options.limit));
    }

    const q = query(appointmentsRef, ...constraints);
    const snapshot = await getDocs(q);

    return snapshot.docs.map((docSnap) => {
      const data = docSnap.data();
      return {
        id: docSnap.id,
        clientId: data.clientId,
        providerId: data.providerId || data.staffId,
        providerName: data.providerName || data.staffName,
        startTime: convertToDate(data.startTime),
        endTime: convertToDate(data.endTime),
        status: data.status || 'scheduled',
        serviceType: data.serviceType || data.serviceName || 'Appointment',
        notes: data.notes,
      };
    });
  } catch (err) {
    if (isNotFoundOrPermissionError(err)) {
      return [];
    }
    throw err;
  }
}

/**
 * Fetch AI insights for a client
 * READ-ONLY - Risk scores and sentiment from The Scheduler's AI
 *
 * @param businessId - Business ID for tenant isolation
 * @param clientId - Client ID
 * @returns AI insights or null if not available
 *
 * @example
 * ```ts
 * const insights = await getClientAIInsights(businessId, clientId);
 * if (insights && insights.riskScore > 60) {
 *   console.warn('High churn risk client!');
 * }
 * ```
 */
export async function getClientAIInsights(
  businessId: string,
  clientId: string
): Promise<AIInsightsRecord | null> {
  if (!db) {
    throw new Error('Firestore not initialized');
  }

  if (!businessId || !clientId) {
    return null;
  }

  try {
    // Try to fetch from risk scores collection
    const riskScoreRef = doc(db, clientRiskScoreDoc(businessId, clientId));
    const riskScoreSnap = await getDoc(riskScoreRef);

    // Try to fetch from sentiment results collection by clientId
    const sentimentQuery = query(
      collection(db, sentimentResultsCollection(businessId)),
      where('clientId', '==', clientId),
      limit(1),
    );
    const sentimentSnap = await getDocs(sentimentQuery);
    const sentimentData = sentimentSnap.docs[0]?.data();

    if (!riskScoreSnap.exists() && !sentimentData) {
      return null;
    }

    const riskData = riskScoreSnap.data();

    return {
      clientId,
      riskScore: riskData?.riskScore ?? riskData?.score ?? 0,
      sentiment: sentimentData?.sentiment ?? 'neutral',
      lastUpdated: convertToDate(riskData?.updatedAt || sentimentData?.updatedAt),
      factors: riskData?.factors || riskData?.riskFactors || [],
    };
  } catch (err) {
    if (isNotFoundOrPermissionError(err)) {
      return null;
    }
    throw err;
  }
}

/**
 * Fetch communication history for a client
 * READ-ONLY - Email/SMS history metadata (no message content)
 *
 * @param businessId - Business ID for tenant isolation
 * @param clientId - Client ID
 * @param options - Query options
 * @returns Array of communication records (metadata only)
 *
 * @example
 * ```ts
 * const comms = await getClientCommunications(businessId, clientId, { limit: 100 });
 * console.log(`Found ${comms.length} communications`);
 * ```
 */
export async function getClientCommunications(
  businessId: string,
  clientId: string,
  options: { limit?: number } = {}
): Promise<CommunicationRecord[]> {
  if (!db) {
    throw new Error('Firestore not initialized');
  }

  if (!businessId || !clientId) {
    return [];
  }

  try {
    const messagesRef = collection(db, messageHistoryCollection(businessId));

    const constraints: QueryConstraint[] = [
      where('clientId', '==', clientId),
      orderBy('sentAt', 'desc'),
    ];

    if (options.limit) {
      constraints.push(limit(options.limit));
    }

    const q = query(messagesRef, ...constraints);
    const snapshot = await getDocs(q);

    return snapshot.docs.map((docSnap) => {
      const data = docSnap.data();
      return {
        id: docSnap.id,
        clientId: data.clientId,
        type: data.type || (data.messageType === 'email' ? 'email' : 'sms'),
        direction: data.direction || 'outbound',
        subject: data.subject,
        preview: data.preview || data.body?.substring(0, 100) || data.message?.substring(0, 100) || '',
        sentAt: convertToDate(data.sentAt),
        status: data.status || 'sent',
      };
    });
  } catch (err) {
    if (isNotFoundOrPermissionError(err)) {
      return [];
    }
    throw err;
  }
}

/**
 * Get last contact date from communications
 *
 * @param businessId - Business ID
 * @param clientId - Client ID
 * @returns Date of last communication or null
 */
export async function getLastCommunicationDate(
  businessId: string,
  clientId: string
): Promise<Date | null> {
  const comms = await getClientCommunications(businessId, clientId, { limit: 1 });
  return comms.length > 0 ? comms[0].sentAt : null;
}

// ============================================
// Helper Functions
// ============================================

function normalizeAppointmentStatus(raw: any): AppointmentRecord['status'] {
  const value = typeof raw === 'string' ? raw : '';
  switch (value) {
    case 'confirmed':
      return 'confirmed';
    case 'cancelled':
      return 'cancelled';
    case 'completed':
      return 'completed';
    case 'noShow':
    case 'no_show':
      return 'noShow';
    case 'missed':
      return 'missed';
    case 'pending':
    case 'scheduled':
    default:
      return value === 'scheduled' ? 'scheduled' : 'pending';
  }
}

/**
 * Convert Firestore Timestamp to Date
 * Handles both Timestamp objects and Date objects
 */
function convertToDate(value: any): Date {
  if (!value) return new Date();
  if (value instanceof Date) return value;
  if (value.toDate && typeof value.toDate === 'function') {
    return value.toDate();
  }
  return new Date(value);
}

/**
 * Check if error is permission-denied or not-found
 * Used for graceful degradation when Scheduler data is missing
 */
function isNotFoundOrPermissionError(err: any): boolean {
  const code = err?.code || '';
  return code === 'permission-denied' || code === 'not-found';
}

// ============================================
// Exports
// ============================================

export default {
  getClientAppointments,
  getLastAppointmentDate,
  getUpcomingAppointments,
  getClientAIInsights,
  getClientCommunications,
  getLastCommunicationDate,
};
