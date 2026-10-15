// Pengambil screenshot aplikasi Flutter web pada viewport layout mobile.
//
// Dijalankan SATU langkah per pemanggilan supaya setiap proses Chrome ditutup
// sebelum langkah berikutnya ("satu-satu, tutup, lalu ganti screenshot
// berikutnya").
//
//   node tool/screenshot_web.js screenshots/01_login.png login
//   FRESH=1 node tool/screenshot_web.js screenshots/03_beranda.png beranda
//
// Langkah: login, login_error, beranda, sesi, api_401, push, foreground,
//          background, terminated, rotate, logout_dialog, announcement, reset
//
// Prasyarat:
//   node tool/mock_api_server.js 8787            (terminal terpisah)
//   flutter build web --release
//   node tool/serve_web.js build/web 8123        (terminal terpisah)
//
// Dependensi: puppeteer-core (devDependency, tidak masuk ke aplikasi)
//   npm install puppeteer-core
//
// Koordinat di bawah BUKAN tebakan: semuanya diambil dari accessibility tree
// Flutter web lewat `node tool/dump_semantics.js <langkah>`.
//   input Email        -> (199, 346)
//   input Kata sandi   -> (199, 408)
//   tombol Masuk       -> (195, 467)
//   tombol Keluar      -> (370,  28)      dialog: Batal (202,456), Keluar (282,456)
//   Simulator FCM      -> foreground (195,293) background (195,329) terminated (195,365)
//   Sesi & API         -> uji 401 (195,369)  GET /me (195,414)
//   Push & Token       -> rotasi token (195,329)
//   Tab bar (y=740)    -> Beranda (65)  Sesi & API (195)  Push & Token (325)
//
// FRESH=1 menghapus profil Chrome lebih dulu sehingga setiap langkah dimulai
// dari keadaan "belum login" — deterministik dan tidak bergantung langkah lain.

const puppeteer = require('puppeteer-core');
const path = require('path');
const fs = require('fs');

const CHROME =
  process.env.CHROME_EXECUTABLE ||
  'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe';
const APP_URL = process.env.APP_URL || 'http://127.0.0.1:8123/';
const PROFILE = process.env.PROFILE_DIR || path.join(__dirname, '.chrome-profile');

// Viewport layout mobile: rasio ponsel, DPR 2 -> berkas 780 x 1560 px.
const VIEW = {
  width: 390,
  height: 780,
  deviceScaleFactor: 2,
  isMobile: true,
  hasTouch: true,
};

const LOGIN = {
  email: [199, 346],
  password: [199, 408],
  submit: [195, 467],
};

const TAB = {
  beranda: [65, 740],
  sesi: [195, 740],
  push: [325, 740],
};

const SIM = {
  foreground: [195, 293],
  background: [195, 329],
  terminated: [195, 365],
};

const SESI = { uji401: [195, 369], getMe: [195, 414] };
const PUSH = { rotate: [195, 329] };
const LOGOUT = { appbar: [370, 28], dialogKeluar: [282, 456] };
// Baris pertama daftar "Pengumuman kampus" pada tab Beranda.
const TILE = { pertama: [195, 526] };

const out = process.argv[2];
const step = process.argv[3];

if (!out || !step) {
  console.error('usage: node tool/screenshot_web.js <output.png> <step>');
  process.exit(2);
}

const wait = (ms) => new Promise((r) => setTimeout(r, ms));

/**
 * Menghapus profil Chrome dengan percobaan ulang.
 *
 * Windows kadang masih menggenggam berkas profil beberapa saat setelah proses
 * Chrome induk berhenti, sehingga `rmSync` gagal dengan EPERM. Tanpa percobaan
 * ulang, langkah berikutnya gagal hanya karena proses sebelumnya belum benar-
 * benar selesai.
 */
async function resetProfile() {
  for (let attempt = 1; attempt <= 8; attempt += 1) {
    try {
      fs.rmSync(PROFILE, { recursive: true, force: true });
      return;
    } catch (error) {
      if (attempt === 8) throw error;
      await wait(1000);
    }
  }
}

async function tap(page, xy, settle = 600) {
  await page.mouse.click(xy[0], xy[1]);
  await wait(settle);
}

