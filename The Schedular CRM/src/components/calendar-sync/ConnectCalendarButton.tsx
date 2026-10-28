import type { CalendarProvider } from '../../types/calendar-sync';

interface ConnectCalendarButtonProps {
  disabled?: boolean;
  onStartOAuth: (provider: CalendarProvider) => Promise<void> | void;
  helperText?: string;
}

export function ConnectCalendarButton({
  disabled,
  onStartOAuth,
  helperText,
}: ConnectCalendarButtonProps) {
  return (
    <div className="connect-calendar">
      <div className="connect-calendar__buttons">
        <button
          type="button"
          className="btn btn--primary"
          disabled={disabled}
          onClick={() => onStartOAuth('google')}
        >
          Connect Google Calendar
        </button>
        <button
          type="button"
          className="btn btn--secondary"
          disabled={disabled}
          onClick={() => onStartOAuth('outlook')}
        >
          Connect Outlook
        </button>
      </div>
      {helperText && <p className="text-muted">{helperText}</p>}
    </div>
  );
}

export default ConnectCalendarButton;
