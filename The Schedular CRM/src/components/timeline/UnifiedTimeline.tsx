/**
 * UnifiedTimeline Component
 * Enhanced timeline with filtering and pagination
 *
 * Agent CRM-26 Implementation
 * Dependencies: CRM-13 (activity service)
 */

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../../context/AuthContext';
import { getActivityService, type EntityType } from '../../services/activity-service';
import { createSecurityContext } from '../../lib/security-context';
import type { SalesActivity, SalesActivityType } from '../../types/models';
import '../details/details.css';
import './timeline.css';

// ============================================
// Types
// ============================================

export interface UnifiedTimelineProps {
  /** Entity type to show timeline for */
  entityType?: EntityType;
  /** Entity ID */
  entityId?: string;
  /** Unified timeline params (alternative to entityType/entityId) */
  params?: {
    dealId?: string;
    clientId?: string;
    companyId?: string;
    leadId?: string;
  };
  /** Callback when activity is clicked */
  onActivityClick?: (activity: SalesActivity) => void;
  /** Callback to log new activity */
  onLogActivity?: () => void;
  /** Empty message when no activities */
  emptyMessage?: string;
  /** Enable activity type filtering */
  enableFiltering?: boolean;
  /** Enable pagination/infinite scroll */
  enablePagination?: boolean;
  /** Items per page */
  pageSize?: number;
}

// ============================================
// Helpers
// ============================================

function getActivityIcon(type: SalesActivityType): string {
  const icons = {
    call: '📞',
    email: '📧',
    meeting: '📅',
    note: '📝',
    task: '✓',
  };
  return icons[type] || '•';
}

function formatRelativeTime(date: Date): string {
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);

  if (diffMins < 1) return 'Just now';
  if (diffMins < 60) return `${diffMins}m ago`;
  if (diffHours < 24) return `${diffHours}h ago`;
  if (diffDays < 7) return `${diffDays}d ago`;

  return date.toLocaleDateString();
}

// ============================================
// Component
// ============================================

/**
 * UnifiedTimeline - Enhanced activity timeline
 *
 * Features:
 * - Activity type filtering
 * - Infinite scroll / pagination
 * - Task completion toggle
 * - Unified timeline across multiple entities
 *
 * @example
 * ```tsx
 * // Single entity timeline
 * <UnifiedTimeline
 *   entityType="deal"
 *   entityId={dealId}
 *   enableFiltering
 *   enablePagination
 * />
 *
 * // Unified timeline for deal and client
 * <UnifiedTimeline
 *   params={{ dealId, clientId }}
 *   enableFiltering
 * />
 * ```
 */
