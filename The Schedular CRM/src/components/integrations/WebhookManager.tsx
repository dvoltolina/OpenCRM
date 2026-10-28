/**
 * WebhookManager Component
 * CRUD interface for webhook endpoint configuration
 *
 * HIPAA Compliance:
 * - No PHI in webhook payloads (sanitized by service)
 * - Secrets shown only once on creation/regeneration
 * - Error messages sanitized
 *
 * Security:
 * - URLs must be HTTPS
 * - Secrets for HMAC-SHA256 signature verification
 * - Only admin/owner can manage endpoints
 * - Test button for validating endpoints
 *
 * Task 10: API Integrations UI Components
 */

import { useState, useEffect, useCallback, useMemo } from 'react';
import { getWebhookEndpointService } from '../../services/webhook-endpoint-service';
import type { WebhookEndpoint, WebhookEvent } from '../../types/integrations';

// ============================================
// Types
// ============================================

interface WebhookManagerProps {
  securityContext: any;
  onUpdate?: () => void;
}

interface SecretDisplay {
  endpointId: string;
  secret: string;
}

// ============================================
// Constants
// ============================================

const WEBHOOK_EVENTS: { value: WebhookEvent; label: string }[] = [
  { value: 'lead.created', label: 'Lead Created' },
  { value: 'lead.updated', label: 'Lead Updated' },
  { value: 'lead.converted', label: 'Lead Converted' },
  { value: 'deal.created', label: 'Deal Created' },
  { value: 'deal.updated', label: 'Deal Updated' },
  { value: 'deal.stage_changed', label: 'Deal Stage Changed' },
  { value: 'deal.won', label: 'Deal Won' },
  { value: 'deal.lost', label: 'Deal Lost' },
  { value: 'contact.created', label: 'Contact Created' },
  { value: 'contact.updated', label: 'Contact Updated' },
  { value: 'task.created', label: 'Task Created' },
  { value: 'task.completed', label: 'Task Completed' },
  { value: 'email.sent', label: 'Email Sent' },
  { value: 'email.opened', label: 'Email Opened' },
  { value: 'sequence.enrolled', label: 'Sequence Enrolled' },
  { value: 'sequence.completed', label: 'Sequence Completed' },
  { value: 'form.submitted', label: 'Form Submitted' },
];

// ============================================
// Component
// ============================================

/**
 * WebhookManager - Webhook endpoint CRUD
 *
 * Features:
 * - List all webhook endpoints
 * - Create new endpoints with event selection
 * - Edit endpoint configuration
 * - Delete endpoints
 * - Test endpoint delivery
 * - Regenerate secrets
 *
 * @example
 * ```tsx
 * <WebhookManager
 *   securityContext={securityContext}
 *   onUpdate={handleRefresh}
 * />
 * ```
 */
