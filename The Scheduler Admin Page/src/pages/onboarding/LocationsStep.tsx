import type { StepProps } from './StepTypes';

export function LocationsStep({ draft, setDraft, disableInputs, onAddLocation }: StepProps) {
  if (!draft) return null;

  return (
    <div className="onboarding__card">
      <div className="onboarding__card-header">
        <h3>Locations</h3>
      </div>

      {draft.locations.length === 0 ? (
        <div className="onboarding__empty">
          <p>Add at least one location to continue.</p>
        </div>
      ) : (
        <div className="onboarding__list">
          {draft.locations.map((location, index) => (
            <div key={index} className="onboarding__list-item">
              <div className="onboarding__form-grid">
                <div className="onboarding__field">
                  <label className="onboarding__label">Location name</label>
                  <input
                    className="onboarding__input"
                    placeholder="e.g., Main Office"
                    value={location.name}
                    onChange={(e) =>
                      setDraft((prev) =>
                        prev
                          ? {
                              ...prev,
                              locations: prev.locations.map((loc, idx) =>
                                idx === index ? { ...loc, name: e.target.value } : loc,
                              ),
                            }
                          : prev,
                      )
                    }
                    disabled={disableInputs}
                  />
                </div>

                <div className="onboarding__field">
                  <label className="onboarding__label">Timezone</label>
                  <input
                    className="onboarding__input"
                    placeholder="e.g., America/New_York"
                    value={location.timezone ?? ''}
                    onChange={(e) =>
                      setDraft((prev) =>
                        prev
                          ? {
                              ...prev,
                              locations: prev.locations.map((loc, idx) =>
                                idx === index ? { ...loc, timezone: e.target.value } : loc,
                              ),
                            }
                          : prev,
                      )
                    }
                    disabled={disableInputs}
                  />
                </div>

                <div className="onboarding__field onboarding__field--full">
                  <label className="onboarding__label">Address</label>
                  <input
                    className="onboarding__input"
                    placeholder="Street address"
                    value={location.address ?? ''}
                    onChange={(e) =>
                      setDraft((prev) =>
                        prev
                          ? {
                              ...prev,
                              locations: prev.locations.map((loc, idx) =>
                                idx === index ? { ...loc, address: e.target.value } : loc,
                              ),
                            }
                          : prev,
                      )
                    }
                    disabled={disableInputs}
                  />
                </div>

                <div className="onboarding__field onboarding__field--full">
                  <label className="onboarding__label">Notes</label>
                  <input
                    className="onboarding__input"
                    placeholder="Any additional information"
                    value={location.notes ?? ''}
                    onChange={(e) =>
                      setDraft((prev) =>
                        prev
                          ? {
                              ...prev,
                              locations: prev.locations.map((loc, idx) =>
                                idx === index ? { ...loc, notes: e.target.value } : loc,
                              ),
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
        onClick={onAddLocation}
        disabled={disableInputs}
      >
        <span>+</span>
        <span>Add location</span>
      </button>
    </div>
  );
}