async function clearField(page, xy) {
  await tap(page, xy, 250);
  await page.keyboard.down('Control');
  await page.keyboard.press('KeyA');
  await page.keyboard.up('Control');
  await page.keyboard.press('Backspace');
  await wait(150);
}

/** Login memakai kredensial yang sudah terisi otomatis di halaman login. */
async function login(page) {
  await tap(page, LOGIN.submit, 3200);
}

async function main() {
  if (step === 'reset') {
    await resetProfile();
    console.log('profile reset');
    return;
  }

  if (process.env.FRESH === '1') {
    await resetProfile();
  }

  const browser = await puppeteer.launch({
    executablePath: CHROME,
    headless: true,
    userDataDir: PROFILE,
    defaultViewport: VIEW,
    args: [
      '--no-sandbox',
      '--disable-dev-shm-usage',
      '--hide-scrollbars',
      '--force-color-profile=srgb',
      '--enable-unsafe-swiftshader',
      '--window-size=390,780',
    ],
  });

  try {
    const page = await browser.newPage();
    await page.setViewport(VIEW);
    page.on('pageerror', (e) => console.log('[pageerror]', e.message));
    page.on('console', (m) => {
      if (m.type() === 'error' || process.env.CONSOLE === 'all') {
        console.log(`[console.${m.type()}]`, m.text());
      }
    });

    await page.goto(APP_URL, { waitUntil: 'networkidle2', timeout: 240000 });
    await wait(7000); // beri waktu Flutter + secure storage siap

    switch (step) {
      case 'login':
        break;

      case 'login_error':
        await clearField(page, LOGIN.email);
        await page.keyboard.type('bukan-email', { delay: 40 });
        await clearField(page, LOGIN.password);
        await page.keyboard.type('12', { delay: 40 });
        await tap(page, LOGIN.submit, 1200);
        break;

      case 'beranda':
        await login(page);
        await tap(page, TAB.beranda, 1500);
        break;

      case 'sesi':
        await login(page);
        await tap(page, TAB.sesi, 1500);
        break;

      case 'api_401':
        await login(page);
        await tap(page, TAB.sesi, 1200);
        await tap(page, SESI.uji401, 4500); // expire -> 401 -> refresh -> retry
        // Gulir agar rantai "401 -> refresh -> ulang -> 200" pada Log lalu
        // lintas ikut terlihat; kartu respons di atasnya sudah terbaca.
        await page.mouse.move(195, 400);
        await page.mouse.wheel({ deltaY: 620 });
        await wait(900);
        break;

      case 'push':
        await login(page);
        await tap(page, TAB.push, 1800);
        break;

      case 'rotate':
        await login(page);
        await tap(page, TAB.push, 1500);
        await tap(page, PUSH.rotate, 2200);
        // Gulir sedikit agar baris log terakhir ("token tercatat di backend")
        // ikut terlihat sebagai bukti onTokenRefresh mengirim ulang.
        await page.mouse.move(195, 400);
        await page.mouse.wheel({ deltaY: 260 });
        await wait(800);
        break;

      case 'foreground':
        await login(page);
        await tap(page, TAB.beranda, 1200);
        await tap(page, SIM.foreground, 1400);
        break;

      case 'background':
        await login(page);
        await tap(page, TAB.beranda, 1200);
        await tap(page, SIM.background, 3000);
        break;

      case 'terminated':
        await login(page);
        await tap(page, TAB.beranda, 1200);
        await tap(page, SIM.terminated, 3000);
        break;

      case 'logout_dialog':
        await login(page);
        await tap(page, LOGOUT.appbar, 1200);
        break;

      case 'announcement':
        await login(page);
        await tap(page, TAB.beranda, 1200);
        await tap(page, TILE.pertama, 2500);
        break;

      default:
        throw new Error('step tidak dikenal: ' + step);
    }

    // Pindahkan kursor agar tooltip hover tidak ikut terfoto.
    await page.mouse.move(195, 620);
    await wait(500);

    fs.mkdirSync(path.dirname(out), { recursive: true });
    await page.screenshot({ path: out });
    console.log('captured ' + out + ' (step=' + step + ')');
  } finally {
    await browser.close();
  }
}

main().catch((e) => {
  console.error('FAILED:', e.message);
  process.exitCode = 1;
});
