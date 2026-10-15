// Static file server kecil untuk menjalankan hasil `flutter build web`.
//
// Dipakai hanya untuk pengambilan screenshot di lingkungan tanpa emulator
// Android. Tidak ada dependensi eksternal (Node.js built-in saja).
//
//   node tool/serve_web.js [folder] [port]
//   node tool/serve_web.js build/web 8123
//
// Rute yang tidak menemukan berkas akan dijawab `index.html` supaya deep link
// (mis. `/pengumuman/3`) tetap bisa dimuat langsung oleh peramban.

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
    const urlPath = decodeURIComponent((req.url || '/').split('?')[0]);
    let filePath = path.join(root, urlPath);

    if (!fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
      filePath = path.join(root, 'index.html');
    }

    fs.readFile(filePath, (err, data) => {
      if (err) {
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        res.end('404');
        return;
      }
      res.writeHead(200, {
        'Content-Type': TYPES[path.extname(filePath)] || 'application/octet-stream',
        'Cache-Control': 'no-store',
      });
      res.end(data);
    });
  })
  .listen(port, '127.0.0.1', () => {
    console.log(`static server: http://127.0.0.1:${port}/  (root: ${root})`);
  });
