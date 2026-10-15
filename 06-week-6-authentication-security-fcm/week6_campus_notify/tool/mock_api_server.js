// Mock Campus API — backend tiruan untuk demo Minggu 6.
//
// Tidak ada dependensi eksternal (Node.js built-in saja).
//
//   node tool/mock_api_server.js [port]
//   node tool/mock_api_server.js 8787
//
// Kenapa perlu server sungguhan padahal auth-nya mock?
// Karena jalur yang WAJIB dibuktikan modul — "401 memicu refresh sekali lalu
// mengulang request" — tidak bisa dibuktikan tanpa ada yang benar-benar
// mengembalikan 401. Server ini melakukannya, dan mencatat setiap permintaan
// ke stdout sehingga rantai 401 → refresh → retry bisa ditunjukkan.
//
// Kontrak:
//   POST /auth/login      -> { access_token, refresh_token }
//   POST /auth/refresh    -> { access_token }   (refresh token di BODY, bukan URL)
//   GET  /me              -> 401 bila access token kedaluwarsa/dicabut
//   GET  /announcements   -> daftar pengumuman kampus
//   GET  /announcements/:id
//   POST /devices         -> simpan registration token FCM per pengguna
//   GET  /devices         -> daftar token yang tercatat
//   POST /debug/expire    -> cabut SEMUA access token (untuk menguji 401)

const http = require('http');

const PORT = Number(process.argv[2] || 8787);

// --- State -----------------------------------------------------------------

/**
 * Access token yang dicabut lewat POST /debug/expire -> waktu kedaluwarsa
 * pencabutannya (ms).
 *
 * Pencabutan sengaja BERSIFAT SEMENTARA (lihat REVOKE_TTL_MS). Alasannya
 * praktis: server ini dipakai berulang kali saat mengambil screenshot, dan
 * kalau pencabutan permanen maka satu kali menekan "Uji 401" akan membuat
 * SELURUH pengambilan screenshot berikutnya ikut 401 — demo jadi tidak bisa
 * diulang tanpa me-restart server.
 */
const revoked = new Map();

const REVOKE_TTL_MS = 20_000;

/** Access token yang pernah dilihat, agar /debug/expire bisa mencabut semua. */
const seenAccessTokens = new Set();

/** Registration token FCM yang tercatat per pengguna. */
const devices = [];

const ANNOUNCEMENTS = [
  {
    id: '1',
    title: 'Jadwal UAS semester ganjil',
    body:
      'Ujian Akhir Semester dilaksanakan 12–23 Januari. Kartu ujian dapat '
      + 'diunduh dari portal akademik mulai 5 Januari.',
    published_at: '10 Okt 2026, 08:00',
  },
  {
    id: '2',
    title: 'Pemeliharaan sistem akademik',
    body:
      'Portal akademik tidak dapat diakses Minggu 18 Oktober pukul 00.00–04.00 '
      + 'untuk pemeliharaan basis data.',
    published_at: '11 Okt 2026, 13:30',
  },
  {
    id: '3',
    title: 'Jadwal kuliah berubah',
    body:
      'Kelas Mobile pindah ke Ruang A2 jam 13.00 mulai pekan depan. '
      + 'Mohon perhatikan perubahan ruang pada KRS masing-masing.',
    published_at: '12 Okt 2026, 09:15',
  },
  {
    id: '4',
    title: 'Beasiswa prestasi dibuka',
    body:
      'Pendaftaran beasiswa prestasi akademik dibuka hingga 30 Oktober. '
      + 'Syarat: IPK minimal 3.25 dan tidak sedang menerima beasiswa lain.',
    published_at: '13 Okt 2026, 10:45',
  },
  {
    id: '5',
    title: 'Seminar keamanan aplikasi mobile',
    body:
      'Seminar "OWASP Mobile Top 10" digelar di Aula JTI, Kamis pukul 09.00. '
      + 'Terbuka untuk seluruh mahasiswa, kuota 120 peserta.',
    published_at: '14 Okt 2026, 15:20',
  },
];

// --- Util ------------------------------------------------------------------

function log(...args) {
  const time = new Date().toTimeString().slice(0, 8);
  console.log(`[${time}]`, ...args);
}

function send(res, status, payload) {
  const body = JSON.stringify(payload);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(body),
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Cache-Control': 'no-store',
  });
  res.end(body);
}

function readJson(req) {
  return new Promise((resolve) => {
    let raw = '';
    req.on('data', (chunk) => {
      raw += chunk;
    });
    req.on('end', () => {
      if (!raw) return resolve({});
      try {
        resolve(JSON.parse(raw));
      } catch (_) {
        resolve({});
      }
    });
  });
}

function bearer(req) {
  const header = req.headers['authorization'] || '';
  return header.startsWith('Bearer ') ? header.slice(7).trim() : null;
}

/**
 * Access token dianggap sah bila berpola token mock codelab dan belum dicabut.
 *
 * Client membuat tokennya sendiri (AuthRepository mock), jadi server tidak
 * menerbitkannya — server hanya memvalidasi bentuk dan status pencabutan.
 * Pola inilah yang membuat 401 bisa dipicu secara deterministik lewat
 * POST /debug/expire.
 */
function accessTokenValid(token) {
  if (!token) return false;

  // Pencabutan hanya berlaku selama REVOKE_TTL_MS.
  const revokedUntil = revoked.get(token);
  if (revokedUntil !== undefined) {
    if (Date.now() < revokedUntil) return false;
    revoked.delete(token);
  }

  return (
    token.startsWith('mock-access-for-') ||
    token.startsWith('mock-access-renewed-')
  );
}

