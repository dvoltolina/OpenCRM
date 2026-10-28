/**
 * BulkEmailModal Component
 * Modal for sending bulk emails to multiple contacts
 *
 * HIPAA Compliance:
 * - NO PHI in email content
 * - Rate limiting to prevent spam
 * - Opt-out preference validation
 * - Audit logging for all operations
 */

import { useState, useEffect, useMemo, useCallback } from 'react';
import { getEmailService } from '../../services/email-service';
import { getRateLimitService } from '../../services/RateLimitService';
import { useAuth } from '../../context/AuthContext';
import type { EmailTemplateType, BulkEmailResult, EmailTemplate } from '../../types/email';
import type { SecurityContext } from '../../data/repositories/repository-types';

// ============================================
// Types
// ============================================

export interface BulkEmailContact {
  id: string;
  name: string;
  email: string;
  hasOptedOut?: boolean;
}

export interface BulkEmailModalProps {
  /** Whether modal is open */
  isOpen: boolean;
  /** Called when modal should close */
  onClose: () => void;
  /** Contacts to email */
  contacts: BulkEmailContact[];
  /** Called after sending completes */
  onComplete?: (results: BulkEmailResult) => void;
}

interface ValidationResult {
  valid: BulkEmailContact[];
  invalid: Array<{ contact: BulkEmailContact; reason: string }>;
}

// ============================================
// Component
// ============================================

