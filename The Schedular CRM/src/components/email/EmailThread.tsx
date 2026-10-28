import { useEffect, useMemo, useState } from 'react';
import type { EmailMessage, EmailThread as Thread } from '../../types/email-integration';
import { EmailTrackingBadge } from './EmailTrackingBadge';
import { getFeatureFlags } from '../../config/features';
import { useEmailIntegration } from '../../hooks/useEmailIntegration';
import { ErrorBanner } from '../common/ErrorBanner';
import './email.css';

interface EmailThreadProps {
  thread?: Thread & { messages?: EmailMessage[] };
  threadId?: string;
}

const sanitizeEmailHtml = (html?: string): string => {
  if (!html) return '';
  if (typeof window === 'undefined' || !window.DOMParser) {
    return '';
  }
  const parser = new DOMParser();
  const doc = parser.parseFromString(html, 'text/html');
  doc.querySelectorAll('script, style').forEach((node) => node.remove());
  doc.querySelectorAll('*').forEach((node) => {
    Array.from(node.attributes).forEach((attr) => {
      const name = attr.name.toLowerCase();
      const value = attr.value.toLowerCase();
      if (name.startsWith('on')) {
        node.removeAttribute(attr.name);
      }
      if ((name === 'href' || name === 'src') && value.startsWith('javascript:')) {
        node.removeAttribute(attr.name);
      }
    });
  });
  return doc.body.innerHTML;
};

/**
 * Conversation view for a single email thread with sanitized HTML rendering.
 */
export function EmailThread({ thread, threadId }: EmailThreadProps) {
  const features = getFeatureFlags();
  const integration = useEmailIntegration({ loadEmails: false, loadTemplates: false, loadAccounts: false });
  const [localThread, setLocalThread] = useState<Thread & { messages?: EmailMessage[] } | null>(thread || null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setLocalThread(thread || null);
  }, [thread]);

  useEffect(() => {
    const load = async () => {
      if (threadId) {
        const result = await integration.loadThread(threadId);
        if (result) {
          setLocalThread(result);
          setError(null);
        } else if (integration.threadError) {
          setError(integration.threadError);
        }
      }
    };

    if (!thread && threadId) {
      load();
    }
  }, [integration, thread, threadId]);

  const messages = useMemo(() => localThread?.messages || [], [localThread]);

  if (!features.enableEmailIntegration) return null;

  return (
    <div className="email-thread">
      <div className="email-thread__header">
        <div className="email-thread__header-copy">
          <h4>{localThread?.subject || 'Thread'}</h4>
          {localThread?.participantEmails && (
            <p className="email-thread__participants">
              {localThread.participantEmails.join(', ')}
            </p>
          )}
        </div>
      </div>
      {error && <ErrorBanner message={error} onDismiss={() => setError(null)} />}
      <div className="email-thread__messages">
        {messages.map((message) => (
          <article key={message.id} className="email-thread__message">
            <div className="email-thread__message-header">
              <div className="email-thread__sender">
                <strong className="email-thread__author">
                  {message.fromName || message.fromEmail}
                </strong>
                <div className="email-thread__timestamp">
                  {new Date(message.sentAt).toLocaleString()}
                </div>
              </div>
              <EmailTrackingBadge
                opens={message.opens}
                clicks={message.clicks}
                firstOpenedAt={message.firstOpenedAt}
                lastOpenedAt={message.lastOpenedAt}
              />
            </div>
            <div
              className="email-thread__body"
              dangerouslySetInnerHTML={{ __html: sanitizeEmailHtml(message.bodyHtml || message.bodyText) }}
            />
            {message.attachments?.length ? (
              <div className="email-thread__attachments">
                Attachments ({message.attachments.length})
              </div>
            ) : null}
          </article>
        ))}
        {messages.length === 0 && <div className="email-thread__empty">No messages yet</div>}
      </div>
    </div>
  );
}

export default EmailThread;
