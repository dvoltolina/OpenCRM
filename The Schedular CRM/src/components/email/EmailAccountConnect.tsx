import { useEffect, useMemo, useState } from 'react';
import { getFeatureFlags } from '../../config/features';
import type { EmailAccount, EmailProvider } from '../../types/email-integration';
import { useEmailIntegration, type UseEmailIntegrationResult } from '../../hooks/useEmailIntegration';
import { ErrorBanner } from '../common/ErrorBanner';

interface EmailAccountConnectProps {
  /** Share an existing integration instance so account state is reused */
  integration?: UseEmailIntegrationResult;
  /** Optional auth code captured from an OAuth redirect */
  authorizationCode?: string;
  /** Preferred provider when pre-populating the connect form */
  providerHint?: EmailProvider;
  /** Callback after successful connect */
  onConnected?: (account: EmailAccount) => void;
  /** Callback after successful disconnect */
  onDisconnected?: (accountId: string) => void;
}

const formatDate = (value?: Date) => {
  if (!value) return '—';
  try {
    return new Date(value).toLocaleString();
  } catch {
    return '—';
  }
};

/**
 * Inbox connection + status controls backed by useEmailIntegration.
 * Handles configuration gating, sync triggers, token refresh, and auto-association.
 */
export function EmailAccountConnect({
  integration: providedIntegration,
  authorizationCode,
  providerHint,
  onConnected,
  onDisconnected,
}: EmailAccountConnectProps) {
  const features = getFeatureFlags();
  const internalIntegration = useEmailIntegration({
    loadAccounts: true,
    loadTemplates: false,
    loadEmails: false,
  });
  const integration = providedIntegration ?? internalIntegration;

  const [provider, setProvider] = useState<EmailProvider>(providerHint ?? 'gmail');
  const [authCode, setAuthCode] = useState(authorizationCode ?? '');
  const [status, setStatus] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [syncing, setSyncing] = useState<string | null>(null);
  const [autoAssociating, setAutoAssociating] = useState<string | null>(null);

  const isDisabled = !features.enableEmailIntegration || !integration.enabled;
  const notConfigured = !integration.configured || !integration.contextReady;

  useEffect(() => {
    if (authorizationCode && providerHint && integration.contextReady) {
      void handleConnect(providerHint, authorizationCode);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [authorizationCode, providerHint, integration.contextReady]);

  const sortedAccounts = useMemo(
    () =>
      [...integration.accounts].sort((a, b) =>
        (a.email || '').localeCompare(b.email || '', undefined, { sensitivity: 'base' })
      ),
    [integration.accounts]
  );

  const handleConnect = async (selectedProvider: EmailProvider, code?: string) => {
    if (!integration.contextReady) {
      setError('Email integration is not ready (auth or backend config missing).');
      return;
    }
    const finalCode = (code ?? authCode).trim();
    if (!finalCode) {
      setError('Authorization code is required to connect an inbox.');
      return;
    }

    setBusy(true);
    setError(null);
    setStatus(null);

    try {
      const account = await integration.connectAccount(selectedProvider, finalCode);
      if (account) {
        setStatus(`Connected ${account.email || selectedProvider} successfully`);
        setAuthCode('');
        onConnected?.(account);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unable to connect account');
    } finally {
      setBusy(false);
    }
  };

  const handleDisconnect = async (accountId: string) => {
    setBusy(true);
    setError(null);
    setStatus(null);
    try {
      await integration.disconnectAccount(accountId);
      setStatus('Account disconnected');
      onDisconnected?.(accountId);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unable to disconnect account');
    } finally {
      setBusy(false);
    }
  };

  const handleSync = async (accountId: string, folder: 'inbox' | 'sent') => {
    setSyncing(`${accountId}:${folder}`);
    setError(null);
    setStatus(null);
    try {
      const result = await integration.syncAccount(accountId, folder);
      if (result) {
        setStatus(
          `Synced ${folder} (${result.created} new, ${result.updated} updated${
            result.skipped ? `, ${result.skipped} skipped` : ''
          })`
        );
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Sync failed');
    } finally {
      setSyncing(null);
    }
  };

  const handleRefreshTokens = async (accountId: string) => {
    setBusy(true);
    setError(null);
    setStatus(null);
    try {
      await integration.refreshAccountTokens(accountId);
      setStatus('Tokens refreshed');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Token refresh failed');
    } finally {
      setBusy(false);
    }
  };

  const handleAutoAssociate = async (accountId: string) => {
    setAutoAssociating(accountId);
    setError(null);
    setStatus(null);
    try {
      const linked = await integration.autoAssociate(accountId);
      setStatus(`Auto-associated ${linked} messages`);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Auto-association failed');
    } finally {
      setAutoAssociating(null);
    }
  };

  if (isDisabled) return null;

  return (
    <div className="bg-white rounded-lg shadow p-4 space-y-4">
      <div className="flex items-start justify-between gap-3">
        <div>
          <h3 className="text-lg font-semibold">Inbox Connection</h3>
          <p className="text-sm text-gray-600">
            Connect Gmail or Outlook to sync threads and track opens/clicks. OAuth happens via Cloud
            Functions; no tokens are stored client-side.
          </p>
        </div>
        <button
          type="button"
          className="text-sm text-blue-600 hover:text-blue-800"
          onClick={() => integration.refreshAccounts()}
          disabled={integration.accountsLoading}
        >
          {integration.accountsLoading ? 'Refreshing…' : 'Refresh'}
        </button>
      </div>

      {!integration.configured && (
        <ErrorBanner
          variant="warning"
          message="Resolve the shared Scheduler Functions host via VITE_FUNCTIONS_BASE_URL or Firebase project config, then deploy the email OAuth Cloud Functions before enabling inbox sync."
        />
      )}

      {!integration.contextReady && integration.configured && (
        <ErrorBanner
          variant="info"
          message="Preparing security context… sign in or retry in a moment."
        />
      )}

      {error && (
        <ErrorBanner
          variant="error"
          message={error}
          onDismiss={() => setError(null)}
        />
      )}
      {status && (
        <div className="rounded-md bg-green-50 border border-green-200 p-3 text-sm text-green-800">
          {status}
        </div>
      )}

      <div className="border rounded-md p-3 space-y-3">
        <div className="flex flex-col md:flex-row gap-3">
          <div className="flex-1">
            <label className="block text-sm font-medium text-gray-700 mb-1">Provider</label>
            <select
              value={provider}
              onChange={(e) => setProvider(e.target.value as EmailProvider)}
              className="w-full border rounded-md px-3 py-2"
            >
              <option value="gmail">Gmail</option>
              <option value="outlook">Outlook</option>
              <option value="smtp">SMTP Relay</option>
            </select>
            <p className="text-xs text-gray-500 mt-1">
              OAuth flows happen via the backend; paste the returned authorization code to finalize the connection.
            </p>
          </div>
          <div className="flex-1">
            <label className="block text-sm font-medium text-gray-700 mb-1">Authorization Code</label>
            <input
              value={authCode}
              onChange={(e) => setAuthCode(e.target.value)}
              placeholder="Paste code from provider redirect"
              className="w-full border rounded-md px-3 py-2"
            />
          </div>
          <div className="flex items-end">
            <button
              type="button"
              onClick={() => handleConnect(provider)}
              className="btn btn-primary px-4 py-2"
              disabled={busy || notConfigured}
            >
              {busy ? 'Connecting…' : 'Connect'}
            </button>
          </div>
        </div>
      </div>

      <div className="space-y-2">
        <div className="flex items-center justify-between">
          <h4 className="text-sm font-semibold text-gray-800">Connected Accounts</h4>
          <span className="text-xs text-gray-500">
            {integration.accounts.length > 0
              ? `${integration.accounts.length} account${integration.accounts.length === 1 ? '' : 's'}`
              : 'None connected'}
          </span>
        </div>

        <div className="divide-y border rounded-md">
          {sortedAccounts.length === 0 && (
            <div className="p-3 text-sm text-gray-600">
              No accounts yet. Connect Gmail or Outlook to begin syncing conversations.
            </div>
          )}
          {sortedAccounts.map((account) => (
            <div key={account.id} className="p-3 flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
              <div>
                <div className="flex items-center gap-2">
                  <span className="text-sm font-semibold">{account.email}</span>
                  <span className="text-xs px-2 py-1 rounded-full bg-gray-100 text-gray-700 capitalize">
                    {account.provider}
                  </span>
                  <span
                    className={`text-xs px-2 py-1 rounded-full ${
                      account.syncStatus === 'synced'
                        ? 'bg-green-100 text-green-700'
                        : account.syncStatus === 'error'
                          ? 'bg-red-100 text-red-700'
                          : 'bg-yellow-100 text-yellow-700'
                    }`}
                  >
                    {account.syncStatus}
                  </span>
                </div>
                <div className="text-xs text-gray-600 mt-1 flex gap-3 flex-wrap">
                  <span>Last sync: {formatDate(account.lastSyncAt)}</span>
                  <span>Token expiry: {formatDate(account.tokenExpiresAt)}</span>
                </div>
              </div>

              <div className="flex flex-wrap gap-2">
                <button
                  type="button"
                  className="btn btn-secondary btn-sm"
                  onClick={() => integration.setSelectedAccountId(account.id)}
                  disabled={integration.selectedAccountId === account.id}
                >
                  {integration.selectedAccountId === account.id ? 'Default' : 'Set Default'}
                </button>
                <button
                  type="button"
                  className="btn btn-outline btn-sm"
                  onClick={() => handleSync(account.id, 'inbox')}
                  disabled={Boolean(syncing)}
                >
                  {syncing === `${account.id}:inbox` ? 'Syncing…' : 'Sync Inbox'}
                </button>
                <button
                  type="button"
                  className="btn btn-outline btn-sm"
                  onClick={() => handleSync(account.id, 'sent')}
                  disabled={Boolean(syncing)}
                >
                  {syncing === `${account.id}:sent` ? 'Syncing…' : 'Sync Sent'}
                </button>
                <button
                  type="button"
                  className="btn btn-outline btn-sm"
                  onClick={() => handleAutoAssociate(account.id)}
                  disabled={Boolean(autoAssociating)}
                >
                  {autoAssociating === account.id ? 'Linking…' : 'Auto-Associate'}
                </button>
                <button
                  type="button"
                  className="btn btn-outline btn-sm"
                  onClick={() => handleRefreshTokens(account.id)}
                  disabled={busy}
                >
                  Refresh Tokens
                </button>
                <button
                  type="button"
                  className="btn btn-secondary btn-sm"
                  onClick={() => handleDisconnect(account.id)}
                  disabled={busy}
                >
                  Disconnect
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

export default EmailAccountConnect;
