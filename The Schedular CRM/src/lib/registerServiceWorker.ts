/**
 * Register service worker for offline support and push
 * HIPAA: caches only static shell; no PHI responses cached.
 */

function isLocalDevHost(hostname: string): boolean {
  return (
    hostname === 'localhost' ||
    hostname === '127.0.0.1' ||
    hostname === '[::1]'
  );
}

async function unregisterDevelopmentServiceWorkers(): Promise<void> {
  try {
    const registrations = await navigator.serviceWorker.getRegistrations();
    await Promise.all(registrations.map((registration) => registration.unregister()));
  } catch (err) {
    console.info('[sw] dev unregister failed', err);
  }

  if (!('caches' in window)) {
    return;
  }

  try {
    const cacheKeys = await caches.keys();
    await Promise.all(cacheKeys.map((key) => caches.delete(key)));
  } catch (err) {
    console.info('[sw] dev cache cleanup failed', err);
  }
}

export function registerServiceWorker(): void {
  if (typeof window === 'undefined') return;
  if (!('serviceWorker' in navigator)) return;

  // Avoid registering during tests
  if (import.meta.env?.VITEST) return;

  // Do not run the caching service worker in local Vite development.
  // It can cache /@vite/client and module responses, which breaks HMR
  // and can leave localhost serving stale bundles after restarts.
  if (import.meta.env.DEV || isLocalDevHost(window.location.hostname)) {
    window.addEventListener('load', () => {
      void unregisterDevelopmentServiceWorkers();
    });
    return;
  }

  // Register after page load to avoid blocking rendering
  window.addEventListener('load', () => {
    navigator.serviceWorker
      .register('/sw.js')
      .catch((err) => {
        // Silent failure; app still works online
        console.info('[sw] registration failed', err);
      });
  });
}
