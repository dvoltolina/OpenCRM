/**
 * Team Route Planning Page
 * Multi-staff route planning with drag-drop assignment
 *
 * Features:
 * - View all working staff for a selected date
 * - Drag contacts to assign to staff routes
 * - Auto-assign based on territories
 * - Save all routes at once
 */

import { useState, useCallback } from 'react';
import {
  DndContext,
  closestCenter,
  KeyboardSensor,
  PointerSensor,
  useSensor,
  useSensors,
  type DragEndEvent,
  DragOverlay,
  type DragStartEvent,
} from '@dnd-kit/core';
import {
  SortableContext,
  sortableKeyboardCoordinates,
  useSortable,
  verticalListSortingStrategy,
} from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import { useTeamRouteBuilder, type WorkingStaffMember } from '../hooks';
import { ConfirmDialog } from '../components/modals';
import { Button, Card, EmptyState, PageHeader, PageLayout, Toolbar } from '../components/ui';
import { useModal } from '../hooks';
import type { Client } from '../types/models';
import './styles/team-route-planning-page.css';

// ============================================
// Draggable Contact Card
// ============================================

interface DraggableContactProps {
  contact: Client;
  isDragging?: boolean;
}

function DraggableContact({ contact, isDragging }: DraggableContactProps) {
  return (
    <div
      className={`contact-card ${isDragging ? 'contact-card--dragging' : ''}`}
      style={{ opacity: isDragging ? 0.5 : 1 }}
    >
      <div className="contact-card__name">
        {contact.firstName} {contact.lastName}
      </div>
      {contact.companyName && (
        <div className="contact-card__company">{contact.companyName}</div>
      )}
      {contact.address?.city && (
        <div className="contact-card__location">
          {contact.address.city}, {contact.address.state} {contact.address.zipCode}
        </div>
      )}
    </div>
  );
}

// ============================================
// Sortable Contact in Staff Column
// ============================================

interface SortableContactProps {
  contact: Client;
  index: number;
  onRemove: (contactId: string) => void;
}

function SortableContact({ contact, index, onRemove }: SortableContactProps) {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({ id: contact.id });

  const style: React.CSSProperties = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.5 : 1,
  };

  return (
    <div
      ref={setNodeRef}
      style={style}
      className="route-stop-card"
      {...attributes}
      {...listeners}
    >
      <span className="route-stop-card__number">{index + 1}</span>
      <div className="route-stop-card__content">
        <div className="route-stop-card__name">
          {contact.firstName} {contact.lastName}
        </div>
        {contact.companyName && (
          <div className="route-stop-card__company">{contact.companyName}</div>
        )}
      </div>
      <button
        className="route-stop-card__remove"
        onClick={(e) => {
          e.stopPropagation();
          onRemove(contact.id);
        }}
      >
        &times;
      </button>
    </div>
  );
}

// ============================================
// Staff Route Column
// ============================================

interface StaffColumnProps {
  member: WorkingStaffMember;
  onRemoveContact: (contactId: string, staffId: string) => void;
  onClearRoute: (staffId: string) => void;
  onSaveRoute: (staffId: string) => void;
  hasConflict?: boolean;
}

function StaffColumn({
  member,
  onRemoveContact,
  onClearRoute,
  onSaveRoute,
  hasConflict,
}: StaffColumnProps) {
  const { staff, schedule, territories, selectedContacts } = member;

  const handleRemove = useCallback(
    (contactId: string) => {
      onRemoveContact(contactId, staff.id);
    },
    [onRemoveContact, staff.id]
  );

  return (
    <div className={`staff-column ${hasConflict ? 'staff-column--conflict' : ''}`}>
      <div className="staff-column__header">
        <div className="staff-column__avatar">
          {staff.displayName?.charAt(0)?.toUpperCase() ?? 'U'}
        </div>
        <div className="staff-column__info">
          <div className="staff-column__name">{staff.displayName}</div>
          <div className="staff-column__meta">
            {selectedContacts.length} stops
            {schedule?.maxStopsPerDay && ` / ${schedule.maxStopsPerDay} max`}
          </div>
          {territories.length > 0 && (
            <div className="staff-column__territories">
              {territories.map((t) => (
                <span
                  key={t.id}
                  className="territory-badge"
                  style={{ backgroundColor: t.colorHex }}
                >
                  {t.name}
                </span>
              ))}
            </div>
          )}
        </div>
        {hasConflict && <span className="conflict-badge">!</span>}
      </div>

      <div className="staff-column__drop-zone" data-staff-id={staff.id}>
        <SortableContext
          items={selectedContacts.map((c) => c.id)}
          strategy={verticalListSortingStrategy}
        >
          {selectedContacts.length === 0 ? (
            <div className="staff-column__empty">
              Drag contacts here
            </div>
          ) : (
            selectedContacts.map((contact, index) => (
              <SortableContact
                key={contact.id}
                contact={contact}
                index={index}
                onRemove={handleRemove}
              />
            ))
          )}
        </SortableContext>
      </div>

      <div className="staff-column__actions">
        <Button
          variant="ghost"
          size="sm"
          onClick={() => onClearRoute(staff.id)}
          disabled={selectedContacts.length === 0}
        >
          Clear
        </Button>
        <Button
          size="sm"
          onClick={() => onSaveRoute(staff.id)}
          disabled={selectedContacts.length === 0}
        >
          Save
        </Button>
      </div>
    </div>
  );
}

