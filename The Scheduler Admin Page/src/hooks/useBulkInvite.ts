import { useState, useCallback } from 'react';
import { useBusinessContext } from './useBusinessContext';
import { parseCsvInvites, type ParsedCsvResult } from '../lib/csvParser';
import { sendBulkInvites, type BulkInviteResult } from '../data/bulkInvites';

type BulkInviteStep = 'upload' | 'preview' | 'sending' | 'done';

/**
 * Hook for managing bulk invite state and operations.
 * HIPAA Note: All operations are audit logged with counts only, never PII.
 */
export function useBulkInvite() {
  const { businessId, userId } = useBusinessContext({ minRole: 'admin' });
  const [step, setStep] = useState<BulkInviteStep>('upload');
  const [parsedData, setParsedData] = useState<ParsedCsvResult | null>(null);
  const [result, setResult] = useState<BulkInviteResult | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  /**
   * Handles CSV file upload and parsing.
   * HIPAA Note: File is read locally, never sent to server until user confirms.
   */
  const handleFileUpload = useCallback((file: File) => {
    setLoading(true);
    setError(null);

    const reader = new FileReader();

    reader.onload = (e) => {
      try {
        const content = e.target?.result as string;
        if (!content) {
          setError('Failed to read file');
          setLoading(false);
          return;
        }

        const parsed = parseCsvInvites(content);
        setParsedData(parsed);
        setStep('preview');
      } catch (err) {
        setError('Failed to parse CSV file');
        console.error('[useBulkInvite] Parse error:', err);
      } finally {
        setLoading(false);
      }
    };

    reader.onerror = () => {
      setError('Failed to read file');
      setLoading(false);
    };

    reader.readAsText(file);
  }, []);

  /**
   * Sends the validated invites to the server.
   * HIPAA Note: Only valid invites are sent. Audit logged with counts only.
   */
  const sendInvites = useCallback(async () => {
    if (!businessId || !userId) {
      setError('Business context is required');
      return;
    }

    if (!parsedData || parsedData.valid.length === 0) {
      setError('No valid invites to send');
      return;
    }

    setLoading(true);
    setError(null);
    setStep('sending');

    try {
      const inviteResult = await sendBulkInvites(businessId, userId, {
        invites: parsedData.valid,
      });

      setResult(inviteResult);
      setStep('done');
    } catch (err) {
      setError('Failed to send invites');
      console.error('[useBulkInvite] Send error:', err);
      setStep('preview'); // Return to preview on error
    } finally {
      setLoading(false);
    }
  }, [businessId, userId, parsedData]);

  /**
   * Resets the bulk invite flow to initial state.
   */
  const reset = useCallback(() => {
    setStep('upload');
    setParsedData(null);
    setResult(null);
    setError(null);
    setLoading(false);
  }, []);

  /**
   * Goes back to the upload step.
   */
  const goBack = useCallback(() => {
    setStep('upload');
    setParsedData(null);
    setError(null);
  }, []);

  return {
    step,
    parsedData,
    result,
    loading,
    error,
    handleFileUpload,
    sendInvites,
    reset,
    goBack,
  };
}
