import { useEffect, useMemo, useState } from 'react';

import type {
  Location,
  LocationInput,
  OperatingHoursDay,
} from '../../types/models';
import { formatOperatingHours } from '../../lib/operatingHours';
import type { StaffOption } from './locationTypes';

type OperatingHoursBlock = OperatingHoursDay['blocks'][number];

const DAY_ORDER: OperatingHoursDay['day'][] = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

const DEFAULT_OPERATING_HOURS: OperatingHoursDay[] = DAY_ORDER.map((day) => ({
  day,
  isOpen: ['saturday', 'sunday'].includes(day) ? false : true,
  blocks: ['saturday', 'sunday'].includes(day) ? [] : [{ start: '09:00', end: '17:00' }],
}));

const EMPTY_FORM: LocationInput = {
  name: '',
  address: '',
  timezone: 'America/New_York',
  hours: '',
  operatingHours: DEFAULT_OPERATING_HOURS,
  staffIds: [],
  notes: '',
  phone: '',
  email: '',
  status: 'active',
  tags: [],
  capacity: 0,
  parkingInfo: '',
};

const cloneHours = (hours: OperatingHoursDay[]): OperatingHoursDay[] =>
  hours.map((day) => ({
    day: day.day,
    isOpen: day.isOpen ?? false,
    blocks: (day.blocks ?? []).map((b) => ({ ...b })),
  }));

const normalizeOperatingHours = (
  input?: OperatingHoursDay[] | Location | null,
): OperatingHoursDay[] => {
  const source = Array.isArray(input)
    ? input
    : Array.isArray(input?.operatingHours) && input?.operatingHours.length
      ? (input?.operatingHours as OperatingHoursDay[])
      : Array.isArray(input?.hours)
        ? (input?.hours as OperatingHoursDay[])
        : DEFAULT_OPERATING_HOURS;

  const lookup = new Map<string, OperatingHoursDay>(
    source.map((day) => [day.day ?? '', { ...day, blocks: day.blocks ?? [] }]),
  );

  return DAY_ORDER.map((dayKey) => {
    const entry = lookup.get(dayKey);
    if (entry) {
      return {
        day: dayKey,
        isOpen: entry.isOpen ?? false,
        blocks: (entry.blocks ?? []).map((b) => ({ ...b })),
      };
    }
    return { day: dayKey, isOpen: false, blocks: [] };
  });
};