// ============================================
// Unassigned Contacts Pool
// ============================================

interface UnassignedPoolProps {
  contacts: Client[];
  searchQuery: string;
  onSearchChange: (query: string) => void;
}

function UnassignedPool({ contacts, searchQuery, onSearchChange }: UnassignedPoolProps) {
  const filteredContacts = contacts.filter((c) => {
    if (!searchQuery) return true;
    const query = searchQuery.toLowerCase();
    return (
      c.firstName?.toLowerCase().includes(query) ||
      c.lastName?.toLowerCase().includes(query) ||
      c.companyName?.toLowerCase().includes(query) ||
      c.address?.city?.toLowerCase().includes(query) ||
      c.address?.zipCode?.includes(query)
    );
  });

  return (
    <div className="unassigned-pool">
      <div className="unassigned-pool__header">
        <h3>Unassigned Contacts ({contacts.length})</h3>
        <input
          type="text"
          placeholder="Search contacts..."
          value={searchQuery}
          onChange={(e) => onSearchChange(e.target.value)}
          className="search-input"
        />
      </div>
      <div className="unassigned-pool__list">
        {filteredContacts.map((contact) => (
          <div key={contact.id} data-contact-id={contact.id}>
            <DraggableContact contact={contact} />
          </div>
        ))}
        {filteredContacts.length === 0 && (
          <div className="unassigned-pool__empty">
            {searchQuery ? 'No contacts match your search' : 'All contacts assigned'}
          </div>
        )}
      </div>
    </div>
  );
}

// ============================================
// Main Page Component
// ============================================

