import { type CSSProperties, FormEvent, useEffect, useMemo, useState } from 'react';

import { useBusinessContext } from '../hooks/useBusinessContext';
import { useFeatureFlags } from '../hooks/useFeatureFlags';
import {
  type HydratedWaitlistEntry,
  useWaitlistEntries,
} from '../hooks/useWaitlistEntries';
import type { WaitlistEntryStatus, WaitlistPriority } from '../types/models';
import { SPACING, THEME } from './dashboard/DashboardComponents';
import { EntryDrawer } from './waitlist/EntryDrawer';
import { QuickAddDialog } from './waitlist/QuickAddDialog';
import { PriorityBadge, StatusBadge } from './waitlist/WaitlistBadges';
import type { WaitlistNotifyChannel } from './waitlist/types';

type FilterState = {
  status: 'all' | WaitlistEntryStatus;
  serviceId: 'all' | string;
  providerId: 'all' | string;
  priority: 'all' | WaitlistPriority;
  search: string;
};

type SlotFormState = {
  serviceId: string;
  providerId: string;
  start: string;
  end: string;
  channel: WaitlistNotifyChannel;
};

const INITIAL_FILTERS: FilterState = {
  status: 'active',
  serviceId: 'all',
  providerId: 'all',
  priority: 'all',
  search: '',
};

const PANEL_STYLE: CSSProperties = {
  padding: SPACING.lg,
  background: THEME.colorBgPanelGradient,
  borderRadius: THEME.radius,
  border: `1px solid ${THEME.colorBorder}`,
  boxShadow: THEME.shadow,
  marginBottom: SPACING.lg,
};