function requireAuth(req, res) {
  const token = bearer(req);
  if (token) seenAccessTokens.add(token);

  if (!accessTokenValid(token)) {
    log(`401 ${req.method} ${req.url} (access token kedaluwarsa/dicabut)`);
    send(res, 401, {
      error: 'unauthorized',
      message: 'Access token kedaluwarsa. Tukar refresh token Anda.',
    });
    return null;
  }
  return token;
}

// --- Routing ---------------------------------------------------------------

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://127.0.0.1:${PORT}`);
  const path = url.pathname;
  const method = req.method || 'GET';

  // Preflight CORS.
  if (method === 'OPTIONS') {
    send(res, 204, {});
    return;
  }

  // --- Auth ---------------------------------------------------------------
  if (method === 'POST' && path === '/auth/login') {
    const body = await readJson(req);
    const email = String(body.email || '').trim();
    if (!email.includes('@')) {
      log('400 POST /auth/login (email tidak valid)');
      send(res, 400, { error: 'invalid_email' });
      return;
    }
    log(`200 POST /auth/login (${email})`);
    send(res, 200, {
      access_token: `mock-access-for-${email}`,
      refresh_token: `mock-refresh-for-${email}`,
      expires_in: 900,
    });
    return;
  }

  if (method === 'POST' && path === '/auth/refresh') {
    // Refresh token WAJIB lewat body POST — tidak pernah di query string.
    const body = await readJson(req);
    const refresh = String(body.refresh_token || '');
    if (!refresh.startsWith('mock-refresh-for-')) {
      log('401 POST /auth/refresh (refresh token tidak sah)');
      send(res, 401, { error: 'invalid_refresh_token' });
      return;
    }
    const renewed = `mock-access-renewed-${Date.now()}`;
    log(`200 POST /auth/refresh -> access token baru diterbitkan`);
    send(res, 200, { access_token: renewed, expires_in: 900 });
    return;
  }

  if (method === 'GET' && path === '/me') {
    const token = requireAuth(req, res);
    if (!token) return;
    const email = token.startsWith('mock-access-for-')
      ? token.slice('mock-access-for-'.length)
      : 'mahasiswa@polinema.ac.id';
    log(`200 GET /me (${email})`);
    send(res, 200, {
      email,
      name: 'Mahasiswa JTI',
      role: 'mahasiswa',
      program_studi: 'Teknik Informatika',
      token_type: token.startsWith('mock-access-renewed-')
        ? 'hasil refresh'
        : 'hasil login',
    });
    return;
  }

  // --- Pengumuman ---------------------------------------------------------
  if (method === 'GET' && path === '/announcements') {
    if (!requireAuth(req, res)) return;
    log(`200 GET /announcements (${ANNOUNCEMENTS.length} item)`);
    send(res, 200, { items: ANNOUNCEMENTS });
    return;
  }

  const announcementMatch = path.match(/^\/announcements\/([^/]+)$/);
  if (method === 'GET' && announcementMatch) {
    if (!requireAuth(req, res)) return;
    const id = decodeURIComponent(announcementMatch[1]);
    const found = ANNOUNCEMENTS.find((item) => item.id === id);
    if (!found) {
      log(`404 GET /announcements/${id}`);
      send(res, 404, { error: 'not_found', message: 'Pengumuman tidak ada.' });
      return;
    }
    log(`200 GET /announcements/${id}`);
    send(res, 200, found);
    return;
  }

  // --- Registrasi perangkat ----------------------------------------------
  if (method === 'POST' && path === '/devices') {
    if (!requireAuth(req, res)) return;
    const body = await readJson(req);
    const fcmToken = String(body.fcm_token || '');
    const platform = String(body.platform || 'unknown');
    if (!fcmToken) {
      log('400 POST /devices (fcm_token kosong)');
      send(res, 400, { error: 'missing_fcm_token' });
      return;
    }
    // Backend WAJIB mengganti token lama, bukan menumpuknya.
    const existing = devices.findIndex((d) => d.platform === platform);
    const record = { fcm_token: fcmToken, platform, updated_at: new Date().toISOString() };
    if (existing >= 0) {
      devices[existing] = record;
      log(`200 POST /devices (token platform ${platform} DIPERBARUI)`);
    } else {
      devices.push(record);
      log(`200 POST /devices (token platform ${platform} dicatat)`);
    }
    send(res, 200, { ok: true, total: devices.length });
    return;
  }

  if (method === 'GET' && path === '/devices') {
    if (!requireAuth(req, res)) return;
    log(`200 GET /devices (${devices.length} token)`);
    send(res, 200, { devices });
    return;
  }

  // --- Alat bantu demo ----------------------------------------------------
  if (method === 'POST' && path === '/debug/expire') {
    const until = Date.now() + REVOKE_TTL_MS;
    for (const token of seenAccessTokens) revoked.set(token, until);
    log(
      `200 POST /debug/expire (${revoked.size} access token dicabut selama `
        + `${REVOKE_TTL_MS / 1000} detik — request berikutnya harus 401)`,
    );
    send(res, 200, { revoked: revoked.size, ttl_ms: REVOKE_TTL_MS });
    return;
  }

  if (method === 'GET' && path === '/health') {
    send(res, 200, { ok: true, devices: devices.length, revoked: revoked.size });
    return;
  }

  log(`404 ${method} ${path}`);
  send(res, 404, { error: 'not_found', message: `Tidak ada rute ${method} ${path}` });
});

server.listen(PORT, '127.0.0.1', () => {
  log(`Mock Campus API aktif di http://127.0.0.1:${PORT}`);
  log('Tekan Ctrl+C untuk berhenti.');
});
