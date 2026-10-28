import { useCallback, useEffect, useState } from 'react';

import { listAppointments } from '../data/appointments';
import { listClients } from '../data/clients';
import { listPayments } from '../data/payments';
import type { Appointment, Client, Payment } from '../types/models';

export type LedgerEntry = Payment & {
  clientName?: string;
  clientEmail?: string;
  appointmentStart?: string;
  appointmentStatus?: Appointment['status'];
};

type LedgerState = {
  entries: LedgerEntry[];
  loading: boolean;
  error: string | null;
  refresh: () => void;
};

export function usePaymentsLedger(businessId?: string, userId?: string): LedgerState {
  const [entries, setEntries] = useState<LedgerEntry[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [refreshToken, setRefreshToken] = useState(0);

  const refresh = useCallback(() => {
    setRefreshToken((token) => token + 1);
  }, []);

  useEffect(() => {
    if (!businessId) {
      setEntries([]);
      setLoading(false);
      setError(null);
      return;
    }

    let cancelled = false;
    setLoading(true);
    setError(null);

    Promise.all([
      listPayments(businessId, {}, userId),
      listClients(businessId, userId),
      listAppointments(businessId, {}, userId),
    ])
      .then(([payments, clients, appointments]) => {
        if (cancelled) return;

        const clientMap = new Map<string, Client>();
        clients.forEach((client) => clientMap.set(client.id, client));

        const appointmentMap = new Map<string, Appointment>();
        appointments.forEach((appointment) => appointmentMap.set(appointment.id, appointment));

        const enhanced = payments
          .slice()
          .sort(
            (a, b) =>
              new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime(),
          )
          .map<LedgerEntry>((payment) => {
            const client = payment.clientId ? clientMap.get(payment.clientId) : undefined;
            const appointment = payment.appointmentId
              ? appointmentMap.get(payment.appointmentId)
              : undefined;

            return {
              ...payment,
              clientName: client?.name,
              clientEmail: client?.email,
              appointmentStart: appointment?.start,
              appointmentStatus: appointment?.status,
            };
          });

        setEntries(enhanced);
      })
      .catch((err) => {
        if (cancelled) return;
        console.error('Failed to load payments ledger', err);
        setError('Failed to load payments ledger.');
      })
      .finally(() => {
        if (!cancelled) {
          setLoading(false);
        }
      });

    return () => {
      cancelled = true;
    };
  }, [businessId, refreshToken, userId]);

  return { entries, loading, error, refresh };
}