export function BulkEmailModal({
  isOpen,
  onClose,
  contacts,
  onComplete,
}: BulkEmailModalProps) {
  const { crmUser, businessId } = useAuth();
  const [selectedTemplateType, setSelectedTemplateType] = useState<EmailTemplateType>('marketing');
  const [customSubject, setCustomSubject] = useState('');
  const [customMessage, setCustomMessage] = useState('');
  const [skipInvalid, setSkipInvalid] = useState(true);
  const [isSending, setIsSending] = useState(false);
  const [progress, setProgress] = useState(0);
  const [results, setResults] = useState<BulkEmailResult | null>(null);
  const [rateLimitWarning, setRateLimitWarning] = useState<string | null>(null);
  const [templates, setTemplates] = useState<EmailTemplate[]>([]);
  const [selectedTemplateId, setSelectedTemplateId] = useState<string>('');

  // Validate contacts
  const validation = useMemo((): ValidationResult => {
    const valid: BulkEmailContact[] = [];
    const invalid: Array<{ contact: BulkEmailContact; reason: string }> = [];

    contacts.forEach((contact) => {
      if (!contact.email) {
        invalid.push({ contact, reason: 'No email address' });
      } else if (contact.hasOptedOut) {
        invalid.push({ contact, reason: 'Opted out of emails' });
      } else {
        valid.push(contact);
      }
    });

    return { valid, invalid };
  }, [contacts]);

  // Calculate sendable count
  const sendableCount = skipInvalid
    ? validation.valid.length
    : contacts.filter((c) => c.email && !c.hasOptedOut).length;

  // Check rate limits
  const checkRateLimits = useCallback(async () => {
    if (!businessId || !crmUser) return;

    const rateLimitService = getRateLimitService();
    const usage = await rateLimitService.getUsage('bulk_operation', crmUser.id, businessId);

    if (usage.remaining < 1) {
      setRateLimitWarning(
        `Bulk email limit reached. Try again after ${usage.resetAt.toLocaleTimeString()}.`
      );
    } else if (usage.remaining <= 3) {
      setRateLimitWarning(
        `${usage.remaining} bulk operations remaining. Limit resets at ${usage.resetAt.toLocaleTimeString()}.`
      );
    } else {
      setRateLimitWarning(null);
    }
  }, [businessId, crmUser]);

  // Load templates on open
  useEffect(() => {
    if (isOpen && businessId && crmUser) {
      const loadTemplates = async () => {
        const emailService = getEmailService();
        const context: SecurityContext = {
          businessId,
          userId: crmUser.id,
          userName: crmUser.displayName || crmUser.email || crmUser.id,
          userRole: crmUser.role,
          teamIds: crmUser.teamIds,
          managedTeamIds: crmUser.managedTeamIds,
          managerId: crmUser.managerId,
        };

        const result = await emailService.getTemplates(context);
        if (result.success && result.data) {
          setTemplates(result.data.data || []);
        }
      };
      loadTemplates();
    }
  }, [isOpen, businessId, crmUser]);

  // Reset state when modal opens
  useEffect(() => {
    if (isOpen) {
      setSelectedTemplateType('marketing');
      setSelectedTemplateId('');
      setCustomSubject('');
      setCustomMessage('');
      setSkipInvalid(true);
      setIsSending(false);
      setProgress(0);
      setResults(null);
      checkRateLimits();
    }
  }, [isOpen, checkRateLimits]);

  // Handle bulk send
  const handleSend = async () => {
    if (!businessId || !crmUser || sendableCount === 0) return;

    setIsSending(true);
    setProgress(0);

    try {
      const contactsToEmail = skipInvalid
        ? validation.valid
        : contacts.filter((c) => c.email && !c.hasOptedOut);

      // Simulate progress for better UX
      const progressInterval = setInterval(() => {
        setProgress((prev) => Math.min(prev + 10, 90));
      }, 200);

      const emailService = getEmailService();
      const context: SecurityContext = {
        businessId,
        userId: crmUser.id,
        userName: crmUser.displayName || crmUser.email || crmUser.id,
        userRole: crmUser.role,
        teamIds: crmUser.teamIds,
        managedTeamIds: crmUser.managedTeamIds,
        managerId: crmUser.managerId,
      };

      const result = await emailService.sendBulkEmail(context, {
        recipientIds: contactsToEmail.map((c) => c.id),
        templateType: selectedTemplateType,
        templateId: selectedTemplateId || undefined,
        templateData: {
          subject: customSubject || undefined,
          message: customMessage || undefined,
        },
        category: 'marketing',
      });

      clearInterval(progressInterval);
      setProgress(100);

      setResults(result);
      onComplete?.(result);
    } catch (err) {
      setResults({
        success: false,
        total: sendableCount,
        queued: 0,
        failed: sendableCount,
        errors: { _all: err instanceof Error ? err.message : 'Unknown error' },
      });
    } finally {
      setIsSending(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div
      className="modal-overlay"
      onClick={onClose}
      role="dialog"
      aria-modal="true"
      aria-labelledby="bulk-email-modal-title"
    >
      <div
        className="modal-content bulk-email-modal"
        onClick={(e) => e.stopPropagation()}
        data-testid="bulk-email-modal"
      >
        {/* Header */}
        <div className="modal-header">
          <h2 id="bulk-email-modal-title" className="modal-title">
            {results ? 'Email Results' : 'Send Bulk Email'}
          </h2>
          <button
            type="button"
            className="modal-close"
            onClick={onClose}
            aria-label="Close modal"
          >
            ×
          </button>
        </div>

        {/* Content */}
        <div className="modal-body">
          {results ? (
            <ResultsContent results={results} onClose={onClose} />
          ) : isSending ? (
            <ProgressContent progress={progress} count={sendableCount} />
          ) : (
            <EmailFormContent
              contacts={contacts}
              validation={validation}
              templates={templates}
              selectedTemplateType={selectedTemplateType}
              selectedTemplateId={selectedTemplateId}
              customSubject={customSubject}
              customMessage={customMessage}
              skipInvalid={skipInvalid}
              sendableCount={sendableCount}
              rateLimitWarning={rateLimitWarning}
              onTemplateTypeChange={setSelectedTemplateType}
              onTemplateIdChange={setSelectedTemplateId}
              onSubjectChange={setCustomSubject}
              onMessageChange={setCustomMessage}
              onSkipInvalidChange={setSkipInvalid}
              onSend={handleSend}
              onCancel={onClose}
            />
          )}
        </div>
      </div>
    </div>
  );
}

// ============================================
// Sub-components
// ============================================

interface EmailFormContentProps {
  contacts: BulkEmailContact[];
  validation: ValidationResult;
  templates: EmailTemplate[];
  selectedTemplateType: EmailTemplateType;
  selectedTemplateId: string;
  customSubject: string;
  customMessage: string;
  skipInvalid: boolean;
  sendableCount: number;
  rateLimitWarning: string | null;
  onTemplateTypeChange: (type: EmailTemplateType) => void;
  onTemplateIdChange: (id: string) => void;
  onSubjectChange: (subject: string) => void;
  onMessageChange: (message: string) => void;
  onSkipInvalidChange: (skip: boolean) => void;
  onSend: () => void;
  onCancel: () => void;
}

function EmailFormContent({
  contacts,
  validation,
  templates,
  selectedTemplateType,
  selectedTemplateId,
  customSubject,
  customMessage,
  skipInvalid,
  sendableCount,
  rateLimitWarning,
  onTemplateTypeChange,
  onTemplateIdChange,
  onSubjectChange,
  onMessageChange,
  onSkipInvalidChange,
  onSend,
  onCancel,
}: EmailFormContentProps) {
  const templateTypes: { value: EmailTemplateType; label: string }[] = [
    { value: 'marketing', label: 'Marketing' },
    { value: 'follow_up', label: 'Follow Up' },
    { value: 'custom', label: 'Custom' },
  ];

  const filteredTemplates = templates.filter(
    (t) => t.type === selectedTemplateType && t.isActive
  );

  return (
    <>
      {/* Summary */}
      <div className="bulk-email-modal__summary">
        <div className="bulk-email-modal__summary-item">
          <span className="bulk-email-modal__summary-value">{contacts.length}</span>
          <span className="bulk-email-modal__summary-label">Selected</span>
        </div>
        <div className="bulk-email-modal__summary-item bulk-email-modal__summary-item--valid">
          <span className="bulk-email-modal__summary-value">{validation.valid.length}</span>
          <span className="bulk-email-modal__summary-label">Valid</span>
        </div>
        <div className="bulk-email-modal__summary-item bulk-email-modal__summary-item--invalid">
          <span className="bulk-email-modal__summary-value">{validation.invalid.length}</span>
          <span className="bulk-email-modal__summary-label">Issues</span>
        </div>
      </div>

      {/* Invalid Contacts List */}
      {validation.invalid.length > 0 && (
        <div className="bulk-email-modal__issues">
          <h4 className="bulk-email-modal__issues-title">
            Contacts with Issues ({validation.invalid.length})
          </h4>
          <div className="bulk-email-modal__issues-list">
            {validation.invalid.slice(0, 5).map(({ contact, reason }) => (
              <div key={contact.id} className="bulk-email-modal__issue">
                <span className="bulk-email-modal__issue-name">{contact.name}</span>
                <span className="bulk-email-modal__issue-reason">{reason}</span>
              </div>
            ))}
            {validation.invalid.length > 5 && (
              <div className="bulk-email-modal__issue-more">
                +{validation.invalid.length - 5} more
              </div>
            )}
          </div>
        </div>
      )}

      {/* Skip Invalid Checkbox */}
      {validation.invalid.length > 0 && (
        <label className="bulk-email-modal__checkbox">
          <input
            type="checkbox"
            checked={skipInvalid}
            onChange={(e) => onSkipInvalidChange(e.target.checked)}
          />
          <span>Skip contacts with issues (email {validation.valid.length} only)</span>
        </label>
      )}

      {/* Rate Limit Warning */}
      {rateLimitWarning && (
        <div className="bulk-email-modal__rate-warning" role="alert">
          <svg
            width="16"
            height="16"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
          >
            <circle cx="12" cy="12" r="10" />
            <line x1="12" y1="8" x2="12" y2="12" />
            <line x1="12" y1="16" x2="12.01" y2="16" />
          </svg>
          <span>{rateLimitWarning}</span>
        </div>
      )}

      {/* Template Type Selector */}
      <div className="bulk-email-modal__field">
        <label htmlFor="bulk-email-type" className="bulk-email-modal__label">
          Email Type
        </label>
        <select
          id="bulk-email-type"
          className="bulk-email-modal__select"
          value={selectedTemplateType}
          onChange={(e) => onTemplateTypeChange(e.target.value as EmailTemplateType)}
          data-testid="bulk-email-type"
        >
          {templateTypes.map((type) => (
            <option key={type.value} value={type.value}>
              {type.label}
            </option>
          ))}
        </select>
      </div>

      {/* Template Selector */}
      {filteredTemplates.length > 0 && (
        <div className="bulk-email-modal__field">
          <label htmlFor="bulk-email-template" className="bulk-email-modal__label">
            Template (Optional)
          </label>
          <select
            id="bulk-email-template"
            className="bulk-email-modal__select"
            value={selectedTemplateId}
            onChange={(e) => onTemplateIdChange(e.target.value)}
            data-testid="bulk-email-template"
          >
            <option value="">Use default template</option>
            {filteredTemplates.map((template) => (
              <option key={template.id} value={template.id}>
                {template.name}
              </option>
            ))}
          </select>
        </div>
      )}

      {/* Custom Subject */}
      <div className="bulk-email-modal__field">
        <label htmlFor="bulk-email-subject" className="bulk-email-modal__label">
          Subject {selectedTemplateType === 'custom' ? '(Required)' : '(Optional Override)'}
        </label>
        <input
          id="bulk-email-subject"
          type="text"
          className="bulk-email-modal__input"
          value={customSubject}
          onChange={(e) => onSubjectChange(e.target.value)}
          placeholder="Enter email subject..."
          data-testid="bulk-email-subject"
        />
      </div>

      {/* Custom Message */}
      <div className="bulk-email-modal__field">
        <label htmlFor="bulk-email-message" className="bulk-email-modal__label">
          Message {selectedTemplateType === 'custom' ? '(Required)' : '(Optional Override)'}
        </label>
        <textarea
          id="bulk-email-message"
          className="bulk-email-modal__textarea"
          value={customMessage}
          onChange={(e) => onMessageChange(e.target.value)}
          placeholder="Enter your message... (Do not include personal health information)"
          rows={4}
          data-testid="bulk-email-message"
        />
        <p className="bulk-email-modal__hint">
          HIPAA Notice: Do not include any personal health information (PHI) in this message.
        </p>
      </div>

      {/* Estimate */}
      <div className="bulk-email-modal__estimate">
        <strong>{sendableCount}</strong> contacts will receive this email
      </div>

      {/* Actions */}
      <div className="modal-footer">
        <button type="button" className="btn btn-secondary" onClick={onCancel}>
          Cancel
        </button>
        <button
          type="button"
          className="btn btn-primary"
          onClick={onSend}
          disabled={
            sendableCount === 0 ||
            !!rateLimitWarning?.includes('reached') ||
            (selectedTemplateType === 'custom' && (!customSubject || !customMessage))
          }
          data-testid="bulk-email-send-button"
        >
          Send to {sendableCount} Contacts
        </button>
      </div>
    </>
  );
}

interface ProgressContentProps {
  progress: number;
  count: number;
}

function ProgressContent({ progress, count }: ProgressContentProps) {
  return (
    <div className="bulk-email-modal__progress" data-testid="bulk-email-progress">
      <div className="bulk-email-modal__progress-icon">
        <svg
          className="bulk-email-modal__spinner"
          width="48"
          height="48"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
        >
          <path d="M21 12a9 9 0 1 1-6.219-8.56" />
        </svg>
      </div>
      <h3 className="bulk-email-modal__progress-title">Sending to {count} contacts...</h3>
      <div className="bulk-email-modal__progress-bar">
        <div
          className="bulk-email-modal__progress-fill"
          style={{ width: `${progress}%` }}
        />
      </div>
      <p className="bulk-email-modal__progress-text">{progress}% complete</p>
    </div>
  );
}

interface ResultsContentProps {
  results: BulkEmailResult;
  onClose: () => void;
}

function ResultsContent({ results, onClose }: ResultsContentProps) {
  return (
    <div className="bulk-email-modal__results" data-testid="bulk-email-results">
      <div className="bulk-email-modal__results-summary">
        <div className="bulk-email-modal__results-item bulk-email-modal__results-item--success">
          <span className="bulk-email-modal__results-value">{results.queued}</span>
          <span className="bulk-email-modal__results-label">Sent</span>
        </div>
        <div className="bulk-email-modal__results-item bulk-email-modal__results-item--error">
          <span className="bulk-email-modal__results-value">{results.failed}</span>
          <span className="bulk-email-modal__results-label">Failed</span>
        </div>
      </div>

      {/* Error Details */}
      {results.errors && Object.keys(results.errors).length > 0 && (
        <div className="bulk-email-modal__results-details bulk-email-modal__results-details--error">
          <h4>Errors</h4>
          <ul>
            {Object.entries(results.errors).slice(0, 10).map(([id, error]) => (
              <li key={id}>
                {id === '_all' ? error : `${id.slice(0, 8)}...: ${error}`}
              </li>
            ))}
            {Object.keys(results.errors).length > 10 && (
              <li className="text-muted">+{Object.keys(results.errors).length - 10} more</li>
            )}
          </ul>
        </div>
      )}

      {/* Success Message */}
      {results.success && results.queued > 0 && (
        <div className="bulk-email-modal__success-message">
          Emails have been queued for delivery. You can track delivery status in the Email Logs.
        </div>
      )}

      <div className="modal-footer">
        <button type="button" className="btn btn-primary" onClick={onClose}>
          Done
        </button>
      </div>
    </div>
  );
}

export default BulkEmailModal;
