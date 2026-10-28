import type { StepProps } from './StepTypes';

export function TeamStep({ draft, setDraft, disableInputs, onAddInvite, crmEnabled, crmDisabledReason }: StepProps) {
  if (!draft) return null;
  const invites = draft.team.invites;
  const locations = draft.locations ?? [];

  const toggleModule = (index: number, key: keyof NonNullable<(typeof invites)[number]['moduleAccess']>) => {
    setDraft((prev) =>
      prev
        ? {
            ...prev,
            team: {
              ...prev.team,
              invites: prev.team.invites.map((inv, idx) =>
                idx === index
                  ? {
                      ...inv,
                      moduleAccess: {
                        scheduling: inv.moduleAccess?.scheduling ?? false,
                        clients: inv.moduleAccess?.clients ?? false,
                        marketing: inv.moduleAccess?.marketing ?? false,
                        reporting: inv.moduleAccess?.reporting ?? false,
                        billing: inv.moduleAccess?.billing ?? false,
                        settings: inv.moduleAccess?.settings ?? false,
                        [key]: !(inv.moduleAccess?.[key] ?? false),
                      },
                    }
                  : inv,
              ),
            },
          }
        : prev,
    );
  };

  const toggleLocation = (index: number, locationId: string) => {
    setDraft((prev) =>
      prev
        ? {
            ...prev,
            team: {
              ...prev.team,
              invites: prev.team.invites.map((inv, idx) =>
                idx === index
                  ? {
                      ...inv,
                      locationIds: inv.locationIds?.includes(locationId)
                        ? inv.locationIds.filter((id) => id !== locationId)
                        : [...(inv.locationIds ?? []), locationId],
                    }
                  : inv,
              ),
            },
          }
        : prev,
    );
  };

  return (
    <div className="onboarding__card">
      <div className="onboarding__card-header">
        <h3>Invite your team members</h3>
        <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
          <label className="onboarding__checkbox">
            <input
              type="checkbox"
              checked={draft.team.skipped}
              onChange={(e) =>
                setDraft((prev) =>
                  prev ? { ...prev, team: { ...prev.team, skipped: e.target.checked } } : prev,
                )
              }
              disabled={disableInputs}
            />
            <span>Skip for now</span>
          </label>
          <button className="onboarding__btn onboarding__btn--secondary" type="button" onClick={onAddInvite} disabled={disableInputs}>
            + Add invite
          </button>
        </div>
      </div>

      {invites.length === 0 && (
        <div className="onboarding__empty">
          <p>No team members invited yet. Add your first invite to get started.</p>
        </div>
      )}

      {invites.length > 0 && (
        <div className="onboarding__list">
          {invites.map((invite, index) => (
            <div key={index} className="onboarding__list-item">
              <div className="onboarding__list-item-header">
                <div className="onboarding__list-item-title">
                  {invite.email || `Invite ${index + 1}`}
                </div>
              </div>

              <div className="onboarding__form-grid">
                <div className="onboarding__field">
                  <label className="onboarding__label onboarding__label--required">Email</label>
                  <input
                    className="onboarding__input"
                    placeholder="team@example.com"
                    value={invite.email}
                    onChange={(e) =>
                      setDraft((prev) =>
                        prev
                          ? {
                              ...prev,
                              team: {
                                ...prev.team,
                                invites: prev.team.invites.map((inv, idx) =>
                                  idx === index ? { ...inv, email: e.target.value } : inv,
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
                  <label className="onboarding__label onboarding__label--required">Role</label>
                  <select
                    className="onboarding__select"
                    value={invite.role}
                    onChange={(e) =>
                      setDraft((prev) =>
                        prev
                          ? {
                              ...prev,
                              team: {
                                ...prev.team,
                                invites: prev.team.invites.map((inv, idx) =>
                                  idx === index ? { ...inv, role: e.target.value as any } : inv,
                                ),
                              },
                            }
                          : prev,
                      )
                    }
                    disabled={disableInputs}
                  >
                    <option value="admin">Admin</option>
                    <option value="manager">Manager</option>
                    <option value="staff">Staff</option>
                    <option value="provider">Provider</option>
                    <option value="frontDesk">Front Desk</option>
                    <option value="sales">Sales</option>
                  </select>
                </div>
              </div>

              <div style={{ display: 'flex', gap: 16, marginTop: 16, flexWrap: 'wrap' }}>
                <label className="onboarding__checkbox">
                  <input
                    type="checkbox"
                    checked={invite.isProvider}
                    onChange={(e) =>
                      setDraft((prev) =>
                        prev
                          ? {
                              ...prev,
                              team: {
                                ...prev.team,
                                invites: prev.team.invites.map((inv, idx) =>
                                  idx === index ? { ...inv, isProvider: e.target.checked } : inv,
                                ),
                              },
                            }
                          : prev,
                      )
                    }
                    disabled={disableInputs}
                  />
                  <span>Is Provider</span>
                </label>

                <label className={`onboarding__checkbox ${!crmEnabled ? 'onboarding__checkbox--disabled' : ''}`}>
                  <input
                    type="checkbox"
                    checked={Boolean(invite.crmAccess)}
                    onChange={(e) =>
                      setDraft((prev) =>
                        prev
                          ? {
                              ...prev,
                              team: {
                                ...prev.team,
                                invites: prev.team.invites.map((inv, idx) =>
                                  idx === index ? { ...inv, crmAccess: e.target.checked } : inv,
                                ),
                              },
                            }
                          : prev,
                      )
                    }
                    disabled={disableInputs || !crmEnabled}
                    title={!crmEnabled ? crmDisabledReason : undefined}
                  />
                  <span>
                    Requires CRM access
                    {!crmEnabled && (
                      <span style={{ marginLeft: 8, fontSize: 13, color: 'var(--color-text-light)' }}>
                        ({crmDisabledReason || 'CRM not included in current plan'})
                      </span>
                    )}
                  </span>
                </label>
              </div>

              <div className="onboarding__divider"></div>

              <div className="onboarding__field">
                <label className="onboarding__label">Module Permissions</label>
                <div className="onboarding__permissions">
                  {[
                    ['Scheduling', 'scheduling'],
                    ['Clients', 'clients'],
                    ['Marketing', 'marketing'],
                    ['Reporting', 'reporting'],
                    ['Billing', 'billing'],
                    ['Settings', 'settings'],
                  ].map(([label, key]) => (
                    <label key={key} className="onboarding__permission-chip">
                      <input
                        type="checkbox"
                        checked={Boolean(invite.moduleAccess?.[key as keyof typeof invite.moduleAccess])}
                        onChange={() => toggleModule(index, key as keyof NonNullable<typeof invite.moduleAccess>)}
                        disabled={disableInputs}
                      />
                      {label}
                    </label>
                  ))}
                </div>
              </div>

              {locations.length > 0 && (
                <div className="onboarding__field" style={{ marginTop: 16 }}>
                  <label className="onboarding__label">Location Access</label>
                  <div className="onboarding__permissions">
                    {locations.map((loc, locIndex) => (
                      <label key={locIndex} className="onboarding__permission-chip">
                        <input
                          type="checkbox"
                          checked={invite.locationIds?.includes(loc.name) ?? false}
                          onChange={() => toggleLocation(index, loc.name)}
                          disabled={disableInputs}
                        />
                        {loc.name || `Location ${locIndex + 1}`}
                      </label>
                    ))}
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

export function ComplianceStep({ draft, setDraft, disableInputs }: StepProps) {
  if (!draft) return null;
  const compliance = draft.compliance;

  return (
    <div className="onboarding__card">
      <div className="onboarding__card-header">
        <h3>HIPAA Compliance & Security</h3>
      </div>

      <div className="onboarding__alert onboarding__alert--info">
        <div className="onboarding__alert-content">
          <h4>Healthcare Data Protection</h4>
          <p>
            These compliance settings are required for HIPAA-compliant healthcare scheduling.
            Please review and acknowledge each requirement carefully.
          </p>
        </div>
      </div>

      <div className="onboarding__form-grid onboarding__form-grid--single">
        <label className="onboarding__checkbox">
          <input
            type="checkbox"
            checked={compliance.hipaaAcknowledged}
            onChange={(e) =>
              setDraft((prev) =>
                prev ? { ...prev, compliance: { ...prev.compliance, hipaaAcknowledged: e.target.checked } } : prev,
              )
            }
            disabled={disableInputs}
          />
          <span>
            <strong>HIPAA Acknowledgment (Required)</strong>
            <br />
            <span style={{ fontSize: 13, color: 'var(--color-text-muted)' }}>
              I acknowledge that this system will handle Protected Health Information (PHI) and must comply with HIPAA regulations.
            </span>
          </span>
        </label>

        <label className="onboarding__checkbox">
          <input
            type="checkbox"
            checked={compliance.mfaReminderAcknowledged}
            onChange={(e) =>
              setDraft((prev) =>
                prev
                  ? { ...prev, compliance: { ...prev.compliance, mfaReminderAcknowledged: e.target.checked } }
                  : prev,
              )
            }
            disabled={disableInputs}
          />
          <span>
            <strong>Multi-Factor Authentication (Required)</strong>
            <br />
            <span style={{ fontSize: 13, color: 'var(--color-text-muted)' }}>
              I understand that MFA is required for all users accessing PHI to ensure secure authentication.
            </span>
          </span>
        </label>

        <label className="onboarding__checkbox">
          <input
            type="checkbox"
            checked={compliance.phiLoggingSafeguards}
            onChange={(e) =>
              setDraft((prev) =>
                prev
                  ? { ...prev, compliance: { ...prev.compliance, phiLoggingSafeguards: e.target.checked } }
                  : prev,
              )
            }
            disabled={disableInputs}
          />
          <span>
            <strong>PHI Logging Safeguards (Required)</strong>
            <br />
            <span style={{ fontSize: 13, color: 'var(--color-text-muted)' }}>
              I acknowledge that Protected Health Information must never be logged in plain text or stored in system logs.
            </span>
          </span>
        </label>
      </div>

      <div className="onboarding__divider"></div>

      <div className="onboarding__form-grid">
        <div className="onboarding__field onboarding__field--full">
          <label className="onboarding__label">Allowed Email Domains (Optional)</label>
          <input
            className="onboarding__input"
            placeholder="example.com, hospital.org"
            value={(compliance.allowedDomains ?? []).join(', ')}
            onChange={(e) =>
              setDraft((prev) =>
                prev
                  ? {
                      ...prev,
                      compliance: {
                        ...prev.compliance,
                        allowedDomains: e.target.value
                          .split(',')
                          .map((d) => d.trim())
                          .filter(Boolean),
                      },
                    }
                  : prev,
              )
            }
            disabled={disableInputs}
          />
          <span style={{ fontSize: 13, color: 'var(--color-text-light)', marginTop: 4 }}>
            Restrict team invitations to specific email domains (comma-separated)
          </span>
        </div>

        <div className="onboarding__field">
          <label className="onboarding__label">Data Retention Period (Optional)</label>
          <input
            className="onboarding__input"
            type="number"
            min={0}
            placeholder="e.g., 60"
            value={compliance.dataRetentionMonths ?? ''}
            onChange={(e) =>
              setDraft((prev) =>
                prev
                  ? { ...prev, compliance: { ...prev.compliance, dataRetentionMonths: Number(e.target.value) } }
                  : prev,
              )
            }
            disabled={disableInputs}
          />
          <span style={{ fontSize: 13, color: 'var(--color-text-light)', marginTop: 4 }}>
            Number of months to retain patient data
          </span>
        </div>
      </div>
    </div>
  );
}

export function BillingStep({ billingProfile }: StepProps) {
  const addOnLabels: Record<string, string> = {
    'addon-reports': 'Advanced Reports',
    'addon-import-export': 'Import/Export',
    'addon-marketing': 'Marketing',
  };

  const addOns =
    billingProfile?.addOnIds?.map((id) => addOnLabels[id] || id) ??
    billingProfile?.addonIds?.map((id) => addOnLabels[id] || id) ??
    [];

  return (
    <div className="onboarding__card">
      <div className="onboarding__card-header">
        <h3>Billing Overview</h3>
        <span className="onboarding__plan-badge">
          {billingProfile?.status ?? 'Incomplete'}
        </span>
      </div>

      <div className="onboarding__billing-summary">
        <div className="onboarding__billing-item">
          <h4>Current Plan</h4>
          <p>{billingProfile?.planName ?? billingProfile?.planId ?? 'No plan selected'}</p>
        </div>
        <div className="onboarding__billing-item">
          <h4>Seats</h4>
          <p>{billingProfile?.seats ?? 0}</p>
        </div>
        <div className="onboarding__billing-item">
          <h4>Add-ons</h4>
          <p>{addOns.length ? addOns.join(', ') : 'None'}</p>
        </div>
      </div>

      <div className="onboarding__divider"></div>

      <div className="onboarding__field">
        <label className="onboarding__label">Plan Entitlements</label>
        {billingProfile?.entitlements?.length ? (
          <div className="onboarding__form-grid">
            {billingProfile.entitlements.map((entitlement) => (
              <div key={entitlement.id} className="onboarding__list-item">
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span style={{ fontSize: 14, fontWeight: 500 }}>{entitlement.label}</span>
                  <span className={`status status--${entitlement.enabled ? 'confirmed' : 'pending'}`}>
                    {entitlement.enabled ? 'Enabled' : 'Pending'}
                  </span>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="onboarding__empty">
            <p>Entitlements will appear once billing is completed.</p>
          </div>
        )}
      </div>

      <div className="onboarding__alert onboarding__alert--info" style={{ marginTop: 20 }}>
        <div className="onboarding__alert-content">
          <p>
            Billing changes are managed on the Billing page. Contact an owner to update your plan or add seats.
          </p>
        </div>
      </div>
    </div>
  );
}

export function IntegrationsStep({ draft, setDraft, disableInputs }: StepProps) {
  if (!draft) return null;
  const integrations = draft.integrations;

  return (
    <div className="onboarding__card">
      <div className="onboarding__card-header">
        <h3>Integrations & Data Setup</h3>
      </div>

      <div className="onboarding__form-grid">
        <div className="onboarding__field">
          <label className="onboarding__label">Data Import Preference</label>
          <select
            className="onboarding__select"
            value={integrations.importPreference ?? 'none'}
            onChange={(e) =>
              setDraft((prev) =>
                prev
                  ? { ...prev, integrations: { ...prev.integrations, importPreference: e.target.value as any } }
                  : prev,
              )
            }
            disabled={disableInputs}
          >
            <option value="none">Skip for now</option>
            <option value="csv">CSV upload</option>
            <option value="api">API connector</option>
          </select>
        </div>
      </div>

      <div className="onboarding__divider"></div>

      <div className="onboarding__field">
        <label className="onboarding__label">Integration Options</label>
        <div className="onboarding__form-grid onboarding__form-grid--single">
          <label className="onboarding__checkbox">
            <input
              type="checkbox"
              checked={integrations.calendarSyncPlanned}
              onChange={(e) =>
                setDraft((prev) =>
                  prev
                    ? { ...prev, integrations: { ...prev.integrations, calendarSyncPlanned: e.target.checked } }
                    : prev,
                )
              }
              disabled={disableInputs}
            />
            <span>
              <strong>Enable Calendar Sync</strong>
              <br />
              <span style={{ fontSize: 13, color: 'var(--color-text-muted)' }}>
                Sync appointments with Google Calendar, Outlook, or other calendar providers
              </span>
            </span>
          </label>

          <label className="onboarding__checkbox">
            <input
              type="checkbox"
              checked={integrations.paymentsReady}
              onChange={(e) =>
                setDraft((prev) =>
                  prev ? { ...prev, integrations: { ...prev.integrations, paymentsReady: e.target.checked } } : prev,
                )
              }
              disabled={disableInputs}
            />
            <span>
              <strong>Payment Settings Confirmed</strong>
              <br />
              <span style={{ fontSize: 13, color: 'var(--color-text-muted)' }}>
                Payment processor is configured and ready to accept payments
              </span>
            </span>
          </label>
        </div>
      </div>
    </div>
  );
}

export function ReviewStep({ draft }: StepProps) {
  if (!draft) return null;

  return (
    <div className="onboarding__card">
      <div className="onboarding__card-header">
        <h3>Review Your Setup</h3>
      </div>

      <div className="onboarding__review-grid">
        <div className="onboarding__review-card">
          <h4>Business Information</h4>
          <p>{draft.businessBasics.businessName}</p>
          <p className="muted">{draft.businessBasics.industry}</p>
          <p className="muted">Location: {draft.businessBasics.primaryLocation}</p>
        </div>

        <div className="onboarding__review-card">
          <h4>Scheduling Setup</h4>
          <p>{draft.scheduling.services.length} service{draft.scheduling.services.length !== 1 ? 's' : ''} configured</p>
          <p className="muted">
            Operating: {draft.scheduling.hours?.filter((h) => h.isOpen).map((h) => h.day).join(', ') || 'Not set'}
          </p>
          {draft.scheduling.requireDeposit && (
            <p className="muted">
              Deposit: {draft.scheduling.depositAmount ?? 0}
              {draft.scheduling.depositType === 'percent' ? '%' : ' fixed'}
            </p>
          )}
        </div>

        <div className="onboarding__review-card">
          <h4>Team Members</h4>
          <p>{draft.team.invites.length} invite{draft.team.invites.length !== 1 ? 's' : ''} pending</p>
          {draft.team.invites.length > 0 && (
            <p className="muted">
              {draft.team.invites.map(inv => inv.email || 'Unnamed').slice(0, 3).join(', ')}
              {draft.team.invites.length > 3 && ` +${draft.team.invites.length - 3} more`}
            </p>
          )}
        </div>

        <div className="onboarding__review-card">
          <h4>Compliance</h4>
          <p>
            {draft.compliance.hipaaAcknowledged && draft.compliance.mfaReminderAcknowledged && draft.compliance.phiLoggingSafeguards
              ? 'All requirements met'
              : 'Incomplete'}
          </p>
          <p className="muted">
            HIPAA: {draft.compliance.hipaaAcknowledged ? 'Complete' : 'Incomplete'}
            {' • '}
            MFA: {draft.compliance.mfaReminderAcknowledged ? 'Complete' : 'Incomplete'}
            {' • '}
            PHI: {draft.compliance.phiLoggingSafeguards ? 'Complete' : 'Incomplete'}
          </p>
        </div>

        <div className="onboarding__review-card">
          <h4>Billing Plan</h4>
          <p>{draft.billing.planId ?? 'Not selected'}</p>
          <p className="muted">{draft.billing.seats} seat{draft.billing.seats !== 1 ? 's' : ''}</p>
        </div>

        <div className="onboarding__review-card">
          <h4>Integrations</h4>
          <p>
            {draft.integrations.calendarSyncPlanned || draft.integrations.paymentsReady
              ? 'Configured'
              : 'None configured'}
          </p>
          <p className="muted">
            {draft.integrations.calendarSyncPlanned && 'Calendar sync enabled'}
            {draft.integrations.calendarSyncPlanned && draft.integrations.paymentsReady && ' • '}
            {draft.integrations.paymentsReady && 'Payments ready'}
          </p>
        </div>
      </div>
    </div>
  );
}
