/**
 * useContactMutations Hook
 * CRUD operations for contacts
 *
 * Agent CRM-10 Implementation
 * Dependencies: Agent CRM-05 (contact repository)
 */

import { useCallback, useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { getContactRepository } from '../data/repositories/contact-repository';
import { createSecurityContext } from './usePipeline';
import type { Client, GeocodedAddress } from '../types/models';
import {
  geocodeAddress,
  buildAddressString,
  hasAddressChanged,
} from '../services/geocoding-service';
import { useDemoGuard } from './useDemoGuard';

// ============================================
// Types
// ============================================

export interface ContactMutationOptions {
  /** Allow duplicate email/phone */
  allowDuplicate?: boolean;
  /** Auto-geocode address if provided (default: true) */
  autoGeocode?: boolean;
}

export interface UseContactMutationsResult {
  /** Create a new contact */
  createContact: (data: Partial<Client>, options?: ContactMutationOptions) => Promise<Client>;
  /** Update an existing contact */
  updateContact: (
    id: string,
    data: Partial<Client>,
    options?: ContactMutationOptions
  ) => Promise<void>;
  /** Delete a contact */
  deleteContact: (id: string) => Promise<void>;
  /** Link contact to a company */
  linkToCompany: (id: string, companyId: string, companyName: string) => Promise<void>;
  /** Unlink contact from company */
  unlinkFromCompany: (id: string) => Promise<void>;
  /** Update lifecycle stage */
  updateLifecycle: (id: string, lifecycle: NonNullable<Client['lifecycle']>) => Promise<void>;
  /** Update last contacted timestamp */
  updateLastContacted: (id: string) => Promise<void>;
  /** Add tag to contact */
  addTag: (id: string, tag: string) => Promise<void>;
  /** Remove tag from contact */
  removeTag: (id: string, tag: string) => Promise<void>;
  /** Update geocoded address (for route planning) */
  updateGeocodedAddress: (id: string, geocodedAddress: GeocodedAddress) => Promise<void>;
  /** Whether a mutation is in progress */
  isLoading: boolean;
  /** Error from the last mutation */
  error: Error | null;
  /** Clear the error state */
  clearError: () => void;
}

// ============================================
// Hook Implementation
// ============================================

/**
 * Hook for contact CRUD operations
 *
 * @returns Mutation functions and state
 *
 * @example
 * ```tsx
 * const { createContact, updateLifecycle, linkToCompany, isLoading } = useContactMutations();
 *
 * const handleCreate = async () => {
 *   const contact = await createContact({
 *     firstName: 'John',
 *     lastName: 'Doe',
 *     email: 'john@example.com',
 *   });
 *   console.log('Created contact:', contact.id);
 * };
 * ```
 */
export function useContactMutations(): UseContactMutationsResult {
  const { crmUser, businessId } = useAuth();
  const { guardMutation } = useDemoGuard();
  const [isLoading, setIsLoading] = useState(false);
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

  // Create a new contact
  const createContact = useCallback(
    async (data: Partial<Client>, options?: ContactMutationOptions): Promise<Client> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getContactRepository();

        // Auto-geocode if address is provided (default: true)
        let geocodedAddress: GeocodedAddress | undefined;
        const shouldGeocode = options?.autoGeocode !== false && data.address;
        if (shouldGeocode) {
          const addressString = buildAddressString(data as Client);
          if (addressString) {
            try {
              const result = await geocodeAddress(addressString);
              if (result) {
                geocodedAddress = result;
              }
            } catch {
              // Geocoding failure should not block contact creation
              console.warn('Auto-geocoding failed during contact creation');
            }
          }
        }

        const contactData = {
          firstName: data.firstName || '',
          lastName: data.lastName || '',
          email: data.email || '',
          phone: data.phone,
          address: data.address,
          companyId: data.companyId,
          companyName: data.companyName,
          lifecycle: data.lifecycle || 'prospect',
          leadSource: data.leadSource || 'other',
          tags: data.tags || [],
          crmNotes: data.crmNotes,
          ...(geocodedAddress ? { geocodedAddress } : {}),
        };

        const result = await repo.create(context, {
          ...(options?.allowDuplicate ? { allowDuplicate: true } : {}),
          ...(contactData as Omit<Client, 'id' | 'createdAt' | 'updatedAt'>),
        });

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to create contact');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  // Update an existing contact
  const updateContact = useCallback(
    async (id: string, data: Partial<Client>, options?: ContactMutationOptions): Promise<void> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();

        // RBAC Check - only admin/owner/staff can edit (front desk is read-only)
        if (context.userRole !== 'owner' && context.userRole !== 'admin' && context.userRole !== 'staff') {
          throw new Error('Insufficient permissions to edit contacts');
        }

        const repo = getContactRepository();

        // Check if we need to auto-geocode (address changed)
        let updateData = { ...data };
        const shouldGeocode = options?.autoGeocode !== false && data.address;
        if (shouldGeocode) {
          // Get existing contact to check if address changed
          const existingResult = await repo.getById(context, id);
          if (existingResult.success) {
            const addressChanged = hasAddressChanged(existingResult.data, data);
            if (addressChanged) {
              const addressString = buildAddressString({ ...existingResult.data, ...data } as Client);
              if (addressString) {
                try {
                  const geocodedAddress = await geocodeAddress(addressString);
                  if (geocodedAddress) {
                    updateData = { ...updateData, geocodedAddress };
                  }
                } catch {
                  // Geocoding failure should not block contact update
                  console.warn('Auto-geocoding failed during contact update');
                }
              }
            }
          }
        }

        const result = await repo.update(
          context,
          id,
          { ...(options?.allowDuplicate ? { allowDuplicate: true } : {}), ...updateData } as Partial<
            Client
          > & { allowDuplicate?: boolean }
        );

        if (!result.success) {
          throw new Error(result.error.message);
        }
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to update contact');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  // Delete a contact
  const deleteContact = useCallback(
    async (id: string): Promise<void> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();

        // RBAC Check - only admin/owner can delete
        if (context.userRole !== 'owner' && context.userRole !== 'admin') {
          throw new Error('Only administrators can delete contacts');
        }

        const repo = getContactRepository();

        const result = await repo.delete(context, id);

        if (!result.success) {
          throw new Error(result.error.message);
        }
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to delete contact');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  // Link contact to a company
  const linkToCompany = useCallback(
    async (id: string, companyId: string, companyName: string): Promise<void> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getContactRepository();

        const result = await repo.linkToCompany(context, id, companyId, companyName);

        if (!result.success) {
          throw new Error(result.error.message);
        }
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to link contact to company');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  // Unlink contact from company
  const unlinkFromCompany = useCallback(
    async (id: string): Promise<void> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getContactRepository();

        const result = await repo.unlinkFromCompany(context, id);

        if (!result.success) {
          throw new Error(result.error.message);
        }
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to unlink contact from company');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  // Update lifecycle stage
  const updateLifecycle = useCallback(
    async (id: string, lifecycle: NonNullable<Client['lifecycle']>): Promise<void> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getContactRepository();

        const result = await repo.updateLifecycle(context, id, lifecycle);

        if (!result.success) {
          throw new Error(result.error.message);
        }
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to update lifecycle');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  // Update last contacted timestamp
  const updateLastContacted = useCallback(
    async (id: string): Promise<void> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getContactRepository();

        const result = await repo.updateLastContacted(context, id);

        if (!result.success) {
          throw new Error(result.error.message);
        }
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to update last contacted');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  // Add tag to contact
  const addTag = useCallback(
    async (id: string, tag: string): Promise<void> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getContactRepository();

        const result = await repo.addTag(context, id, tag);

        if (!result.success) {
          throw new Error(result.error.message);
        }
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to add tag');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  // Remove tag from contact
  const removeTag = useCallback(
    async (id: string, tag: string): Promise<void> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getContactRepository();

        const result = await repo.removeTag(context, id, tag);

        if (!result.success) {
          throw new Error(result.error.message);
        }
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to remove tag');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  // Update geocoded address (for route planning)
  const updateGeocodedAddress = useCallback(
    async (id: string, geocodedAddress: GeocodedAddress): Promise<void> => {
      setIsLoading(true);
      setError(null);

      try {
        const context = getContext();
        const repo = getContactRepository();

        // Geocoding updates are allowed for staff+ (same as contact updates)
        if (context.userRole !== 'owner' && context.userRole !== 'admin' && context.userRole !== 'staff' && context.userRole !== 'manager') {
          throw new Error('Insufficient permissions to update contact geocoding');
        }

        const result = await repo.update(context, id, { geocodedAddress });

        if (!result.success) {
          throw new Error(result.error.message);
        }
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to update geocoded address');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  return {
    createContact: guardMutation(createContact, { action: 'contact-create' }),
    updateContact: guardMutation(updateContact, { action: 'contact-update' }),
    deleteContact: guardMutation(deleteContact, { action: 'contact-delete' }),
    linkToCompany: guardMutation(linkToCompany, { action: 'contact-link-company' }),
    unlinkFromCompany: guardMutation(unlinkFromCompany, { action: 'contact-unlink-company' }),
    updateLifecycle: guardMutation(updateLifecycle, { action: 'contact-lifecycle-update' }),
    updateLastContacted: guardMutation(updateLastContacted, { action: 'contact-last-contacted' }),
    addTag: guardMutation(addTag, { action: 'contact-tag-add' }),
    removeTag: guardMutation(removeTag, { action: 'contact-tag-remove' }),
    updateGeocodedAddress: guardMutation(updateGeocodedAddress, { action: 'contact-geocode-update' }),
    isLoading,
    error,
    clearError,
  };
}

export default useContactMutations;