export function WaitlistPage() {
  const { businessId, role, userId } = useBusinessContext({ requireBusinessId: true });
  const flagState = useFeatureFlags(businessId);
  const {
    entries,
    clients,
    services,
    staff,
    loading,
    error,
    refresh,
    createEntry,
    convertEntry,
    expireEntry,
    notifyEntry,
    releaseSlot,
  } = useWaitlistEntries(businessId, userId);

  const [filters, setFilters] = useState<FilterState>(INITIAL_FILTERS);
  const [selectedEntry, setSelectedEntry] = useState<HydratedWaitlistEntry | null>(null);
  const [showQuickAdd, setShowQuickAdd] = useState(false);
  const [slotSubmitting, setSlotSubmitting] = useState(false);

  const defaultChannel = useMemo<WaitlistNotifyChannel>(() => {
    const base = flagState.flags.waitlistNotifyChannels;
    return (base[0] as WaitlistNotifyChannel) ?? 'sms';
  }, [flagState.flags.waitlistNotifyChannels]);

  const [slotForm, setSlotForm] = useState<SlotFormState>(() => ({
    serviceId: '',
    providerId: '',
    start: '',
    end: '',
    channel: defaultChannel,
  }));

  useEffect(() => {
    setSlotForm((prev) => ({ ...prev, channel: defaultChannel }));
  }, [defaultChannel]);

  const selectableChannels = useMemo<WaitlistNotifyChannel[]>(() => {
    const base = flagState.flags.waitlistNotifyChannels;
    if (base.includes('sms') && base.includes('email')) {
      return ['sms', 'email', 'both'];
    }
    return base.length ? base : ['sms'];
  }, [flagState.flags.waitlistNotifyChannels]);

  const canManageEntries = role === 'owner' || role === 'admin' || role === 'staff';
  const quickAddDisabled = !canManageEntries || !clients.length || !services.length;

  const filteredEntries = useMemo(() => {
    return entries.filter((entry) => {
      if (filters.status !== 'all' && entry.status !== filters.status) return false;
      if (filters.serviceId !== 'all' && entry.serviceId !== filters.serviceId) return false;
      if (filters.providerId !== 'all' && entry.providerId !== filters.providerId) return false;
      if (filters.priority !== 'all' && (entry.priority ?? 'standard') !== filters.priority) {
        return false;
      }
      if (filters.search) {
        const term = filters.search.toLowerCase();
        const blob = `${entry.clientName ?? ''} ${entry.serviceName ?? ''} ${entry.notes ?? ''}`;
        if (!blob.toLowerCase().includes(term)) return false;
      }
      return true;
    });
  }, [entries, filters]);

  const handleSlotSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!slotForm.serviceId || !slotForm.providerId || !slotForm.start || !slotForm.end) return;
    setSlotSubmitting(true);
    try {
      await releaseSlot({
        serviceId: slotForm.serviceId,
        start: slotForm.start,
        end: slotForm.end,
        providerId: slotForm.providerId || undefined,
        notifyChannel: slotForm.channel,
      });
      setSlotForm((prev) => ({ ...prev, start: '', end: '' }));
    } finally {
      setSlotSubmitting(false);
    }
  };

  const pageStyle: CSSProperties = {
    minHeight: '100vh',
    background: `linear-gradient(180deg, ${THEME.colorBgGradientStart} 0%, ${THEME.colorBgGradientEnd} 100%)`,
  };

  if (flagState.loading) {
    return (
      <section style={pageStyle}>
        <header className="page-header">
          <div>
            <p className="eyebrow">Operations</p>
            <h1>Waitlist Management</h1>
            <p className="muted">Loading tenant configuration…</p>
          </div>
        </header>
        <div className="panel">
          <p className="muted">Fetching feature flags for this business.</p>
        </div>
      </section>
    );
  }

  if (!flagState.flags.enableWaitlist) {
    return (
      <section style={pageStyle}>
        <header className="page-header">
          <div>
            <p className="eyebrow">Operations</p>
            <h1>Waitlist</h1>
            <p className="muted">Waitlist is disabled for this business. Enable via feature flags.</p>
          </div>
        </header>
        <div className="panel panel--alert">
          <p className="muted">
            Toggle `enableWaitlist` inside the tenant&rsquo;s feature flags to expose this module.
          </p>
        </div>
      </section>
    );
  }

  return (
    <section style={pageStyle}>
      <header className="page-header">
        <div>
          <p className="eyebrow">Operations</p>
          <h1>Waitlist Management</h1>
          <p className="muted">
            Monitor entries, convert them into bookings, expire stale requests, and capture ad-hoc
            leads via quick add.
          </p>
        </div>
        <div className="header-actions">
          <button
            className="button button--ghost"
            type="button"
            onClick={refresh}
            disabled={loading}
          >
            Refresh
          </button>
          <button
            className="button button--primary"
            type="button"
            disabled={quickAddDisabled}
            onClick={() => setShowQuickAdd(true)}
          >
            Quick add
          </button>
        </div>
      </header>

      {flagState.error ? (
        <div className="panel panel--alert">
          <p className="muted">
            Feature flag warning: {flagState.error}. Showing defaults until resolved.
          </p>
        </div>
      ) : null}

      <FiltersPanel
        services={services}
        staff={staff}
        filters={filters}
        onChange={setFilters}
      />

      <WaitlistTable
        entries={filteredEntries}
        loading={loading}
        error={error}
        canManage={canManageEntries}
        onConvert={convertEntry}
        onExpire={expireEntry}
        onNotify={notifyEntry}
        onSelect={setSelectedEntry}
      />

      <div className="grid grid--2" style={{ gap: SPACING.lg, marginBottom: SPACING.lg }}>
        <div style={{ ...PANEL_STYLE, marginBottom: 0 }}>
          <h2>Released Slot Broadcast</h2>
          <p className="muted">
            Trigger the shared `handleReleasedSlot` endpoint to notify matching waitlist entries
            when provider availability opens up.
          </p>
          <form className="stack" onSubmit={handleSlotSubmit}>
            <label>
              <span className="eyebrow">Service</span>
              <select
                value={slotForm.serviceId}
                onChange={(event) =>
                  setSlotForm((prev) => ({ ...prev, serviceId: event.target.value }))
                }
                required
              >
                <option value="">Select service</option>
                {services.map((service) => (
                  <option key={service.id} value={service.id}>
                    {service.name}
                  </option>
                ))}
              </select>
            </label>

            <label>
              <span className="eyebrow">Provider</span>
              <select
                value={slotForm.providerId}
                onChange={(event) =>
                  setSlotForm((prev) => ({ ...prev, providerId: event.target.value }))
                }
                required
              >
                <option value="">Select provider</option>
                {staff.map((member) => (
                  <option key={member.id} value={member.id}>
                    {member.displayName}
                  </option>
                ))}
              </select>
            </label>

            <label>
              <span className="eyebrow">Start</span>
              <input
                type="datetime-local"
                value={slotForm.start}
                onChange={(event) => setSlotForm((prev) => ({ ...prev, start: event.target.value }))}
                required
              />
            </label>

            <label>
              <span className="eyebrow">End</span>
              <input
                type="datetime-local"
                value={slotForm.end}
                onChange={(event) => setSlotForm((prev) => ({ ...prev, end: event.target.value }))}
                required
              />
            </label>

            <label>
              <span className="eyebrow">Channel</span>
              <select
                value={slotForm.channel}
                onChange={(event) =>
                  setSlotForm((prev) => ({
                    ...prev,
                    channel: event.target.value as WaitlistNotifyChannel,
                  }))
                }
              >
                {selectableChannels.map((channel) => (
                  <option key={channel} value={channel}>
                    {channel.toUpperCase()}
                  </option>
                ))}
              </select>
            </label>

            <div className="dialog-actions">
              <button
                className="button button--ghost"
                type="button"
                onClick={() =>
                  setSlotForm({
                    serviceId: '',
                    providerId: '',
                    start: '',
                    end: '',
                    channel: defaultChannel,
                  })
                }
              >
                Clear
              </button>
              <button
                className="button button--primary"
                type="submit"
                disabled={!canManageEntries || slotSubmitting}
              >
                {slotSubmitting ? 'Broadcasting…' : 'Broadcast slot'}
              </button>
            </div>
          </form>
        </div>

        <div style={{ ...PANEL_STYLE, marginBottom: 0 }} className="panel--alert">
          <h2>Playbook</h2>
          <ul className="list">
            <li>Convert when a slot is confirmed with the client.</li>
            <li>Notify to trigger SMS/email nudge (configurable channels).</li>
            <li>Expire entries that have aged out of the target window.</li>
            <li>Use quick add for in-person or phone requests.</li>
          </ul>
        </div>
      </div>

      {showQuickAdd && (
        <QuickAddDialog
          clients={clients}
          services={services}
          staff={staff}
          channels={selectableChannels}
          onClose={() => setShowQuickAdd(false)}
          onSubmit={async (input) => {
            await createEntry(input);
            setShowQuickAdd(false);
          }}
        />
      )}

      {selectedEntry ? (
        <EntryDrawer
          entry={selectedEntry}
          onClose={() => setSelectedEntry(null)}
          canManage={canManageEntries}
          onConvert={convertEntry}
          onExpire={expireEntry}
          onNotify={notifyEntry}
        />
      ) : null}
    </section>
  );
}

