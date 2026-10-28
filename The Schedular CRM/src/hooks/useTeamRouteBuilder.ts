/**
 * Team Route Builder Hook
 * Orchestrates multi-staff route planning with territory auto-assignment
 *
 * HIPAA Compliance: All operations require authentication
 */

import { useState, useEffect, useCallback, useMemo } from 'react';
import { useAuth } from '../context/AuthContext';
import { useStaffSchedules, isStaffWorkingOnDate } from './useStaffSchedules';
import { useTerritories, suggestStaffForContact } from './useTerritories';
import { useContacts } from './useContacts';
import { useRoutes, useRouteMutations } from './useRoutes';
import { useTeamMembers } from './useTeamMembers';
import type {
  Route,
  RouteStop,
  StaffSchedule,
  Territory,
  Client,
} from '../types/models';
import type { TeamMember } from './useTeamMembers';

// ============================================
// Types
// ============================================

export interface WorkingStaffMember {
  staff: TeamMember;
  schedule: StaffSchedule | null;
  territories: Territory[];
  route: Route | null;
  selectedContacts: Client[];
  calendarConflicts: string[];
}

export interface TeamRoutePlan {
  date: Date;
  workingStaff: WorkingStaffMember[];
  unassignedContacts: Client[];
  assignedContactIds: Set<string>;
}

export interface UseTeamRouteBuilderResult {
  // Data
  selectedDate: Date;
  workingTeam: WorkingStaffMember[];
  unassignedContacts: Client[];
  allContacts: Client[];

  // Loading states
  isLoading: boolean;
  isSaving: boolean;
  error: Error | null;

  // Date selection
  setSelectedDate: (date: Date) => void;

  // Contact assignment
  assignContactToStaff: (contactId: string, staffId: string) => void;
  removeContactFromStaff: (contactId: string, staffId: string) => void;
  moveContactBetweenStaff: (
    contactId: string,
    fromStaffId: string,
    toStaffId: string
  ) => void;
  autoAssignUnassigned: () => void;
  clearStaffRoute: (staffId: string) => void;
  clearAllRoutes: () => void;

  // Route operations
  optimizeStaffRoute: (staffId: string) => Promise<void>;
  saveAllRoutes: () => Promise<Route[]>;
  saveSingleRoute: (staffId: string, routeName: string) => Promise<Route>;

  // Validation
  conflicts: Array<{ staffId: string; type: string; message: string }>;
  validatePlan: () => boolean;

  // Refresh
  refresh: () => void;
}

// ============================================
// Hook Implementation
// ============================================

