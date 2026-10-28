import { useState } from 'react';
import { getFeatureFlags } from '../../config/features';
import { useEmailIntegration } from '../../hooks/useEmailIntegration';
import { ErrorBanner } from '../common/ErrorBanner';
import './email.css';

interface EmailAssociationPickerProps {
  messageId?: string;
  defaultEntityType?: 'lead' | 'client' | 'deal';
  defaultEntityId?: string;
  onAssociate?: (entityType: 'lead' | 'client' | 'deal', entityId: string) => Promise<void> | void;
}

/**
 * Helper to link an email to a lead/client/deal.
 */
export function EmailAssociationPicker({
  messageId,
  defaultEntityType = 'lead',
  defaultEntityId,
  onAssociate,
}: EmailAssociationPickerProps) {
  const features = getFeatureFlags();
  const integration = useEmailIntegration({ loadEmails: false, loadTemplates: false, loadAccounts: false });
  const [entityType, setEntityType] = useState<'lead' | 'client' | 'deal'>(defaultEntityType);
  const [entityId, setEntityId] = useState(defaultEntityId || '');
  const [status, setStatus] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [isLinking, setIsLinking] = useState(false);

  if (!features.enableEmailIntegration) return null;

  const handleAssociate = async () => {
    if (!entityId) {
      setError('Enter a valid entity ID.');
      return;
    }
    setStatus(null);
    setError(null);
    setIsLinking(true);

    try {
      if (onAssociate) {
        await onAssociate(entityType, entityId);
      } else if (messageId) {
        await integration.associateEmail(messageId, entityType, entityId);
      }
      setStatus('Email linked.');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unable to link email');
    } finally {
      setIsLinking(false);
    }
  };

  return (
    <div className="email-association-picker">
      {error && <ErrorBanner message={error} onDismiss={() => setError(null)} />}
      {status && <div className="email-status email-status--success">{status}</div>}
      <label className="email-association-picker__label">Link email to</label>
      <div className="email-association-picker__controls">
        <select
          value={entityType}
          onChange={(e) => setEntityType(e.target.value as 'lead' | 'client' | 'deal')}
        >
          <option value="lead">Lead</option>
          <option value="client">Client</option>
          <option value="deal">Deal</option>
        </select>
        <input
          value={entityId}
          onChange={(e) => setEntityId(e.target.value)}
          placeholder="Entity ID"
        />
        <button
          type="button"
          className="btn btn--secondary"
          onClick={handleAssociate}
          disabled={!entityId || isLinking}
        >
          {isLinking ? 'Linking…' : 'Link'}
        </button>
      </div>
    </div>
  );
}

export default EmailAssociationPicker;
