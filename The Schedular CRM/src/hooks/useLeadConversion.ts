/**
 * useLeadConversion Hook
 * React hook for lead conversion workflow
 *
 * Agent CRM-11 Implementation
 * Dependencies: Lead Conversion Service
 */

import { useState, useCallback } from 'react';
import { useAuth } from '../context/AuthContext';
import { createSecurityContext } from './usePipeline';
import {
  getLeadConversionService,
  type ConversionOptions,
  type ConversionResult,
  type DuplicateMatch,
  type CanConvertResult,
} from '../services/lead-conversion-service';
import { useDemoGuard } from './useDemoGuard';

// Re-export types for convenience
export type { DuplicateMatch };
import type { Lead } from '../types/models';

// ============================================
// Types
// ============================================

export interface UseLeadConversionResult {
  /** Convert a lead to a client/deal */
  convert: (options: Omit<ConversionOptions, 'leadId'> & { leadId: string }) => Promise<ConversionResult>;
  /** Check if a lead can be converted */
  canConvert: (leadId: string) => Promise<CanConvertResult>;
  /** Check for duplicate clients */
  checkDuplicates: (lead: Lead) => Promise<DuplicateMatch[]>;
  /** Potential duplicate clients from last check */
  duplicates: DuplicateMatch[];
  /** True while conversion is in progress */
  isConverting: boolean;
  /** True while checking for duplicates */
  isCheckingDuplicates: boolean;
  /** Error from the last operation */
  error: Error | null;
  /** Clear the error state */
  clearError: () => void;
}

// ============================================
// Hook Implementation
// ============================================

/**
 * Hook for lead conversion workflow
 *
 * @returns Conversion functions, state, and error handling
 *
 * @example
 * ```tsx
 * const {
 *   convert,
 *   checkDuplicates,
 *   duplicates,
 *   isConverting,
 *   error,
 * } = useLeadConversion();
 *
 * // Check for duplicates before converting
 * const handleConvert = async (lead: Lead) => {
 *   const matches = await checkDuplicates(lead);
 *
 *   if (matches.length > 0) {
 *     // Show duplicate selection UI
 *     setShowDuplicateDialog(true);
 *     return;
 *   }
 *
 *   // No duplicates, proceed with conversion
 *   const result = await convert({
 *     leadId: lead.id,
 *     createDeal: true,
 *     dealData: {
 *       title: `Deal for ${lead.firstName}`,
 *       valueCents: 50000,
 *       pipelineId: defaultPipelineId,
 *       stageId: firstStageId,
 *     },
 *   });
 *
 *   console.log('Converted:', result.client.id, result.deal?.id);
 * };
 * ```
 */
export function useLeadConversion(): UseLeadConversionResult {
  const { crmUser, businessId } = useAuth();
  const { guardMutation } = useDemoGuard();
  const [duplicates, setDuplicates] = useState<DuplicateMatch[]>([]);
  const [isConverting, setIsConverting] = useState(false);
  const [isCheckingDuplicates, setIsCheckingDuplicates] = useState(false);
  const [error, setError] = useState<Error | null>(null);

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

  // Clear error
  const clearError = useCallback(() => {
    setError(null);
  }, []);

  // Check if lead can be converted
  const canConvert = useCallback(
    async (leadId: string): Promise<CanConvertResult> => {
      try {
        const context = getContext();
        const service = getLeadConversionService();
        return await service.canConvert(context, leadId);
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to check conversion');
        return { canConvert: false, reason: error.message };
      }
    },
    [getContext]
  );

  // Check for duplicate clients
  const checkDuplicates = useCallback(
    async (lead: Lead): Promise<DuplicateMatch[]> => {
      setIsCheckingDuplicates(true);
      setError(null);

      try {
        const context = getContext();
        const service = getLeadConversionService();
        const matches = await service.suggestExistingClient(context, lead);
        setDuplicates(matches);
        return matches;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to check duplicates');
        setError(error);
        setDuplicates([]);
        return [];
      } finally {
        setIsCheckingDuplicates(false);
      }
    },
    [getContext]
  );

  // Convert lead
  const convert = useCallback(
    async (options: ConversionOptions): Promise<ConversionResult> => {
      setIsConverting(true);
      setError(null);

      try {
        const context = getContext();
        const service = getLeadConversionService();
        const result = await service.convert(context, options);

        // Clear duplicates after successful conversion
        setDuplicates([]);

        return result;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to convert lead');
        setError(error);
        throw error;
      } finally {
        setIsConverting(false);
      }
    },
    [getContext]
  );

  return {
    convert: guardMutation(convert, { action: 'lead-convert' }),
    canConvert,
    checkDuplicates,
    duplicates,
    isConverting,
    isCheckingDuplicates,
    error,
    clearError,
  };
}

export default useLeadConversion;
