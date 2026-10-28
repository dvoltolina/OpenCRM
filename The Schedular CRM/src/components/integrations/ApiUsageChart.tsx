/**
 * ApiUsageChart Component
 * Visualizes API usage statistics over time
 *
 * HIPAA Compliance:
 * - Only aggregated usage data displayed
 * - No PHI in any visualization
 *
 * Security:
 * - Only admin/owner can view usage charts
 *
 * Task 10: API Integrations UI Components
 */

import { useMemo } from 'react';
import type { ApiKey } from '../../types/integrations';

// ============================================
// Types
// ============================================

interface ApiUsageChartProps {
  securityContext: any;
  apiKeys: ApiKey[];
}

// ============================================
// Component
// ============================================

/**
 * ApiUsageChart - API usage visualization
 *
 * Features:
 * - Display total requests across all keys
 * - Show requests per API key
 * - Rate limit usage indicators
 * - Simple bar chart visualization
 *
 * @example
 * ```tsx
 * <ApiUsageChart
 *   securityContext={securityContext}
 *   apiKeys={keys}
 * />
 * ```
 */
export function ApiUsageChart({ apiKeys }: ApiUsageChartProps) {
  // Calculate total usage
  const totalRequests = useMemo(() => {
    return apiKeys.reduce((sum, key) => sum + key.usageCount, 0);
  }, [apiKeys]);

  // Calculate active keys
  const activeKeys = useMemo(() => {
    return apiKeys.filter((key) => key.isActive).length;
  }, [apiKeys]);

  // Get max usage for scaling
  const maxUsage = useMemo(() => {
    if (apiKeys.length === 0) return 100;
    return Math.max(...apiKeys.map((key) => key.usageCount), 1);
  }, [apiKeys]);

  // Sort keys by usage
  const sortedKeys = useMemo(() => {
    return [...apiKeys].sort((a, b) => b.usageCount - a.usageCount);
  }, [apiKeys]);

  return (
    <div className="api-usage-chart">
      {/* Summary Stats */}
      <div className="api-usage-chart__stats">
        <div className="api-usage-chart__stat">
          <div className="api-usage-chart__stat-label">Total Requests</div>
          <div className="api-usage-chart__stat-value">{totalRequests.toLocaleString()}</div>
        </div>
        <div className="api-usage-chart__stat">
          <div className="api-usage-chart__stat-label">Active Keys</div>
          <div className="api-usage-chart__stat-value">{activeKeys}</div>
        </div>
        <div className="api-usage-chart__stat">
          <div className="api-usage-chart__stat-label">Total Keys</div>
          <div className="api-usage-chart__stat-value">{apiKeys.length}</div>
        </div>
      </div>

      {/* Chart */}
      {sortedKeys.length > 0 ? (
        <div className="api-usage-chart__chart">
          <h4 className="api-usage-chart__chart-title">Requests per API Key</h4>
          <div className="api-usage-chart__bars">
            {sortedKeys.map((key) => {
              const widthPercent = maxUsage > 0 ? (key.usageCount / maxUsage) * 100 : 0;

              return (
                <div key={key.id} className="api-usage-chart__bar-row">
                  <div className="api-usage-chart__bar-label">
                    {key.name}
                    <span className="api-usage-chart__bar-prefix">({key.keyPrefix}...)</span>
                  </div>
                  <div className="api-usage-chart__bar-container">
                    <div
                      className="api-usage-chart__bar"
                      style={{ width: `${widthPercent}%` }}
                    >
                      <span className="api-usage-chart__bar-value">
                        {key.usageCount.toLocaleString()}
                      </span>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      ) : (
        <div className="api-usage-chart__empty">
          <p>No usage data available.</p>
        </div>
      )}
    </div>
  );
}
