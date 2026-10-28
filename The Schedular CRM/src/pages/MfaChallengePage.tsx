import { useEffect, useRef, useState } from 'react';
import type { MultiFactorResolver } from 'firebase/auth';
import { PhoneAuthProvider, PhoneMultiFactorGenerator, RecaptchaVerifier } from 'firebase/auth';
import { useNavigate } from 'react-router-dom';
import { getFirebaseAuth } from '../lib/firebase';
import { useAuth } from '../context/AuthContext';
import { Button, Card, PageLayout } from '../components/ui';

interface MfaChallengePageProps {
  resolver: MultiFactorResolver;
  onResolved: () => Promise<void>;
}

export function MfaChallengePage({ resolver, onResolved }: MfaChallengePageProps) {
  const auth = getFirebaseAuth();
  const navigate = useNavigate();
  const { signOut } = useAuth();
  const recaptchaRef = useRef<RecaptchaVerifier | null>(null);

  const [verificationId, setVerificationId] = useState<string | null>(null);
  const [code, setCode] = useState('');
  const [isSending, setIsSending] = useState(false);
  const [isVerifying, setIsVerifying] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    return () => {
      recaptchaRef.current?.clear();
      recaptchaRef.current = null;
    };
  }, []);

  useEffect(() => {
    // Send the first code when arriving on the challenge screen
    sendCode();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [resolver]);

  const ensureRecaptcha = () => {
    if (!auth) return null;
    if (recaptchaRef.current) return recaptchaRef.current;

    const verifier = new RecaptchaVerifier(auth, 'mfa-challenge-recaptcha', {
      size: 'invisible',
    });
    verifier.render();
    recaptchaRef.current = verifier;
    return verifier;
  };

  const sendCode = async () => {
    if (!auth) {
      setError('Session not initialized. Please sign in again.');
      return;
    }
    setError(null);
    setIsSending(true);
    try {
      const verifier = ensureRecaptcha();
      if (!verifier) {
        setError('reCAPTCHA failed to initialize.');
        return;
      }

      const phoneProvider = new PhoneAuthProvider(auth);
      const firstHint = resolver.hints[0];
      const id = await phoneProvider.verifyPhoneNumber(
        {
          multiFactorHint: firstHint,
          session: resolver.session,
        },
        verifier
      );
      setVerificationId(id);
    } catch {
      setError('Could not send verification code. Please retry.');
      recaptchaRef.current?.clear();
      recaptchaRef.current = null;
    } finally {
      setIsSending(false);
    }
  };

  const verifyCode = async () => {
    if (!verificationId) {
      setError('Request a verification code to continue.');
      return;
    }

    setError(null);
    setIsVerifying(true);
    try {
      const credential = PhoneAuthProvider.credential(verificationId, code);
      const assertion = PhoneMultiFactorGenerator.assertion(credential);
      await resolver.resolveSignIn(assertion);
      await onResolved();
      navigate('/dashboard', { replace: true });
    } catch {
      setError('Invalid code. Please try again.');
      recaptchaRef.current?.clear();
      recaptchaRef.current = null;
    } finally {
      setIsVerifying(false);
    }
  };

  const maskedPhone = (resolver.hints[0] as any)?.phoneNumber || 'your enrolled device';

  return (
    <PageLayout width="wide">
      <div className="ui-auth">
        <Card className="ui-auth__panel" padding="lg">
          <header className="ui-auth__header">
            <p className="ui-auth__eyebrow">Security verification</p>
            <h1 className="ui-auth__title">Complete multi-factor sign-in</h1>
            <p className="ui-auth__subtitle">
              We sent a verification code to {maskedPhone}. Enter it to continue.
            </p>
          </header>

          {error && <div className="error-message">{error}</div>}

          <div className="ui-auth__actions">
            <Button type="button" variant="secondary" onClick={sendCode} disabled={isSending}>
              {isSending ? 'Sending code...' : 'Resend code'}
            </Button>
          </div>

          <div className="form-group">
            <label htmlFor="mfa-code">Verification code</label>
            <input
              id="mfa-code"
              type="text"
              value={code}
              onChange={(e) => setCode(e.target.value)}
              placeholder="Enter 6-digit code"
              disabled={isVerifying}
            />
          </div>

          <div className="ui-auth__actions">
            <Button type="button" onClick={verifyCode} disabled={isVerifying}>
              {isVerifying ? 'Verifying...' : 'Verify and continue'}
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

          <div id="mfa-challenge-recaptcha" />
          <p className="ui-auth__footer">
            If you no longer have access to this device, sign out and contact a workspace administrator.
          </p>
        </Card>
      </div>
    </PageLayout>
  );
}
