import type { OperatingHoursDay as OperatingHoursDayStrict } from '../types/models';

type OperatingHoursBlock = Partial<OperatingHoursDayStrict['blocks'][number]>;
type OperatingHoursDay = Partial<OperatingHoursDayStrict> & { blocks?: OperatingHoursBlock[] };
export type OperatingHoursValue = string | OperatingHoursDay[] | null | undefined;

const DAY_LABELS: Record<string, string> = {
  monday: 'Mon',
  tuesday: 'Tue',
  wednesday: 'Wed',
  thursday: 'Thu',
  friday: 'Fri',
  saturday: 'Sat',
  sunday: 'Sun',
};

const formatDayLabel = (value?: string) => {
  if (!value) return 'Day';
  const normalized = value.toLowerCase();
  return DAY_LABELS[normalized] ?? `${value.charAt(0).toUpperCase()}${value.slice(1)}`;
};

const formatBlocks = (blocks?: OperatingHoursBlock[]) => {
  if (!Array.isArray(blocks)) return '';
  const validBlocks = blocks.filter((block) => block?.start && block?.end);
  if (!validBlocks.length) return '';
  return validBlocks.map((block) => `${block.start}-${block.end}`).join(', ');
};

/**
 * Formats operating hours that may be stored as a human-readable string or a structured array.
 * This keeps rendering safe even when Firestore data contains the structured shape from onboarding.
 */
export function formatOperatingHours(hours: OperatingHoursValue, fallback = 'Not set'): string {
  if (!hours) return fallback;
  if (typeof hours === 'string') return hours || fallback;
  if (!Array.isArray(hours)) return fallback;

  const openDays = hours.filter((day) => day && day.isOpen);
  if (!openDays.length) return 'Closed';

  const parts = openDays
    .map((day) => {
      if (!day) return '';
      const label = formatDayLabel(day.day);
      const blocksText = formatBlocks(day.blocks);
      return blocksText ? `${label} ${blocksText}` : label;
    })
    .filter(Boolean);

  return parts.length ? parts.join(' | ') : fallback;
}
