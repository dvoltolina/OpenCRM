import { useEffect } from 'react';
import type { StepProps } from './StepTypes';

type HoursBlock = { start: string; end: string };

const QUICK_TEMPLATE: Array<{ day: string; isOpen: boolean; blocks: HoursBlock[] }> = [
  { day: 'monday', isOpen: true, blocks: [{ start: '09:00', end: '17:00' }] },
  { day: 'tuesday', isOpen: true, blocks: [{ start: '09:00', end: '17:00' }] },
  { day: 'wednesday', isOpen: true, blocks: [{ start: '09:00', end: '17:00' }] },
  { day: 'thursday', isOpen: true, blocks: [{ start: '09:00', end: '17:00' }] },
  { day: 'friday', isOpen: true, blocks: [{ start: '09:00', end: '17:00' }] },
  { day: 'saturday', isOpen: false, blocks: [] },
  { day: 'sunday', isOpen: false, blocks: [] },
];

export function SchedulingStep({ draft, setDraft, disableInputs, onAddService }: StepProps) {
  if (!draft) return null;
  const scheduling = draft.scheduling;
  const hours = scheduling.hours ?? QUICK_TEMPLATE;

  // Initialize hours in draft if not set (fixes continue button not working)
  useEffect(() => {
    if (!scheduling.hours) {
      setDraft((prev) =>
        prev
          ? {
              ...prev,
              scheduling: {
                ...prev.scheduling,
                hours: QUICK_TEMPLATE,
                operatingDays: QUICK_TEMPLATE.filter((d) => d.isOpen).map((d) => d.day),
              },
            }
          : prev,
      );
    }
  }, [scheduling.hours, setDraft]);

  const updateHours = (day: string, updater: (current: typeof hours[0]) => typeof hours[0]) => {
    setDraft((prev) =>
      prev
        ? {
            ...prev,
            scheduling: {
              ...prev.scheduling,
              hours: hours.map((entry) => (entry.day === day ? updater(entry) : entry)),
              operatingDays: hours
                .map((entry) => (entry.day === day ? updater(entry) : entry))
                .filter((d) => d.isOpen)
                .map((d) => d.day),
            },
          }
        : prev,
    );
  };

  const applyQuickTemplate = () => {
    setDraft((prev) =>
      prev
        ? {
            ...prev,
            scheduling: {
              ...prev.scheduling,
              hours: QUICK_TEMPLATE,
              operatingDays: QUICK_TEMPLATE.filter((d) => d.isOpen).map((d) => d.day),
            },
          }
        : prev,
    );
  };

  return (
    <div className="onboarding__card">
      {/* Operating Hours Section */}
      <div className="onboarding__section">
        <div className="onboarding__section-header">
          <h3>Operating hours</h3>
          <button
            className="onboarding__btn onboarding__btn--secondary"
            type="button"
            onClick={applyQuickTemplate}
            disabled={disableInputs}
          >
            Set 9-5 Mon-Fri
          </button>
        </div>

        <div className="onboarding__schedule">
          {hours.map((day) => (
            <div key={day.day} className="onboarding__schedule-day">
              <div className="onboarding__schedule-toggle">
                <label className="onboarding__checkbox">
                  <input
                    type="checkbox"
                    checked={day.isOpen}
                    onChange={(e) =>
                      updateHours(day.day, (curr) => ({
                        ...curr,
                        isOpen: e.target.checked,
                        blocks: e.target.checked && curr.blocks.length === 0 ? [{ start: '09:00', end: '17:00' }] : curr.blocks,
                      }))
                    }
                    disabled={disableInputs}
                  />
                  <span className="onboarding__schedule-day-name">{day.day}</span>
                </label>
              </div>

              {day.isOpen ? (
                <div className="onboarding__schedule-times">
                  {day.blocks.map((block, blockIdx) => (
                    <div key={blockIdx} style={{ display: 'flex', alignItems: 'center', gap: '8px', flex: 1 }}>
                      <input
                        type="time"
                        value={block.start}
                        onChange={(e) =>
                          updateHours(day.day, (curr) => ({
                            ...curr,
                            blocks: curr.blocks.map((b, idx) =>
                              idx === blockIdx ? { ...b, start: e.target.value } : b,
                            ),
                          }))
                        }
                        disabled={disableInputs}
                      />
                      <span style={{ color: 'var(--color-text-light)' }}>-</span>
                      <input
                        type="time"
                        value={block.end}
                        onChange={(e) =>
                          updateHours(day.day, (curr) => ({
                            ...curr,
                            blocks: curr.blocks.map((b, idx) =>
                              idx === blockIdx ? { ...b, end: e.target.value } : b,
                            ),
                          }))
                        }
                        disabled={disableInputs}
                      />
                      {day.blocks.length > 1 && (
                        <button
                          className="onboarding__list-item-remove"
                          type="button"
                          onClick={() =>
                            updateHours(day.day, (curr) => ({
                              ...curr,
                              blocks: curr.blocks.filter((_, idx) => idx !== blockIdx),
                            }))
                          }
                          disabled={disableInputs}
                        >
                          Remove
                        </button>
                      )}
                    </div>
                  ))}
                  {day.blocks.length < 3 && (
                    <button
                      className="onboarding__btn onboarding__btn--secondary"
                      type="button"
                      style={{ padding: '6px 12px', fontSize: '12px' }}
                      onClick={() =>
                        updateHours(day.day, (curr) => ({
                          ...curr,
                          blocks: [...curr.blocks, { start: '09:00', end: '17:00' }],
                        }))
                      }
                      disabled={disableInputs}
                    >
                      Add block
                    </button>
                  )}
                </div>
              ) : (
                <span className="onboarding__schedule-closed">Closed</span>
              )}
            </div>
          ))}
        </div>

        <div className="onboarding__divider" />

        <div className="onboarding__form-grid onboarding__form-grid--single">
          <div className="onboarding__field">
            <label className="onboarding__label onboarding__label--required">Self-booking access</label>
            <select
              className="onboarding__select"
              value={scheduling.selfBookingAccess}
              onChange={(e) =>
                setDraft((prev) =>
                  prev
                    ? {
                        ...prev,
                        scheduling: { ...prev.scheduling, selfBookingAccess: e.target.value as any },
                      }
                    : prev,
                )
              }
              disabled={disableInputs}
            >
              <option value="disabled">Disabled</option>
              <option value="existing_only">Existing clients only</option>
              <option value="all_customers">All customers</option>
            </select>
          </div>

          <label className="onboarding__checkbox">
            <input
              type="checkbox"
              checked={scheduling.requireDeposit}
              onChange={(e) =>
                setDraft((prev) =>
                  prev
                    ? { ...prev, scheduling: { ...prev.scheduling, requireDeposit: e.target.checked } }
                    : prev,
                )
              }
              disabled={disableInputs}
            />
            <span>Require deposit</span>
          </label>

          {scheduling.requireDeposit && (
            <div className="onboarding__form-grid">
              <div className="onboarding__field">
                <label className="onboarding__label">Deposit type</label>
                <select
                  className="onboarding__select"
                  value={scheduling.depositType ?? 'amount'}
                  onChange={(e) =>
                    setDraft((prev) =>
                      prev
                        ? { ...prev, scheduling: { ...prev.scheduling, depositType: e.target.value as any } }
                        : prev,
                    )
                  }
                  disabled={disableInputs}
                >
                  <option value="amount">Fixed amount</option>
                  <option value="percent">Percent</option>
                </select>
              </div>
              <div className="onboarding__field">
                <label className="onboarding__label">Deposit value</label>
                <input
                  className="onboarding__input"
                  type="number"
                  min={0}
                  value={scheduling.depositAmount ?? 0}
                  onChange={(e) =>
                    setDraft((prev) =>
                      prev
                        ? {
                            ...prev,
                            scheduling: { ...prev.scheduling, depositAmount: Number(e.target.value) },
                          }
                        : prev,
                    )
                  }
                  disabled={disableInputs}
                />
              </div>
            </div>
          )}

          <div className="onboarding__form-grid">
            <label className="onboarding__checkbox">
              <input
                type="checkbox"
                checked={scheduling.emailReminders}
                onChange={(e) =>
                  setDraft((prev) =>
                    prev
                      ? { ...prev, scheduling: { ...prev.scheduling, emailReminders: e.target.checked } }
                      : prev,
                  )
                }
                disabled={disableInputs}
              />
              <span>Email reminders</span>
            </label>

            <label className="onboarding__checkbox">
              <input
                type="checkbox"
                checked={scheduling.smsReminders}
                onChange={(e) =>
                  setDraft((prev) =>
                    prev ? { ...prev, scheduling: { ...prev.scheduling, smsReminders: e.target.checked } } : prev,
                  )
                }
                disabled={disableInputs}
              />
              <span>SMS reminders</span>
            </label>
          </div>

          <div className="onboarding__field">
            <label className="onboarding__label">Reminder lead time (hours)</label>
            <input
              className="onboarding__input"
              type="number"
              min={0}
              value={scheduling.reminderLeadTimeHours}
              onChange={(e) =>
                setDraft((prev) =>
                  prev
                    ? { ...prev, scheduling: { ...prev.scheduling, reminderLeadTimeHours: Number(e.target.value) } }
                    : prev,
                )
              }
              disabled={disableInputs}
            />
          </div>

          <div className="onboarding__field">
            <label className="onboarding__label">Communications preferences (optional)</label>
            <textarea
              className="onboarding__textarea"
              value={scheduling.communicationNotes ?? ''}
              onChange={(e) =>
                setDraft((prev) =>
                  prev
                    ? { ...prev, scheduling: { ...prev.scheduling, communicationNotes: e.target.value } }
                    : prev,
                )
              }
              disabled={disableInputs}
            />
          </div>
        </div>
      </div>

      <div className="onboarding__divider" />

      {/* Services Section */}
      <div className="onboarding__section">
        <div className="onboarding__section-header">
          <h3>Services</h3>
        </div>

        {scheduling.services.length === 0 ? (
          <div className="onboarding__empty">
            <p>Add at least one service to continue.</p>
          </div>
        ) : (
          <div className="onboarding__list">
            {scheduling.services.map((service, index) => (
              <div key={index} className="onboarding__list-item">
                <div className="onboarding__form-grid onboarding__form-grid--triple">
                  <div className="onboarding__field">
                    <label className="onboarding__label">Service name</label>
                    <input
                      className="onboarding__input"
                      placeholder="e.g., General Consultation"
                      value={service.name}
                      onChange={(e) =>
                        setDraft((prev) =>
                          prev
                            ? {
                                ...prev,
                                scheduling: {
                                  ...prev.scheduling,
                                  services: prev.scheduling.services.map((s, idx) =>
                                    idx === index ? { ...s, name: e.target.value } : s,
                                  ),
                                },
                              }
                            : prev,
                        )
                      }
                      disabled={disableInputs}
                    />
                  </div>

                  <div className="onboarding__field">
                    <label className="onboarding__label">Duration (min)</label>
                    <input
                      className="onboarding__input"
                      type="number"
                      placeholder="30"
                      value={service.durationMinutes ?? ''}
                      onChange={(e) =>
                        setDraft((prev) =>
                          prev
                            ? {
                                ...prev,
                                scheduling: {
                                  ...prev.scheduling,
                                  services: prev.scheduling.services.map((s, idx) =>
                                    idx === index ? { ...s, durationMinutes: Number(e.target.value) } : s,
                                  ),
                                },
                              }
                            : prev,
                        )
                      }
                      disabled={disableInputs}
                    />
                  </div>

                  <div className="onboarding__field">
                    <label className="onboarding__label">Price</label>
                    <input
                      className="onboarding__input"
                      type="number"
                      placeholder="0.00"
                      value={service.price ?? ''}
                      onChange={(e) =>
                        setDraft((prev) =>
                          prev
                            ? {
                                ...prev,
                                scheduling: {
                                  ...prev.scheduling,
                                  services: prev.scheduling.services.map((s, idx) =>
                                    idx === index ? { ...s, price: Number(e.target.value) } : s,
                                  ),
                                },
                              }
                            : prev,
                        )
                      }
                      disabled={disableInputs}
                    />
                  </div>
                </div>

                <div className="onboarding__form-grid">
                  <div className="onboarding__field">
                    <label className="onboarding__label">Category (optional)</label>
                    <input
                      className="onboarding__input"
                      placeholder="e.g., Therapy"
                      value={service.category ?? ''}
                      onChange={(e) =>
                        setDraft((prev) =>
                          prev
                            ? {
                                ...prev,
                                scheduling: {
                                  ...prev.scheduling,
                                  services: prev.scheduling.services.map((s, idx) =>
                                    idx === index ? { ...s, category: e.target.value } : s,
                                  ),
                                },
                              }
                            : prev,
                        )
                      }
                      disabled={disableInputs}
                    />
                  </div>

                  <div className="onboarding__field">
                    <label className="onboarding__label">Description (optional)</label>
                    <input
                      className="onboarding__input"
                      placeholder="Brief description"
                      value={service.description ?? ''}
                      onChange={(e) =>
                        setDraft((prev) =>
                          prev
                            ? {
                                ...prev,
                                scheduling: {
                                  ...prev.scheduling,
                                  services: prev.scheduling.services.map((s, idx) =>
                                    idx === index ? { ...s, description: e.target.value } : s,
                                  ),
                                },
                              }
                            : prev,
                        )
                      }
                      disabled={disableInputs}
                    />
                  </div>
                </div>

                <div className="onboarding__form-grid">
                  <div className="onboarding__field">
                    <label className="onboarding__label">Buffer before (min)</label>
                    <input
                      className="onboarding__input"
                      type="number"
                      placeholder="0"
                      value={service.bufferBefore ?? ''}
                      onChange={(e) =>
                        setDraft((prev) =>
                          prev
                            ? {
                                ...prev,
                                scheduling: {
                                  ...prev.scheduling,
                                  services: prev.scheduling.services.map((s, idx) =>
                                    idx === index ? { ...s, bufferBefore: Number(e.target.value) } : s,
                                  ),
                                },
                              }
                            : prev,
                        )
                      }
                      disabled={disableInputs}
                    />
                  </div>

                  <div className="onboarding__field">
                    <label className="onboarding__label">Buffer after (min)</label>
                    <input
                      className="onboarding__input"
                      type="number"
                      placeholder="0"
                      value={service.bufferAfter ?? ''}
                      onChange={(e) =>
                        setDraft((prev) =>
                          prev
                            ? {
                                ...prev,
                                scheduling: {
                                  ...prev.scheduling,
                                  services: prev.scheduling.services.map((s, idx) =>
                                    idx === index ? { ...s, bufferAfter: Number(e.target.value) } : s,
                                  ),
                                },
                              }
                            : prev,
                        )
                      }
                      disabled={disableInputs}
                    />
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        <button
          className="onboarding__add-btn"
          type="button"
          onClick={onAddService}
          disabled={disableInputs}
        >
          <span>+</span>
          <span>Add service</span>
        </button>
      </div>
    </div>
  );
}