export function TeamRoutePlanningPage() {
  const [searchQuery, setSearchQuery] = useState('');
  const [activeContact, setActiveContact] = useState<Client | null>(null);
  const saveAllModal = useModal();

  const {
    selectedDate,
    setSelectedDate,
    workingTeam,
    unassignedContacts,
    allContacts,
    isLoading,
    isSaving,
    error,
    assignContactToStaff,
    removeContactFromStaff,
    moveContactBetweenStaff,
    autoAssignUnassigned,
    clearStaffRoute,
    clearAllRoutes,
    saveAllRoutes,
    saveSingleRoute,
    conflicts,
    refresh,
  } = useTeamRouteBuilder();

  // Drag-and-drop sensors
  const sensors = useSensors(
    useSensor(PointerSensor, {
      activationConstraint: { distance: 8 },
    }),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates,
    })
  );

  const handleDragStart = useCallback((event: DragStartEvent) => {
    const contactId = event.active.id as string;
    const contact = allContacts.find((c) => c.id === contactId);
    setActiveContact(contact ?? null);
  }, [allContacts]);

  const handleDragEnd = useCallback(
    (event: DragEndEvent) => {
      setActiveContact(null);

      const { active, over } = event;
      if (!over) return;

      const contactId = active.id as string;
      const overId = over.id as string;

      // Find where the contact is being dropped
      // Check if dropping over a staff column
      const staffColumn = over.data?.current?.sortable?.containerId;

      if (staffColumn) {
        // Moving within or between staff columns
        const fromStaff = workingTeam.find((m) =>
          m.selectedContacts.some((c) => c.id === contactId)
        );
        const toStaff = workingTeam.find((m) => m.staff.id === staffColumn);

        if (fromStaff && toStaff && fromStaff.staff.id !== toStaff.staff.id) {
          moveContactBetweenStaff(contactId, fromStaff.staff.id, toStaff.staff.id);
        }
      } else {
        // Dropping on a staff column from unassigned
        const targetStaff = workingTeam.find((m) =>
          m.selectedContacts.some((c) => c.id === overId)
        );
        if (targetStaff) {
          assignContactToStaff(contactId, targetStaff.staff.id);
        }
      }
    },
    [workingTeam, assignContactToStaff, moveContactBetweenStaff]
  );

  const handleSaveAll = useCallback(async () => {
    try {
      await saveAllRoutes();
      saveAllModal.close();
    } catch {
      // Error is handled in hook
    }
  }, [saveAllRoutes, saveAllModal]);

  const handleSaveOne = useCallback(
    async (staffId: string) => {
      const member = workingTeam.find((m) => m.staff.id === staffId);
      if (!member) return;

      const routeName = `${member.staff.displayName} - ${selectedDate.toLocaleDateString()}`;
      try {
        await saveSingleRoute(staffId, routeName);
      } catch {
        // Error is handled in hook
      }
    },
    [workingTeam, selectedDate, saveSingleRoute]
  );

  const conflictStaffIds = new Set(conflicts.map((c) => c.staffId));
  const totalAssignedStops = workingTeam.reduce((sum, member) => sum + member.selectedContacts.length, 0);

  if (isLoading) {
    return (
      <PageLayout width="wide" className="team-route-planning-page">
        <PageHeader
          eyebrow="Field Routes"
          title="Team Route Planning"
          subtitle="Distribute contact coverage across the staff working that day."
        />
        <Card padding="lg" className="team-route-planning-page__status-card">
          <p>Loading team route data...</p>
        </Card>
      </PageLayout>
    );
  }

  return (
    <PageLayout width="wide" className="team-route-planning-page">
      <PageHeader
        eyebrow="Field Routes"
        title="Team Route Planning"
        subtitle="Assign daily contact coverage across scheduled staff, then save routes in one pass."
        actions={(
          <div className="team-route-planning-page__header-actions">
            <label className="team-route-planning-page__date-field">
              <span>Date</span>
              <input
                type="date"
                value={selectedDate.toISOString().split('T')[0]}
                onChange={(e) => setSelectedDate(new Date(e.target.value))}
                className="date-input"
              />
            </label>
            <Button
              variant="secondary"
              onClick={autoAssignUnassigned}
              disabled={unassignedContacts.length === 0}
            >
              Auto-Assign
            </Button>
            <Button variant="ghost" onClick={clearAllRoutes}>
              Clear All
            </Button>
            <Button
              onClick={() => saveAllModal.open()}
              disabled={isSaving || workingTeam.every((m) => m.selectedContacts.length === 0)}
            >
              {isSaving ? 'Saving...' : 'Save All Routes'}
            </Button>
          </div>
        )}
      />

      <Card tone="accent" className="team-route-planning-page__hero">
        <div className="team-route-planning-page__hero-copy">
          <h2>Balance assignments before routes hit the field.</h2>
          <p>
            Drag unassigned contacts onto scheduled reps, watch for territory or capacity
            conflicts, and save the day’s routes without leaving the planner.
          </p>
        </div>
        <div className="team-route-planning-page__hero-stats" aria-label="Team routing summary">
          <div>
            <span>Scheduled staff</span>
            <strong>{workingTeam.length}</strong>
          </div>
          <div>
            <span>Assigned stops</span>
            <strong>{totalAssignedStops}</strong>
          </div>
          <div>
            <span>Unassigned</span>
            <strong>{unassignedContacts.length}</strong>
          </div>
        </div>
      </Card>

      {error && (
        <Card className="team-route-planning-page__banner-card">
          <EmptyState
            tone="danger"
            title="Route builder unavailable"
            description={error.message}
            actions={(
              <Button variant="secondary" onClick={refresh}>
                Retry
              </Button>
            )}
          />
        </Card>
      )}

      {conflicts.length > 0 && (
        <Card className="team-route-planning-page__banner-card team-route-planning-page__banner-card--warning">
          <div className="conflicts-banner">
            <strong>Conflicts detected</strong>
            <ul>
              {conflicts.map((c, i) => (
                <li key={i}>{c.message}</li>
              ))}
            </ul>
          </div>
        </Card>
      )}

      <DndContext
        sensors={sensors}
        collisionDetection={closestCenter}
        onDragStart={handleDragStart}
        onDragEnd={handleDragEnd}
      >
        <div className="team-route-layout">
          <Card className="team-route-planning-page__pool-card">
            <UnassignedPool
              contacts={unassignedContacts}
              searchQuery={searchQuery}
              onSearchChange={setSearchQuery}
            />
          </Card>

          <Card padding="sm" className="team-route-planning-page__board-card">
            <Toolbar
              className="team-route-planning-page__toolbar"
              start={(
                <div className="team-route-planning-page__section-heading">
                  <h2>Staff Routes</h2>
                  <p>Save an individual route or commit the full day once assignments are balanced.</p>
                </div>
              )}
              end={(
                <span className="team-route-planning-page__toolbar-meta">
                  {conflicts.length > 0 ? `${conflicts.length} warning${conflicts.length === 1 ? '' : 's'}` : 'No conflicts'}
                </span>
              )}
            />

            <div className="staff-columns">
              {workingTeam.length === 0 ? (
                <EmptyState
                  title="No scheduled staff"
                  description="Set up staff schedules to make team route assignment available for this date."
                />
              ) : (
                workingTeam.map((member) => (
                  <StaffColumn
                    key={member.staff.id}
                    member={member}
                    onRemoveContact={removeContactFromStaff}
                    onClearRoute={clearStaffRoute}
                    onSaveRoute={handleSaveOne}
                    hasConflict={conflictStaffIds.has(member.staff.id)}
                  />
                ))
              )}
            </div>
          </Card>
        </div>

        <DragOverlay>
          {activeContact && <DraggableContact contact={activeContact} isDragging />}
        </DragOverlay>
      </DndContext>

      <ConfirmDialog
        isOpen={saveAllModal.isOpen}
        onCancel={saveAllModal.close}
        onConfirm={handleSaveAll}
        title="Save All Routes"
        message={`Save routes for ${workingTeam.filter((m) => m.selectedContacts.length > 0).length} staff members?`}
        confirmText={isSaving ? 'Saving...' : 'Save All'}
        variant="info"
      />
    </PageLayout>
  );
}

export default TeamRoutePlanningPage;
