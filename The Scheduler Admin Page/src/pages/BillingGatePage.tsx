import { useState } from 'react';
import { useNavigate, Navigate } from 'react-router-dom';

import { useAuth } from '../context/AuthContext';
import { useBillingProfile } from '../hooks/useBillingProfile';
import { useBusinessContext } from '../hooks/useBusinessContext';
import type { BillingProfile } from '../types/models';

const PLAN_OPTIONS = [
  {
    id: 'starter',
    name: 'Starter',
    description: 'For small teams getting started',
    price: '$29/mo',
    defaultSeats: 3,
    features: ['Basic scheduling', 'Client management', 'Email notifications'],
  },
  {
    id: 'pro',
    name: 'Pro',
    description: 'For growing businesses',
    price: '$99/mo',
    defaultSeats: 10,
    features: [
      'Everything in Starter',
      'Reporting & analytics',
      'Marketing campaigns',
      'CSV import/export',
      'Priority support',
    ],
    popular: true,
  },
  {
    id: 'scale',
    name: 'Scale',
    description: 'For established businesses',
    price: '$299/mo',
    defaultSeats: 30,
    features: [
      'Everything in Pro',
      'Advanced reporting',
      'Custom integrations',
      'Dedicated support',
      'SLA guarantee',
    ],
  },
];

const ADD_ON_OPTIONS = [
  {
    id: 'addon-reports',
    name: 'Advanced Reports',
    description: 'Detailed analytics and custom reporting',
    price: '$19/mo',
  },
  {
    id: 'addon-import-export',
    name: 'Import/Export',
    description: 'CSV bulk operations',
    price: '$9/mo',
  },
  {
    id: 'addon-marketing',
    name: 'Marketing',
    description: 'Email/SMS campaigns',
    price: '$29/mo',
  },
];

