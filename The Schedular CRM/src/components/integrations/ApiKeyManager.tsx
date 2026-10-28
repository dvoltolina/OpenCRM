/**
 * ApiKeyManager Component
 * CRUD interface for API key management with scope selection
 *
 * HIPAA Compliance:
 * - Full API keys shown only once on creation
 * - Only keyPrefix displayed in list
 * - No PHI in any field
 *
 * Security:
 * - Keys hashed with SHA-256
 * - Scope-based access control
 * - Rate limiting configuration
 * - Only admin/owner can manage keys
 *
 * Task 10: API Integrations UI Components
 */

import { useState, useEffect, useCallback, useMemo } from 'react';
import { getApiKeyService } from '../../services/api-key-service';
import type { ApiKey, ApiScope } from '../../types/integrations';

// ============================================
// Types
// ============================================

interface ApiKeyManagerProps {
  securityContext: any;
  onUpdate?: () => void;
}

interface KeyDisplay {
  keyId: string;
  fullKey: string;
}

// ============================================
// Constants
// ============================================

const API_SCOPES: { value: ApiScope; label: string; description: string }[] = [
  { value: 'leads:read', label: 'Read Leads', description: 'View lead data' },
  { value: 'leads:write', label: 'Write Leads', description: 'Create/update leads' },
  { value: 'deals:read', label: 'Read Deals', description: 'View deal data' },
  { value: 'deals:write', label: 'Write Deals', description: 'Create/update deals' },
  { value: 'contacts:read', label: 'Read Contacts', description: 'View contact data' },
  { value: 'contacts:write', label: 'Write Contacts', description: 'Create/update contacts' },
  { value: 'tasks:read', label: 'Read Tasks', description: 'View task data' },
  { value: 'tasks:write', label: 'Write Tasks', description: 'Create/update tasks' },
  { value: 'activities:read', label: 'Read Activities', description: 'View activity data' },
  { value: 'sequences:read', label: 'Read Sequences', description: 'View sequence data' },
  { value: 'sequences:write', label: 'Write Sequences', description: 'Manage sequences' },
  { value: 'webhooks:manage', label: 'Manage Webhooks', description: 'Configure webhooks' },
];

// ============================================
// Component
// ============================================

