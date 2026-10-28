/**
 * useOpsNotes Hook
 * Support notes for a tenant (super-admin only).
 */

import { useCallback, useEffect, useState } from 'react';
import { listOpsNotes, addOpsNote } from '../data/opsNotes';
import { useSuperAdminContext } from './useSuperAdminContext';
import type { OpsNote, OpsNoteCategory, OpsNotePriority } from '../types/ops';

export type UseOpsNotesResult = {
  notes: OpsNote[];
  loading: boolean;
  error: string | null;
  adding: boolean;
  refresh: () => Promise<void>;
  addNote: (input: {
    content: string;
    category?: OpsNoteCategory;
    priority?: OpsNotePriority;
  }) => Promise<void>;
};

export function useOpsNotes(businessId: string | null): UseOpsNotesResult {
  const { isAuthorized, userId, email } = useSuperAdminContext();
  const [notes, setNotes] = useState<OpsNote[]>([]);
  const [loading, setLoading] = useState(false);
  const [adding, setAdding] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    if (!isAuthorized || !businessId) {
      setNotes([]);
      return;
    }

    setLoading(true);
    setError(null);
    try {
      const data = await listOpsNotes(businessId);
      setNotes(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load notes');
    } finally {
      setLoading(false);
    }
  }, [isAuthorized, businessId]);

  useEffect(() => {
    if (businessId) {
      void refresh();
    }
  }, [businessId, refresh]);

  const addNote = useCallback(
    async (input: {
      content: string;
      category?: OpsNoteCategory;
      priority?: OpsNotePriority;
    }) => {
      if (!isAuthorized || !userId || !email || !businessId) return;

      setAdding(true);
      setError(null);
      try {
        await addOpsNote(businessId, {
          content: input.content,
          createdBy: userId,
          createdByEmail: email,
          category: input.category,
          priority: input.priority,
        });
        await refresh();
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to add note');
        throw err;
      } finally {
        setAdding(false);
      }
    },
    [isAuthorized, userId, email, businessId, refresh],
  );

  return { notes, loading, error, adding, refresh, addNote };
}
