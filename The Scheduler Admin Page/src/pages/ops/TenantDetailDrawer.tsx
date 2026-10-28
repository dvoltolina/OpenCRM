/**
 * TenantDetailDrawer
 * Drawer for viewing and managing a single tenant (super-admin only).
 * Tabs: Overview, Billing, Flags, Notes, Actions
 */

import { useState } from 'react';
import { useTenantDetails } from '../../hooks/useTenantDetails';
import { useOpsNotes } from '../../hooks/useOpsNotes';
import { useOpsAuditLogForTenant } from '../../hooks/useOpsAuditLog';
import { TenantOverviewPanel } from './panels/TenantOverviewPanel';
import { TenantBillingPanel } from './panels/TenantBillingPanel';
import { TenantFlagsPanel } from './panels/TenantFlagsPanel';
import { TenantNotesPanel } from './panels/TenantNotesPanel';
import { TenantActionsPanel } from './panels/TenantActionsPanel';

type Tab = 'overview' | 'billing' | 'flags' | 'notes' | 'actions';

type Props = {
  businessId: string;
  tenantName: string;
  onClose: () => void;
  onUpdated?: () => void;
};

export function TenantDetailDrawer({ businessId, tenantName, onClose, onUpdated }: Props) {
  const [activeTab, setActiveTab] = useState<Tab>('overview');
  const { details, loading, error, updating, refresh, setPlan, toggleAddon, updateFlags } =
    useTenantDetails(businessId);
  const { notes, loading: notesLoading, addNote, adding: addingNote } = useOpsNotes(businessId);
  const { logs: auditLogs, loading: auditLoading } = useOpsAuditLogForTenant(businessId);

  const handleUpdate = async (fn: () => Promise<void>) => {
    await fn();
    onUpdated?.();
  };

  const tabs: { id: Tab; label: string }[] = [
    { id: 'overview', label: 'Overview' },
    { id: 'billing', label: 'Billing' },
    { id: 'flags', label: 'Flags' },
    { id: 'notes', label: `Notes (${notes.length})` },
    { id: 'actions', label: 'Actions' },
  ];

  return (
    <div className="drawer-overlay" onClick={onClose}>
      <div className="drawer drawer--wide" onClick={(e) => e.stopPropagation()}>
        <div className="drawer__header">
          <div>
            <p className="eyebrow">Tenant Details</p>
            <h2>{tenantName}</h2>
            <p className="muted" style={{ fontSize: 12 }}>
              {businessId}
            </p>
          </div>
          <button className="button button--ghost" onClick={onClose}>
            x
          </button>
        </div>

        {/* Tabs */}
        <div className="drawer__tabs">
          {tabs.map((tab) => (
            <button
              key={tab.id}
              className={`tab ${activeTab === tab.id ? 'tab--active' : ''}`}
              onClick={() => setActiveTab(tab.id)}
            >
              {tab.label}
            </button>
          ))}
        </div>

        <div className="drawer__content">
          {loading && !details ? (
            <p className="muted">Loading tenant details...</p>
          ) : error ? (
            <div className="panel panel--alert">
              <strong>Error:</strong> {error}
            </div>
          ) : !details ? (
            <p className="muted">Tenant not found.</p>
          ) : (
            <>
              {activeTab === 'overview' && (
                <TenantOverviewPanel
                  workspace={details.workspace}
                  billing={details.billing}
                  auditLogs={auditLogs}
                  auditLoading={auditLoading}
                />
              )}

              {activeTab === 'billing' && (
                <TenantBillingPanel
                  billing={details.billing}
                  updating={updating}
                  onSetPlan={(planId, planName, seats) =>
                    handleUpdate(() => setPlan(planId, planName, seats))
                  }
                  onToggleAddon={(addonId, enabled) =>
                    handleUpdate(() => toggleAddon(addonId, enabled))
                  }
                />
              )}

              {activeTab === 'flags' && (
                <TenantFlagsPanel
                  flags={details.flags}
                  updating={updating}
                  onUpdateFlags={(updates) => handleUpdate(() => updateFlags(updates))}
                />
              )}

              {activeTab === 'notes' && (
                <TenantNotesPanel
                  notes={notes}
                  loading={notesLoading}
                  adding={addingNote}
                  onAddNote={addNote}
                />
              )}

              {activeTab === 'actions' && (
                <TenantActionsPanel
                  businessId={businessId}
                  tenantName={tenantName}
                />
              )}
            </>
          )}
        </div>
      </div>
    </div>
  );
}
