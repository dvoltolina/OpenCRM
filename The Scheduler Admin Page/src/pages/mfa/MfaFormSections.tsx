type MfaMethod = 'totp' | 'sms';

type MethodToggleProps = {
  availableMethods: MfaMethod[];
  selected: MfaMethod;
  disabled: boolean;
  onSelect: (method: MfaMethod) => void;
};

export function MethodToggle({ availableMethods, selected, disabled, onSelect }: MethodToggleProps) {
  if (availableMethods.length <= 1) return null;

  return (
    <div role="group" aria-labelledby="method-toggle-label" style={{ marginTop: 12, marginBottom: 8 }}>
      <p id="method-toggle-label" className="muted" style={{ marginBottom: 8 }}>Choose how you want to verify:</p>
      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
        <button
          type="button"
          className={selected === 'totp' ? 'button button--secondary' : 'button button--ghost'}
          onClick={() => onSelect('totp')}
          disabled={disabled}
          aria-pressed={selected === 'totp'}
          aria-label="Verify using authenticator app"
        >
          Authenticator app
        </button>
        <button
          type="button"
          className={selected === 'sms' ? 'button button--secondary' : 'button button--ghost'}
          onClick={() => onSelect('sms')}
          disabled={disabled}
          aria-pressed={selected === 'sms'}
          aria-label="Verify using text message"
        >
          Text message
        </button>
      </div>
    </div>
  );
}

type TotpEnrollSectionProps = {
  qrCodeUrl: string | null;
  manualEntryKey: string;
  code: string;
  isGenerating: boolean;
  isVerifying: boolean;
  isSavingCodes: boolean;
  disableInputs: boolean;
  onCodeChange: (value: string) => void;
  onVerify: () => void;
  onRetryQr: () => void;
};

export function TotpEnrollSection({
  qrCodeUrl,
  manualEntryKey,
  code,
  isGenerating,
  isVerifying,
  isSavingCodes,
  disableInputs,
  onCodeChange,
  onVerify,
  onRetryQr,
}: TotpEnrollSectionProps) {
  return (
    <>
      {isGenerating ? (
        <p style={{ marginTop: 16 }}>Generating QR code...</p>
      ) : qrCodeUrl ? (
        <>
          <div style={{ marginTop: 24, marginBottom: 16, textAlign: 'center' }}>
            <p style={{ marginBottom: 12, fontWeight: 500 }}>
              Scan this QR code with your authenticator app:
            </p>
            <img
              src={qrCodeUrl}
              alt="QR code for authenticator app"
              style={{ maxWidth: '240px', margin: '0 auto' }}
            />
          </div>

          <div style={{ marginBottom: 16, textAlign: 'center' }}>
            <p style={{ marginBottom: 8, fontSize: '14px', color: '#666' }}>
              Or enter this code manually:
            </p>
            <p
              style={{
                fontFamily: 'monospace',
                fontSize: '14px',
                backgroundColor: '#f5f5f5',
                padding: '8px',
                borderRadius: '4px',
                wordBreak: 'break-all',
              }}
            >
              {manualEntryKey}
            </p>
          </div>
        </>
      ) : (
        <div style={{ marginTop: 16, padding: 12, border: '1px solid #eee', borderRadius: 8 }}>
          <p style={{ margin: 0, marginBottom: 8 }}>
            Still waiting on the QR code. You can retry QR generation or switch to text verification.
          </p>
          <button
            className="button button--secondary"
            type="button"
            onClick={onRetryQr}
            disabled={isGenerating}
            aria-busy={isGenerating}
            aria-label="Retry QR code generation"
          >
            {isGenerating ? 'Retrying...' : 'Retry QR code'}
          </button>
        </div>
      )}

      <label className="auth-label" htmlFor="totp-enroll-code" style={{ marginTop: 16 }}>
        Enter the 6-digit code from your app
        <input
          id="totp-enroll-code"
          type="text"
          inputMode="numeric"
          value={code}
          onChange={(e) => onCodeChange(e.target.value.replace(/\D/g, '').slice(0, 6))}
          placeholder="000000"
          disabled={disableInputs || !qrCodeUrl}
          maxLength={6}
          aria-required="true"
          aria-describedby="totp-enroll-code-help"
          autoComplete="one-time-code"
        />
        <span id="totp-enroll-code-help" className="sr-only">Enter the 6-digit verification code from your authenticator app</span>
      </label>

      <button
        className="button button--primary"
        type="button"
        onClick={onVerify}
        disabled={disableInputs || !qrCodeUrl || code.length !== 6}
        aria-busy={isVerifying || isSavingCodes}
        style={{ marginTop: 16 }}
      >
        {isVerifying ? 'Verifying...' : isSavingCodes ? 'Setting up backup codes...' : 'Verify & Continue'}
      </button>
    </>
  );
}

type SmsEnrollSectionProps = {
  phoneNumber: string;
  code: string;
  isSendingSms: boolean;
  isVerifying: boolean;
  isSavingCodes: boolean;
  disableInputs: boolean;
  hasVerificationId: boolean;
  recaptchaReady: boolean;
  onPhoneChange: (value: string) => void;
  onCodeChange: (value: string) => void;
  onSendCode: () => void;
  onVerify: () => void;
};