type FiltersPanelProps = {
  services: { id: string; name: string }[];
  staff: { id: string; displayName: string }[];
  filters: FilterState;
  onChange: (next: FilterState) => void;
};

function FiltersPanel({ services, staff, filters, onChange }: FiltersPanelProps) {
  return (
    <div style={PANEL_STYLE}>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: SPACING.lg }}>
        <label>
          <span className="eyebrow">Service</span>
          <select
            value={filters.serviceId}
            onChange={(event) =>
              onChange({ ...filters, serviceId: event.target.value as FilterState['serviceId'] })
            }
          >
            <option value="all">All services</option>
            {services.map((service) => (
              <option key={service.id} value={service.id}>
                {service.name}
              </option>
            ))}
          </select>
        </label>

        <label>
          <span className="eyebrow">Provider</span>
          <select
            value={filters.providerId}
            onChange={(event) =>
              onChange({ ...filters, providerId: event.target.value as FilterState['providerId'] })
            }
          >
            <option value="all">All providers</option>
            {staff.map((member) => (
              <option key={member.id} value={member.id}>
                {member.displayName}
              </option>
            ))}
          </select>
        </label>

        <label>
          <span className="eyebrow">Status</span>
          <select
            value={filters.status}
            onChange={(event) =>
              onChange({ ...filters, status: event.target.value as FilterState['status'] })
            }
          >
            <option value="all">All statuses</option>
            <option value="active">Active</option>
            <option value="notified">Notified</option>
            <option value="converted">Converted</option>
            <option value="expired">Expired</option>
          </select>
        </label>

        <label>
          <span className="eyebrow">Priority</span>
          <select
            value={filters.priority}
            onChange={(event) =>
              onChange({ ...filters, priority: event.target.value as FilterState['priority'] })
            }
          >
            <option value="all">All priorities</option>
            <option value="vip">VIP</option>
            <option value="standard">Standard</option>
          </select>
        </label>

        <label>
          <span className="eyebrow">Search</span>
          <input
            type="search"
            placeholder="Client, service, or notes"
            value={filters.search}
            onChange={(event) => onChange({ ...filters, search: event.target.value })}
          />
        </label>

        <div>
          <button
            className="button button--ghost"
            type="button"
            onClick={() => onChange(INITIAL_FILTERS)}
          >
            Reset
          </button>
        </div>
      </div>
    </div>
  );
}

