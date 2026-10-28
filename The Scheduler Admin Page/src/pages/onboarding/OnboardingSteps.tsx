import type { OnboardingState, OnboardingStepId } from '../../types/models';
import { BusinessStep, LocationsStep, SchedulingStep } from './StepBasics';
import { BillingStep, ComplianceStep, IntegrationsStep, ReviewStep, TeamStep } from './StepTeamCompliance';
import type { StepProps } from './StepTypes';

export type { StepProps, UseBillingHandler } from './StepTypes';

export function renderStepContent(props: StepProps) {
  const { currentStep } = props;
  switch (currentStep) {
    case 'business':
      return <BusinessStep {...props} />;
    case 'scheduling':
      return <SchedulingStep {...props} />;
    case 'locations':
      return <LocationsStep {...props} />;
    case 'team':
      return <TeamStep {...props} />;
    case 'compliance':
      return <ComplianceStep {...props} />;
    case 'billing':
      return <BillingStep {...props} />;
    case 'integrations':
      return <IntegrationsStep {...props} />;
    case 'review':
    default:
      return <ReviewStep {...props} />;
  }
}

export function validateStep(step: OnboardingStepId, draft: OnboardingState): string | null {
  switch (step) {
    case 'business': {
      const basics = draft.businessBasics;
      if (!basics.businessName || !basics.industry || !basics.legalEntityType || !basics.timezone) {
        return 'Fill in business name, industry, entity type, and timezone.';
      }
      if (!basics.primaryLocation || !basics.contactEmail || !basics.tagline) {
        return 'Primary location, contact email, and tagline are required.';
      }
      const addr = basics.primaryLocationAddress;
      if (!addr?.street || !addr?.city || !addr?.state || !addr?.zip) {
        return 'Complete primary location address is required (street, city, state, zip).';
      }
      return null;
    }
    case 'scheduling':
      if (!draft.scheduling.services.length) return 'Add at least one service.';
      if (!draft.scheduling.operatingDays.length) return 'Select at least one operating day.';
      if (draft.scheduling.requireDeposit) {
        const amount = draft.scheduling.depositAmount ?? 0;
        if (!Number.isFinite(amount) || amount <= 0) {
          return 'Enter a deposit amount.';
        }
      }
      const openDays = draft.scheduling.hours?.filter((h) => h.isOpen) ?? [];
      if (openDays.length === 0) return 'Set at least one open day with hours.';
      const hasValidBlocks = openDays.every((day) =>
        day.blocks.every((b) => b.start && b.end && b.start < b.end),
      );
      if (!hasValidBlocks) return 'Add valid start/end times for open days.';
      return null;
    case 'locations':
      if (!draft.locations.length) return 'Add at least one location.';
      return null;
    case 'team':
      if (!draft.team.skipped && draft.team.invites.length === 0) {
        return 'Invite at least one team member or explicitly skip.';
      }
      return null;
    case 'compliance':
      if (
        !draft.compliance.hipaaAcknowledged ||
        !draft.compliance.mfaReminderAcknowledged ||
        !draft.compliance.phiLoggingSafeguards
      ) {
        return 'Compliance acknowledgments are required.';
      }
      return null;
    case 'billing':
      // Billing is completed before onboarding starts; this step is read-only.
      return null;
    case 'review':
    default:
      return null;
  }
}

export function buildStepPayload(
  currentStep: OnboardingStepId,
  draft: OnboardingState,
  nextStep: OnboardingStepId | null,
  orderedSteps: OnboardingStepId[],
): Partial<OnboardingState> {
  const currentStepIndex = orderedSteps.indexOf(currentStep);
  const targetStep = nextStep ?? currentStep;
  const base = { currentStep: targetStep };
  switch (currentStep) {
    case 'business':
      return { ...base, businessBasics: draft.businessBasics };
    case 'scheduling':
      return { ...base, scheduling: draft.scheduling };
    case 'locations':
      return { ...base, locations: draft.locations };
    case 'team':
      return { ...base, team: draft.team };
    case 'compliance':
      return { ...base, compliance: draft.compliance };
    case 'billing':
      return { ...base, billing: draft.billing };
    case 'integrations':
      return { ...base, integrations: draft.integrations };
    case 'review':
    default:
      return {
        ...base,
        reviewConfirmed: true,
        completedSteps: orderedSteps.slice(0, currentStepIndex + 1),
      };
  }
}
