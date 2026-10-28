import { useEffect, useRef, useState } from 'react';
import type { FormEvent } from 'react';
import type { Location } from 'react-router-dom';
import { useLocation, useNavigate } from 'react-router-dom';
import { PhoneAuthProvider, PhoneMultiFactorGenerator, RecaptchaVerifier, multiFactor } from 'firebase/auth';
import { getFirebaseAuth } from '../lib/firebase';
import { useAuth } from '../context/AuthContext';
import { MfaChallengePage } from './MfaChallengePage';
import { Button, Card, PageLayout } from '../components/ui';

export function MfaEnrollmentPage() {
  const { status, user, mfaResolver, mfaEnrollmentRequired, requiresMfa, signOut, refreshAuthState } = useAuth();
  const auth = getFirebaseAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const recaptchaRef = useRef<RecaptchaVerifier | null>(null);

  const [phoneNumber, setPhoneNumber] = useState('');
  const [verificationId, setVerificationId] = useState<string | null>(null);
  const [code, setCode] = useState('');
  const [isSending, setIsSending] = useState(false);
  const [isVerifying, setIsVerifying] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const from = (location.state as { from?: Location })?.from?.pathname || '/dashboard';

  useEffect(() => {
    if (status === 'loading') return;
    if (status !== 'mfa_required') {
      const target = status === 'unauthenticated' ? '/login' : from;
      navigate(target, { replace: true });
    }
  }, [status, navigate, from]);

  useEffect(() => {
    return () => {
      recaptchaRef.current?.clear();
      recaptchaRef.current = null;
    };
  }, []);

  const ensureRecaptcha = () => {
    if (!auth) return null;
    if (recaptchaRef.current) return recaptchaRef.current;

    const verifier = new RecaptchaVerifier(auth, 'mfa-enroll-recaptcha', {
      size: 'invisible',
    });
    verifier.render();
    recaptchaRef.current = verifier;
    return verifier;
  };

  const startEnrollment = async (e: FormEvent) => {
    e.preventDefault();
    if (!auth || !user) {
      setError('Your session expired. Please sign in again.');
      return;
    }
    setError(null);
    setIsSending(true);
    try {
      const verifier = ensureRecaptcha();
      if (!verifier) {
        setError('reCAPTCHA could not start. Please retry.');
        return;
      }

      const session = await multiFactor(auth.currentUser!).getSession();
      const phoneProvider = new PhoneAuthProvider(auth);
      const id = await phoneProvider.verifyPhoneNumber(
        {
          phoneNumber,
          session,
        },
        verifier
      );
      setVerificationId(id);
    } catch {
      setError('Unable to send verification code. Please retry.');
      recaptchaRef.current?.clear();
      recaptchaRef.current = null;
    } finally {
      setIsSending(false);
    }
  };

  const verifyEnrollment = async () => {
    if (!verificationId || !auth || !user) {
      setError('Verification expired. Please resend the code.');
      return;
    }

    setIsVerifying(true);
    setError(null);
    try {
      const credential = PhoneAuthProvider.credential(verificationId, code);
      const assertion = PhoneMultiFactorGenerator.assertion(credential);
      await multiFactor(auth.currentUser!).enroll(assertion, 'Primary phone');
      await refreshAuthState();
      navigate(from, { replace: true });
    } catch {
      setError('Invalid code. Please try again.');
      recaptchaRef.current?.clear();
      recaptchaRef.current = null;
    } finally {
      setIsVerifying(false);
    }
  };

  if (mfaResolver) {
    return (
      <MfaChallengePage
        resolver={mfaResolver}
        onResolved={async () => {
          await refreshAuthState();
        }}
      />
    );
  }

  return (
    <PageLayout width="wide">
      <div className="ui-auth">
        <Card className="ui-auth__panel" padding="lg">
          <header className="ui-auth__header">
            <p className="ui-auth__eyebrow">Security verification</p>
            <h1 className="ui-auth__title">Set up multi-factor authentication</h1>
            <p className="ui-auth__subtitle">
              Enroll a trusted phone number to continue into the workspace.
            </p>
          </header>

          {error && <div className="error-message">{error}</div>}
          {requiresMfa && mfaEnrollmentRequired && (
            <div className="info-banner">
              MFA required for this business (HIPAA/2FA policy). Enrollment is mandatory for owner/admin roles.
            </div>
          )}

          {!user && (
            <div className="info-banner">
              Your session is not active. Please sign in again to complete MFA.
            </div>
          )}

          <form className="mfa-form" onSubmit={startEnrollment}>
            <div className="form-group">
              <label htmlFor="phone-number">Phone number</label>
              <input
                id="phone-number"
                type="tel"
                value={phoneNumber}
                onChange={(e) => setPhoneNumber(e.target.value)}
                placeholder="+1 555 555 5555"
                disabled={isSending || isVerifying}
                required
              />
            </div>

            <div className="ui-auth__actions">
              <Button type="submit" disabled={isSending || isVerifying}>
                {isSending ? 'Sending code...' : 'Send verification code'}
              </Button>
              <Button
                type="button"
                variant="ghost"
                onClick={async () => {
                  await signOut();
                  navigate('/login', { replace: true });
                }}
              >
                Sign out
              </Button>
            </div>
          </form>

          {verificationId && (
            <div className="mfa-form ui-auth__verification">
              <div className="form-group">
                <label htmlFor="verification-code">Enter the code</label>
                <input
                  id="verification-code"
                  type="text"
                  value={code}
                  onChange={(e) => setCode(e.target.value)}
                  placeholder="6-digit code"
                  disabled={isVerifying}
                  required
                />
              </div>
              <div className="ui-auth__actions">
                <Button type="button" onClick={verifyEnrollment} disabled={isVerifying}>
                  {isVerifying ? 'Verifying...' : 'Verify & enroll'}
                </Button>
              </div>
            </div>
          )}

          <div id="mfa-enroll-recaptcha" />
          <p className="ui-auth__footer">
            Verification codes are only used to confirm the enrolled device for this authenticated session.
          </p>
        </Card>
      </div>
    </PageLayout>
  );
}
