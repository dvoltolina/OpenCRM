import { useCallback, useEffect, useRef, useState } from 'react';
import { Navigate, useNavigate, useSearchParams } from 'react-router-dom';
import { applyActionCode } from 'firebase/auth';

import { useAuth } from '../context/AuthContext';
import { getFirebaseAuth } from '../lib/firebase';

export function VerifyEmailPage() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const { state, sendVerification, refreshUser, signOut } = useAuth();
  const [status, setStatus] = useState<'idle' | 'sending' | 'checking'>('idle');
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const handledLink = useRef(false);
  const autoChecked = useRef(false);
  const autoSent = useRef(false);

  const mapVerificationError = (err: unknown) => {
    const code = err && typeof err === 'object' && 'code' in err ? (err as { code?: string }).code : undefined;
    if (code === 'auth/too-many-requests') {
      return 'Too many attempts. Please wait a few minutes before requesting another email.';
    }
    if (code === 'auth/invalid-continue-uri' || code === 'auth/unauthorized-continue-uri') {
      return `Email links must use an authorized domain. Add ${window.location.origin} to Firebase Auth > Authorized domains.`;
    }
    return err instanceof Error ? err.message : 'Unable to send verification email.';
  };

  // Handle verification links sent with handleCodeInApp
  useEffect(() => {
    const mode = searchParams.get('mode');
    const oobCode = searchParams.get('oobCode');
    if (handledLink.current || mode !== 'verifyEmail' || !oobCode) return;
    handledLink.current = true;

    const confirmEmail = async () => {
      try {
        setStatus('checking');
        setError(null);
        await applyActionCode(getFirebaseAuth(), oobCode);
        await refreshUser();
      } catch (err) {
        const message =
          err instanceof Error && err.message.toLowerCase().includes('expired')
            ? 'This verification link has expired. Please request a new one.'
            : 'Unable to verify this link. Please request a new verification email.';
        setError(message);
      } finally {
        setStatus('idle');
      }
    };

    void confirmEmail();
  }, [refreshUser, searchParams]);

  // If the user already verified in another tab/device, automatically check and advance
  useEffect(() => {
    if (handledLink.current || autoChecked.current) return;
    autoChecked.current = true;

    const checkVerification = async () => {
      try {
        setStatus('checking');
        setError(null);
        await refreshUser();
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unable to refresh account status.');
      } finally {
        setStatus('idle');
      }
    };

    void checkVerification();
  }, [refreshUser]);

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

  // After email verification, redirect to owner onboarding
  if (state.status === 'pending_profile') {
    return <Navigate to="/owner-onboarding" replace />;
  }

  // Already signed in - go to dashboard
  if (state.status === 'signed_in') {
    return <Navigate to="/dashboard" replace />;
  }

  // MFA required - go to MFA page
  if (state.status === 'mfa_required') {
    return <Navigate to="/mfa" replace />;
  }

  // Safety check - only render form for pending_verification status
  if (state.status !== 'pending_verification') {
    return <Navigate to="/login" replace />;
  }

  const userEmail =
    state.status === 'pending_verification' ? state.user.email ?? 'your email' : 'your email';

  const handleResend = useCallback(async () => {
    setStatus('sending');
    setError(null);
    setNotice(null);
    try {
      await sendVerification();
      setNotice(`Verification email sent to ${userEmail}.`);
    } catch (err) {
      console.error('Failed to send verification email', err);
      setError(mapVerificationError(err));
    } finally {
      setStatus('idle');
    }
  }, [sendVerification, userEmail]);

  const handleCheck = async () => {
    setStatus('checking');
    setError(null);
    setNotice(null);
    try {
      await refreshUser();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unable to refresh account status.');
    } finally {
      setStatus('idle');
    }
  };

  const handleBackToLogin = async () => {
    setStatus('checking');
    setError(null);
    try {
      await signOut();
      navigate('/login', { replace: true });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unable to return to login.');
    } finally {
      setStatus('idle');
    }
  };

  // Ensure a verification email is sent when landing on the page (when not already handling a link)
  useEffect(() => {
    if (state.status !== 'pending_verification') return;
    if (handledLink.current) return;
    if (searchParams.get('mode') === 'verifyEmail') return;
    if (autoSent.current) return;
    autoSent.current = true;

    void handleResend();
  }, [handleResend, searchParams, state.status]);

  const isProcessing = status !== 'idle';

  return (
    <div className="auth-shell">
      <div className="auth-card" role="main" aria-labelledby="verify-title" style={{ maxWidth: 420, padding: '40px 48px' }}>
        {/* OpenCRM badge */}
        <div style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          gap: 6,
          marginBottom: 32,
          padding: '8px 16px',
          background: 'linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%)',
          borderRadius: 20,
          width: 'fit-content',
          margin: '0 auto 32px auto'
        }}>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M12 2L2 7l10 5 10-5-10-5z"/>
            <path d="M2 17l10 5 10-5"/>
            <path d="M2 12l10 5 10-5"/>
          </svg>
          <span style={{ fontSize: 12, fontWeight: 600, color: 'white', letterSpacing: '0.5px' }}>
            OpenCRM
          </span>
        </div>

        {/* Email icon */}
        <div style={{
          display: 'flex',
          justifyContent: 'center',
          marginBottom: 24
        }}>
          <div style={{
            width: 64,
            height: 64,
            borderRadius: '50%',
            background: 'linear-gradient(135deg, #e0e7ff 0%, #c7d2fe 100%)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center'
          }}>
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#4f46e5" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <rect x="2" y="4" width="20" height="16" rx="2"/>
              <path d="M22 6l-10 7L2 6"/>
            </svg>
          </div>
        </div>

        <h1 id="verify-title" style={{
          fontSize: 28,
          fontWeight: 700,
          textAlign: 'center',
          marginBottom: 16,
          color: '#1e293b'
        }}>
          Check your inbox
        </h1>

        <p style={{
          textAlign: 'center',
          color: '#64748b',
          fontSize: 15,
          lineHeight: 1.6,
          marginBottom: 8
        }}>
          We've sent a verification link to
        </p>
        <p style={{
          textAlign: 'center',
          color: '#1e293b',
          fontSize: 15,
          fontWeight: 600,
          marginBottom: 24
        }}>
          {state.user.email}
        </p>

        <p style={{
          textAlign: 'center',
          color: '#94a3b8',
          fontSize: 13,
          lineHeight: 1.5,
          marginBottom: 32,
          padding: '0 16px'
        }}>
          Click the link in your email to verify your account and continue with onboarding.
        </p>

        {error && (
          <div style={{
            background: '#fef2f2',
            border: '1px solid #fecaca',
            borderRadius: 8,
            padding: '12px 16px',
            marginBottom: 24
          }}>
            <p style={{ color: '#dc2626', fontSize: 14, margin: 0, textAlign: 'center' }} role="alert">
              {error}
            </p>
          </div>
        )}

        {notice && (
          <div style={{
            background: '#f0fdf4',
            border: '1px solid #bbf7d0',
            borderRadius: 8,
            padding: '12px 16px',
            marginBottom: 24
          }}>
            <p style={{ color: '#16a34a', fontSize: 14, margin: 0, textAlign: 'center' }} role="status" aria-live="polite">
              {notice}
            </p>
          </div>
        )}

        <button
          type="button"
          onClick={handleCheck}
          disabled={isProcessing}
          aria-busy={status === 'checking'}
          aria-label="Check if email has been verified"
          style={{
            width: '100%',
            padding: '14px 24px',
            fontSize: 15,
            fontWeight: 600,
            color: 'white',
            background: 'linear-gradient(135deg, #4f46e5 0%, #6366f1 100%)',
            border: 'none',
            borderRadius: 10,
            cursor: isProcessing ? 'not-allowed' : 'pointer',
            opacity: isProcessing ? 0.7 : 1,
            transition: 'all 0.2s ease',
            marginBottom: 12
          }}
        >
          {status === 'checking' ? 'Checking...' : "I've verified my email"}
        </button>

        <button
          type="button"
          onClick={handleResend}
          disabled={isProcessing}
          aria-busy={status === 'sending'}
          aria-label="Resend verification email"
          style={{
            width: '100%',
            padding: '14px 24px',
            fontSize: 15,
            fontWeight: 500,
            color: '#4f46e5',
            background: 'white',
            border: '1px solid #e2e8f0',
            borderRadius: 10,
            cursor: isProcessing ? 'not-allowed' : 'pointer',
            opacity: isProcessing ? 0.7 : 1,
            transition: 'all 0.2s ease',
            marginBottom: 24
          }}
        >
          {status === 'sending' ? 'Sending...' : 'Resend verification email'}
        </button>

        <div style={{
          textAlign: 'center',
          paddingTop: 16,
          borderTop: '1px solid #f1f5f9'
        }}>
          <button
            type="button"
            onClick={handleBackToLogin}
            disabled={isProcessing}
            aria-label="Navigate back to login page"
            style={{
              background: 'none',
              border: 'none',
              color: '#64748b',
              fontSize: 14,
              cursor: 'pointer',
              textDecoration: 'underline',
              textUnderlineOffset: 3
            }}
          >
            Back to login
          </button>
        </div>
      </div>
    </div>
  );
}
