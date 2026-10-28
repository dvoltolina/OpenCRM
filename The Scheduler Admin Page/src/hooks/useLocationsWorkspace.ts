import { useCallback, useEffect, useState } from 'react';

import {
  createLocation,
  createResource,
  deleteLocation,
  deleteResource,
  listLocations,
  listResourceConflicts,
  listResources,
  resolveResourceConflict,
  toggleResourceMaintenance,
  updateLocation,
  updateResource,
} from '../data/locations';
import { listServices } from '../data/services';
import { listStaff } from '../data/staff';
import type {
  Location,
  LocationInput,
  Resource,
  ResourceConflict,
  ResourceInput,
  Service,
  StaffMember,
} from '../types/models';

type LocationsWorkspaceState = {
  locations: Location[];
  resources: Resource[];
  staff: StaffMember[];
  services: Service[];
  conflicts: ResourceConflict[];
  loading: boolean;
  error: string | null;
  saving: boolean;
  refresh: () => Promise<void>;
  saveLocation: (input: LocationInput, locationId?: string) => Promise<void>;
  deleteLocation: (locationId: string) => Promise<void>;
  saveResource: (input: ResourceInput, resourceId?: string) => Promise<void>;
  deleteResource: (resourceId: string) => Promise<void>;
  toggleMaintenance: (resourceId: string, note?: string) => Promise<void>;
  resolveConflict: (conflictId: string, resolution: string) => Promise<void>;
};

export function useLocationsWorkspace(businessId?: string, userId?: string): LocationsWorkspaceState {
  const [locations, setLocations] = useState<Location[]>([]);
  const [resources, setResources] = useState<Resource[]>([]);
  const [staff, setStaff] = useState<StaffMember[]>([]);
  const [services, setServices] = useState<Service[]>([]);
  const [conflicts, setConflicts] = useState<ResourceConflict[]>([]);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    if (!businessId) {
      // No businessId - clear all data and set error
      setLocations([]);
      setResources([]);
      setStaff([]);
      setServices([]);
      setConflicts([]);
      setError('Business context required to load locations workspace');
      return;
    }

    setLoading(true);
    setError(null);
    try {
      const [locs, res, staffRows, serviceRows, conflictRows] = await Promise.all([
        listLocations(businessId, userId),
        listResources(businessId),
        listStaff(businessId, userId),
        listServices(businessId, userId),
        listResourceConflicts(businessId),
      ]);

      setLocations(locs);
      setResources(res);
      setStaff(staffRows);
      setServices(serviceRows);
      setConflicts(conflictRows);
    } catch (err) {
      console.error('Failed to load locations workspace', err);
      setError(err instanceof Error ? err.message : 'Failed to load locations data.');
      // Clear data on error
      setLocations([]);
      setResources([]);
      setStaff([]);
      setServices([]);
      setConflicts([]);
    } finally {
      setLoading(false);
    }
  }, [businessId, userId]);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  const withMutation = useCallback(
    async (fn: () => Promise<void>) => {
      setSaving(true);
      setError(null);
      try {
        await fn();
        await refresh();
      } catch (err) {
        console.error('Locations workspace mutation failed', err);
        setError(err instanceof Error ? err.message : 'Failed to save changes.');
      } finally {
        setSaving(false);
      }
    },
    [refresh],
  );

  return {
    locations,
    resources,
    staff,
    services,
    conflicts,
    loading,
    error,
    saving,
    refresh,
    saveLocation: async (input, locationId) => {
      if (!businessId) return;
      await withMutation(async () => {
        if (locationId) {
          await updateLocation(businessId, locationId, input);
        } else {
          await createLocation(businessId, input);
        }
      });
    },
    deleteLocation: async (locationId) => {
      if (!businessId) return;
      await withMutation(async () => {
        await deleteLocation(businessId, locationId);
      });
    },
    saveResource: async (input, resourceId) => {
      if (!businessId) return;
      await withMutation(async () => {
        if (resourceId) {
          await updateResource(businessId, resourceId, input);
        } else {
          await createResource(businessId, input);
        }
      });
    },
    deleteResource: async (resourceId) => {
      if (!businessId) return;
      await withMutation(async () => {
        await deleteResource(businessId, resourceId);
      });
    },
    toggleMaintenance: async (resourceId, note) => {
      if (!businessId) return;
      await withMutation(async () => {
        await toggleResourceMaintenance(businessId, resourceId, note);
      });
    },
    resolveConflict: async (conflictId, resolution) => {
      if (!businessId) return;
      await withMutation(async () => {
        await resolveResourceConflict(businessId, conflictId, resolution);
      });
    },
  };
}

