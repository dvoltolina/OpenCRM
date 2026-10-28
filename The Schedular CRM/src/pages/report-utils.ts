import type { Deal, Lead } from '../types/models';
import { sanitizeTeamIds } from '../lib/security-context';

export function formatCurrency(cents: number, currency: string = 'USD') {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency }).format(
    cents / 100
  );
}

export function groupRevenueByMonth(deals: Deal[]) {
  const map = new Map<string, number>();
  deals
    .filter((d) => d.status === 'won' && d.closedAt)
    .forEach((d) => {
      const date = d.closedAt as Date;
      const key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
      map.set(key, (map.get(key) || 0) + d.valueCents);
    });
  return Array.from(map.entries())
    .sort(([a], [b]) => (a > b ? 1 : -1))
    .map(([period, valueCents]) => ({ period, valueCents }));
}

export function summarizeLeadSources(leads: Lead[]) {
  const map = new Map<string, number>();
  leads.forEach((lead) => {
    const source = lead.source || 'other';
    map.set(source, (map.get(source) || 0) + 1);
  });
  return Array.from(map.entries()).map(([source, count]) => ({ source, count }));
}

export type ReportFilterState = {
  startDate: string;
  endDate: string;
  pipelineId: string;
  stageIds: string[];
  ownerIds: string[];
  teamIds: string[];
  statuses: Array<'open' | 'won' | 'lost'>;
  assigneeIds: string[];
  leadSources: string[];
};

export const DEFAULT_FILTERS: ReportFilterState = {
  startDate: '',
  endDate: '',
  pipelineId: '',
  stageIds: [],
  ownerIds: [],
  teamIds: [],
  statuses: [],
  assigneeIds: [],
  leadSources: [],
};

export const formatDateInput = (date?: Date) =>
  date ? new Date(date).toISOString().slice(0, 10) : '';

export const parseDateInput = (value?: string) => {
  if (!value) return undefined;
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? undefined : parsed;
};

export const parseCommaSeparated = (value: string) =>
  sanitizeTeamIds(
    value
      .split(',')
      .map((v) => v.trim())
      .filter(Boolean)
  );
