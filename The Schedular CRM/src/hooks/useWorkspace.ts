/**
 * useWorkspace Hook
 *
 * Fetches workspace/business metadata for displaying in settings.
 * Maintains strict tenant isolation - only fetches data for authenticated user's businessId.
 *
 * HIPAA/Security Compliance:
 * - No default/fallback businessId
 * - Requires authenticated user with valid businessId
 * - Read-only access to workspace metadata
 */

import { useEffect, useState } from 'react';
import { doc, getDoc } from 'firebase/firestore';
import { getFirebaseDb } from '../lib/firebase';
import { useAuth } from '../context/AuthContext';
import type { Business } from '../types/models';

interface UseWorkspaceResult {
  workspace: Business | null;
  isLoading: boolean;
  error: Error | null;
  refresh: () => Promise<void>;
}

/**
 * Fetch workspace metadata for the current user's business
 *
 * @returns Workspace data, loading state, and error
 *
 * @example
 * ```tsx
 * const { workspace, isLoading, error } = useWorkspace();
 *
 * if (workspace) {
 *   console.log('Workspace:', workspace.name);
 *   console.log('Slug:', workspace.slug);
 *   console.log('Public URL:', workspace.publicBookingUrl);
 * }
 * ```
 */
export function useWorkspace(): UseWorkspaceResult {
  const { businessId, crmUser } = useAuth();
  const [workspace, setWorkspace] = useState<Business | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const fetchWorkspace = async () => {
    // Security: Require businessId with no fallback
    if (!businessId || !crmUser) {
      setWorkspace(null);
      setIsLoading(false);
      setError(new Error('No business context available'));
      return;
    }

    const db = getFirebaseDb();
    if (!db) {
      setError(new Error('Database not initialized'));
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const businessDocRef = doc(db, 'businesses', businessId);
      const businessSnap = await getDoc(businessDocRef);

      if (!businessSnap.exists()) {
        throw new Error('Workspace not found');
      }

      const data = businessSnap.data();
      const business: Business = {
        id: businessSnap.id,
        name: data.name || 'Unnamed Workspace',
        slug: data.slug,
        inviteCode: data.inviteCode,
        publicBookingUrl: data.publicBookingUrl,
        requiresHipaaCompliance: data.requiresHipaaCompliance,
        mfaEnabled: data.mfaEnabled,
        auditLoggingEnabled: data.auditLoggingEnabled,
        createdAt: data.createdAt?.toDate() || new Date(),
        updatedAt: data.updatedAt?.toDate(),
        ownerId: data.ownerId,
        ownerEmail: data.ownerEmail,
      };

      setWorkspace(business);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to load workspace';
      setError(new Error(message));
      setWorkspace(null);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchWorkspace();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [businessId, crmUser]);

  return {
    workspace,
    isLoading,
    error,
    refresh: fetchWorkspace,
  };
}
