import { useEffect, useState } from 'react';
import { getFeatureFlags } from '../../config/features';
import { useEmailIntegration } from '../../hooks/useEmailIntegration';
import { ErrorBanner } from '../common/ErrorBanner';

interface EmailTemplateEditorProps {
  onSave?: (template: {
    name: string;
    subject: string;
    bodyHtml: string;
    bodyText?: string;
    category: 'outreach' | 'followup' | 'nurture' | 'transactional';
    availableMergeFields?: string[];
  }) => Promise<void> | void;
}

/**
 * Template CRUD UI for email integration.
 */
export function EmailTemplateEditor({ onSave }: EmailTemplateEditorProps) {
  const features = getFeatureFlags();
  const integration = useEmailIntegration({ loadEmails: false });
  const [name, setName] = useState('');
  const [subject, setSubject] = useState('');
  const [body, setBody] = useState('');
  const [category, setCategory] = useState<'outreach' | 'followup' | 'nurture' | 'transactional'>(
    'outreach'
  );
  const [mergeFields, setMergeFields] = useState('');
  const [status, setStatus] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [integrationErrorDismissed, setIntegrationErrorDismissed] = useState(false);

  const combinedError = integrationErrorDismissed ? error : error || integration.templateError;

  useEffect(() => {
    if (integration.templateError) {
      setIntegrationErrorDismissed(false);
    }
  }, [integration.templateError]);

  if (!features.enableEmailIntegration) return null;

  const handleSave = async () => {
    setStatus(null);
    if (!name.trim() || !subject.trim() || !body.trim()) {
      setError('Name, subject, and body are required.');
      return;
    }

    const templatePayload = {
      name,
      subject,
      bodyHtml: body,
      bodyText: body,
      category,
      availableMergeFields: mergeFields
        .split(',')
        .map((f) => f.trim())
        .filter(Boolean),
    };

    try {
      if (onSave) {
        await onSave(templatePayload);
      } else {
        await integration.saveTemplate(templatePayload);
      }
      setStatus('Template saved.');
      setError(null);
      setName('');
      setSubject('');
      setBody('');
      setMergeFields('');
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Unable to save template';
      setError(message);
    }
  };

  return (
    <div className="email-template-editor">
      {combinedError && (
        <ErrorBanner
          message={combinedError}
          onDismiss={() => {
            setError(null);
            setIntegrationErrorDismissed(true);
          }}
        />
      )}
      {status && <div className="text-success">{status}</div>}
      <div className="email-template-editor__row">
        <label>Name</label>
        <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Template name" />
      </div>
      <div className="email-template-editor__row">
        <label>Subject</label>
        <input
          value={subject}
          onChange={(e) => setSubject(e.target.value)}
          placeholder="Subject line"
        />
      </div>
      <div className="email-template-editor__row">
        <label>Category</label>
        <select value={category} onChange={(e) => setCategory(e.target.value as any)}>
          <option value="outreach">Outreach</option>
          <option value="followup">Follow-up</option>
          <option value="nurture">Nurture</option>
          <option value="transactional">Transactional</option>
        </select>
      </div>
      <div className="email-template-editor__row">
        <label>Merge fields (comma separated)</label>
        <input
          value={mergeFields}
          onChange={(e) => setMergeFields(e.target.value)}
          placeholder="firstName,lastName,company"
        />
      </div>
      <div className="email-template-editor__row">
        <label>Body</label>
        <textarea
          value={body}
          onChange={(e) => setBody(e.target.value)}
          placeholder="HTML content"
          rows={6}
        />
      </div>
      <div className="email-template-editor__footer">
        <button
          type="button"
          className="btn btn-primary"
          onClick={handleSave}
          disabled={integration.templatesLoading}
        >
          {integration.templatesLoading ? 'Saving…' : 'Save Template'}
        </button>
      </div>

      <div className="email-template-editor__list">
        <div className="email-template-editor__list-header">
          <h4>Templates</h4>
        </div>
        {integration.templatesLoading && <div>Loading templates…</div>}
        {!integration.templatesLoading && integration.templates.length === 0 && (
          <div className="text-muted">No templates yet.</div>
        )}
        {!integration.templatesLoading &&
          integration.templates.map((tpl) => (
            <div key={tpl.id} className="email-template-editor__item">
              <div>
                <strong>{tpl.name}</strong> · {tpl.category}
                <div className="text-muted">Usage: {tpl.usageCount}</div>
              </div>
              <button
                type="button"
                className="btn btn-secondary"
                onClick={() => integration.deleteTemplate(tpl.id)}
              >
                Delete
              </button>
            </div>
          ))}
      </div>
    </div>
  );
}

export default EmailTemplateEditor;
