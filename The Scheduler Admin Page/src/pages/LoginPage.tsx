import { useState } from 'react';
import { Navigate, useNavigate } from 'react-router-dom';

import { useAuth } from '../context/AuthContext';

const cardStyle: React.CSSProperties = {
  background: 'linear-gradient(180deg, #FFFFFF 0%, #F9FAFB 100%)',
  boxShadow: '0 20px 60px rgba(15, 23, 42, 0.08)',
  border: '1px solid #E5E7EB',
  borderRadius: '16px',
  padding: '40px',
  maxWidth: '440px',
  width: '100%',
};

const inputStyle: React.CSSProperties = {
  width: '100%',
  padding: '12px 16px',
  fontSize: '15px',
  lineHeight: '1.5',
  borderRadius: '8px',
  border: '1px solid #D1D5DB',
  backgroundColor: '#FFFFFF',
  transition: 'all 0.2s ease',
  outline: 'none',
};

const inputFocusStyle: React.CSSProperties = {
  borderColor: '#0ea5e9',
  boxShadow: '0 0 0 3px rgba(14, 165, 233, 0.1)',
};

const labelStyle: React.CSSProperties = {
  display: 'block',
  fontSize: '14px',
  fontWeight: 500,
  color: '#374151',
  marginBottom: '20px',
};

const primaryButtonStyle: React.CSSProperties = {
  width: '100%',
  padding: '12px 24px',
  fontSize: '15px',
  fontWeight: 600,
  color: '#FFFFFF',
  backgroundColor: '#0ea5e9',
  border: 'none',
  borderRadius: '8px',
  cursor: 'pointer',
  transition: 'all 0.2s ease',
  marginTop: '8px',
};

const primaryButtonHoverStyle: React.CSSProperties = {
  backgroundColor: '#0284c7',
};

const ghostButtonStyle: React.CSSProperties = {
  padding: '8px 16px',
  fontSize: '14px',
  fontWeight: 500,
  color: '#0ea5e9',
  backgroundColor: 'transparent',
  border: 'none',
  cursor: 'pointer',
  transition: 'all 0.2s ease',
};

const errorStyle: React.CSSProperties = {
  padding: '12px 16px',
  backgroundColor: '#FEF2F2',
  color: '#DC2626',
  borderRadius: '8px',
  fontSize: '14px',
  marginBottom: '16px',
  border: '1px solid #FEE2E2',
};

export function LoginPage() {
  const navigate = useNavigate();
  const { state, signIn } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [emailFocused, setEmailFocused] = useState(false);
  const [passwordFocused, setPasswordFocused] = useState(false);
  const [primaryButtonHovered, setPrimaryButtonHovered] = useState(false);

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

  if (state.status === 'error') {
    return (
      <div className="auth-shell">
        <div style={cardStyle}>
          <h1 style={{ fontSize: '24px', fontWeight: 700, color: '#111827', marginBottom: '12px' }}>
            Scheduler Admin
          </h1>
          <p style={errorStyle}>Authentication error: {state.error}</p>
        </div>
      </div>
    );
  }

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    setLoading(true);
    setError(null);

    try {
      await signIn(email.trim(), password);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unable to sign in');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-shell">
      <form style={cardStyle} onSubmit={handleSubmit} aria-labelledby="login-title">
        <h1
          id="login-title"
          style={{
            fontSize: '24px',
            fontWeight: 700,
            color: '#111827',
            marginBottom: '8px',
            textAlign: 'center',
          }}
        >
          Scheduler Admin
        </h1>
        <p
          style={{
            fontSize: '15px',
            color: '#6B7280',
            textAlign: 'center',
            marginBottom: '8px',
          }}
        >
          Sign in to continue to the Admin Portal.
        </p>
        <p
          style={{
            fontSize: '12px',
            color: '#9CA3AF',
            textAlign: 'center',
            marginBottom: '32px',
            lineHeight: '1.5',
          }}
        >
          HIPAA or 2FA-enabled businesses will prompt for a verification code after password entry.
        </p>

        <label style={labelStyle} htmlFor="email-input">
          Email
          <input
            id="email-input"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            onFocus={() => setEmailFocused(true)}
            onBlur={() => setEmailFocused(false)}
            style={{
              ...inputStyle,
              ...(emailFocused ? inputFocusStyle : {}),
              marginTop: '6px',
            }}
            required
            autoComplete="email"
            aria-required="true"
            disabled={loading}
          />
        </label>

        <label style={labelStyle} htmlFor="password-input">
          Password
          <input
            id="password-input"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            onFocus={() => setPasswordFocused(true)}
            onBlur={() => setPasswordFocused(false)}
            placeholder="Your password"
            style={{
              ...inputStyle,
              ...(passwordFocused ? inputFocusStyle : {}),
              marginTop: '6px',
            }}
            required
            autoComplete="current-password"
            aria-required="true"
            disabled={loading}
          />
        </label>

        {error ? (
          <p style={errorStyle} role="alert">
            {error}
          </p>
        ) : null}

        <button
          type="submit"
          disabled={loading}
          aria-busy={loading}
          onMouseEnter={() => setPrimaryButtonHovered(true)}
          onMouseLeave={() => setPrimaryButtonHovered(false)}
          style={{
            ...primaryButtonStyle,
            ...(primaryButtonHovered && !loading ? primaryButtonHoverStyle : {}),
            opacity: loading ? 0.7 : 1,
            cursor: loading ? 'not-allowed' : 'pointer',
          }}
        >
          {loading ? 'Signing in…' : 'Sign In'}
        </button>

        <div style={{ marginTop: '24px', textAlign: 'center' }}>
          <button
            type="button"
            onClick={() => navigate('/signup')}
            disabled={loading}
            aria-label="Navigate to sign up page"
            style={{
              ...ghostButtonStyle,
              opacity: loading ? 0.5 : 1,
              cursor: loading ? 'not-allowed' : 'pointer',
            }}
          >
            Create a new owner/admin account
          </button>
        </div>

        <p
          style={{
            marginTop: '32px',
            paddingTop: '24px',
            borderTop: '1px solid #E5E7EB',
            fontSize: '12px',
            color: '#9CA3AF',
            textAlign: 'center',
          }}
        >
          OpenCRM
        </p>
      </form>
    </div>
  );
}
