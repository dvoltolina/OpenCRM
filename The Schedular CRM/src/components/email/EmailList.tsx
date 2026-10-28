import { useCallback, useEffect, useMemo, useState } from 'react';
import { getFeatureFlags } from '../../config/features';
import type { EmailMessage, EmailDirection } from '../../types/email-integration';
import { useEmailIntegration } from '../../hooks/useEmailIntegration';
import { EmailTrackingBadge } from './EmailTrackingBadge';
import { EmailThread } from './EmailThread';
import { EmailAssociationPicker } from './EmailAssociationPicker';
import { ErrorBanner } from '../common/ErrorBanner';
import './email.css';

interface EmailListProps {
  entityType?: 'lead' | 'client' | 'deal';
  entityId?: string;
  accountId?: string;
  fetchEmails?: () => Promise<EmailMessage[]>;
}

function formatDirectionLabel(direction: EmailDirection): string {
  return direction === 'inbound' ? 'Inbound' : 'Outbound';
}

function getDirectionToneClassName(direction: EmailDirection): string {
  return direction === 'inbound' ? 'email-pill--neutral' : 'email-pill--info';
}

/**
 * Inbox-style list with search/filter + optional thread preview.
 */
export function EmailList({ entityType, entityId, accountId, fetchEmails }: EmailListProps) {
  const features = getFeatureFlags();
  const integration = useEmailIntegration({
    entityType,
    entityId,
    loadEmails: !fetchEmails,
    loadTemplates: false,
  });

  const [emails, setEmails] = useState<EmailMessage[]>([]);
  const [search, setSearch] = useState('');
  const [direction, setDirection] = useState<'all' | EmailDirection>('all');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [selectedThreadId, setSelectedThreadId] = useState<string | null>(null);

  const hydrate = useCallback(async () => {
    if (fetchEmails) {
      setLoading(true);
      setError(null);
      try {
        const data = await fetchEmails();
        setEmails(data);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unable to load emails');
      } finally {
        setLoading(false);
      }
      return;
    }

    setEmails(integration.emails);
    setError(integration.emailError);
    setLoading(integration.emailsLoading);
  }, [fetchEmails, integration.emailError, integration.emails, integration.emailsLoading]);

  useEffect(() => {
    hydrate();
  }, [hydrate]);

  useEffect(() => {
    if (selectedThreadId) {
      integration.loadThread(selectedThreadId);
    }
  }, [integration, selectedThreadId]);

  const filteredEmails = useMemo(() => {
    let list = emails;
    if (accountId) {
      list = list.filter((email) => email.accountId === accountId);
    }
    if (direction !== 'all') {
      list = list.filter((email) => email.direction === direction);
    }
    if (search.trim()) {
      const needle = search.toLowerCase();
      list = list.filter(
        (email) =>
          email.subject.toLowerCase().includes(needle) ||
          email.snippet.toLowerCase().includes(needle) ||
          email.fromEmail.toLowerCase().includes(needle)
      );
    }
    return list;
  }, [emails, accountId, direction, search]);

  if (!features.enableEmailIntegration) {
    return null;
  }

  const handleViewThread = (message: EmailMessage) => {
    if (message.threadId) {
      setSelectedThreadId(message.threadId);
    }
  };

  const handleAssociate = async (messageId: string, targetType: 'lead' | 'client' | 'deal', targetId: string) => {
    setError(null);
    try {
      await integration.associateEmail(messageId, targetType, targetId);
      await hydrate();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unable to link email');
    }
  };

  return (
    <div className="email-list">
      <div className="email-list__header">
        <div className="email-list__header-copy">
          <div className="email-list__title-row">
            <h4>Email</h4>
            <span className="email-list__count">{filteredEmails.length}</span>
          </div>
          <div className="email-list__context-row">
            {entityType && entityId && (
              <span className="email-list__context">
                Linked to {entityType} · {entityId}
              </span>
            )}
            {accountId && <span className="email-pill email-pill--neutral">Account {accountId}</span>}
          </div>
        </div>
        <div className="email-list__filters">
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search subject/snippet"
          />
          <select value={direction} onChange={(e) => setDirection(e.target.value as 'all' | EmailDirection)}>
            <option value="all">All</option>
            <option value="inbound">Inbound</option>
            <option value="outbound">Outbound</option>
          </select>
          <button
            type="button"
            className="btn btn--ghost"
            onClick={() => {
              if (fetchEmails) {
                hydrate();
              } else {
                integration.refreshEmails();
              }
            }}
            disabled={loading}
          >
            Refresh
          </button>
        </div>
      </div>

      {error && <ErrorBanner message={error} onDismiss={() => setError(null)} />}
      {loading && <div className="email-list__loading">Loading emails…</div>}
      {!loading && filteredEmails.length === 0 && (
        <div className="email-list__empty">No emails found</div>
      )}
      {!loading && filteredEmails.length > 0 && (
        <ul className="email-list__items">
          {filteredEmails.map((email) => (
            <li key={email.id} className="email-list__item">
              <div className="email-list__subject-row">
                <div className="email-list__subject-group">
                  <div className="email-list__subject">{email.subject || 'Untitled email'}</div>
                  <span className={`email-pill ${getDirectionToneClassName(email.direction)}`}>
                    {formatDirectionLabel(email.direction)}
                  </span>
                </div>
                <span className="email-list__time">
                  {new Date(email.sentAt).toLocaleString()}
                </span>
              </div>
              <div className="email-list__meta">
                <span>{email.fromName || email.fromEmail}</span>
                <span>To {email.toEmails.join(', ')}</span>
              </div>
              <div className="email-list__snippet">{email.snippet}</div>
              <div className="email-list__actions">
                <EmailTrackingBadge
                  opens={email.opens}
                  clicks={email.clicks}
                  firstOpenedAt={email.firstOpenedAt}
                  lastOpenedAt={email.lastOpenedAt}
                />
                {email.threadId && (
                  <button
                    type="button"
                    className="btn btn--secondary"
                    onClick={() => handleViewThread(email)}
                    disabled={integration.threadLoading}
                  >
                    View Thread
                  </button>
                )}
              </div>
              {!email.associatedEntityId && (
                <div className="email-list__associate">
                  <EmailAssociationPicker
                    messageId={email.id}
                    onAssociate={(type, id) => handleAssociate(email.id, type, id)}
                  />
                </div>
              )}
            </li>
          ))}
        </ul>
      )}

      {integration.thread && selectedThreadId === integration.thread.id && (
        <div className="email-list__thread">
          <EmailThread thread={integration.thread} />
        </div>
      )}
    </div>
  );
}

export default EmailList;
