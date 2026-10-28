import { useEffect, useMemo, useState } from 'react';
import { Navigate, useNavigate } from 'react-router-dom';

import { useAuth } from '../context/AuthContext';
import {
  BOOKING_SLUG_REGEX,
  createWorkspace,
  generateSlugFromName,
  lookupBusinessBySlug,
} from '../data/workspace';

const INDUSTRY_OPTIONS = [
  { value: 'healthcare_medical', label: 'Healthcare / Medical', hipaa: true },
  { value: 'behavioral_health', label: 'Behavioral Health / Therapy', hipaa: true },
  { value: 'dental_optometry', label: 'Dental / Optometry', hipaa: true },
  { value: 'wellness', label: 'Wellness / Alternative Medicine' },
  { value: 'beauty_salon', label: 'Beauty / Salon / Spa' },
  { value: 'fitness', label: 'Fitness / Personal Training' },
  { value: 'real_estate', label: 'Real Estate' },
  { value: 'coaching', label: 'Coaching / Consulting' },
  { value: 'professional_services', label: 'Professional Services' },
  { value: 'education', label: 'Education / Tutoring' },
  { value: 'other', label: 'Other' },
];

export function OwnerOnboardingPage() {
  const navigate = useNavigate();
  const { state, refreshUser, reloadCurrentUser, signOut } = useAuth();
  const [businessName, setBusinessName] = useState('');
  const [industry, setIndustry] = useState(INDUSTRY_OPTIONS[0]?.value ?? 'healthcare_medical');
  const [slug, setSlug] = useState('');
  const [slugStatus, setSlugStatus] = useState<'idle' | 'checking' | 'available' | 'taken'>('idle');
  const [hipaaOverride, setHipaaOverride] = useState<boolean | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const isHipaaIndustry = useMemo(
    () => INDUSTRY_OPTIONS.find((opt) => opt.value === industry)?.hipaa ?? false,
    [industry],
  );

  const requiresHipaa = hipaaOverride ?? isHipaaIndustry;

  useEffect(() => {
    if (!slug && businessName) {
      setSlug(generateSlugFromName(businessName));
    }
  }, [businessName, slug]);

  useEffect(() => {
    if (state.status === 'signed_in') {
      navigate('/dashboard', { replace: true });
    } else if (state.status === 'pending_verification') {
      navigate('/verify-email', { replace: true });
    }
  }, [state.status, navigate]);

  if (state.status === 'loading') {
    return (
      <div className="auth-shell">
        <div className="auth-card">
          <p>Loading account…</p>
        </div>
      </div>
    );
  }

  if (state.status === 'signed_out') {
    return <Navigate to="/login" replace />;
  }

  if (state.status !== 'pending_profile' && state.status !== 'loading') {
    return <Navigate to="/dashboard" replace />;
  }

  const handleSlugCheck = async () => {
    if (!slug || !BOOKING_SLUG_REGEX.test(slug)) {
      setError('Slug must be lowercase letters, numbers, or hyphens.');
      return;
    }
    setError(null);
    setSlugStatus('checking');
    try {
      const result = await lookupBusinessBySlug(slug);
      setSlugStatus(result.found ? 'taken' : 'available');
    } catch (err) {
      // HIPAA: Log error without exposing user data
      console.error('Slug lookup failed');
      setError('Unable to check slug availability. Try again.');
      setSlugStatus('idle');
    }
  };

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    setError(null);

    const ownerEmail = state.status === 'pending_profile' ? state.user.email : null;
    const ownerName = state.status === 'pending_profile' ? state.user.displayName : null;

    if (!ownerEmail) {
      setError('A verified email is required. Please sign in again.');
      return;
    }

    if (!businessName.trim()) {
      setError('Business name is required.');
      return;
    }

    if (slug && !BOOKING_SLUG_REGEX.test(slug)) {
      setError('Slug must be lowercase letters, numbers, or hyphens (no leading/trailing hyphens).');
      return;
    }

    setLoading(true);
    try {
      await createWorkspace({
        businessName: businessName.trim(),
        ownerEmail,
        ownerDisplayName: ownerName ?? ownerEmail,
        industry,
        slug: slug || undefined,
        requiresHipaaCompliance: requiresHipaa,
        mfaEnabled: requiresHipaa,
      });

      await reloadCurrentUser();
      await refreshUser();
      navigate('/billing-gate', { replace: true });
    } catch (err) {
      // HIPAA: Log error without exposing user data
      console.error('Workspace creation failed');
      setError('Unable to create workspace. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleBackToLogin = async () => {
    try {
      await signOut();
    } catch (err) {
      // HIPAA: Log error without exposing user data
      console.warn('Sign out failed');
    } finally {
      navigate('/login', { replace: true });
    }
  };

  return (
    <div className="auth-shell">
      <form className="auth-card" onSubmit={handleSubmit} aria-labelledby="onboarding-title">
        <p className="eyebrow">Owner onboarding</p>
        <h1 id="onboarding-title">Create your business workspace</h1>
        <p className="muted">
          This will create your business, generate an invite code, and unlock billing and onboarding.
        </p>

        <label className="auth-label" htmlFor="businessName-input">
          Business name
          <input
            id="businessName-input"
            type="text"
            value={businessName}
            onChange={(e) => setBusinessName(e.target.value)}
            placeholder="My Practice"
            required
            aria-required="true"
            disabled={loading}
          />
        </label>

        <label className="auth-label" htmlFor="industry-select">
          Industry
          <select
            id="industry-select"
            value={industry}
            onChange={(e) => {
              setIndustry(e.target.value);
              setHipaaOverride(null);
            }}
            disabled={loading}
            aria-required="true"
          >
            {INDUSTRY_OPTIONS.map((opt) => (
              <option key={opt.value} value={opt.value}>
                {opt.label}
              </option>
            ))}
          </select>
        </label>

        <label className="auth-label" htmlFor="slug-input">
          Custom booking URL slug (optional)
          <div style={{ display: 'flex', gap: 8 }}>
            <input
              id="slug-input"
              type="text"
              value={slug}
              onChange={(e) => {
                setSlug(e.target.value.toLowerCase());
                setSlugStatus('idle');
              }}
              placeholder="my-practice"
              maxLength={50}
              style={{ flex: 1 }}
              disabled={loading}
              aria-describedby="slug-help"
            />
            <button
              className="button button--ghost"
              type="button"
              onClick={handleSlugCheck}
              disabled={slugStatus === 'checking' || loading}
              aria-busy={slugStatus === 'checking'}
              aria-label="Check slug availability"
            >
              {slugStatus === 'checking' ? 'Checking…' : 'Check'}
            </button>
          </div>
          <p className="muted" id="slug-help" style={{ marginTop: 4, fontSize: 12 }}>
            Lowercase letters, numbers, and hyphens only. Leave blank to auto-generate.
            {slugStatus === 'available' && <span style={{ color: 'green', marginLeft: 8 }} role="status">Available</span>}
            {slugStatus === 'taken' && <span style={{ color: '#b42318', marginLeft: 8 }} role="status">Taken</span>}
          </p>
        </label>

        {isHipaaIndustry && (
          <div className="panel" style={{ borderColor: 'var(--warning-color, #f79009)', background: '#fff9eb' }} role="alert">
            <p className="eyebrow">HIPAA industry</p>
            <p className="muted" style={{ margin: 0 }}>
              Your industry requires HIPAA compliance. MFA will be required for admins/owners and session persistence will be limited.
            </p>
          </div>
        )}

        <label className="auth-label" style={{ display: 'flex', gap: 8, alignItems: 'center', cursor: 'pointer' }} htmlFor="hipaa-checkbox">
          <input
            id="hipaa-checkbox"
            type="checkbox"
            checked={requiresHipaa}
            onChange={(e) => setHipaaOverride(e.target.checked)}
            disabled={loading}
          />
          <span>Enable HIPAA compliance and require MFA</span>
        </label>

        {error ? <p className="error" role="alert">{error}</p> : null}

        <button className="button button--primary" type="submit" disabled={loading} aria-busy={loading}>
          {loading ? 'Creating workspace…' : 'Create my business'}
        </button>

        <div style={{ marginTop: 12 }}>
          <button
            className="button button--ghost"
            type="button"
            onClick={handleBackToLogin}
            disabled={loading}
            aria-label="Navigate back to login page"
          >
            Back to login
          </button>
        </div>
      </form>
    </div>
  );
}
