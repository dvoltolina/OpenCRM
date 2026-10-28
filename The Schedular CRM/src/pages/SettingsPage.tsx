import { useCallback, useEffect, useMemo, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { Button, Card, PageHeader, PageLayout } from '../components/ui';
import {
  WorkspaceSettings,
  PipelineSettings,
  TeamSettings,
  CustomFieldsSettings,
  CRMSettings,
  AutomationSettings,
} from '../components/settings';
import { NotificationPreferences } from '../components/notifications';
import { useIntegrationSync } from '../hooks/useIntegrationSync';
import { getFeatureFlags } from '../config/features';
import { useAuth } from '../context/AuthContext';
import { CalendarSyncPanel } from '../components/calendar-sync/CalendarSyncPanel';
import {
  DEFAULT_SETTINGS_TAB,
  normalizeSettingsTab,
  SETTINGS_NOTIFICATION_TAB,
  type SettingsTab,
} from './settings-tabs';
import './styles/settings-page.css';

const SETTINGS_TAB_META: Record<
  SettingsTab,
  { eyebrow: string; description: string }
> = {
  workspace: {
    eyebrow: 'Workspace',
    description: 'Business metadata, security posture, and workspace-level defaults.',
  },
  pipeline: {
    eyebrow: 'Pipeline',
    description: 'Stages, funnel structure, and shared sales process configuration.',
  },
  team: {
    eyebrow: 'Team',
    description: 'Team structure, assignment policies, and user organization.',
  },
  fields: {
    eyebrow: 'Custom Fields',
    description: 'Entity-specific CRM fields that make the workspace adaptable.',
  },
  integrations: {
    eyebrow: 'Integrations',
    description: 'Connection status, sync utilities, and business-level integration controls.',
  },
  profile: {
    eyebrow: 'Business Profile',
    description: 'General CRM configuration and operational business settings.',
  },
  automation: {
    eyebrow: 'Automation',
    description: 'Rule configuration, guardrails, and workflow defaults.',
  },
  notifications: {
    eyebrow: 'Notifications',
    description: 'User notification preferences and in-app delivery behavior.',
  },
};

export function SettingsPage() {
  const [searchParams, setSearchParams] = useSearchParams();
  const [integrationId, setIntegrationId] = useState<string>('default');
  const { isLoading: syncLoading, error: syncError, lastResult, runSync } = useIntegrationSync();
  const features = getFeatureFlags();
  const { crmUser, hasRole } = useAuth();
  const canAccessWorkspaceSettings = hasRole(['owner', 'admin']);
  const canManageAutomation = hasRole(['owner', 'admin', 'manager']);

  const tabs = useMemo<{ id: SettingsTab; label: string }[]>(
    () => {
      const nextTabs: { id: SettingsTab; label: string }[] = [];

      if (canAccessWorkspaceSettings) {
        nextTabs.push(
          { id: 'workspace', label: 'Workspace' },
          { id: 'pipeline', label: 'Pipeline' },
          { id: 'team', label: 'Team' },
          { id: 'fields', label: 'Custom Fields' },
        );

        if (features.enableAutomation && canManageAutomation) {
          nextTabs.push({ id: 'automation', label: 'Automation' });
        }

        nextTabs.push(
          { id: 'integrations', label: 'Integrations' },
          { id: 'profile', label: 'Business Profile' },
        );
      }

      nextTabs.push({ id: 'notifications', label: 'Notifications' });

      return nextTabs;
    },
    [canAccessWorkspaceSettings, canManageAutomation, features.enableAutomation]
  );
  const availableTabIds = useMemo(() => tabs.map((tab) => tab.id), [tabs]);
  const rawTab = searchParams.get('tab');
  const fallbackTab = canAccessWorkspaceSettings ? DEFAULT_SETTINGS_TAB : SETTINGS_NOTIFICATION_TAB;
  const activeTab = useMemo<SettingsTab>(() => {
    return normalizeSettingsTab(rawTab, availableTabIds, fallbackTab);
  }, [availableTabIds, fallbackTab, rawTab]);
  const activeTabMeta = SETTINGS_TAB_META[activeTab];

  useEffect(() => {
    if (!rawTab) return;
    if (rawTab !== activeTab) {
      const nextParams = new URLSearchParams(searchParams);
      nextParams.set('tab', activeTab);
      setSearchParams(nextParams, { replace: true });
    }
  }, [activeTab, rawTab, searchParams, setSearchParams]);

  const handleTabChange = useCallback(
    (tab: SettingsTab) => {
      const nextParams = new URLSearchParams(searchParams);
      nextParams.set('tab', tab);
      setSearchParams(nextParams, { replace: true });
    },
    [searchParams, setSearchParams]
  );

  const renderActiveTab = () => {
    if (activeTab === 'workspace') {
      return <WorkspaceSettings />;
    }

    if (activeTab === 'pipeline') {
      return <PipelineSettings />;
    }

    if (activeTab === 'team') {
      return <TeamSettings />;
    }

    if (activeTab === 'fields') {
      return <CustomFieldsSettings />;
    }

    if (activeTab === 'automation' && features.enableAutomation && canManageAutomation) {
      return <AutomationSettings />;
    }

    if (activeTab === 'integrations' && canAccessWorkspaceSettings) {
      return (
        <div className="settings-page__stack">
          <Card className="settings-page__inline-panel" padding="lg" tone="subtle">
            <div className="settings-page__section-header">
              <div>
                <p className="ui-empty-state__eyebrow">Connection Health</p>
                <h3>Workspace integrations</h3>
                <p>
                  Integration endpoints deploy from the shared Scheduler backend. Keep the
                  corresponding Functions active before enabling the related feature flags.
                </p>
              </div>
            </div>

            {features.enableCalendarSync ? (
              <CalendarSyncPanel />
            ) : (
              <div className="settings-page__notice">
                Calendar sync is disabled via feature flag in this environment.
              </div>
            )}
          </Card>

          <Card className="settings-page__inline-panel" padding="lg">
            <div className="settings-page__section-header">
              <div>
                <p className="ui-empty-state__eyebrow">Manual Trigger</p>
                <h3>Run integration sync</h3>
                <p>Trigger `/integrationSync` on the shared Functions host using your ID token.</p>
              </div>
            </div>

            <label className="settings-page__input-group">
              <span>Integration ID</span>
              <input
                type="text"
                value={integrationId}
                onChange={(event) => setIntegrationId(event.target.value)}
                placeholder="default"
              />
            </label>

            {syncError ? <div className="settings-page__notice is-danger">{syncError}</div> : null}
            {lastResult ? <div className="settings-page__notice is-success">{lastResult}</div> : null}

            <div className="settings-page__actions">
              <Button
                onClick={() => runSync({ integrationId })}
                disabled={syncLoading}
              >
                {syncLoading ? 'Syncing…' : 'Run sync'}
              </Button>
            </div>
          </Card>

          <CRMSettings initialTab="general" />
        </div>
      );
    }

    if (activeTab === 'profile' && canAccessWorkspaceSettings) {
      return <CRMSettings initialTab="general" />;
    }

    if (activeTab === 'notifications' && crmUser) {
      return <NotificationPreferences userId={crmUser.id} />;
    }

    return null;
  };

  return (
    <PageLayout className="settings-page">
      <PageHeader
        eyebrow="Configuration"
        title="Settings"
        subtitle="Workspace administration, operational defaults, and notification controls in one place."
        actions={(
          <div className="settings-page__summary-pill">
            <span>{tabs.length} tabs</span>
            <strong>{activeTabMeta.eyebrow}</strong>
          </div>
        )}
      />

      <Card className="settings-page__hero" padding="lg" tone="accent">
        <div className="settings-page__hero-copy">
          <p className="ui-empty-state__eyebrow">Current Focus</p>
          <h2>{activeTabMeta.eyebrow}</h2>
          <p>{activeTabMeta.description}</p>
        </div>
      </Card>

      <div className="settings-page__layout">
        <Card className="settings-page__nav-card" padding="md" tone="subtle">
          <div className="settings-page__nav-header">
            <p className="ui-empty-state__eyebrow">Sections</p>
            <h2>Navigate settings</h2>
          </div>

          {tabs.map((tab) => (
            <button
              key={tab.id}
              type="button"
              className={`settings-page__nav-item ${activeTab === tab.id ? 'is-active' : ''}`}
              onClick={() => handleTabChange(tab.id)}
              aria-label={tab.label}
            >
              <span className="settings-page__nav-label">{tab.label}</span>
              <span className="settings-page__nav-description">
                {SETTINGS_TAB_META[tab.id].eyebrow}
              </span>
            </button>
          ))}
        </Card>

        <Card className="settings-page__content-card" padding="lg">
          <div className="settings-page__content-header">
            <div>
              <p className="ui-empty-state__eyebrow">{activeTabMeta.eyebrow}</p>
              <h2>{tabs.find((tab) => tab.id === activeTab)?.label || 'Settings'}</h2>
              <p>{activeTabMeta.description}</p>
            </div>
          </div>

          <div className="settings-page__content-body">{renderActiveTab()}</div>
        </Card>
      </div>
    </PageLayout>
  );
}