export function useTeamRouteBuilder(initialDate?: Date): UseTeamRouteBuilderResult {
  const { crmUser: _crmUser, businessId: _businessId } = useAuth();

  // State
  const [selectedDate, setSelectedDate] = useState<Date>(
    initialDate ?? new Date()
  );
  const [staffAssignments, setStaffAssignments] = useState<
    Map<string, Client[]>
  >(new Map());
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  // Fetch data
  const { schedules, isLoading: schedulesLoading, refresh: refreshSchedules } = useStaffSchedules();
  const { territories, isLoading: territoriesLoading, refresh: refreshTerritories } = useTerritories();
  const { contacts, isLoading: contactsLoading, refresh: refreshContacts } = useContacts({});
  const { members: teamMembers, isLoading: membersLoading, refresh: refreshMembers } = useTeamMembers();

  // Memoize route filters to avoid recreating object each render (prevents fetch loops)
  const routeFilters = useMemo(
    () => ({
      dateFrom: selectedDate,
      dateTo: selectedDate,
    }),
    [selectedDate]
  );

  const { routes, isLoading: routesLoading, refresh: refreshRoutes } = useRoutes(routeFilters);
  const { createRoute, updateRoute, optimizeRoute } = useRouteMutations();

  const isLoading = schedulesLoading || territoriesLoading || contactsLoading || membersLoading || routesLoading;

  // Get contacts with geocoded addresses (for route planning)
  const geocodedContacts = useMemo(
    () => contacts.filter((c) => c.geocodedAddress?.latitude && c.geocodedAddress?.longitude),
    [contacts]
  );

  // Build working team for selected date
  const workingTeam = useMemo((): WorkingStaffMember[] => {
    if (isLoading) return [];

    return teamMembers
      .map((member) => {
        const schedule = schedules.find((s) => s.staffId === member.id) ?? null;
        const isWorking = schedule ? isStaffWorkingOnDate(schedule, selectedDate) : true; // If no schedule, assume working

        if (!isWorking) return null;

        const memberTerritories = territories.filter((t) =>
          t.assignments.some((a) => a.staffId === member.id)
        );

        const existingRoute = routes.find((r) => r.assigneeId === member.id) ?? null;

        // Get assigned contacts from state or existing route
        const assignedContacts = staffAssignments.get(member.id) ??
          (existingRoute?.stops.map((s) => s.contact) ?? []);

        return {
          staff: member,
          schedule,
          territories: memberTerritories,
          route: existingRoute,
          selectedContacts: assignedContacts,
          calendarConflicts: [] as string[], // TODO: Integrate with calendar conflict service
        };
      })
      .filter((m): m is WorkingStaffMember => m !== null);
  }, [teamMembers, schedules, territories, routes, selectedDate, isLoading, staffAssignments]);

  // Calculate assigned contact IDs
  const assignedContactIds = useMemo(() => {
    const ids = new Set<string>();
    workingTeam.forEach((member) => {
      member.selectedContacts.forEach((c) => ids.add(c.id));
    });
    return ids;
  }, [workingTeam]);

  // Calculate unassigned contacts
  const unassignedContacts = useMemo(
    () => geocodedContacts.filter((c) => !assignedContactIds.has(c.id)),
    [geocodedContacts, assignedContactIds]
  );

  // Initialize staff assignments from existing routes
  useEffect(() => {
    if (!isLoading && routes.length > 0) {
      const newAssignments = new Map<string, Client[]>();
      routes.forEach((route) => {
        if (route.assigneeId) {
          newAssignments.set(
            route.assigneeId,
            route.stops.map((s) => s.contact)
          );
        }
      });
      setStaffAssignments(newAssignments);
    }
  }, [routes, isLoading]);

  // ============================================
  // Contact Assignment Functions
  // ============================================

  const assignContactToStaff = useCallback(
    (contactId: string, staffId: string) => {
      const contact = geocodedContacts.find((c) => c.id === contactId);
      if (!contact) return;

      setStaffAssignments((prev) => {
        const next = new Map(prev);
        const current = next.get(staffId) ?? [];
        if (!current.some((c) => c.id === contactId)) {
          next.set(staffId, [...current, contact]);
        }
        return next;
      });
    },
    [geocodedContacts]
  );

  const removeContactFromStaff = useCallback(
    (contactId: string, staffId: string) => {
      setStaffAssignments((prev) => {
        const next = new Map(prev);
        const current = next.get(staffId) ?? [];
        next.set(
          staffId,
          current.filter((c) => c.id !== contactId)
        );
        return next;
      });
    },
    []
  );

  const moveContactBetweenStaff = useCallback(
    (contactId: string, fromStaffId: string, toStaffId: string) => {
      const contact = geocodedContacts.find((c) => c.id === contactId);
      if (!contact) return;

      setStaffAssignments((prev) => {
        const next = new Map(prev);

        // Remove from source
        const fromContacts = next.get(fromStaffId) ?? [];
        next.set(
          fromStaffId,
          fromContacts.filter((c) => c.id !== contactId)
        );

        // Add to destination
        const toContacts = next.get(toStaffId) ?? [];
        if (!toContacts.some((c) => c.id === contactId)) {
          next.set(toStaffId, [...toContacts, contact]);
        }

        return next;
      });
    },
    [geocodedContacts]
  );

  const autoAssignUnassigned = useCallback(() => {
    const workingStaffIds = workingTeam.map((m) => m.staff.id);

    setStaffAssignments((prev) => {
      const next = new Map(prev);

      unassignedContacts.forEach((contact) => {
        const suggestion = suggestStaffForContact(
          territories,
          contact,
          workingStaffIds
        );

        if (suggestion) {
          const current = next.get(suggestion.staffId) ?? [];
          if (!current.some((c) => c.id === contact.id)) {
            next.set(suggestion.staffId, [...current, contact]);
          }
        }
      });

      return next;
    });
  }, [unassignedContacts, territories, workingTeam]);

  const clearStaffRoute = useCallback((staffId: string) => {
    setStaffAssignments((prev) => {
      const next = new Map(prev);
      next.set(staffId, []);
      return next;
    });
  }, []);

  const clearAllRoutes = useCallback(() => {
    setStaffAssignments(new Map());
  }, []);

  // ============================================
  // Route Operations
  // ============================================

  const optimizeStaffRoute = useCallback(
    async (staffId: string) => {
      const member = workingTeam.find((m) => m.staff.id === staffId);
      if (!member || member.selectedContacts.length < 2) return;

      // If route exists, optimize it
      if (member.route) {
        try {
          const optimized = await optimizeRoute(member.route.id);
          setStaffAssignments((prev) => {
            const next = new Map(prev);
            next.set(staffId, optimized.stops.map((s) => s.contact));
            return next;
          });
        } catch (err) {
          setError(err instanceof Error ? err : new Error('Failed to optimize route'));
        }
      }
    },
    [workingTeam, optimizeRoute]
  );

  const saveSingleRoute = useCallback(
    async (staffId: string, routeName: string): Promise<Route> => {
      const member = workingTeam.find((m) => m.staff.id === staffId);
      if (!member) {
        throw new Error('Staff member not found');
      }

      const contacts = staffAssignments.get(staffId) ?? [];
      if (contacts.length === 0) {
        throw new Error('No contacts assigned to this staff member');
      }

      const stops: RouteStop[] = contacts.map((contact, index) => ({
        contactId: contact.id,
        contact,
        order: index,
        status: 'pending' as const,
      }));

      const routeData = {
        name: routeName,
        date: selectedDate,
        assigneeId: staffId,
        assigneeName: member.staff.displayName,
        stops,
        status: 'planned' as const,
      };

      setIsSaving(true);
      try {
        let route: Route;
        if (member.route) {
          route = await updateRoute(member.route.id, routeData);
        } else {
          route = await createRoute(routeData);
        }
        refreshRoutes();
        return route;
      } catch (err) {
        setError(err instanceof Error ? err : new Error('Failed to save route'));
        throw err;
      } finally {
        setIsSaving(false);
      }
    },
    [workingTeam, staffAssignments, selectedDate, createRoute, updateRoute, refreshRoutes]
  );

  const saveAllRoutes = useCallback(async (): Promise<Route[]> => {
    const savedRoutes: Route[] = [];
    setIsSaving(true);
    setError(null);

    try {
      for (const member of workingTeam) {
        const contacts = staffAssignments.get(member.staff.id) ?? [];
        if (contacts.length === 0) continue;

        const routeName = `${member.staff.displayName} - ${selectedDate.toLocaleDateString()}`;
        const route = await saveSingleRoute(member.staff.id, routeName);
        savedRoutes.push(route);
      }

      refreshRoutes();
      return savedRoutes;
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to save routes'));
      throw err;
    } finally {
      setIsSaving(false);
    }
  }, [workingTeam, staffAssignments, selectedDate, saveSingleRoute, refreshRoutes]);

  // ============================================
  // Validation
  // ============================================

  const conflicts = useMemo(() => {
    const result: Array<{ staffId: string; type: string; message: string }> = [];

    workingTeam.forEach((member) => {
      // Check for schedule conflicts
      if (member.schedule?.maxStopsPerDay) {
        const stopCount = member.selectedContacts.length;
        if (stopCount > member.schedule.maxStopsPerDay) {
          result.push({
            staffId: member.staff.id,
            type: 'capacity',
            message: `${member.staff.displayName} has ${stopCount} stops (max: ${member.schedule.maxStopsPerDay})`,
          });
        }
      }

      // Check for calendar conflicts
      if (member.calendarConflicts.length > 0) {
        result.push({
          staffId: member.staff.id,
          type: 'calendar',
          message: `${member.staff.displayName} has calendar conflicts`,
        });
      }
    });

    return result;
  }, [workingTeam]);

  const validatePlan = useCallback((): boolean => {
    return conflicts.length === 0;
  }, [conflicts]);

  // ============================================
  // Refresh
  // ============================================

  const refresh = useCallback(() => {
    refreshSchedules();
    refreshTerritories();
    refreshContacts();
    refreshMembers();
    refreshRoutes();
  }, [refreshSchedules, refreshTerritories, refreshContacts, refreshMembers, refreshRoutes]);

  return {
    selectedDate,
    workingTeam,
    unassignedContacts,
    allContacts: geocodedContacts,
    isLoading,
    isSaving,
    error,
    setSelectedDate,
    assignContactToStaff,
    removeContactFromStaff,
    moveContactBetweenStaff,
    autoAssignUnassigned,
    clearStaffRoute,
    clearAllRoutes,
    optimizeStaffRoute,
    saveAllRoutes,
    saveSingleRoute,
    conflicts,
    validatePlan,
    refresh,
  };
}

export default useTeamRouteBuilder;
