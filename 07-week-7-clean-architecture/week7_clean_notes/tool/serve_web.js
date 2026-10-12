// Static file server kecil untuk menjalankan hasil `flutter build web`.
//
// Dipakai hanya untuk pengambilan screenshot di lingkungan tanpa emulator
// Android. Tidak ada dependensi eksternal (Node.js built-in saja).
//
//   node tool/serve_web.js [folder] [port]
//   node tool/serve_web.js build/web 8123

const http = require('http');
const fs = require('fs');
const path = require('path');

const root = process.argv[2] || 'build/web';
const port = Number(process.argv[3] || 8123);

const TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.css': 'text/css',
  '.otf': 'font/otf',
  '.ttf': 'font/ttf',
  '.ico': 'image/x-icon',
  '.bin': 'application/octet-stream',
  '.symbols': 'application/octet-stream',
};

http
  .createServer((req, res) => {
    let rel = decodeURIComponent((req.url || '/').split('?')[0]);
    if (rel === '/' || rel === '') {
      rel = '/index.html';
    }
    const file = path.join(root, rel);
    fs.readFile(file, (err, data) => {
      if (err) {
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        res.end('not found: ' + rel);
        return;
      }
      res.writeHead(200, {
        'Content-Type': TYPES[path.extname(file)] || 'application/octet-stream',
        'Cache-Control': 'no-store',
      });
      res.end(data);
    });
  })
  .listen(port, '127.0.0.1', () =>
    console.log('serving ' + root + ' on http://127.0.0.1:' + port),
  );
