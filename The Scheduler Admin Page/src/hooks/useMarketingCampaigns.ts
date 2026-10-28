import { useCallback, useEffect, useMemo, useState } from 'react';

import {
  deleteMarketingCampaign,
  type CampaignLaunchResponse,
  type CampaignTemplateSnapshot,
  type CampaignTestResponse,
  launchCampaignNow,
  listMarketingCampaigns,
  marketingAudienceTags,
  marketingRateLimitDefaults,
  previewCampaignRender as previewCampaignRenderRequest,
  saveMarketingCampaignDraft,
  sendCampaignTest as sendCampaignTestRequest,
  type SaveMarketingCampaignDraftInput,
  type CampaignPreviewRenderResponse,
} from '../data/campaigns';
import { listClients } from '../data/clients';
import { listTemplates } from '../data/templates';
import type {
  CampaignAudienceFilters,
  CampaignAudiencePreview,
  CampaignChannel,
  Client,
  MarketingCampaign,
  MarketingRateLimitWindow,
  MessageTemplate,
} from '../types/models';

type CampaignPreviewInput = {
  filters: CampaignAudienceFilters;
  channels: CampaignChannel[];
};

type UseMarketingCampaignsResult = {
  campaigns: MarketingCampaign[];
  templates: MessageTemplate[];
  tags: string[];
  clients: Client[];
  loading: boolean;
  saving: boolean;
  error: string | null;
  rateLimit: MarketingRateLimitWindow;
  refresh: () => Promise<void>;
  previewAudience: (input: CampaignPreviewInput) => Promise<CampaignAudiencePreview>;
  previewCampaignRender: (
    campaign: MarketingCampaign,
    sampleData?: Record<string, string>,
  ) => Promise<CampaignPreviewRenderResponse>;
  saveCampaignDraft: (input: SaveMarketingCampaignDraftInput) => Promise<MarketingCampaign>;
  deleteCampaign: (campaign: MarketingCampaign) => Promise<void>;
  launchCampaign: (campaign: MarketingCampaign) => Promise<CampaignLaunchSummary>;
  sendCampaignTest: (
    campaign: MarketingCampaign,
    recipient: string,
    channel: CampaignChannel,
  ) => Promise<CampaignTestResponse>;
};

export type CampaignLaunchSummary = {
  totalQueuedCount: number;
  channelsAttempted: CampaignChannel[];
  channelsQueued: CampaignChannel[];
  responses: CampaignLaunchResponse[];
};

const DAY_MS = 24 * 60 * 60 * 1000;

function normalizeClients(clients: Client[]): Client[] {
  return clients;
}

function deriveTags(clients: Client[]): string[] {
  const set = new Set<string>();
  clients.forEach((client) => {
    client.tags?.forEach((tag) => set.add(tag));
  });
  const derived = Array.from(set);
  return derived.length ? derived : marketingAudienceTags;
}

function computeLocalPreview(
  clients: Client[],
  input: CampaignPreviewInput,
  rateLimit: MarketingRateLimitWindow,
): CampaignAudiencePreview {
  const now = Date.now();

  const filtered = clients.filter((client) => {
    if (input.filters.tags.length) {
      const hasTag = client.tags?.some((tag) => input.filters.tags.includes(tag));
      if (!hasTag) return false;
    }

    if (input.filters.lastVisitMode !== 'any') {
      const lastVisit = client.lastVisitAt ? Date.parse(client.lastVisitAt) : null;
      if (!lastVisit) {
        if (input.filters.lastVisitMode === 'overdue') {
          // keep clients with no history when targeting overdue
        } else {
          return false;
        }
      } else {
        const delta = now - lastVisit;
        if (input.filters.lastVisitMode === 'within' && delta > input.filters.lastVisitDays * DAY_MS) {
          return false;
        }
        if (input.filters.lastVisitMode === 'overdue' && delta < input.filters.lastVisitDays * DAY_MS) {
          return false;
        }
      }
    }

    if (input.filters.upcomingMode !== 'any') {
      const nextAppt = client.nextAppointmentAt ? Date.parse(client.nextAppointmentAt) : null;
      if (input.filters.upcomingMode === 'within') {
        if (!nextAppt) return false;
        if (nextAppt - now > input.filters.upcomingDays * DAY_MS) {
          return false;
        }
      } else if (input.filters.upcomingMode === 'none') {
        if (nextAppt && nextAppt - now <= input.filters.upcomingDays * DAY_MS) {
          return false;
        }
      }
    }

    return true;
  });

  const optedOut = filtered.filter((client) =>
    input.channels.some((channel) => client.marketingOptOutChannels?.includes(channel)),
  ).length;

  const matching = filtered.length;
  const eligible = Math.max(0, matching - optedOut);
  const rateLimited = Math.max(0, eligible - rateLimit.maxRecipientsPerHour);

  return {
    matching,
    optedOut,
    rateLimited,
    finalSendable: Math.max(0, eligible - rateLimited),
  };
}

