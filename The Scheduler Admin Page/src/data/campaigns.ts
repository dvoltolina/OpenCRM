import { addDoc, deleteDoc, doc } from 'firebase/firestore';

import { fetchCollection, postTenantEndpoint, scopedCollection } from './firestoreBase';
import { assertDemoMutationAllowed } from '../config/demo';
import { getDb } from '../lib/firebase';
import type {
  CampaignAudienceFilters,
  CampaignChannel,
  Client,
  MarketingCampaign,
  MarketingRateLimitWindow,
  MessageTemplate,
} from '../types/models';

export const marketingAudienceTags = [
  'vip',
  'membership',
  'orthodontics',
  'telehealth',
  'inactive',
  'new-client',
];

export const marketingRateLimitDefaults: MarketingRateLimitWindow = {
  maxRecipientsPerHour: 500,
  windowHours: 1,
};

// Note: Seed data should only be used for UI development/preview.
// In production, businessId must come from authenticated context.
function buildMarketingSeedData(businessId: string) {
  const marketingClientsSeed: Client[] = [
  {
    id: 'client-alex',
    businessId,
    name: 'Alex Morgan',
    email: 'alex@example.com',
    phone: '+1 202-555-0189',
    tags: ['vip', 'telehealth'],
    lastVisitAt: '2025-11-05T15:00:00Z',
    nextAppointmentAt: '2025-12-02T19:00:00Z',
    marketingOptOutChannels: [],
  },
  {
    id: 'client-bree',
    businessId,
    name: 'Bree Carter',
    email: 'bree@example.com',
    phone: '+1 415-555-0189',
    tags: ['orthodontics', 'inactive'],
    lastVisitAt: '2025-05-22T18:00:00Z',
    marketingOptOutChannels: ['sms'],
  },
  {
    id: 'client-carlos',
    businessId,
    name: 'Carlos Díaz',
    email: 'carlos@example.com',
    phone: '+1 312-555-7788',
    tags: ['membership'],
    lastVisitAt: '2025-10-01T17:00:00Z',
    nextAppointmentAt: '2025-11-28T17:30:00Z',
    marketingOptOutChannels: [],
  },
  {
    id: 'client-dina',
    businessId,
    name: 'Dina Patel',
    email: 'dina@example.com',
    phone: '+1 206-555-3377',
    tags: ['inactive'],
    lastVisitAt: '2024-12-14T16:00:00Z',
    marketingOptOutChannels: ['email', 'sms'],
  },
  {
    id: 'client-eli',
    businessId,
    name: 'Eli Johnson',
    email: 'eli@example.com',
    phone: '+1 503-555-6222',
    tags: ['new-client', 'telehealth'],
    lastVisitAt: '2025-11-15T20:00:00Z',
    nextAppointmentAt: '2025-11-30T20:00:00Z',
    marketingOptOutChannels: [],
  },
  {
    id: 'client-fatima',
    businessId,
    name: 'Fatima Noor',
    email: 'fatima@example.com',
    phone: '+1 702-555-5522',
    tags: ['membership', 'vip'],
    lastVisitAt: '2025-10-20T16:30:00Z',
    marketingOptOutChannels: ['email'],
  },
];

  const marketingCampaignSeed: MarketingCampaign[] = [
  {
    id: 'cmp-fall-welcome',
    businessId,
    name: 'Fall Reactivation Series',
    description: 'Win back inactive clients before holiday rush.',
    channels: ['email', 'sms'],
    templateIds: { email: 'tmpl-fall-email', sms: 'tmpl-fall-sms' },
    subjectLine: 'We saved a spot for you',
    smsBodyPreview: 'Hi {{firstName}}, book now & save 20% on your next visit.',
    filters: {
      tags: ['inactive'],
      lastVisitMode: 'overdue',
      lastVisitDays: 120,
      upcomingMode: 'none',
      upcomingDays: 30,
    },
    status: 'sent',
    createdAt: '2025-09-28T15:00:00Z',
    sentAt: '2025-09-29T18:00:00Z',
    audienceStats: {
      matching: 820,
      optedOut: 42,
      rateLimited: 20,
      finalSendable: 758,
    },
  },
  {
    id: 'cmp-holiday-vip',
    businessId,
    name: 'VIP Early Access',
    description: 'Launch concierge scheduling for VIP members.',
    channels: ['email'],
    templateIds: { email: 'tmpl-vip-holiday' },
    subjectLine: 'VIP: reserve your preferred holiday slots',
    filters: {
      tags: ['vip', 'membership'],
      lastVisitMode: 'within',
      lastVisitDays: 90,
      upcomingMode: 'any',
      upcomingDays: 30,
    },
    status: 'scheduled',
    createdAt: '2025-11-20T17:00:00Z',
    scheduledFor: '2025-11-27T14:00:00Z',
    audienceStats: {
      matching: 210,
      optedOut: 8,
      rateLimited: 0,
      finalSendable: 202,
    },
  },
  {
    id: 'cmp-year-end',
    businessId,
    name: 'Year-End Benefit Reminder',
    description: 'Remind clients to use insurance benefits.',
    channels: ['sms'],
    templateIds: { sms: 'tmpl-benefits-sms' },
    smsBodyPreview: 'Use remaining benefits before Dec 31. Reply to book.',
    filters: {
      tags: ['new-client', 'orthodontics'],
      lastVisitMode: 'any',
      lastVisitDays: 30,
      upcomingMode: 'within',
      upcomingDays: 14,
    },
    status: 'draft',
    createdAt: '2025-11-22T12:00:00Z',
  },
];

  return { marketingClientsSeed, marketingCampaignSeed };
}

