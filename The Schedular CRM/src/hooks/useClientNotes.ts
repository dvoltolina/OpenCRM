/**
 * Client Notes Hook
 * Provides React Query hooks for client notes and job notes
 *
 * Supports bidirectional sync with Flutter app:
 * - Client notes can be created/edited in CRM
 * - Job notes from providers are read-only
 */

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useMemo } from 'react';
import { useAuth } from '../context/AuthContext';
import { createSecurityContext } from '../lib/security-context';
import { useDemoGuard } from './useDemoGuard';
import {
  getClientNoteRepository,
  getJobNoteRepository,
  type ClientNote,
  type JobNote,
  type ClientNoteType,
  type ClientNoteFilters,
  type JobNoteFilters,
} from '../data/repositories/client-note-repository';

// Re-export types for convenience
export type { ClientNote, JobNote, ClientNoteType };

// ============================================
// Client Notes Hooks
// ============================================

/**
 * Hook to fetch client notes for a specific client
 */
export function useClientNotes(clientId: string | undefined, options?: { limit?: number }) {
  const { crmUser } = useAuth();
  const securityContext = useMemo(
    () => (crmUser ? createSecurityContext(crmUser) : null),
    [crmUser]
  );

  const query = useQuery({
    queryKey: ['clientNotes', clientId, options?.limit],
    queryFn: async () => {
      if (!securityContext || !clientId) {
        return [];
      }
      const repo = getClientNoteRepository();
      const result = await repo.getByClientId(securityContext, clientId, options);
      if (!result.success) {
        throw result.error || new Error('Failed to fetch client notes');
      }
      return result.data;
    },
    enabled: Boolean(securityContext && clientId),
    staleTime: 30000, // 30 seconds
  });

  return {
    notes: query.data || [],
    isLoading: query.isLoading,
    error: query.error,
    refetch: query.refetch,
  };
}

/**
 * Hook to fetch filtered client notes
 */
export function useFilteredClientNotes(filters: ClientNoteFilters, options?: { limit?: number }) {
  const { crmUser } = useAuth();
  const securityContext = useMemo(
    () => (crmUser ? createSecurityContext(crmUser) : null),
    [crmUser]
  );

  const query = useQuery({
    queryKey: ['clientNotes', 'filtered', filters, options],
    queryFn: async () => {
      if (!securityContext) {
        return { data: [] as ClientNote[], lastDoc: null, hasMore: false, totalCount: 0 };
      }
      const repo = getClientNoteRepository();
      const result = await repo.getFiltered(securityContext, filters, options);
      if (!result.success) {
        throw result.error || new Error('Failed to fetch client notes');
      }
      return result.data;
    },
    enabled: Boolean(securityContext),
    staleTime: 30000,
  });

  return {
    notes: query.data?.data || [],
    total: query.data?.totalCount || 0,
    hasMore: query.data?.hasMore || false,
    isLoading: query.isLoading,
    error: query.error,
    refetch: query.refetch,
  };
}

/**
 * Hook to fetch recent client notes (for activity feed)
 */
export function useRecentClientNotes(limit: number = 10) {
  const { crmUser } = useAuth();
  const securityContext = useMemo(
    () => (crmUser ? createSecurityContext(crmUser) : null),
    [crmUser]
  );

  const query = useQuery({
    queryKey: ['clientNotes', 'recent', limit],
    queryFn: async () => {
      if (!securityContext) {
        return [];
      }
      const repo = getClientNoteRepository();
      const result = await repo.getRecent(securityContext, limit);
      if (!result.success) {
        throw result.error || new Error('Failed to fetch recent notes');
      }
      return result.data;
    },
    enabled: Boolean(securityContext),
    staleTime: 30000,
  });

  return {
    notes: query.data || [],
    isLoading: query.isLoading,
    error: query.error,
    refetch: query.refetch,
  };
}

// ============================================
// Client Notes Mutations
// ============================================

