import { useMemo, useState } from 'react';
import { Navigate, useNavigate } from 'react-router-dom';

import { useAuth } from '../context/AuthContext';
import {
  PASSWORD_RULES,
  getPasswordStrength,
  getStrengthLabel,
  validatePassword,
} from '../lib/passwordPolicy';

export function SignupPage() {
  const navigate = useNavigate();
  const { state, createAccount } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [displayName, setDisplayName] = useState('');
  const [agreeTerms, setAgreeTerms] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  // All hooks must be called before any early returns
  const passwordErrors = useMemo(() => validatePassword(password), [password]);
  const passwordStrength = useMemo(() => getPasswordStrength(password), [password]);
  const strengthLabel = useMemo(() => getStrengthLabel(passwordStrength), [passwordStrength]);

  // Redirect based on auth state
  if (state.status === 'signed_in') {
    return <Navigate to="/dashboard" replace />;
  }

  if (state.status === 'pending_verification') {
    return <Navigate to="/verify-email" replace />;
  }

  if (state.status === 'pending_profile') {
    return <Navigate to="/owner-onboarding" replace />;
  }

  if (state.status === 'mfa_required') {
    return <Navigate to="/mfa" replace />;
  }

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    setError(null);

    if (passwordErrors.length > 0) {
      setError('Password does not meet the security requirements.');
      return;
    }

    if (password !== confirmPassword) {
      setError('Passwords do not match.');
      return;
    }

    if (!agreeTerms) {
      setError('You must agree to the Terms and Privacy Policy.');
      return;
    }

    setLoading(true);
    try {
      await createAccount(email.trim(), password, displayName.trim());
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unable to create account. Try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-shell">
      <form
        className="auth-card"
        onSubmit={handleSubmit}
        aria-labelledby="signup-title"
        style={{
          background: 'linear-gradient(180deg, #FFFFFF 0%, #F9FAFB 100%)',
          boxShadow: '0 20px 60px rgba(15, 23, 42, 0.08)',
          border: '1px solid #E5E7EB',
          borderRadius: '16px',
        }}
      >
        <h1 id="signup-title">Create your owner/admin account</h1>
        <p className="muted">This account will own the business workspace and billing.</p>

        <label className="auth-label" htmlFor="displayName-input">
          Full name
          <input
            id="displayName-input"
            type="text"
            value={displayName}
            onChange={(e) => setDisplayName(e.target.value)}
            placeholder="Your name"
            required
            autoComplete="name"
            aria-required="true"
            disabled={loading}
            style={{
              transition: 'border-color 0.15s, box-shadow 0.15s',
            }}
            onFocus={(e) => {
              e.target.style.borderColor = '#0ea5e9';
              e.target.style.boxShadow = '0 0 0 3px rgba(14, 165, 233, 0.1)';
            }}
            onBlur={(e) => {
              e.target.style.borderColor = '#d1d5db';
              e.target.style.boxShadow = 'none';
            }}
          />
        </label>
        <label className="auth-label" htmlFor="email-input">
          Email
          <input
            id="email-input"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="you@example.com"
            required
            autoComplete="email"
            aria-required="true"
            disabled={loading}
            style={{
              transition: 'border-color 0.15s, box-shadow 0.15s',
            }}
            onFocus={(e) => {
              e.target.style.borderColor = '#0ea5e9';
              e.target.style.boxShadow = '0 0 0 3px rgba(14, 165, 233, 0.1)';
            }}
            onBlur={(e) => {
              e.target.style.borderColor = '#d1d5db';
              e.target.style.boxShadow = 'none';
            }}
          />
        </label>
        <label className="auth-label" htmlFor="password-input">
          Password
          <input
            id="password-input"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="Min 12 characters with upper/lower/number/symbol"
            required
            autoComplete="new-password"
            aria-required="true"
            aria-describedby="password-strength password-requirements"
            disabled={loading}
            style={{
              transition: 'border-color 0.15s, box-shadow 0.15s',
            }}
            onFocus={(e) => {
              e.target.style.borderColor = '#0ea5e9';
              e.target.style.boxShadow = '0 0 0 3px rgba(14, 165, 233, 0.1)';
            }}
            onBlur={(e) => {
              e.target.style.borderColor = '#d1d5db';
              e.target.style.boxShadow = 'none';
            }}
          />
        </label>
        <div className="muted" style={{ marginBottom: 8 }} id="password-strength">
          <div
            aria-label={`Password strength: ${strengthLabel}`}
            aria-valuemax={100}
            aria-valuemin={0}
            aria-valuenow={Math.round(passwordStrength * 100)}
            role="progressbar"
            style={{
              background: '#e5e7eb',
              borderRadius: 6,
              height: 8,
              overflow: 'hidden',
              marginBottom: 6,
            }}
          >
            <div
              style={{
                width: `${Math.round(passwordStrength * 100)}%`,
                background:
                  passwordStrength >= 0.85
                    ? '#15803d'
                    : passwordStrength >= 0.55
                      ? '#a16207'
                      : '#b91c1c',
                height: '100%',
                transition: 'width 120ms ease',
              }}
            />
          </div>
          <span style={{ fontWeight: 600 }}>{strengthLabel}</span>
          <span style={{ marginLeft: 8 }}>
            • Use a long unique passphrase for the best protection.
          </span>
        </div>
        <div className="panel" style={{ background: '#f8fafc' }} id="password-requirements">
          <p className="eyebrow" style={{ marginTop: 0 }}>
            Password requirements
          </p>
          <ul style={{ paddingLeft: 16, margin: 0, display: 'grid', gap: 4 }} role="list">
            {PASSWORD_RULES.map((rule) => {
              const satisfied = rule.test(password);
              return (
                <li
                  key={rule.id}
                  style={{
                    color: satisfied ? '#15803d' : '#6b7280',
                    listStyle: 'none',
                    display: 'flex',
                    alignItems: 'center',
                    gap: 6,
                  }}
                  role="listitem"
                  aria-label={`${rule.label}: ${satisfied ? 'satisfied' : 'not satisfied'}`}
                >
                  <span
                    aria-hidden="true"
                    style={{
                      width: 16,
                      height: 16,
                      borderRadius: '50%',
                      border: '1px solid',
                      borderColor: satisfied ? '#15803d' : '#d1d5db',
                      background: satisfied ? '#dcfce7' : 'transparent',
                      display: 'inline-flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontSize: 10,
                      color: satisfied ? '#15803d' : '#9ca3af',
                    }}
                  >
                    {satisfied ? 'OK' : ''}
                  </span>
                  <span>{rule.label}</span>
                </li>
              );
            })}
          </ul>
        </div>
        <label className="auth-label" htmlFor="confirmPassword-input">
          Confirm password
          <input
            id="confirmPassword-input"
            type="password"
            value={confirmPassword}
            onChange={(e) => setConfirmPassword(e.target.value)}
            placeholder="Re-enter password"
            required
            autoComplete="new-password"
            aria-required="true"
            disabled={loading}
            style={{
              transition: 'border-color 0.15s, box-shadow 0.15s',
            }}
            onFocus={(e) => {
              e.target.style.borderColor = '#0ea5e9';
              e.target.style.boxShadow = '0 0 0 3px rgba(14, 165, 233, 0.1)';
            }}
            onBlur={(e) => {
              e.target.style.borderColor = '#d1d5db';
              e.target.style.boxShadow = 'none';
            }}
          />
        </label>

        <label className="auth-label" style={{ display: 'flex', gap: 8, alignItems: 'center', cursor: 'pointer' }} htmlFor="agreeTerms-checkbox">
          <input
            id="agreeTerms-checkbox"
            type="checkbox"
            checked={agreeTerms}
            onChange={(e) => setAgreeTerms(e.target.checked)}
            required
            aria-required="true"
            disabled={loading}
          />
          <span>
            I agree to the Terms of Service and Privacy Policy
          </span>
        </label>

        {error ? <p className="error" role="alert">{error}</p> : null}

        <button
          className="button button--primary"
          type="submit"
          disabled={loading}
          aria-busy={loading}
          style={{
            background: loading ? '#0ea5e9' : '#0ea5e9',
            opacity: loading ? 0.7 : 1,
          }}
          onMouseEnter={(e) => {
            if (!loading) {
              e.currentTarget.style.background = '#0284c7';
            }
          }}
          onMouseLeave={(e) => {
            if (!loading) {
              e.currentTarget.style.background = '#0ea5e9';
            }
          }}
        >
          {loading ? 'Creating account…' : 'Create account'}
        </button>

        <div style={{ marginTop: 16, textAlign: 'center' }}>
          <button
            type="button"
            className="button button--ghost"
            onClick={() => navigate('/login')}
            disabled={loading}
            aria-label="Navigate to login page"
          >
            Already have an account? Sign in
          </button>
        </div>
      </form>
    </div>
  );
}