// Export seed data for backward compatibility - requires businessId parameter
export function getMarketingSeeds(businessId: string) {
  if (!businessId) {
    throw new Error('businessId is required to generate seed data');
  }
  return buildMarketingSeedData(businessId);
}

// ==================== UI Preview Stub Exports (Development Only) ====================
// WARNING: These exports contain FICTIONAL demo data for UI preview rendering.
// They do NOT access Firestore and contain NO real PHI.
// Production code MUST use listMarketingCampaigns() which enforces tenant isolation.
const _stubData = buildMarketingSeedData('stub-business-id');
export const marketingCampaignSeed = _stubData.marketingCampaignSeed;
export const marketingClientsSeed = _stubData.marketingClientsSeed;

type MarketingCampaignRecord = Partial<MarketingCampaign> & {
  id: string;
  createdAt?: unknown;
  updatedAt?: unknown;
  scheduledFor?: unknown;
  sentAt?: unknown;
};

export type CampaignTemplateSnapshot = Pick<MessageTemplate, 'id' | 'body' | 'subject'>;

export type SaveMarketingCampaignDraftInput = {
  name: string;
  description?: string;
  channels: CampaignChannel[];
  templateIds: {
    email?: string;
    sms?: string;
  };
  filters: CampaignAudienceFilters;
  subjectLine?: string;
  emailTemplate?: CampaignTemplateSnapshot;
  smsTemplate?: CampaignTemplateSnapshot;
};

function normalizeTimestamp(value: unknown, fallback: string): string {
  if (typeof value === 'string') return value;
  if (value instanceof Date) return value.toISOString();
  if (
    value &&
    typeof value === 'object' &&
    'toDate' in value &&
    typeof (value as { toDate?: unknown }).toDate === 'function'
  ) {
    return (value as { toDate: () => Date }).toDate().toISOString();
  }
  return fallback;
}

function normalizeMarketingCampaign(record: MarketingCampaignRecord): MarketingCampaign {
  const nowIso = new Date().toISOString();
  const emailSubjectTemplate = typeof record.emailSubjectTemplate === 'string' ? record.emailSubjectTemplate : undefined;
  const emailBodyTemplate = typeof record.emailBodyTemplate === 'string' ? record.emailBodyTemplate : undefined;
  const smsBodyTemplate = typeof record.smsBodyTemplate === 'string' ? record.smsBodyTemplate : undefined;

  return {
    id: record.id,
    businessId: record.businessId ?? '',
    name: record.name ?? 'Untitled Campaign',
    description: record.description,
    channels: Array.isArray(record.channels) ? record.channels : ['email'],
    templateIds: record.templateIds ?? {},
    subjectLine: typeof record.subjectLine === 'string' ? record.subjectLine : emailSubjectTemplate,
    smsBodyPreview:
      typeof record.smsBodyPreview === 'string' ?
        record.smsBodyPreview :
        smsBodyTemplate?.slice(0, 160),
    template: typeof record.template === 'string' ? record.template : undefined,
    emailSubjectTemplate,
    emailBodyTemplate,
    smsBodyTemplate,
    filters: record.filters ?? {
      tags: [],
      lastVisitMode: 'any',
      lastVisitDays: 30,
      upcomingMode: 'any',
      upcomingDays: 30,
    },
    status: record.status ?? 'draft',
    createdAt: normalizeTimestamp(record.createdAt, nowIso),
    updatedAt: record.updatedAt ? normalizeTimestamp(record.updatedAt, nowIso) : undefined,
    scheduledFor: record.scheduledFor ? normalizeTimestamp(record.scheduledFor, nowIso) : undefined,
    sentAt: record.sentAt ? normalizeTimestamp(record.sentAt, nowIso) : undefined,
    audienceStats: record.audienceStats,
  };
}

export async function listMarketingCampaigns(businessId: string): Promise<MarketingCampaign[]> {
  if (!businessId) {
    throw new Error('businessId is required to list marketing campaigns');
  }
  try {
    const scoped = scopedCollection<MarketingCampaignRecord>(businessId, ['campaigns']);
    const rows = await fetchCollection(scoped);
    return rows
      .map(normalizeMarketingCampaign)
      .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
  } catch (error) {
    console.warn('Failed to load marketing campaigns', error);
    throw error;
  }
}

