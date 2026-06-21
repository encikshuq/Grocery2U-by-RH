# Grocery2U by RH - Cache Auto Clear

Versi ini menambah PWA cache update system.

Fail penting:
- `sw.js` - service worker utama
- `service-worker.js` - salinan untuk compatibility
- `version.json` - nombor versi app
- `manifest.json` - PWA manifest dikemas kini

Cara release versi baru:
1. Tukar versi dalam `sw.js` dan `service-worker.js`:
   `const APP_VERSION = '1.2.2';`
2. Tukar versi dalam `version.json`.
3. Tukar cachebuster dalam `index.html` jika perlu.
4. Upload semua file ke hosting.

Service worker akan delete cache lama yang bermula dengan `grocery2u` dan reload app apabila versi baru dikesan.