export function BillingGatePage() {
  const navigate = useNavigate();
  const { signOut } = useAuth();
  const { businessId, userId, role } = useBusinessContext();
  const {
    profile,
    loading: billingLoading,
    error: billingError,
    launchCheckout,
  } = useBillingProfile(businessId, userId);
  const [selectedPlan, setSelectedPlan] = useState<string>('pro');
  const [seats, setSeats] = useState<number>(3);
  const [selectedAddons, setSelectedAddons] = useState<string[]>([]);
  const [checkoutLoading, setCheckoutLoading] = useState(false);
  const isOwner = role === 'owner';
  const handleBackToDashboard = () => navigate('/dashboard');
  const handleBackToLogin = () => navigate('/login', { replace: true });

  const handleSignOut = async () => {
    try {
      await signOut();
      navigate('/login');
    } catch (error) {
      console.error('Sign out failed:', error);
    }
  };

  const handleToggleAddon = (addonId: string) => {
    setSelectedAddons((prev) =>
      prev.includes(addonId) ? prev.filter((id) => id !== addonId) : [...prev, addonId],
    );
  };

  const handleStartCheckout = async () => {
    if (!businessId) return;
    setCheckoutLoading(true);
    try {
      const url = await launchCheckout({
        planId: selectedPlan,
        seats,
        addons: selectedAddons,
      });
      if (url && typeof window !== 'undefined') {
        window.location.href = url;
      } else {
        alert('Checkout URL unavailable. Please contact support.');
      }
    } catch (err) {
      console.error('Failed to launch checkout', err);
      alert('Unable to start checkout. Please try again.');
    } finally {
      setCheckoutLoading(false);
    }
  };

  const selectedPlanInfo = PLAN_OPTIONS.find((p) => p.id === selectedPlan);

  if (!isOwner) {
    return (
      <section className="panel" style={{ margin: 24, maxWidth: 600 }}>
        <p className="eyebrow">Billing Required</p>
        <h1>Owner must complete billing setup</h1>
        <p className="muted">
          Your business owner needs to complete billing setup before you can access the platform. Please contact the
          owner to complete this step.
        </p>
        <div style={{ display: 'flex', gap: 12, marginTop: 16 }}>
          <button className="button button--ghost" type="button" onClick={handleBackToDashboard}>
            Back to dashboard
          </button>
          <button className="button button--ghost" type="button" onClick={handleBackToLogin}>
            Back to login
          </button>
        </div>
      </section>
    );
  }

  if (billingLoading) {
    return (
      <section className="panel" style={{ margin: 24 }}>
        <p>Loading billing information...</p>
      </section>
    );
  }

  if (billingError) {
    return (
      <section className="panel" style={{ margin: 24, borderColor: 'var(--danger-color, #b42318)' }}>
        <p className="eyebrow">Error</p>
        <p className="muted">{billingError}</p>
        <p className="muted" style={{ marginTop: 8 }}>
          If you reached this page from an email or link, verify the URL matches your app domain and that billing is enabled
          for this business.
        </p>
        <div style={{ display: 'flex', gap: 12, marginTop: 16 }}>
          <button className="button button--ghost" type="button" onClick={handleBackToDashboard}>
            Back to dashboard
          </button>
          <button className="button button--ghost" type="button" onClick={handleBackToLogin}>
            Back to login
          </button>
        </div>
      </section>
    );
  }

  // If billing is already complete (active/trialing/past_due), show status message
  if (profile && isSubscriptionActive(profile)) {
    return <Navigate to="/onboarding" replace state={{ billingStatus: profile.status }} />;
  }

  return (
    <section
      style={{
        minHeight: '100vh',
        background: 'linear-gradient(180deg, #F7F8FA 0%, #FFFFFF 100%)',
        padding: 24,
      }}
      aria-label="Billing setup"
    >
      <div style={{ maxWidth: 1200, margin: '0 auto' }}>
        {/* Sign out option */}
        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 8, marginBottom: 16 }}>
          <button
            className="button button--ghost"
            type="button"
            onClick={handleBackToDashboard}
            style={{ fontSize: '0.875rem' }}
          >
            Back to dashboard
          </button>
          <button
            className="button button--ghost"
            type="button"
            onClick={handleSignOut}
            style={{ fontSize: '0.875rem' }}
            aria-label="Sign out"
          >
            Sign out
          </button>
        </div>

        <header style={{ textAlign: 'center', marginBottom: 48 }}>
          <p className="eyebrow">OpenCRM</p>
          <h1 style={{ marginBottom: 12 }}>Choose your plan</h1>
          <p className="muted">Select a plan and complete billing to continue setting up your account.</p>
        </header>

        {/* Plan Selection */}
        <div style={{ marginBottom: 48 }}>
          <h2 style={{ marginBottom: 24 }}>Plans</h2>
          <div className="grid grid--3" style={{ gap: 24 }}>
            {PLAN_OPTIONS.map((plan) => (
              <PlanCard
                key={plan.id}
                plan={plan}
                selected={selectedPlan === plan.id}
                onSelect={() => setSelectedPlan(plan.id)}
              />
            ))}
          </div>
        </div>

        {/* Seats Selection */}
        <div style={{ marginBottom: 48 }}>
          <h2 style={{ marginBottom: 12 }}>Seats</h2>
          <p className="muted" style={{ marginBottom: 16 }}>
            How many team members will use the platform?
          </p>
          <div style={{ maxWidth: 300 }}>
            <label htmlFor="seats-input" style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              <span>Number of seats</span>
              <input
                id="seats-input"
                type="number"
                min={1}
                max={100}
                value={seats}
                onChange={(e) => setSeats(Math.max(1, parseInt(e.target.value) || 1))}
                style={{
                  padding: 12,
                  fontSize: 16,
                  borderRadius: 8,
                  border: '1px solid #E5E7EB',
                  transition: 'border-color 0.2s, box-shadow 0.2s',
                }}
                aria-label="Number of seats"
              />
            </label>
            <p className="muted" style={{ marginTop: 8, fontSize: '0.875rem' }}>
              Default for {selectedPlanInfo?.name}: {selectedPlanInfo?.defaultSeats} seats
            </p>
          </div>
        </div>

        {/* Add-ons */}
        <div style={{ marginBottom: 48 }}>
          <h2 style={{ marginBottom: 12 }}>Add-ons (Optional)</h2>
          <p className="muted" style={{ marginBottom: 16 }}>
            Enhance your plan with additional features
          </p>
          <div className="grid grid--3" style={{ gap: 16 }}>
            {ADD_ON_OPTIONS.map((addon) => (
              <AddonCard
                key={addon.id}
                addon={addon}
                selected={selectedAddons.includes(addon.id)}
                onToggle={() => handleToggleAddon(addon.id)}
              />
            ))}
          </div>
        </div>

        {/* Summary & Checkout */}
        <div
          style={{
            position: 'sticky',
            bottom: 0,
            background: 'linear-gradient(180deg, #FFFFFF 0%, #F9FAFB 100%)',
            border: '1px solid #E5E7EB',
            borderRadius: 16,
            padding: 24,
            boxShadow: '0 6px 20px rgba(0, 0, 0, 0.04)',
          }}
        >
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
            <div>
              <h3 style={{ margin: 0 }}>Summary</h3>
              <p className="muted" style={{ margin: 0 }}>
                {selectedPlanInfo?.name} plan • {seats} seat{seats !== 1 ? 's' : ''}
                {selectedAddons.length > 0 && ` • ${selectedAddons.length} add-on${selectedAddons.length !== 1 ? 's' : ''}`}
              </p>
            </div>
            <div style={{ textAlign: 'right' }}>
              <p className="eyebrow" style={{ margin: 0 }}>
                Starting at
              </p>
              <h2 style={{ margin: 0 }}>{selectedPlanInfo?.price}</h2>
            </div>
          </div>
          <button
            className="button button--primary"
            type="button"
            onClick={handleStartCheckout}
            disabled={!businessId || checkoutLoading}
            style={{ width: '100%', padding: 16, fontSize: 16 }}
            aria-label="Proceed to checkout"
          >
            {checkoutLoading ? 'Starting checkout...' : 'Start checkout'}
          </button>
          <p className="muted" style={{ textAlign: 'center', marginTop: 12, fontSize: '0.875rem' }}>
            You'll be redirected to Stripe to complete payment
          </p>
        </div>
      </div>
    </section>
  );
}

