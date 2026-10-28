/**
 * TenantFlagsPanel
 * Toggle feature flags for a tenant.
 */

import { useState } from 'react';
import type { FeatureFlags } from '../../../types/models';
import { ConfirmDialog } from '../../../components/ConfirmDialog';

type Props = {
  flags: FeatureFlags;
  updating: boolean;
  onUpdateFlags: (updates: Partial<FeatureFlags>) => Promise<void>;
};

const FLAG_GROUPS = [
  {
    label: 'Core Modules',
    flags: [
      { key: 'enableReporting', label: 'Reporting & Analytics' },
      { key: 'enableMarketing', label: 'Marketing Campaigns' },
      { key: 'enableAutomatedReminders', label: 'Automated Reminders' },
      { key: 'enablePayments', label: 'Payment Processing' },
    ],
  },
  {
    label: 'Scheduling Features',
    flags: [
      { key: 'enableCalendarSync', label: 'Calendar Sync' },
      { key: 'enableTelehealth', label: 'Telehealth/Video' },
      { key: 'enableWaitlist', label: 'Waitlist' },
      { key: 'enableClientPortal', label: 'Client Portal' },
      { key: 'enableSessionNotes', label: 'Session Notes (PHI)' },
    ],
  },
  {
    label: 'Locations & Resources',
    flags: [
      { key: 'enableLocations', label: 'Multi-Location' },
      { key: 'enableResources', label: 'Resource Management' },
      { key: 'enableResourceConflicts', label: 'Resource Conflicts' },
    ],
  },
  {
    label: 'Advanced',
    flags: [
      { key: 'enableIntakeBuilder', label: 'Intake Form Builder' },
      { key: 'enableImportExport', label: 'Import/Export' },
      { key: 'enableAutomation', label: 'Workflow Automation' },
    ],
  },
] as const;

export function TenantFlagsPanel({ flags, updating, onUpdateFlags }: Props) {
  const [pendingUpdate, setPendingUpdate] = useState<{
    key: keyof FeatureFlags;
    value: boolean;
    label: string;
  } | null>(null);

  const handleToggle = (key: keyof FeatureFlags, label: string) => {
    const currentValue = flags[key];
    if (typeof currentValue === 'boolean') {
      setPendingUpdate({ key, value: !currentValue, label });
    }
  };

  const handleConfirm = async () => {
    if (pendingUpdate) {
      await onUpdateFlags({ [pendingUpdate.key]: pendingUpdate.value });
      setPendingUpdate(null);
    }
  };

  return (
    <div className="stack">
      {FLAG_GROUPS.map((group) => (
        <div key={group.label} className="panel">
          <h3>{group.label}</h3>
          <div className="stack" style={{ gap: 8 }}>
            {group.flags.map((flag) => {
              const value = flags[flag.key as keyof FeatureFlags];
              const isBoolean = typeof value === 'boolean';
              return (
                <div
                  key={flag.key}
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                    padding: '8px 0',
                    borderBottom: '1px solid var(--color-border)',
                  }}
                >
                  <span>{flag.label}</span>
                  {isBoolean ? (
                    <button
                      className={`button button--ghost ${value ? 'button--success' : ''}`}
                      onClick={() => handleToggle(flag.key as keyof FeatureFlags, flag.label)}
                      disabled={updating}
                      style={{
                        minWidth: 60,
                        color: value ? 'var(--color-success)' : 'var(--color-muted)',
                      }}
                    >
                      {value ? 'ON' : 'OFF'}
                    </button>
                  ) : (
                    <span className="muted">—</span>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      ))}

      {/* Confirm Dialog */}
      {pendingUpdate && (
        <ConfirmDialog
          title="Toggle Feature Flag"
          message={`Are you sure you want to ${pendingUpdate.value ? 'enable' : 'disable'} "${pendingUpdate.label}"?`}
          onConfirm={handleConfirm}
          onCancel={() => setPendingUpdate(null)}
          confirmLabel={pendingUpdate.value ? 'Enable' : 'Disable'}
          danger={!pendingUpdate.value}
        />
      )}
    </div>
  );
}
