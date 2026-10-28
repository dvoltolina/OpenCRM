/**
 * Service Worker for Push Notifications
 * Handles background push events and notification clicks
 *
 * HIPAA Compliance:
 * - No PHI stored in service worker
 * - Push content is minimal - links back to app for details
 */

// Cache name for versioning
const CACHE_NAME = 'crm-push-v1';
const SHELL_CACHE = 'crm-shell-v1';
const OFFLINE_URL = '/offline.html';
const PRECACHE_URLS = [
  '/',
  '/index.html',
  OFFLINE_URL,
  '/manifest.webmanifest',
  '/icon.svg',
];

// ============================================
// Installation
// ============================================

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches
      .open(SHELL_CACHE)
      .then((cache) => cache.addAll(PRECACHE_URLS))
      .catch(() => {
        // If pre-cache fails (likely offline in dev), continue without blocking install
      })
  );
  self.skipWaiting(); // Activate immediately
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) =>
        Promise.all(
          keys.map((key) => {
            if (key !== CACHE_NAME && key !== SHELL_CACHE) {
              return caches.delete(key);
            }
            return undefined;
          })
        )
      )
      .then(() => self.clients.claim())
  );
});

// ============================================
// Push Event Handler
// ============================================

self.addEventListener('push', (event) => {
  if (!event.data) {
    return;
  }

  let payload;
  try {
    payload = event.data.json();
  } catch (e) {
    // If not JSON, try text
    payload = {
      title: 'New Notification',
      body: event.data.text(),
    };
  }

  const {
    title = 'New Notification',
    body = 'You have a new notification',
    icon = '/icon.svg',
    badge = '/icon.svg',
    data = {},
  } = payload;

  const options = {
    body,
    icon,
    badge,
    data,
    tag: data.notificationId || 'default',
    renotify: true,
    requireInteraction: data.type === 'task_due' || data.type === 'mention',
    vibrate: [200, 100, 200],
    actions: [
      {
        action: 'view',
        title: 'View',
      },
      {
        action: 'dismiss',
        title: 'Dismiss',
      },
    ],
  };

  event.waitUntil(
    self.registration.showNotification(title, options)
  );
});

// ============================================
// Notification Click Handler
// ============================================

self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  const { action } = event;
  const data = event.notification.data || {};

  // Handle dismiss action
  if (action === 'dismiss') {
    return;
  }

  // Determine URL to open
  let url = '/notifications';
  if (data.url) {
    url = data.url;
  } else if (data.notificationId) {
    url = `/notifications?id=${data.notificationId}`;
  }

  // Ensure URL is absolute
  if (!url.startsWith('http')) {
    url = self.location.origin + url;
  }

  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true })
      .then((clientList) => {
        // Check if there's already a window open
        for (const client of clientList) {
          if (client.url.startsWith(self.location.origin) && 'focus' in client) {
            // Navigate existing window
            client.postMessage({
              type: 'NOTIFICATION_CLICK',
              url,
              notificationId: data.notificationId,
            });
            return client.focus();
          }
        }

        // Open new window if none found
        if (self.clients.openWindow) {
          return self.clients.openWindow(url);
        }
      })
  );
});

// ============================================
// Fetch Handler (App Shell + Offline Fallback)
// ============================================

self.addEventListener('fetch', (event) => {
  const { request } = event;

  if (request.method !== 'GET') {
    return;
  }

  const url = new URL(request.url);

  // Avoid caching external requests or Firebase APIs (no PHI caching)
  const isExternal = url.origin !== self.location.origin;
  const isFirebase = /firebase|googleapis|gstatic|cloudfunctions/.test(url.host);
  if (isExternal || isFirebase) {
    return;
  }

  // Navigation requests: network-first, fallback to cache, then offline page
  if (request.mode === 'navigate') {
    event.respondWith(
      fetch(request)
        .then((response) => {
          const copy = response.clone();
          caches.open(SHELL_CACHE).then((cache) => cache.put(request, copy));
          return response;
        })
        .catch(() =>
          caches.match(request).then((cached) => cached || caches.match(OFFLINE_URL))
        )
    );
    return;
  }

  // Static assets (scripts/styles/images/fonts): cache-first, then network
  const staticTypes = ['style', 'script', 'image', 'font'];
  if (staticTypes.includes(request.destination)) {
    event.respondWith(
      caches.match(request).then((cached) => {
        if (cached) return cached;
        return fetch(request)
          .then((response) => {
            const copy = response.clone();
            caches.open(SHELL_CACHE).then((cache) => cache.put(request, copy));
            return response;
          })
          .catch(() => cached);
      })
    );
  }
});

// ============================================
// Message Handler (for closing notifications)
// ============================================

self.addEventListener('message', (event) => {
  const { type, notificationId } = event.data || {};

  if (type === 'CLOSE_NOTIFICATION' && notificationId) {
    // Close notification by tag
    self.registration.getNotifications({ tag: notificationId })
      .then((notifications) => {
        notifications.forEach((notification) => notification.close());
      });
  }
});

// ============================================
// Background Sync (future use)
// ============================================

self.addEventListener('sync', (event) => {
  if (event.tag === 'sync-notifications') {
    // Future: sync read/archive states when back online
  }
});

// ============================================
// Periodic Sync (future use)
// ============================================

self.addEventListener('periodicsync', (event) => {
  if (event.tag === 'check-notifications') {
    // Future: check for new notifications periodically
  }
});
