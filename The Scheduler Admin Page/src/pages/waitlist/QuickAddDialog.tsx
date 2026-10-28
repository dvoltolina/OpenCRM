import { FormEvent, useMemo, useState } from 'react';

import type { WaitlistEntryInput } from '../../data/waitlist';
import type { Client, Service, StaffMember, WaitlistPriority } from '../../types/models';
import type { WaitlistNotifyChannel } from './types';

type QuickAddDialogProps = {
  clients: Client[];
  services: Service[];
  staff: StaffMember[];
  channels: WaitlistNotifyChannel[];
  onClose: () => void;
  onSubmit: (input: WaitlistEntryInput) => Promise<void>;
};

export function QuickAddDialog({
  clients,
  services,
  staff,
  channels,
  onClose,
  onSubmit,
}: QuickAddDialogProps) {
  const defaultChannel = useMemo<WaitlistNotifyChannel>(() => channels[0] ?? 'sms', [channels]);
  const [form, setForm] = useState<WaitlistEntryInput>({
    clientId: '',
    serviceId: '',
    providerId: '',
    preferredStart: '',
    preferredEnd: '',
    priority: 'standard',
    notes: '',
    notificationChannel: defaultChannel === 'both' ? 'sms' : defaultChannel,
  });
  const [submitting, setSubmitting] = useState(false);

  const canSubmit = Boolean(form.clientId && form.serviceId);

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!canSubmit) return;
    setSubmitting(true);
    try {
      await onSubmit({
        clientId: form.clientId,
        serviceId: form.serviceId,
        providerId: form.providerId || undefined,
        preferredStart: form.preferredStart || undefined,
        preferredEnd: form.preferredEnd || undefined,
        priority: form.priority ?? 'standard',
        notes: form.notes?.trim() || undefined,
        notificationChannel: form.notificationChannel,
      });
      setForm((prev) => ({ ...prev, clientId: '', serviceId: '' }));
    } finally {
      setSubmitting(false);
    }
  };

  const channelOptions = channels.includes('both') ? channels : channels;

  return (
    <div className="dialog-overlay">
      <div className="dialog">
        <h2>Quick Add Waitlist Entry</h2>
        {(!clients.length || !services.length) && (
          <p className="muted">Add at least one client and service to create waitlist entries.</p>
        )}
        <form onSubmit={handleSubmit}>
          <label>
            Client
            <select
              value={form.clientId}
              onChange={(e) => setForm((prev) => ({ ...prev, clientId: e.target.value }))}
              required
            >
              <option value="">Select client</option>
              {clients.map((client) => (
                <option key={client.id} value={client.id}>
                  {client.name}
                </option>
              ))}
            </select>
          </label>

          <label>
            Service
            <select
              value={form.serviceId}
              onChange={(e) => setForm((prev) => ({ ...prev, serviceId: e.target.value }))}
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
            Preferred start
            <input
              type="datetime-local"
              value={form.preferredStart ?? ''}
              onChange={(e) => setForm((prev) => ({ ...prev, preferredStart: e.target.value }))}
            />
          </label>

          <label>
            Preferred end
            <input
              type="datetime-local"
              value={form.preferredEnd ?? ''}
              onChange={(e) => setForm((prev) => ({ ...prev, preferredEnd: e.target.value }))}
            />
          </label>

          <label>
            Provider
            <select
              value={form.providerId ?? ''}
              onChange={(e) => setForm((prev) => ({ ...prev, providerId: e.target.value }))}
            >
              <option value="">Any provider</option>
              {staff.map((member) => (
                <option key={member.id} value={member.id}>
                  {member.displayName}
                </option>
              ))}
            </select>
          </label>

          <label>
            Priority
            <select
              value={form.priority ?? 'standard'}
              onChange={(e) =>
                setForm((prev) => ({
                  ...prev,
                  priority: e.target.value as WaitlistPriority,
                }))
              }
            >
              <option value="standard">Standard</option>
              <option value="vip">VIP</option>
            </select>
          </label>

          <label>
            Notification channel
            <select
              value={form.notificationChannel ?? defaultChannel}
              onChange={(e) =>
                setForm((prev) => ({
                  ...prev,
                  notificationChannel: e.target.value as WaitlistNotifyChannel,
                }))
              }
            >
              {channelOptions.map((channel) => (
                <option key={channel} value={channel}>
                  {channel.toUpperCase()}
                </option>
              ))}
            </select>
          </label>

          <label>
            Notes
            <textarea
              rows={3}
              value={form.notes ?? ''}
              onChange={(e) => setForm((prev) => ({ ...prev, notes: e.target.value }))}
              placeholder="Preferences, family members, urgency…"
            />
          </label>

          <div className="dialog-actions">
            <button type="button" onClick={onClose}>
              Cancel
            </button>
            <button type="submit" disabled={!canSubmit || submitting}>
              {submitting ? 'Saving…' : 'Add to waitlist'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}