type WaitlistTableProps = {
  entries: HydratedWaitlistEntry[];
  loading: boolean;
  error: string | null;
  canManage: boolean;
  onConvert: (id: string) => Promise<void>;
  onExpire: (id: string) => Promise<void>;
  onNotify: (id: string) => Promise<void>;
  onSelect: (entry: HydratedWaitlistEntry) => void;
};

function WaitlistTable({
  entries,
  loading,
  error,
  canManage,
  onConvert,
  onExpire,
  onNotify,
  onSelect,
}: WaitlistTableProps) {
  return (
    <div style={PANEL_STYLE}>
      <header style={{ marginBottom: SPACING.lg }}>
        <div>
          <h2>Waitlist ({entries.length})</h2>
          <p className="muted">
            {loading ? 'Loading waitlist entries…' : 'Filter by service, provider, or status.'}
          </p>
        </div>
      </header>
      {error ? <p className="error">{error}</p> : null}
      <div className="table">
        <div className="table__head">
          <span>Client</span>
          <span>Service</span>
          <span>Provider</span>
          <span>Preferred</span>
          <span>Priority</span>
          <span>Status</span>
          <span>Actions</span>
        </div>
        {entries.length === 0 && !loading ? (
          <div className="empty-state">No waitlist entries match the current filters.</div>
        ) : null}
        {entries.map((entry) => (
          <div
            key={entry.id}
            className="table__row"
            style={{ cursor: 'pointer', transition: `all ${THEME.transitionBase} ease-out` }}
            role="button"
            onClick={() => onSelect(entry)}
            onMouseOver={(e) => {
              e.currentTarget.style.transform = 'translateX(4px)';
              e.currentTarget.style.backgroundColor = THEME.colorBgPanel;
            }}
            onMouseOut={(e) => {
              e.currentTarget.style.transform = 'translateX(0)';
              e.currentTarget.style.backgroundColor = 'transparent';
            }}
          >
            <span className="truncate">{entry.clientName ?? entry.clientId}</span>
            <span className="truncate">{entry.serviceName ?? '—'}</span>
            <span className="truncate">{entry.providerName ?? 'Any provider'}</span>
            <span className="truncate">
              {entry.preferredStart ? new Date(entry.preferredStart).toLocaleString() : 'Flexible'}
            </span>
            <span>
              <PriorityBadge priority={entry.priority ?? 'standard'} />
            </span>
            <span>
              <StatusBadge status={entry.status} />
            </span>
            <span>
              <div className="chip-row chip-row--compact">
                <button
                  type="button"
                  disabled={!canManage}
                  onClick={(event) => {
                    event.stopPropagation();
                    void onConvert(entry.id);
                  }}
                >
                  Convert
                </button>
                <button
                  type="button"
                  disabled={!canManage}
                  onClick={(event) => {
                    event.stopPropagation();
                    void onNotify(entry.id);
                  }}
                >
                  Notify
                </button>
                <button
                  type="button"
                  disabled={!canManage}
                  onClick={(event) => {
                    event.stopPropagation();
                    void onExpire(entry.id);
                  }}
                >
                  Expire
                </button>
              </div>
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}
