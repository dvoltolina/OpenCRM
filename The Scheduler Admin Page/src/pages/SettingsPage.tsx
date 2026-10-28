import { useEffect, useState, type CSSProperties } from 'react';
import { useNavigate } from 'react-router-dom';
import { isDemoMode } from '../config/demo';
import { useBusinessContext } from '../hooks/useBusinessContext';
import { useFeatureFlags } from '../hooks/useFeatureFlags';
import { useIntegrationsPanel } from '../hooks/useIntegrationsPanel';
import { useAdvancedSettings } from '../hooks/useAdvancedSettings';
import type { FeatureFlags, WorkspaceInfo } from '../types/models';
import { getWorkspaceInfo } from '../data/workspace';
import { CalendarSyncPanel } from './settings/CalendarSyncPanel';
import { FeatureFlagsPanel } from './settings/FeatureFlagsPanel';
import { StaffIntegrationsPanel } from './settings/StaffIntegrationsPanel';
import { TelehealthPanel } from './settings/TelehealthPanel';
import { AdvancedSettingsPanel } from './settings/AdvancedSettingsPanel';
import { ActivityLogPanel } from '../components/ActivityLogPanel';
import { THEME, SPACING } from './dashboard/DashboardComponents';

export function SettingsPage() {
  const navigate = useNavigate();
  const { businessId, userId, role } = useBusinessContext();
  const integrations = useIntegrationsPanel(businessId, userId);
  const featureFlagsState = useFeatureFlags(businessId);
  const featureFlags = featureFlagsState.flags;
  const [workspaceInfo, setWorkspaceInfo] = useState<WorkspaceInfo | null>(null);
  const [workspaceLoading, setWorkspaceLoading] = useState(false);
  const [workspaceError, setWorkspaceError] = useState<string | null>(null);

  const loadWorkspaceInfo = () => {
    if (!businessId) {
      setWorkspaceInfo(null);
      setWorkspaceError('No workspace context available');
      return;
    }

    setWorkspaceLoading(true);
    setWorkspaceError(null);
    getWorkspaceInfo(businessId)
      .then(setWorkspaceInfo)
      .catch((err) => {
        // HIPAA Compliance: Do not log error details that may contain PHI
        // Only log the fact that an error occurred without exposing sensitive data
        console.error('Failed to load workspace info');
        setWorkspaceError(err instanceof Error ? err.message : 'Failed to load workspace info');
      })
      .finally(() => setWorkspaceLoading(false));
  };

  useEffect(() => {
    loadWorkspaceInfo();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [businessId]);

  // Advanced Settings (owner-only)
  const advancedSettings = useAdvancedSettings(workspaceInfo);
  const isOwner = role === 'owner';

  const handleFlagToggle = (flag: keyof FeatureFlags, value: boolean) => {
    if (isDemoMode) return;
    if (featureFlags[flag] === value) return;
    void featureFlagsState.mutate({ [flag]: value } as Partial<FeatureFlags>);
  };

  const handleWaitlistChannel = (channel: 'sms' | 'email', enabled: boolean) => {
    if (isDemoMode) return;
    const current = new Set(featureFlags.waitlistNotifyChannels);
    if (enabled) {
      current.add(channel);
    } else {
      current.delete(channel);
    }
    void featureFlagsState.mutate({ waitlistNotifyChannels: Array.from(current) });
  };

  // Page container style with gradient background
  const pageStyle: CSSProperties = {
    background: `linear-gradient(180deg, ${THEME.colorBgGradientStart} 0%, ${THEME.colorBgGradientEnd} 100%)`,
    minHeight: '100vh',
    padding: `${SPACING.xl}px`,
  };

  // Premium panel style
  const panelStyle: CSSProperties = {
    background: THEME.colorBgPanelGradient,
    borderRadius: THEME.radius,
    boxShadow: THEME.shadow,
    border: `1px solid ${THEME.colorBorder}`,
    padding: `${SPACING.lg}px`,
    marginBottom: `${SPACING.lg}px`,
    transition: `all ${THEME.transitionBase} ease-out`,
  };

  // Card style for interactive panels with hover effect
  const cardStyle: CSSProperties = {
    background: THEME.colorBgPanelGradient,
    borderRadius: THEME.radius,
    boxShadow: THEME.shadow,
    border: `1px solid ${THEME.colorBorder}`,
    padding: `${SPACING.lg}px`,
    transition: `all ${THEME.transitionBase} ease-out`,
    cursor: 'pointer',
  };

  const handleCardHover = (e: React.MouseEvent<HTMLDivElement>, isEntering: boolean) => {
    if (isEntering) {
      e.currentTarget.style.transform = 'translateY(-3px)';
      e.currentTarget.style.boxShadow = THEME.shadowHover;
    } else {
      e.currentTarget.style.transform = 'translateY(0)';
      e.currentTarget.style.boxShadow = THEME.shadow;
    }
  };

  return (
    <section style={pageStyle}>
      <header className="page-header">
        <div>
          <p className="eyebrow">Configuration</p>
          <h1>Business Settings</h1>
          <p className="muted">
            Business details, booking policies, reminders, calendar sync, and telehealth connections.
          </p>
        </div>
      </header>

      <div className="stack" style={{ gap: `${SPACING.lg}px` }}>
        {/* Workspace Identifiers Panel */}
        <div style={panelStyle}>
          <h2>Workspace Identifiers</h2>
          {workspaceLoading && <p className="muted">Loading workspace information...</p>}
          {workspaceError && (
            <div className="note-box" role="alert">
              <strong>Error loading workspace info:</strong> {workspaceError}
            </div>
          )}
          {workspaceInfo && !workspaceLoading && (
            <div className="stack">
              <dl className="data-list">
                <dt>Workspace ID</dt>
                <dd>
                  <code>{workspaceInfo.id}</code>
                </dd>

                <dt>Workspace Name</dt>
                <dd>{workspaceInfo.name}</dd>

                {workspaceInfo.slug && (
                  <>
                    <dt>Workspace Slug</dt>
                    <dd>
                      <code>{workspaceInfo.slug}</code>
                    </dd>
                  </>
                )}

                {workspaceInfo.publicBookingUrl && (
                  <>
                    <dt>Public Booking URL</dt>
                    <dd>
                      <a href={workspaceInfo.publicBookingUrl} target="_blank" rel="noopener noreferrer">
                        {workspaceInfo.publicBookingUrl}
                      </a>
                    </dd>
                  </>
                )}

                {workspaceInfo.timezone && (
                  <>
                    <dt>Timezone</dt>
                    <dd>{workspaceInfo.timezone}</dd>
                  </>
                )}
              </dl>

              {!workspaceInfo.slug && (
                <div className="note-box" role="status">
                  <strong>Note:</strong> No public booking slug configured. Contact support to enable public
                  booking for this workspace.
                </div>
              )}
            </div>
          )}
        </div>

        {featureFlagsState.error && (
          <div className="note-box" role="status">
            <strong>Feature flags unavailable.</strong> {featureFlagsState.error}
          </div>
        )}

        {isDemoMode && (
          <div className="note-box" role="status">
            <strong>Demo mode.</strong> Settings, integrations, HIPAA controls, and tenant configuration are visible but read-only.
          </div>
        )}

        <FeatureFlagsPanel
          flags={featureFlags}
          updating={featureFlagsState.updating}
          readOnly={isDemoMode}
          onToggle={handleFlagToggle}
          onToggleChannel={handleWaitlistChannel}
        />

        {featureFlags.enableCalendarSync && (
          <CalendarSyncPanel
            lookup={integrations.integrationLookup}
            loading={integrations.loading}
            mutationKey={integrations.mutationKey}
            error={integrations.error}
            onRefreshAll={integrations.refresh}
            onConnect={(provider) => integrations.actions.connect(provider)}
            onDisconnect={(provider) => integrations.actions.disconnect(provider)}
            onRefresh={(provider) => integrations.actions.refreshProvider(provider)}
          />
        )}

        {featureFlags.enableTelehealth && (
          <>
            <TelehealthPanel
              lookup={integrations.integrationLookup}
              loading={integrations.loading}
              mutationKey={integrations.mutationKey}
              settings={integrations.telehealthSettings}
              services={integrations.servicePreferences}
              onConnect={(provider) => integrations.actions.connect(provider)}
              onDisconnect={(provider) => integrations.actions.disconnect(provider)}
              onRefresh={(provider) => integrations.actions.refreshProvider(provider)}
              onSetDefault={(provider) => integrations.actions.setDefaultTelehealthProvider(provider)}
              onSetFallback={(provider) => integrations.actions.setFallbackTelehealthProvider(provider)}
              onRequireLink={(enabled) => integrations.actions.setRequireTelehealthLink(enabled)}
              onServiceProviderChange={(serviceId, provider) =>
                integrations.actions.setServiceTelehealthProvider(serviceId, provider)
              }
            />

            <StaffIntegrationsPanel
              rows={integrations.staffRows}
              loading={integrations.loading}
              mutationKey={integrations.mutationKey}
              onUpdateCalendar={(staffId, provider) =>
                integrations.actions.updateStaffCalendar(staffId, provider)
              }
              onUpdateTelehealth={(staffId, provider) =>
                integrations.actions.updateStaffTelehealth(staffId, provider)
              }
            />
          </>
        )}

        {/* Advanced Settings - Owner Only */}
        {isOwner && (
          <AdvancedSettingsPanel
            workspaceInfo={workspaceInfo}
            state={advancedSettings.state}
            actions={advancedSettings.actions}
            onRefresh={loadWorkspaceInfo}
          />
        )}

        {/* Security & Audit Log - Admin/Owner Only */}
        {(role === 'admin' || role === 'owner') && (
          <div style={panelStyle}>
            <h2>Security & Audit Log</h2>
            <p className="muted" style={{ marginBottom: `${SPACING.md}px` }}>
              View all security events and user activity for this workspace. Logs are retained for
              compliance and troubleshooting purposes.
            </p>
            <ActivityLogPanel limit={25} showFilters={true} title="Recent Activity" />
          </div>
        )}

        <div
          className="grid grid--2"
          style={{
            gap: `${SPACING.lg}px`,
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))',
          }}
        >
          <div
            style={cardStyle}
            onClick={() => navigate('/settings/business-details')}
            onMouseEnter={(e) => handleCardHover(e, true)}
            onMouseLeave={(e) => handleCardHover(e, false)}
            role="button"
            tabIndex={0}
            onKeyDown={(e) => {
              if (e.key === 'Enter' || e.key === ' ') {
                e.preventDefault();
                navigate('/settings/business-details');
              }
            }}
          >
            <h2>Business Details</h2>
            <p className="muted" style={{ marginBottom: `${SPACING.md}px` }}>
              Configure your business name, logo, address, timezone, contact email, and industry settings.
            </p>
            <ul className="list" style={{ marginBottom: `${SPACING.md}px` }}>
              <li>Business name and contact information</li>
              <li>Logo and branding assets</li>
              <li>Address and timezone configuration</li>
              <li>Industry classification</li>
              <li>White-label settings (Phase 3)</li>
            </ul>
            <button
              type="button"
              className="button button--ghost"
              style={{ color: THEME.colorAccent }}
              onClick={(e) => {
                e.stopPropagation();
                navigate('/settings/business-details');
              }}
              aria-label="Configure business details"
            >
              Configure Business Details
            </button>
          </div>

          <div
            style={cardStyle}
            onClick={() => navigate('/settings/booking')}
            onMouseEnter={(e) => handleCardHover(e, true)}
            onMouseLeave={(e) => handleCardHover(e, false)}
            role="button"
            tabIndex={0}
            onKeyDown={(e) => {
              if (e.key === 'Enter' || e.key === ' ') {
                e.preventDefault();
                navigate('/settings/booking');
              }
            }}
          >
            <h2>Booking Settings</h2>
            <p className="muted" style={{ marginBottom: `${SPACING.md}px` }}>
              Manage client booking policies, cancellation rules, and appointment approval settings.
            </p>
            <ul className="list" style={{ marginBottom: `${SPACING.md}px` }}>
              <li>Client self-booking toggle</li>
              <li>Maximum bookings per day limits</li>
              <li>Cancellation and rescheduling policies</li>
              <li>Appointment approval requirements</li>
              <li>Intake form submission rules</li>
            </ul>
            <button
              type="button"
              className="button button--ghost"
              style={{ color: THEME.colorAccent }}
              onClick={(e) => {
                e.stopPropagation();
                navigate('/settings/booking');
              }}
              aria-label="Configure booking settings"
            >
              Configure Booking Settings
            </button>
          </div>

          <div
            style={cardStyle}
            onClick={() => navigate('/settings/notifications')}
            onMouseEnter={(e) => handleCardHover(e, true)}
            onMouseLeave={(e) => handleCardHover(e, false)}
            role="button"
            tabIndex={0}
            onKeyDown={(e) => {
              if (e.key === 'Enter' || e.key === ' ') {
                e.preventDefault();
                navigate('/settings/notifications');
              }
            }}
          >
            <h2>Reminders & Notifications</h2>
            <p className="muted" style={{ marginBottom: `${SPACING.md}px` }}>
              Configure automated reminders, notification timing, and message templates.
            </p>
            <ul className="list" style={{ marginBottom: `${SPACING.md}px` }}>
              <li>SMS and email notification toggles</li>
              <li>Reminder timing and frequency</li>
              <li>Custom message templates</li>
              <li>Notification preferences by service type</li>
              <li>Template editor for customization</li>
            </ul>
            <button
              type="button"
              className="button button--ghost"
              style={{ color: THEME.colorAccent }}
              onClick={(e) => {
                e.stopPropagation();
                navigate('/settings/notifications');
              }}
              aria-label="Configure reminder and notification settings"
            >
              Configure Notifications
            </button>
          </div>
        </div>
      </div>
    </section>
  );
}
