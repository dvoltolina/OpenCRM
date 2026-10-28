import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { describe, expect, it, vi, beforeEach } from 'vitest';
import { EmailComposer } from '../EmailComposer';
import type { EmailAccount } from '../../../types/email-integration';

const account: EmailAccount = {
  id: 'acc-1',
  businessId: 'biz-1',
  userId: 'user-1',
  provider: 'gmail',
  email: 'user@example.com',
  displayName: 'User',
  accessToken: 'enc',
  refreshToken: 'enc',
  tokenExpiresAt: new Date(),
  syncStatus: 'synced',
  lastSyncAt: new Date(),
  syncEnabled: true,
  syncInbound: true,
  syncOutbound: true,
  autoAssociate: true,
  createdAt: new Date(),
};

const sendEmailMock = vi.fn().mockResolvedValue({ success: true });
const sendTemplatedEmailMock = vi.fn().mockResolvedValue({ success: true });

const integrationMock = {
  accounts: [account],
  templates: [],
  selectedAccountId: account.id,
  setSelectedAccountId: vi.fn(),
  sendEmail: sendEmailMock,
  sendTemplatedEmail: sendTemplatedEmailMock,
  isSending: false,
  accountsLoading: false,
  templatesLoading: false,
};

vi.mock('../../../config/features', () => ({
  getFeatureFlags: () => ({ enableEmailIntegration: true }),
}));

vi.mock('../../../hooks/useEmailIntegration', () => ({
  useEmailIntegration: () => integrationMock,
}));

describe('EmailComposer', () => {
  beforeEach(() => {
    sendEmailMock.mockClear();
    sendTemplatedEmailMock.mockClear();
  });

  it('calls onSend with parsed recipients', async () => {
    const onSend = vi.fn();
    render(<EmailComposer defaultTo="lead@example.com" onSend={onSend} />);

    fireEvent.change(screen.getByPlaceholderText('Subject'), { target: { value: 'Hello' } });
    fireEvent.change(screen.getByPlaceholderText('Write your email...'), {
      target: { value: 'Body text' },
    });
    fireEvent.click(screen.getByText('Send'));

    await waitFor(() => expect(onSend).toHaveBeenCalled());
    const payload = onSend.mock.calls[0][0];
    expect(payload.to).toEqual(['lead@example.com']);
    expect(payload.subject).toBe('Hello');
    expect(payload.bodyHtml).toContain('Body text');
  });

  it('uses integration sendEmail when onSend is not provided', async () => {
    render(<EmailComposer defaultTo="lead@example.com" />);

    fireEvent.change(screen.getByPlaceholderText('Subject'), { target: { value: 'Hello' } });
    fireEvent.change(screen.getByPlaceholderText('Write your email...'), {
      target: { value: 'Body text' },
    });
    fireEvent.click(screen.getByText('Send'));

    await waitFor(() => expect(sendEmailMock).toHaveBeenCalled());
    const callArgs = sendEmailMock.mock.calls[0][0];
    expect(callArgs.to).toEqual(['lead@example.com']);
    expect(callArgs.subject).toBe('Hello');
  });
});
