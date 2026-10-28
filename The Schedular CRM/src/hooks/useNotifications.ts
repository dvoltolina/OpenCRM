/**
 * useNotifications Hook
 * Real-time notifications with subscription and actions
 *
 * CRM Notifications Implementation
 */

import { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import { useSecurityContext } from './useSecurityContext';
import { getNotificationService } from '../services/notification-service';
import type { Notification } from '../types/notifications';
import { useDemoGuard } from './useDemoGuard';

// ============================================
// Types
// ============================================

export interface UseNotificationsResult {
  /** List of notifications */
  notifications: Notification[];
  /** Number of unread notifications */
  unreadCount: number;
  /** Loading state */
  isLoading: boolean;
  /** Error message if any */
  error: string | null;
  /** Mark a notification as read */
  markAsRead: (id: string) => Promise<void>;
  /** Mark all notifications as read */
  markAllAsRead: () => Promise<void>;
  /** Archive a notification */
  archive: (id: string) => Promise<void>;
  /** Refresh notifications */
  refresh: () => Promise<void>;
  /** Load more notifications */
  loadMore: () => Promise<void>;
  /** Whether there are more to load */
  hasMore: boolean;
}

export interface UseNotificationsOptions {
  /** Maximum notifications to load initially */
  limit?: number;
  /** Include archived notifications */
  includeArchived?: boolean;
  /** Only show unread */
  unreadOnly?: boolean;
  /** Enable real-time subscription */
  realtime?: boolean;
}

// ============================================
// Hook
// ============================================

export function useNotifications(
  options: UseNotificationsOptions = {}
): UseNotificationsResult {
  const { guardMutation } = useDemoGuard();
  const {
    limit = 50,
    includeArchived = false,
    unreadOnly = false,
    realtime = true,
  } = options;

  const { context, isAuthenticated } = useSecurityContext();
  const notificationService = useMemo(() => getNotificationService(), []);

  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [hasMore, setHasMore] = useState(false);
  const [lastDocId, setLastDocId] = useState<string | undefined>(undefined);

  const unsubscribeRef = useRef<(() => void) | null>(null);
  const unsubscribeCountRef = useRef<(() => void) | null>(null);

  // ============================================
  // Load notifications
  // ============================================

  const loadNotifications = useCallback(async () => {
    if (!context || !isAuthenticated) return;

    setIsLoading(true);
    setError(null);

    try {
      const result = await notificationService.getAll(context, {
        limit,
        includeArchived,
        unreadOnly,
      });

      if (result.success && result.data) {
        setNotifications(result.data.notifications);
        setHasMore(result.data.hasMore);
        setLastDocId(result.data.lastDocId);
      } else {
        setError(result.error?.message || 'Failed to load notifications');
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load notifications');
    } finally {
      setIsLoading(false);
    }
  }, [context, includeArchived, isAuthenticated, limit, notificationService, unreadOnly]);

  // ============================================
  // Real-time subscription
  // ============================================

  useEffect(() => {
    if (!context || !isAuthenticated || !realtime) {
      loadNotifications();
      return;
    }

    setIsLoading(true);

    // Subscribe to notifications
    unsubscribeRef.current = notificationService.subscribe(
      context,
      (updatedNotifications) => {
        setNotifications(updatedNotifications);
        setIsLoading(false);
      },
      { limit, includeArchived }
    );

    // Subscribe to unread count
    unsubscribeCountRef.current = notificationService.subscribeToUnreadCount(
      context,
      (count) => {
        setUnreadCount(count);
      }
    );

    // Cleanup
    return () => {
      if (unsubscribeRef.current) {
        unsubscribeRef.current();
        unsubscribeRef.current = null;
      }
      if (unsubscribeCountRef.current) {
        unsubscribeCountRef.current();
        unsubscribeCountRef.current = null;
      }
    };
  }, [context, includeArchived, isAuthenticated, limit, loadNotifications, notificationService, realtime]);

  // ============================================
  // Actions
  // ============================================

  const markAsRead = useCallback(async (id: string) => {
    if (!context) return;

    try {
      const result = await notificationService.markAsRead(context, id);
      if (!result.success) {
        setError(result.error?.message || 'Failed to mark as read');
      }

      // Optimistically update
      setNotifications((prev) =>
        prev.map((n) =>
          n.id === id ? { ...n, isRead: true, readAt: new Date() } : n
        )
      );
      setUnreadCount((prev) => Math.max(0, prev - 1));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to mark as read');
    }
  }, [context, notificationService]);

  const markAllAsRead = useCallback(async () => {
    if (!context) return;

    try {
      const result = await notificationService.markAllAsRead(context);
      if (!result.success) {
        setError(result.error?.message || 'Failed to mark all as read');
      }

      // Optimistically update
      const now = new Date();
      setNotifications((prev) =>
        prev.map((n) => ({ ...n, isRead: true, readAt: now }))
      );
      setUnreadCount(0);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to mark all as read');
    }
  }, [context, notificationService]);

  const archive = useCallback(async (id: string) => {
    if (!context) return;

    try {
      const result = await notificationService.archive(context, id);
      if (!result.success) {
        setError(result.error?.message || 'Failed to archive');
      }

      // Optimistically remove from list
      setNotifications((prev) => prev.filter((n) => n.id !== id));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to archive');
    }
  }, [context, notificationService]);

  const refresh = useCallback(async () => {
    await loadNotifications();
  }, [loadNotifications]);

  const loadMore = useCallback(async () => {
    if (!context || !hasMore || !lastDocId) return;

    try {
      const result = await notificationService.getAll(context, {
        limit,
        includeArchived,
        unreadOnly,
        lastDocId, // Cursor-based pagination
      });

      if (result.success && result.data) {
        setNotifications((prev) => [...prev, ...result.data!.notifications]);
        setHasMore(result.data.hasMore);
        setLastDocId(result.data.lastDocId);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load more');
    }
  }, [context, hasMore, includeArchived, lastDocId, limit, notificationService, unreadOnly]);

  return {
    notifications,
    unreadCount,
    isLoading,
    error,
    markAsRead: guardMutation(markAsRead, { action: 'notification-mark-read' }),
    markAllAsRead: guardMutation(markAllAsRead, { action: 'notification-mark-all-read' }),
    archive: guardMutation(archive, { action: 'notification-archive' }),
    refresh,
    loadMore,
    hasMore,
  };
}