export function SmsEnrollSection({
  phoneNumber,
  code,
  isSendingSms,
  isVerifying,
  isSavingCodes,
  disableInputs,
  hasVerificationId,
  recaptchaReady,
  onPhoneChange,
  onCodeChange,
  onSendCode,
  onVerify,
}: SmsEnrollSectionProps) {
  return (
    <>
      <label className="auth-label" htmlFor="sms-enroll-phone" style={{ marginTop: 12 }}>
        Phone number for MFA
        <input
          id="sms-enroll-phone"
          type="tel"
          value={phoneNumber}
          onChange={(e) => onPhoneChange(e.target.value)}
          placeholder="+1 415 555 0123"
          disabled={disableInputs}
          aria-required="true"
          autoComplete="tel"
        />
      </label>
      <div style={{ display: 'flex', gap: 8, marginTop: 8 }}>
        <button
          className="button button--secondary"
          type="button"
          onClick={onSendCode}
          disabled={disableInputs || !recaptchaReady || !phoneNumber.trim()}
          aria-busy={isSendingSms}
          aria-label={hasVerificationId ? 'Resend verification code' : 'Send verification code'}
        >
          {isSendingSms ? 'Sending...' : hasVerificationId ? 'Resend code' : 'Send code'}
        </button>
      </div>

      <label className="auth-label" htmlFor="sms-enroll-code" style={{ marginTop: 16 }}>
        Enter the 6-digit code from your text
        <input
          id="sms-enroll-code"
          type="text"
          inputMode="numeric"
          value={code}
          onChange={(e) => onCodeChange(e.target.value.replace(/\D/g, '').slice(0, 6))}
          placeholder="000000"
          disabled={disableInputs || !hasVerificationId}
          maxLength={6}
          aria-required="true"
          autoComplete="one-time-code"
        />
      </label>

      <button
        className="button button--primary"
        type="button"
        onClick={onVerify}
        disabled={disableInputs || !hasVerificationId || code.length !== 6}
        aria-busy={isVerifying || isSavingCodes}
        style={{ marginTop: 16 }}
      >
        {isVerifying ? 'Verifying...' : isSavingCodes ? 'Setting up backup codes...' : 'Verify & Continue'}
      </button>
    </>
  );
}

type TotpChallengeSectionProps = {
  code: string;
  isVerifying: boolean;
  isIdle: boolean;
  onCodeChange: (value: string) => void;
  onVerify: () => void;
};

export function TotpChallengeSection({
  code,
  isVerifying,
  isIdle,
  onCodeChange,
  onVerify,
}: TotpChallengeSectionProps) {
  return (
    <>
      <label className="auth-label" htmlFor="totp-challenge-code">
        Enter the 6-digit code from your authenticator
        <input
          id="totp-challenge-code"
          type="text"
          inputMode="numeric"
          value={code}
          onChange={(e) => onCodeChange(e.target.value.replace(/\D/g, '').slice(0, 6))}
          placeholder="000000"
          disabled={isVerifying}
          maxLength={6}
          aria-required="true"
          autoComplete="one-time-code"
        />
      </label>

      <button
        className="button button--primary"
        type="button"
        onClick={onVerify}
        disabled={!isIdle || code.length !== 6}
        aria-busy={isVerifying}
        style={{ marginTop: 16 }}
      >
        {isVerifying ? 'Verifying...' : 'Verify & continue'}
      </button>
    </>
  );
}

type SmsChallengeSectionProps = {
  phoneDisplay?: string | null;
  code: string;
  isSendingSms: boolean;
  isVerifying: boolean;
  disableInputs: boolean;
  hasVerificationId: boolean;
  recaptchaReady: boolean;
  onCodeChange: (value: string) => void;
  onSendCode: () => void;
  onVerify: () => void;
};

export function SmsChallengeSection({
  phoneDisplay,
  code,
  isSendingSms,
  isVerifying,
  disableInputs,
  hasVerificationId,
  recaptchaReady,
  onCodeChange,
  onSendCode,
  onVerify,
}: SmsChallengeSectionProps) {
  return (
    <>
      <div className="panel" style={{ marginTop: 12 }}>
        <p style={{ margin: 0 }}>Send a code to {phoneDisplay ?? 'your phone number'}.</p>
        <div style={{ display: 'flex', gap: 8, marginTop: 8 }}>
          <button
            className="button button--secondary"
            type="button"
            onClick={onSendCode}
            disabled={disableInputs || !recaptchaReady}
            aria-busy={isSendingSms}
            aria-label={hasVerificationId ? 'Resend verification code' : 'Send verification code'}
          >
            {isSendingSms ? 'Sending...' : hasVerificationId ? 'Resend code' : 'Send code'}
          </button>
        </div>
      </div>

      <label className="auth-label" htmlFor="sms-challenge-code" style={{ marginTop: 16 }}>
        Enter the 6-digit code from your text
        <input
          id="sms-challenge-code"
          type="text"
          inputMode="numeric"
          value={code}
          onChange={(e) => onCodeChange(e.target.value.replace(/\D/g, '').slice(0, 6))}
          placeholder="000000"
          disabled={disableInputs || !hasVerificationId}
          maxLength={6}
          aria-required="true"
          autoComplete="one-time-code"
        />
      </label>

      <button
        className="button button--primary"
        type="button"
        onClick={onVerify}
        disabled={disableInputs || !hasVerificationId || code.length !== 6}
        aria-busy={isVerifying}
        style={{ marginTop: 16 }}
      >
        {isVerifying ? 'Verifying...' : 'Verify & continue'}
      </button>
    </>
  );
}