export function useMarketingCampaigns(businessId?: string, userId?: string): UseMarketingCampaignsResult {
  const [campaigns, setCampaigns] = useState<MarketingCampaign[]>([]);
  const [templates, setTemplates] = useState<MessageTemplate[]>([]);
  const [clients, setClients] = useState<Client[]>([]);
  const [tags, setTags] = useState<string[]>([]);
  const [rateLimit, setRateLimit] = useState<MarketingRateLimitWindow>(marketingRateLimitDefaults);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    if (!businessId) {
      setCampaigns([]);
      setClients([]);
      setTemplates([]);
      setTags([]);
      setRateLimit(marketingRateLimitDefaults);
      setError(null);
      return;
    }

    setLoading(true);
    setError(null);
    try {
      const [campaignRows, clientRows, templateRows] = await Promise.all([
        listMarketingCampaigns(businessId),
        listClients(businessId, userId),
        listTemplates(businessId, userId),
      ]);

      setCampaigns(campaignRows);
      const hydratedClients = normalizeClients(clientRows);
      setClients(hydratedClients);
      setTags(deriveTags(hydratedClients));
      setTemplates(templateRows);
      setRateLimit(marketingRateLimitDefaults);
    } catch (err) {
      console.error('Failed to load marketing campaigns', err);
      setError('Failed to load marketing campaigns.');
      setCampaigns([]);
      setClients([]);
      setTags([]);
      setTemplates([]);
      setRateLimit(marketingRateLimitDefaults);
    } finally {
      setLoading(false);
    }
  }, [businessId, userId]);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  const previewAudience = useCallback(
    async (input: CampaignPreviewInput) => {
      void businessId;
      return computeLocalPreview(clients, input, rateLimit);
    },
    [businessId, clients, rateLimit],
  );

  const previewCampaignRender = useCallback(
    async (campaign: MarketingCampaign, sampleData?: Record<string, string>) => {
      if (!businessId) {
        throw new Error('Business context is required to preview a campaign.');
      }
      return previewCampaignRenderRequest(
        businessId,
        campaign.id,
        sampleData,
        campaign.channels[0] ?? 'email',
      );
    },
    [businessId],
  );

  const saveCampaignDraft = useCallback(
    async (input: SaveMarketingCampaignDraftInput) => {
      if (!businessId) {
        throw new Error('Business context is required to save a campaign draft.');
      }

      setSaving(true);
      setError(null);
      try {
        const emailTemplate = input.templateIds.email ?
          templates.find((template) => template.id === input.templateIds.email && template.channel === 'email') :
          undefined;
        const smsTemplate = input.templateIds.sms ?
          templates.find((template) => template.id === input.templateIds.sms && template.channel === 'sms') :
          undefined;

        const toSnapshot = (template?: MessageTemplate): CampaignTemplateSnapshot | undefined =>
          template ?
            {
              id: template.id,
              body: template.body,
              subject: template.subject,
            } :
            undefined;

        const saved = await saveMarketingCampaignDraft(businessId, {
          ...input,
          emailTemplate: toSnapshot(emailTemplate),
          smsTemplate: toSnapshot(smsTemplate),
        });
        await refresh();
        return saved;
      } catch (err) {
        console.error('Failed to save marketing campaign draft', err);
        setError(err instanceof Error ? err.message : 'Failed to save marketing campaign draft.');
        throw err;
      } finally {
        setSaving(false);
      }
    },
    [businessId, refresh, templates],
  );

  const deleteCampaign = useCallback(
    async (campaign: MarketingCampaign) => {
      if (!businessId) {
        throw new Error('Business context is required to delete a campaign.');
      }
      setSaving(true);
      setError(null);
      try {
        await deleteMarketingCampaign(businessId, campaign.id);
        await refresh();
      } catch (err) {
        console.error('Failed to delete marketing campaign', err);
        setError(err instanceof Error ? err.message : 'Failed to delete marketing campaign.');
        throw err;
      } finally {
        setSaving(false);
      }
    },
    [businessId, refresh],
  );

  const launchCampaign = useCallback(
    async (campaign: MarketingCampaign) => {
      if (!businessId) {
        throw new Error('Business context is required to launch a campaign.');
      }
      setSaving(true);
      setError(null);
      try {
        const recipientIdsByChannel = resolveRecipientIds(campaign, clients, rateLimit);
        const responses: CampaignLaunchResponse[] = [];
        const channelsQueued: CampaignChannel[] = [];
        let totalQueuedCount = 0;
        for (const channel of campaign.channels) {
          const recipientIds = recipientIdsByChannel[channel] ?? [];
          if (!recipientIds.length) continue;
          const response = await launchCampaignNow(businessId, {
            campaignId: campaign.id,
            recipientIds,
            channel,
          });
          responses.push(response);
          channelsQueued.push(channel);
          totalQueuedCount += response.queuedCount ?? recipientIds.length;
        }
        await refresh();
        return {
          totalQueuedCount,
          channelsAttempted: [...campaign.channels],
          channelsQueued,
          responses,
        };
      } catch (err) {
        console.error('Failed to launch campaign now', err);
        setError('Failed to launch campaign.');
        throw err;
      } finally {
        setSaving(false);
      }
    },
    [businessId, clients, rateLimit, refresh],
  );

  const sendCampaignTest = useCallback(
    async (campaign: MarketingCampaign, recipient: string, channel: CampaignChannel) => {
      if (!businessId) {
        throw new Error('Business context is required to send a campaign test.');
      }
      setSaving(true);
      setError(null);
      try {
        return await sendCampaignTestRequest(businessId, {
          campaignId: campaign.id,
          recipient,
          channel,
        });
      } catch (err) {
        console.error('Failed to send campaign test', err);
        setError('Failed to send campaign test.');
        throw err;
      } finally {
        setSaving(false);
      }
    },
    [businessId],
  );

  return useMemo(
    () => ({
      campaigns,
      templates,
      clients,
      tags,
      loading,
      saving,
      error,
      rateLimit,
      refresh,
      previewAudience,
      previewCampaignRender,
      saveCampaignDraft,
      deleteCampaign,
      launchCampaign,
      sendCampaignTest,
    }),
    [
      campaigns,
      clients,
      deleteCampaign,
      error,
      loading,
      previewAudience,
      previewCampaignRender,
      saveCampaignDraft,
      launchCampaign,
      sendCampaignTest,
      rateLimit,
      refresh,
      saving,
      tags,
      templates,
    ],
  );
}

