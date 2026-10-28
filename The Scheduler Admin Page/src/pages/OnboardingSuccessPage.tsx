import { Navigate, useNavigate } from 'react-router-dom';

import { useBusinessContext } from '../hooks/useBusinessContext';
import { useOnboarding } from '../hooks/useOnboarding';
import { useWorkspaceInfo } from '../hooks/useWorkspaceInfo';

function formatDeposit({
  requireDeposit,
  depositType,
  depositAmount,
}: {
  requireDeposit: boolean;
  depositType?: 'amount' | 'percent';
  depositAmount?: number;
}) {
  if (!requireDeposit) return 'No deposit required';
  const value = depositAmount ?? 0;
  return depositType === 'percent' ? `${value}% of service price` : `$${value} fixed deposit`;
}

function getSelfBookingLabel(value?: string) {
  if (!value) return 'Not set';
  const labels: Record<string, string> = {
    disabled: 'Disabled',
    existing_only: 'Existing clients',
    all_customers: 'All customers',
  };
  return labels[value] ?? value;
}

export function OnboardingSuccessPage() {
  const navigate = useNavigate();
  const { businessId, userId } = useBusinessContext();
  const { state, loading, error } = useOnboarding(businessId, userId);
  const {
    workspace,
    loading: workspaceLoading,
    error: workspaceError,
  } = useWorkspaceInfo(businessId);

  if (!businessId) return <Navigate to="/login" replace />;

  const bookingUrl =
    workspace?.publicBookingUrl || (workspace?.slug ? `https://app.example.com/book/${workspace.slug}` : null);
  const openDays = state?.scheduling.hours?.filter((h) => h.isOpen) ?? [];

  if ((loading || workspaceLoading) && !state) {
    return (
      <div className="panel" style={{ margin: 24 }}>
        <p>Loading your onboarding summary...</p>
      </div>
    );
  }

  if (!loading && state && state.status !== 'completed') {
    return <Navigate to="/onboarding" replace />;
  }

  return (
    <section>
      <header className="page-header">
        <div>
          <p className="eyebrow">Onboarding complete</p>
          <h1>You're ready to start booking</h1>
          <p className="muted">
            Share your booking link and invite code, review booking preferences, and head to the dashboard to start
            working.
          </p>
        </div>
        <div className="header-actions">
          <button className="button button--ghost" type="button" onClick={() => navigate('/dashboard')}>
            Go to dashboard
          </button>
          <button className="button button--primary" type="button" onClick={() => navigate('/staff')}>
            Manage team permissions
          </button>
        </div>
      </header>

      {(error || workspaceError) && (
        <div className="panel" style={{ borderColor: 'var(--danger-color, #b42318)' }}>
          <p className="muted">{error || workspaceError}</p>
        </div>
      )}

      <div className="grid grid--2" style={{ gap: 16 }}>
        <div className="panel">
          <p className="eyebrow">Share links</p>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            <div>
              <p className="muted" style={{ margin: 0 }}>
                Public booking URL
              </p>
              {bookingUrl ? (
                <a href={bookingUrl} target="_blank" rel="noreferrer" style={{ wordBreak: 'break-all' }}>
                  {bookingUrl}
                </a>
              ) : (
                <p className="muted" style={{ margin: 0 }}>
                  Booking URL will appear once a slug is configured.
                </p>
              )}
            </div>
            <div>
              <p className="muted" style={{ margin: 0 }}>
                Invite code
              </p>
              <p style={{ margin: 0, fontFamily: 'monospace' }}>{workspace?.inviteCode ?? 'Not available yet'}</p>
            </div>
          </div>
        </div>
        <div className="panel">
          <p className="eyebrow">Booking preferences</p>
          <p style={{ margin: '4px 0' }}>
            Self-booking: <strong>{getSelfBookingLabel(state?.scheduling.selfBookingAccess)}</strong>
          </p>
          <p className="muted" style={{ margin: '4px 0' }}>
            Deposit: {state ? formatDeposit(state.scheduling) : 'Not set'}
          </p>
          <p className="muted" style={{ margin: '4px 0' }}>
            Reminders: {state ? `${state.scheduling.emailReminders ? 'Email' : 'No email'} · ${state.scheduling.smsReminders ? 'SMS' : 'No SMS'} · ${state.scheduling.reminderLeadTimeHours}h before` : 'Not set'}
          </p>
        </div>
      </div>

      <div className="panel" style={{ marginTop: 16 }}>
        <p className="eyebrow">Operating hours</p>
        {openDays.length === 0 && <p className="muted">No hours set.</p>}
        {openDays.length > 0 && (
          <div className="grid grid--2" style={{ gap: 12 }}>
            {openDays.map((day) => (
              <div key={day.day} className="panel" style={{ margin: 0 }}>
                <p style={{ margin: '0 0 4px 0', textTransform: 'capitalize' }}>{day.day}</p>
                {day.blocks.map((block, idx) => (
                  <p key={idx} className="muted" style={{ margin: 0 }}>
                    {block.start} - {block.end}
                  </p>
                ))}
              </div>
            ))}
          </div>
        )}
      </div>
    </section>
  );
}
