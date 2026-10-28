import type { StepProps } from './StepTypes';

export function BusinessStep({ draft, setDraft, disableInputs }: StepProps) {
  if (!draft) return null;
  const basics = draft.businessBasics;
  const update = (key: keyof typeof basics, value: string) =>
    setDraft((prev) =>
      prev ? { ...prev, businessBasics: { ...prev.businessBasics, [key]: value } } : prev,
    );

  return (
    <div className="onboarding__card">
      <div className="onboarding__form-grid">
        <div className="onboarding__field">
          <label className="onboarding__label onboarding__label--required">Business name</label>
          <input
            type="text"
            className="onboarding__input"
            value={basics.businessName ?? ''}
            onChange={(e) => update('businessName', e.target.value)}
            disabled={disableInputs}
          />
        </div>

        <div className="onboarding__field">
          <label className="onboarding__label onboarding__label--required">Legal entity type</label>
          <input
            type="text"
            className="onboarding__input"
            value={basics.legalEntityType ?? ''}
            onChange={(e) => update('legalEntityType', e.target.value)}
            disabled={disableInputs}
          />
        </div>

        <div className="onboarding__field">
          <label className="onboarding__label onboarding__label--required">Timezone</label>
          <input
            type="text"
            className="onboarding__input"
            value={basics.timezone ?? ''}
            onChange={(e) => update('timezone', e.target.value)}
            disabled={disableInputs}
          />
        </div>

        <div className="onboarding__field">
          <label className="onboarding__label onboarding__label--required">Primary location name</label>
          <input
            type="text"
            className="onboarding__input"
            placeholder="e.g., Main Office"
            value={basics.primaryLocation ?? ''}
            onChange={(e) => update('primaryLocation', e.target.value)}
            disabled={disableInputs}
          />
        </div>

        <div className="onboarding__field onboarding__field--full">
          <label className="onboarding__label onboarding__label--required">Street address</label>
          <input
            type="text"
            className="onboarding__input"
            placeholder="e.g., 123 Main Street, Suite 100"
            value={basics.primaryLocationAddress?.street ?? ''}
            onChange={(e) =>
              setDraft((prev) =>
                prev
                  ? {
                      ...prev,
                      businessBasics: {
                        ...prev.businessBasics,
                        primaryLocationAddress: {
                          ...prev.businessBasics.primaryLocationAddress,
                          street: e.target.value,
                        },
                      },
                    }
                  : prev,
              )
            }
            disabled={disableInputs}
          />
        </div>

        <div className="onboarding__field">
          <label className="onboarding__label onboarding__label--required">City</label>
          <input
            type="text"
            className="onboarding__input"
            placeholder="e.g., San Francisco"
            value={basics.primaryLocationAddress?.city ?? ''}
            onChange={(e) =>
              setDraft((prev) =>
                prev
                  ? {
                      ...prev,
                      businessBasics: {
                        ...prev.businessBasics,
                        primaryLocationAddress: {
                          ...prev.businessBasics.primaryLocationAddress,
                          city: e.target.value,
                        },
                      },
                    }
                  : prev,
              )
            }
            disabled={disableInputs}
          />
        </div>

        <div className="onboarding__field">
          <label className="onboarding__label onboarding__label--required">State</label>
          <input
            type="text"
            className="onboarding__input"
            placeholder="e.g., CA"
            value={basics.primaryLocationAddress?.state ?? ''}
            onChange={(e) =>
              setDraft((prev) =>
                prev
                  ? {
                      ...prev,
                      businessBasics: {
                        ...prev.businessBasics,
                        primaryLocationAddress: {
                          ...prev.businessBasics.primaryLocationAddress,
                          state: e.target.value,
                        },
                      },
                    }
                  : prev,
              )
            }
            disabled={disableInputs}
          />
        </div>

        <div className="onboarding__field">
          <label className="onboarding__label onboarding__label--required">ZIP code</label>
          <input
            type="text"
            className="onboarding__input"
            placeholder="e.g., 94102"
            value={basics.primaryLocationAddress?.zip ?? ''}
            onChange={(e) =>
              setDraft((prev) =>
                prev
                  ? {
                      ...prev,
                      businessBasics: {
                        ...prev.businessBasics,
                        primaryLocationAddress: {
                          ...prev.businessBasics.primaryLocationAddress,
                          zip: e.target.value,
                        },
                      },
                    }
                  : prev,
              )
            }
            disabled={disableInputs}
          />
        </div>

        <div className="onboarding__field">
          <label className="onboarding__label">Country</label>
          <input
            type="text"
            className="onboarding__input"
            placeholder="e.g., US"
            value={basics.primaryLocationAddress?.country ?? 'US'}
            onChange={(e) =>
              setDraft((prev) =>
                prev
                  ? {
                      ...prev,
                      businessBasics: {
                        ...prev.businessBasics,
                        primaryLocationAddress: {
                          ...prev.businessBasics.primaryLocationAddress,
                          country: e.target.value,
                        },
                      },
                    }
                  : prev,
              )
            }
            disabled={disableInputs}
          />
        </div>

        <div className="onboarding__field">
          <label className="onboarding__label onboarding__label--required">Contact email</label>
          <input
            type="email"
            className="onboarding__input"
            value={basics.contactEmail ?? ''}
            onChange={(e) => update('contactEmail', e.target.value)}
            disabled={disableInputs}
          />
        </div>

        <div className="onboarding__field">
          <label className="onboarding__label">Contact phone</label>
          <input
            type="text"
            className="onboarding__input"
            value={basics.contactPhone ?? ''}
            onChange={(e) => update('contactPhone', e.target.value)}
            disabled={disableInputs}
          />
        </div>

        <div className="onboarding__field">
          <label className="onboarding__label">Website</label>
          <input
            type="text"
            className="onboarding__input"
            value={basics.website ?? ''}
            onChange={(e) => update('website', e.target.value)}
            disabled={disableInputs}
          />
        </div>

        <div className="onboarding__field onboarding__field--full">
          <label className="onboarding__label onboarding__label--required">Tagline</label>
          <input
            type="text"
            className="onboarding__input"
            value={basics.tagline ?? ''}
            onChange={(e) => update('tagline', e.target.value)}
            disabled={disableInputs}
          />
        </div>

        <div className="onboarding__field onboarding__field--full">
          <label className="onboarding__label">Logo URL</label>
          <input
            type="text"
            className="onboarding__input"
            value={basics.logoUrl ?? ''}
            onChange={(e) => update('logoUrl', e.target.value)}
            disabled={disableInputs}
          />
        </div>
      </div>
    </div>
  );
}
