// Memverifikasi kontrak Mock Campus API TANPA aplikasi Flutter.
//
//   node tool/check_api_flow.js [baseUrl]
//
// Urutan yang diuji persis seperti yang diwajibkan modul:
//   login -> /me 200 -> /debug/expire -> /me 401 -> refresh -> /me 200
//
// Kalau skrip ini lulus, jalur refresh pada interceptor Dio sudah punya lawan
// bicara yang benar.

const BASE = process.argv[2] || 'http://127.0.0.1:8787';

let failures = 0;

function check(label, actual, expected) {
  const ok = actual === expected;
  if (!ok) failures += 1;
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${label} (dapat ${actual}, harap ${expected})`);
}

async function call(path, { method = 'GET', token, body } = {}) {
  const headers = {};
  if (token) headers['Authorization'] = `Bearer ${token}`;
  if (body) headers['Content-Type'] = 'application/json';
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });
  let json = null;
  try {
    json = await res.json();
  } catch (_) {
    json = null;
  }
  return { status: res.status, json };
}

async function main() {
  console.log(`Menguji ${BASE}\n`);

  const health = await call('/health');
  check('GET /health', health.status, 200);

  const login = await call('/auth/login', {
    method: 'POST',
    body: { email: 'mahasiswa@polinema.ac.id', password: 'rahasia123' },
  });
  check('POST /auth/login', login.status, 200);
  const access = login.json?.access_token;
  const refresh = login.json?.refresh_token;

  check('GET /me (token sah)', (await call('/me', { token: access })).status, 200);
  check(
    'GET /me (tanpa token)',
    (await call('/me')).status,
    401,
  );
  check(
    'GET /announcements',
    (await call('/announcements', { token: access })).status,
    200,
  );
  check(
    'GET /announcements/3',
    (await call('/announcements/3', { token: access })).status,
    200,
  );
  check(
    'GET /announcements/999 -> 404',
    (await call('/announcements/999', { token: access })).status,
    404,
  );

  const device = await call('/devices', {
    method: 'POST',
    token: access,
    body: { fcm_token: 'contoh:APA91bTokenUji', platform: 'web' },
  });
  check('POST /devices', device.status, 200);

  // --- Inti pembuktian ------------------------------------------------------
  check(
    'POST /debug/expire',
    (await call('/debug/expire', { method: 'POST' })).status,
    200,
  );
  check(
    'GET /me SETELAH expire -> 401',
    (await call('/me', { token: access })).status,
    401,
  );

  const renewed = await call('/auth/refresh', {
    method: 'POST',
    body: { refresh_token: refresh },
  });
  check('POST /auth/refresh', renewed.status, 200);
  check(
    'GET /me dengan access BARU -> 200',
    (await call('/me', { token: renewed.json?.access_token })).status,
    200,
  );

  const badRefresh = await call('/auth/refresh', {
    method: 'POST',
    body: { refresh_token: 'palsu' },
  });
  check('POST /auth/refresh (token palsu) -> 401', badRefresh.status, 401);

  console.log(
    failures === 0
      ? '\nSEMUA PEMERIKSAAN LULUS'
      : `\n${failures} PEMERIKSAAN GAGAL`,
  );
  // Sengaja tidak memakai process.exit(): memutus koneksi keep-alive Node
  // secara paksa memicu assertion libuv di Windows dan membuat keluaran kotor.
  process.exitCode = failures === 0 ? 0 : 1;
}

main().catch((error) => {
  console.error('Gagal menjalankan pemeriksaan:', error.message);
  console.error('Pastikan server sudah jalan: node tool/mock_api_server.js 8787');
  process.exitCode = 1;
});
