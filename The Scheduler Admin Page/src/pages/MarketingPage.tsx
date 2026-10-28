import { useMemo, useState, type CSSProperties } from 'react';

import { useBusinessContext } from '../hooks/useBusinessContext';
import { useFeatureFlags } from '../hooks/useFeatureFlags';
import { useMarketingCampaigns } from '../hooks/useMarketingCampaigns';
import type {
  CampaignAudienceFilters,
  CampaignAudiencePreview,
  CampaignChannel,
  MarketingCampaign,
} from '../types/models';
import { THEME, SPACING } from './dashboard/DashboardComponents';

const defaultFilters: CampaignAudienceFilters = {
  tags: [],
  lastVisitMode: 'within',
  lastVisitDays: 90,
  upcomingMode: 'any',
  upcomingDays: 30,
};

export function MarketingPage() {
  const { businessId, userId } = useBusinessContext({ minRole: 'admin' });
  const { flags, loading: flagsLoading } = useFeatureFlags(businessId);
  const {
    campaigns,
    templates,
    tags,
    loading,
    saving,
    error,
    rateLimit,
    previewAudience,
    previewCampaignRender,
    saveCampaignDraft,
    deleteCampaign,
    launchCampaign,
    sendCampaignTest,
  } = useMarketingCampaigns(businessId, userId);

  const [campaignName, setCampaignName] = useState('');
  const [description, setDescription] = useState('');
  const [selectedTemplates, setSelectedTemplates] = useState<{ email?: string; sms?: string }>({});
  const [subjectLine, setSubjectLine] = useState('');
  const [channels, setChannels] = useState<CampaignChannel[]>(['email']);
  const [filters, setFilters] = useState<CampaignAudienceFilters>(defaultFilters);
  const [preview, setPreview] = useState<CampaignAudiencePreview | null>(null);
  const [testRecipient, setTestRecipient] = useState('');
  const [testChannel, setTestChannel] = useState<CampaignChannel>('email');
  const [statusMessage, setStatusMessage] = useState<string | null>(null);

  const marketingEnabled = flags.enableMarketing;
  const emailTemplates = useMemo(
    () => templates.filter((template) => template.channel === 'email'),
    [templates],
  );
  const smsTemplates = useMemo(
    () => templates.filter((template) => template.channel === 'sms'),
    [templates],
  );

  const selectedChannels = new Set(channels);

  const handleChannelToggle = (channel: CampaignChannel) => {
    setChannels((prev) => {
      if (prev.includes(channel)) {
        return prev.length === 1 ? prev : prev.filter((ch) => ch !== channel);
      }
      return [...prev, channel];
    });
  };

  const handleTagToggle = (tag: string) => {
    setFilters((prev) => {
      const exists = prev.tags.includes(tag);
      return {
        ...prev,
        tags: exists ? prev.tags.filter((t) => t !== tag) : [...prev.tags, tag],
      };
    });
  };

  const handlePreviewAudience = async () => {
    const result = await previewAudience({ filters, channels });
    setPreview(result);
    setStatusMessage(
      `Audience estimate: ${result.finalSendable} sendable (${result.optedOut} opted-out, ${result.rateLimited} held for rate limit).`,
    );
  };

  const handlePreviewCampaign = async (campaign: MarketingCampaign) => {
    try {
      const result = await previewCampaignRender(campaign, {
        businessName: 'Scheduler',
        firstName: 'Test',
        lastName: 'User',
      });
      const previewSnippet = result.preview?.trim().slice(0, 140);
      const subjectSnippet = result.subject?.trim();
      setStatusMessage(
        previewSnippet ?
          `Rendered ${result.channel?.toUpperCase() ?? campaign.channels[0]?.toUpperCase() ?? 'EMAIL'} preview for ${campaign.name}${subjectSnippet ? ` (${subjectSnippet})` : ''}: ${previewSnippet}${result.preview && result.preview.length > 140 ? '…' : ''}` :
          `Requested preview for ${campaign.name}.`,
      );
    } catch {
      // error handled in hook
    }
  };

  const handleSaveDraft = async () => {
    try {
      const saved = await saveCampaignDraft({
        name: campaignName,
        description,
        channels,
        templateIds: selectedTemplates,
        filters,
        subjectLine,
      });
      setStatusMessage(`Saved draft campaign "${saved.name}" to the shared backend.`);
      setCampaignName('');
      setDescription('');
      setSubjectLine('');
      setSelectedTemplates({});
      setPreview(null);
    } catch {
      // error handled in hook
    }
  };

  const handleLaunchCampaign = async (campaign: MarketingCampaign) => {
    if (!businessId) return;
    try {
      const result = await launchCampaign(campaign);
      if (!result.totalQueuedCount) {
        setStatusMessage(
          `${campaign.name} has no currently eligible recipients for the selected campaign filters and opt-out rules.`,
        );
        return;
      }

      setStatusMessage(
        `Launched ${campaign.name} for ${result.totalQueuedCount} recipients across ${result.channelsQueued
          .map((channel) => channel.toUpperCase())
          .join(', ')}.`,
      );
    } catch {
      // error handled in hook
    }
  };

  const handleDeleteCampaign = async (campaign: MarketingCampaign) => {
    if (!businessId) return;
    if (!confirm(`Delete draft campaign "${campaign.name}"?`)) return;
    try {
      await deleteCampaign(campaign);
      setStatusMessage(`Deleted draft campaign "${campaign.name}".`);
    } catch {
      // error handled in hook
    }
  };

  const handleSendTest = async (campaign: MarketingCampaign) => {
    if (!businessId || !testRecipient) return;
    try {
      const result = await sendCampaignTest(campaign, testRecipient, testChannel);
      const previewSnippet = result.renderedPreview?.trim().slice(0, 120);
      const renderedSubject = result.subject?.trim();
      setStatusMessage(
        `Test ${(result.channel ?? testChannel).toUpperCase()} sent for ${campaign.name} to ${testRecipient}.${renderedSubject ? ` Subject: ${renderedSubject}.` : ''}${result.messageId ? ` Message ID: ${result.messageId}.` : ''}${previewSnippet ? ` Preview: ${previewSnippet}${result.renderedPreview && result.renderedPreview.length > 120 ? '…' : ''}` : ''}`,
      );
      setTestRecipient('');
    } catch {
      // error handled in hook
    }
  };

  const pageContainerStyle: CSSProperties = {
    minHeight: '100vh',
    background: `linear-gradient(180deg, ${THEME.colorBgGradientStart} 0%, ${THEME.colorBgGradientEnd} 100%)`,
    padding: SPACING.lg,
  };

  const panelStyle: CSSProperties = {
    background: THEME.colorBgPanelGradient,
    borderRadius: THEME.radius,
    boxShadow: THEME.shadow,
    border: `1px solid ${THEME.colorBorder}`,
    padding: SPACING.lg,
  };

  if (flagsLoading) {
    return (
      <div style={pageContainerStyle}>
        <div style={panelStyle}>
          <p>Loading feature flags…</p>
        </div>
      </div>
    );
  }

  if (!marketingEnabled) {
    return (
      <div style={pageContainerStyle}>
        <div className="page-header">
          <div>
            <p className="eyebrow">Campaigns</p>
            <h1>Marketing Campaigns</h1>
            <p className="muted">Enable `enableMarketing` to unlock email/SMS blasts.</p>
          </div>
        </div>
        <div style={{ ...panelStyle, borderColor: THEME.colorWarning }}>
          <p className="panel__title">Marketing module disabled</p>
          <p className="muted">
            Toggle `enableMarketing` in feature flags to compose audience-targeted campaigns with rate-limit
            protection.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div style={pageContainerStyle}>
      <div className="page-header">
        <div>
          <p className="eyebrow">Campaigns</p>
          <h1>Marketing Campaigns</h1>
          <p className="muted">
            Build audience filters, reuse templates, and respect opt-outs + courier rate limits for every blast.
          </p>
        </div>
        <div className="header-actions">
          <button className="button button--ghost" onClick={() => void location.reload()}>
            Refresh
          </button>
        </div>
      </div>

      {error && (
        <div style={{ ...panelStyle, borderColor: THEME.colorDanger, marginBottom: SPACING.lg }}>
          <p className="panel__title">Issue loading campaigns</p>
          <p className="muted">{error}</p>
        </div>
      )}

      {statusMessage && (
        <div style={{ ...panelStyle, borderColor: THEME.colorAccent, marginBottom: SPACING.lg }}>
          <p className="panel__title">Status</p>
          <p className="muted">{statusMessage}</p>
        </div>
      )}

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: SPACING.lg, marginBottom: SPACING.lg }}>
        <section style={panelStyle}>
          <h2 style={{ marginTop: 0, marginBottom: SPACING.lg }}>Audience Planner</h2>
          <div className="stack">
            <label className="field">
              <span>Campaign name</span>
              <input
                value={campaignName}
                onChange={(event) => setCampaignName(event.target.value)}
                placeholder="e.g. Spring Reactivation Push"
              />
            </label>
            <label className="field">
              <span>Summary</span>
              <textarea
                className="textarea"
                rows={3}
                value={description}
                onChange={(event) => setDescription(event.target.value)}
                placeholder="Short internal description for the draft campaign."
              />
            </label>
            <div>
              <p className="panel__title">Audience estimate channels</p>
              <div className="chip-row">
                {(['email', 'sms'] as CampaignChannel[]).map((channel) => (
                  <button
                    key={channel}
                    type="button"
                    className={`chip ${selectedChannels.has(channel) ? '' : 'chip--outline'}`}
                    onClick={() => handleChannelToggle(channel)}
                  >
                    {channel === 'email' ? 'Email' : 'SMS'}
                  </button>
                ))}
              </div>
            </div>
            {selectedChannels.has('email') && (
              <>
                <label className="field">
                  <span>Email template</span>
                  <select
                    value={selectedTemplates.email ?? ''}
                    onChange={(event) =>
                      setSelectedTemplates((prev) => ({
                        ...prev,
                        email: event.target.value || undefined,
                      }))
                    }
                  >
                    <option value="">Choose template</option>
                    {emailTemplates.map((template) => (
                      <option value={template.id} key={template.id}>
                        {template.subject ?? template.type}
                      </option>
                    ))}
                  </select>
                </label>
                <label className="field">
                  <span>Email subject override</span>
                  <input
                    value={subjectLine}
                    onChange={(event) => setSubjectLine(event.target.value)}
                    placeholder="Optional subject override"
                  />
                </label>
              </>
            )}
            {selectedChannels.has('sms') && (
              <label className="field">
                <span>SMS template</span>
                <select
                  value={selectedTemplates.sms ?? ''}
                  onChange={(event) =>
                    setSelectedTemplates((prev) => ({
                      ...prev,
                      sms: event.target.value || undefined,
                    }))
                  }
                >
                  <option value="">Choose template</option>
                  {smsTemplates.map((template) => (
                    <option value={template.id} key={template.id}>
                      {template.type}
                    </option>
                  ))}
                </select>
              </label>
            )}
            <p className="muted">
              Saving now creates a real draft campaign document in the shared tenant `campaigns` collection using
              snapshots of the selected templates. Scheduled sends are still not available in the shared contract.
            </p>
          </div>

          <div className="stack">
            <button className="button button--primary" onClick={handleSaveDraft} disabled={saving}>
              {saving ? 'Saving…' : 'Save draft campaign'}
            </button>
            <button className="button" onClick={handlePreviewAudience} disabled={loading}>
              Estimate audience
            </button>
            <label className="field">
              <span>Test recipient</span>
              <input
                type="email"
                placeholder="ops@example.com"
                value={testRecipient}
                onChange={(e) => setTestRecipient(e.target.value)}
              />
            </label>
            <label className="field">
              <span>Test channel</span>
              <select value={testChannel} onChange={(e) => setTestChannel(e.target.value as CampaignChannel)}>
                <option value="email">Email</option>
                <option value="sms">SMS</option>
              </select>
            </label>
            <p className="muted">
              Preview, launch, and test operate on the saved campaigns from the shared `businesses/{businessId}/campaigns`
              collection shown below. Scheduled sends remain unavailable in the current Scheduler marketing contract.
            </p>
          </div>
        </section>

        <section style={panelStyle}>
          <h2 style={{ marginTop: 0, marginBottom: SPACING.lg }}>Contract Status</h2>
          <div className="stack">
            <div
              style={{
                border: `1px solid ${THEME.colorBorder}`,
                borderRadius: THEME.radius,
                padding: SPACING.md,
                background: 'rgba(255, 255, 255, 0.55)',
              }}
            >
              <p className="panel__title">Saved backend content</p>
              <p className="muted" style={{ marginBottom: 0 }}>
                {campaigns.length} saved campaign{campaigns.length === 1 ? '' : 's'} loaded from the shared backend.
                {` ${emailTemplates.length} email template${emailTemplates.length === 1 ? '' : 's'} and ${smsTemplates.length} SMS template${smsTemplates.length === 1 ? '' : 's'} are available for those campaigns.`}
              </p>
            </div>

            <div
              style={{
                border: `1px solid ${THEME.colorAccent}`,
                borderRadius: THEME.radius,
                padding: SPACING.md,
                background: 'rgba(224, 242, 254, 0.75)',
              }}
            >
              <p className="panel__title">Still unavailable here</p>
              <p className="muted" style={{ marginBottom: 0 }}>
                Draft creation is now real. Scheduled sends and queue-at-time delivery still require a dedicated shared
                backend contract and scheduler flow.
              </p>
            </div>

            <div>
              <p className="panel__title">Tags for local audience estimation</p>
              <div className="chip-row chip-row--wrap">
                {tags.map((tag) => (
                  <button
                    key={tag}
                    className={`chip chip--outline ${filters.tags.includes(tag) ? 'chip-selected' : ''}`}
                    type="button"
                    onClick={() => handleTagToggle(tag)}
                  >
                    #{tag}
                  </button>
                ))}
              </div>
            </div>

            <fieldset className="audience-fieldset">
              <legend>Last visit</legend>
              {(['any', 'within', 'overdue'] as CampaignAudienceFilters['lastVisitMode'][]).map((mode) => (
                <label key={mode} className="radio-row">
                  <input
                    type="radio"
                    name="last-visit"
                    checked={filters.lastVisitMode === mode}
                    onChange={() =>
                      setFilters((prev) => ({
                        ...prev,
                        lastVisitMode: mode,
                      }))
                    }
                  />
                  <span>
                    {mode === 'any' && 'Any history'}
                    {mode === 'within' && `Visited within `}
                    {mode === 'overdue' && `Inactive for `}
                    {mode !== 'any' && (
                      <input
                        type="number"
                        min={7}
                        max={365}
                        value={filters.lastVisitDays}
                        onChange={(e) =>
                          setFilters((prev) => ({
                            ...prev,
                            lastVisitDays: Number(e.target.value) || prev.lastVisitDays,
                          }))
                        }
                        className="inline-input"
                      />
                    )}
                    {mode !== 'any' && ' days'}
                  </span>
                </label>
              ))}
            </fieldset>

            <fieldset className="audience-fieldset">
              <legend>Upcoming bookings</legend>
              {(['any', 'within', 'none'] as CampaignAudienceFilters['upcomingMode'][]).map((mode) => (
                <label key={mode} className="radio-row">
                  <input
                    type="radio"
                    name="upcoming"
                    checked={filters.upcomingMode === mode}
                    onChange={() =>
                      setFilters((prev) => ({
                        ...prev,
                        upcomingMode: mode,
                      }))
                    }
                  />
                  <span>
                    {mode === 'any' && 'Any upcoming state'}
                    {mode === 'within' && (
                      <>
                        Upcoming within{' '}
                        <input
                          type="number"
                          min={1}
                          max={120}
                          value={filters.upcomingDays}
                          onChange={(e) =>
                            setFilters((prev) => ({
                              ...prev,
                              upcomingDays: Number(e.target.value) || prev.upcomingDays,
                            }))
                          }
                          className="inline-input"
                        />{' '}
                        days
                      </>
                    )}
                    {mode === 'none' && `No booking in next ${filters.upcomingDays} days`}
                  </span>
                </label>
              ))}
            </fieldset>

            <AudienceSummary
              preview={preview}
              rateLimit={rateLimit.maxRecipientsPerHour}
              channels={channels}
              loading={loading}
            />
          </div>
        </section>
      </div>

      <section style={panelStyle}>
        <div className="panel__subheader">
          <div>
            <h2 style={{ marginTop: 0, marginBottom: SPACING.xs }}>Recent Campaigns</h2>
            <p className="muted">Monitor delivery, opt-outs, and rate-limit holds.</p>
          </div>
          <span className="badge badge--info">
            Limit {rateLimit.maxRecipientsPerHour}/hr · window {rateLimit.windowHours}h
          </span>
        </div>
        <CampaignHistoryTable
          campaigns={campaigns}
          onPreview={handlePreviewCampaign}
          onDelete={handleDeleteCampaign}
          onLaunch={handleLaunchCampaign}
          onTest={handleSendTest}
          saving={saving}
          testChannel={testChannel}
          testRecipient={testRecipient}
        />
      </section>
    </div>
  );
}

