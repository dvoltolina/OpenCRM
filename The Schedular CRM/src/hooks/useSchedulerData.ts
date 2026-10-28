/**
 * useSchedulerData Hook
 * Fetches read-only data from The Scheduler collections
 *
 * Agent CRM-43 Implementation
 * Dependencies: CRM-17 (Detail views)
 */

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../context/AuthContext';
import {
  getClientAIInsights,
  getClientAppointments,
  getClientCommunications,
} from '../services/scheduler-integration-service';

// ============================================
// Types
// ============================================

export interface Appointment {
  id: string;
  clientId: string;
  providerId: string;
  providerName?: string;
  staffId?: string; // Added
  staffName?: string; // Added
  startTime: Date;
  endTime: Date;
  status: 'pending' | 'confirmed' | 'cancelled' | 'completed' | 'noShow' | 'scheduled' | 'missed';
  serviceType: string;
  notes?: string;
}

export interface AIInsights {
  clientId: string;
  riskScore: number; // 0-100, higher = more at risk
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

// ============================================
// Hook: useClientAppointments
// ============================================

export interface UseClientAppointmentsResult {
  /** List of appointments */
  appointments: Appointment[];
  /** Loading state */
  isLoading: boolean;
  /** Error if any */
  error: Error | null;
  /** Refresh appointments */
  refresh: () => void;
  /** Upcoming appointments */
  upcoming: Appointment[];
  /** Past appointments */
  past: Appointment[];
}

/**
 * Fetch appointments for a client from The Scheduler
 *
 * @param clientId - Client ID to fetch appointments for
 * @returns Appointments data and loading state
 *
 * @example
 * ```tsx
 * const { appointments, upcoming, past, isLoading } = useClientAppointments('client-123');
 * ```
 */
export function useClientAppointments(clientId: string | undefined): UseClientAppointmentsResult {
  const { businessId } = useAuth();
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const fetchAppointments = useCallback(async () => {
    if (!clientId || !businessId) {
      setAppointments([]);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const appts = await getClientAppointments(businessId, clientId, {
        limit: 50,
        orderDirection: 'desc',
      });
      setAppointments(appts);
    } catch (err) {
      // Gracefully handle missing collections or permissions
      if ((err as any).code === 'permission-denied' || (err as any).code === 'not-found') {
        setAppointments([]);
        setError(null); // Don't show error for missing data
      } else {
        setError(err instanceof Error ? err : new Error('Failed to fetch appointments'));
      }
    } finally {
      setIsLoading(false);
    }
  }, [clientId, businessId]);

  useEffect(() => {
    fetchAppointments();
  }, [fetchAppointments]);

  // Split into upcoming and past
  const now = new Date();
  const upcoming = appointments.filter((appt) => appt.startTime > now);
  const past = appointments.filter((appt) => appt.startTime <= now);

  return {
    appointments,
    isLoading,
    error,
    refresh: fetchAppointments,
    upcoming,
    past,
  };
}

// ============================================
// Hook: useClientAIInsights
// ============================================

export interface UseClientAIInsightsResult {
  /** AI insights data */
  insights: AIInsights | null;
  /** Loading state */
  isLoading: boolean;
  /** Error if any */
  error: Error | null;
  /** Refresh insights */
  refresh: () => void;
}

/**
 * Fetch AI insights for a client from The Scheduler
 *
 * @param clientId - Client ID to fetch insights for
 * @returns AI insights data and loading state
 *
 * @example
 * ```tsx
 * const { insights, isLoading } = useClientAIInsights('client-123');
 * ```
 */
export function useClientAIInsights(clientId: string | undefined): UseClientAIInsightsResult {
  const { businessId } = useAuth();
  const [insights, setInsights] = useState<AIInsights | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const fetchInsights = useCallback(async () => {
    if (!clientId || !businessId) {
      setInsights(null);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      setInsights(await getClientAIInsights(businessId, clientId));
    } catch (err) {
      // Gracefully handle missing collections or permissions
      if ((err as any).code === 'permission-denied' || (err as any).code === 'not-found') {
        setInsights(null);
        setError(null); // Don't show error for missing data
      } else {
        setError(err instanceof Error ? err : new Error('Failed to fetch AI insights'));
      }
    } finally {
      setIsLoading(false);
    }
  }, [clientId, businessId]);

  useEffect(() => {
    fetchInsights();
  }, [fetchInsights]);

  return {
    insights,
    isLoading,
    error,
    refresh: fetchInsights,
  };
}

// ============================================
// Hook: useClientCommunications
// ============================================

export interface UseClientCommunicationsResult {
  /** List of communication records */
  communications: CommunicationRecord[];
  /** Loading state */
  isLoading: boolean;
  /** Error if any */
  error: Error | null;
  /** Refresh communications */
  refresh: () => void;
  /** Email records only */
  emails: CommunicationRecord[];
  /** SMS records only */
  sms: CommunicationRecord[];
}

/**
 * Fetch communication history for a client from The Scheduler
 *
 * @param clientId - Client ID to fetch communications for
 * @returns Communication records and loading state
 *
 * @example
 * ```tsx
 * const { communications, emails, sms, isLoading } = useClientCommunications('client-123');
 * ```
 */
export function useClientCommunications(
  clientId: string | undefined
): UseClientCommunicationsResult {
  const { businessId } = useAuth();
  const [communications, setCommunications] = useState<CommunicationRecord[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const fetchCommunications = useCallback(async () => {
    if (!clientId || !businessId) {
      setCommunications([]);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      setCommunications(
        await getClientCommunications(businessId, clientId, { limit: 100 })
      );
    } catch (err) {
      // Gracefully handle missing collections or permissions
      if ((err as any).code === 'permission-denied' || (err as any).code === 'not-found') {
        setCommunications([]);
        setError(null); // Don't show error for missing data
      } else {
        setError(err instanceof Error ? err : new Error('Failed to fetch communications'));
      }
    } finally {
      setIsLoading(false);
    }
  }, [clientId, businessId]);

  useEffect(() => {
    fetchCommunications();
  }, [fetchCommunications]);

  // Filter by type
  const emails = communications.filter((comm) => comm.type === 'email');
  const sms = communications.filter((comm) => comm.type === 'sms');

  return {
    communications,
    isLoading,
    error,
    refresh: fetchCommunications,
    emails,
    sms,
  };
}
export default {
  useClientAppointments,
  useClientAIInsights,
  useClientCommunications,
};