export async function saveMarketingCampaignDraft(
  businessId: string,
  input: SaveMarketingCampaignDraftInput,
): Promise<MarketingCampaign> {
  assertDemoMutationAllowed('save marketing campaign draft');
  if (!businessId) {
    throw new Error('businessId is required to save a marketing campaign draft');
  }
  if (!input.name.trim()) {
    throw new Error('Campaign name is required.');
  }
  if (!input.channels.length) {
    throw new Error('Select at least one channel.');
  }

  const emailBodyTemplate = input.channels.includes('email') ? input.emailTemplate?.body?.trim() : undefined;
  const emailSubjectTemplate = input.channels.includes('email') ?
    (input.subjectLine?.trim() || input.emailTemplate?.subject?.trim() || undefined) :
    undefined;
  const smsBodyTemplate = input.channels.includes('sms') ? input.smsTemplate?.body?.trim() : undefined;

  if (input.channels.includes('email') && !emailBodyTemplate) {
    throw new Error('Select an email template before saving an email campaign.');
  }
  if (input.channels.includes('sms') && !smsBodyTemplate) {
    throw new Error('Select an SMS template before saving an SMS campaign.');
  }

  const nowIso = new Date().toISOString();
  const payload: Omit<MarketingCampaignRecord, 'id'> = {
    businessId,
    name: input.name.trim(),
    description: input.description?.trim() || undefined,
    channels: [...input.channels],
    templateIds: {
      email: input.templateIds.email,
      sms: input.templateIds.sms,
    },
    subjectLine: emailSubjectTemplate,
    smsBodyPreview: smsBodyTemplate?.slice(0, 160),
    template: emailBodyTemplate ?? smsBodyTemplate ?? '',
    emailSubjectTemplate,
    emailBodyTemplate,
    smsBodyTemplate,
    filters: input.filters,
    status: 'draft',
    createdAt: nowIso,
    updatedAt: nowIso,
  };

  const db = getDb();
  const docRef = await addDoc(scopedCollection<MarketingCampaignRecord>(businessId, ['campaigns'], db).ref, payload);
  return normalizeMarketingCampaign({ id: docRef.id, ...payload });
}

export async function deleteMarketingCampaign(businessId: string, campaignId: string): Promise<void> {
  assertDemoMutationAllowed('delete marketing campaign');
  if (!businessId) {
    throw new Error('businessId is required to delete a marketing campaign');
  }
  if (!campaignId) {
    throw new Error('campaignId is required to delete a marketing campaign');
  }
  await deleteDoc(doc(getDb(), 'businesses', businessId, 'campaigns', campaignId));
}

export async function previewCampaignRender(
  businessId: string,
  campaignId: string,
  sampleData?: Record<string, string>,
  channel?: CampaignChannel,
): Promise<CampaignPreviewRenderResponse> {
  if (!businessId) {
    throw new Error('businessId is required to preview a campaign');
  }
  if (!campaignId) {
    throw new Error('campaignId is required to preview a campaign');
  }

  return postTenantEndpoint('/previewCampaign', businessId, {
    campaignId,
    sampleData,
    channel,
  });
}

export type CampaignLaunchInput = {
  campaignId: string;
  recipientIds: string[];
  channel: CampaignChannel;
};

export type CampaignLaunchResponse = {
  success?: boolean;
  queuedCount?: number;
  error?: string;
};

export async function launchCampaignNow(
  businessId: string,
  input: CampaignLaunchInput,
): Promise<CampaignLaunchResponse> {
  assertDemoMutationAllowed('launch campaign');
  if (!businessId) throw new Error('businessId is required to launch a campaign');
  return postTenantEndpoint('/launchCampaign', businessId, input);
}

export async function scheduleCampaign(
  businessId: string,
  input: CampaignLaunchInput,
): Promise<void> {
  assertDemoMutationAllowed('schedule campaign');
  if (!businessId) throw new Error('businessId is required to schedule a campaign');
  void input;
  throw new Error(
    'Scheduled marketing sends are not supported by the current Scheduler marketing contract. Launch saved campaigns immediately instead.',
  );
}

export type CampaignTestResponse = {
  success?: boolean;
  messageId?: string;
  renderedPreview?: string;
  error?: string;
};

export async function sendCampaignTest(
  businessId: string,
  payload: {
    campaignId: string;
    channel: CampaignChannel;
    recipient: string;
  },
): Promise<CampaignTestResponse> {
  assertDemoMutationAllowed('send campaign test');
  if (!businessId) throw new Error('businessId is required to send a campaign test');
  return postTenantEndpoint('/testCampaign', businessId, payload);
}

export type CampaignPreviewRenderResponse = {
  success?: boolean;
  preview?: string;
  subject?: string;
  channel?: CampaignChannel;
  variables?: string[];
  error?: string;
};
