import type { FeatureFlags } from '../../types/models';

const FLAG_GROUPS: Array<{
  title: string;
  description: string;
  items: Array<{
    flag: keyof FeatureFlags;
    label: string;
    detail: string;
  }>;
}> = [
  {
    title: 'Core Modules',
    description: 'Enable or hide entire workspaces per tenant.',
    items: [
      {
        flag: 'enableReporting',
        label: 'Reporting & analytics',
        detail: 'Revenue, cancellations, utilization, exports.',
      },
      {
        flag: 'enableMarketing',
        label: 'Marketing campaigns',
        detail: 'Email/SMS blasts with audience filtering.',
      },
      {
        flag: 'enableAutomatedReminders',
        label: 'Communications & automation',
        detail: 'Template editor and reminder rules.',
      },
      {
        flag: 'enablePayments',
        label: 'Billing & payments',
        detail: 'Stripe portal, ledger, refunds.',
      },
    ],
  },
  {
    title: 'Scheduling Surfaces',
    description: 'Expose operational modules that affect booking flows.',
    items: [
      {
        flag: 'enableCalendarSync',
        label: 'Calendar sync',
        detail: 'Google/Outlook provider cards + staff preferences.',
      },
      {
        flag: 'enableTelehealth',
        label: 'Telehealth',
        detail: 'Zoom/Meet provider cards + per-service overrides.',
      },
      {
        flag: 'enableWaitlist',
        label: 'Waitlist workspace',
        detail: 'Staff-facing queue + released-slot broadcast.',
      },
      {
        flag: 'enableClientPortal',
        label: 'Client portal access',
        detail: 'Self-serve booking + intake entry points.',
      },
      {
        flag: 'enableSessionNotes',
        label: 'Session notes',
        detail: 'Provider-only encrypted notes inside client drawer.',
      },
    ],
  },
  {
    title: 'Locations & Resources',
    description: 'Control what facility-level features appear.',
    items: [
      {
        flag: 'enableLocations',
        label: 'Locations module',
        detail: 'Base locations workspace + staff assignment.',
      },
      {
        flag: 'enableResources',
        label: 'Resources & rooms',
        detail: 'Resource CRUD inside locations.',
      },
      {
        flag: 'enableResourceConflicts',
        label: 'Resource conflict panel',
        detail: 'Conflict alerts + maintenance drawer.',
      },
    ],
  },
];

type FeatureFlagsPanelProps = {
  flags: FeatureFlags;
  updating: boolean;
  readOnly?: boolean;
  onToggle: (flag: keyof FeatureFlags, value: boolean) => void;
  onToggleChannel: (channel: 'sms' | 'email', enabled: boolean) => void;
};

export function FeatureFlagsPanel({
  flags,
  updating,
  readOnly = false,
  onToggle,
  onToggleChannel,
}: FeatureFlagsPanelProps) {
  const waitlistChannels = new Set(flags.waitlistNotifyChannels);
  const disabled = updating || readOnly;

  return (
    <section className="panel" aria-labelledby="feature-flags-heading">
      <div className="panel__subheader">
        <div>
          <h2 id="feature-flags-heading">Feature Flags</h2>
          <p className="muted">
            Toggle modules per tenant. Changes take effect immediately for the signed-in business.
          </p>
        </div>
        {updating && <span className="badge badge--info" role="status" aria-live="polite">Saving…</span>}
        {readOnly && <span className="badge badge--warn">Demo read-only</span>}
      </div>

      <div className="stack" style={{ gap: 20 }}>
        {FLAG_GROUPS.map((group) => (
          <div key={group.title}>
            <p className="panel__title">{group.title}</p>
            <p className="muted">{group.description}</p>
            <div className="flag-grid">
              {group.items.map((item) => (
                <label key={item.flag} className="flag-card">
                  <div className="flag-card__header">
                    <input
                      type="checkbox"
                      checked={Boolean(flags[item.flag])}
                      onChange={(event) => onToggle(item.flag, event.target.checked)}
                      disabled={disabled}
                      title={readOnly ? 'Feature flags are read-only in demo mode.' : undefined}
                      aria-label={`${item.label}: ${item.detail}`}
                    />
                    <span>{item.label}</span>
                  </div>
                  <p className="flag-card__detail">{item.detail}</p>
                </label>
              ))}
            </div>
          </div>
        ))}

        <div>
          <p className="panel__title">Waitlist notification channels</p>
          <p className="muted">
            Select which outbound channels are allowed when staff notify clients about open slots.
          </p>
          <div className="chip-row">
            {(['sms', 'email'] as const).map((channel) => {
              const selected = waitlistChannels.has(channel);
              return (
                <button
                  key={channel}
                  type="button"
                  className={`chip chip--outline ${selected ? 'chip-selected' : ''}`}
                  onClick={() => onToggleChannel(channel, !selected)}
                  disabled={disabled}
                  title={readOnly ? 'Waitlist channels are read-only in demo mode.' : undefined}
                  aria-pressed={selected}
                  aria-label={`${selected ? 'Disable' : 'Enable'} ${channel.toUpperCase()} notifications for waitlist`}
                >
                  {channel.toUpperCase()}
                </button>
              );
            })}
          </div>
        </div>
      </div>
    </section>
  );
}