export interface CreateNoteInput {
  clientId: string;
  content: string;
  type: ClientNoteType;
  [key: string]: unknown;
}

export interface UpdateNoteInput {
  noteId: string;
  content: string;
  type: ClientNoteType;
}

/**
 * Hook for client note mutations (create, update, delete)
 */
export function useClientNoteMutations() {
  const { crmUser } = useAuth();
  const { guardMutation } = useDemoGuard();
  const queryClient = useQueryClient();
  const securityContext = useMemo(
    () => (crmUser ? createSecurityContext(crmUser) : null),
    [crmUser]
  );

  const createMutation = useMutation({
    mutationFn: async (input: CreateNoteInput) => {
      if (!securityContext) {
        throw new Error('Not authenticated');
      }
      const repo = getClientNoteRepository();
      const result = await repo.createNote(securityContext, input);
      if (!result.success) {
        throw result.error || new Error('Failed to create note');
      }
      return result.data;
    },
    onSuccess: (data) => {
      // Invalidate relevant queries
      queryClient.invalidateQueries({ queryKey: ['clientNotes', data.clientId] });
      queryClient.invalidateQueries({ queryKey: ['clientNotes', 'recent'] });
      queryClient.invalidateQueries({ queryKey: ['clientNotes', 'filtered'] });
    },
  });

  const updateMutation = useMutation({
    mutationFn: async (input: UpdateNoteInput) => {
      if (!securityContext) {
        throw new Error('Not authenticated');
      }
      const repo = getClientNoteRepository();
      const result = await repo.updateNote(securityContext, input.noteId, {
        content: input.content,
        type: input.type,
      });
      if (!result.success) {
        throw result.error || new Error('Failed to update note');
      }
      return result.data;
    },
    onSuccess: (data) => {
      queryClient.invalidateQueries({ queryKey: ['clientNotes', data.clientId] });
      queryClient.invalidateQueries({ queryKey: ['clientNotes', 'recent'] });
      queryClient.invalidateQueries({ queryKey: ['clientNotes', 'filtered'] });
    },
  });

  const deleteMutation = useMutation({
    mutationFn: async ({ noteId, clientId }: { noteId: string; clientId: string }) => {
      if (!securityContext) {
        throw new Error('Not authenticated');
      }
      const repo = getClientNoteRepository();
      const result = await repo.deleteNote(securityContext, noteId);
      if (!result.success) {
        throw result.error || new Error('Failed to delete note');
      }
      return { noteId, clientId };
    },
    onSuccess: ({ clientId }) => {
      queryClient.invalidateQueries({ queryKey: ['clientNotes', clientId] });
      queryClient.invalidateQueries({ queryKey: ['clientNotes', 'recent'] });
      queryClient.invalidateQueries({ queryKey: ['clientNotes', 'filtered'] });
    },
  });

  return {
    createNote: guardMutation(createMutation.mutateAsync, { action: 'client-note-create' }),
    updateNote: guardMutation(updateMutation.mutateAsync, { action: 'client-note-update' }),
    deleteNote: guardMutation(deleteMutation.mutateAsync, { action: 'client-note-delete' }),
    isCreating: createMutation.isPending,
    isUpdating: updateMutation.isPending,
    isDeleting: deleteMutation.isPending,
    createError: createMutation.error,
    updateError: updateMutation.error,
    deleteError: deleteMutation.error,
  };
}

// ============================================
// Job Notes Hooks (Read-Only)
// ============================================

/**
 * Hook to fetch job notes for a specific client (read-only from Flutter providers)
 */
