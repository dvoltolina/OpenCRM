/**
 * WebhookDeliveryLog Component
 * Displays recent webhook delivery attempts with status and retry options
 *
 * HIPAA Compliance:
 * - Payloads displayed are sanitized (no PHI)
 * - Response bodies truncated and sanitized
 * - Only metadata shown for audit purposes
 *
 * Security:
 * - Only admin/owner can view delivery logs
 * - Retry requires confirmation
 *
 * Task 10: API Integrations UI Components
 */

import { useState, useEffect, useCallback, useMemo } from 'react';
import { getWebhookEndpointService } from '../../services/webhook-endpoint-service';
import type { WebhookEndpoint, WebhookDelivery } from '../../types/integrations';

// ============================================
// Types
// ============================================

interface WebhookDeliveryLogProps {
  securityContext: any;
  webhookEndpoints: WebhookEndpoint[];
}

// ============================================
// Component
// ============================================

/**
 * WebhookDeliveryLog - Webhook delivery history
 *
 * Features:
 * - List recent deliveries for all endpoints
 * - Filter by endpoint or status
 * - Show delivery details (status, response time, etc.)
 * - Retry failed deliveries
 * - Display response codes and error messages
 *
 * @example
 * ```tsx
 * <WebhookDeliveryLog
 *   securityContext={securityContext}
 *   webhookEndpoints={endpoints}
 * />
 * ```
 */
