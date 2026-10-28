/**
 * Staff Schedules Page
 * Manage work schedules for all staff members
 */

import { useState, useCallback, useMemo } from 'react';
import {
  useStaffSchedules,
  useStaffScheduleMutations,
  useTeamMembers,
  useModal,
  createDefaultWeeklyPatterns,
} from '../hooks';
import { WeeklyPatternEditor, ExceptionList } from '../components/schedules';
import { ConfirmDialog } from '../components/modals';
import { Button, Card, EmptyState, PageHeader, PageLayout } from '../components/ui';
import type { StaffSchedule, WeeklySchedulePattern, ScheduleException } from '../types/models';
import type { TeamMember } from '../hooks/useTeamMembers';
import './styles/staff-schedules-page.css';

export function StaffSchedulesPage() {
  const { members, isLoading: membersLoading } = useTeamMembers();
  const { schedules, isLoading: schedulesLoading, refresh } = useStaffSchedules();
  const {
    createSchedule,
    updateSchedule,
    deleteSchedule,
    updateWeeklyPatterns,
    addException,
    removeException,
    isLoading: mutationLoading,
  } = useStaffScheduleMutations();

  const [selectedStaffId, setSelectedStaffId] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const deleteModal = useModal<string>();

  const isLoading = membersLoading || schedulesLoading;

  // Get schedule for selected staff
  const selectedSchedule = useMemo(() => {
    if (!selectedStaffId) return null;
    return schedules.find((s) => s.staffId === selectedStaffId) ?? null;
  }, [selectedStaffId, schedules]);

  // Get selected staff member
  const selectedMember = useMemo(() => {
    if (!selectedStaffId) return null;
    return members.find((m) => m.id === selectedStaffId) ?? null;
  }, [selectedStaffId, members]);

  // Filter members by search
  const filteredMembers = useMemo(() => {
    if (!searchQuery) return members;
    const query = searchQuery.toLowerCase();
    return members.filter(
      (m) =>
        m.displayName?.toLowerCase().includes(query) ||
        m.email?.toLowerCase().includes(query)
    );
  }, [members, searchQuery]);

  // Check if member has a schedule
  const hasSchedule = useCallback(
    (staffId: string) => schedules.some((s) => s.staffId === staffId),
    [schedules]
  );

  // Create schedule for staff member
  const handleCreateSchedule = useCallback(
    async (member: TeamMember) => {
      try {
        await createSchedule({
          staffId: member.id,
          staffName: member.displayName,
          staffEmail: member.email,
          weeklyPatterns: createDefaultWeeklyPatterns(),
          exceptions: [],
        });
        setSelectedStaffId(member.id);
        refresh();
      } catch {
        // Error handled in hook
      }
    },
    [createSchedule, refresh]
  );

  // Update weekly patterns
  const handlePatternsChange = useCallback(
    async (patterns: WeeklySchedulePattern[]) => {
      if (!selectedSchedule) return;
      try {
        await updateWeeklyPatterns(selectedSchedule.id, patterns);
        refresh();
      } catch {
        // Error handled in hook
      }
    },
    [selectedSchedule, updateWeeklyPatterns, refresh]
  );

  // Add exception
  const handleAddException = useCallback(
    async (exception: Omit<ScheduleException, 'id'>) => {
      if (!selectedSchedule) return;
      try {
        await addException(selectedSchedule.id, exception);
        refresh();
      } catch {
        // Error handled in hook
      }
    },
    [selectedSchedule, addException, refresh]
  );

  // Remove exception
  const handleRemoveException = useCallback(
    async (exceptionId: string) => {
      if (!selectedSchedule) return;
      try {
        await removeException(selectedSchedule.id, exceptionId);
        refresh();
      } catch {
        // Error handled in hook
      }
    },
    [selectedSchedule, removeException, refresh]
  );

  // Update schedule settings
  const handleUpdateSettings = useCallback(
    async (updates: Partial<StaffSchedule>) => {
      if (!selectedSchedule) return;
      try {
        await updateSchedule(selectedSchedule.id, updates);
        refresh();
      } catch {
        // Error handled in hook
      }
    },
    [selectedSchedule, updateSchedule, refresh]
  );

  // Delete schedule
  const handleDeleteSchedule = useCallback(async () => {
    const scheduleId = deleteModal.data;
    if (!scheduleId) return;
    try {
      await deleteSchedule(scheduleId);
      if (selectedSchedule?.id === scheduleId) {
        setSelectedStaffId(null);
      }
      deleteModal.close();
      refresh();
    } catch {
      // Error handled in hook
    }
  }, [deleteModal, deleteSchedule, selectedSchedule, refresh]);

  if (isLoading) {
    return (
      <PageLayout width="wide" className="staff-schedules-page">
        <PageHeader
          eyebrow="Operations"
          title="Staff Schedules"
          subtitle="Manage weekly capacity, limits, and exceptions for every working rep."
        />
        <Card padding="lg" className="staff-schedules-page__status-card">
          <p>Loading staff schedules...</p>
        </Card>
      </PageLayout>
    );
  }

  return (
    <PageLayout width="wide" className="staff-schedules-page">
      <PageHeader
        eyebrow="Operations"
        title="Staff Schedules"
        subtitle="Set availability, route limits, and exceptions so routing and approval tools reflect real working capacity."
        actions={(
          <Button variant="ghost" onClick={refresh} disabled={mutationLoading}>
            Refresh
          </Button>
        )}
      />

      <Card tone="accent" className="staff-schedules-page__hero">
        <div className="staff-schedules-page__hero-copy">
          <h2>Keep staffing and route capacity aligned.</h2>
          <p>
            Review who has active schedules, edit day-by-day working windows, and
            capture exceptions before route planning or approvals begin.
          </p>
        </div>
        <div className="staff-schedules-page__hero-stats" aria-label="Staff schedule summary">
          <div>
            <span>Team members</span>
            <strong>{members.length}</strong>
          </div>
          <div>
            <span>Active schedules</span>
            <strong>{schedules.length}</strong>
          </div>
          <div>
            <span>Focused staff</span>
            <strong>{selectedMember?.displayName || 'None'}</strong>
          </div>
        </div>
      </Card>

      <div className="staff-schedules-layout">
        <Card className="staff-schedules-page__list-card">
          <aside className="staff-list-panel">
            <div className="staff-list-header">
              <input
                type="text"
                placeholder="Search staff..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="search-input"
              />
            </div>

            <div className="staff-list">
              {filteredMembers.map((member) => {
                const memberHasSchedule = hasSchedule(member.id);
                const isSelected = selectedStaffId === member.id;

                return (
                  <div
                    key={member.id}
                    className={`staff-list-item ${isSelected ? 'staff-list-item--selected' : ''}`}
                    onClick={() => setSelectedStaffId(member.id)}
                  >
                    <div className="staff-list-item__avatar">
                      {member.displayName?.charAt(0)?.toUpperCase() ?? 'U'}
                    </div>
                    <div className="staff-list-item__info">
                      <div className="staff-list-item__name">{member.displayName}</div>
                      <div className="staff-list-item__email">{member.email}</div>
                    </div>
                    <div className="staff-list-item__status">
                      {memberHasSchedule ? (
                        <span className="status-badge status-badge--success">Scheduled</span>
                      ) : (
                        <span className="status-badge status-badge--muted">No Schedule</span>
                      )}
                    </div>
                  </div>
                );
              })}

              {filteredMembers.length === 0 && (
                <div className="staff-list-empty">
                  {searchQuery ? 'No staff match your search' : 'No staff members found'}
                </div>
              )}
            </div>
          </aside>
        </Card>

        <Card className="staff-schedules-page__editor-card">
          <main className="schedule-editor-panel">
            {!selectedStaffId ? (
              <EmptyState
                title="Select a staff member"
                description="Choose someone from the team list to edit weekly patterns, route limits, and schedule exceptions."
              />
            ) : !selectedSchedule ? (
              <EmptyState
                title={`${selectedMember?.displayName || 'This staff member'} has no schedule yet`}
                description="Create a default schedule first, then refine timezones, route caps, and daily availability."
                actions={(
                  <Button
                    onClick={() => selectedMember && handleCreateSchedule(selectedMember)}
                    disabled={mutationLoading}
                  >
                    {mutationLoading ? 'Creating...' : 'Create Schedule'}
                  </Button>
                )}
              />
            ) : (
              <div className="schedule-editor">
                <div className="schedule-editor__header">
                  <h2>{selectedMember?.displayName}'s Schedule</h2>
                  <Button
                    variant="danger"
                    size="sm"
                    onClick={() => deleteModal.open(selectedSchedule.id)}
                    disabled={mutationLoading}
                  >
                    Delete Schedule
                  </Button>
                </div>

                {/* Schedule Settings */}
                <section className="schedule-section">
                  <h3>Settings</h3>
                  <div className="schedule-settings-grid">
                    <div className="form-group">
                      <label>Max Stops Per Day</label>
                      <input
                        type="number"
                        min="1"
                        max="50"
                        value={selectedSchedule.maxStopsPerDay ?? ''}
                        onChange={(e) =>
                          handleUpdateSettings({
                            maxStopsPerDay: e.target.value ? parseInt(e.target.value) : undefined,
                          })
                        }
                        placeholder="No limit"
                        disabled={mutationLoading}
                      />
                    </div>

                    <div className="form-group">
                      <label>Max Driving Minutes/Day</label>
                      <input
                        type="number"
                        min="30"
                        max="720"
                        step="30"
                        value={selectedSchedule.maxDrivingMinutesPerDay ?? ''}
                        onChange={(e) =>
                          handleUpdateSettings({
                            maxDrivingMinutesPerDay: e.target.value
                              ? parseInt(e.target.value)
                              : undefined,
                          })
                        }
                        placeholder="No limit"
                        disabled={mutationLoading}
                      />
                    </div>

                    <div className="form-group">
                      <label>Home Base Address</label>
                      <input
                        type="text"
                        value={selectedSchedule.homeBaseAddress ?? ''}
                        onChange={(e) =>
                          handleUpdateSettings({ homeBaseAddress: e.target.value || undefined })
                        }
                        placeholder="Starting location for routes"
                        disabled={mutationLoading}
                      />
                    </div>

                    <div className="form-group">
                      <label>Timezone</label>
                      <select
                        value={selectedSchedule.timezone}
                        onChange={(e) => handleUpdateSettings({ timezone: e.target.value })}
                        disabled={mutationLoading}
                      >
                        <option value="America/New_York">Eastern Time</option>
                        <option value="America/Chicago">Central Time</option>
                        <option value="America/Denver">Mountain Time</option>
                        <option value="America/Los_Angeles">Pacific Time</option>
                        <option value="America/Phoenix">Arizona Time</option>
                      </select>
                    </div>
                  </div>
                </section>

                <section className="schedule-section">
                  <WeeklyPatternEditor
                    patterns={selectedSchedule.weeklyPatterns}
                    onChange={handlePatternsChange}
                    disabled={mutationLoading}
                  />
                </section>

                <section className="schedule-section">
                  <ExceptionList
                    exceptions={selectedSchedule.exceptions}
                    onAdd={handleAddException}
                    onRemove={handleRemoveException}
                    disabled={mutationLoading}
                  />
                </section>
              </div>
            )}
          </main>
        </Card>
      </div>

      <ConfirmDialog
        isOpen={deleteModal.isOpen}
        onCancel={deleteModal.close}
        onConfirm={handleDeleteSchedule}
        title="Delete Schedule"
        message="Are you sure you want to delete this schedule? This action cannot be undone."
        confirmText={mutationLoading ? 'Deleting...' : 'Delete'}
        variant="danger"
      />
    </PageLayout>
  );
}

export default StaffSchedulesPage;
