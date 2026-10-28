import { useState } from 'react';

import type { HydratedWaitlistEntry } from '../../hooks/useWaitlistEntries';
import { PriorityBadge, StatusBadge } from './WaitlistBadges';

type EntryDrawerProps = {
  entry: HydratedWaitlistEntry;
  onClose: () => void;
  canManage: boolean;
  onConvert: (id: string) => Promise<void>;
  onExpire: (id: string) => Promise<void>;
  onNotify: (id: string) => Promise<void>;
};

export function EntryDrawer({
  entry,
  onClose,
  canManage,
  onConvert,
  onExpire,
  onNotify,
}: EntryDrawerProps) {
  const [submitting, setSubmitting] = useState<'convert' | 'expire' | 'notify' | null>(null);

  const handleAction = async (
    action: 'convert' | 'expire' | 'notify',
    callback: (id: string) => Promise<void>,
  ) => {
    if (!canManage || submitting === action) return;
    setSubmitting(action);
    try {
      await callback(entry.id);
    } finally {
      setSubmitting(null);
    }
  };

  return (
    <div className="drawer-overlay">
      <div className="drawer">
        <div className="drawer-header">
          <div>
            <p className="eyebrow">Waitlist entry</p>
            <h2>{entry.clientName ?? entry.clientId}</h2>
            <p className="muted">{entry.serviceName ?? 'Any service'}</p>
          </div>
          <button className="button button--ghost" type="button" onClick={onClose}>
            Close
          </button>
        </div>

        <div className="drawer-content">
          <div className="stack">
            <div className="panel">
              <h3>Details</h3>
              <div className="stack">
                <div className="meta-row">
                  <span className="eyebrow">Status</span>
                  <StatusBadge status={entry.status} />
                </div>
                <div className="meta-row">
                  <span className="eyebrow">Priority</span>
                  <PriorityBadge priority={entry.priority ?? 'standard'} />
                </div>
                <div className="meta-row">
                  <span className="eyebrow">Preferred window</span>
                  <span>
                    {entry.preferredStart
                      ? new Date(entry.preferredStart).toLocaleString()
                      : 'Flexible'}
                    {entry.preferredEnd
                      ? ` → ${new Date(entry.preferredEnd).toLocaleString()}`
                      : ''}
                  </span>
                </div>
                <div className="meta-row">
                  <span className="eyebrow">Provider preference</span>
                  <span>{entry.providerName ?? 'Any provider'}</span>
                </div>
                {entry.notes ? (
                  <div>
                    <span className="eyebrow">Notes</span>
                    <p>{entry.notes}</p>
                  </div>
                ) : null}
              </div>
            </div>

            <div className="panel">
              <h3>Contact</h3>
              <div className="stack">
                <div className="meta-row">
                  <span className="eyebrow">Email</span>
                  <span>{entry.clientEmail ?? '—'}</span>
                </div>
                <div className="meta-row">
                  <span className="eyebrow">Phone</span>
                  <span>{entry.clientPhone ?? '—'}</span>
                </div>
                <div className="meta-row">
                  <span className="eyebrow">Notification channel</span>
                  <span>{entry.notificationChannel?.toUpperCase() ?? 'Not set'}</span>
                </div>
              </div>
            </div>

            <div className="panel">
              <h3>Actions</h3>
              <div className="chip-row chip-row--wrap">
                <button
                  type="button"
                  disabled={!canManage || submitting === 'convert'}
                  onClick={() => handleAction('convert', onConvert)}
                >
                  {submitting === 'convert' ? 'Converting…' : 'Convert to appointment'}
                </button>
                <button
                  type="button"
                  disabled={!canManage || submitting === 'notify'}
                  onClick={() => handleAction('notify', onNotify)}
                >
                  {submitting === 'notify' ? 'Notifying…' : 'Send notification'}
                </button>
                <button
                  type="button"
                  disabled={!canManage || submitting === 'expire'}
                  onClick={() => handleAction('expire', onExpire)}
                >
                  {submitting === 'expire' ? 'Expiring…' : 'Expire entry'}
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}