function resolveRecipientIds(
  campaign: MarketingCampaign,
  clients: Client[],
  rateLimit: MarketingRateLimitWindow,
): Record<CampaignChannel, string[]> {
  const result: Record<CampaignChannel, string[]> = { email: [], sms: [] };
  const eligibleClients = clients.filter((client) => matchesCampaignFilters(client, campaign.filters));

  (['email', 'sms'] as CampaignChannel[]).forEach((channel) => {
    if (!campaign.channels.includes(channel)) return;
    result[channel] = eligibleClients
      .filter((client) => !client.marketingOptOutChannels?.includes(channel))
      .map((client) => client.id)
      .slice(0, rateLimit.maxRecipientsPerHour);
  });

  return result;
}

function matchesCampaignFilters(client: Client, filters: CampaignAudienceFilters): boolean {
  const now = Date.now();

  if (filters.tags.length) {
    const hasTag = client.tags?.some((tag) => filters.tags.includes(tag));
    if (!hasTag) return false;
  }

  if (filters.lastVisitMode !== 'any') {
    const lastVisit = client.lastVisitAt ? Date.parse(client.lastVisitAt) : null;
    if (!lastVisit) {
      if (filters.lastVisitMode !== 'overdue') {
        return false;
      }
    } else {
      const delta = now - lastVisit;
      if (filters.lastVisitMode === 'within' && delta > filters.lastVisitDays * DAY_MS) {
        return false;
      }
      if (filters.lastVisitMode === 'overdue' && delta < filters.lastVisitDays * DAY_MS) {
        return false;
      }
    }
  }

  if (filters.upcomingMode !== 'any') {
    const nextAppt = client.nextAppointmentAt ? Date.parse(client.nextAppointmentAt) : null;
    if (filters.upcomingMode === 'within') {
      if (!nextAppt || nextAppt - now > filters.upcomingDays * DAY_MS) {
        return false;
      }
    } else if (filters.upcomingMode === 'none') {
      if (nextAppt && nextAppt - now <= filters.upcomingDays * DAY_MS) {
        return false;
      }
    }
  }

  return true;
}
