// Memverifikasi jalur 401 -> refresh -> retry PADA APLIKASI yang berjalan.
//
//   node tool/verify_refresh_flow.js
//
// Kenapa perlu, padahal ada `check_api_flow.js`?
// `check_api_flow.js` memeriksa kontrak SERVER. Skrip ini memeriksa KLIEN-nya:
// apakah interceptor Dio benar-benar menukar refresh token, mengulang request
// sekali, dan berakhir 200 di dalam aplikasi yang berjalan.
//
// Perbedaan itu penting: bug `Random().nextInt(1 << 32)` membuat jalur refresh
// selalu gagal DI WEB, sementara server tetap membalas 200 saat dipanggil
// langsung. Bug seperti itu hanya tertangkap oleh skrip ini.
//
// Prasyarat:
//   node tool/mock_api_server.js 8787     (terminal terpisah)
//   flutter build web --release
//   node tool/serve_web.js build/web 8123 (terminal terpisah)
//
// Keluar dengan kode 1 bila rantai retry tidak terjadi, refresh ikut gagal,
// atau pengguna terlempar ke /login.

const puppeteer = require('puppeteer-core');
const path = require('path');
const fs = require('fs');

const CHROME =
  process.env.CHROME_EXECUTABLE ||
  'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe';
const APP_URL = process.env.APP_URL || 'http://127.0.0.1:8123/';
const PROFILE = process.env.PROFILE_DIR || path.join(__dirname, '.chrome-profile');

const VIEW = {
  width: 390,
  height: 780,
  deviceScaleFactor: 2,
  isMobile: true,
  hasTouch: true,
};

// Koordinat sama dengan `screenshot_web.js` (dari accessibility tree).
const LOGIN_SUBMIT = [195, 467];
const TAB_SESI = [195, 740];
const UJI_401 = [195, 369];

const wait = (ms) => new Promise((r) => setTimeout(r, ms));
const tap = async (page, xy, settle = 700) => {
  await page.mouse.click(xy[0], xy[1]);
  await wait(settle);
};

async function main() {
  fs.rmSync(PROFILE, { recursive: true, force: true });

  const browser = await puppeteer.launch({
    executablePath: CHROME,
    headless: true,
    userDataDir: PROFILE,
    defaultViewport: VIEW,
    args: [
      '--no-sandbox',
      '--disable-dev-shm-usage',
      '--hide-scrollbars',
      '--enable-unsafe-swiftshader',
    ],
  });

  try {
    const page = await browser.newPage();
    const logs = [];
    page.on('console', (m) => logs.push(m.text()));
    page.on('pageerror', (e) => console.log('[pageerror]', e.message));

    await page.goto(APP_URL, { waitUntil: 'networkidle2', timeout: 240000 });
    await wait(7000);

    await tap(page, LOGIN_SUBMIT, 3500); // masuk
    await tap(page, TAB_SESI, 1500); // tab "Sesi & API"
    await tap(page, UJI_401, 6000); // 401 -> refresh -> retry

    const url = page.url();
    const retried = logs.some((l) => l.includes('ulang GET /me → 200'));
    const refreshFailed = logs.some((l) => l.includes('refresh ikut kedaluwarsa'));

    console.log('url akhir          :', url);
    console.log('rantai retry       :', retried ? 'ADA (ulang GET /me → 200)' : 'TIDAK ADA');
    console.log('refresh ikut mati  :', refreshFailed ? 'YA' : 'tidak');

    if (!retried || refreshFailed || url.includes('/login')) {
      console.error('\nGAGAL: jalur 401 -> refresh -> retry tidak berjalan benar.');
      process.exitCode = 1;
    } else {
      console.log('\nLULUS: 401 -> refresh -> retry berakhir 200 tanpa memaksa login ulang.');
    }
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error('Gagal menjalankan pemeriksaan:', error.message);
  console.error('Pastikan server sudah jalan: node tool/mock_api_server.js 8787');
  process.exitCode = 1;
});
