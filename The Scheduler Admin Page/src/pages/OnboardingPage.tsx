import { useCallback, useEffect, useMemo, useState } from 'react';
import { Navigate, useNavigate } from 'react-router-dom';

import { getOnboardingSteps, requiresHipaaCompliance } from '../data/onboarding';
import { useBillingProfile } from '../hooks/useBillingProfile';
import { useBusinessContext } from '../hooks/useBusinessContext';
import { useOnboarding } from '../hooks/useOnboarding';
import { createLocationsAndServices } from '../data/onboarding';
import {
  buildStepPayload,
  renderStepContent,
  validateStep,
} from './onboarding/OnboardingSteps';
import type { OnboardingState, OnboardingStepId, OnboardingTeamInvite } from '../types/models';
import { saveInvitePermissions } from '../data/staffPermissions';
import '../styles/onboarding.css';

const STEP_LABELS: Record<OnboardingStepId, string> = {
  business: 'Business Basics',
  scheduling: 'Self-Booking & Scheduling',
  locations: 'Locations',
  team: 'Team',
  compliance: 'Compliance & Security',
  billing: 'Plan & Billing',
  integrations: 'Data & Integrations',
  review: 'Review & Confirm',
};

export function OnboardingPage() {
  const { businessId, role, userId } = useBusinessContext();
  if (!businessId) return <Navigate to="/login" replace />;
  return (
    <OnboardingPageInner
      key={businessId}
      businessId={businessId}
      role={role}
      userId={userId}
    />
  );
}

type OnboardingPageInnerProps = {
  businessId: string;
  role?: string;
  userId?: string;
};

