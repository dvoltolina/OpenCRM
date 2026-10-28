/**
 * IntegrationCard Component
 * Displays integration status with connect/disconnect actions.
 *
 * HIPAA Compliance:
 * - No PHI displayed
 * - Error messages sanitized (no internal details)
 *
 * Security:
 * - RBAC enforced at parent level
 * - Disconnect requires confirmation
 *
 * Agent CRM - API Integrations Task 10 Implementation
 */

import { useState, useCallback, useMemo } from 'react';
import { useAuth } from '../../context/AuthContext';
import { getIntegrationRepository } from '../../data/repositories/integration-repository';
import type { Integration } from '../../types/integrations';
import type { SecurityContext } from '../../data/repositories/repository-types';

// ============================================
// Types
// ============================================

interface IntegrationCardProps {
  integration: Integration;
  onRefresh: () => void;
}

// ============================================
// Component
// ============================================

/**
 * IntegrationCard - Display integration status
 *
 * Features:
 * - Shows integration name, provider, and status
 * - Displays last sync time
 * - Shows error messages when status is 'error'
 * - Connect/Disconnect actions
 *
 * @example
 * ```tsx
 * <IntegrationCard
 *   integration={integration}
 *   onRefresh={handleRefresh}
 * />
 * ```
 */
export function IntegrationCard({ integration, onRefresh }: IntegrationCardProps) {
  const { crmUser, businessId } = useAuth();
  const integrationRepo = useMemo(() => getIntegrationRepository(), []);

  const securityContext: SecurityContext | null = useMemo(() => {
    if (!crmUser || !businessId) return null;
    return {
      userId: crmUser.id,
      businessId,
      userName: crmUser.displayName || crmUser.email || crmUser.id,
      userRole: crmUser.role || 'staff',
      teamIds: crmUser.teamIds,
      managedTeamIds: crmUser.managedTeamIds,
      managerId: crmUser.managerId,
    };
  }, [crmUser, businessId]);

  const [isDisconnecting, setIsDisconnecting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Format last sync time
  const lastSyncText = useMemo(() => {
    if (!integration.lastSyncAt) return 'Never synced';

    const now = new Date();
    const syncDate = integration.lastSyncAt instanceof Date
      ? integration.lastSyncAt
      : new Date(integration.lastSyncAt);
    const diffMs = now.getTime() - syncDate.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    const diffDays = Math.floor(diffMs / 86400000);

    if (diffMins < 1) return 'Just now';
    if (diffMins < 60) return `${diffMins}m ago`;
    if (diffHours < 24) return `${diffHours}h ago`;
    if (diffDays === 1) return 'Yesterday';
    return `${diffDays} days ago`;
  }, [integration.lastSyncAt]);

  // Status badge styling
  const statusClass = useMemo(() => {
    switch (integration.status) {
      case 'active':
        return 'integration-card__status--active';
      case 'error':
        return 'integration-card__status--error';
      case 'inactive':
        return 'integration-card__status--inactive';
      case 'pending_auth':
        return 'integration-card__status--pending';
      default:
        return '';
    }
  }, [integration.status]);

  // Handlers
  const handleDisconnect = useCallback(async () => {
    if (!securityContext) return;

    const confirmed = window.confirm(
      `Are you sure you want to disconnect ${integration.name}?`
    );
    if (!confirmed) return;

    setIsDisconnecting(true);
    setError(null);

    try {
      const result = await integrationRepo.delete(securityContext, integration.id);
      if (result.success) {
        onRefresh();
      } else {
        setError('Failed to disconnect integration');
      }
    } catch (err) {
      setError('An error occurred while disconnecting');
      console.error('Error disconnecting:', err);
    } finally {
      setIsDisconnecting(false);
    }
  }, [securityContext, integrationRepo, integration, onRefresh]);

  const handleReconnect = useCallback(() => {
    // TODO: Implement reconnect flow (OAuth, etc.)
    alert('Reconnect flow not yet implemented');
  }, []);

  return (
    <div className="integration-card">
      {/* Header */}
      <div className="integration-card__header">
        <div className="integration-card__title-row">
          <h3 className="integration-card__name">{integration.name}</h3>
          <span className={`integration-card__status ${statusClass}`}>
            {integration.status === 'active' && '✓ Active'}
            {integration.status === 'error' && '⚠️ Error'}
            {integration.status === 'inactive' && 'Inactive'}
            {integration.status === 'pending_auth' && 'Pending Auth'}
          </span>
        </div>
        {integration.description && (
          <p className="integration-card__description">{integration.description}</p>
        )}
      </div>

      {/* Body */}
      <div className="integration-card__body">
        {/* Provider */}
        {integration.provider && (
          <div className="integration-card__field">
            <span className="integration-card__label">Provider:</span>
            <span className="integration-card__value">{integration.provider}</span>
          </div>
        )}

        {/* Last Sync */}
        <div className="integration-card__field">
          <span className="integration-card__label">Last Sync:</span>
          <span className="integration-card__value">{lastSyncText}</span>
        </div>

        {/* Error Message */}
        {integration.status === 'error' && integration.lastErrorMessage && (
          <div className="integration-card__error">
            <span className="integration-card__error-icon">⚠️</span>
            <span className="integration-card__error-message">
              {integration.lastErrorMessage}
            </span>
          </div>
        )}

        {/* Local Error */}
        {error && (
          <div className="integration-card__error">
            <span className="integration-card__error-icon">⚠️</span>
            <span className="integration-card__error-message">{error}</span>
          </div>
        )}
      </div>

      {/* Footer */}
      <div className="integration-card__footer">
        {integration.status === 'error' ? (
          <button
            type="button"
            className="btn btn-primary btn-sm"
            onClick={handleReconnect}
            disabled={isDisconnecting}
          >
            Reconnect
          </button>
        ) : (
          <button
            type="button"
            className="btn btn-ghost btn-sm"
            onClick={handleDisconnect}
            disabled={isDisconnecting}
          >
            {isDisconnecting ? 'Disconnecting...' : 'Disconnect'}
          </button>
        )}
      </div>
    </div>
  );
}
