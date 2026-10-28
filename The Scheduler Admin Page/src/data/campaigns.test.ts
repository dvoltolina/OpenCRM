import { beforeEach, describe, expect, it, vi } from 'vitest';

import { addDoc, deleteDoc, doc } from 'firebase/firestore';

import {
  deleteMarketingCampaign,
  launchCampaignNow,
  previewCampaignRender,
  saveMarketingCampaignDraft,
  sendCampaignTest,
} from './campaigns';

const mockPostTenantEndpoint = vi.hoisted(() => vi.fn());
const mockScopedCollection = vi.hoisted(() => vi.fn());

vi.mock('../config/demo', () => ({
  assertDemoMutationAllowed: vi.fn(),
}));

vi.mock('../lib/firebase', () => ({
  getDb: vi.fn(() => ({ __db: true })),
}));

vi.mock('firebase/firestore', () => ({
  addDoc: vi.fn(),
  deleteDoc: vi.fn(),
  doc: vi.fn(),
}));
const mockAddDoc = vi.mocked(addDoc);
const mockDeleteDoc = vi.mocked(deleteDoc);
const mockDoc = vi.mocked(doc);

vi.mock('./firestoreBase', () => ({
  fetchCollection: vi.fn(),
  postTenantEndpoint: mockPostTenantEndpoint,
  scopedCollection: mockScopedCollection,
}));

describe('campaign transport alignment', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockScopedCollection.mockReturnValue({
      path: 'businesses/biz_123/campaigns',
      ref: 'campaigns-ref',
    } as any);
  });

  it('previews campaigns through the shared marketing HTTP endpoint', async () => {
    mockPostTenantEndpoint.mockResolvedValue({ success: true, preview: 'Preview' });

    await previewCampaignRender('biz_123', 'campaign_123', { firstName: 'Test' }, 'sms');

    expect(mockPostTenantEndpoint).toHaveBeenCalledWith('/previewCampaign', 'biz_123', {
      campaignId: 'campaign_123',
      sampleData: { firstName: 'Test' },
      channel: 'sms',
    });
  });

  it('saves draft campaigns into the shared campaigns collection with template snapshots', async () => {
    mockAddDoc.mockResolvedValue({ id: 'campaign_123' } as any);

    const saved = await saveMarketingCampaignDraft('biz_123', {
      name: 'Spring Reactivation',
      description: 'Bring inactive clients back',
      channels: ['email', 'sms'],
      templateIds: {
        email: 'tmpl_email',
        sms: 'tmpl_sms',
      },
      filters: {
        tags: ['inactive'],
        lastVisitMode: 'overdue',
        lastVisitDays: 120,
        upcomingMode: 'none',
        upcomingDays: 30,
      },
      subjectLine: 'Come back this spring',
      emailTemplate: {
        id: 'tmpl_email',
        subject: 'Fallback subject',
        body: 'Hello {{firstName}}',
      },
      smsTemplate: {
        id: 'tmpl_sms',
        body: 'Reply YES to book.',
      },
    });

    expect(mockAddDoc).toHaveBeenCalledWith(
      'campaigns-ref',
      expect.objectContaining({
        businessId: 'biz_123',
        name: 'Spring Reactivation',
        channels: ['email', 'sms'],
        templateIds: {
          email: 'tmpl_email',
          sms: 'tmpl_sms',
        },
        subjectLine: 'Come back this spring',
        template: 'Hello {{firstName}}',
        emailSubjectTemplate: 'Come back this spring',
        emailBodyTemplate: 'Hello {{firstName}}',
        smsBodyTemplate: 'Reply YES to book.',
        smsBodyPreview: 'Reply YES to book.',
        status: 'draft',
      }),
    );
    expect(saved).toEqual(
      expect.objectContaining({
        id: 'campaign_123',
        subjectLine: 'Come back this spring',
        emailBodyTemplate: 'Hello {{firstName}}',
        smsBodyTemplate: 'Reply YES to book.',
      }),
    );
  });

  it('deletes draft campaigns from the shared campaigns collection', async () => {
    mockDoc.mockReturnValue('campaign-doc-ref' as any);

    await deleteMarketingCampaign('biz_123', 'campaign_123');

    expect(mockDoc).toHaveBeenCalledWith({ __db: true }, 'businesses', 'biz_123', 'campaigns', 'campaign_123');
    expect(mockDeleteDoc).toHaveBeenCalledWith('campaign-doc-ref');
  });

  it('launches saved campaigns through the shared marketing HTTP endpoint', async () => {
    mockPostTenantEndpoint.mockResolvedValue({ success: true, queuedCount: 12 });

    const result = await launchCampaignNow('biz_123', {
      campaignId: 'campaign_123',
      recipientIds: ['client_1', 'client_2'],
      channel: 'email',
    });

    expect(mockPostTenantEndpoint).toHaveBeenCalledWith('/launchCampaign', 'biz_123', {
      campaignId: 'campaign_123',
      recipientIds: ['client_1', 'client_2'],
      channel: 'email',
    });
    expect(result).toEqual(expect.objectContaining({ queuedCount: 12 }));
  });

  it('sends campaign tests through the shared marketing HTTP endpoint', async () => {
    mockPostTenantEndpoint.mockResolvedValue({ success: true });

    await sendCampaignTest('biz_123', {
      campaignId: 'campaign_123',
      recipient: 'ops@example.com',
      channel: 'email',
    });

    expect(mockPostTenantEndpoint).toHaveBeenCalledWith('/testCampaign', 'biz_123', {
      campaignId: 'campaign_123',
      recipient: 'ops@example.com',
      channel: 'email',
    });
  });
});
