/**
 * TenantBillingPanel
 * Manage tenant plan, seats, and add-ons.
 */

import { useState } from 'react';
import type { BillingProfile } from '../../../types/models';
import { AVAILABLE_PLANS, AVAILABLE_ADDONS } from '../../../types/ops';
import { ConfirmDialog } from '../../../components/ConfirmDialog';

type Props = {
  billing: BillingProfile | null;
  updating: boolean;
  onSetPlan: (planId: string, planName: string, seats: number) => Promise<void>;
  onToggleAddon: (addonId: string, enabled: boolean) => Promise<void>;
};

export function TenantBillingPanel({ billing, updating, onSetPlan, onToggleAddon }: Props) {
  const [selectedPlan, setSelectedPlan] = useState(billing?.planId || '');
  const [seats, setSeats] = useState(billing?.seats || 1);
  const [confirmPlan, setConfirmPlan] = useState(false);
  const [confirmAddon, setConfirmAddon] = useState<{ id: string; enabled: boolean } | null>(null);

  const currentAddons = billing?.addonIds ?? [];

  const handlePlanSave = async () => {
    const plan = AVAILABLE_PLANS.find((p) => p.id === selectedPlan);
    if (plan) {
      await onSetPlan(selectedPlan, plan.name, seats);
    }
    setConfirmPlan(false);
  };

  const handleAddonToggle = async () => {
    if (confirmAddon) {
      await onToggleAddon(confirmAddon.id, confirmAddon.enabled);
      setConfirmAddon(null);
    }
  };

  return (
    <div className="stack">
      {/* Plan Selection */}
      <div className="panel">
        <h3>Plan & Seats</h3>
        <div className="form-group">
          <label htmlFor="plan">Plan</label>
          <select
            id="plan"
            value={selectedPlan}
            onChange={(e) => setSelectedPlan(e.target.value)}
            disabled={updating}
          >
            <option value="">Select a plan...</option>
            {AVAILABLE_PLANS.map((plan) => (
              <option key={plan.id} value={plan.id}>
                {plan.name} ({plan.baseSeats} seats)
              </option>
            ))}
          </select>
        </div>

        <div className="form-group">
          <label htmlFor="seats">Seats</label>
          <input
            type="number"
            id="seats"
            min={1}
            value={seats}
            onChange={(e) => setSeats(parseInt(e.target.value, 10) || 1)}
            disabled={updating}
          />
        </div>

        <button
          className="button button--primary"
          onClick={() => setConfirmPlan(true)}
          disabled={updating || !selectedPlan}
        >
          {updating ? 'Saving...' : 'Update Plan'}
        </button>
      </div>

      {/* Add-ons */}
      <div className="panel">
        <h3>Add-ons</h3>
        <div className="stack" style={{ gap: 12 }}>
          {AVAILABLE_ADDONS.map((addon) => {
            const isEnabled = currentAddons.includes(addon.id);
            return (
              <div
                key={addon.id}
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  padding: '12px 0',
                  borderBottom: '1px solid var(--color-border)',
                }}
              >
                <div>
                  <strong>{addon.name}</strong>
                  <br />
                  <span className="muted" style={{ fontSize: 12 }}>
                    {addon.description}
                  </span>
                </div>
                <button
                  className={`button ${isEnabled ? 'button--danger' : 'button--primary'}`}
                  onClick={() => setConfirmAddon({ id: addon.id, enabled: !isEnabled })}
                  disabled={updating}
                >
                  {isEnabled ? 'Remove' : 'Add'}
                </button>
              </div>
            );
          })}
        </div>
      </div>

      {/* Confirm Plan Dialog */}
      {confirmPlan && (
        <ConfirmDialog
          title="Update Plan"
          message={`Are you sure you want to change the plan to "${AVAILABLE_PLANS.find((p) => p.id === selectedPlan)?.name}" with ${seats} seats?`}
          onConfirm={handlePlanSave}
          onCancel={() => setConfirmPlan(false)}
          confirmLabel="Update Plan"
        />
      )}

      {/* Confirm Addon Dialog */}
      {confirmAddon && (
        <ConfirmDialog
          title={confirmAddon.enabled ? 'Add Add-on' : 'Remove Add-on'}
          message={`Are you sure you want to ${confirmAddon.enabled ? 'add' : 'remove'} the "${AVAILABLE_ADDONS.find((a) => a.id === confirmAddon.id)?.name}" add-on?`}
          onConfirm={handleAddonToggle}
          onCancel={() => setConfirmAddon(null)}
          confirmLabel={confirmAddon.enabled ? 'Add' : 'Remove'}
          danger={!confirmAddon.enabled}
        />
      )}
    </div>
  );
}