function OperatingHoursEditor({
  hours,
  onChange,
}: {
  hours: OperatingHoursDay[];
  onChange: (next: OperatingHoursDay[]) => void;
}) {
  const applyTemplate = () => onChange(cloneHours(DEFAULT_OPERATING_HOURS));

  const updateDay = (dayName: string, updater: (current: OperatingHoursDay) => OperatingHoursDay) => {
    onChange(
      hours.map((day) => (day.day === dayName ? updater(day) : day)),
    );
  };

  return (
    <div className="stack" style={{ gap: 12 }}>
      <div className="grid grid--2" style={{ alignItems: 'center' }}>
        <h4 style={{ margin: 0 }}>Operating hours</h4>
        <div style={{ textAlign: 'right' }}>
          <button
            type="button"
            className="button button--ghost"
            onClick={applyTemplate}
          >
            Set Mon-Fri 9-5
          </button>
        </div>
      </div>
      <div className="stack" style={{ gap: 8 }}>
        {hours.map((day) => (
          <div key={day.day} className="panel" style={{ padding: 12, margin: 0 }}>
            <div className="grid grid--2" style={{ alignItems: 'center' }}>
              <label className="meta-row" style={{ gap: 8 }}>
                <input
                  type="checkbox"
                  checked={day.isOpen}
                  onChange={(e) =>
                    updateDay(day.day, (curr) => ({
                      ...curr,
                      isOpen: e.target.checked,
                      blocks:
                        e.target.checked && (!curr.blocks || curr.blocks.length === 0)
                          ? [{ start: '09:00', end: '17:00' }]
                          : curr.blocks ?? [],
                    }))
                  }
                />
                <span style={{ textTransform: 'capitalize' }}>{day.day}</span>
              </label>
              {day.isOpen && (
                <button
                  type="button"
                  className="button button--ghost"
                  onClick={() =>
                    updateDay(day.day, (curr) => ({
                      ...curr,
                      blocks: [...(curr.blocks ?? []), { start: '09:00', end: '17:00' }].slice(
                        0,
                        3,
                      ),
                    }))
                  }
                  disabled={(day.blocks?.length ?? 0) >= 3}
                >
                  Add block
                </button>
              )}
            </div>
            {day.isOpen ? (
              <div className="stack" style={{ gap: 8 }}>
                {(day.blocks ?? []).map((block: OperatingHoursBlock, idx: number) => (
                  <div key={idx} className="grid grid--3" style={{ alignItems: 'center' }}>
                    <input
                      type="time"
                      value={block.start ?? ''}
                      onChange={(e) =>
                        updateDay(day.day, (curr) => ({
                          ...curr,
                          blocks: (curr.blocks ?? []).map((b, bIdx) =>
                            bIdx === idx ? { ...b, start: e.target.value } : b,
                          ),
                        }))
                      }
                    />
                    <input
                      type="time"
                      value={block.end ?? ''}
                      onChange={(e) =>
                        updateDay(day.day, (curr) => ({
                          ...curr,
                          blocks: (curr.blocks ?? []).map((b, bIdx) =>
                            bIdx === idx ? { ...b, end: e.target.value } : b,
                          ),
                        }))
                      }
                    />
                    {(day.blocks?.length ?? 0) > 1 && (
                      <button
                        type="button"
                        className="button button--ghost"
                        onClick={() =>
                          updateDay(day.day, (curr) => ({
                            ...curr,
                            blocks: (curr.blocks ?? []).filter((_, bIdx) => bIdx !== idx),
                          }))
                        }
                      >
                        Remove
                      </button>
                    )}
                  </div>
                ))}
              </div>
            ) : (
              <p className="muted" style={{ margin: 0 }}>
                Closed
              </p>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}

export function LocationDialog({
  location,
  staffOptions,
  onClose,
  onSave,
}: {
  location: Location | null;
  staffOptions: StaffOption[];
  onClose: () => void;
  onSave: (input: LocationInput) => void;
}) {
  const [operatingHours, setOperatingHours] = useState<OperatingHoursDay[]>(() =>
    normalizeOperatingHours(location),
  );

  const buildFormState = (input: Location | null | undefined, hoursState: OperatingHoursDay[]): LocationInput => {
    if (!input) return { ...EMPTY_FORM, operatingHours: hoursState };
    const { id: _id, businessId: _businessId, ...rest } = input;
    const derivedHours = formatOperatingHours(hoursState, rest.hours ?? '');
    return {
      ...EMPTY_FORM,
      ...rest,
      hours: rest.hours || derivedHours,
      operatingHours: hoursState,
    };
  };

  const [form, setForm] = useState<LocationInput>(() => buildFormState(location, operatingHours));

  useEffect(() => {
    const nextHours = normalizeOperatingHours(location);
    setOperatingHours(nextHours);
    setForm(buildFormState(location, nextHours));
  }, [location]);

  // Close dialog on Escape key
  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        onClose();
      }
    };
    window.addEventListener('keydown', handleEscape);
    return () => window.removeEventListener('keydown', handleEscape);
  }, [onClose]);

  const hoursPreview = useMemo(
    () => formatOperatingHours(operatingHours, 'Not set'),
    [operatingHours],
  );

  const handleSubmit = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const hoursLabel = (form.hours ?? '').trim() || hoursPreview;
    onSave({
      ...form,
      hours: hoursLabel,
      operatingHours: cloneHours(operatingHours),
      tags: form.tags?.filter(Boolean),
    });
  };

  const toggleStaff = (id: string) => {
    setForm((prev) => ({
      ...prev,
      staffIds: prev.staffIds.includes(id)
        ? prev.staffIds.filter((staffId) => staffId !== id)
        : [...prev.staffIds, id],
    }));
  };

  return (
    <div
      className="dialog-overlay"
      onClick={onClose}
      role="dialog"
      aria-modal="true"
      aria-labelledby="location-dialog-title"
    >
      <div className="dialog" onClick={(e) => e.stopPropagation()}>
        <h2 id="location-dialog-title">{location ? 'Edit location' : 'New location'}</h2>
        <form className="stack" onSubmit={handleSubmit}>
          <label>
            Name
            <input
              type="text"
              value={form.name}
              onChange={(e) => setForm((prev) => ({ ...prev, name: e.target.value }))}
              required
            />
          </label>
          <label>
            Address
            <input
              type="text"
              value={form.address}
              onChange={(e) => setForm((prev) => ({ ...prev, address: e.target.value }))}
              required
            />
          </label>
          <div className="grid grid--2">
            <label>
              Timezone
              <input
                type="text"
                value={form.timezone}
                onChange={(e) => setForm((prev) => ({ ...prev, timezone: e.target.value }))}
                placeholder="America/New_York"
                required
              />
            </label>
            <label>
              Display label (optional)
              <input
                type="text"
                value={form.hours ?? hoursPreview}
                onChange={(e) => setForm((prev) => ({ ...prev, hours: e.target.value }))}
                placeholder={hoursPreview}
              />
              <span className="muted" style={{ fontSize: 12 }}>Auto-generated from blocks if left blank.</span>
            </label>
          </div>

          <OperatingHoursEditor hours={operatingHours} onChange={setOperatingHours} />

          <div className="grid grid--2">
            <label>
              Phone
              <input
                type="tel"
                value={form.phone ?? ''}
                onChange={(e) => setForm((prev) => ({ ...prev, phone: e.target.value }))}
              />
            </label>
            <label>
              Email
              <input
                type="email"
                value={form.email ?? ''}
                onChange={(e) => setForm((prev) => ({ ...prev, email: e.target.value }))}
              />
            </label>
          </div>
          <div className="grid grid--2">
            <label>
              Status
              <select
                value={form.status ?? 'active'}
                onChange={(e) =>
                  setForm((prev) => ({ ...prev, status: e.target.value as LocationInput['status'] }))
                }
              >
                <option value="active">Active</option>
                <option value="inactive">Inactive</option>
              </select>
            </label>
            <label>
              Capacity
              <input
                type="number"
                min={0}
                value={form.capacity ?? 0}
                onChange={(e) =>
                  setForm((prev) => ({ ...prev, capacity: Number(e.target.value) || 0 }))
                }
              />
            </label>
          </div>
          <label>
            Tags (comma separated)
            <input
              type="text"
              value={form.tags?.join(', ') ?? ''}
              onChange={(e) =>
                setForm((prev) => ({
                  ...prev,
                  tags: e.target.value
                    .split(',')
                    .map((tag) => tag.trim())
                    .filter(Boolean),
                }))
              }
              placeholder="flagship, ortho"
            />
          </label>
          <label>
            Notes
            <textarea
              rows={3}
              value={form.notes ?? ''}
              onChange={(e) => setForm((prev) => ({ ...prev, notes: e.target.value }))}
              placeholder="Access codes, special instructions, etc."
            />
          </label>
          <label>
            Parking info
            <textarea
              rows={2}
              value={form.parkingInfo ?? ''}
              onChange={(e) => setForm((prev) => ({ ...prev, parkingInfo: e.target.value }))}
              placeholder="Garage entrance, validation rules, etc."
            />
          </label>
          <fieldset>
            <legend>Assigned staff</legend>
            <div className="chip-row chip-row--wrap">
              {staffOptions.map((option) => (
                <label key={option.id} className="chip chip--outline" style={{ cursor: 'pointer' }}>
                  <input
                    type="checkbox"
                    checked={form.staffIds.includes(option.id)}
                    onChange={() => toggleStaff(option.id)}
                  />
                  {option.label} · {option.role}
                </label>
              ))}
            </div>
          </fieldset>
          <div className="dialog-actions">
            <button type="button" onClick={onClose} aria-label="Cancel">
              Cancel
            </button>
            <button type="submit" aria-label={location ? 'Save location changes' : 'Create new location'}>
              Save location
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
