import { useEffect, useMemo, useState, type CSSProperties } from 'react';

import { useBusinessContext } from '../hooks/useBusinessContext';
import { useGroupSessions } from '../hooks/useGroupSessions';
import type { GroupSession } from '../types/models';
import { AttendeePanel, SessionCard, SessionDialog } from './groupSessions/GroupSessionsComponents';
import { THEME, SPACING } from './dashboard/DashboardComponents';

export function GroupSessionsPage() {
  const { businessId, userId } = useBusinessContext();
  const {
    sessions,
    attendeesBySession,
    clients,
    staff,
    services,
    locations,
    loading,
    saving,
    error,
    loadAttendees,
    saveSession,
    deleteSession,
    addAttendee,
    updateAttendee,
    removeAttendee,
  } = useGroupSessions(businessId, userId);

  const [selectedSessionId, setSelectedSessionId] = useState<string | null>(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingSession, setEditingSession] = useState<GroupSession | null>(null);

  const selectedSession = sessions.find((session) => session.id === selectedSessionId) ?? null;
  const attendees = selectedSession ? attendeesBySession[selectedSession.id] ?? [] : [];

  useEffect(() => {
    if (!selectedSessionId && sessions.length) {
      setSelectedSessionId(sessions[0].id);
    }
  }, [selectedSessionId, sessions]);

  useEffect(() => {
    if (selectedSession) {
      void loadAttendees(selectedSession.id);
    }
  }, [selectedSession, loadAttendees]);

  const serviceLookup = useMemo(
    () => Object.fromEntries(services.map((service) => [service.id, service])),
    [services],
  );
  const staffLookup = useMemo(
    () => Object.fromEntries(staff.map((member) => [member.id, member])),
    [staff],
  );
  const locationLookup = useMemo(
    () => Object.fromEntries(locations.map((location) => [location.id, location])),
    [locations],
  );

  const openCreateDialog = () => {
    setEditingSession(null);
    setDialogOpen(true);
  };

  const openEditDialog = (session: GroupSession) => {
    setEditingSession(session);
    setDialogOpen(true);
  };

  const closeDialog = () => {
    setDialogOpen(false);
    setEditingSession(null);
  };

  const handleSaveSession = async (input: Parameters<typeof saveSession>[0], sessionId?: string) => {
    await saveSession(input, sessionId);
    closeDialog();
  };

  const handleDeleteSession = async (session: GroupSession) => {
    if (!confirm(`Cancel ${session.title}?`)) return;
    await deleteSession(session.id);
    if (selectedSessionId === session.id) {
      setSelectedSessionId(null);
    }
  };

  const handleAddAttendee = async (attendee: Parameters<typeof addAttendee>[1]) => {
    if (!selectedSession) return;
    await addAttendee(selectedSession.id, attendee);
    await loadAttendees(selectedSession.id);
  };

  const handleUpdateAttendee = async (
    attendeeId: string,
    updates: Parameters<typeof updateAttendee>[2],
  ) => {
    if (!selectedSession) return;
    await updateAttendee(selectedSession.id, attendeeId, updates);
    await loadAttendees(selectedSession.id);
  };

  const handleRemoveAttendee = async (attendeeId: string) => {
    if (!selectedSession) return;
    await removeAttendee(selectedSession.id, attendeeId);
    await loadAttendees(selectedSession.id);
  };

  // Professional styles following design system
  const pageContainerStyle: CSSProperties = {
    minHeight: '100vh',
    background: `linear-gradient(180deg, ${THEME.colorBgGradientStart} 0%, ${THEME.colorBgGradientEnd} 100%)`,
    padding: SPACING.xl,
  };

  const headerStyle: CSSProperties = {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: SPACING.xl,
    gap: SPACING.lg,
  };

  const headerTextStyle: CSSProperties = {
    flex: 1,
  };

  const eyebrowStyle: CSSProperties = {
    fontSize: 11,
    fontWeight: 600,
    color: THEME.colorAccent,
    textTransform: 'uppercase',
    letterSpacing: '0.1em',
    margin: 0,
  };

  const titleStyle: CSSProperties = {
    fontSize: 26,
    fontWeight: 700,
    color: THEME.colorText,
    margin: `${SPACING.sm}px 0 0`,
    lineHeight: 1.2,
  };

  const subtitleStyle: CSSProperties = {
    fontSize: 14,
    color: THEME.colorTextMuted,
    margin: `${SPACING.xs}px 0 0`,
    lineHeight: 1.5,
  };

  const headerActionsStyle: CSSProperties = {
    display: 'flex',
    gap: SPACING.sm,
    flexShrink: 0,
  };

  const alertPanelStyle: CSSProperties = {
    padding: SPACING.lg,
    background: THEME.colorBgPanelGradient,
    borderRadius: THEME.radius,
    boxShadow: THEME.shadow,
    border: `1px solid ${THEME.colorBorder}`,
    marginBottom: SPACING.lg,
  };

  const emptyPanelStyle: CSSProperties = {
    padding: SPACING.xl,
    background: THEME.colorBgPanelGradient,
    borderRadius: THEME.radius,
    boxShadow: THEME.shadow,
    border: `1px solid ${THEME.colorBorder}`,
    textAlign: 'center',
  };

  const gridStyle: CSSProperties = {
    display: 'grid',
    gridTemplateColumns: 'repeat(2, 1fr)',
    gap: SPACING.lg,
    marginBottom: SPACING.lg,
  };

  const mutedTextStyle: CSSProperties = {
    color: THEME.colorTextMuted,
    margin: 0,
  };

  return (
    <section style={pageContainerStyle}>
      <header style={headerStyle}>
        <div style={headerTextStyle}>
          <p style={eyebrowStyle}>Programs</p>
          <h1 style={titleStyle}>Group Sessions / Classes</h1>
          <p style={subtitleStyle}>
            Plan recurring classes, track attendees, and manage waitlists for multi-client sessions.
          </p>
        </div>
        <div style={headerActionsStyle}>
          <button
            className="button button--ghost"
            type="button"
            disabled={!selectedSession}
            onClick={() => selectedSession && openEditDialog(selectedSession)}
          >
            Edit selected
          </button>
          <button className="button button--primary" type="button" onClick={openCreateDialog}>
            New session
          </button>
        </div>
      </header>

      {error && (
        <div style={alertPanelStyle}>
          <p style={mutedTextStyle}>{error}</p>
        </div>
      )}

      {loading ? (
        <div style={emptyPanelStyle}>
          <p style={mutedTextStyle}>Loading group sessions…</p>
        </div>
      ) : sessions.length === 0 ? (
        <div style={emptyPanelStyle}>
          <p style={mutedTextStyle}>No group sessions yet. Create one to get started.</p>
        </div>
      ) : (
        <div style={gridStyle}>
          {sessions.map((session) => (
            <SessionCard
              key={session.id}
              session={session}
              serviceLabel={serviceLookup[session.serviceId]?.name ?? 'Service'}
              locationLabel={session.locationId ? locationLookup[session.locationId]?.name : undefined}
              providerLabels={session.providerIds.map((id) => staffLookup[id]?.displayName ?? id)}
              waitlistCount={session.waitlistIds?.length ?? 0}
              selected={session.id === selectedSessionId}
              onSelect={() => setSelectedSessionId(session.id)}
              onEdit={() => openEditDialog(session)}
              onDelete={() => handleDeleteSession(session)}
            />
          ))}
        </div>
      )}

      {selectedSession && (
        <AttendeePanel
          session={selectedSession}
          attendees={attendees}
          clients={clients}
          onAddAttendee={handleAddAttendee}
          onUpdateAttendee={handleUpdateAttendee}
          onRemoveAttendee={handleRemoveAttendee}
        />
      )}

      {dialogOpen && (
        <SessionDialog
          session={editingSession}
          services={services}
          staff={staff}
          locations={locations}
          onClose={closeDialog}
          onSubmit={(input) => handleSaveSession(input, editingSession?.id)}
        />
      )}

      {saving && (
        <div style={{ ...alertPanelStyle, marginTop: SPACING.md }}>
          <p style={mutedTextStyle}>Saving changes…</p>
        </div>
      )}
    </section>
  );
}
