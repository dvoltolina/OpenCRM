/**
 * useOwnershipTransfer Hook
 * Manages state for ownership transfer process.
 */

import { useState, useCallback } from 'react';

import { transferOwnership, type OwnershipTransferInput } from '../data/ownershipTransfer';

export function useOwnershipTransfer() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  const executeTransfer = useCallback(
    async (input: OwnershipTransferInput): Promise<boolean> => {
      setLoading(true);
      setError(null);
      setSuccess(false);

      try {
        const result = await transferOwnership(input);

        if (result.success) {
          setSuccess(true);
          return true;
        } else {
          setError(result.error || 'Transfer failed');
          return false;
        }
      } catch (err) {
        const message = err instanceof Error ? err.message : 'Unknown error occurred';
        setError(message);
        return false;
      } finally {
        setLoading(false);
      }
    },
    []
  );

  const reset = useCallback(() => {
    setLoading(false);
    setError(null);
    setSuccess(false);
  }, []);

  return {
    loading,
    error,
    success,
    executeTransfer,
    reset,
  };
}