type AudienceSummaryProps = {
  preview: CampaignAudiencePreview | null;
  rateLimit: number;
  channels: CampaignChannel[];
  loading: boolean;
};

function AudienceSummary({ preview, rateLimit, channels, loading }: AudienceSummaryProps) {
  return (
    <div
      style={{
        background: THEME.colorBgPanelGradient,
        border: `1px solid ${THEME.colorBorder}`,
        borderRadius: THEME.radius,
        padding: SPACING.lg,
        boxShadow: THEME.shadow,
      }}
    >
      <div>
        <p className="panel__title">Audience preview</p>
        <p className="muted">
          Include tags + recency filters, then preview before sending. Opt-outs are removed per channel automatically.
        </p>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: SPACING.md, margin: `${SPACING.md}px 0` }}>
        <Metric label="Matching contacts" value={preview?.matching ?? '—'} />
        <Metric label="Opt-outs" value={preview?.optedOut ?? '—'} />
        <Metric label="Rate limited" value={preview?.rateLimited ?? `>${rateLimit}`} />
        <Metric label="Sendable" value={preview?.finalSendable ?? '—'} accent />
      </div>
      <p className="muted">
        Channels selected: {channels.length ? channels.map((ch) => ch.toUpperCase()).join(', ') : 'None'}
      </p>
      {loading && <p className="muted">Refreshing campaign + template data…</p>}
    </div>
  );
}

