import './email.css';

interface EmailTrackingBadgeProps {
  opens: number;
  clicks: number;
  firstOpenedAt?: Date;
  lastOpenedAt?: Date;
}

function formatTimestamp(value?: Date): string {
  return value ? new Date(value).toLocaleString() : '';
}

/**
  * Displays simple open/click counts for an email message.
  */
export function EmailTrackingBadge({
  opens,
  clicks,
  firstOpenedAt,
  lastOpenedAt,
}: EmailTrackingBadgeProps) {
  return (
    <div className="email-tracking-badge">
      <div className="email-tracking-badge__pills">
        <span className="email-pill email-pill--success">Opens {opens}</span>
        <span className="email-pill email-pill--info">Clicks {clicks}</span>
      </div>
      {(firstOpenedAt || lastOpenedAt) && (
        <div className="email-tracking-badge__meta">
          {firstOpenedAt && <span>First opened {formatTimestamp(firstOpenedAt)}</span>}
          {lastOpenedAt && <span>Last opened {formatTimestamp(lastOpenedAt)}</span>}
        </div>
      )}
    </div>
  );
}

export default EmailTrackingBadge;