export function WebhookDeliveryLog({
  securityContext,
  webhookEndpoints,
}: WebhookDeliveryLogProps) {
  const webhookService = useMemo(() => getWebhookEndpointService(), []);

  const [deliveries, setDeliveries] = useState<WebhookDelivery[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedEndpoint, setSelectedEndpoint] = useState<string>('all');
  const [selectedStatus, setSelectedStatus] = useState<string>('all');
  const [retryingId, setRetryingId] = useState<string | null>(null);

  // Load deliveries
  const loadDeliveries = useCallback(async () => {
    if (!securityContext || webhookEndpoints.length === 0) {
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      // Load deliveries for all endpoints (or selected endpoint)
      const endpointsToLoad =
        selectedEndpoint === 'all'
          ? webhookEndpoints
          : webhookEndpoints.filter((e) => e.id === selectedEndpoint);

      const deliveryResults = await Promise.all(
        endpointsToLoad.map((endpoint) =>
          webhookService.getDeliveries(securityContext, endpoint.id, { limit: 10 })
        )
      );

      // Combine and sort by date
      const allDeliveries: WebhookDelivery[] = [];
      deliveryResults.forEach((result) => {
        if (result.success && result.data) {
          allDeliveries.push(...result.data.data);
        }
      });

      allDeliveries.sort((a, b) => {
        const aTime = a.createdAt instanceof Date ? a.createdAt.getTime() : new Date(a.createdAt).getTime();
        const bTime = b.createdAt instanceof Date ? b.createdAt.getTime() : new Date(b.createdAt).getTime();
        return bTime - aTime;
      });

      setDeliveries(allDeliveries);
    } catch (err) {
      setError('An error occurred while loading delivery logs');
      console.error('Error loading deliveries:', err);
    } finally {
      setIsLoading(false);
    }
  }, [securityContext, webhookEndpoints, selectedEndpoint, webhookService]);

  useEffect(() => {
    loadDeliveries();
  }, [loadDeliveries]);

  // Filter deliveries by status
  const filteredDeliveries = useMemo(() => {
    if (selectedStatus === 'all') return deliveries;
    return deliveries.filter((d) => d.status === selectedStatus);
  }, [deliveries, selectedStatus]);

  // Get endpoint name by ID
  const getEndpointName = useCallback(
    (webhookId: string) => {
      const endpoint = webhookEndpoints.find((e) => e.id === webhookId);
      return endpoint?.name || 'Unknown';
    },
    [webhookEndpoints]
  );

  // Handle retry
  const handleRetry = useCallback(
    async (deliveryId: string) => {
      if (!securityContext) return;

      const confirmed = window.confirm(
        'Retry this webhook delivery?'
      );
      if (!confirmed) return;

      setRetryingId(deliveryId);
      setError(null);

      try {
        const result = await webhookService.retryDelivery(securityContext, deliveryId);

        if (result.success) {
          // Reload deliveries
          await loadDeliveries();
        } else {
          setError(result.error?.message || 'Failed to retry delivery');
        }
      } catch (err) {
        setError('An error occurred while retrying the delivery');
        console.error('Error retrying delivery:', err);
      } finally {
        setRetryingId(null);
      }
    },
    [securityContext, webhookService, loadDeliveries]
  );

  return (
    <div className="webhook-delivery-log">
      {/* Header with Filters */}
      <div className="webhook-delivery-log__header">
        <h3 className="webhook-delivery-log__title">Recent Deliveries</h3>

        <div className="webhook-delivery-log__filters">
          <div className="webhook-delivery-log__filter-group">
            <label htmlFor="endpoint-filter" className="webhook-delivery-log__filter-label">
              Endpoint:
            </label>
            <select
              id="endpoint-filter"
              className="webhook-delivery-log__filter-select"
              value={selectedEndpoint}
              onChange={(e) => setSelectedEndpoint(e.target.value)}
            >
              <option value="all">All Endpoints</option>
              {webhookEndpoints.map((endpoint) => (
                <option key={endpoint.id} value={endpoint.id}>
                  {endpoint.name}
                </option>
              ))}
            </select>
          </div>

          <div className="webhook-delivery-log__filter-group">
            <label htmlFor="status-filter" className="webhook-delivery-log__filter-label">
              Status:
            </label>
            <select
              id="status-filter"
              className="webhook-delivery-log__filter-select"
              value={selectedStatus}
              onChange={(e) => setSelectedStatus(e.target.value)}
            >
              <option value="all">All Statuses</option>
              <option value="pending">Pending</option>
              <option value="success">Success</option>
              <option value="failed">Failed</option>
              <option value="retrying">Retrying</option>
            </select>
          </div>

          <button
            type="button"
            className="btn btn-sm btn-ghost"
            onClick={loadDeliveries}
            disabled={isLoading}
          >
            Refresh
          </button>
        </div>
      </div>

      {/* Error Banner */}
      {error && (
        <div className="webhook-delivery-log__error">
          <span className="webhook-delivery-log__error-icon">⚠️</span>
          <span>{error}</span>
          <button
            type="button"
            className="webhook-delivery-log__error-close"
            onClick={() => setError(null)}
          >
            &times;
          </button>
        </div>
      )}

      {/* Deliveries Table */}
      {isLoading ? (
        <div className="webhook-delivery-log__loading">
          <div className="spinner" />
          <p>Loading deliveries...</p>
        </div>
      ) : filteredDeliveries.length === 0 ? (
        <div className="webhook-delivery-log__empty">
          <p>No deliveries found.</p>
        </div>
      ) : (
        <div className="webhook-delivery-log__table-container">
          <table className="webhook-delivery-log__table">
            <thead>
              <tr>
                <th>Endpoint</th>
                <th>Event</th>
                <th>Status</th>
                <th>Response</th>
                <th>Time</th>
                <th>Attempts</th>
                <th>Created</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredDeliveries.map((delivery) => (
                <tr key={delivery.id}>
                  <td className="webhook-delivery-log__endpoint">
                    {getEndpointName(delivery.webhookId)}
                  </td>
                  <td className="webhook-delivery-log__event">
                    <code>{delivery.event}</code>
                  </td>
                  <td>
                    <span
                      className={`webhook-delivery-log__status webhook-delivery-log__status--${delivery.status}`}
                    >
                      {delivery.status}
                    </span>
                  </td>
                  <td className="webhook-delivery-log__response">
                    {delivery.responseStatus ? (
                      <span
                        className={`webhook-delivery-log__response-code ${
                          delivery.responseStatus >= 200 && delivery.responseStatus < 300
                            ? 'webhook-delivery-log__response-code--success'
                            : 'webhook-delivery-log__response-code--error'
                        }`}
                      >
                        {delivery.responseStatus}
                      </span>
                    ) : (
                      '-'
                    )}
                  </td>
                  <td className="webhook-delivery-log__time">
                    {delivery.responseTimeMs
                      ? `${delivery.responseTimeMs}ms`
                      : '-'}
                  </td>
                  <td className="webhook-delivery-log__attempts">
                    {delivery.attemptCount}
                  </td>
                  <td className="webhook-delivery-log__created">
                    {new Date(delivery.createdAt).toLocaleString()}
                  </td>
                  <td className="webhook-delivery-log__actions">
                    {delivery.status === 'failed' && (
                      <button
                        type="button"
                        className="btn btn-sm btn-ghost"
                        onClick={() => handleRetry(delivery.id)}
                        disabled={retryingId === delivery.id}
                      >
                        {retryingId === delivery.id ? 'Retrying...' : 'Retry'}
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