function OnboardingPageInner({ businessId, role, userId }: OnboardingPageInnerProps) {
  const navigate = useNavigate();
  const { state, loading, error, saveStep, complete } = useOnboarding(businessId, userId);
  const { profile: billingProfile, launchCheckout, openPortal } = useBillingProfile(businessId, userId);
  const [currentStep, setCurrentStep] = useState<OnboardingStepId>('business');
  const [draft, setDraft] = useState<OnboardingState | null>(null);
  const [inlineError, setInlineError] = useState<string | null>(null);
  const [savingStep, setSavingStep] = useState(false);
  const isOwner = role === 'owner';

  const crmEnabled = useMemo(() => {
    const entitlements = billingProfile?.entitlements || [];
    if (!entitlements.length) return false;
    return entitlements.some(
      (e) => e.enabled && (e.id === 'crm' || e.label.toLowerCase().includes('crm')),
    );
  }, [billingProfile]);
  const crmDisabledReason = crmEnabled ? undefined : 'CRM access requires a CRM-enabled plan/add-on';

  useEffect(() => {
    if (state) {
      setDraft(state);
      setCurrentStep(state.currentStep ?? 'business');
    }
  }, [state]);

  // Get steps based on industry (HIPAA compliance only for healthcare industries)
  const onboardingSteps = useMemo(
    () => getOnboardingSteps(draft?.businessBasics?.industry ?? ''),
    [draft?.businessBasics?.industry],
  );

  const isHipaaRequired = useMemo(
    () => requiresHipaaCompliance(draft?.businessBasics?.industry ?? ''),
    [draft?.businessBasics?.industry],
  );

  const stepIndex = useMemo(
    () => onboardingSteps.findIndex((step) => step === currentStep),
    [currentStep, onboardingSteps],
  );
  const nextStep =
    stepIndex >= 0 && stepIndex < onboardingSteps.length - 1
      ? onboardingSteps[stepIndex + 1]
      : null;
  const prevStep = stepIndex > 0 ? onboardingSteps[stepIndex - 1] : null;

  const handleSaveAndContinue = async () => {
    if (!draft) return;
    if (currentStep !== 'billing') {
      const validation = validateStep(currentStep, draft);
      if (validation) {
        setInlineError(validation);
        return;
      }
    }
    setInlineError(null);
    const payload =
      currentStep === 'billing'
        ? {
            billing: {
              ...draft.billing,
              planId: billingProfile?.planId ?? draft.billing.planId,
              seats: billingProfile?.seats ?? draft.billing.seats,
              addons: billingProfile?.addOnIds ?? billingProfile?.addonIds ?? draft.billing.addons,
              status: billingProfile?.status ?? draft.billing.status,
            },
          }
        : buildStepPayload(currentStep, draft, nextStep, onboardingSteps);
    await saveStep(payload, currentStep);
    if (!nextStep) {
      try {
        await createLocationsAndServices(businessId, draft, userId);
        await saveInvitePermissions(businessId, draft.team.invites, userId);
      } catch (err) {
        console.error('Failed to finalize onboarding resources', err);
        setInlineError('Unable to create resources or permissions. Please retry.');
        return;
      }
      await complete();
      navigate('/onboarding/success', { replace: true });
      return;
    }
    setCurrentStep(nextStep);
  };

  const persistStep = useCallback(
    async (targetStep: OnboardingStepId) => {
      if (!draft) return;
      setSavingStep(true);
      try {
        const payload = buildStepPayload(currentStep, draft, targetStep, onboardingSteps);
        await saveStep(payload, currentStep);
      } catch (err) {
        console.error('Failed to persist onboarding step', err);
      } finally {
        setSavingStep(false);
      }
    },
    [currentStep, draft, saveStep, onboardingSteps],
  );

  // Calculate progress percentage
  const progressPercentage = useMemo(() => {
    if (!draft) return 0;
    const completedCount = draft.completedSteps.length;
    const totalSteps = onboardingSteps.length;
    return Math.round((completedCount / totalSteps) * 100);
  }, [draft, onboardingSteps]);

  if (!state && loading) {
    return (
      <div className="onboarding__loading">
        <p>Loading onboarding...</p>
      </div>
    );
  }

  const handleStepChange = async (targetStep: OnboardingStepId) => {
    setInlineError(null);
    if (currentStep !== targetStep) {
      await persistStep(targetStep);
    }
    setCurrentStep(targetStep);
  };

  const handleAddService = () => {
    setDraft((prev) =>
      prev
        ? {
            ...prev,
            scheduling: {
              ...prev.scheduling,
              services: [
                ...prev.scheduling.services,
                { name: `Service ${prev.scheduling.services.length + 1}` },
              ],
            },
          }
        : prev,
    );
  };

  const handleAddLocation = () => {
    setDraft((prev) =>
      prev
        ? {
            ...prev,
            locations: [
              ...prev.locations,
              {
                name: `Location ${prev.locations.length + 1}`,
                address: '',
                timezone: prev.businessBasics.timezone,
              },
            ],
          }
        : prev,
    );
  };

  const handleAddInvite = () => {
    setDraft((prev) =>
      prev
        ? {
            ...prev,
            team: {
              ...prev.team,
              invites: [
                ...prev.team.invites,
                {
                  email: '',
                  role: 'staff',
                  isProvider: true,
                  crmAccess: false,
                  moduleAccess: {
                    scheduling: true,
                    clients: true,
                    marketing: false,
                    reporting: false,
                    billing: false,
                    settings: false,
                  },
                  locationIds: [],
                  serviceIds: [],
                },
              ] as OnboardingTeamInvite[],
            },
          }
        : prev,
    );
  };

  const isStepComplete = (step: OnboardingStepId) => draft?.completedSteps.includes(step);
  const disableInputs = !isOwner;

  return (
    <div className="onboarding" style={{ background: 'linear-gradient(180deg, #F7F8FA 0%, #FFFFFF 100%)' }}>
      <aside className="onboarding__sidebar">
        <div className="onboarding__brand">
          <div className="onboarding__brand-text">
            <h2>Getting Started</h2>
            <span>OpenCRM</span>
          </div>
        </div>

        <nav className="onboarding__steps">
          {onboardingSteps.map((step, index) => (
            <button
              key={step}
              type="button"
              className={`onboarding__step${currentStep === step ? ' onboarding__step--active' : ''}${isStepComplete(step) ? ' onboarding__step--completed' : ''}`}
              onClick={() => void handleStepChange(step)}
              disabled={!isOwner || savingStep}
            >
              <div className="onboarding__step-number">
                {isStepComplete(step) ? 'OK' : index + 1}
              </div>
              <span>{STEP_LABELS[step]}</span>
            </button>
          ))}
        </nav>

        <div className="onboarding__help" style={{
          boxShadow: '0 6px 20px rgba(0, 0, 0, 0.04)',
          background: 'rgba(255, 255, 255, 0.05)',
          border: '1px solid rgba(255, 255, 255, 0.08)'
        }}>
          <h4>Need help?</h4>
          <p>
            Our support team is available 24/7 to assist you with your scheduling setup.
          </p>
        </div>
      </aside>

      <main className="onboarding__main">
        <div className="onboarding__header">
          <div className="onboarding__header-top">
            <div className="onboarding__progress">
              <div className="onboarding__progress-bar">
                <div
                  className="onboarding__progress-fill"
                  style={{ width: `${progressPercentage}%` }}
                />
              </div>
              <span className="onboarding__progress-text">
                {progressPercentage}% Complete
              </span>
            </div>
            {billingProfile && (
              <div className="onboarding__plan-info" style={{
                background: 'linear-gradient(180deg, #FFFFFF 0%, #F9FAFB 100%)',
                border: '1px solid #E5E7EB',
                borderRadius: '12px',
                boxShadow: '0 6px 20px rgba(0, 0, 0, 0.04)'
              }}>
                <div className="onboarding__plan-item">
                  <span className="onboarding__plan-label">Current Plan</span>
                  <span className="onboarding__plan-value">
                    {billingProfile.planName ?? billingProfile.planId ?? 'Not selected'}
                    {billingProfile.status === 'trialing' && ' (Free Trial)'}
                  </span>
                </div>
                <div className="onboarding__plan-item">
                  <span className="onboarding__plan-label">Status</span>
                  <span className="onboarding__plan-status" style={{ color: '#0ea5e9' }}>{billingProfile.status}</span>
                </div>
              </div>
            )}
          </div>

          <h1>{STEP_LABELS[currentStep]}</h1>
          <p>
            Complete the required steps to unlock the admin dashboard. Billing and onboarding are owner-only actions.
          </p>
        </div>

        {error && (
          <div className="onboarding__alert onboarding__alert--error" style={{
            borderRadius: '12px',
            boxShadow: '0 6px 20px rgba(0, 0, 0, 0.04)',
            border: '1px solid #E5E7EB'
          }}>
            <div className="onboarding__alert-content">
              <h4>Error</h4>
              <p>{error}</p>
            </div>
          </div>
        )}

        {!isOwner && (
          <div className="onboarding__alert onboarding__alert--warning" style={{
            borderRadius: '12px',
            boxShadow: '0 6px 20px rgba(0, 0, 0, 0.04)',
            border: '1px solid #E5E7EB'
          }}>
            <div className="onboarding__alert-content">
              <h4>Owner action required</h4>
              <p>
                An owner must finish onboarding and billing before the dashboard is available. You can review the steps
                but cannot submit changes.
              </p>
            </div>
          </div>
        )}

        {inlineError && (
          <div className="onboarding__alert onboarding__alert--error" style={{
            borderRadius: '12px',
            boxShadow: '0 6px 20px rgba(0, 0, 0, 0.04)',
            border: '1px solid #E5E7EB'
          }}>
            <div className="onboarding__alert-content">
              <h4>Validation Error</h4>
              <p>{inlineError}</p>
            </div>
          </div>
        )}

        <div className="onboarding__content">
          {renderStepContent({
            currentStep,
            draft,
            setDraft,
            disableInputs,
            billingProfile,
            launchCheckout,
            openPortal,
            onAddService: handleAddService,
            onAddLocation: handleAddLocation,
            onAddInvite: handleAddInvite,
            crmEnabled,
            crmDisabledReason,
          })}
        </div>

        <div className="onboarding__footer">
          <div className="onboarding__footer-info">
            Step {stepIndex + 1} of {onboardingSteps.length}
          </div>
          <div className="onboarding__footer-actions">
            {prevStep && (
              <button
                className="onboarding__btn onboarding__btn--secondary"
                type="button"
                onClick={() => void handleStepChange(prevStep)}
                disabled={!isOwner || savingStep}
                style={{
                  borderRadius: '12px',
                  boxShadow: '0 6px 20px rgba(0, 0, 0, 0.04)',
                  border: '1px solid #E5E7EB'
                }}
              >
                ← Back
              </button>
            )}
            <button
              className="onboarding__btn onboarding__btn--primary"
              type="button"
              onClick={handleSaveAndContinue}
              disabled={loading || disableInputs || savingStep}
              style={{
                background: '#0ea5e9',
                borderRadius: '12px',
                boxShadow: '0 6px 20px rgba(0, 0, 0, 0.04)',
                border: '1px solid #0ea5e9'
              }}
              onMouseEnter={(e) => !loading && !disableInputs && !savingStep && (e.currentTarget.style.background = '#0284c7')}
              onMouseLeave={(e) => (e.currentTarget.style.background = '#0ea5e9')}
            >
              {currentStep === 'review' ? 'Finish onboarding' : 'Save & continue →'}
            </button>
          </div>
        </div>
      </main>
    </div>
  );
}
