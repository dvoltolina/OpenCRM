/**
 * usePayments Hook
 * React hooks for payment processing and history
 *
 * Agent CRM-29 Implementation
 * Dependencies: payment-service.ts
 */

import { useState, useCallback, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { createSecurityContext } from './usePipeline';
import { getPaymentService } from '../services/payment-service';
import type {
  ChargeClientRequest,
  ChargeResult,
  PaymentHistoryOptions,
} from '../services/payment-service';
import type { Payment, PaymentMethodCard } from '../types/models';

// ============================================
// Types
// ============================================

export interface UsePaymentsResult {
  /** Charge a client */
  chargeClient: (request: ChargeClientRequest) => Promise<ChargeResult>;
  /** Get payment history */
  getHistory: (options?: PaymentHistoryOptions) => Promise<Payment[]>;
  /** Get saved payment methods for a client */
  getPaymentMethods: (clientId: string) => Promise<PaymentMethodCard[]>;
  /** Loading state */
  isLoading: boolean;
  /** Error state */
  error: string | null;
}

export interface UsePaymentHistoryResult {
  /** Payment history */
  payments: Payment[];
  /** Loading state */
  isLoading: boolean;
  /** Error state */
  error: string | null;
  /** Refresh payment history */
  refresh: () => void;
}

// ============================================
// Hook Implementations
// ============================================

/**
 * Hook for payment operations
 * Provides methods to charge clients and retrieve payment history
 *
 * @example
 * ```tsx
 * const { chargeClient, getHistory, isLoading } = usePayments();
 *
 * const handleCharge = async () => {
 *   const result = await chargeClient({
 *     amountCents: 10000,
 *     currency: 'USD',
 *     clientId: 'client-123',
 *     clientName: 'John Doe',
 *     method: 'card',
 *     paymentMethodId: 'pm_123',
 *   });
 *
 *   if (result.success) {
 *     console.log('Payment succeeded:', result.payment);
 *   }
 * };
 * ```
 */
export function usePayments(): UsePaymentsResult {
  const { crmUser, businessId } = useAuth();
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Get security context
  const getContext = useCallback(() => {
    if (!businessId || !crmUser) {
      throw new Error('User not authenticated');
    }
    return createSecurityContext(
      businessId,
      crmUser.id,
      crmUser.displayName,
      crmUser.role
    );
  }, [businessId, crmUser]);

  /**
   * Charge a client
   */
  const chargeClient = useCallback(
    async (request: ChargeClientRequest): Promise<ChargeResult> => {
      if (!businessId || !crmUser) {
        return {
          success: false,
          error: 'User not authenticated',
        };
      }

      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const service = getPaymentService();
        const result = await service.chargeClient(context, request);

        if (!result.success) {
          setError(result.error || 'Failed to process payment');
        }

        return result;
      } catch (err) {
        const errorMessage = err instanceof Error ? err.message : 'Failed to process payment';
        setError(errorMessage);
        return {
          success: false,
          error: errorMessage,
        };
      } finally {
        setIsLoading(false);
      }
    },
    [businessId, crmUser, getContext]
  );

  /**
   * Get payment history
   */
  const getHistory = useCallback(
    async (options: PaymentHistoryOptions = {}): Promise<Payment[]> => {
      if (!businessId || !crmUser) {
        return [];
      }

      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const service = getPaymentService();
        return await service.getPaymentHistory(context, options);
      } catch (err) {
        const errorMessage = err instanceof Error ? err.message : 'Failed to fetch payment history';
        setError(errorMessage);
        return [];
      } finally {
        setIsLoading(false);
      }
    },
    [businessId, crmUser, getContext]
  );

  /**
   * Get saved payment methods for a client
   */
  const getPaymentMethods = useCallback(
    async (clientId: string): Promise<PaymentMethodCard[]> => {
      if (!businessId || !crmUser) {
        return [];
      }

      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const service = getPaymentService();
        return await service.getPaymentMethods(context, clientId);
      } catch (err) {
        const errorMessage = err instanceof Error ? err.message : 'Failed to fetch payment methods';
        setError(errorMessage);
        return [];
      } finally {
        setIsLoading(false);
      }
    },
    [businessId, crmUser, getContext]
  );

  return {
    chargeClient,
    getHistory,
    getPaymentMethods,
    isLoading,
    error,
  };
}

/**
 * Hook for fetching payment history
 * Automatically fetches and caches payment history
 *
 * @param options - Query options for filtering payments
 * @returns Payment history and state
 *
 * @example
 * ```tsx
 * const { payments, isLoading, refresh } = usePaymentHistory({
 *   clientId: 'client-123',
 *   limit: 10,
 * });
 *
 * if (isLoading) return <Loading />;
 *
 * return (
 *   <PaymentList payments={payments} onRefresh={refresh} />
 * );
 * ```
 */
export function usePaymentHistory(
  options: PaymentHistoryOptions = {}
): UsePaymentHistoryResult {
  const { crmUser, businessId } = useAuth();
  const [payments, setPayments] = useState<Payment[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Get security context
  const getContext = useCallback(() => {
    if (!businessId || !crmUser) {
      throw new Error('User not authenticated');
    }
    return createSecurityContext(
      businessId,
      crmUser.id,
      crmUser.displayName,
      crmUser.role
    );
  }, [businessId, crmUser]);

  // Fetch payment history
  const fetchHistory = useCallback(async () => {
    if (!businessId || !crmUser) {
      setPayments([]);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const context = getContext();
      const service = getPaymentService();
      const history = await service.getPaymentHistory(context, options);
      setPayments(history);
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to fetch payment history';
      setError(errorMessage);
      setPayments([]);
    } finally {
      setIsLoading(false);
    }
  }, [businessId, crmUser, getContext, options]);

  // Initial fetch
  useEffect(() => {
    fetchHistory();
  }, [fetchHistory]);

  // Manual refresh
  const refresh = useCallback(() => {
    fetchHistory();
  }, [fetchHistory]);

  return {
    payments,
    isLoading,
    error,
    refresh,
  };
}

export default usePayments;