type PlanCardProps = {
  plan: (typeof PLAN_OPTIONS)[0];
  selected: boolean;
  onSelect: () => void;
};

function PlanCard({ plan, selected, onSelect }: PlanCardProps) {
  const [isHovered, setIsHovered] = useState(false);

  return (
    <div
      onClick={onSelect}
      onKeyDown={(e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          onSelect();
        }
      }}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      tabIndex={0}
      role="button"
      aria-pressed={selected}
      style={{
        cursor: 'pointer',
        border: `${selected ? 2 : 1}px solid ${selected ? '#0ea5e9' : '#E5E7EB'}`,
        borderRadius: 12,
        padding: 24,
        position: 'relative',
        background: 'linear-gradient(180deg, #FFFFFF 0%, #F9FAFB 100%)',
        boxShadow: isHovered ? '0 10px 28px rgba(0, 0, 0, 0.08)' : '0 6px 20px rgba(0, 0, 0, 0.04)',
        transform: isHovered ? 'translateY(-4px)' : 'translateY(0)',
        transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
      }}
    >
      {plan.popular && (
        <div
          style={{
            position: 'absolute',
            top: -12,
            left: '50%',
            transform: 'translateX(-50%)',
            background: '#0ea5e9',
            color: '#fff',
            padding: '4px 12px',
            borderRadius: 12,
            fontSize: '0.75rem',
            fontWeight: 600,
          }}
        >
          Popular
        </div>
      )}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 12 }}>
        <input type="radio" checked={selected} onChange={onSelect} aria-label={`Select ${plan.name} plan`} />
        <div>
          <h3 style={{ margin: 0 }}>{plan.name}</h3>
          <p className="muted" style={{ margin: 0, fontSize: '0.875rem' }}>
            {plan.description}
          </p>
        </div>
      </div>
      <div style={{ marginBottom: 16 }}>
        <p style={{ fontSize: '2rem', fontWeight: 700, margin: 0 }}>{plan.price}</p>
        <p className="muted" style={{ margin: 0, fontSize: '0.875rem' }}>
          {plan.defaultSeats} seats included
        </p>
      </div>
      <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
        {plan.features.map((feature, idx) => (
          <li key={idx} style={{ marginBottom: 8, display: 'flex', alignItems: 'center', gap: 8 }}>
            <span style={{ color: '#0ea5e9', fontWeight: 'bold' }} aria-hidden="true">+</span>
            <span style={{ fontSize: '0.875rem' }}>{feature}</span>
          </li>
        ))}
      </ul>
    </div>
  );
}

type AddonCardProps = {
  addon: (typeof ADD_ON_OPTIONS)[0];
  selected: boolean;
  onToggle: () => void;
};

function AddonCard({ addon, selected, onToggle }: AddonCardProps) {
  const [isHovered, setIsHovered] = useState(false);

  return (
    <div
      onClick={onToggle}
      onKeyDown={(e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          onToggle();
        }
      }}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      tabIndex={0}
      role="button"
      aria-pressed={selected}
      style={{
        cursor: 'pointer',
        border: `${selected ? 2 : 1}px solid ${selected ? '#0ea5e9' : '#E5E7EB'}`,
        borderRadius: 12,
        padding: 20,
        background: 'linear-gradient(180deg, #FFFFFF 0%, #F9FAFB 100%)',
        boxShadow: isHovered ? '0 10px 28px rgba(0, 0, 0, 0.08)' : '0 6px 20px rgba(0, 0, 0, 0.04)',
        transform: isHovered ? 'translateY(-4px)' : 'translateY(0)',
        transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
      }}
    >
      <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12, marginBottom: 12 }}>
        <input type="checkbox" checked={selected} onChange={onToggle} aria-label={`Add ${addon.name} addon`} />
        <div style={{ flex: 1 }}>
          <h4 style={{ margin: 0, marginBottom: 4 }}>{addon.name}</h4>
          <p className="muted" style={{ margin: 0, fontSize: '0.875rem' }}>
            {addon.description}
          </p>
        </div>
      </div>
      <p style={{ fontSize: '1.25rem', fontWeight: 600, margin: 0 }}>{addon.price}</p>
    </div>
  );
}

function isSubscriptionActive(profile: BillingProfile): boolean {
  return ['active', 'trialing', 'past_due'].includes(profile.status ?? '');
}
