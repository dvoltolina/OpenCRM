import { DEMO_BANNER_MESSAGE, DEMO_SIGN_UP_URL, isDemoMode } from '../config/demo';
import { useDemoBlockedMessage } from '../hooks/useDemoGuard';
import './demo-banner.css';

export function DemoBanner() {
  const { clearMessage, message } = useDemoBlockedMessage();

  if (!isDemoMode) {
    return null;
  }

  return (
    <div className="demo-banner" role="status" aria-live="polite">
      <div className="demo-banner__content">
        <div className="demo-banner__copy">
          <span className="demo-banner__eyebrow">Read-only demo</span>
          <span className="demo-banner__message">{DEMO_BANNER_MESSAGE}</span>
        </div>
        <div className="demo-banner__actions">
          {message && (
            <button
              type="button"
              className="demo-banner__notice"
              onClick={clearMessage}
              aria-label="Dismiss demo notice"
            >
              {message}
            </button>
          )}
          <a className="demo-banner__link" href={DEMO_SIGN_UP_URL}>
            Sign Up
          </a>
        </div>
      </div>
    </div>
  );
}