export function WebhookManager({ securityContext, onUpdate }: WebhookManagerProps) {
  const webhookService = useMemo(() => getWebhookEndpointService(), []);

  const [endpoints, setEndpoints] = useState<WebhookEndpoint[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Form state
  const [showForm, setShowForm] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    url: '',
    events: [] as WebhookEvent[],
    retryEnabled: true,
    maxRetries: 3,
  });

  // Secret display (shown only once after creation/regeneration)
  const [secretDisplay, setSecretDisplay] = useState<SecretDisplay | null>(null);

  // Testing state
  const [testingEndpointId, setTestingEndpointId] = useState<string | null>(null);

  // Load endpoints
  const loadEndpoints = useCallback(async () => {
    if (!securityContext) return;

    setIsLoading(true);
    setError(null);

    try {
      const result = await webhookService.getEndpoints(securityContext);
      if (result.success && result.data) {
        setEndpoints(result.data);
      } else {
        setError('Failed to load webhook endpoints');
      }
    } catch (err) {
      setError('An error occurred while loading webhooks');
      console.error('Error loading webhooks:', err);
    } finally {
      setIsLoading(false);
    }
  }, [securityContext, webhookService]);

  useEffect(() => {
    loadEndpoints();
  }, [loadEndpoints]);

  // Form handlers
  const handleSubmit = useCallback(
    async (e: React.FormEvent) => {
      e.preventDefault();

      if (!securityContext) return;

      if (formData.events.length === 0) {
        setError('Please select at least one event');
        return;
      }

      setIsSubmitting(true);
      setError(null);

      try {
        const result = await webhookService.createEndpoint(securityContext, formData);

        if (result.success && result.data) {
          // Show secret (only shown once)
          setSecretDisplay({
            endpointId: result.data.id,
            secret: result.data.secret,
          });

          // Reset form
          setFormData({
            name: '',
            description: '',
            url: '',
            events: [],
            retryEnabled: true,
            maxRetries: 3,
          });
          setShowForm(false);

          // Reload list
          await loadEndpoints();
          if (onUpdate) onUpdate();
        } else {
          setError(result.error?.message || 'Failed to create webhook');
        }
      } catch (err) {
        setError('An error occurred while creating the webhook');
        console.error('Error creating webhook:', err);
      } finally {
        setIsSubmitting(false);
      }
    },
    [securityContext, formData, webhookService, loadEndpoints, onUpdate]
  );

  const handleEventToggle = useCallback((event: WebhookEvent) => {
    setFormData((prev) => ({
      ...prev,
      events: prev.events.includes(event)
        ? prev.events.filter((e) => e !== event)
        : [...prev.events, event],
    }));
  }, []);

  const handleDelete = useCallback(
    async (endpointId: string) => {
      if (!securityContext) return;

      const confirmed = window.confirm(
        'Are you sure you want to delete this webhook endpoint?'
      );
      if (!confirmed) return;

      setError(null);

      try {
        const result = await webhookService.deleteEndpoint(securityContext, endpointId);

        if (result.success) {
          await loadEndpoints();
          if (onUpdate) onUpdate();
        } else {
          setError(result.error?.message || 'Failed to delete webhook');
        }
      } catch (err) {
        setError('An error occurred while deleting the webhook');
        console.error('Error deleting webhook:', err);
      }
    },
    [securityContext, webhookService, loadEndpoints, onUpdate]
  );

  const handleTest = useCallback(
    async (endpointId: string) => {
      if (!securityContext) return;

      setTestingEndpointId(endpointId);
      setError(null);

      try {
        const result = await webhookService.testEndpoint(securityContext, endpointId);

        if (result.success && result.data) {
          if (result.data.success) {
            alert(
              `Test successful!\nStatus: ${result.data.statusCode}\nResponse time: ${result.data.responseTimeMs}ms`
            );
          } else {
            alert(`Test failed: ${result.data.error || 'Unknown error'}`);
          }
        } else {
          setError(result.error?.message || 'Failed to test webhook');
        }
      } catch (err) {
        setError('An error occurred while testing the webhook');
        console.error('Error testing webhook:', err);
      } finally {
        setTestingEndpointId(null);
      }
    },
    [securityContext, webhookService]
  );

  const handleRegenerateSecret = useCallback(
    async (endpointId: string) => {
      if (!securityContext) return;

      const confirmed = window.confirm(
        'Are you sure you want to regenerate the secret? The old secret will stop working immediately.'
      );
      if (!confirmed) return;

      setError(null);

      try {
        const result = await webhookService.regenerateSecret(
          securityContext,
          endpointId
        );

        if (result.success && result.data) {
          setSecretDisplay({
            endpointId,
            secret: result.data,
          });
          await loadEndpoints();
        } else {
          setError(result.error?.message || 'Failed to regenerate secret');
        }
      } catch (err) {
        setError('An error occurred while regenerating the secret');
        console.error('Error regenerating secret:', err);
      }
    },
    [securityContext, webhookService, loadEndpoints]
  );

  return (
    <div className="webhook-manager">
      {/* Header */}
      <div className="webhook-manager__header">
        <h2 className="webhook-manager__title">Webhook Endpoints</h2>
        <button
          type="button"
          className="btn btn-primary"
          onClick={() => setShowForm(!showForm)}
        >
          {showForm ? 'Cancel' : 'Add Webhook'}
        </button>
      </div>

      {/* Error Banner */}
      {error && (
        <div className="webhook-manager__error">
          <span className="webhook-manager__error-icon">⚠️</span>
          <span>{error}</span>
          <button
            type="button"
            className="webhook-manager__error-close"
            onClick={() => setError(null)}
          >
            &times;
          </button>
        </div>
      )}

      {/* Secret Display (shown only once) */}
      {secretDisplay && (
        <div className="webhook-manager__secret-display">
          <div className="webhook-manager__secret-header">
            <h3>Webhook Secret</h3>
            <button
              type="button"
              onClick={() => setSecretDisplay(null)}
              className="webhook-manager__secret-close"
            >
              &times;
            </button>
          </div>
          <p className="webhook-manager__secret-warning">
            Copy this secret now. It will not be shown again.
          </p>
          <div className="webhook-manager__secret-value">
            <code>{secretDisplay.secret}</code>
            <button
              type="button"
              className="btn btn-sm btn-ghost"
              onClick={() => {
                navigator.clipboard.writeText(secretDisplay.secret);
                alert('Secret copied to clipboard');
              }}
            >
              Copy
            </button>
          </div>
        </div>
      )}

      {/* Create Form */}
      {showForm && (
        <form onSubmit={handleSubmit} className="webhook-manager__form">
          <div className="form-group">
            <label htmlFor="webhook-name" className="form-label">
              Name *
            </label>
            <input
              id="webhook-name"
              type="text"
              className="form-input"
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              required
              disabled={isSubmitting}
            />
          </div>

          <div className="form-group">
            <label htmlFor="webhook-description" className="form-label">
              Description
            </label>
            <textarea
              id="webhook-description"
              className="form-input"
              value={formData.description}
              onChange={(e) =>
                setFormData({ ...formData, description: e.target.value })
              }
              disabled={isSubmitting}
              rows={2}
            />
          </div>

          <div className="form-group">
            <label htmlFor="webhook-url" className="form-label">
              URL * (must be HTTPS)
            </label>
            <input
              id="webhook-url"
              type="url"
              className="form-input"
              value={formData.url}
              onChange={(e) => setFormData({ ...formData, url: e.target.value })}
              placeholder="https://example.com/webhooks/crm"
              required
              disabled={isSubmitting}
            />
          </div>

          <div className="form-group">
            <label className="form-label">Events *</label>
            <div className="webhook-manager__events">
              {WEBHOOK_EVENTS.map((event) => (
                <label key={event.value} className="webhook-manager__event-checkbox">
                  <input
                    type="checkbox"
                    checked={formData.events.includes(event.value)}
                    onChange={() => handleEventToggle(event.value)}
                    disabled={isSubmitting}
                  />
                  <span>{event.label}</span>
                </label>
              ))}
            </div>
          </div>

          <div className="form-group">
            <label className="webhook-manager__checkbox-label">
              <input
                type="checkbox"
                checked={formData.retryEnabled}
                onChange={(e) =>
                  setFormData({ ...formData, retryEnabled: e.target.checked })
                }
                disabled={isSubmitting}
              />
              <span>Enable automatic retries on failure</span>
            </label>
          </div>

          {formData.retryEnabled && (
            <div className="form-group">
              <label htmlFor="webhook-max-retries" className="form-label">
                Max Retries
              </label>
              <input
                id="webhook-max-retries"
                type="number"
                className="form-input"
                value={formData.maxRetries}
                onChange={(e) =>
                  setFormData({ ...formData, maxRetries: parseInt(e.target.value) })
                }
                min={1}
                max={10}
                disabled={isSubmitting}
              />
            </div>
          )}

          <div className="webhook-manager__form-actions">
            <button
              type="submit"
              className="btn btn-primary"
              disabled={isSubmitting}
            >
              {isSubmitting ? 'Creating...' : 'Create Webhook'}
            </button>
            <button
              type="button"
              className="btn btn-ghost"
              onClick={() => setShowForm(false)}
              disabled={isSubmitting}
            >
              Cancel
            </button>
          </div>
        </form>
      )}

      {/* Endpoints List */}
      {isLoading ? (
        <div className="webhook-manager__loading">
          <div className="spinner" />
          <p>Loading webhooks...</p>
        </div>
      ) : endpoints.length === 0 ? (
        <div className="webhook-manager__empty">
          <p>No webhook endpoints configured.</p>
        </div>
      ) : (
        <div className="webhook-manager__list">
          {endpoints.map((endpoint) => (
            <div key={endpoint.id} className="webhook-manager__endpoint">
              <div className="webhook-manager__endpoint-header">
                <div>
                  <h4 className="webhook-manager__endpoint-name">{endpoint.name}</h4>
                  {endpoint.description && (
                    <p className="webhook-manager__endpoint-description">
                      {endpoint.description}
                    </p>
                  )}
                </div>
                <span
                  className={`webhook-manager__endpoint-status webhook-manager__endpoint-status--${
                    endpoint.isActive ? 'active' : 'inactive'
                  }`}
                >
                  {endpoint.isActive ? 'Active' : 'Inactive'}
                </span>
              </div>

              <div className="webhook-manager__endpoint-details">
                <div className="webhook-manager__endpoint-field">
                  <span className="webhook-manager__endpoint-label">URL:</span>
                  <code className="webhook-manager__endpoint-value">
                    {endpoint.url}
                  </code>
                </div>

                <div className="webhook-manager__endpoint-field">
                  <span className="webhook-manager__endpoint-label">Events:</span>
                  <div className="webhook-manager__endpoint-tags">
                    {endpoint.events.map((event) => (
                      <span key={event} className="webhook-manager__endpoint-tag">
                        {event}
                      </span>
                    ))}
                  </div>
                </div>

                <div className="webhook-manager__endpoint-field">
                  <span className="webhook-manager__endpoint-label">
                    Last Triggered:
                  </span>
                  <span className="webhook-manager__endpoint-value">
                    {endpoint.lastTriggeredAt
                      ? new Date(endpoint.lastTriggeredAt).toLocaleString()
                      : 'Never'}
                  </span>
                </div>

                {endpoint.failureCount > 0 && (
                  <div className="webhook-manager__endpoint-field webhook-manager__endpoint-field--error">
                    <span className="webhook-manager__endpoint-label">Failures:</span>
                    <span className="webhook-manager__endpoint-value">
                      {endpoint.failureCount} (Last:{' '}
                      {endpoint.lastFailureAt
                        ? new Date(endpoint.lastFailureAt).toLocaleString()
                        : 'N/A'}
                      )
                    </span>
                  </div>
                )}
              </div>

              <div className="webhook-manager__endpoint-actions">
                <button
                  type="button"
                  className="btn btn-sm btn-ghost"
                  onClick={() => handleTest(endpoint.id)}
                  disabled={testingEndpointId === endpoint.id}
                >
                  {testingEndpointId === endpoint.id ? 'Testing...' : 'Test'}
                </button>
                <button
                  type="button"
                  className="btn btn-sm btn-ghost"
                  onClick={() => handleRegenerateSecret(endpoint.id)}
                >
                  Regenerate Secret
                </button>
                <button
                  type="button"
                  className="btn btn-sm btn-danger"
                  onClick={() => handleDelete(endpoint.id)}
                >
                  Delete
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
