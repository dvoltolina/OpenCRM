import type {
  BillingProfile,
  OnboardingState,
  OnboardingStepId,
} from '../../types/models';

export type UseBillingHandler = (input: { planId: string; seats: number; addons?: string[] }) => Promise<string>;

export type StepProps = {
  currentStep: OnboardingStepId;
  draft: OnboardingState | null;
  setDraft: (updater: (prev: OnboardingState | null) => OnboardingState | null) => void;
  disableInputs: boolean;
  billingProfile: BillingProfile | null;
  launchCheckout: UseBillingHandler;
  openPortal: () => Promise<string | null>;
  onAddService: () => void;
  onAddLocation: () => void;
  onAddInvite: () => void;
  /** Whether current plan/entitlements allow CRM access for invites */
  crmEnabled: boolean;
  /** Optional reason to show when CRM access is disabled */
  crmDisabledReason?: string;
};