export function useJobNotes(clientId: string | undefined, options?: { limit?: number }) {
  const { crmUser } = useAuth();
  const securityContext = useMemo(
    () => (crmUser ? createSecurityContext(crmUser) : null),
    [crmUser]
  );

  const query = useQuery({
    queryKey: ['jobNotes', clientId, options?.limit],
    queryFn: async () => {
      if (!securityContext || !clientId) {
        return [];
      }
      const repo = getJobNoteRepository();
      const result = await repo.getByClientId(securityContext, clientId, options);
      if (!result.success) {
        throw result.error || new Error('Failed to fetch job notes');
      }
      return result.data;
    },
    enabled: Boolean(securityContext && clientId),
    staleTime: 60000, // 1 minute (less frequent updates since it's read-only)
  });

  return {
    notes: query.data || [],
    isLoading: query.isLoading,
    error: query.error,
    refetch: query.refetch,
  };
}

/**
 * Hook to fetch job notes for a specific appointment
 */
export function useAppointmentJobNotes(appointmentId: string | undefined) {
  const { crmUser } = useAuth();
  const securityContext = useMemo(
    () => (crmUser ? createSecurityContext(crmUser) : null),
    [crmUser]
  );

  const query = useQuery({
    queryKey: ['jobNotes', 'appointment', appointmentId],
    queryFn: async () => {
      if (!securityContext || !appointmentId) {
        return [];
      }
      const repo = getJobNoteRepository();
      const result = await repo.getByAppointmentId(securityContext, appointmentId);
      if (!result.success) {
        throw result.error || new Error('Failed to fetch job notes');
      }
      return result.data;
    },
    enabled: Boolean(securityContext && appointmentId),
    staleTime: 60000,
  });

  return {
    notes: query.data || [],
    isLoading: query.isLoading,
    error: query.error,
    refetch: query.refetch,
  };
}

/**
 * Hook to fetch filtered job notes
 */
export function useFilteredJobNotes(filters: JobNoteFilters, options?: { limit?: number }) {
  const { crmUser } = useAuth();
  const securityContext = useMemo(
    () => (crmUser ? createSecurityContext(crmUser) : null),
    [crmUser]
  );

  const query = useQuery({
    queryKey: ['jobNotes', 'filtered', filters, options],
    queryFn: async () => {
      if (!securityContext) {
        return [];
      }
      const repo = getJobNoteRepository();
      const result = await repo.getFiltered(securityContext, filters, options);
      if (!result.success) {
        throw result.error || new Error('Failed to fetch job notes');
      }
      return result.data;
    },
    enabled: Boolean(securityContext),
    staleTime: 60000,
  });

  return {
    notes: query.data || [],
    isLoading: query.isLoading,
    error: query.error,
    refetch: query.refetch,
  };
}

// ============================================
// Combined Notes Hook
// ============================================

/**
 * Hook to fetch both client notes and job notes for a client
 * Useful for showing a complete activity history
 */
export function useAllClientNotes(clientId: string | undefined) {
  const clientNotesQuery = useClientNotes(clientId);
  const jobNotesQuery = useJobNotes(clientId);

  const allNotes = useMemo(() => {
    const clientNotes = clientNotesQuery.notes.map((note) => ({
      ...note,
      noteType: 'client' as const,
      displayContent: note.content,
      displayDate: note.createdAt,
      displayAuthor: note.createdByName,
    }));

    const jobNotes = jobNotesQuery.notes.map((note) => ({
      ...note,
      noteType: 'job' as const,
      displayContent: note.noteContent,
      displayDate: note.createdAt,
      displayAuthor: note.providerName,
    }));

    // Combine and sort by date (newest first)
    return [...clientNotes, ...jobNotes].sort(
      (a, b) => b.displayDate.getTime() - a.displayDate.getTime()
    );
  }, [clientNotesQuery.notes, jobNotesQuery.notes]);

  return {
    notes: allNotes,
    clientNotes: clientNotesQuery.notes,
    jobNotes: jobNotesQuery.notes,
    isLoading: clientNotesQuery.isLoading || jobNotesQuery.isLoading,
    error: clientNotesQuery.error || jobNotesQuery.error,
    refetch: () => {
      clientNotesQuery.refetch();
      jobNotesQuery.refetch();
    },
  };
}