export function ApiKeyManager({ securityContext, onUpdate }: ApiKeyManagerProps) {
  const apiKeyService = useMemo(() => getApiKeyService(), []);

  const [keys, setKeys] = useState<ApiKey[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [keyDisplay, setKeyDisplay] = useState<KeyDisplay | null>(null);

  const [formData, setFormData] = useState({
    name: '',
    description: '',
    scopes: [] as ApiScope[],
    rateLimit: 60,
    expiresAt: '',
  });

  // Load keys
  const loadKeys = useCallback(async () => {
    if (!securityContext) return;

    setIsLoading(true);
    setError(null);

    try {
      const result = await apiKeyService.getKeys(securityContext);
      if (result.success && result.data) {
        setKeys(result.data);
      } else {
        setError('Failed to load API keys');
      }
    } catch (err) {
      setError('An error occurred while loading API keys');
      console.error('Error loading keys:', err);
    } finally {
      setIsLoading(false);
    }
  }, [securityContext, apiKeyService]);

  useEffect(() => {
    loadKeys();
  }, [loadKeys]);

  // Handle form submit
  const handleSubmit = useCallback(
    async (e: React.FormEvent) => {
      e.preventDefault();

      if (!securityContext) return;

      if (formData.scopes.length === 0) {
        setError('Please select at least one scope');
        return;
      }

      setIsSubmitting(true);
      setError(null);

      try {
        const result = await apiKeyService.createKey(securityContext, {
          name: formData.name,
          description: formData.description || undefined,
          scopes: formData.scopes,
          rateLimit: formData.rateLimit,
          expiresAt: formData.expiresAt ? new Date(formData.expiresAt) : undefined,
        });

        if (result.success && result.data) {
          // Show full key (only shown once)
          setKeyDisplay({
            keyId: result.data.key.id,
            fullKey: result.data.fullKey,
          });

          // Reset form
          setFormData({
            name: '',
            description: '',
            scopes: [],
            rateLimit: 60,
            expiresAt: '',
          });
          setShowForm(false);

          await loadKeys();
          if (onUpdate) onUpdate();
        } else {
          setError(result.error?.message || 'Failed to create API key');
        }
      } catch (err) {
        setError('An error occurred while creating the API key');
        console.error('Error creating key:', err);
      } finally {
        setIsSubmitting(false);
      }
    },
    [securityContext, formData, apiKeyService, loadKeys, onUpdate]
  );

  const handleScopeToggle = useCallback((scope: ApiScope) => {
    setFormData((prev) => ({
      ...prev,
      scopes: prev.scopes.includes(scope)
        ? prev.scopes.filter((s) => s !== scope)
        : [...prev.scopes, scope],
    }));
  }, []);

  const handleRevoke = useCallback(
    async (keyId: string) => {
      if (!securityContext) return;

      const confirmed = window.confirm(
        'Are you sure you want to revoke this API key? This action cannot be undone.'
      );
      if (!confirmed) return;

      setError(null);

      try {
        const result = await apiKeyService.revokeKey(securityContext, keyId);

        if (result.success) {
          await loadKeys();
          if (onUpdate) onUpdate();
        } else {
          setError(result.error?.message || 'Failed to revoke API key');
        }
      } catch (err) {
        setError('An error occurred while revoking the API key');
        console.error('Error revoking key:', err);
      }
    },
    [securityContext, apiKeyService, loadKeys, onUpdate]
  );

  return (
    <div className="api-key-manager">
      <div className="api-key-manager__header">
        <h2 className="api-key-manager__title">API Keys</h2>
        <button
          type="button"
          className="btn btn-primary"
          onClick={() => setShowForm(!showForm)}
        >
          {showForm ? 'Cancel' : 'Create API Key'}
        </button>
      </div>

      {error && (
        <div className="api-key-manager__error">
          <span>⚠️</span>
          <span>{error}</span>
          <button type="button" onClick={() => setError(null)}>
            &times;
          </button>
        </div>
      )}

      {keyDisplay && (
        <div className="api-key-manager__key-display">
          <h3>API Key Created</h3>
          <p className="api-key-manager__key-warning">
            Copy this key now. It will not be shown again.
          </p>
          <div className="api-key-manager__key-value">
            <code>{keyDisplay.fullKey}</code>
            <button
              type="button"
              className="btn btn-sm btn-ghost"
              onClick={() => {
                navigator.clipboard.writeText(keyDisplay.fullKey);
                alert('API key copied to clipboard');
              }}
            >
              Copy
            </button>
          </div>
          <button
            type="button"
            className="btn btn-primary"
            onClick={() => setKeyDisplay(null)}
          >
            Done
          </button>
        </div>
      )}

      {showForm && (
        <form onSubmit={handleSubmit} className="api-key-manager__form">
          <div className="form-group">
            <label htmlFor="key-name" className="form-label">
              Name *
            </label>
            <input
              id="key-name"
              type="text"
              className="form-input"
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              required
              disabled={isSubmitting}
            />
          </div>

          <div className="form-group">
            <label htmlFor="key-description" className="form-label">
              Description
            </label>
            <textarea
              id="key-description"
              className="form-input"
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              disabled={isSubmitting}
              rows={2}
            />
          </div>

          <div className="form-group">
            <label className="form-label">Scopes *</label>
            <div className="api-key-manager__scopes">
              {API_SCOPES.map((scope) => (
                <label key={scope.value} className="api-key-manager__scope-checkbox">
                  <input
                    type="checkbox"
                    checked={formData.scopes.includes(scope.value)}
                    onChange={() => handleScopeToggle(scope.value)}
                    disabled={isSubmitting}
                  />
                  <div>
                    <div className="api-key-manager__scope-label">{scope.label}</div>
                    <div className="api-key-manager__scope-description">
                      {scope.description}
                    </div>
                  </div>
                </label>
              ))}
            </div>
          </div>

          <div className="form-group">
            <label htmlFor="key-rate-limit" className="form-label">
              Rate Limit (requests per minute)
            </label>
            <input
              id="key-rate-limit"
              type="number"
              className="form-input"
              value={formData.rateLimit}
              onChange={(e) =>
                setFormData({ ...formData, rateLimit: parseInt(e.target.value) })
              }
              min={1}
              max={1000}
              disabled={isSubmitting}
            />
          </div>

          <div className="form-group">
            <label htmlFor="key-expires" className="form-label">
              Expires At (optional)
            </label>
            <input
              id="key-expires"
              type="datetime-local"
              className="form-input"
              value={formData.expiresAt}
              onChange={(e) => setFormData({ ...formData, expiresAt: e.target.value })}
              disabled={isSubmitting}
            />
          </div>

          <div className="api-key-manager__form-actions">
            <button type="submit" className="btn btn-primary" disabled={isSubmitting}>
              {isSubmitting ? 'Creating...' : 'Create API Key'}
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

      {isLoading ? (
        <div className="api-key-manager__loading">
          <div className="spinner" />
          <p>Loading API keys...</p>
        </div>
      ) : keys.length === 0 ? (
        <div className="api-key-manager__empty">
          <p>No API keys created yet.</p>
        </div>
      ) : (
        <div className="api-key-manager__list">
          {keys.map((key) => (
            <div key={key.id} className="api-key-manager__key">
              <div className="api-key-manager__key-header">
                <div>
                  <h4 className="api-key-manager__key-name">{key.name}</h4>
                  {key.description && (
                    <p className="api-key-manager__key-description">{key.description}</p>
                  )}
                </div>
                <span
                  className={`api-key-manager__key-status api-key-manager__key-status--${
                    key.isActive ? 'active' : 'inactive'
                  }`}
                >
                  {key.isActive ? 'Active' : 'Revoked'}
                </span>
              </div>

              <div className="api-key-manager__key-details">
                <div className="api-key-manager__key-field">
                  <span className="api-key-manager__key-label">Key:</span>
                  <code className="api-key-manager__key-value">{key.keyPrefix}...</code>
                </div>

                <div className="api-key-manager__key-field">
                  <span className="api-key-manager__key-label">Scopes:</span>
                  <div className="api-key-manager__key-tags">
                    {key.scopes.map((scope) => (
                      <span key={scope} className="api-key-manager__key-tag">
                        {scope}
                      </span>
                    ))}
                  </div>
                </div>

                <div className="api-key-manager__key-field">
                  <span className="api-key-manager__key-label">Rate Limit:</span>
                  <span className="api-key-manager__key-value">
                    {key.rateLimit} requests/{key.rateLimitWindow}s
                  </span>
                </div>

                <div className="api-key-manager__key-field">
                  <span className="api-key-manager__key-label">Usage:</span>
                  <span className="api-key-manager__key-value">
                    {key.usageCount} requests
                    {key.lastUsedAt && ` (Last: ${new Date(key.lastUsedAt).toLocaleString()})`}
                  </span>
                </div>

                {key.expiresAt && (
                  <div className="api-key-manager__key-field">
                    <span className="api-key-manager__key-label">Expires:</span>
                    <span className="api-key-manager__key-value">
                      {new Date(key.expiresAt).toLocaleString()}
                    </span>
                  </div>
                )}
              </div>

              {key.isActive && (
                <div className="api-key-manager__key-actions">
                  <button
                    type="button"
                    className="btn btn-sm btn-danger"
                    onClick={() => handleRevoke(key.id)}
                  >
                    Revoke
                  </button>
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