type MetricProps = {
  label: string;
  value: number | string;
  accent?: boolean;
};

function Metric({ label, value, accent }: MetricProps) {
  return (
    <div
      style={{
        textAlign: 'center',
        padding: SPACING.md,
        background: accent ? THEME.colorAccentSubtle : 'rgba(255, 255, 255, 0.5)',
        borderRadius: SPACING.sm,
        border: `1px solid ${accent ? THEME.colorAccent : THEME.colorBorderLight}`,
      }}
    >
      <p style={{ fontSize: 11, fontWeight: 600, color: THEME.colorTextMuted, margin: 0, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
        {label}
      </p>
      <strong style={{ fontSize: 20, fontWeight: 700, color: accent ? THEME.colorAccentStrong : THEME.colorText, margin: `${SPACING.xs}px 0 0`, display: 'block' }}>
        {value}
      </strong>
    </div>
  );
}

function CampaignHistoryTable({
  campaigns,
  onPreview,
  onDelete,
  onLaunch,
  onTest,
  saving,
  testChannel,
  testRecipient,
}: {
  campaigns: MarketingCampaign[];
  onPreview: (campaign: MarketingCampaign) => Promise<void>;
  onDelete: (campaign: MarketingCampaign) => Promise<void>;
  onLaunch: (campaign: MarketingCampaign) => Promise<void>;
  onTest: (campaign: MarketingCampaign) => Promise<void>;
  saving: boolean;
  testChannel: CampaignChannel;
  testRecipient: string;
}) {
  if (!campaigns.length) {
    return (
      <p className="muted">
        No saved campaigns found in the shared backend yet. Create a draft above to enable preview, test, and launch
        against the shared tenant collection.
      </p>
    );
  }
  return (
    <div className="table-wrapper">
      <table className="table">
        <thead>
          <tr>
            <th>Name</th>
            <th>Status</th>
            <th>Channels</th>
            <th>Scheduled/Sent</th>
            <th>Audience</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {campaigns.map((campaign) => (
            <tr key={campaign.id}>
              <td>
                <strong>{campaign.name}</strong>
                <p className="muted truncate">{campaign.description}</p>
              </td>
              <td>
                <span className={`status status--${statusBadge(campaign.status)}`}>{campaign.status}</span>
              </td>
              <td>{campaign.channels.map((ch) => ch.toUpperCase()).join(', ')}</td>
              <td>
                {campaign.sentAt
                  ? new Date(campaign.sentAt).toLocaleString()
                  : campaign.scheduledFor
                    ? new Date(campaign.scheduledFor).toLocaleString()
                    : 'Draft'}
              </td>
              <td>
                {campaign.audienceStats ? (
                  <>
                    <strong>{campaign.audienceStats.finalSendable}</strong> sendable
                    <p className="muted">
                      {campaign.audienceStats.optedOut} opt-outs · {campaign.audienceStats.rateLimited} held
                    </p>
                  </>
                ) : (
                  <span className="muted">Pending preview</span>
                )}
              </td>
              <td>
                <div className="chip-row chip-row--compact">
                  <button
                    className="chip chip--outline"
                    type="button"
                    onClick={() => void onPreview(campaign)}
                    disabled={saving}
                  >
                    Preview
                  </button>
                  <button
                    className="chip chip--outline"
                    type="button"
                    onClick={() => void onTest(campaign)}
                    disabled={saving || !testRecipient}
                    title={!testRecipient ? 'Enter a test recipient above first.' : undefined}
                  >
                    Test {testChannel.toUpperCase()}
                  </button>
                  <button className="chip" type="button" onClick={() => void onLaunch(campaign)} disabled={saving}>
                    Launch
                  </button>
                  {campaign.status === 'draft' && (
                    <button
                      className="chip chip--outline"
                      type="button"
                      onClick={() => void onDelete(campaign)}
                      disabled={saving}
                    >
                      Delete
                    </button>
                  )}
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function statusBadge(status: MarketingCampaign['status']): 'sent' | 'failed' | 'pending' {
  return status === 'sent' ? 'sent' : status === 'failed' ? 'failed' : 'pending';
}