export function UnifiedTimeline({
  entityType,
  entityId,
  params,
  onActivityClick,
  onLogActivity,
  emptyMessage = 'No activity yet',
  enableFiltering = true,
  enablePagination = true,
  pageSize = 20,
}: UnifiedTimelineProps) {
  const { crmUser, businessId } = useAuth();
  const [activities, setActivities] = useState<SalesActivity[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedType, setSelectedType] = useState<SalesActivityType | 'all'>('all');
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(false);
  const [isLoadingMore, setIsLoadingMore] = useState(false);

  // Get security context
  const getContext = useCallback(() => {
    if (!businessId || !crmUser) {
      throw new Error('User not authenticated');
    }
    return createSecurityContext(crmUser);
  }, [businessId, crmUser]);

  // Fetch activities
  const fetchActivities = useCallback(
    async (loadMore: boolean = false) => {
      if (!businessId || !crmUser) {
        setActivities([]);
        setIsLoading(false);
        return;
      }

      if (loadMore) {
        setIsLoadingMore(true);
      } else {
        setIsLoading(true);
      }
      setError(null);

      try {
        const context = getContext();
        const activityService = getActivityService();

        let result;
        const limit = loadMore ? pageSize : pageSize * page;

        if (params) {
          // Unified timeline across multiple entities
          result = await activityService.getUnifiedTimeline(context, params, limit);
        } else if (entityType && entityId) {
          // Single entity timeline
          result = await activityService.getEntityTimeline(context, entityType, entityId, limit);
        } else {
          throw new Error('Either params or entityType/entityId must be provided');
        }

        if (result.success) {
          const newActivities = result.data || [];
          setActivities(newActivities);
          setHasMore(newActivities.length >= limit);
        } else {
          setError(result.error?.message || 'Failed to load activities');
          setActivities([]);
        }
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to load activities');
        setActivities([]);
      } finally {
        if (loadMore) {
          setIsLoadingMore(false);
        } else {
          setIsLoading(false);
        }
      }
    },
    [businessId, crmUser, getContext, entityType, entityId, params, pageSize, page]
  );

  // Initial fetch
  useEffect(() => {
    fetchActivities(false);
  }, [fetchActivities]);

  // Load more handler
  const handleLoadMore = () => {
    if (!isLoadingMore && hasMore) {
      setPage((prev) => prev + 1);
      fetchActivities(true);
    }
  };

  // Filter activities by type
  const filteredActivities =
    selectedType === 'all'
      ? activities
      : activities.filter((activity) => activity.type === selectedType);

  // Activity type options
  const activityTypes: Array<{ value: SalesActivityType | 'all'; label: string }> = [
    { value: 'all', label: 'All Activities' },
    { value: 'call', label: 'Calls' },
    { value: 'email', label: 'Emails' },
    { value: 'meeting', label: 'Meetings' },
    { value: 'note', label: 'Notes' },
    { value: 'task', label: 'Tasks' },
  ];

  if (isLoading) {
    return (
      <div className="unified-timeline">
        <div className="unified-timeline__loading">Loading activities...</div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="unified-timeline">
        <div className="unified-timeline__error">{error}</div>
      </div>
    );
  }

  return (
    <div className="unified-timeline">
      <div className="unified-timeline__header">
        {enableFiltering && (
          <div className="unified-timeline__filters">
            <select
              className="unified-timeline__filter-select"
              value={selectedType}
              onChange={(e) => setSelectedType(e.target.value as SalesActivityType | 'all')}
            >
              {activityTypes.map((type) => (
                <option key={type.value} value={type.value}>
                  {type.label}
                </option>
              ))}
            </select>
          </div>
        )}
        {onLogActivity && (
          <button type="button" className="btn btn--primary btn--sm" onClick={onLogActivity}>
            Log Activity
          </button>
        )}
      </div>

      {filteredActivities.length === 0 ? (
        <div className="unified-timeline__empty">
          <p>{emptyMessage}</p>
          {onLogActivity && (
            <button type="button" className="btn btn--secondary btn--sm" onClick={onLogActivity}>
              Log First Activity
            </button>
          )}
        </div>
      ) : (
        <>
          <div className="unified-timeline__items">
            {filteredActivities.map((activity) => (
              <div
                key={activity.id}
                className={`activity-item ${onActivityClick ? 'activity-item--clickable' : ''} ${
                  activity.type === 'task' && !activity.isCompleted ? 'activity-item--task-pending' : ''
                }`}
                onClick={() => onActivityClick?.(activity)}
                role={onActivityClick ? 'button' : undefined}
                tabIndex={onActivityClick ? 0 : undefined}
              >
                <div className="activity-item__icon">
                  {activity.type === 'task' ? (
                    <input
                      type="checkbox"
                      className="activity-item__checkbox"
                      checked={activity.isCompleted}
                      readOnly
                      aria-label={`Task "${activity.title}" is ${activity.isCompleted ? 'complete' : 'incomplete'}`}
                    />
                  ) : (
                    <span className={`activity-icon activity-icon--${activity.type}`}>
                      {getActivityIcon(activity.type)}
                    </span>
                  )}
                </div>
                <div className="activity-item__content">
                  <div className="activity-item__header">
                    <div className="activity-item__title">{activity.title}</div>
                    <div className="activity-item__time">
                      {formatRelativeTime(activity.createdAt)}
                    </div>
                  </div>
                  {activity.description && (
                    <div className="activity-item__description">{activity.description}</div>
                  )}
                  <div className="activity-item__meta">
                    <span className="activity-item__author">{activity.createdByName}</span>
                    {activity.type === 'task' && activity.dueDate && (
                      <>
                        <span className="activity-item__separator">•</span>
                        <span className="activity-item__due">
                          Due: {new Date(activity.dueDate).toLocaleDateString()}
                        </span>
                      </>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>

          {enablePagination && hasMore && (
            <div className="unified-timeline__footer">
              <button
                type="button"
                className="btn btn--secondary btn--sm"
                onClick={handleLoadMore}
                disabled={isLoadingMore}
              >
                {isLoadingMore ? 'Loading...' : 'Load More'}
              </button>
            </div>
          )}
        </>
      )}
    </div>
  );
}

export default UnifiedTimeline;
