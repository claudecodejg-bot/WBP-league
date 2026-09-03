// =============================================
//  Service worker — installability only
// =============================================
// Android/Chrome will not offer the "Install app" prompt unless the site
// registers a service worker with a fetch handler. That is the ONLY reason
// this file exists.
//
// It deliberately caches NOTHING. Standings, results and availability change
// every week, and serving a stale scoreboard from cache would be worse than
// showing nothing at all. Every request passes straight through to the
// network exactly as it would without a service worker.
//
// If we ever want genuine offline support, the right approach is
// cache-first for the page shell, photos and icons, but always
// network-first for anything from Supabase.

self.addEventListener('install', () => self.skipWaiting())

self.addEventListener('activate', event => event.waitUntil(self.clients.claim()))

self.addEventListener('fetch', () => {
  // No respondWith() — the browser handles the request normally.
  // The handler must exist for the install prompt to be offered.
})
