// The deploy workflow replaces "dev" with the commit ID, so every deploy refreshes installed apps.
const CACHE_NAME = "vocab-cache-dev";
const PRECACHE_URLS = [
  "./",
  "./index.html",
  "./styles.css",
  "./manifest.json",
  "./js/app.js",
  "./js/dateUtils.js",
  "./js/storage.js",
  "./js/deckLoader.js",
  "./js/wordState.js",
  "./js/words-everyday.js",
  "./js/words-advanced.js",
  "./js/ui-learn.js",
  "./js/ui-revise.js",
  "./js/ui-calendar.js",
  "./js/wordSearch.js",
  "./js/ui-revisit.js",
  "./icons/icon-180.png",
  "./icons/icon-192.png",
  "./icons/icon-512.png",
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(PRECACHE_URLS.map((url) => new Request(url, { cache: "reload" }))))
  );
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key))
      )
    )
  );
  self.clients.claim();
});

self.addEventListener("fetch", (event) => {
  event.respondWith(
    caches.match(event.request).then((cached) => cached || fetch(event.request))
  );
});
