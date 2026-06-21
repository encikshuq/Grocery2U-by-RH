/* Grocery2U by RH - Service Worker
   Purpose: force fresh app updates and remove old cache automatically. */
const APP_VERSION = '1.2.1';
const CACHE_NAME = `grocery2u-rh-${APP_VERSION}`;
const APP_SHELL = [
  './',
  './index.html',
  './manifest.json',
  './version.json',
  './favicon.ico',
  './supabase-config.js',
  './assets/logo.png',
  './assets/logo-full.png',
  './assets/grocery-bg-blur.jpg',
  './assets/icons/icon-32.png',
  './assets/icons/icon-48.png',
  './assets/icons/icon-96.png',
  './assets/icons/icon-180.png',
  './assets/icons/icon-192.png',
  './assets/icons/icon-512.png'
];

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(APP_SHELL))
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.map((key) => {
      if (key !== CACHE_NAME && key.startsWith('grocery2u')) {
        return caches.delete(key);
      }
      return Promise.resolve();
    }));
    await self.clients.claim();
  })());
});

self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);

  // Always fetch these fresh so updates/config do not get stuck.
  const freshFiles = ['index.html', 'version.json', 'supabase-config.js', 'manifest.json'];
  const mustFetchFresh = freshFiles.some((file) => url.pathname.endsWith(file));

  if (mustFetchFresh) {
    event.respondWith(
      fetch(request, { cache: 'no-store' })
        .then((response) => {
          const copy = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(request, copy));
          return response;
        })
        .catch(() => caches.match(request))
    );
    return;
  }

  // Cache-first for images/icons for speed, fallback to network.
  event.respondWith(
    caches.match(request).then((cached) => {
      return cached || fetch(request).then((response) => {
        if (response && response.status === 200 && response.type === 'basic') {
          const copy = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(request, copy));
        }
        return response;
      });
    })
  );
});
