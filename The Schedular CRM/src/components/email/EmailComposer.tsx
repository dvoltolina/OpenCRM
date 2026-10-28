import { useEffect, useMemo, useState } from 'react';
import type { EmailTemplate } from '../../types/email-integration';
import { getFeatureFlags } from '../../config/features';
import { EmailTrackingBadge } from './EmailTrackingBadge';
import { useEmailIntegration } from '../../hooks/useEmailIntegration';
import { ErrorBanner } from '../common/ErrorBanner';
import './email.css';

interface EmailComposerProps {
  accountId?: string;
  defaultTo?: string;
  associatedEntity?: { type: string; id: string };
  mergeData?: Record<string, string>;
  onSend?: (payload: {
    to: string[];
    cc: string[];
    bcc: string[];
    subject: string;
    bodyHtml: string;
    bodyText?: string;
    accountId?: string;
    associatedEntity?: { type: string; id: string };
  }) => Promise<void> | void;
}

const parseRecipients = (value: string): string[] =>
  value
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);

const parseMergeJson = (value: string): Record<string, string> | null => {
  if (!value.trim()) return {};
  try {
    return JSON.parse(value);
  } catch {
    return null;
  }
};

/**
 * Email composer with template support, tracking toggles, and account selection.
 */
export function EmailComposer({
  accountId,
  defaultTo,
  associatedEntity,
  mergeData,
  onSend,
}: EmailComposerProps) {
  const features = getFeatureFlags();
  const integration = useEmailIntegration({ loadEmails: false });
  const [to, setTo] = useState(defaultTo ?? '');
  const [cc, setCc] = useState('');
  const [bcc, setBcc] = useState('');
  const [subject, setSubject] = useState('');
  const [body, setBody] = useState('');
  const [selectedTemplateId, setSelectedTemplateId] = useState<string>('');
  const [mergeJson, setMergeJson] = useState(JSON.stringify(mergeData ?? {}, null, 2));
  const [trackOpens, setTrackOpens] = useState(true);
  const [trackClicks, setTrackClicks] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [status, setStatus] = useState<string | null>(null);

  useEffect(() => {
    if (defaultTo) {
      setTo(defaultTo);
    }
  }, [defaultTo]);

  const accounts = useMemo(() => integration.accounts, [integration.accounts]);
  const templates = useMemo(() => integration.templates, [integration.templates]);
  const activeAccountId = accountId || integration.selectedAccountId || accounts[0]?.id;
  const recipients = useMemo(() => parseRecipients(to), [to]);
  const ccList = useMemo(() => parseRecipients(cc), [cc]);
  const bccList = useMemo(() => parseRecipients(bcc), [bcc]);
  const selectedTemplate: EmailTemplate | undefined = useMemo(
    () => templates.find((tpl) => tpl.id === selectedTemplateId),
    [selectedTemplateId, templates]
  );

  useEffect(() => {
    if (selectedTemplate && !subject) {
      setSubject(selectedTemplate.subject);
    }
    if (selectedTemplate && !body) {
      setBody(selectedTemplate.bodyHtml || selectedTemplate.bodyText || '');
    }
  }, [selectedTemplate, subject, body]);

  if (!features.enableEmailIntegration) {
    return null;
  }

  const handleSend = async () => {
    setError(null);
    setStatus(null);

    if (!recipients.length) {
      setError('Add at least one recipient email address.');
      return;
    }

    const mergePayload = parseMergeJson(mergeJson);
    if (mergePayload === null) {
      setError('Merge data must be valid JSON (e.g., {"firstName":"Alex"}).');
      return;
    }

    try {
      if (onSend) {
        await onSend({
          to: recipients,
          cc: ccList,
          bcc: bccList,
          subject,
          bodyHtml: body,
          bodyText: body,
          accountId: activeAccountId,
          associatedEntity,
        });
        setStatus('Email sent.');
        return;
      }

      const result = selectedTemplateId
        ? await integration.sendTemplatedEmail({
            accountId: activeAccountId,
            templateId: selectedTemplateId,
            to: recipients,
            mergeData: mergePayload || {},
            associatedEntity,
          })
        : await integration.sendEmail({
            accountId: activeAccountId,
            to: recipients,
            cc: ccList,
            bcc: bccList,
            subject,
            bodyHtml: body,
            bodyText: body,
            trackOpens,
            trackClicks,
            associatedEntity,
          });

      if (result.success) {
        setStatus('Email sent.');
        setSubject('');
        setBody('');
        setCc('');
        setBcc('');
      } else {
        setError(result.error || 'Failed to send email.');
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to send email.');
    }
  };

  return (
    <div className="email-composer">
      {error && (
        <ErrorBanner message={error} onDismiss={() => setError(null)} />
      )}
      {status && <div className="email-status email-status--success">{status}</div>}

      <div className="email-composer__grid">
        <div className="email-composer__row">
          <label className="email-composer__label">From Account</label>
          <select
            value={activeAccountId || ''}
            onChange={(e) => integration.setSelectedAccountId(e.target.value)}
            disabled={integration.accountsLoading}
          >
            {accounts.length === 0 && <option value="">No connected accounts</option>}
            {accounts.map((acct) => (
              <option key={acct.id} value={acct.id}>
                {acct.email} · {acct.provider}
              </option>
            ))}
          </select>
        </div>

        <div className="email-composer__row">
          <label className="email-composer__label">Template</label>
          <select
            value={selectedTemplateId}
            onChange={(e) => setSelectedTemplateId(e.target.value)}
            disabled={integration.templatesLoading}
          >
            <option value="">No template</option>
            {templates.map((tpl) => (
              <option key={tpl.id} value={tpl.id}>
                {tpl.name} ({tpl.category})
              </option>
            ))}
          </select>
        </div>

        <div className="email-composer__row email-composer__row--wide">
          <label className="email-composer__label">Merge Data (JSON)</label>
          <textarea
            value={mergeJson}
            onChange={(e) => setMergeJson(e.target.value)}
            rows={3}
            placeholder='{"firstName":"Alex"}'
          />
        </div>

        <div className="email-composer__row email-composer__row--wide">
          <label className="email-composer__label">To</label>
          <input
            value={to}
            onChange={(e) => setTo(e.target.value)}
            placeholder="recipient@example.com"
          />
        </div>

        <div className="email-composer__row">
          <label className="email-composer__label">Cc</label>
          <input
            value={cc}
            onChange={(e) => setCc(e.target.value)}
            placeholder="Add Cc recipients"
          />
        </div>

        <div className="email-composer__row">
          <label className="email-composer__label">Bcc</label>
          <input
            value={bcc}
            onChange={(e) => setBcc(e.target.value)}
            placeholder="Add Bcc recipients"
          />
        </div>

        <div className="email-composer__row email-composer__row--wide">
          <label className="email-composer__label">Subject</label>
          <input
            value={subject}
            onChange={(e) => setSubject(e.target.value)}
            placeholder="Subject"
          />
        </div>

        <div className="email-composer__row email-composer__row--wide">
          <label className="email-composer__label">Body</label>
          <textarea
            value={body}
            onChange={(e) => setBody(e.target.value)}
            placeholder="Write your email..."
            rows={6}
          />
        </div>
      </div>

      <div className="email-composer__footer">
        <div className="email-composer__tracking">
          <div className="email-composer__checkboxes">
            <label className="email-composer__checkbox">
              <input
                type="checkbox"
                checked={trackOpens}
                onChange={(e) => setTrackOpens(e.target.checked)}
              />
              Track opens
            </label>
            <label className="email-composer__checkbox">
              <input
                type="checkbox"
                checked={trackClicks}
                onChange={(e) => setTrackClicks(e.target.checked)}
              />
              Track clicks
            </label>
          </div>
          <div className="email-composer__tracking-preview">
            <span className="email-composer__tracking-label">Tracking Preview</span>
            <EmailTrackingBadge opens={0} clicks={0} />
          </div>
        </div>
        <button
          type="button"
          className="btn btn--primary"
          onClick={handleSend}
          disabled={integration.isSending || integration.accountsLoading}
        >
          {integration.isSending ? 'Sending…' : 'Send'}
        </button>
      </div>
    </div>
  );
}

export default EmailComposer;
