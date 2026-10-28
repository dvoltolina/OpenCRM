import { useEffect, useMemo, useState } from 'react';
import { Navigate, useNavigate } from 'react-router-dom';
import {
  multiFactor,
  PhoneAuthProvider,
  PhoneMultiFactorGenerator,
  RecaptchaVerifier,
  TotpMultiFactorGenerator,
  TotpSecret,
  type MultiFactorResolver,
  type PhoneMultiFactorInfo,
  type User,
} from 'firebase/auth';
import QRCode from 'qrcode';

import { useAuth } from '../context/AuthContext';
import { getFirebaseAuth } from '../lib/firebase';
import { generateBackupCodes, saveBackupCodes } from '../data/backupCodes';
import { logAuditEvent } from '../data/auditLog';
import { BackupCodesView } from './mfa/BackupCodesView';
import {
  MethodToggle,
  SmsChallengeSection,
  SmsEnrollSection,
  TotpChallengeSection,
  TotpEnrollSection,
} from './mfa/MfaFormSections';

type ViewState =
  | 'idle'
  | 'generating_qr'
  | 'sending_sms'
  | 'verifying'
  | 'saving_codes'
  | 'show_backup_codes';

type MfaMethod = 'totp' | 'sms';

export function MfaPage() {
  const { state, refreshUser, signOut } = useAuth();
  const navigate = useNavigate();

  // Enrollment state
  const [qrCodeUrl, setQrCodeUrl] = useState<string | null>(null);
  const [totpSecret, setTotpSecret] = useState<TotpSecret | null>(null);
  const [manualEntryKey, setManualEntryKey] = useState<string>('');
  const [qrAttempted, setQrAttempted] = useState(false);
  const [phoneNumber, setPhoneNumber] = useState('');
  const [smsVerificationId, setSmsVerificationId] = useState<string | null>(null);
  const [recaptchaVerifier, setRecaptchaVerifier] = useState<RecaptchaVerifier | null>(null);

  // Common state
  const [method, setMethod] = useState<MfaMethod>('totp');
  const [code, setCode] = useState('');
  const [status, setStatus] = useState<ViewState>('idle');
  const [error, setError] = useState<string | null>(null);
  const [backupCodes, setBackupCodes] = useState<string[]>([]);
  const [savedBackupCodes, setSavedBackupCodes] = useState(false);

  const isEnroll = state.status === 'mfa_required' && state.step === 'enroll';
  const isChallenge = state.status === 'mfa_required' && state.step === 'challenge';

  const resolver: MultiFactorResolver | undefined = useMemo(() => {
    if (state.status === 'mfa_required' && state.step === 'challenge') {
      return state.resolver;
    }
    return undefined;
  }, [state]);

  const phoneHint: PhoneMultiFactorInfo | undefined = useMemo(() => {
    return resolver?.hints.find((hint) => hint.factorId === 'phone') as
      | PhoneMultiFactorInfo
      | undefined;
  }, [resolver]);

  const availableMethods = useMemo<MfaMethod[]>(() => {
    if (isEnroll) return ['totp', 'sms'];

    const methods: MfaMethod[] = [];
    if (resolver?.hints.some((hint) => hint.factorId === 'totp')) {
      methods.push('totp');
    }
    if (resolver?.hints.some((hint) => hint.factorId === 'phone')) {
      methods.push('sms');
    }
    return methods.length ? methods : ['totp'];
  }, [isEnroll, resolver]);

  useEffect(() => {
    if (!availableMethods.includes(method)) {
      setMethod(availableMethods[0]);
      setCode('');
    }
  }, [availableMethods, method]);

  useEffect(() => {
    setError(null);
    setCode('');
    setSmsVerificationId(null);
    if (method === 'totp') {
      setQrAttempted(false);
    }
  }, [method]);

  useEffect(() => {
    if (method !== 'sms' || recaptchaVerifier) return;

    let verifier: RecaptchaVerifier | null = null;
    try {
      verifier = new RecaptchaVerifier(getFirebaseAuth(), 'mfa-recaptcha-container', {
        size: 'invisible',
      });
      void verifier.render();
      setRecaptchaVerifier(verifier);
    } catch (err) {
      // HIPAA: Log error without exposing user data
      console.error('Failed to initialize reCAPTCHA');
      setError('Unable to start SMS verification. Try authenticator app or refresh the page.');
    }

    return () => {
      verifier?.clear();
      setRecaptchaVerifier((current) => (current === verifier ? null : current));
    };
  }, [method, recaptchaVerifier]);

  // Generate QR code on enrollment
  useEffect(() => {
    if (!isEnroll || method !== 'totp' || qrCodeUrl || status !== 'idle' || qrAttempted) return;

    const generateQR = async () => {
      setQrAttempted(true);
      setStatus('generating_qr');
      setError(null);

      try {
        const auth = getFirebaseAuth();
        const currentUser = auth.currentUser;
        if (!currentUser) {
          throw new Error('No authenticated user found.');
        }

        const session = await multiFactor(currentUser).getSession();
        const secret = await TotpMultiFactorGenerator.generateSecret(session);

        const qrUrl = secret.generateQrCodeUrl(
          currentUser.email ?? 'user@example.com',
          'The Scheduler',
        );

        const qrDataUrl = await QRCode.toDataURL(qrUrl);
        setQrCodeUrl(qrDataUrl);
        setTotpSecret(secret);
        setManualEntryKey(secret.secretKey);
        setStatus('idle');
      } catch (err) {
        // HIPAA: Log error without exposing user data
        console.error('Failed to generate TOTP secret');
        setError('Failed to set up authenticator. Please try again or switch to text verification.');
        setStatus('idle');
      }
    };

    void generateQR();
  }, [isEnroll, method, qrAttempted, qrCodeUrl, status]);

  const finalizeEnrollment = async (currentUser: User, methodUsed: MfaMethod) => {
    const businessId =
      state.status === 'mfa_required' && state.step === 'enroll' ? state.user.businessId : '';

    if (businessId) {
      await logAuditEvent({
        businessId,
        userId: currentUser.uid,
        actionType: 'mfa_enrolled',
        entityType: 'user',
        entityId: currentUser.uid,
        metadata: { method: methodUsed },
      });
    }

    setStatus('saving_codes');
    const codes = generateBackupCodes(10);
    setBackupCodes(codes);

    if (businessId) {
      await saveBackupCodes(businessId, currentUser.uid, codes);
      await logAuditEvent({
        businessId,
        userId: currentUser.uid,
        actionType: 'backup_codes_generated',
        entityType: 'user',
        entityId: currentUser.uid,
        metadata: { count: codes.length },
      });
    }

    setStatus('show_backup_codes');
  };

  const handleRetryQr = () => {
    setError(null);
    setQrCodeUrl(null);
    setTotpSecret(null);
    setManualEntryKey('');
    setQrAttempted(false);
    setStatus('idle');
  };

  const handleEnrollVerify = async () => {
    if (method === 'sms') {
      await handleEnrollSmsVerify();
      return;
    }

    if (!totpSecret || !code) {
      setError('Please enter the 6-digit code from your authenticator app.');
      return;
    }

    setStatus('verifying');
    setError(null);

    try {
      const auth = getFirebaseAuth();
      const currentUser = auth.currentUser;
      if (!currentUser) {
        throw new Error('No authenticated user found.');
      }

      const assertion = TotpMultiFactorGenerator.assertionForEnrollment(totpSecret, code);
      await multiFactor(currentUser).enroll(assertion, 'Authenticator App');

      await finalizeEnrollment(currentUser, 'totp');
    } catch (err) {
      // HIPAA: Log error without exposing user data
      console.error('MFA enrollment verification failed');
      setError('Verification failed. Confirm the code and try again.');
      setStatus('idle');
    }
  };

  const handleSendSmsCode = async () => {
    if (!isEnroll) return;
    if (!recaptchaVerifier) {
      setError('SMS verification is unavailable. Please refresh and try again.');
      return;
    }

    const normalizedPhone = phoneNumber.trim();
    if (!/^\+?[1-9]\d{7,14}$/.test(normalizedPhone)) {
      setError('Enter a valid phone number in international format (e.g., +14155550123).');
      return;
    }

    setStatus('sending_sms');
    setError(null);

    try {
      const auth = getFirebaseAuth();
      const currentUser = auth.currentUser;
      if (!currentUser) {
        throw new Error('No authenticated user found.');
      }

      const session = await multiFactor(currentUser).getSession();
      const provider = new PhoneAuthProvider(auth);
      const verificationId = await provider.verifyPhoneNumber(
        { phoneNumber: normalizedPhone, session },
        recaptchaVerifier,
      );
      setSmsVerificationId(verificationId);
      setStatus('idle');
    } catch (err) {
      // HIPAA: Log error without exposing user data
      console.error('Failed to send SMS verification code');
      setError('Unable to send verification code. Check the number and try again.');
      setStatus('idle');
    }
  };

  const handleEnrollSmsVerify = async () => {
    if (!smsVerificationId || code.length !== 6) {
      setError('Enter the 6-digit code sent to your phone.');
      return;
    }

    setStatus('verifying');
    setError(null);

    try {
      const auth = getFirebaseAuth();
      const currentUser = auth.currentUser;
      if (!currentUser) {
        throw new Error('No authenticated user found.');
      }

      const credential = PhoneAuthProvider.credential(smsVerificationId, code);
      const assertion = PhoneMultiFactorGenerator.assertion(credential);
      await multiFactor(currentUser).enroll(assertion, 'SMS');

      await finalizeEnrollment(currentUser, 'sms');
    } catch (err) {
      // HIPAA: Log error without exposing user data
      console.error('SMS MFA enrollment verification failed');
      setError('Verification failed. Confirm the code and try again.');
      setStatus('idle');
    }
  };

  const handleBackupCodesContinue = async () => {
    if (!savedBackupCodes) {
      setError('Please confirm you have saved your backup codes in a secure place.');
      return;
    }

    await refreshUser();
    navigate('/dashboard', { replace: true });
  };

  const handleChallengeVerify = async () => {
    if (!resolver) {
      setError('No MFA challenge found. Please try logging in again.');
      return;
    }

    if (method === 'sms') {
      await handleChallengeSmsVerify();
      return;
    }

    if (!code) {
      setError('Please enter the 6-digit code from your authenticator app.');
      return;
    }

    setStatus('verifying');
    setError(null);

    try {
      const auth = getFirebaseAuth();

      // TOTP verification
      const totpHint = resolver.hints.find((hint) => hint.factorId === 'totp');
      if (!totpHint) {
        throw new Error('No TOTP factor enrolled.');
      }

      const assertion = TotpMultiFactorGenerator.assertionForSignIn(totpHint.uid, code);
      await resolver.resolveSignIn(assertion);

      await refreshUser();
      navigate('/dashboard', { replace: true });
    } catch (err) {
      // HIPAA: Log error without exposing user data
      console.error('MFA challenge verification failed');
      setError('Verification failed. Confirm the code and try again.');
      setStatus('idle');
    }
  };

  const handleSendChallengeSms = async () => {
    if (!resolver) {
      setError('No MFA challenge found. Please try logging in again.');
      return;
    }
    if (!recaptchaVerifier) {
      setError('SMS verification is unavailable. Please refresh and try again.');
      return;
    }
    if (!phoneHint) {
      setError('No phone factor found on your account.');
      return;
    }

    setStatus('sending_sms');
    setError(null);

    try {
      const auth = getFirebaseAuth();
      const provider = new PhoneAuthProvider(auth);
      const verificationId = await provider.verifyPhoneNumber(
        { multiFactorHint: phoneHint, session: resolver.session },
        recaptchaVerifier,
      );
      setSmsVerificationId(verificationId);
      setStatus('idle');
    } catch (err) {
      // HIPAA: Log error without exposing user data
      console.error('Failed to send SMS challenge code');
      setError('Unable to send verification code. Try again.');
      setStatus('idle');
    }
  };

  const handleChallengeSmsVerify = async () => {
    if (!resolver) {
      setError('No MFA challenge found. Please try logging in again.');
      return;
    }
    if (!smsVerificationId || code.length !== 6) {
      setError('Enter the 6-digit code sent to your phone.');
      return;
    }

    setStatus('verifying');
    setError(null);

    try {
      const credential = PhoneAuthProvider.credential(smsVerificationId, code);
      const assertion = PhoneMultiFactorGenerator.assertion(credential);
      await resolver.resolveSignIn(assertion);

      await refreshUser();
      navigate('/dashboard', { replace: true });
    } catch (err) {
      // HIPAA: Log error without exposing user data
      console.error('SMS MFA challenge verification failed');
      setError('Verification failed. Confirm the code and try again.');
      setStatus('idle');
    }
  };

  const downloadBackupCodes = () => {
    const text = backupCodes.map((code, idx) => `${idx + 1}. ${code}`).join('\n');
    const blob = new Blob([text], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'scheduler-backup-codes.txt';
    a.click();
    URL.revokeObjectURL(url);
  };

  const copyBackupCodes = async () => {
    const text = backupCodes.join('\n');
    try {
      await navigator.clipboard.writeText(text);
      alert('Backup codes copied to clipboard');
    } catch (err) {
      // HIPAA: Log error without exposing user data
      console.error('Failed to copy backup codes');
    }
  };

  if (state.status === 'loading') {
    return (
      <div className="auth-shell">
        <div className="auth-card">
          <p>Checking account...</p>
        </div>
      </div>
    );
  }

  if (state.status === 'signed_out') {
    return <Navigate to="/login" replace />;
  }

  if (state.status === 'pending_verification') {
    return <Navigate to="/verify-email" replace />;
  }

  if (state.status === 'pending_profile') {
    return <Navigate to="/owner-onboarding" replace />;
  }

  if (state.status === 'signed_in') {
    return <Navigate to="/dashboard" replace />;
  }

  if (!isEnroll && !isChallenge) {
    return <Navigate to="/login" replace />;
  }

  const isSendingSms = status === 'sending_sms';
  const isVerifying = status === 'verifying';
  const isGeneratingQr = status === 'generating_qr';
  const isSavingCodes = status === 'saving_codes';
  const disableInputs = isSendingSms || isVerifying || isSavingCodes;

  // Show backup codes screen after enrollment
  if (status === 'show_backup_codes' && backupCodes.length > 0) {
    return (
      <BackupCodesView
        backupCodes={backupCodes}
        savedBackupCodes={savedBackupCodes}
        error={error}
        onToggleSaved={(checked) => setSavedBackupCodes(checked)}
        onCopyCodes={copyBackupCodes}
        onDownloadCodes={downloadBackupCodes}
        onContinue={handleBackupCodesContinue}
      />
    );
  }

  return (
    <div className="auth-shell">
      <div className="auth-card" role="main" aria-labelledby="mfa-title">
        <p className="eyebrow">Account security</p>
        <h1 id="mfa-title">
          {isEnroll ? 'Set up multi-factor authentication' : 'Verify your identity'}
        </h1>
        <p className="muted">
          {isEnroll
            ? 'HIPAA and 2FA-enforced businesses require an extra verification step for admin/owner accounts.'
            : 'Enter the code from your authenticator app or text message to continue.'}
        </p>

        <MethodToggle
          availableMethods={availableMethods}
          selected={method}
          disabled={disableInputs}
          onSelect={setMethod}
        />

        {isEnroll ? (
          method === 'totp' ? (
            <TotpEnrollSection
              qrCodeUrl={qrCodeUrl}
              manualEntryKey={manualEntryKey}
              code={code}
              isGenerating={isGeneratingQr}
              isVerifying={isVerifying}
              isSavingCodes={isSavingCodes}
              disableInputs={disableInputs}
              onCodeChange={setCode}
              onVerify={handleEnrollVerify}
              onRetryQr={handleRetryQr}
            />
          ) : (
            <SmsEnrollSection
              phoneNumber={phoneNumber}
              code={code}
              isSendingSms={isSendingSms}
              isVerifying={isVerifying}
              isSavingCodes={isSavingCodes}
              disableInputs={disableInputs}
              hasVerificationId={Boolean(smsVerificationId)}
              recaptchaReady={Boolean(recaptchaVerifier)}
              onPhoneChange={setPhoneNumber}
              onCodeChange={setCode}
              onSendCode={handleSendSmsCode}
              onVerify={handleEnrollVerify}
            />
          )
        ) : (
          method === 'totp' ? (
            <TotpChallengeSection
              code={code}
              isVerifying={isVerifying}
              isIdle={status === 'idle'}
              onCodeChange={setCode}
              onVerify={handleChallengeVerify}
            />
          ) : (
            <SmsChallengeSection
              phoneDisplay={phoneHint?.phoneNumber}
              code={code}
              isSendingSms={isSendingSms}
              isVerifying={isVerifying}
              disableInputs={disableInputs}
              hasVerificationId={Boolean(smsVerificationId)}
              recaptchaReady={Boolean(recaptchaVerifier && phoneHint)}
              onCodeChange={setCode}
              onSendCode={handleSendChallengeSms}
              onVerify={handleChallengeVerify}
            />
          )
        )}

        {error ? <p className="error" role="alert" style={{ marginTop: 12 }}>{error}</p> : null}

        <div style={{ marginTop: 16 }}>
          <button
            className="button button--ghost"
            type="button"
            onClick={signOut}
            disabled={disableInputs}
            aria-label="Sign out and return to login page"
          >
            Back to login
          </button>
        </div>
        <div id="mfa-recaptcha-container" style={{ display: 'none' }} aria-hidden="true" />
      </div>
    </div>
  );
}
