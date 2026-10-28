import type {
  CalendarIntegrationProvider,
  TelehealthFallbackOption,
  TelehealthProvider,
} from '../../types/models';

export type ProviderMeta<T extends string> = {
  id: T;
  name: string;
  description: string;
  tone: 'badge--success' | 'badge--info' | 'badge--warn' | 'badge--neutral';
};

export const CALENDAR_PROVIDER_META: ProviderMeta<CalendarIntegrationProvider>[] = [
  {
    id: 'googleCalendar',
    name: 'Google Calendar',
    description: 'Two-way syncing for Workspace + personal calendars.',
    tone: 'badge--success',
  },
  {
    id: 'outlookCalendar',
    name: 'Microsoft Outlook',
    description: 'Office 365 / Exchange calendar sync for staff.',
    tone: 'badge--info',
  },
];

export const TELEHEALTH_PROVIDER_META: ProviderMeta<TelehealthProvider>[] = [
  {
    id: 'zoom',
    name: 'Zoom',
    description: 'Generate Zoom links for telehealth appointments.',
    tone: 'badge--success',
  },
  {
    id: 'googleMeet',
    name: 'Google Meet',
    description: 'Provision Meet links tied to Google Workspace accounts.',
    tone: 'badge--info',
  },
];

export const PROVIDER_STATUS_META = {
  connected: { label: 'Connected', tone: 'badge--success' },
  connecting: { label: 'Connecting', tone: 'badge--info' },
  error: { label: 'Needs attention', tone: 'badge--warn' },
  disconnected: { label: 'Disconnected', tone: 'badge--neutral' },
} as const;

export const CALENDAR_SELECT_OPTIONS: Array<{
  value: CalendarIntegrationProvider | 'none';
  label: string;
}> = [
  { value: 'none', label: 'Unassigned' },
  { value: 'googleCalendar', label: 'Google Calendar' },
  { value: 'outlookCalendar', label: 'Microsoft Outlook' },
];

export const TELEHEALTH_SELECT_OPTIONS: Array<{
  value: TelehealthProvider | 'default' | TelehealthFallbackOption;
  label: string;
}> = [
  { value: 'default', label: 'Use default setting' },
  { value: 'zoom', label: 'Zoom' },
  { value: 'googleMeet', label: 'Google Meet' },
  { value: 'phone', label: 'Phone fallback' },
  { value: 'in_person', label: 'In person' },
];

